# Fields of Mistria 1.0 localization findings

Inspection date: 2026-08-05  
Archive inspected: `C:\Program Files (x86)\Steam\steamapps\common\Fields of Mistria\assets.zip`  
Original archive SHA-256: `fad572e94321933172f0af0ef570c23577621d19fa51b4b0d6da61ced9775e43`

## Format

The game-localization root is `assets/localization/` and contains exactly:

- `l10n.meta.toml`
- `translations/*.meta.toml`
- `source_caches/*.meta.toml`

All 15 inspected files are UTF-8 TOML (with a UTF-8 BOM in the shipped files) and parse successfully.

`l10n.meta.toml` has:

- `[meta_properties]`: the localization asset ID and `asset_kind = "L10n"`.
- `[asset_properties.languages.<code>]`: language registration and display/runtime settings.
- `[asset_properties.languages.<code>.pronouns]`: optional pronoun display records and macro bindings.
- `[asset_properties.fiddle_renames]`: path/pattern rules telling the game which source asset fields are localized.

English (`eng`) has no `translation` or `src_cache` field because the source game data is already English. Other languages point to a translation asset ID and a source-cache asset ID. The shipped language codes are `eng`, `jpn`, `zh-Hans`, `zh-Hant`, `spa`, `fra`, `kor`, and `rus`.

Translation files are flat TOML tables:

```toml
[meta_properties]
id = "..."
asset_kind = "L10nTarget"

[asset_properties]
"source/key/path" = "translated text"
```

Source caches use the same flat key/value shape, with `asset_kind = "L10nSourceCache"`, and store the English source string for each cached key. They are not a second translation format and are not split into plural/gender objects.

Translations are split into one file per language, not into thematic files. Each language has one translation file and one source-cache file. A translation may contain fewer or more keys than the current source cache; this is already true in the shipped data.

There is no explicit fallback-language field in the inspected TOML. Missing translation keys therefore appear to rely on the game’s runtime source/English fallback. The static format supports incomplete language files, but a runtime test is still required before treating fallback behavior as guaranteed for every UI path.

## Counts

The French source cache is the complete source-key reference found in this installation: **38,191 source entries**.

| Language/file | Translation entries | Missing source keys | Extra keys | Source-cache entries |
|---|---:|---:|---:|---:|
| French (`fra`) | 38,191 | 0 | 0 | 38,191 |
| Japanese (`jpn`) | 34,177 | 4,369 | 355 | 34,177 |
| Korean (`kor`) | 42,230 | 13 | 4,052 | 42,230 |
| Russian (`rus`) | 38,164 | 32 | 5 | 38,164 |
| Spanish (`spa`) | 38,187 | 13 | 9 | 38,187 |
| Simplified Chinese (`zh-Hans`) | 42,230 | 13 | 4,052 | 42,230 |
| Traditional Chinese (`zh-Hant`) | 42,230 | 13 | 4,052 | 42,230 |

Available languages: **8**, including English. Duplicate assignment detection found **0 duplicate keys** in all extracted files; TOML parsing also succeeded for every file.

The source contains **4,529 bracket-token occurrences in 4,440 entries**, including `[Ari]`, `[farm_name]`, `[child_0]`, `[pet_name]`, and item/event placeholders. It contains **428 markup-tag occurrences in 35 entries**, chiefly `<they>`, `<she>`, `<he>`, `<it>`, `<none>`, and `<else>` pairs. It contains **4 printf-style occurrences** (`% f`). Backslash escape sequences are represented in the parsed TOML strings as actual newlines/tabs where applicable; the source files must retain their original escaped representation when serialized.

The source also contains 1,706 `$...` occurrences in 1,500 entries. These are source text/macro-like tokens seen in the data and must be preserved exactly until their runtime semantics are confirmed; they are not assumed to be ordinary Bulgarian-translatable text.

There are no dedicated plural, gender, or variant value objects. Gender/pronoun behavior is represented by language metadata plus conditional markup in a small subset of strings. Path-name heuristics found 56 plural/count-related keys, 19 gender-related keys, and 123 variant-related keys; these are key-name classifications, not separate TOML structures.

## Can Bulgarian be registered directly?

Yes, the format has a direct language-registration slot: add a new language table such as `asset_properties.languages.bul`, a translation file such as `translations/bul.meta.toml`, and a matching source cache such as `source_caches/bul.meta.toml`. No existing language slot needs to be reused. Reusing a slot would risk changing that language’s identity, settings, and future update behavior.

The proof of concept uses `bul` and registers it with `display_name = "Български (POC)"`, a translation asset ID, and a source-cache asset ID. The exact runtime language-picker behavior for an unshipped language (`ship = false`) should be tested in-game before a full release.

## MOMI 0.15.0 assessment

The current implementation does support the new archive and generic TOML mechanics:

- `AssetsStore` opens `assets.zip`, creates/uses `assets.bak.zip`, and rebuilds the archive.
- `TOMLCollector` collects arbitrary mod `.toml`/`.meta.toml` files outside `momi/`.
- `TOMLInstaller` writes them below the game `assets/` root and recursively merges TOML tables.
- `MOMIOperations.MergeTomlTables` supports ordinary key replacement/addition and MOMI directives.
- `manifest.toml` is accepted, alongside legacy JSON manifests.

Therefore a normal MOMI overlay can technically target `localization/l10n.meta.toml`, `localization/translations/bul.meta.toml`, and `localization/source_caches/bul.meta.toml` from a mod root. There is no dedicated localization option, language-file option, or special `assets/localization` handler; it is covered by generic TOML installation.

For this project, MOMI is not sufficient as the only writer because its current store implementation copies/updates the live archive, may overwrite `assets.bak.zip`, has no recorded game hash/update guard, and does not perform an atomic replacement. The project therefore uses option **C**, a focused standalone injector. The overlay remains MOMI-compatible so it can be upstreamed or used through MOMI after the installer’s archive safety and localization-specific behavior are strengthened.

## Proof of concept result

The POC modifies a copied archive only. The exact content changes are:

1. Replace `assets/localization/l10n.meta.toml` by appending the validated `bul` registration.
2. Add `assets/localization/source_caches/bul.meta.toml` with one source key.
3. Add `assets/localization/translations/bul.meta.toml` with one clearly identifiable test translation: `ТЕСТ БГ: Земеделие`.

No other ZIP entry content changed. The resulting archive passed `zipfile.testzip()`, the localization inspector, and TOML parsing. A second application reported zero changed entries and kept the same output hash.

The injector creates a non-overwriting backup, records SHA-256 hashes, validates TOML before writing, writes a temporary archive beside the target, validates it, and atomically replaces the target. Restore copies the verified backup through the same temporary-file-and-atomic-replace path.

## Preservation rules

The Bulgarian pipeline must preserve keys, ordering where practical, UTF-8 Cyrillic text, placeholders, markup tags, printf tokens, newlines, escapes, and `$...` runtime-sensitive tokens. Only player-facing string values should be translated. Generated archives, extracted copyrighted localization data, and the original game archive are excluded from Git.

