#!/usr/bin/env python3
"""Prepare ignored Bulgarian translation work files from a current assets.zip."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tomllib
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("archive", type=Path)
    ap.add_argument("--work", type=Path, default=Path("translation/source_keys"))
    args = ap.parse_args()
    inspection = args.work / ".." / ".." / "localization_inspection"
    subprocess.run([sys.executable, str(Path(__file__).with_name("inspect_fom_localization.py")), str(args.archive), "--extract", "--output", str(inspection)], check=True)
    root = inspection / "extracted" / "assets" / "localization"
    candidates = sorted((root / "source_caches").glob("*.meta.toml"))
    if not candidates: raise RuntimeError("No source cache was extracted")
    # The game has no separate English source-cache file. In the inspected
    # 1.0 archive, fra.meta.toml is the complete cache whose values are the
    # English source strings. Do not choose by byte size: some translated
    # caches contain extra keys and are not the canonical source set.
    source_path = root / "source_caches" / "fra.meta.toml"
    if not source_path.exists():
        raise RuntimeError("The canonical English source cache fra.meta.toml is missing")
    source = tomllib.loads(source_path.read_text(encoding="utf-8-sig"))["asset_properties"]
    args.work.mkdir(parents=True, exist_ok=True)
    out = args.work / "source_keys.jsonl"
    with out.open("w", encoding="utf-8", newline="\n") as f:
        for key in sorted(source):
            f.write(json.dumps({"key": key, "source": source[key], "translation": "", "status": "untranslated"}, ensure_ascii=False) + "\n")
    print(f"Prepared {len(source)} source keys in {out}")
    return 0

if __name__ == "__main__": raise SystemExit(main())
