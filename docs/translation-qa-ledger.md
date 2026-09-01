# Translation QA ledger

This is the working ledger for the Bulgarian localization. It records scope
and decisions; it is not a claim that a batch is final merely because it has a
translation or QA commit.

## Workflow

1. GPT prepares a source-grounded translation batch.
2. The batch is checked for placeholders, markers, terminology, meaning,
   character voice, and natural Bulgarian.
3. A dedicated `they` pass checks the whole sentence, not only the tagged word.
4. The batch is compared with earlier translations and the glossary.
5. Only after manual review is it marked `reviewed` here.

The ongoing QA pass uses a temporary merge of all current files in
`translation/work/`, produced by `tools/build_bg_overlay.py`. The merged
output is checked with `tools/qa_bg_translation.py`; the old generated package
must not be used as the current QA input because it contains only an earlier
snapshot. The QA tool separates exact English fallbacks, structural errors,
semantic review candidates, gender-token style candidates, and line-length
warnings. Both tools are tracked project files on branch `temp-translation`.

## Player-variant token standard

When a line depends on the player's gender or number, keep the complete
player-dependent phrase in one grouped token:

```text
<he>...</he><she>...</she><they>...</they>
```

This is the preferred form because it makes search, QA, and possible future
extension easier. Multiple groups are allowed only when separate agreement
choices are genuinely required for natural Bulgarian.

## Scope status

| Area | Translation present | QA status | Notes |
| --- | --- | --- | --- |
| Juniper banked dialogue | Yes | Reviewed / conductor pass 1 | Context, voice, terminology, and gender grouping checked; advisory checker candidates accepted where structurally valid. |
| Juniper gifts | Yes | Reviewed / conductor pass 1 | Gift terminology, tone, and player variants checked. |
| Juniper market | Yes | Reviewed / conductor pass 1 | Puns, item markers, terminology, and voice checked. |
| Juniper museum | Yes | Reviewed / conductor pass 1 | Lore, canonical item markers, and terminology checked. |
| Juniper dates/relationship/marriage | Yes | Reviewed / conductor pass 1 | Agreement, context, grouped-token structure, and voice checked. |
| Josephine | Yes | Complete for current QA cycle | Banked dialogue 01–04, gifts, market 01–02, and museum dialogue reviewed; corrected one missing greeting variant and one punctuation artifact. Remaining global QA candidates are not Josephine-specific blockers. |
| Elsie | Yes | Reviewed / conductor pass 1 | Main, gift, market, and museum dialogue checked for context, voice, terminology, semantic accuracy, and player variants. |
| Eiland | Yes | Partial / historical QA | Must be audited against current rules and glossary. |
| Seridia | Yes | Not started | Present in the source catalog, but no Seridia work file exists; package entries are still English fallback. Approximately 1306 source keys are available for a future translation-only pass. |
| Celine early banked dialogue | Yes | Complete for current QA cycle | Full file pass completed; corrected missing player-variant branches, punctuation, awkward phrasing, and legacy translation errors. TOML and automated QA checks pass. |
| Celine dates | Yes | Complete for current QA cycle | Bathhouse, beach, deep-woods picnic, gem cutting, inn-meal, park, and post-baby date lines reviewed; direct-address variants and obvious grammar issues corrected. |
| Dell market dialogue | Yes | Complete for current QA cycle | Market lines reviewed against English; added missing player-address variants for direct questions. `Зорел` remains feminine (`най-яката`). |
| Dell museum dialogue | Yes | Complete for current QA cycle | Museum lines reviewed; corrected missing player variants in donation/bringing/catching lines, fixed singular `Светкавично водно конче`, and kept `Драконова стража` as the organization name. |
| Dell main dialogue and gifts | Yes | Complete for current QA cycle | Main banked and gift lines reviewed; corrected player variants, token boundaries, and punctuation. Remaining automated candidates are contextual false positives (`ще те наричаме` and a non-player character subject). |
| Hemlock gifts and museum dialogue | Yes | Complete for current QA cycle | Gift and museum batches reviewed; added missing `казваш/казвате`, `Познаваш ме/Познавате ме`, and `теб/вас` variants. Museum phrasing checked; no other certain corrections found. |
| Hemlock main and market dialogue | Yes | Complete for current QA cycle | Main dialogue files 01–03 and Market files 01–02 reviewed; corrected player variants, imperative forms, item/location inflection, and one awkward sentence. Remaining line-length warnings are informational. |
| Errol | Yes | Complete for current QA cycle | All seven work files covering the 175 current Errol dialogue keys reviewed; corrected missing player-address variants, imperative forms, and `ти/ви`/`теб/вас` agreement. Remaining automated candidates are false positives for non-player subjects or item descriptions. |
| Caldarus | Yes | Partial / translation in progress; QA complete for current work | QA complete for the 436 currently translated keys in `bul_caldarus_statue_general_early.meta.toml`, `bul_story_caldarus_essence_follow_up.meta.toml`, and `bul_story_mines_caldarus_recovery.meta.toml`. No stale extras remain; 2554 current Caldarus keys are still untranslated and require a later translation pass. |
| Items, quests, UI, tutorials | Yes | Partial / historical QA | Check terminology drift and source coverage. |

