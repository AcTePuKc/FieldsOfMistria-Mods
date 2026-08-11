# GML hooks and the hardcoded `Lvl` label

## Discovery

The `Lvl 0` label shown in the Player/Info menu is not supplied by the
`spr_ui_skills_lvl_*` image. The relevant engine code is:

`assets/gml/scripts/UI/Anchor/Menus/PlayerMenu.gml`

The current code contains:

```gml
format("Lvl {}", renown_to_level(ARI.renown)),
```

The existing Bulgarian localization key is therefore bypassed on this screen:

```toml
"misc_local/renown_lvl_insert" = "Ниво"
```

## Failed approach

Do not add a complete replacement file at:

`gml/scripts/UI/Anchor/Menus/PlayerMenu.gml`

The engine already defines `PlayerMenu`, so AIM reports a duplicate function
definition and skips that part of the mod:

`function 'PlayerMenu' ... already defined by the engine`

## Correct approach

Use an MMAPI hook and a mod-owned GML file with uniquely prefixed function
names. The working `Map NPC Labels` mod is the reference implementation:

- manifest declares `requires_hooks = ["ui.menu_opened"]`;
- its GML registers a callback with `mmapi_on("ui.menu_opened", ...)`;
- it inspects and decorates the opened menu without redefining engine menus.

The future Bulgarian fix should use the same pattern: detect `Menu.Player`
when it opens and update the relevant text node, if the hook exposes that node.
Do not ship the full engine `PlayerMenu.gml` as a replacement.

The rejected full-file test was intentionally kept out of the working mod and
archive. The test confirmed AIM's duplicate-definition validation is working.

## Successful test

The working implementation uses `gml/BulgarianLvlHook.gml` and declares:

```toml
requires_hooks = ["ui.menu_opened"]
```

It was tested in-game and changed the Player/Info panel from `Lvl 0` to the
localized `Ниво 0`. It does not depend on `Map NPC Labels` or any other mod;
it depends only on the `ui.menu_opened` hook being available in the installer
and game API.

If the upstream game later localizes this line itself, the hook should be
removed to avoid maintaining a duplicate fix.
