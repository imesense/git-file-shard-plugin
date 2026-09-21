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

## Explicitly Out of Scope

- Core plugin functionality (split/merge/scan) — not yet formalized.

## Technical Notes

- Installer script: `src/ImeSense.GitFileShardPlugin.Setup.Inno/Setup.iss`,
  built with Inno Setup 7 (`ISCC.exe Setup.iss` →
  `bin/GitFileShardPlugin.exe`).
- `Setup.iss` conventions: 4-space indentation; Pascal `{ ... }` comments must
  never contain Inno constants such as `{app}` (the first `}` closes the
  comment); every user-visible task message must exist in both
  `Locales/Options.eng.isl` and `Locales/Options.rus.isl`.
- Markdown files follow `.editorconfig`: CRLF line endings, 2-space list
  indentation, MarkdownLint rules from `.markdownlint.yaml`.

## History Context

The `innosetup-installer` capability was formalized as change
`add-innosetup-installer` (archived 2026-09-19).
