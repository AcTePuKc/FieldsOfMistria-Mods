# Journal inventory tabs: runtime note

`PlayerMenu.gml` selects the journal inventory section sprites with:

```gml
var insert = local_language() == "rus" ? "_ru" : "";
```

This affects:

- `spr_ui_journal_inventory_section_a`
- `spr_ui_journal_inventory_section_b`
- `spr_ui_journal_inventory_section_c`

The Russian variants are `20x46` animations. Adding `_bul` assets alone will
not make the game use them because the current GML condition only checks
`rus`. Supporting Bulgarian requires an engine-side localization fix or an
`ui.menu_opened` hook that replaces the three sprites after the Player/Info
menu is created.

