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

## Equals (`=...=`) marker

Text enclosed in equals signs is rendered in dark pink. It is player-facing
text, not an asset ID.

When translating:

- preserve the opening and closing `=` characters exactly;
- translate the text inside the markers into Bulgarian;
- retain its grammatical form in the surrounding sentence.

An in-game Day 0 test compared `=Пролетна салата=` and `=Spring Salad=` in
two consecutive Balor lines. Both rendered as dark-pink text, confirming that
the inner text is displayed directly.

## At-sign (`@`) marker

The source currently contains one known example: `@INCREDIBLE!` in the Water
Tablet turn-in scene. A direct in-game Day 0 test confirmed that a leading
`@` and an enclosing `@word@` are consumed by the engine and are not rendered
as visible text in ordinary dialogue. Its exact special use is still unknown.

When it appears in source text:

- preserve each `@` in the same position relative to the translated text;
- do not translate it, remove it, or add new ones;
- treat it as engine markup even when it has no visible effect in a test.

## Caret (`^...^`) marker

Text enclosed in carets appears mostly in Mine scenes and is likely rendered
with a wavering or otherwise unstable text effect. Its exact runtime behavior
has not yet been independently confirmed, but the marker is part of the
source formatting and must be preserved.

When it appears in source text:

- preserve the opening and closing `^` characters;
- keep them around the complete translated passage;
- preserve any nested `$...$`, `=...=`, or gender markup inside the carets;
- do not treat `^...^` as a gender token or replace it with ordinary
  punctuation.

Example:

```toml
"example" = "^A $Sealing Scroll$!?^"
```

becomes:

```toml
"example" = "^$Свитък за запечатване$!?^"
```

The current Bulgarian form is `@НЕВЕРОЯТНО!`.

## Player pronouns and grammatical variants

The public Bulgarian pack exposes exactly three player choices:

- `they_them` - `Те / Тях`, macro `they`;
- `she_her` - `Тя / Нея`, macro `she`;
- `he_him` - `Той / Него`, macro `he`.

These are choices for the player's pronouns, not a requirement to write three
versions of every line. First rewrite a sentence neutrally when that is natural.
When Bulgarian agreement is unavoidable, provide all three corresponding
branches in the fixed order:

```text
<he>...</he><she>...</she><they>...</they>
```

The isolated Day 0 experiment showed that `<else>` should not be treated as an
automatic replacement for a missing `he` or `she` branch. A line containing
only `they` and `else` did not provide the expected fallback when another
pronoun was selected. Keep `<else>` only when it is present and semantically
needed in the source; it is not a shortcut for removing ordinary Bulgarian
gender variants.

Do not use masculine wording as the fallback. Do not add `<it>`, `<all>`, or
`<none>` branches to ordinary Bulgarian dialogue. The Bulgarian pack does not
offer those selections because the current text has no matching variants; a
visible choice without a matching branch can make part of a line disappear.

### Future isolated `all` experiment

The archived reference metadata contains an `all` selection whose `macros`
list enables every pronoun macro at once. This is not part of the current
Bulgarian package. If we test it later, do so only in a separate experimental
copy with a short diagnostic line; never add it to the working package without
checking how the game renders a line containing multiple matching branches.

**Planned after QA:** first build `0.1.4-testing` with the current three-choice
Bulgarian setup. Then test adding the `all` selection against that working local
build, because the other shipped localizations expose it. Only if rendering is
correct should `all` be added to the builder and package metadata. Do not change
the current Bulgarian default or working package before that test passes.

### Future single-variant package builder

Create a local build script that takes the canonical tokenized translation and
generates a clean package for exactly one selection (`he_him`, `she_her`, or
`they_them`). The builder should resolve the selected branch, write a matching
`l10n.meta.toml`, and place the result in a fresh output directory. It should
not delete arbitrary installed folders; cleanup must be limited to known,
script-generated output paths or handled manually. Keep the full tokenized
package as a separate distribution option.

### Dedicated `they` QA pass

Before finalizing a dialogue batch or NPC, run a dedicated pass for the `they`
branch. In Bulgarian, plural agreement often extends beyond the obvious noun or
adjective inside the variant tag. Check the whole sentence for singular forms
that also need to change.

Common leak points include:

- `си` -> `сте`;
- `ти` -> `ви`;
- `теб` -> `вас`;
- `те` as an object pronoun -> `ви` when addressing the player;
- `кажи` -> `кажете`;
- `искаш` -> `искате`;
- `можеш` -> `можете`;
- `настани се` -> `настанете се`;
- `почини си` -> `починете си`;
- `забрави` -> `забравете`;
- `стопли се` -> `стоплете се`;
- `ще пристигнеш` -> `ще пристигнете`.

