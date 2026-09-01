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
    r"(?:\$[^$\r\n]+\$|=[^=\r\n]+=|\[[^\]\r\n]+\]|\{[^}\r\n]+\}|%(?!\s+[sdif])[-+#0 ]*\d*(?:\.\d+)?[sdif]|"
    r"\\[nrt\\\"']|</?[^>]+>|\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*)"
)

# These constructs are deliberately excluded from the human-language scan.
# The contents of $...$ and =...= markers are not excluded: translated item
# and location names may be inside them, and leftover English there should be
# reported rather than hidden.
TECHNICAL_TEXT_RE = re.compile(
    r"(?:\[[^\]\r\n]+\]|\{[^}\r\n]+\}|%(?!\s+[sdif])[-+#0 ]*\d*(?:\.\d+)?[sdif]|"
    r"\\[nrt\\\"']|</?(?:he|she|they|else)>|\$\{[^}]+\})"
)
LATIN_RE = re.compile(r"[A-Za-z]")
ALLOWED_LATIN_RE = re.compile(
    r"(?<=\d)x(?=\d)|\b(?:VRR|NVidia|AMD|FreeSync|VSync|Xbox|Nintendo|"
    r"Steam Deck|FPS|NPC Studio|Sync)\b"
)
PRONOUN_TAGS = {"<he>", "</he>", "<she>", "</she>", "<they>", "</they>"}
INTENTIONAL_EMPTY_KEYS = {"misc_local/empty_string"}
INTENTIONAL_PLACEHOLDER_MISMATCHES = {
    # English exposes additional <it>/<none> branches here; Bulgarian uses
    # its supported he/she/they variants after a context review.
    "Conversations/Bank/Eiland/Relationship Lines/Relationship/post_8h_lines_romantic/eiland_post_8h_romantic_0/3",
    # Source has an <else> branch, but Bulgarian intentionally exposes only
    # he/she/they; the runtime test showed that <else> is not a usable fallback.
    "Conversations/gameplay_triggered/inspect_dragonsworn_tablet/2",
}
GENDER_BRANCH_RE = re.compile(
    r"<he>(?P<he>.*?)</he><she>(?P<she>.*?)</she><they>(?P<they>.*?)</they>",
    re.DOTALL,
)
GENDER_TAG_RE = re.compile(r"</?(?:he|she|they)>")
PLAYER_ADDRESS_RE = re.compile(r"\b(?:you|your|yours|yourself)\b", re.IGNORECASE)

# These are review candidates, not automatic errors. They capture known
# high-risk literal translations and terminology drift without pretending that
# a script can judge every Bulgarian sentence semantically.
SEMANTIC_CANDIDATES = (
    ("misc_local/pet", re.compile(r"\bЛюбимец\b"), "Pet is an action here; review as a verb such as Погали."),
    ("misc_local/inspect", re.compile(r"\bРазглеждане\b"), "Review the UI action; Преглед is the current choice."),
    ("misc_local/offer", re.compile(r"\bПредложи\b"), "Review altar/statue context; Принеси is the current choice."),
    (None, re.compile(r"Плоча естествено образувано стъкло"), "Literal glass description; review natural Bulgarian wording."),
    (None, re.compile(r"есенциални прилепи"), "Review named Essence Bat terminology; current choice is прилеп на есенцията."),
    (None, re.compile(r"\bБичи рог\b"), "Review item naming; current choice is Рог от бик."),
    (None, re.compile(r"Закачи заклинание"), "Review short UI label; current choice is Закачи."),
    (None, re.compile(r"да убива мигновено"), "Review infinitive aspect; source describes a chance to убие мигновено."),
    (None, re.compile(r"\b(?:Айленд|Айланд)\b"), "Review legacy Eiland spelling; approved project form is Ейланд."),
)


def load_table(path: Path) -> dict[str, str]:
    data = tomllib.loads(path.read_text(encoding="utf-8-sig"))
    table = data.get("asset_properties")
    if not isinstance(table, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in table.items()):
        raise ValueError(f"{path}: expected a flat [asset_properties] string table")
    return table


def tokens(value: str) -> Counter[str]:
    normalized: list[str] = []
    for token in TOKEN_RE.findall(value):
        if token in PRONOUN_TAGS:
            # Bulgarian intentionally adds player-variant branches that are
            # absent from the English source; those are checked separately.
            continue
        if token.startswith("$") and token.endswith("$"):
            normalized.append("$<marker>$")
        elif token.startswith("=") and token.endswith("="):
            normalized.append("=<marker>=")
        else:
            normalized.append(token)
    return Counter(normalized)


def tokens_compatible(source: Counter[str], translation: Counter[str]) -> bool:
    """Allow technical tokens to repeat inside the three player branches."""
    if set(translation) - set(source):
        return False
    return all(
        source_token_count <= translation.get(token, 0) <= source_token_count * 3
        for token, source_token_count in source.items()
    )


