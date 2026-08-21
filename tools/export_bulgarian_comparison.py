"""Export comparison TSVs grouped deterministically by localization key prefix."""

from __future__ import annotations

import csv
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_FILE = ROOT / "mods/bulgarian-localization/package/localization/translations/bul.meta.toml"
WORK_DIRECTORY = ROOT / "mods/bulgarian-localization/translation/work"
LOCALIZATION_ROOT = ROOT / "localization_inspection/extracted/assets/localization"
OUTPUT_DIRECTORY = ROOT / "translation" / "review"
COLUMNS = ("key", "english", "french", "russian", "bulgarian")


def category_for_key(key: str) -> str:
    """Choose a stable, human-readable TSV category from the key prefix."""
    if key.startswith(("Conversations/", "Cutscenes/", "letters/")):
        return "dialogue"
    if key.startswith("items/"):
        return "items"
    if key.startswith("quests/"):
        return "quests"
    if key.startswith("ui/tutorials/"):
        return "tutorials"
    if key.startswith("ui/"):
        return "ui"
    if key.startswith("locations/"):
        return "locations"
    return "misc"


def load_values(path: Path) -> dict[str, str]:
    parsed = tomllib.loads(path.read_text(encoding="utf-8"))
    return parsed.get("asset_properties", parsed)


def tsv_cell(value: str) -> str:
    return value.replace("\t", "\\t").replace("\r\n", "\\n").replace("\n", "\\n")


def main() -> None:
    bulgarian = load_values(PACKAGE_FILE)
    work_files = sorted(WORK_DIRECTORY.glob("*.meta.toml"))
    for work_file in work_files:
        bulgarian.update(load_values(work_file))

    english = load_values(LOCALIZATION_ROOT / "source_caches/canonical-1.0.2.meta.toml")
    french = load_values(LOCALIZATION_ROOT / "translations/fra.meta.toml")
    russian = load_values(LOCALIZATION_ROOT / "translations/rus.meta.toml")

    categorized_rows: dict[str, list[tuple[str, str, str, str, str]]] = {}
    for key, bulgarian_value in bulgarian.items():
        category = category_for_key(key)
        categorized_rows.setdefault(category, []).append(
            (
                key,
                tsv_cell(english.get(key, "")),
                tsv_cell(french.get(key, "")),
                tsv_cell(russian.get(key, "")),
                tsv_cell(bulgarian_value),
            )
        )

    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for category, rows in sorted(categorized_rows.items()):
        output_file = OUTPUT_DIRECTORY / f"{category}.tsv"
        with output_file.open("w", encoding="utf-8-sig", newline="") as stream:
            writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
            writer.writerow(COLUMNS)
            writer.writerows(rows)
        print(f"Wrote {len(rows)} rows to {output_file}")

    print(f"Exported {len(bulgarian)} rows from {len(work_files)} work files.")


if __name__ == "__main__":
    main()
