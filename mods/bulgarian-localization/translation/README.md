# Bulgarian localization workflow

The game has no separate English source-cache file: cache values are English
strings despite their language filenames. In Fields of Mistria 1.0.2 no single
cache contains every valid key. `tools/prepare_bg_pipeline.py` generates the
active `source_caches/canonical-1.0.2.meta.toml` catalog by preferring
`zh-Hans` and adding only keys missing from the other official caches. Value
collisions are recorded in `localization_inspection/source_cache_reconciliation.json`.

The working translation is kept outside generated archive output. The normal
workflow is:

1. Prepare source keys from the current `assets.zip` with
   `tools/prepare_bg_pipeline.py`.
2. Translate only player-facing values in the generated Bulgarian work file.
3. Build a temporary merge from every file in `translation/work/` with
   `tools/build_bg_overlay.py`; do not QA the stale generated package.
4. Run `tools/qa_bg_translation.py` on that temporary merge before packaging.
5. Review uncertain strings and glossary changes manually.
6. Generate `translations/bul.meta.toml` and the matching source cache only
   after QA passes.

The QA tool is intentionally useful before the translation is complete. It
reports exact source fallbacks separately, checks only translated overrides,
and keeps semantic, possible missing-gender, gender-token, punctuation, marker,
and line-length items in separate review sections. The possible missing-gender
section is intentionally broad: it uses English `you/your` as a recall-oriented
signal, excludes prompts, and requires human context review. A typical local
review run is:

```powershell
python tools/build_bg_overlay.py `
  --source mods/bulgarian-localization/package/localization/source_caches/bul.meta.toml `
  --work mods/bulgarian-localization/translation/work `
  --overlay .archive/qa-work-overlay

python tools/qa_bg_translation.py `
  .archive/qa-work-overlay/localization/source_caches/bul.meta.toml `
  .archive/qa-work-overlay/localization/translations/bul.meta.toml `
  --json .archive/qa-work-report.json
```

The QA and overlay tools are project workflow files and must remain tracked on
the `temp-translation` branch so they are available when the branch is later
published. The `.archive` outputs are disposable local reports and are not
uploaded.

The Russian, French, and Spanish translations are secondary references only.
They must not replace the English source when meaning, placeholders, or tone
are ambiguous.

Generated source keys, QA reports, extracted assets, archives, and translated
game data are ignored by Git. This directory contains translator-owned work
files for the Bulgarian localization; future Fields of Mistria mods belong in
their own directory under `mods/`.

## Pronoun and grammatical variants

The game supports pronoun selections through `l10n.meta.toml` and conditional
markup inside translated strings. Bulgarian exposes three player-facing
choices because they match the grammatical variants used by the translation:

```toml
they_them = { display = "Те / Тях", macros = ["they"] }
she_her = { display = "Тя / Нея", macros = ["she"] }
he_him = { display = "Той / Него", macros = ["he"] }
```

When a translated sentence requires grammatical agreement, use the matching
tags in the value:

```text
<he>той е готов</he><she>тя е готова</she><they>те са готови</they>
```

These tags are runtime markup and must not be translated, renamed, reordered,
or removed. A source key that contains pronoun variants must retain equivalent
variants in the Bulgarian value, unless the sentence is deliberately
rewritten so that grammatical gender is no longer needed. Existing work files
with gendered player-facing text must be reviewed under this rule during QA.

## Russian localization as a review reference

The Russian localization is a secondary diagnostic reference, not a source of
meaning or style. It uses a separate four-macro system: `p/f/m/n` (plural,
feminine, masculine, and neuter), plus an `all` menu option. Its compact tag
names and five menu choices must not be copied into Bulgarian. Use Russian
entries only to identify dialogue that may need Bulgarian variants, then write
the Bulgarian text from the English source and the scene context.

Prefer neutral Bulgarian wording in UI labels, tutorials, item descriptions,
and system messages when it is natural. Use conditional `he/she/they`
variants in dialogue or other player-facing text when gender agreement
materially changes the sentence. Do not copy Russian wording or assume that
every Russian gender choice is grammatically or stylistically correct for
Bulgarian. Adding a Bulgarian neuter option would require a full audit and
explicit matching branches throughout the pack; it is not a menu-only change.

Pronoun choices are stored per language in each save. When Bulgarian is added
to an existing save, the game initializes its Bulgarian choice from
`default_pronoun`; it does not copy the English choice or infer it from the
character's appearance. Keep the Bulgarian default neutral (`they_them`) and
select `Тя / Нея`, `Той / Него`, or another option in the language settings
when testing a specific variant. Do not add `it`, `all`, or `none` choices
unless the Bulgarian text has been fully audited and tested for them.
