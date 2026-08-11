#!/usr/bin/env python3
"""Stage only the runtime files needed by the Bulgarian release workflow."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path


PACKAGE_ROOTS = ("manifest.toml", "animations", "fiddle", "gml", "localization")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mod-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    source = args.mod_root.resolve()
    output = args.output.resolve()
    if output.exists():
        raise FileExistsError(f"Refusing to replace existing release package: {output}")

    output.mkdir(parents=True)
    for name in PACKAGE_ROOTS:
        item = source / name
        if not item.exists():
            raise FileNotFoundError(f"Required runtime input is missing: {item}")
        destination = output / name
        if item.is_dir():
            shutil.copytree(item, destination)
        else:
            shutil.copy2(item, destination)
    print(f"Staged release package: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
