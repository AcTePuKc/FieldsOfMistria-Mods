# Built-in Fonts and Localization Findings

## Summary

Bulgarian does not need a new font asset merely because it needs a language
entry. MOMI localization packs can map a language to an existing game font in
`fiddle/ui/text_styles.toml`.

The game already ships several fonts and uses them by language and text
category. The relevant built-in mapping is:

```toml
[standard]
eng = "fnt_mistria_birdseed"
spa = "fnt_mistria_birdseed"
fra = "fnt_mistria_birdseed"
rus = "fnt_mistria_birdseed"
jpn = "fnt_pixel_m_plus"
zh-Hant = "fnt_cubic_11"
zh-Hans = "fnt_zpix"
kor = "fnt_silver"

[popup_description]
jpn = "fnt_pixel_m_plus"
zh-Hant = "fnt_cubic_11"
zh-Hans = "fnt_zpix"
kor = "fnt_silver"

[textbox]
jpn = "fnt_pixel_m_plus"
zh-Hant = "fnt_cubic_11"
zh-Hans = "fnt_zpix"
kor = "fnt_silver"
```

The mapping is per text style. A language does not have to use one custom
font for every UI surface, and a pack can point to a font that is already in
the base game.

## Glyph coverage

The five characters needed by the Bulgarian teaser test were checked against
every shipped font:

| Built-in font | `Ѝѝ` | `„“”` |
|---|---:|---:|
| `fnt_mistria_birdseed` | no | no |
| `fnt_cubic_11` | no | partial |
| `fnt_nosutaru` | no | partial |
| `fnt_pixel_m_plus` | no | partial |
| `fnt_zpix` | no | yes |
| `fnt_silver` | yes | yes |

`fnt_silver` is the only shipped font found with all five characters. Its
visual style is different from Birdseed, but it provides a clean functional
baseline without adding a font asset.

## Successful built-in-font test

The test package used:

```toml
[standard]
bul = "fnt_silver"

[popup_description]
bul = "fnt_silver"

[textbox]
bul = "fnt_silver"
```

The package removed the custom Bulgarian TTF and its meta file. It changed
only the manifest version and `fiddle/ui/text_styles.toml`; the resulting ZIP
was reopened successfully, and both TOML files parsed successfully.

The in-game test confirmed that the Bulgarian dialogue rendered with the
required characters, including Bulgarian `Ѝ/ѝ` and quotation marks. The
remaining issue is visual style, not missing glyphs or font registration.

## Font metadata conclusions

The base game stores font-specific rendering hints in each font's own
`*.meta.toml`. These values are not universal language settings and should not
be copied mechanically between fonts.

The shipped pixel fonts use `allow_shading = false`. That is appropriate for
those pixel assets. Applying the same setting to an arbitrary vector or
variable TTF can remove portions of strokes when the outline is thresholded.

`minimum_expected_size` and `minimum_expected_line_height` are independent
font metrics. The second value is not an inverse of the first and should not
be made smaller just because the font needs to appear smaller. For a new font,
the values should be selected from the font's metrics and verified in-game.

## `text_markers.toml`

`fiddle/ui/text_markers.toml` is the registry for dynamic text markers. It
contains the special marker characters and the supported marker names, for
example player names, farm names, item names, children, spouse and other
runtime values.

Marker names and syntax are technical identifiers. They must remain unchanged
when translating text. A marker's surrounding player-facing text may be
translated, but the marker itself must retain its spelling, punctuation and
placement.

## Current direction

The built-in-font route is now the preferred baseline:

1. map Bulgarian text styles to an existing compatible game font;
2. avoid a custom TTF unless no shipped font provides the required glyphs and
   visual style;
3. keep `allow_shading = false` for the pixel-font assets used by the game;
4. only add a new font asset when a verified visual requirement justifies it;
5. do not commit extracted game assets, copyrighted localization data or test
   ZIP packages.
