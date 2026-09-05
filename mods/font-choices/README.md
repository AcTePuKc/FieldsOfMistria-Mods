# Font Choices

Independent add-on for choosing fonts without modifying a localization package.

## UI translation source

Player-facing UI labels live in one TOML per language under `localization/ui/`,
not in the hand-written GML. After changing any language file, run
`python tools/build_font_choices_ui.py`. The generated
`gml/FontChoicesUI.generated.gml` is packaged with Font Choices. Each language
file can be translated, reviewed, and replaced independently; an incomplete
file safely retains English for keys it has not translated.

Current profiles:

- Bulgarian/English/French/Spanish/Portuguese: Silver, IBM Plex, Roboto
  Condensed, Play, Marmelad, Monomakh, and Playpen Sans,
  subject to each language's glyph coverage and in-game review.
- Polish: Silver plus the explicitly tested IBM Plex 17x13 Lab variants.
- Russian: Game default, IBM Plex, and Playpen Sans.
- Turkish: Silver, IBM Plex, Play, Marmelad, Monomakh, and Playpen Sans.
  These choices pass the repaired Turkish translation's complete glyph audit
  and in-game review.

The add-on changes only the currently selected, explicitly supported game
language. It does not add, replace, or translate any language. An unknown or
future language has no Font Choices category and receives no font override.

## Experimental — global test builds

Version 0.0.34 keeps **Experimental** inside **Font Choices** as one global
button. It uses the same two-step picker — family first, then a metric profile
— but always applies the result to all text roles together. Its compact status
label shows the actual choice, for example `Monomakh / 17S`; `S` is shaded and
`F` is flat. Selecting an experimental profile deliberately clears its
individual experimental role overrides, so there is one unambiguous global
result.

The existing per-role controls in **Font Choices** remain available for the
combinations already reviewed in-game. An unset role displays `Follow All
text`.

The current Lab contains IBM Plex, Sofia Condensed, Sofia Extra Condensed,
Monomakh, Ponomar, and Triodion. Both Sofia families are offered only for
Bulgarian and Russian: their Latin rendering is unsuitable. Cormorant Infant
Italic and Handjet were removed after repeated glyph-rendering failures. The
14x12 Sofia variants were also removed; their useful comparisons begin at
17x13. Tall 19x14 variants remain restricted to popup descriptions and
dialogue text.

For Polish, the Compact 14x12 and Tall 19x14 IBM Plex variants are hidden;
only the two 17x13 variants passed the visual review.

Ponomar and Triodion are Lab-only while their rendering is calibrated. Their
old direct 14x12 choices were removed, including from Russian. Russian keeps
IBM Compact as a direct option and adds visually approved Playpen Sans; the
Lab lets the three historical Cyrillic families be tried at larger metrics.

Turkish appears after its translation repair: IBM Plex's four profiles and
Monomakh's generated profiles are available through the global Experimental
button. Ponomar and Triodion remain hidden for Turkish because they lack five
required Turkish glyphs.

Every generated Lab variant explicitly declares its allowed languages. This is
intentional: selections saved by earlier test builds are validated safely when
the game next starts, rather than relying on an optional runtime field.

The available experimental variants are generated from `font-lab-variants.toml` with:

```text
python tools/build_font_lab_variants.py
```

This copies an unchanged TTF/OTF into unique assets and writes their metadata;
it does not edit glyph outlines or scale the source font. Add only variants
that are intended for a controlled in-game comparison. The Experimental
category ships its available profiles as opt-in tests; feedback determines
which profiles remain and which become curated choices.

Font selections apply immediately and are saved under the private
`font_choices_selected` key in the game's settings.json. This test add-on can
reapply a selection after the title menu exists, but that is not a production
guarantee of title-screen persistence: static per-language profile packages
will be the release model.

Experimental profiles remain opt-in: visual acceptance requires an in-game review in
addition to the coverage audit. The font files are distributed under their
included license texts in `licenses/`.

## Adding a tested language

`gml/FontChoices.gml` has one `fc_profile_registry()` list. Add one language
block there only after the candidate passes the coverage audit and an in-game
check. Each block declares its language code, default, UI labels, and available
font assets; no other function needs a language-specific edit.
