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
game data are ignored by Git.
