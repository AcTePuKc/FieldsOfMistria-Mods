#!/usr/bin/env python3
"""Prepare ignored Bulgarian translation work files from a current assets.zip."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tomllib
import zipfile
from pathlib import Path


PREFERRED_CACHES = ("zh-Hans", "zh-Hant", "kor", "fra", "spa", "rus", "jpn")
HIDDEN_RUNTIME_UI = {
    "misc_local/select_your_birthday": "Select Your Birthday",
    "misc_local/choose_a_vsync": "Choose VSync Mode",
    "misc_local/vsync_off": "Off",
    "misc_local/vsync_on": "On",
    "misc_local/vsync_adaptive": "Adaptive",
    "misc_local/frame_rate_cap": "Frame Rate Cap: 60 FPS",
    "misc_local/brightness": "Brightness",
    "misc_local/saturation": "Saturation",
}


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
        for key, value in sorted(values.items())
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def reconcile_source_caches(root: Path) -> tuple[dict[str, str], dict[str, object]]:
    caches: dict[str, dict[str, str]] = {}
    for path in sorted((root / "source_caches").glob("*.meta.toml")):
        language = path.name.removesuffix(".meta.toml")
        caches[language] = tomllib.loads(path.read_text(encoding="utf-8-sig"))["asset_properties"]

    if "zh-Hans" not in caches:
        raise RuntimeError("The preferred zh-Hans source cache is missing")

    merged: dict[str, str] = {}
    provenance: dict[str, str] = {}
    conflicts: list[str] = []
    for language in PREFERRED_CACHES:
        for key, value in caches.get(language, {}).items():
            if key in merged:
                if merged[key] != value:
                    conflicts.append(key)
                continue
            merged[key] = value
            provenance[key] = language

    report: dict[str, object] = {
        "preferred_cache_order": list(PREFERRED_CACHES),
        "cache_key_counts": {language: len(values) for language, values in caches.items()},
        "catalog_key_count": len(merged),
        "conflicting_value_count": len(set(conflicts)),
        "conflicting_value_keys": sorted(set(conflicts)),
        "key_provenance_counts": {
            language: sum(1 for source_language in provenance.values() if source_language == language)
            for language in PREFERRED_CACHES
        },
    }
    return merged, report


def add_runtime_supplements(source: dict[str, str], archive: Path) -> list[str]:
    """Add player-facing runtime strings that are omitted from source caches."""
    member = "assets/fiddle/ui/character_customization.toml"
    added: list[str] = []
    with zipfile.ZipFile(archive) as bundle:
        runtime_ui = tomllib.loads(bundle.read(member).decode("utf-8-sig"))
    for category, entries in runtime_ui.items():
        if not isinstance(entries, list):
            continue
        for index, entry in enumerate(entries):
            if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
                continue
            key = f"ui/character_customization/{category}/{index}/name"
            if key not in source:
                source[key] = entry["name"]
                added.append(key)
    for key, value in HIDDEN_RUNTIME_UI.items():
        if key not in source:
            source[key] = value
            added.append(key)
    return added


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("archive", type=Path)
    ap.add_argument("--work", type=Path, default=Path("mods/bulgarian-localization/translation/source_keys"))
    repo_root = Path(__file__).resolve().parents[1]
    args = ap.parse_args()
    inspection = repo_root / "localization_inspection"
    subprocess.run([sys.executable, str(Path(__file__).with_name("inspect_fom_localization.py")), str(args.archive), "--extract", "--output", str(inspection)], check=True)
    root = inspection / "extracted" / "assets" / "localization"
    if not list((root / "source_caches").glob("*.meta.toml")):
        raise RuntimeError("No source cache was extracted")
    # No single cache is complete in 1.0.2. Build a key catalog that prefers
    # zh-Hans (the largest cache) and supplements only missing keys from the
    # remaining official caches. Colliding values are recorded for review.
    source, reconciliation = reconcile_source_caches(root)
    runtime_keys = add_runtime_supplements(source, args.archive)
    reconciliation["runtime_supplement_keys"] = runtime_keys
    reconciliation["catalog_key_count"] = len(source)
    source_path = root / "source_caches" / "canonical-1.0.2.meta.toml"
    write_table(source_path, "fom-canonical-source-1.0.2", "L10nSourceCache", source)
    (inspection / "source_cache_reconciliation.json").write_text(
        json.dumps(reconciliation, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    args.work.mkdir(parents=True, exist_ok=True)
    out = args.work / "source_keys.jsonl"
    with out.open("w", encoding="utf-8", newline="\n") as f:
        for key in sorted(source):
            f.write(json.dumps({"key": key, "source": source[key], "translation": "", "status": "untranslated"}, ensure_ascii=False) + "\n")
    print(f"Prepared {len(source)} reconciled source keys in {out}")
    print(f"Canonical source catalog: {source_path}")
    return 0

if __name__ == "__main__": raise SystemExit(main())
