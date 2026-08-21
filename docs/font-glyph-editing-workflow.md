# Fields of Mistria TTF glyph editing workflow

The game loads `fnt_mistria_birdseed_bul.ttf` as a TrueType font. BMFont Studio
produces bitmap-font pages (`.fnt` plus PNG) and therefore is not the final
compiler for this asset.

The proven runtime baseline is the font used by teaser versions 0.0.4 and
0.0.6:

```text
SHA-256: 9093264f62261165fc9061a56abf0efce5dbc5260f48605814c6521b6fdb0ea8
Glyph slots: 269
Mapped Unicode characters: 268
```

Run `tools/export_fom_ttf_glyphs.py` to create 11x14 editable PNG cells, zoomed
previews, a contact sheet, and a manifest containing the original glyph order,
indices, metrics, and PNG hashes.

Run `tools/import_fom_ttf_glyphs.py` after editing. By default it imports only
PNGs whose hashes differ from the export manifest. It preserves the original
glyph order, Unicode mappings, advance widths, and left-side bearings, and
reopens the output TTF to validate the result.

The Bulgarian additions occupy these proven slots:

| Character | Code point | Glyph index |
|---|---:|---:|
| `ѝ` | U+045D | 264 |
| `„` | U+201E | 265 |
| `“` | U+201C | 266 |
| `”` | U+201D | 267 |
| `Ѝ` | U+040D | 268 |

Generated TTFs remain test candidates until they have been installed through
MOMI and verified in the game. A structurally valid TTF is not sufficient proof
that the game runtime renders every modified glyph correctly.