## Open decisions

- `Monster Powder`: temporarily prefer `Прах от чудовище`; compare against the
  item name `Чудовищен прах` before finalizing the glossary rule.
- `Wintergreen`: approved project spelling is `гаултерия`; keep it consistent
  in glossary, item names, and dialogue unless a later source-grounded choice
  requires a contextual form such as `плод на гаултерията`.
- `Acolyte` / `devotee` / `follower`: distinguish religious/lore meaning from
  ordinary following and document the approved Bulgarian forms.
- `Wheedle`: current approved name is `Уийдъл`; preserve deliberate jokes such
  as `Greedle`/`Weasel` only when they are source-supported wordplay.

## Review labels

- `translated`: a work file exists.
- `automated-checked`: syntax, markers, or structural checks passed.
- `voice-checked`: character voice and tone reviewed.
- `terminology-checked`: glossary and earlier usage reviewed.
- `they-checked`: all relevant plural/agreement changes reviewed.
- `reviewed`: all applicable checks above completed by the conductor.

## Initial findings from the current audit

- **Corrected — Eiland romantic `eiland_post_8h_romantic_0/3`:** the source
  explicitly says that Eiland sees the person he cares about every day. The
  Bulgarian line now preserves that meaning with one grouped object variant:
  `да <he>го виждам</he><she>я виждам</she><they>ви виждам</they>`.
- **Reviewed — Juniper marriage `morning_0/2`:** after checking the exchange
  `Добро утро` → `Спа ли добре?`, the line was rewritten as one grouped token:
  `Аз определено спах чудесно, щом ти беше до мен` / `... щом бяхте до мен`.
  This preserves the affectionate meaning while sounding natural for Juniper.
- **Not a defect by itself:** the gender checker reports lines with a large
  shared prefix/suffix. These are review candidates only; a single grouped
  token is often exactly the desired structure.
- **Semantic/style candidate — Juniper market `market_zorel_1/init`:** the
  source asks which *genre* of `$Song Crystal$` Dozy would prefer, while the
  current line begins `Какъв $Музикален кристал$...`. Verify whether the
  Bulgarian should explicitly retain `жанр`, so the question is about musical
  style rather than which item to choose.
- **Reviewed — Juniper market `market_zorel_1/init`:** retained the established
  `Музикален кристал` term and added `жанр музика` only to make this dialogue
  question natural and clear. This does not establish that individual crystals
  have formal in-game genres.
- **Reviewed — Wheedle spelling:** five Juniper lines used `Уидъл` even though
  the glossary, NPC name, and the rest of the dialogue consistently use
  `Уийдъл`. The five occurrences were normalized to the approved spelling.
- **Reviewed — UI/item terminology pass:** `Pet` as an action is now `Погали`,
  while the noun/default name remains `Любимец`; `Inspect` is `Преглед`,
  `Pin Spell` is `Закачи`, and the short summary label is `Обобщ.`. The
  natural-material and item fixes are `Парче естествено стъкло`, `Рог от бик`,
  and `да убие мигновено`.
- **Reviewed — Essence Bat terminology:** the creature is a named monster,
  not an adjective meaning “essential”; the approved form is `прилеп на
  есенцията`, plural `прилепи на есенцията`, used consistently in drops and
  pet-skin names/descriptions.
- **Reviewed — grouped-token cleanup:** the Juniper reagent question,
  rosewater-bath greeting, and ancient-royal-scepter museum line were each
  consolidated into one complete `<he>/<she>/<they>` group. The branches were
  balanced before and after the edit; this is a structural cleanup, not a
  change to the intended meaning.
