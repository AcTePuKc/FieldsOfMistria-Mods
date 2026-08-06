# Fields of Mistria Bulgarian Localization

Work-in-progress Bulgarian localization for Fields of Mistria 1.0.x.

This repository contains translator-owned work files, terminology, validation tools, and packaging documentation. Extracted game assets, the original game archive, generated source-key dumps, and generated archives are intentionally excluded from Git.

The project is currently intended to remain private while the translation and release workflow are being prepared. A public release should contain only the files needed to distribute the finished localization and its documentation.

## Workflow

1. Inspect the current game archive with the tools in `tools/`.
2. Prepare and review Bulgarian work files under `mods/bulgarian-localization/translation/work/`.
3. Run the Bulgarian token-preservation QA tool before packaging.
4. Build a MOMI-compatible localization package or use the safety-checked injector for local testing.
5. Validate the resulting archive before using it in the game.

See `mods/bulgarian-localization/translation/README.md` for the translation workflow and `docs/github-nexus-publishing.md` for the optional Nexus Mods release automation.

## Release policy

The first Nexus Mods release will be uploaded manually. GitHub-to-Nexus automation will only be enabled after the first Nexus main file exists and its identifiers have been verified.
