#!/usr/bin/env python3
"""Create a clean MOMI/AIM package from the generated Bulgarian overlay."""
from __future__ import annotations

import argparse
import tomllib
import zipfile
from pathlib import Path


REQUIRED = {
    "manifest.toml",
    "localization/l10n.meta.toml",
    "localization/source_caches/bul.meta.toml",
    "localization/translations/bul.meta.toml",
    "gml/BulgarianLvlHook.gml",
}
PACKAGE_ROOTS = ("manifest.toml", "animations", "fiddle", "gml", "localization")


def package_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for relative in PACKAGE_ROOTS:
        item = root / relative
        if item.is_file():
            files.append(item)
        elif item.is_dir():
            files.extend(sorted(path for path in item.rglob("*") if path.is_file()))
        else:
            raise FileNotFoundError(f"Required package input is missing: {item}")
    return files


def validate_archive(path: Path) -> int:
    with zipfile.ZipFile(path) as archive:
        bad_member = archive.testzip()
        if bad_member:
            raise ValueError(f"Unreadable ZIP entry: {bad_member}")
        names = set(archive.namelist())
        missing = REQUIRED - names
        forbidden = sorted(name for name in names if name.startswith(("fonts/", "translation/")))
        if missing or forbidden:
            raise ValueError(f"Missing={sorted(missing)}; forbidden={forbidden}")
        for name in names:
            if name.endswith(".toml"):
                tomllib.loads(archive.read(name).decode("utf-8-sig"))
        return len(names)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mod-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    root = args.mod_root.resolve()
    output = args.output.resolve()
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite existing package: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    files = package_files(root)
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in files:
            archive.write(file, file.relative_to(root).as_posix())
    count = validate_archive(output)
    print(f"Package verified: {output} ({count} files, {output.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
