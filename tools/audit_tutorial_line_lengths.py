#!/usr/bin/env python3
"""List visible Bulgarian tutorial lines that need an in-game width check."""
from __future__ import annotations

import argparse
import tomllib
from collections import defaultdict
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--max-chars", type=int, default=34)
    args = parser.parse_args()

    findings: dict[str, list[tuple[str, int, int, str]]] = defaultdict(list)
    for path in sorted(args.work.glob("*.toml")):
        data = tomllib.loads(path.read_text(encoding="utf-8"))
        for key, value in data.get("asset_properties", {}).items():
            if "/tutorial" not in key.lower():
                continue
            for line_number, line in enumerate(value.splitlines(), start=1):
                if len(line) > args.max_chars:
                    findings[path.name].append((key, line_number, len(line), line))

    lines = [
        "# Уроци за ръчен преглед на ширината",
        "",
        f"Правило: редове над **{args.max_chars} символа** се проверяват в играта, "
        "но не се съкращават автоматично.",
        "",
        f"Общо маркирани редове: **{sum(map(len, findings.values()))}**.",
    ]
    for filename, entries in findings.items():
        lines.extend(["", f"## `{filename}`", ""])
        for key, number, count, text in entries:
            lines.append(f"- `{key}`, ред {number}: **{count}** - {text}")
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {sum(map(len, findings.values()))} findings to {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
