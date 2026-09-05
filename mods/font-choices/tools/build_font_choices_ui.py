"""Build Font Choices' runtime UI catalog from one TOML per language."""
from __future__ import annotations

import argparse
import json
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "localization" / "ui"
LEGACY_SOURCE = ROOT / "localization" / "font-choices-ui.toml"
OUTPUT = ROOT / "gml" / "FontChoicesUI.generated.gml"


def gml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def write_language_files(catalog: dict[str, dict[str, str]]) -> None:
    UI_DIR.mkdir(parents=True, exist_ok=True)
    for language, labels in catalog.items():
        content = "# Font Choices UI translation: edit this language only.\n[ui]\n"
        content += "".join(f"{key} = {json.dumps(value, ensure_ascii=False)}\n" for key, value in labels.items())
        (UI_DIR / f"{language}.toml").write_text(content, encoding="utf-8", newline="\n")


def load_catalog() -> dict[str, dict[str, str]]:
    catalog: dict[str, dict[str, str]] = {}
    for path in sorted(UI_DIR.glob("*.toml")):
        values = tomllib.loads(path.read_text(encoding="utf-8")).get("ui")
        if not isinstance(values, dict) or not values:
            raise SystemExit(f"{path} must contain a non-empty [ui] table.")
        catalog[path.stem] = {key: str(value) for key, value in values.items()}
    if "eng" not in catalog:
        raise SystemExit("localization/ui/eng.toml must define the English fallback.")
    return catalog


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--split-legacy", action="store_true", help="Create localization/ui/<language>.toml from the old combined catalog.")
    args = parser.parse_args()
    if args.split_legacy:
        legacy = tomllib.loads(LEGACY_SOURCE.read_text(encoding="utf-8"))
        write_language_files({language: dict(labels) for language, labels in legacy.items() if isinstance(labels, dict)})

    catalog = load_catalog()
    english = catalog["eng"]
    lines = ["// Generated from localization/ui/*.toml; do not edit by hand.", "function fc_ui_catalog(_language) {", "    static _catalog = {"]
    for language, values in catalog.items():
        labels = dict(english)
        labels.update(values)
        entries = ", ".join(f"{key}: {gml_string(value)}" for key, value in labels.items())
        lines.append(f"        {language}: {{ {entries} }},")
    lines.extend(["    };", "    var _labels = _catalog[$ _language];", "    return _labels == undefined ? _catalog.eng : _labels;", "}", ""])
    OUTPUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
