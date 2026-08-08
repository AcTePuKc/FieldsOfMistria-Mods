# First-day Bulgarian UI smoke-test queue

This is a focused queue for the first playable Bulgarian teaser test. It is a review list, not yet a translation patch. Keep source keys, placeholders, markup, and `\n` line breaks unchanged when applying translations.

## UI and settings

Short UI strings to translate and test in-game:

- `Continue`
- `Exit`
- `Credits`
- `Smooth Camera Tracking`
- `Brightness`
- `Saturation`
- `Frame rate Cap: 60 FPS`
- `Snap Frame Rate`
- `Choose VSync Mode`
- `Off`
- `On`
- `Adaptive`
- `Oversleep Penalty`
- `Move Down`
- `Move Left`
- `Pick Up One (Inventory)`
- `Open Journal`
- `Open Map`
- `Switch Menu Tab (Right)`
- `Switch Menu Tab (Left)`
- `Next Appearance Preset`
- `Last Appearance Preset`
- `Move Furniture Up`
- `Move Furniture Down`
- `Move Furniture Left`
- `Move Furniture Right`
- `Next Toolbar Tab`
- `Last Toolbar Tab`
- `Beta Localization`
- `The Beta Localization ...` (long explanatory popup; review as a separate block)
- `If a piece of text is ...` (long explanatory popup; preserve any markup/placeholders)
- `Exit to Desktop`
- `misc_local/exit_confirm` — `Are you sure you want to exit the game?` (confirmation dialog, not a button)
- `misc_local/confirm_leave_dungeon` — `Are you sure you want to exit the Mines?` (separate confirmation dialog)

### UI length test

Before finalizing the long control labels, measure the available control width in the Settings screen. Prefer concise natural Bulgarian labels over literal translations. Record the maximum usable characters/width from the game rather than guessing from English length.

Candidate review items:

- `Use Tool (Charged)` / `Използване на инструмент (задържане)`
- `Use Tool (Repeated)` / `Използване на инструмент (повтаряне)`
- `Cast Pinned Spell` / `Хвърляне на закачено заклинание` (review whether `закачено` is needed)
- `Give Gift / Throw Item` / `Подаряване / хвърляне на предмет`
- `Next Toolbar Item` / `Следващ предмет от лентата`
- `Last Toolbar Item` / `Предишен предмет от лентата`
- `Start Game` (compare `Започни игра`, `Напред`, `Старт`, and `Начало` in context)

### Measured results from the temporary T20–T45 fixture

These are visual observations from the current Settings layout, not universal character limits. Cyrillic glyph widths and the specific control still matter.

- `T20`: the final `0` wrapped to a second line; two lines looked poor for this control.
- `T25`: visible through the second `4`; the following character wrapped. This is acceptable for the left-side menu label but is not a comfortable target.
- `T30`: visible through the second `0` in the tested field.
- `T35`: visible through the second `9`; this length may be acceptable if a two-line layout is intentionally supported.
- `T40`: visible through the second `0` in the tested field.
- `T45`: visible through the second `0`; this is the longest useful observed range for the tested wide field, not a safe general limit.
- Credits-style text wrapped to three lines; test the concise Bulgarian option `Автори` before `Надписи` or `Кредити`.
- `VSync` wording was too long when translated as `Вертикална синхронизация`; use a shorter UI label if the control remains narrow.
- `Screen Shake` wording `Разтръсване на екрана` needs a natural shorter replacement.
- `Time Particle Strength` was truncated; identify the exact context before choosing a Bulgarian term.

Practical provisional targets:

- narrow menu/control label: aim for approximately 20–25 characters;
- wider setting field: approximately 30–35 characters;
- 40–45 characters should be treated as exceptional and tested individually;
- do not add manual `\n` to short controls unless the game layout explicitly requires it.

Additional strings observed as still needing review:

- `Next Toolbar Item`
- `Last Toolbar Item`
- `Choose VSync Mode`
- `Weather Strength`
- `Time Particle Strength`
- the Credits label and its surrounding screen text

Exit labels must be reviewed separately because they are different source keys:

- `misc_local/exit` — `Exit`
- `misc_local/exit_game` — `Exit Game`
- `misc_local/exit_to_desktop` — `Exit to Desktop`

The width fixture tested `Exit` and `Exit to Desktop`; `Exit Game` still needs a direct UI check.

## Prologue dialogue

Source location:

`Cutscenes/Story Events/prologue/prologue/init`

- `Still working, sis?`
- `Oh, Eiland!`
- `I didn't realize how late it had gotten.`

Preserve the casual voice and the character name `Eiland` according to the project glossary.

## Character customization and starting setup

- `Character Customization`
- `Enter new name`
- proposed default name: `Ari` (verify why the game supplies this value; do not translate the value itself)
- `Mistgrove Farm`

## Day zero

Source location:

`Cutscenes/Story Events/day_zero/day_zero/init`

This block is large and should be translated in a separate focused pass. Prioritize the first visible scene and tutorial prompts for the teaser, then return for the remainder.

## QA notes for the first playthrough

- Verify that Bulgarian appears in the language list and that the game reaches the first scene.
- Record any new `requested asset "..." does not exist` message exactly; the asset name identifies the missing localized resource.
- Check calendar weekday graphics separately from seasonal calendar graphics.
- Review `Screen Shake` wording; the current Bulgarian wording `Разтръсване на екрана` sounds unnatural and needs a better UI label.
- Record missing settings labels such as `Continue` during the playthrough instead of guessing from memory.
- Do not treat English fallback assets as final Bulgarian artwork; they are temporary startup-test assets only.
