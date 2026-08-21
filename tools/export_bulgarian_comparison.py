"""Export comparison TSVs grouped deterministically by localization key prefix."""

from __future__ import annotations

import csv
import re
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_FILE = ROOT / "mods/bulgarian-localization/package/localization/translations/bul.meta.toml"
WORK_DIRECTORY = ROOT / "mods/bulgarian-localization/translation/work"
LOCALIZATION_ROOT = ROOT / "localization_inspection/extracted/assets/localization"
OUTPUT_DIRECTORY = ROOT / "translation" / "review"
COLUMNS = ("key", "english", "french", "russian", "bulgarian")


def filename_part(value: str) -> str:
    """Turn one localization-key segment into a stable filename component."""
    value = re.sub(r"[^0-9A-Za-z]+", "_", value).strip("_").lower()
    return value or "misc"


def dialogue_category_for_key(key: str) -> str:
    """Split the large dialogue set using meaningful key segments."""
    parts = key.split("/")
    root = parts[0]

    if root == "Conversations":
        if len(parts) < 2:
            return "dialogue_conversations_misc"

        section = parts[1]
        if section == "Bank" and len(parts) >= 3:
            return f"dialogue_bank_{filename_part(parts[2])}"
        if section == "Activity Dialogue" and len(parts) >= 3:
            return f"dialogue_activity_{filename_part(parts[2])}"
        return f"dialogue_{filename_part(section)}"

    if root == "Cutscenes":
        if len(parts) >= 2:
            return f"dialogue_cutscenes_{filename_part(parts[1])}"
        return "dialogue_cutscenes_misc"

    if root == "letters":
        return "dialogue_letters"

    return "dialogue_misc"


def category_for_key(key: str) -> str:
    """Choose a stable, human-readable TSV category from the key prefix."""
    if key.startswith(("Conversations/", "Cutscenes/", "letters/")):
        return dialogue_category_for_key(key)
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

    # Remove old dialogue exports so changing the grouping cannot leave a stale
    # monolithic dialogue.tsv or obsolete dialogue chunks beside the new files.
    for stale_file in OUTPUT_DIRECTORY.glob("dialogue*.tsv"):
        stale_file.unlink()

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
