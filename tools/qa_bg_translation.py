#!/usr/bin/env python3
"""Validate a Bulgarian translation table against the canonical source cache."""
from __future__ import annotations

import argparse
import json
import re
import sys
import tomllib
from collections import Counter
from pathlib import Path

TOKEN_RE = re.compile(
    r"(?:\[[^\]\r\n]+\]|\{[^}\r\n]+\}|%[-+#0 ]*\d*(?:\.\d+)?[sdif]|"
    r"\\[nrt\\\"']|</?[^>]+>|\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*)"
)


def load_table(path: Path) -> dict[str, str]:
    data = tomllib.loads(path.read_text(encoding="utf-8-sig"))
    table = data.get("asset_properties")
    if not isinstance(table, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in table.items()):
        raise ValueError(f"{path}: expected a flat [asset_properties] string table")
    return table


def tokens(value: str) -> Counter[str]:
    return Counter(TOKEN_RE.findall(value))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="canonical English source cache")
    parser.add_argument("translation", type=Path, help="Bulgarian translation table")
    parser.add_argument("--json", type=Path, help="write a JSON QA report")
    parser.add_argument("--verbose", action="store_true", help="print complete key lists")
    parser.add_argument("--max-line-length", type=int, default=70, help="warn when a rendered line exceeds this length")
    args = parser.parse_args()

    source = load_table(args.source)
    translation = load_table(args.translation)
    missing = sorted(set(source) - set(translation))
    extra = sorted(set(translation) - set(source))
    empty = sorted(k for k, value in translation.items() if not value)
    mismatches = sorted(
        key for key in set(source) & set(translation)
        if tokens(source[key]) != tokens(translation[key])
    )
    long_lines = [
        {"key": key, "max_length": max(map(len, value.splitlines() or [value]))}
        for key, value in translation.items()
        if max(map(len, value.splitlines() or [value])) > args.max_line_length
    ]
    report = {
        "source_entries": len(source),
        "translation_entries": len(translation),
        "missing_keys": missing,
        "extra_keys": extra,
        "empty_translations": empty,
        "placeholder_mismatches": mismatches,
        "line_length_warnings": long_lines,
        "status": "fail" if extra or mismatches else "pass",
    }
    console_report = dict(report)
    if not args.verbose:
        for name in ("missing_keys", "extra_keys", "empty_translations", "placeholder_mismatches", "line_length_warnings"):
            console_report[name] = {
                "count": len(report[name]),
                "sample": report[name][:10],
            }
    print(json.dumps(console_report, ensure_ascii=False, indent=2))
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 1 if report["status"] == "fail" else 0


if __name__ == "__main__":
    raise SystemExit(main())
