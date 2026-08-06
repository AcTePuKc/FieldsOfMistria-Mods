# Proposed project structure

```text
FieldsOfMistria-Mods/
├─ FINDINGS.md
├─ PROJECT_STRUCTURE.md
├─ README.md
├─ docs/
├─ tools/
│  ├─ inspect_fom_localization.py
│  ├─ analyze_fom_localization.py
│  └─ inject_fom_localization.py
├─ mods/
│  └─ bulgarian-localization/
│     └─ translation/
│        ├─ README.md
│        ├─ bul_l10n.meta.toml          # Bulgarian language/pronoun registration
│        ├─ glossary.toml
│        ├─ work/                       # translator-owned files
│        ├─ source_keys/                # generated working data, ignored
│        └─ qa_reports/                 # generated reports, ignored
└─ local-runtime/                       # ignored archives, backups, state
```

The full workflow should extract source keys from the currently detected archive hash, create Bulgarian source-cache and translation work files, validate protected tokens before packaging, and then invoke the standalone injector. MOMI packaging can remain an optional distribution format, but archive mutation should stay behind the safety-checked injector until MOMI provides equivalent guarantees.
