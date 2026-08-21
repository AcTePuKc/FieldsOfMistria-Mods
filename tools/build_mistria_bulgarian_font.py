"""Create a Bulgarian Mistria font by adding missing glyphs to Birdseed.

The game uses TTF fonts for normal UI/dialogue text.  The Bulgarian language
needs a few glyphs that are not present in the standard Birdseed font. This
tool keeps Birdseed as the base font, imports `Ѝ` and `ѝ` from the bundled
Silver font, and composes Bulgarian quotation marks from Birdseed's own comma
and apostrophe pixels.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont


REQUIRED_GLYPHS = "Ѝѝ„“”"
REFERENCE_GLYPHS = {
    "Ѝ": "И",
    "ѝ": "и",
}


def best_cmap(font: TTFont) -> dict[int, str]:
    cmap = font.getBestCmap()
    if not cmap:
        raise ValueError("Font has no Unicode cmap")
    return cmap


def add_glyphs(base: TTFont, donor: TTFont, characters: str) -> None:
    base_cmap = best_cmap(base)
    donor_cmap = best_cmap(donor)
    donor_glyph_set = donor.getGlyphSet()
    y_scale = base["head"].unitsPerEm / donor["head"].unitsPerEm

    for char in characters:
        codepoint = ord(char)
        donor_name = donor_cmap.get(codepoint)
        if donor_name is None:
            raise ValueError(f"Donor font is missing U+{codepoint:04X} ({char!r})")

        reference_name = base_cmap.get(ord(REFERENCE_GLYPHS[char]))
        if reference_name is None:
            raise ValueError(f"Base font is missing the reference glyph for {char!r}")

        donor_advance, donor_lsb = donor["hmtx"][donor_name]
        target_advance, target_lsb = base["hmtx"][reference_name]
        x_scale = target_advance / donor_advance

        target_name = f"bg_{codepoint:04x}"
        if target_name not in base.getGlyphOrder():
            # Draw through a TransformPen so donor units become base units.
            pen = TTGlyphPen(donor_glyph_set)
            x_offset = target_lsb - round(donor_lsb * x_scale)
            transformed = TransformPen(pen, (x_scale, 0, 0, y_scale, x_offset, 0))
            donor_glyph_set[donor_name].draw(transformed)
            base["glyf"][target_name] = pen.glyph()
            base["hmtx"][target_name] = tuple(
                (target_advance, target_lsb)
            )
            glyph_order = base.getGlyphOrder()
            if target_name not in glyph_order:
                glyph_order.append(target_name)
            base.setGlyphOrder(glyph_order)
            base["glyf"].glyphOrder = glyph_order

        for table in base["cmap"].tables:
            if table.isUnicode():
                table.cmap[codepoint] = target_name


def add_birdseed_quotes(base: TTFont) -> None:
    """Compose Bulgarian double quotes from native Birdseed punctuation."""
    base_cmap = best_cmap(base)
    glyph_set = base.getGlyphSet()
    quote_specs = {
        "„": (",", ((0, 0), (256, 0))),
        "“": ("'", ((0, 0), (128, 0))),
        "”": ("'", ((0, 0), (128, 0))),
    }

    for char, (source_char, offsets) in quote_specs.items():
        source_name = base_cmap[ord(source_char)]
        pen = TTGlyphPen(glyph_set)
        for x_offset, y_offset in offsets:
            transformed = TransformPen(pen, (1, 0, 0, 1, x_offset, y_offset))
            glyph_set[source_name].draw(transformed)

        target_name = f"bg_{ord(char):04x}"
        base["glyf"][target_name] = pen.glyph()
        base["hmtx"][target_name] = (512, 0)
        glyph_order = base.getGlyphOrder()
        if target_name not in glyph_order:
            glyph_order.append(target_name)
            base.setGlyphOrder(glyph_order)
            base["glyf"].glyphOrder = glyph_order
        for table in base["cmap"].tables:
            if table.isUnicode():
                table.cmap[ord(char)] = target_name


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--donor", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    # Preserve the base font's timestamp so identical inputs produce identical
    # output bytes instead of changing the TTF checksum on every build.
    base = TTFont(args.base, recalcTimestamp=False)
    donor = TTFont(args.donor, recalcTimestamp=False)
    add_glyphs(base, donor, "Ѝѝ")
    add_birdseed_quotes(base)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    base.save(args.output)

    check = TTFont(args.output)
    cmap = best_cmap(check)
    missing = [char for char in REQUIRED_GLYPHS if ord(char) not in cmap]
    if missing:
        raise RuntimeError(f"Generated font is missing: {missing!r}")
    print(f"Wrote {args.output} with glyphs: {' '.join(f'U+{ord(c):04X}' for c in REQUIRED_GLYPHS)}")


if __name__ == "__main__":
    main()
