# Journal Wider

Experimental package for one question only: can the Journal gain horizontal
content room without changing unrelated menus?

It adds 50 pixels of logical width to each Journal page and horizontally scales
only the Journal book/page background sprites to cover that space. It does not
change font selection, translation files, Journal height, or any other screen.

This is not release-quality artwork. The test determines whether the existing
tabs, scrollers, input, and submenus remain stable before considering a proper
pixel-art expandable backplate or a player-facing layout option.

Version 0.0.4 applies after the Journal's selected tab has rebuilt the book and
adds a temporary green `JOURNAL POC +50` label at the top of the target menu,
solely to make the hook unambiguous during testing.

Version 0.0.7 adds the first page-specific reflow: on the Relationships/Жители
page only, the four bottom detail labels use the widened page instead of their
vanilla 156px limit. It uses the right page's existing blank vertical area and
bottom-aligns the information block: a long job title moves only the preceding
rows up, while the final relationship row stays near its vanilla bottom
position. This uses rendered text height, so it automatically adapts to the
selected font. Portrait and gift layouts remain unchanged.

Version 0.0.8 moves the Relationships detail block 14px right, under the
portrait rather than across the journal spine, and lowers its bottom-pinned
status row by 2px.

Version 0.0.9 detects the vanilla disabled partner-status icon used by
non-dateable NPCs. Their three visible rows move down 2px as one compact block,
while dateable NPCs retain the four-row layout from 0.0.8.

Version 0.0.10 adds 3px of breathing room above a wrapped job line, per extra
rendered line. This uses the otherwise empty room under the portrait, so it
helps taller/bolder fonts without changing one-line job cards.

Version 0.0.11 uses the Anchor text node's actual post-reflow line count rather
than guessing from pixel height. A tall one-line font therefore no longer gets
treated as a wrapped job. NPCs without a partner-status row also no longer
reserve its vertical space, including when their job title wraps.

Version 0.0.12 is a separate structural test: it redraws the existing loved and
liked gift slots as seven-column grids. Loved gifts remain two rows; liked gifts
shrink from four rows to three, freeing 17 logical pixels without changing the
text block yet. It preserves the vanilla slot construction and item ids so
hovered item tooltips should continue to work.

Version 0.0.13 replaces the prior seven-column experiment with a compact
portrait + ten-column test. It uses the game's existing 64x81 small portrait
frame, moved left, to fit all loved gifts in one row and liked gifts in two.
This frees two gift-grid rows (34 logical pixels); the text block remains
unchanged until the compact composition itself is verified.

Version 0.0.14 replaces the 10-column/small-portrait experiment after it
overlapped the portrait and could leave the initial profile image stale. It
restores vanilla portrait construction and uses nine columns instead: loved
gifts remain two rows and liked gifts become three. This preserves one freed
row while retaining a clean gap beside the normal portrait.

Version 0.0.15 removes one more column after the nine-column grid still touched
the portrait frame at this menu's actual anchor scale. Eight columns retain the
same two-row/three-row composition while restoring a clear visual gap.

Version 0.0.16 was a diagnostic-only checkpoint for the left Relationships
column. It attempted unavailable runtime reflection and must not be used.

Version 0.0.17 restores the full 0.0.15 Relationships layout first, then probes
only a small set of likely public left-list and scrollbar field names through
safe dynamic lookup. It logs matches once when Residents opens; it makes no
visible left-page move.

Version 0.0.18 replaces that incomplete guessed-name probe with the supported
`struct_get_names()` reflection call. It logs every public Relationships field
after the verified right-page reflow, without changing the left page visually.

Version 0.0.19 logs the public fields inside Relationships' discovered
`npc_scroller` node only. It is still diagnostic-only and makes no visual left
page change.

Version 0.0.20 logs the public fields of the discovered scroller's `root` and
`scroll_bar_root` containers. It is still diagnostic-only and makes no visual
left page change.

Version 0.0.21 logs the static Anchor methods on those two containers. This is
the last diagnostic needed before a targeted list-width and scrollbar-position
patch.

Version 0.0.22 is the first narrow left-page visual test. It widens only the
NPC scroller viewport by 50px and moves the complete scrollbar container 50px
right. It deliberately leaves individual NPC rows, portraits, and all right
page content unchanged.

Version 0.0.23 keeps the verified 0.0.22 geometry and logs the first NPC row
and its child nodes. This identifies the separate row background and the
hearts / relationship-bar block before they are moved.

Version 0.0.24 logs the positions and dimensions of that row's background,
portrait glyph, text, and two sprite children. This identifies exactly which
two nodes are the hearts and relationship bar before the visual reflow.

Version 0.0.25 expands the discovered 161x40 NPC row backgrounds by 50px,
alongside the established viewport and scrollbar move. The hearts and
relationship bar are part of the row sprite rather than independent public
nodes, so this test deliberately does not try to translate them independently.

Version 0.0.26 reverts the 0.0.25 row-width experiment. The game draws those
rows below a separate scroller clip/mask, which cut off the baked heart art.
It retains the proven wider viewport and right-shifted scrollbar from 0.0.22.

Version 0.0.27 replaces that temporary rollback with the complete left-list
reflow from the vanilla Scroller construction: it widens both the scroller
canvas and its render clip, then widens each 161x40 NPC row. The rows' native
right-aligned hearts and progress bars therefore move into the new space while
portraits and names retain their original positions.

Version 0.0.28 adds the first Customization-page reflow. It shifts the complete
left editor composition 25px right so its slots, character, arrows, and outfit
button remain centred in the wider page. It also widens the lower JournalFields
profile card and its five interactive field rows to the full left-page width;
the right-side category browser is deliberately unchanged for this checkpoint.

Version 0.0.29 corrects the Customization profile-card width and anchor. The
vanilla journal body is narrower than its page artwork; the card now preserves
those original margins instead of extending across the book spine.

Version 0.0.30 completes the Customization page's structural reflow. Whenever
a left-side category opens its right-side browser, the vanilla `setup_right_page`
constructor is wrapped and its shared category scroller is fitted to the true
inner-page width. Every category receives the same corrected canvas, rows,
grid alignment, and untouched right-edge scrollbar.

Version 0.0.31 replaces that constructor wrapper with an idempotent UI-frame
check. It leaves the game's category-opening method entirely vanilla, then
fits each newly created right-side scroller on the next frame.

Version 0.0.32 starts the Inventory page. It restores the real 226px
journal-interior width for the left information, equipment, and skills panels
and for the right action bar, while preserving the inventory grid's intended
centering in the wider page.

Version 0.0.33 completes the Inventory-page pass by moving the title's
separately anchored bag icon 25px with the widened right page. The bottom HUD
toolbar is intentionally unchanged because it is not part of PlayerMenu.

Version 0.0.34 adds a zero-dependency compatibility pass for Mistria Auxiliary
Bag. When that mod has injected its seven optional `aux_hotbar_slot` controls
into PlayerMenu, they are centred with the widened page; no AuxBag files or
functions are changed.

Version 0.0.35 was a diagnostic build for that compatibility pass. It showed
that AuxBag's final nodes retain their unique seven-slot geometry but not their
labels. Version 0.0.36 uses that geometry to centre the row, removes the
diagnostic logging, and refines the Inventory title icon correction to 10px.
