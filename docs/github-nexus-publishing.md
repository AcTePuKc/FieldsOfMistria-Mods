# GitHub and Nexus Mods publishing

The first version of each mod should be uploaded to Nexus Mods manually. No Nexus secret is needed for that release.

The first release can be packaged with the manually triggered
`Package Bulgarian Mod` workflow. It creates only a validated GitHub Actions
artifact and SHA-256 file; it does not contact Nexus Mods. Download that
artifact and upload it manually as version `0.1.0`. The package directory must
be populated first at `mods/bulgarian-localization/package/`.

After the first manual upload has created the target main file, the active
`.github/workflows/publish-nexus-from-release.yml` workflow can publish future
GitHub releases to Nexus Mods.

## Secrets used after the first Nexus file exists

If GitHub Actions is enabled later, configure these as repository secrets:

- `NEXUS_API_KEY`: the Nexus API key used by the upload action.
- `NEXUS_FILE_ID`: the existing main file's **Group ID** from Nexus's API Info
  dialog. The upload action retains the older `file_id` input name, although
  Nexus now calls this value a Group ID.
- `NEXUS_MOD_ID`: the numeric mod-page ID from the mod page URL. The workflow
  resolves Nexus's separate internal mod ID automatically before adding the
  changelog entry.

These values have different meanings. `NEXUS_FILE_ID` is not a replacement for
`NEXUS_MOD_ID`. A future mod receives its own pair, while `NEXUS_API_KEY`
remains shared.

The numeric ID in a Nexus mod URL is the value used for `NEXUS_MOD_ID`. Open
the main file's **API Info** dialog in the Nexus Files tab and copy its Group
ID as `NEXUS_FILE_ID`.

## Safe local lookup

For a future lookup, create a temporary ignored `.env` from `.env.example`, set only the API key, run the project helper, and remove the file immediately afterward. Never put the API key in a script, TOML file, workflow, README, issue, or commit.

The repository will not store `NEXUS_FILE_ID` or `NEXUS_MOD_ID` either. They belong in GitHub repository secrets after the first Nexus file has been created.

## Changelog formatting

Keep three kinds of release text separate:

- GitHub Release notes: English Markdown, suitable for GitHub readers.
- Nexus description: English public description in `release/nexus-description.txt`.
- Nexus changelog: Bulgarian plain text in `release/nexus-changelog.txt`, one change per line, without Markdown bullet prefixes.

The Nexus changelog is not the same as the GitHub Release body. The upload action sends the dedicated plain-text file to Nexus.

## Privacy and copyrighted source data

The repository should remain private during translation. Do not commit the original `assets.zip`, extracted localization files, complete English source-key dumps, generated game archives, or other copyrighted game data. Keep those files locally and generate release archives only when needed.

Before making the repository public, review the final package and documentation for source-data leakage and confirm that the distribution contents comply with the game's modding and distribution rules.
