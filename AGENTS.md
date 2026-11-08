# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project Overview

**git-file-shard** is a Git plugin that splits large files into shards and merges them back, so repositories can track big binary assets without storing the originals in Git. It ships as a standalone PyInstaller binary (`git-file-shard.exe` on Windows, `git-file-shard` on macOS, invoked by Git as the `git file-shard` subcommand) and as platform installers: an Inno Setup 7 EXE and a WiX Toolset 7 MSI for Windows, plus PKG and DMG packages for macOS.

- Language: Python 3.8+
- License: MIT (see `LICENSE.txt`)
- Default branch: `default`

## Repository Layout

```text
src/git_file_shard/     Python package (plugin core)
src/git_hooks/          Git hooks to copy into .git/hooks/
src/ImeSense.GitFileShardPlugin.Setup.Inno/   Inno Setup 7 EXE installer
src/ImeSense.GitFileShardPlugin.Setup.Wix/    WiX Toolset 7 MSI installer
src/ImeSense.GitFileShardPlugin.Setup.Pkg/    macOS PKG installer
src/ImeSense.GitFileShardPlugin.Setup.Dmg/    macOS DMG wrapper around the PKG
util/                   macOS PKG/DMG build wrappers (arm64/x86_64)
doc/                    integration-guide.md and usage-guide.md
openspec/               OpenSpec artifacts (project.md, specs/, changes/)
.github/workflows/      CI build workflow
bin/, build/, dist/     Build artifacts (git-ignored)
.pip/, .venv/           Local caches (git-ignored)
```

## Build & Verification Commands

There is no test suite. Verification means: byte-compile all sources, shell-check the build scripts, then build the artifacts relevant to the change.

Python tooling (virtual environment in `.venv/`, pip cache in `.pip/`; `pyinstaller` is the only pinned dependency, from `requirements.txt`):

```sh
python -m venv .venv
pip install --cache-dir .pip -r requirements.txt

# Syntax check
python -m compileall -q src
python -m py_compile git-file-shard.spec

# Build the standalone binary -> dist/git-file-shard.exe (Windows)
# or dist/git-file-shard (macOS)
pyinstaller git-file-shard.spec --noconfirm
```

Run the interpreter and PyInstaller from the activated virtual environment (on Windows: `.venv\Scripts\activate`). Build the binary on the target OS: PyInstaller does not cross-compile.

Shell syntax check (macOS build scripts; run on macOS or another bash-capable host):

```sh
bash -n src/ImeSense.GitFileShardPlugin.Setup.Pkg/build.sh
bash -n src/ImeSense.GitFileShardPlugin.Setup.Dmg/build.sh
bash -n util/build-pkg-arm64.sh
bash -n util/build-pkg-x86_64.sh
bash -n util/build-dmg-arm64.sh
bash -n util/build-dmg-x86_64.sh
```

Windows installers:

```sh
# Inno Setup 7 EXE -> bin/GitFileShardPlugin.exe
ISCC.exe src\ImeSense.GitFileShardPlugin.Setup.Inno\Setup.iss

# Compile check only, no output file
ISCC.exe --output=no src\ImeSense.GitFileShardPlugin.Setup.Inno\Setup.iss

# WiX Toolset 7 MSI -> bin/<culture>/GitFileShardPlugin.msi
dotnet build src\ImeSense.GitFileShardPlugin.Setup.Wix\ImeSense.GitFileShardPlugin.Setup.Wix.wixproj -c Release -o bin
```

`ISCC.exe` must be available on `PATH`. The Inno script expects `dist/git-file-shard.exe`, `README.md` and `LICENSE.txt` to exist, and writes output to `bin/`. Note: even `--output=no` deletes a stale file from the output directory, so rebuild after compile-only checks. The WiX build requires the .NET 8 SDK and the same payload; CI uploads `bin/en-US/GitFileShardPlugin.msi` and `bin/ru-RU/GitFileShardPlugin.msi`.

macOS installers (must run on macOS):

```sh
# Bundle the plugin first -> dist/git-file-shard
pyinstaller git-file-shard.spec --noconfirm

# PKG -> bin/GitFileShardPlugin.v<version>.<arch>.pkg
./util/build-pkg-arm64.sh <version>
./util/build-pkg-x86_64.sh <version>

# Plain PKG required by the DMG -> bin/GitFileShardPlugin.pkg
./util/build-pkg-arm64.sh <version> --plain-name

# DMG -> bin/GitFileShardPlugin.v<version>.<arch>.dmg
./util/build-dmg-arm64.sh <version>
./util/build-dmg-x86_64.sh <version>
```

The wrappers pass `<version>` and the architecture to the matching `build.sh` and forward extra arguments (for example `--sign <identity>` for the PKG). The PKG build verifies that the payload architecture matches `--arch`; the DMG build only wraps an existing plain PKG and never builds it. All installers expect `README.md` and `LICENSE.txt` in the repository root.

CI: `.github/workflows/build-application.yml` runs the byte-compile checks on `ubuntu-24.04`, then PyInstaller on `windows-2022`, `ubuntu-24.04` and `macos-14` and uploads `dist/`. The MSI, PKG and DMG jobs build from those artifacts; the Inno EXE job is currently disabled (`if: false`). Keep workflow commands and paths in sync with the local build steps above.

## Conventions

### OpenSpec

Spec-driven specification artifacts live in `openspec/` (structure per Fission-AI
OpenSpec; the CLI is not part of the toolchain here, files are maintained by
hand):

