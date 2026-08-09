#!/usr/bin/env python3
"""Build a Bulgarian MOMI package using the game's built-in Silver font."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import tempfile
import tomllib
import zipfile
from pathlib import Path, PurePosixPath


VERSION_LINE = re.compile(rb'(?m)^version = "[^"]+"\r?$')
TEXT_STYLES_SUFFIX = "/fiddle/ui/text_styles.toml"
FONT_SUFFIXES = (
    "/fonts/fnt_mistria_birdseed_bul.ttf",
    "/fonts/fnt_mistria_birdseed_bul.meta.toml",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_path(name: str) -> str:
    normalized = str(PurePosixPath(name.replace("\\", "/"))).casefold()
    if normalized.startswith("/") or normalized == ".." or normalized.startswith("../"):
        raise ValueError(f"Unsafe ZIP entry path: {name}")
    return normalized.rstrip("/")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite existing package: {output}")
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        raise ValueError("Version must use MAJOR.MINOR.PATCH format")
    if not zipfile.is_zipfile(source):
        raise ValueError(f"Source is not a readable ZIP: {source}")

    before: dict[str, str] = {}
    after: dict[str, str] = {}
    removed: list[str] = []
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None

    try:
        with zipfile.ZipFile(source, "r") as source_zip:
            if source_zip.testzip() is not None:
                raise ValueError("Source ZIP contains a damaged entry")
            entries = source_zip.infolist()
            normalized: dict[str, str] = {}
            for info in entries:
                key = normalized_path(info.filename)
                if key in normalized:
                    raise ValueError(
                        f"Duplicate normalized path: {normalized[key]} and {info.filename}"
                    )
                normalized[key] = info.filename

            manifests = [i for i in entries if i.filename.endswith("/manifest.toml")]
            styles = [i for i in entries if i.filename.endswith(TEXT_STYLES_SUFFIX)]
            if len(manifests) != 1 or len(styles) != 1:
                raise ValueError(
                    f"Expected one manifest and one text_styles.toml; found "
                    f"{len(manifests)} and {len(styles)}"
                )
            manifest_name = manifests[0].filename
            styles_name = styles[0].filename

            handle, raw_temp = tempfile.mkstemp(
                prefix=output.stem + ".", suffix=".tmp.zip", dir=output.parent
            )
            os.close(handle)
            temporary_path = Path(raw_temp)
            with zipfile.ZipFile(temporary_path, "w") as target_zip:
                for info in entries:
                    if any(info.filename.endswith(suffix) for suffix in FONT_SUFFIXES):
                        removed.append(info.filename)
                        continue
                    payload = source_zip.read(info.filename)
                    before[info.filename] = sha256(payload)
                    if info.filename == manifest_name:
                        payload, count = VERSION_LINE.subn(
                            f'version = "{args.version}"'.encode("utf-8"), payload
                        )
                        if count != 1:
                            raise ValueError("Could not replace exactly one manifest version")
                        tomllib.loads(payload.decode("utf-8-sig"))
                    elif info.filename == styles_name:
                        text = payload.decode("utf-8-sig")
                        if text.count('bul = "fnt_mistria_birdseed_bul"') != 3:
                            raise ValueError("Expected exactly three Bulgarian font mappings")
                        text = text.replace(
                            'bul = "fnt_mistria_birdseed_bul"',
                            'bul = "fnt_silver"',
                        )
                        payload = text.encode("utf-8")
                        tomllib.loads(payload.decode("utf-8"))
                    after[info.filename] = sha256(payload)
                    target_zip.writestr(info, payload)

        with temporary_path.open("r+b") as stream:
            stream.flush()
            os.fsync(stream.fileno())
        with zipfile.ZipFile(temporary_path, "r") as check_zip:
            if check_zip.testzip() is not None:
                raise ValueError("Generated ZIP contains a damaged entry")
            if check_zip.read(styles_name).count(b'bul = "fnt_silver"') != 3:
                raise ValueError("Generated ZIP does not contain all Silver mappings")
            tomllib.loads(check_zip.read(manifest_name).decode("utf-8-sig"))

        changed = [
            {
                "entry": name,
                "before_sha256": before[name],
                "after_sha256": after[name],
            }
            for name in before
            if before[name] != after[name]
        ]
        os.replace(temporary_path, output)
        temporary_path = None
        report = {
            "source": str(source),
            "output": str(output),
            "version": args.version,
            "changed_entries": changed,
            "removed_entries": removed,
            "remaining_entry_count": len(after),
            "validation": {
                "zip_readable": True,
                "duplicate_normalized_paths": 0,
                "manifest_toml_parseable": True,
                "text_styles_toml_parseable": True,
            },
        }
        report_path = output.with_suffix(output.suffix + ".report.json")
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(output)
        print(report_path)
        return 0
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()


if __name__ == "__main__":
    raise SystemExit(main())
