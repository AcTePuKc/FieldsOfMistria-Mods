#!/usr/bin/env python
"""
Inspect Fields of Mistria 1.0 localization data inside assets.zip.

The script is intentionally read-only. It does not modify assets.zip.

Usage:
    python inspect_fom_localization.py "C:\path\to\Fields of Mistria\assets.zip"

Optional:
    python inspect_fom_localization.py "C:\path\to\assets.zip" --extract
    python inspect_fom_localization.py "C:\path\to\assets.zip" --output inspection

Python:
    3.11 or newer, because TOML parsing uses the standard-library tomllib module.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
import tomllib
import zipfile
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


LOCALIZATION_ROOT = PurePosixPath("assets/localization")
TRANSLATIONS_ROOT = LOCALIZATION_ROOT / "translations"
SOURCE_CACHES_ROOT = LOCALIZATION_ROOT / "source_caches"
META_FILE = LOCALIZATION_ROOT / "l10n.meta.toml"


@dataclass
class FileInfo:
    path: str
    size: int
    compressed_size: int
    sha256: str
    suffix: str
    category: str
    parse_status: str = "not parsed"
    top_level_type: str | None = None
    item_count: int | None = None
    notes: list[str] = field(default_factory=list)


@dataclass
class InspectionReport:
    archive: str
    archive_size: int
    archive_sha256: str
    localization_root_found: bool
    meta_file_found: bool
    translation_files: list[str]
    source_cache_files: list[str]
    other_localization_files: list[str]
    suffix_counts: dict[str, int]
    language_candidates: dict[str, list[str]]
    meta: Any = None
    files: list[FileInfo] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect Fields of Mistria localization files stored in assets.zip."
    )
    parser.add_argument(
        "archive",
        type=Path,
        help="Path to the game's assets.zip archive.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("localization_inspection"),
        help="Output directory. Default: localization_inspection",
    )
    parser.add_argument(
        "--extract",
        action="store_true",
        help="Extract assets/localization into the output directory.",
    )
    parser.add_argument(
        "--sample-limit",
        type=int,
        default=20,
        help="Maximum number of sample records written per parsed file. Default: 20",
    )
    return parser.parse_args()


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def is_under(path: PurePosixPath, root: PurePosixPath) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def classify(path: PurePosixPath) -> str:
    if path == META_FILE:
        return "metadata"
    if is_under(path, TRANSLATIONS_ROOT):
        return "translation"
    if is_under(path, SOURCE_CACHES_ROOT):
        return "source_cache"
    if is_under(path, LOCALIZATION_ROOT):
        return "other_localization"
    return "other"


def decode_text(data: bytes) -> tuple[str | None, str]:
    encodings = ("utf-8-sig", "utf-8", "utf-16", "utf-16-le", "utf-16-be")
    for encoding in encodings:
        try:
            return data.decode(encoding), encoding
        except UnicodeDecodeError:
            continue
    return None, "binary-or-unknown"


def count_nested_items(value: Any) -> int:
    if isinstance(value, dict):
        return sum(count_nested_items(item) for item in value.values()) + len(value)
    if isinstance(value, list):
        return sum(count_nested_items(item) for item in value) + len(value)
    return 1


def make_json_safe(value: Any) -> Any:
    if isinstance(value, dict):
        return {str(key): make_json_safe(item) for key, item in value.items()}
    if isinstance(value, list):
        return [make_json_safe(item) for item in value]
    if isinstance(value, tuple):
        return [make_json_safe(item) for item in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    return repr(value)


def sample_value(value: Any, limit: int) -> Any:
    if isinstance(value, dict):
        return {
            str(key): sample_value(item, limit)
            for key, item in list(value.items())[:limit]
        }
    if isinstance(value, list):
        return [sample_value(item, limit) for item in value[:limit]]
    return make_json_safe(value)


def inspect_structured_file(
    path: PurePosixPath,
    data: bytes,
    sample_limit: int,
) -> tuple[str, str | None, int | None, list[str], Any | None]:
    suffix = path.suffix.lower()
    notes: list[str] = []
    text, encoding = decode_text(data)

    if text is None:
        return "binary-or-unknown", None, None, notes, None

    notes.append(f"encoding={encoding}")

    try:
        if suffix == ".toml":
            parsed = tomllib.loads(text)
            return (
                "parsed",
                type(parsed).__name__,
                count_nested_items(parsed),
                notes,
                sample_value(parsed, sample_limit),
            )

        if suffix == ".json":
            parsed = json.loads(text)
            return (
                "parsed",
                type(parsed).__name__,
                len(parsed) if hasattr(parsed, "__len__") else 1,
                notes,
                sample_value(parsed, sample_limit),
            )

        if suffix == ".jsonl":
            rows = []
            for line_number, line in enumerate(text.splitlines(), start=1):
                if not line.strip():
                    continue
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError as exc:
                    notes.append(f"invalid JSON on line {line_number}: {exc}")
                    return "parse-error", "jsonl", len(rows), notes, rows[:sample_limit]
            return "parsed", "jsonl", len(rows), notes, rows[:sample_limit]

        if suffix in {".csv", ".tsv"}:
            delimiter = "\t" if suffix == ".tsv" else ","
            rows = list(csv.reader(text.splitlines(), delimiter=delimiter))
            return "parsed", "table", len(rows), notes, rows[:sample_limit]

        if suffix in {".txt", ".lang", ".po", ".yaml", ".yml", ".ron"}:
            lines = text.splitlines()
            return "text", "text", len(lines), notes, lines[:sample_limit]

        return "text-unclassified", "text", len(text.splitlines()), notes, text[:4000]

    except (tomllib.TOMLDecodeError, json.JSONDecodeError, csv.Error) as exc:
        notes.append(str(exc))
        return "parse-error", None, None, notes, text[:4000]


def infer_language_candidates(paths: Iterable[PurePosixPath]) -> dict[str, list[str]]:
    candidates: dict[str, list[str]] = {}

    for path in paths:
        try:
            relative = path.relative_to(TRANSLATIONS_ROOT)
        except ValueError:
            continue

        parts = relative.parts
        if not parts:
            continue

        possible_codes: set[str] = set()

        if len(parts) > 1:
            possible_codes.add(parts[0])

        stem_parts = PurePosixPath(parts[-1]).stem.replace("-", "_").split("_")
        for part in stem_parts:
            normalized = part.lower()
            if 2 <= len(normalized) <= 8 and normalized.isalpha():
                possible_codes.add(normalized)

        for code in sorted(possible_codes):
            candidates.setdefault(code, []).append(path.as_posix())

    return dict(sorted(candidates.items()))


def safe_extract_member(
    archive: zipfile.ZipFile,
    member: zipfile.ZipInfo,
    destination: Path,
) -> Path:
    relative = PurePosixPath(member.filename)

    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Unsafe ZIP member path: {member.filename}")

    target = destination.joinpath(*relative.parts)
    target.parent.mkdir(parents=True, exist_ok=True)

    if member.is_dir():
        target.mkdir(parents=True, exist_ok=True)
    else:
        with archive.open(member, "r") as source, target.open("wb") as output:
            while chunk := source.read(1024 * 1024):
                output.write(chunk)

    return target


def write_text_summary(report: InspectionReport, output_path: Path) -> None:
    lines = [
        "Fields of Mistria localization inspection",
        "=" * 42,
        f"Archive: {report.archive}",
        f"Archive size: {report.archive_size:,} bytes",
        f"Archive SHA-256: {report.archive_sha256}",
        f"Localization root found: {report.localization_root_found}",
        f"Metadata found: {report.meta_file_found}",
        "",
        f"Translation files: {len(report.translation_files)}",
        f"Source cache files: {len(report.source_cache_files)}",
        f"Other localization files: {len(report.other_localization_files)}",
        "",
        "File suffixes:",
    ]

    for suffix, count in sorted(report.suffix_counts.items()):
        lines.append(f"  {suffix or '<no suffix>'}: {count}")

    lines.extend(["", "Possible language identifiers:"])
    for code, paths in report.language_candidates.items():
        lines.append(f"  {code}: {len(paths)} file(s)")

    lines.extend(["", "Files:"])
    for info in report.files:
        lines.append(
            f"  [{info.category}] {info.path} | "
            f"{info.size:,} bytes | {info.parse_status}"
        )
        for note in info.notes:
            lines.append(f"      {note}")

    if report.warnings:
        lines.extend(["", "Warnings:"])
        lines.extend(f"  - {warning}" for warning in report.warnings)

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    archive_path = args.archive.expanduser().resolve()
    output_dir = args.output.expanduser().resolve()

    if sys.version_info < (3, 11):
        print("Python 3.11 or newer is required.", file=sys.stderr)
        return 2

    if not archive_path.is_file():
        print(f"Archive not found: {archive_path}", file=sys.stderr)
        return 2

    if not zipfile.is_zipfile(archive_path):
        print(f"Not a valid ZIP archive: {archive_path}", file=sys.stderr)
        return 2

    output_dir.mkdir(parents=True, exist_ok=True)
    samples_dir = output_dir / "samples"
    samples_dir.mkdir(parents=True, exist_ok=True)

    archive_hash = sha256_file(archive_path)

    with zipfile.ZipFile(archive_path, "r") as archive:
        members = [
            member
            for member in archive.infolist()
            if not member.is_dir()
        ]

        localization_members = [
            member
            for member in members
            if is_under(PurePosixPath(member.filename), LOCALIZATION_ROOT)
        ]

        translation_paths: list[PurePosixPath] = []
        source_cache_paths: list[PurePosixPath] = []
        other_paths: list[PurePosixPath] = []
        file_infos: list[FileInfo] = []
        meta: Any = None
        warnings: list[str] = []

        for member in localization_members:
            path = PurePosixPath(member.filename)
            category = classify(path)

            if category == "translation":
                translation_paths.append(path)
            elif category == "source_cache":
                source_cache_paths.append(path)
            elif category != "metadata":
                other_paths.append(path)

            data = archive.read(member)
            parse_status, top_level_type, item_count, notes, sample = (
                inspect_structured_file(path, data, args.sample_limit)
            )

            info = FileInfo(
                path=path.as_posix(),
                size=member.file_size,
                compressed_size=member.compress_size,
                sha256=sha256_bytes(data),
                suffix=path.suffix.lower(),
                category=category,
                parse_status=parse_status,
                top_level_type=top_level_type,
                item_count=item_count,
                notes=notes,
            )
            file_infos.append(info)

            if path == META_FILE:
                if parse_status == "parsed":
                    text, _ = decode_text(data)
                    assert text is not None
                    meta = make_json_safe(tomllib.loads(text))
                else:
                    warnings.append("l10n.meta.toml exists but could not be parsed.")

            if sample is not None:
                sample_name = path.as_posix().replace("/", "__") + ".sample.json"
                sample_path = samples_dir / sample_name
                sample_path.write_text(
                    json.dumps(make_json_safe(sample), ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )

        suffix_counts = Counter(
            PurePosixPath(member.filename).suffix.lower()
            for member in localization_members
        )

        report = InspectionReport(
            archive=str(archive_path),
            archive_size=archive_path.stat().st_size,
            archive_sha256=archive_hash,
            localization_root_found=bool(localization_members),
            meta_file_found=any(
                PurePosixPath(member.filename) == META_FILE
                for member in localization_members
            ),
            translation_files=sorted(path.as_posix() for path in translation_paths),
            source_cache_files=sorted(path.as_posix() for path in source_cache_paths),
            other_localization_files=sorted(path.as_posix() for path in other_paths),
            suffix_counts=dict(sorted(suffix_counts.items())),
            language_candidates=infer_language_candidates(translation_paths),
            meta=meta,
            files=sorted(file_infos, key=lambda item: item.path),
            warnings=warnings,
        )

        if not report.localization_root_found:
            report.warnings.append(
                "No files were found below assets/localization."
            )

        if not report.meta_file_found:
            report.warnings.append(
                "assets/localization/l10n.meta.toml was not found."
            )

        if args.extract:
            extraction_root = output_dir / "extracted"
            for member in archive.infolist():
                member_path = PurePosixPath(member.filename)
                if is_under(member_path, LOCALIZATION_ROOT):
                    safe_extract_member(archive, member, extraction_root)

    json_path = output_dir / "localization_report.json"
    text_path = output_dir / "localization_report.txt"

    json_path.write_text(
        json.dumps(asdict(report), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    write_text_summary(report, text_path)

    print(f"Inspection complete.")
    print(f"JSON report: {json_path}")
    print(f"Text report: {text_path}")
    print(f"Translation files: {len(report.translation_files)}")
    print(f"Source cache files: {len(report.source_cache_files)}")
    print(f"Metadata found: {report.meta_file_found}")

    if args.extract:
        print(f"Extracted localization: {output_dir / 'extracted' / 'assets' / 'localization'}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
