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

## Language asset IDs

The `translation` and `src_cache` values in `l10n.meta.toml` must exactly match the `id` values written to `translations/bul.meta.toml` and `source_caches/bul.meta.toml`. The current project keeps these IDs stable between builds. If either ID is intentionally changed, update `l10n.meta.toml` at the same time.

## Bulgarian typography

- Use Bulgarian quotation marks `„...“` in player-facing text.
- Do not leave em dashes (`—`) in the generated translation. The overlay builder converts them according to the surrounding text.
- Preserve the Bulgarian letter `ѝ` where it means “to her”; do not replace it with plain `и`.
