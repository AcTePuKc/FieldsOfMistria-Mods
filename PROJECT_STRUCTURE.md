# Proposed project structure

```text
FieldsofMistria_Bulgarian/
├─ FINDINGS.md
├─ PROJECT_STRUCTURE.md
├─ tools/
│  ├─ inspect_fom_localization.py
│  ├─ analyze_fom_localization.py
│  └─ inject_fom_localization.py
├─ poc/
│  ├─ manifest.toml
│  └─ localization/
│     ├─ l10n.meta.toml
│     ├─ translations/bul.meta.toml
│     └─ source_caches/bul.meta.toml
├─ source/
│  └─ extracted-at-runtime/             # ignored; never committed
├─ translation/
│  ├─ source_keys/                      # generated working data, ignored
│  ├─ Bulgarian/                        # translator-owned files
│  └─ qa_reports/                       # generated reports, ignored
└─ runtime/                             # ignored archives, backups, state
```

The full workflow should extract source keys from the currently detected archive hash, create Bulgarian source-cache and translation work files, validate protected tokens before packaging, and then invoke the standalone injector. MOMI packaging can remain an optional distribution format, but archive mutation should stay behind the safety-checked injector until MOMI provides equivalent guarantees.

