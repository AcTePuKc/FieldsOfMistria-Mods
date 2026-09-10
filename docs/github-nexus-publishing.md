# GitHub and Nexus Mods publishing

Every mod and Vortex extension is packaged, released, and published
independently. They must never share a release archive, Nexus description,
changelog, or Nexus file group.

## First release of a mod

The manually dispatched Nexus workflow creates the initial main file when the
selected mod has a page ID but no File ID secret yet. Keep the exact archive
and its SHA-256 record with that release. Then copy the update File/Group ID
shown in the Nexus UI into the matching repository secret. The workflow's API
notice is an internal `mod-file` ID, not the legacy File/Group ID used for
updates. The workflow has no automatic trigger: a GitHub release alone can
never publish anything to Nexus.

## Per-mod release assets

| Target | Required archive name | Package check | Release text directory |
| --- | --- | --- | --- |
| `font-choices` | `FontChoices-<version>.zip` | `font_choices_act` manifest | `release/font-choices/` |
| `journal-wider` | `JournalWider-<version>.zip` | `wide_journal_act` manifest | `release/journal-wider/` |
| `vortex-support` | `AIM-Vortex-Support-<version>.zip` | root `index.js`, `info.json`, `gameart.png` | `release/vortex-support/` |

`<version>` is the exact `MAJOR.MINOR.PATCH` version in the archive's manifest
or Vortex extension `info.json`.

Each release text directory has its own `nexus-description.bbcode` and
plain-text `nexus-changelog.txt`. The workflow sends only the selected target's
changelog. Nexus page descriptions are updated manually, so a release cannot
replace another mod's page text.

## Registry and repository secrets

`release/nexus-targets.json` is the public registry for release metadata:
archive prefix, manifest ID, release-text directory, display name, and the two
secret names. Add one entry there for a new mod; the workflow itself does not
need to change.

Configure these as GitHub repository secrets, never in source files:

- `NEXUS_API_KEY`: shared Nexus API key.
- `NEXUS_FONT_CHOICES_MOD_ID`: Font Choices page ID (`1448`).
- `NEXUS_JOURNAL_MOD_ID`: Journal Wider page ID (`1449`).
- `NEXUS_FONT_CHOICES_FILE_ID`: optional for the initial upload; required for
  later Font Choices updates.
- `NEXUS_JOURNAL_FILE_ID`: optional for the initial upload; required for later
  Journal Wider updates.
- `NEXUS_VORTEX_SUPPORT_MOD_ID`: Fields of Mistria Vortex Support page ID.
- `NEXUS_VORTEX_SUPPORT_FILE_ID`: optional for the initial upload; required for
  later Vortex Support updates.

The initial upload's API notice is not the update File/Group ID. Obtain the
correct Group ID from the Nexus UI, then add it to the matching secret before
publishing the next version. It is distinct from the numeric mod-page ID.

Vortex Support is a `site` Nexus page under **Vortex > Extensions**, not a
`fieldsofmistria` game-mod page. Its registry entry uses
`package_kind: vortex-extension` and `nexus_game_domain: site`; ordinary game
mods retain the default `fieldsofmistria` domain.

## Safe upload procedure

1. Build and test one mod archive locally.
2. Confirm a game-mod archive contains exactly one expected `manifest.toml`, or
   a Vortex archive has its three root files and matching `info.json` version.
3. Add the mod to `release/nexus-targets.json` and configure its two named
   secrets if it is a new target.
4. Create a separate GitHub release/tag for that one mod, containing only the
   exact archive name from the table.
5. Manually start `Publish Selected Mod to Nexus`, supplying the target, exact
   version, and that release tag.
6. After an initial upload, copy the update File/Group ID from the Nexus UI into
   the matching repository secret before its next update.
7. Review the workflow summary and Nexus file page before announcing it.

The workflow downloads one exact filename, verifies the archive manifest ID and
version, resolves only the selected page's internal Nexus ID, and uploads only
to the selected page. It has no wildcard archive selection and no
release-published trigger.

## Privacy and copyrighted source data

Do not commit the original game `assets.zip`, extracted localization files,
complete English source-key dumps, generated game archives, or other
copyrighted game data. Keep those files locally and generate release archives
only when needed. Review every public package and document before release.
