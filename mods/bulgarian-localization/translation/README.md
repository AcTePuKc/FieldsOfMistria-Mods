# Bulgarian localization workflow

The English source cache is the semantic source of truth. In the inspected
Fields of Mistria 1.0 archive it is stored as
`source_caches/fra.meta.toml`, even though the values are English source
strings and the file is not French translation data.

The working translation is kept outside generated archive output. The normal
workflow is:

1. Prepare source keys from the current `assets.zip` with
   `tools/prepare_bg_pipeline.py`.
2. Translate only player-facing values in the generated Bulgarian work file.
3. Run `tools/qa_bg_translation.py` before packaging.
4. Review uncertain strings and glossary changes manually.
5. Generate `translations/bul.meta.toml` and the matching source cache only
   after QA passes.

The Russian, French, and Spanish translations are secondary references only.
They must not replace the English source when meaning, placeholders, or tone
are ambiguous.

Generated source keys, QA reports, extracted assets, archives, and translated
game data are ignored by Git. This directory contains translator-owned work
files for the Bulgarian localization; future Fields of Mistria mods belong in
their own directory under `mods/`.

## Pronoun and grammatical variants

The game supports pronoun selections through `l10n.meta.toml` and conditional
markup inside translated strings. The Bulgarian registration should use the
same compact macro names used by the shipped Russian localization:

```toml
they_them = { display = "Те / Тях", macros = ["p"] }
she_her = { display = "Тя / Нея", macros = ["f"] }
he_him = { display = "Той / Него", macros = ["m"] }
it_its = { display = "То / Него", macros = ["n"] }
```

When a translated sentence requires grammatical agreement, use the matching
tags in the value:

```text
<m>той е готов</m><f>тя е готова</f><p>те са готови</p><n>то е готово</n>
```

These tags are runtime markup and must not be translated, renamed, reordered,
or removed. A source key that contains pronoun variants must retain equivalent
variants in the Bulgarian value, unless the sentence is deliberately
rewritten so that grammatical gender is no longer needed. Existing work files
with gendered player-facing text must be reviewed under this rule during QA.

## Russian localization as a review reference

The Russian localization is a secondary diagnostic reference, not a source of
meaning or style. It contains many dialogue entries with explicit `m/f/p/n`
variants, including cases where the English source does not make the
grammatical issue obvious. Use those entries to identify dialogue that may
need Bulgarian variants, then write the Bulgarian text from the English source
and the scene context.

Prefer neutral Bulgarian wording in UI labels, tutorials, item descriptions,
and system messages when it is natural. Use conditional `m/f/p/n` variants in
dialogue or other player-facing text when gender agreement materially changes
the sentence. Do not copy Russian wording or assume that every Russian gender
choice is grammatically or stylistically correct for Bulgarian.
