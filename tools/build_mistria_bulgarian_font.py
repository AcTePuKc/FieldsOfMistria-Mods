"""Create a Bulgarian Mistria font by adding missing glyphs to Birdseed.

The game uses TTF fonts for normal UI/dialogue text.  The Bulgarian language
needs a few glyphs that are not present in the standard Birdseed font.  This
tool keeps Birdseed as the base font and imports only those glyphs from the
bundled Silver font, scaling them to Birdseed's em size.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont


REQUIRED_GLYPHS = "ѝ„“”"


def best_cmap(font: TTFont) -> dict[int, str]:
    cmap = font.getBestCmap()
    if not cmap:
        raise ValueError("Font has no Unicode cmap")
    return cmap


def add_glyphs(base: TTFont, donor: TTFont, characters: str) -> None:
    base_cmap = best_cmap(base)
    donor_cmap = best_cmap(donor)
    base_glyph_set = base.getGlyphSet()
    donor_glyph_set = donor.getGlyphSet()
    scale = base["head"].unitsPerEm / donor["head"].unitsPerEm

    for char in characters:
        codepoint = ord(char)
        donor_name = donor_cmap.get(codepoint)
        if donor_name is None:
            raise ValueError(f"Donor font is missing U+{codepoint:04X} ({char!r})")

        target_name = f"bg_{codepoint:04x}"
        if target_name not in base.getGlyphOrder():
            # Draw through a TransformPen so donor units become base units.
            pen = TTGlyphPen(donor_glyph_set)
            transformed = TransformPen(pen, (scale, 0, 0, scale, 0, 0))
            donor_glyph_set[donor_name].draw(transformed)
            base["glyf"][target_name] = pen.glyph()
            base["hmtx"][target_name] = tuple(
                round(value * scale) for value in donor["hmtx"][donor_name]
            )
            glyph_order = base.getGlyphOrder()
            if target_name not in glyph_order:
                glyph_order.append(target_name)
            base.setGlyphOrder(glyph_order)
            base["glyf"].glyphOrder = glyph_order

        for table in base["cmap"].tables:
            if table.isUnicode():
                table.cmap[codepoint] = target_name


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--donor", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    base = TTFont(args.base)
    donor = TTFont(args.donor)
    add_glyphs(base, donor, REQUIRED_GLYPHS)
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
