# Breakup letters and follow-up dialogue

The breakup content is present in the game assets but is absent from the
English localization source-key index used by the normal pipeline.

Runtime sources:

- `assets/fiddle/letters.toml` contains 12 `*_break_up` letters, one for each
  romanceable NPC.
- `assets/t2/Conversations/General Dialogue/break_up.c.toml` contains the
  follow-up conversations after the player receives a breakup letter.

The inspected language packs contain 176 breakup follow-up conversation keys
in Korean, Simplified Chinese, and Traditional Chinese. French, Japanese,
Russian, and Spanish do not contain this block. The Chinese/Korean entries
confirm that this is real game content, not an unused hypothetical feature.

This content needs a separate Bulgarian translation pass. Do not expect it to
appear in the generated English source-key list until the extraction pipeline
is extended to include the runtime letter and conversation definitions.

Preserve `[Ari]`, `\n`, prompts, and all conversation branch keys when adding
the Bulgarian entries.
