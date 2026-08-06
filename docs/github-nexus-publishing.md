# GitHub and Nexus Mods publishing

The first version of each mod should be uploaded to Nexus Mods manually. No Nexus secret is needed for that release.

The not-yet-active workflow template is stored at
`docs/workflows/publish-nexus-from-release.yml.example`. Because it is not
under `.github/workflows/`, GitHub Actions will not discover or run it.
Activate it only after the first manual Nexus upload has created the target
main file.

## Secrets used after the first Nexus file exists

If GitHub Actions is enabled later, configure these as repository secrets:

- `NEXUS_API_KEY`: the Nexus API key used by the upload action.
- `NEXUS_BG_FILE_ID`: the v3 `mod_file` ID of the Bulgarian mod's existing main file.
- `NEXUS_BG_MOD_ID`: the v3 internal Nexus mod ID used for the Bulgarian mod's changelog entries.

These values have different meanings. `NEXUS_BG_FILE_ID` is not a replacement for `NEXUS_BG_MOD_ID`, and the older `NEXUS_FILE_GROUP_ID` must not be used with the current v3 upload action. A future mod receives its own namespaced pair, while `NEXUS_API_KEY` remains shared.

The numeric ID in a Nexus mod URL is game-scoped. It can be used with the Nexus v3 API to resolve the internal mod ID and then list the mod files. The active main file's `id` is the value used for `NEXUS_FILE_ID`.

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
