# GitHub and Nexus Mods publishing

Every mod is packaged, released, and published independently. Font Choices,
Journal Wider, and Bulgarian Localization must never share a release archive,
Nexus description, changelog, or Nexus file group.

## First release of a mod

Upload version `0.1.0` manually to its already-created Nexus page. This first
upload creates the main file's **Group ID**. Keep the exact archive and its
SHA-256 record with that release.

The Nexus workflow is deliberately manual-only. It cannot run merely because a
GitHub release was published.

## Per-mod release assets

| Target | Required archive name | Manifest ID | Release text directory |
| --- | --- | --- | --- |
| `font-choices` | `FontChoices-<version>.zip` | `font_choices_act` | `release/font-choices/` |
| `journal-wider` | `JournalWider-<version>.zip` | `wide_journal_act` | `release/journal-wider/` |

`<version>` is the exact `MAJOR.MINOR.PATCH` version in the archive's
`manifest.toml`.

Each release text directory has its own `nexus-description.bbcode` and
plain-text `nexus-changelog.txt`. The workflow sends only the selected target's
changelog. Nexus page descriptions are updated manually, so a release cannot
replace another mod's page text.

## Secrets after the first manual upload

Configure these as GitHub repository secrets, never in source files:

- `NEXUS_API_KEY`: shared Nexus API key.
- `NEXUS_FONT_CHOICES_MOD_ID`: Font Choices page ID (`1448`).
- `NEXUS_FONT_CHOICES_FILE_ID`: Font Choices main-file Group ID.
- `NEXUS_JOURNAL_MOD_ID`: Journal Wider page ID (`1449`).
- `NEXUS_JOURNAL_FILE_ID`: Journal Wider main-file Group ID.

Nexus calls the file-chain value a **Group ID**. The upload action calls the
same value `file_id`; it is distinct from the numeric mod-page ID.

## Safe upload procedure

1. Build and test one mod archive locally.
2. Confirm it contains exactly one `manifest.toml`, with the expected ID and version.
3. Create a GitHub release containing the one exact archive name from the table.
4. For a first release, upload that archive manually to the matching Nexus page
   and store its Group ID in the matching repository secret.
5. For later releases, manually start `Publish Selected Mod to Nexus`, supplying
   the target, exact version, and exact GitHub release tag.
6. Review the workflow summary and Nexus file page before announcing it.

The workflow downloads one exact filename, verifies the archive manifest ID and
version, resolves only the selected page's internal Nexus ID, and uploads only
to the selected page's Group ID. It has no wildcard archive selection and no
release-published trigger.

## Privacy and copyrighted source data

Do not commit the original game `assets.zip`, extracted localization files,
complete English source-key dumps, generated game archives, or other
copyrighted game data. Keep those files locally and generate release archives
only when needed. Review every public package and document before release.