Do not assume that tagging only the gendered adjective or noun is sufficient.
If the surrounding verb, pronoun, auxiliary, or imperative changes for plural
`they`, include that part in the variant as well. Multiple variant groups may
appear in the same sentence only when they represent genuinely independent
agreement choices. Prefer one complete grouped token per line:

```text
<he>...</he><she>...</she><they>...</they>

An apparently gender-neutral line may still require a player-variant token.
Check singular versus plural/polite address (`ти` versus `ви`, singular versus
plural verbs, and related pronouns) even when the he and she branches would be
identical. A line must match the established `they` style whenever it directly
addresses the player; “no gender difference” is not the same as “no variant
needed”.
```

Keep the whole player-dependent phrase inside that one group whenever the
Bulgarian remains natural. This makes the variants easier to search, review,
and extend later. Use multiple groups only when one group would create bad
Bulgarian grammar or would combine unrelated agreement decisions.

### Prompts are player choices

Entries under a `prompts` path are the player's selectable answer or response,
not an NPC line addressed to the player. Do not add `<he>/<she>/<they>` tokens
to prompts merely because they contain `ти`, `теб`, or a singular verb. Add a
variant only when the prompt itself genuinely changes with the player's gender
or another required player-specific form. Review prompt text separately from
the surrounding NPC dialogue.

### Do not neutralize away meaningful player variants

Do not rewrite a line into a neutral form merely to avoid authoring
`<he>/<she>/<they>` branches. If Bulgarian agreement, address, number, humor,
characterization, or the meaning of the source benefits from the distinction,
keep the branches and translate each one deliberately. Neutral wording is
preferred only when it is genuinely natural and does not erase a useful
distinction. A mechanically neutral sentence is not automatically better than
three clear, natural variants.

## Kinship terms in natural dialogue

For `Great Aunt` / `Great Aunt Elsie`, prefer `леля` / `леля Елси` in ordinary
dialogue when the exact genealogical degree is not relevant to the scene.

The literal Bulgarian kinship term `пралеля` is correct and is written as one
word, but it is uncommon and visually easy to misread in fast-moving dialogue.
Using `леля` keeps the relationship clear and the line natural for the player.
Retain `пралеля` only where the exact family relationship itself is important,
for example in genealogy, exposition, or a line that explicitly contrasts
family generations.

## Children in partner-specific dialogue

Child-related dialogue is authored separately for each partner. Do not assume
that `[child_0]` has one universal gender. Verify the corresponding delivery or
relationship lines for that partner before using gendered Bulgarian agreement.

For Celine's partner-specific lines, the child is a boy (`baby boy`, `him`,
`grandson` in the source), so masculine agreement is correct there. Other
partners can have a girl and need their own review.

## Language asset IDs

The `translation` and `src_cache` values in `l10n.meta.toml` must exactly match the `id` values written to `translations/bul.meta.toml` and `source_caches/bul.meta.toml`. The current project keeps these IDs stable between builds. If either ID is intentionally changed, update `l10n.meta.toml` at the same time.

## Bulgarian typography

- Use Bulgarian quotation marks `„...“` in player-facing text.
- When the source ends a line with an ASCII hyphen because the speaker is
  interrupted or the thought is deliberately left unfinished, review it in
  context and normally render the interruption with an ellipsis (`...`). Do
  not copy the ASCII hyphen mechanically, and do not replace every trailing
  hyphen without checking the surrounding dialogue.
- Do not leave em dashes (`—`) in the generated translation. The overlay builder converts them according to the surrounding text.
- Preserve the Bulgarian letter `ѝ` where it means “to her”; do not replace it with plain `и`.

## Bulgarian font glyphs

The custom `fnt_mistria_birdseed_bul.ttf` is generated from the game's Birdseed
font with selected glyph outlines imported from the game's Silver font. The
generator is:

```text
tools/build_mistria_bulgarian_font.py
```

Current generated glyphs:

- `Ѝ` uses the Silver outline, scaled to the width of Birdseed `И`;
- `ѝ` uses the Silver outline, scaled to the width of Birdseed `и`;
- `„` is composed from two native Birdseed commas;
- `“”` are composed from two native Birdseed apostrophes.

Do not replace the TTF with an unverified copy. Any future font change must be
checked in the standard, textbox, and popup-description styles, then tested in
the game with `Ѝ`, `ѝ`, `„`, `“`, and `”`.

The game also ships the 11x14 baked asset
`assets/animations/UI NEW/Fonts/spr_ui_dialogue_font_birdseed_bof.png`, but the
Bulgarian package must not replace it. Fields of Mistria 1.0.2 testing showed
that a 269-glyph Bulgarian TTF with appended `Ѝѝ„“”` entries renders those
characters, while remapping them onto five old glyph slots and replacing the
baked atlas makes the same characters render as missing squares. Keep the
working appended-glyph strategy unless a future game update changes the font
loader, and archive every tested TTF by SHA-256 before replacing it.
