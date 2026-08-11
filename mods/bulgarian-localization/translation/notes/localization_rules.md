# Bulgarian localization rules

## Highlighted text markers

Text enclosed in dollar signs, such as `$Diary$`, `$Pickaxe$`, or `$earthquake$`, is highlighted by the game for special visual formatting.

When translating:

- preserve the opening and closing `$` characters exactly;
- translate the text inside the markers into Bulgarian;
- preserve the intended grammatical form in the sentence;
- do not assume that the English text inside the markers is an asset key or a token that must remain in English.

Example:

```toml
"example" = "Write in your $Diary$."
```

becomes:

```toml
"example" = "Пиши в своя $дневник$."
```

This rule is separate from gender/variant markup such as `<he>...</he><she>...</she><they>...</they>`. Those tags must also be preserved, while each alternative is translated independently.

## Player pronouns and grammatical variants

The public Bulgarian pack exposes exactly three player choices:

- `they_them` - `Те / Тях`, macro `they`;
- `she_her` - `Тя / Нея`, macro `she`;
- `he_him` - `Той / Него`, macro `he`.

These are choices for the player's pronouns, not a requirement to write three
versions of every line. First rewrite a sentence neutrally when that is natural.
When Bulgarian agreement is unavoidable, provide all three corresponding
branches in the fixed order:

```text
<he>...</he><she>...</she><they>...</they>
```

Do not use masculine wording as the fallback. Do not add `<it>`, `<all>`, or
`<none>` branches to ordinary Bulgarian dialogue. The Bulgarian pack does not
offer those selections because the current text has no matching variants; a
visible choice without a matching branch can make part of a line disappear.

## Language asset IDs

The `translation` and `src_cache` values in `l10n.meta.toml` must exactly match the `id` values written to `translations/bul.meta.toml` and `source_caches/bul.meta.toml`. The current project keeps these IDs stable between builds. If either ID is intentionally changed, update `l10n.meta.toml` at the same time.

## Bulgarian typography

- Use Bulgarian quotation marks `„...“` in player-facing text.
- Do not leave em dashes (`—`) in the generated translation. The overlay builder converts them according to the surrounding text.
- Preserve the Bulgarian letter `ѝ` where it means “to her”; do not replace it with plain `и`.

## Bulgarian font glyphs

The custom `fnt_mistria_birdseed_bul.ttf` is generated from the game's Birdseed
font with selected glyph outlines imported from the game's Silver font. The
generator is:

```text
tools/build_mistria_bulgarian_font.py
```

Current generated glyphs:

- `Ѝ` uses the Silver outline, scaled to the width of Birdseed `И`;
- `ѝ` uses the Silver outline, scaled to the width of Birdseed `и`;
- `„` is composed from two native Birdseed commas;
- `“”` are composed from two native Birdseed apostrophes.

Do not replace the TTF with an unverified copy. Any future font change must be
checked in the standard, textbox, and popup-description styles, then tested in
the game with `Ѝ`, `ѝ`, `„`, `“`, and `”`.

The game also ships the 11x14 baked asset
`assets/animations/UI NEW/Fonts/spr_ui_dialogue_font_birdseed_bof.png`, but the
Bulgarian package must not replace it. Fields of Mistria 1.0.2 testing showed
that a 269-glyph Bulgarian TTF with appended `Ѝѝ„“”` entries renders those
characters, while remapping them onto five old glyph slots and replacing the
baked atlas makes the same characters render as missing squares. Keep the
working appended-glyph strategy unless a future game update changes the font
loader, and archive every tested TTF by SHA-256 before replacing it.
