from __future__ import annotations

import hashlib
import json
import re
import tomllib
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "localization_inspection" / "extracted" / "assets" / "localization"

def walk(value, path=()):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk(child, path + (str(key),))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, path + (str(index),))
    else:
        yield path, value

def summarize(value):
    if isinstance(value, dict):
        return {"type": "table", "keys": list(value), "count": len(value)}
    if isinstance(value, list):
        return {"type": "array", "length": len(value), "item_types": sorted({type(x).__name__ for x in value})}
    return {"type": type(value).__name__}

def main():
    files = sorted(ROOT.rglob("*.toml"))
    parsed = {p: tomllib.loads(p.read_text(encoding="utf-8-sig")) for p in files}
    meta = parsed[ROOT / "l10n.meta.toml"]
    print("META_LANGUAGES", json.dumps(list(meta["asset_properties"]["languages"]), ensure_ascii=False))
    source = {"/".join(path): value for path, value in walk(parsed[ROOT / "source_caches" / "fra.meta.toml"]["asset_properties"]) if isinstance(value, str)}
    print("SOURCE_ENTRIES", len(source))
    print("META_LANGUAGE_DETAILS", json.dumps({code: {k: v for k, v in rec.items() if k not in {"pronouns", "pronoun_display_order"}} for code, rec in meta["asset_properties"]["languages"].items()}, ensure_ascii=False, sort_keys=True))

    def raw_duplicate_keys(path):
        seen = Counter()
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            match = re.match(r'^\s*(?:"([^"]+)"|([A-Za-z0-9_-]+))\s*=', line)
            if match:
                seen[match.group(1) or match.group(2)] += 1
        return {k: n for k, n in seen.items() if n > 1}

    token_re = re.compile(r"(?:\[[^\]\n]+\]|\{[^}\n]+\}|%[-+#0 ]*\d*(?:\.\d+)?[sdif]|\\[nrt\\\"']|<[^>]+>|\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*)")
    def token_counts(values):
        c = Counter()
        for value in values:
            c.update(token_re.findall(value))
        return dict(sorted(c.items()))

    all_stats = {"source_entries": len(source), "translations": {}, "source_caches": {}, "duplicate_keys": {}, "token_counts": {}, "token_mismatches": {}}
    pattern_summary = {}
    patterns = {
        "bracket_placeholders": re.compile(r"\[[^\]\r\n]+\]"),
        "markup_tags": re.compile(r"</?[^>]+>"),
        "escape_sequences": re.compile(r"\\\\[nrt\\\"']"),
        "printf_tokens": re.compile(r"%[-+#0 ]*\d*(?:\.\d+)?[sdif]"),
        "dollar_tokens": re.compile(r"(?<![A-Za-z0-9])\$[A-Za-z_][A-Za-z0-9_]*"),
    }
    for name, rx in patterns.items():
        counter = Counter()
        entry_count = 0
        for value in source.values():
            found = rx.findall(value)
            if found: entry_count += 1; counter.update(found)
        pattern_summary[name] = {"entries": entry_count, "occurrences": sum(counter.values()), "patterns": dict(sorted(counter.items()))}
    all_stats["source_pattern_summary"] = pattern_summary
    all_stats["source_structural_key_counts"] = {name: sum(1 for key in source if re.search(pattern, key, re.IGNORECASE)) for name, pattern in {"plural": r"plural|quantity|count", "gender": r"gender|female|male|pronoun", "variant": r"variant|variants|alternative|option"}.items()}
    for kind in ("translations", "source_caches"):
        for p in sorted((ROOT / kind).glob("*.toml")):
            d = parsed[p]["asset_properties"]
            values = list(d.values())
            keys = set(d)
            all_stats[kind][p.stem] = {"entries": len(d), "missing_from_source": len(set(source) - keys), "extra_not_in_source": len(keys - set(source)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "token_counts": token_counts(values)}
            dupes = raw_duplicate_keys(p)
            if dupes:
                all_stats["duplicate_keys"][str(p.relative_to(ROOT))] = dupes
            if kind == "translations":
                all_stats["token_mismatches"][p.stem] = sorted(k for k in source.keys() & keys if Counter(token_re.findall(source[k])) != Counter(token_re.findall(d[k])))
    out = ROOT.parents[2] / "localization_analysis.json"
    out.write_text(json.dumps(all_stats, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"translations": {k: {a: v[a] for a in ("entries", "missing_from_source", "extra_not_in_source")} for k, v in all_stats["translations"].items()}, "source_caches": {k: {a: v[a] for a in ("entries", "missing_from_source", "extra_not_in_source")} for k, v in all_stats["source_caches"].items()}, "duplicates": all_stats["duplicate_keys"], "token_mismatch_counts": {k: len(v) for k, v in all_stats["token_mismatches"].items()}}, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
