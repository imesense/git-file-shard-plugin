# Project Context

## Overview

- **git-file-shard** — Git plugin (Python 3.8+) that splits large files into
  shards and merges them back, so repositories can track big binary assets.
- Distributed as a standalone binary (`dist/git-file-shard.exe`, registered by
  Git as the `git file-shard` subcommand) and as a Windows installer.
- License MIT, publisher ImeSense, default branch `default`.

## Scope Formalized in OpenSpec

- `innosetup-installer` — Windows installer built with Inno Setup 7
  (`src/ImeSense.GitFileShardPlugin.Setup.Inno/`). Implemented and archived:
  `changes/archive/2026-09-19-add-innosetup-installer/` (source commits
  `3a20e98` → `b881a55` → `6909e5b`, 2026-09-03/04).
- `wix-installer` — MSI package built with WiX Toolset 7
  (`src/ImeSense.GitFileShardPlugin.Setup.Wix/`). Implemented and archived:
  `changes/archive/2026-09-21-add-wix-installer/` (2026-09-21); options
  dialog and PATH registration verified by manual install.
- `pkg-installer` — macOS distribution package built with the stock
  `pkgbuild` / `productbuild` tools
  (`src/ImeSense.GitFileShardPlugin.Setup.Pkg/`). Implemented and archived:
  `changes/archive/2026-09-27-add-pkg-installer/` (2026-09-27); install,
  symlink PATH integration and uninstall verified by manual install.

## Explicitly Out of Scope

- Core plugin functionality (split/merge/scan) — not yet formalized.

## Technical Notes

- Installer script: `src/ImeSense.GitFileShardPlugin.Setup.Inno/Setup.iss`,
  built with Inno Setup 7 (`ISCC.exe Setup.iss` →
  `bin/GitFileShardPlugin.exe`).
- macOS package: `src/ImeSense.GitFileShardPlugin.Setup.Pkg/build.sh`
  (`util/build-pkg-arm64.sh <version>` / `util/build-pkg-x86_64.sh
  <version>` → `bin/GitFileShardPlugin.v<version>.<arch>.pkg`);
  identifier `org.imesense.git-file-shard`, install location
  `/Library/Application Support/ImeSense/Git File Shard Plugin`,
  `/usr/local/bin/git-file-shard` symlink created by `postinstall`.
- `Setup.iss` conventions: 4-space indentation; Pascal `{ ... }` comments must
  never contain Inno constants such as `{app}` (the first `}` closes the
  comment); every user-visible task message must exist in both
  `Locales/Options.eng.isl` and `Locales/Options.rus.isl`.
- Markdown files follow `.editorconfig`: CRLF line endings, 2-space list
  indentation, MarkdownLint rules from `.markdownlint.yaml`.

## History Context

The `innosetup-installer` capability was formalized as change
`add-innosetup-installer` (archived 2026-09-19).