def latin_warnings(table: dict[str, str]) -> list[dict[str, object]]:
    warnings: list[dict[str, object]] = []
    for key, value in table.items():
        visible = TECHNICAL_TEXT_RE.sub("", value)
        visible = ALLOWED_LATIN_RE.sub("", visible)
        letters = sorted(set(LATIN_RE.findall(visible)))
        if letters:
            warnings.append({"key": key, "letters": letters, "value": value})
    return warnings


def semantic_candidates(table: dict[str, str]) -> list[dict[str, object]]:
    warnings: list[dict[str, object]] = []
    for key, value in table.items():
        for expected_key, pattern, reason in SEMANTIC_CANDIDATES:
            if expected_key is not None and key != expected_key:
                continue
            if pattern.search(value):
                warnings.append({"key": key, "reason": reason, "value": value})
    return warnings


def style_candidates(table: dict[str, str]) -> list[dict[str, object]]:
    warnings: list[dict[str, object]] = []
    for key, value in table.items():
        tags = GENDER_TAG_RE.findall(value)
        if not tags:
            continue
        branch_matches = list(GENDER_BRANCH_RE.finditer(value))
        if len(branch_matches) > 1:
            warnings.append({
                "key": key,
                "kind": "multiple_gender_triples",
                "reason": "More than one he/she/they triple; review whether branches can be grouped.",
                "value": value,
            })
        if any(tags.count(open_tag) != tags.count(close_tag) for open_tag, close_tag in (
            ("<he>", "</he>"), ("<she>", "</she>"), ("<they>", "</they>"))):
            warnings.append({
                "key": key,
                "kind": "unbalanced_gender_tags",
                "reason": "Gender tags are not balanced.",
                "value": value,
            })
        for match in branch_matches:
            punctuation = sorted(set(char for char in match.group(0) if char in ".!?"))
            if punctuation:
                warnings.append({
                    "key": key,
                    "kind": "punctuation_inside_gender_triple",
                    "reason": "Review sentence punctuation inside the gender branches; it may belong outside the tags.",
                    "punctuation": punctuation,
                    "value": value,
                })
    return warnings


def gender_review_candidates(
    source: dict[str, str], translation: dict[str, str]
) -> list[dict[str, object]]:
    """Find translated dialogue that may need player-agreement review."""
    warnings: list[dict[str, object]] = []
    for key, value in translation.items():
        if key not in source or "/prompts/" in key:
            continue
        if source[key] == value or not PLAYER_ADDRESS_RE.search(source[key]):
            continue
        if GENDER_TAG_RE.search(value):
            continue
        if not key.startswith(("Conversations/", "Cutscenes/")):
            continue
        warnings.append({
            "key": key,
            "kind": "possible_missing_gender_variants",
            "reason": "English addresses the player, but the Bulgarian line has no he/she/they branches; review context and agreement.",
            "value": value,
        })
    return warnings


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
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
    empty = sorted(
        k for k, value in translation.items()
        if not value and k not in INTENTIONAL_EMPTY_KEYS
    )
    # The package builder fills untranslated entries with the English source.
    # Keep those entries visible in the report, but do not mistake them for
    # Bulgarian QA failures while the project is still incomplete.
    unchanged_from_source = sorted(
        key for key in set(source) & set(translation)
        if source[key] == translation[key]
    )
    translated = {
        key: translation[key]
        for key in set(source) & set(translation)
        if source[key] != translation[key]
    }
    mismatches = sorted(
        key for key in translated
        if key not in INTENTIONAL_PLACEHOLDER_MISMATCHES
        and not tokens_compatible(tokens(source[key]), tokens(translation[key]))
    )
    latin = latin_warnings(translated)
    semantic = semantic_candidates(translated)
    style = style_candidates(translated)
    gender_review = gender_review_candidates(source, translated)
    long_lines = [
        {"key": key, "max_length": max(map(len, value.splitlines() or [value]))}
        for key, value in translated.items()
        if max(map(len, value.splitlines() or [value])) > args.max_line_length
    ]
    report = {
        "source_entries": len(source),
        "translation_entries": len(translation),
        "missing_keys": missing,
        "extra_keys": extra,
        "empty_translations": empty,
        "unchanged_from_source": unchanged_from_source,
        "translated_entries_checked": len(translated),
        "placeholder_mismatches": mismatches,
        "latin_letter_warnings": latin,
        "semantic_review_candidates": semantic,
        "style_review_candidates": style,
        "gender_review_candidates": gender_review,
        "line_length_warnings": long_lines,
        "status": "fail" if extra or mismatches or latin else "pass",
    }
    console_report = dict(report)
    if not args.verbose:
        for name in ("missing_keys", "extra_keys", "empty_translations", "unchanged_from_source", "placeholder_mismatches", "latin_letter_warnings", "semantic_review_candidates", "style_review_candidates", "gender_review_candidates", "line_length_warnings"):
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
