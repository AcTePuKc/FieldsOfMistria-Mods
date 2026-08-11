#!/usr/bin/env python3
"""Build a complete MOMI Bulgarian localization overlay from the English cache."""
from __future__ import annotations

import argparse
import json
import re
import shutil
import tomllib
from pathlib import Path


def write_table(path: Path, asset_id: str, asset_kind: str, values: dict[str, str]) -> None:
    lines = [
        "[meta_properties]",
        f"id = {json.dumps(asset_id, ensure_ascii=False)}",
        f"asset_kind = {json.dumps(asset_kind, ensure_ascii=False)}",
        "",
        "[asset_properties]",
    ]
    lines.extend(
        f"{json.dumps(key, ensure_ascii=False)} = {json.dumps(value, ensure_ascii=False)}"
        for key, value in values.items()
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def normalize_bulgarian_text(value: str) -> str:
    """Apply final Bulgarian typography cleanup to translated values only."""
    value = re.sub(r"\s+—\s+", ", ", value)
    value = re.sub(r"—\s*$", "...", value)
    value = value.replace("—", "-")
    value = re.sub(r"“([^”]*)”", r"„\1“", value)
    value = re.sub(r"‘([^’]*)’", r"„\1“", value)
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--overlay", type=Path, required=True)
    parser.add_argument("--translation-id", default="a1f64c8d2e9b7035")
    parser.add_argument("--source-cache-id", default="c7b90e15d4a2863f")
    args = parser.parse_args()

    l10n_template = args.work.parent / "bul_l10n.meta.toml"
    if l10n_template.exists():
        l10n = tomllib.loads(l10n_template.read_text(encoding="utf-8-sig"))
        language = l10n["asset_properties"]["languages"]["bul"]
        if language.get("translation") != args.translation_id:
            raise ValueError(
                f"l10n.meta.toml translation ID {language.get('translation')!r} "
                f"does not match generated ID {args.translation_id!r}"
            )
        if language.get("src_cache") != args.source_cache_id:
            raise ValueError(
                f"l10n.meta.toml source-cache ID {language.get('src_cache')!r} "
                f"does not match generated ID {args.source_cache_id!r}"
            )

    source = tomllib.loads(args.source.read_text(encoding="utf-8-sig"))["asset_properties"]
    translations = dict(source)
    override_count = 0
    for work_file in sorted(args.work.glob("*.toml")):
        work = tomllib.loads(work_file.read_text(encoding="utf-8-sig"))
        for key, value in work.get("asset_properties", {}).items():
            if key not in source:
                raise ValueError(f"Translation key is not in the current source cache: {key}")
            if not isinstance(value, str):
                raise ValueError(f"Translation value is not a string: {work_file}: {key}")
            translations[key] = normalize_bulgarian_text(value)
            override_count += 1

    root = args.overlay / "localization"
    shutil.copyfile(l10n_template, root / "l10n.meta.toml")
    write_table(root / "source_caches" / "bul.meta.toml", args.source_cache_id, "L10nSourceCache", source)
    write_table(root / "translations" / "bul.meta.toml", args.translation_id, "L10nTarget", translations)
    print(f"Built {len(source)} source keys and {override_count} Bulgarian overrides")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