- `openspec/project.md` — project context for spec work.
- `openspec/specs/<capability>/spec.md` — current behavior (source of truth).
- `openspec/changes/<change-id>/` — `proposal.md`, optional `design.md`,
  `tasks.md`, and delta specs under `specs/<capability>/spec.md`.
- Delta specs use `## ADDED Requirements`, `## MODIFIED Requirements`,
  `## REMOVED Requirements` sections; requirements use RFC 2119 keywords and
  `### Requirement: <Name>` headings with `#### Scenario:` blocks
  (WHEN/THEN/AND bullets).
- Do not merge deltas or archive a change on your own initiative. An
  implementation request is not permission to archive. Archive only after an
  explicit user command and after the user has reviewed and verified the
  changes (build/manual test); until then keep the change under
  `openspec/changes/<change-id>/`.
- When the user asks to archive, merge `ADDED` / `MODIFIED` / `REMOVED`
  deltas into the capability spec, update the change's `tasks.md`, move the
  folder to `openspec/changes/archive/YYYY-MM-DD-<change-id>/`, and update
  `openspec/project.md` if scope or history changed.
- Archiving and committing are separate actions: do not create a Git commit
  as part of archiving unless the user explicitly asks for a commit.

### Python

- Docstrings in triple double quotes on all public functions.
- Single quotes for string literals; f-strings for interpolation.
- 4-space indentation (`.editorconfig`).
- Imports: stdlib first, then project (`from os import path` style is used).
- User-facing output via `print()` with `Error:` / `Warning:` prefixes.
- CLI parsing uses `argparse` with subcommands; keep new flags consistent
  with the existing ones (`--repo`, `--threshold`, `--md5`).

### Shell scripts (`src/*/build.sh`, `util/*.sh`)

These rules apply to every shell build script; platform-specific rules live in
the sub-sections below.

- Bash with `set -euo pipefail`.
- 4-space indentation; comments in English.
- Print errors to stderr with an `Error:` prefix and exit non-zero; print the
  usage line on invalid or missing arguments.
- Keep `util/` wrappers as thin forwarders; build logic belongs in `build.sh`.

#### macOS

- `--version` and `--arch arm64|x86_64` are required, with no defaults.
- Check that the script runs on macOS and that every required stock tool
  exists (`command -v`) before using it.
- The PKG build verifies the payload architecture with `lipo`.

#### Linux

- No Linux build scripts yet; add their specific rules here once the first
  one is introduced.

### Inno Setup (`Setup.iss`)

- 4-space indentation.
- Pascal script comments use `{ ... }` braces. Never put `{app}` or other
  Inno constants inside such a comment — the closing brace terminates it.
- Every user-visible task needs a `CustomMessages` entry in **both** locales:
  `Locales/Options.eng.isl` and `Locales/Options.rus.isl`.
- Registry writes for machine/user scope use the `HKA` root key so behavior
  follows the install mode (admin -> HKLM, otherwise HKCU).

### WiX Toolset (`*.wxs`, `*.wxl`)

- 4-space indentation; keep components split by concern
  (`ApplicationComponents.wxs`, `Environment.wxs`, `Folders.wxs`).
- Every user-visible string needs an entry in both `Package.en-us.wxl` and
  `Package.ru-ru.wxl`; the Russian file uses codepage 1251.
- Keep `OptionsDlg` publish `Order` values greater than the built-in
  `WixUI_InstallDir` publishes on the same controls (see `Package.wxs`).

### macOS PKG/DMG

- The PKG build (`Pkg/build.sh`) stages `dist/git-file-shard`, `README.md`,
  `LICENSE.txt` and `uninstall.sh`.
- Localized installer resources live in `Pkg/Resources/en.lproj/` and
  `Pkg/Resources/ru.lproj/`.
- The DMG build (`Dmg/build.sh`) only wraps an existing plain
  `bin/GitFileShardPlugin.pkg`; it never builds the PKG.
- The DMG volume contains the plain PKG only; do not add an `Applications`
  symlink.

### Markdown

- CRLF line endings, 2-space list indentation, final newline
  (`.editorconfig`).
- MarkdownLint rules in `.markdownlint.yaml` / `.markdownlint-cli2.yaml`;
  the CLI2 config excludes `.github/**` markdown files.

### Git

- Commit messages are short imperative summaries, e.g.
  `Add Inno Setup 7 installer project for Windows`.
- Do not run `git commit`, `git push`, `git tag`, `git rebase`, `git reset`,
  `git commit --amend` or other history-changing commands unless the user
  explicitly asks for that exact action.
- Commit only after the user has reviewed and verified the changes. An
  implementation request alone does not authorize a commit.
- Before committing, inspect `git status` and `git diff`; stage only files
  that belong to the requested change.
- Never stage build artifacts (`bin/`, `build/`, `dist/`, `.venv/`, `.pip/`)
  or secrets.

## Domain Notes

- Shards live under `.git-file-shards/<original/file/path>/` containing
  `manifest.json` and `part-N` files; the original file is appended to
  `.gitignore`.
- Manifest fields: `original_file`, `hash`, `algorithm`, `part_count`,
  `part_size_mb`, `total_size`.
- Only files larger than the threshold (default 50 MB) **and** marked
  `file-shards=auto` in `.gitattributes` are processed; last-match-wins.
- A file is re-split only when its hash differs from the one stored in the
  manifest; stale parts are cleaned first to avoid corrupt restores.
- Default hash algorithm is SHA-256; `--md5` switches everything to MD5.
- Git hooks: `pre-commit` -> `git file-shard scan`; `post-checkout` and
  `post-merge` -> `git file-shard restore`.