- **Reviewed — Juniper museum item markers:** four dialogue references did not
  match the canonical item names: `Древен кралски скиптър`, `Мъглена пеперуда`,
  `Димна пеперуда`, and `Пеперуда на залеза`. The museum dialogue was aligned
  with those item names, including the surrounding Bulgarian agreement.
- **Reviewed — Juniper banked grouped tokens:** several bathhouse/register
  lines whose alternatives all addressed the same player were consolidated to
  one complete triple token. No independent agreement choice was lost.
- **Reviewed — remaining seven Juniper banked multi-groups:** all seven were
  confirmed to address the same player throughout the line and were
  consolidated into one complete triple token. The `they` variants retain
  plural agreement in every affected verb/pronoun.
- **Reviewed — Juniper gifts:** the `Fog Orchid` line was aligned to the item
  name `Мъглива орхидея` with matching singular agreement, and `Witch Queens`
  was normalized to the established `кралиците-вещици`. Other checked gift
  item names were already consistent, including Newt, Water Chestnut Fritters,
  Middlemist, Nettle, and Monster Powder (still provisional as documented).
- **Reviewed — Juniper market:** the Wheedle `Fast Food` reference was aligned
  to the canonical marker text `Бърза храна`, and the predicate was corrected
  to feminine agreement: `изглежда изкушаваща`.
- **Reviewed — Juniper relationship files 01–10:** corrected the two basement
  lines that mistranslated `couldn't resist ... one last time` as an inability
  to resist a conversation/seeing someone. They now express the intended
  meaning naturally: one more chat in the best-friend line and one more visit
  in the romantic line. Also fixed a pregnancy line that mixed singular `ти`
  with plural `можете`.
- **Reviewed — Juniper relationship files 11–20:** consolidated the snowy
  morning line's two dependent player-address groups into one complete triple
  token. No additional certain translation error was found in this batch.
- **Reviewed — Juniper relationship files 21–29:** no certain semantic error
  was found in the workstation, post-wedding, best-friend, or romantic batches.
  The snowy/hand-holding and other dependent address groups remain structurally
  valid; voice candidates such as the `сладурство` joke were kept as deliberate
  character humor.
- **Status — Juniper:** first conductor QA pass complete across banked, gifts,
  market, museum, date, and relationship/marriage dialogue. The advisory
  gender-checker warnings are retained as accepted structural candidates, not
  open defects.
- **Status — Josephine:** conductor review started, but token audit is still
  pending. The current inventory is 169 work values, of which 39 already have
  player-variant branches and 130 are unbranched. The 130 are candidates for
  contextual review, not an instruction to add tokens mechanically.
- **Josephine token-audit rule:** an unbranched line is not automatically
  gender-neutral. If it addresses the player, check whether its singular
  `ти`/verb/pronoun forms need a plural or polite `ви`/verb/pronoun branch for
  `they`, even when the he and she text would be identical.
- **Reviewed — Josephine museum terminology:** `Призрачна гъба` is retained as
  the preferred short, game-facing term for `$Spirit Mushroom$`. The glossary,
  museum line, forage item, and spirit-mushroom tea name now use it
  consistently; no player variant was needed in the museum batch.
- **Reviewed — Josephine liked flower gift:** the discourse opener `You know,`
  rendered as `Знаеш ли` is an actual player-facing address in Bulgarian, so
  it now has the minimal `Знаеш ли/Знаете ли` branch. The rest of the line is
  shared naturally.
- **Dialogue-branch QA rule — follow the topology:** numbered dialogue keys are
  not always one linear sequence, and a prompt may appear directly under
  `init` or after any numbered line. Trace each prompt's actual follow-up
  branch in the source, including all consecutive replies before the next
  prompt. In the Eiland dragonsworn block specifically, technical
  `prompts/0` is displayed as prompt 1 and its first NPC continuation is
  `/4` (`/4_eog` in that state branch), followed by `/6`, `/8`...; technical
  `prompts/1` is prompt 2 and its first NPC continuation is `/5` (`/5_eog`),
  followed by `/7`, `/9`.... These numbers are node identifiers, not a
  universal response numbering scheme. Use this even/odd pattern only for
  this verified block. The `_n` and `_eog` suffixes identify alternate
  authored state branches; they are not prompt numbers.
