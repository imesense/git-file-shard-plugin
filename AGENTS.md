# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project Overview

**git-file-shard** is a Git plugin that splits large files into shards and merges them back, so repositories can track big binary assets without storing the originals in Git. It ships as a standalone PyInstaller binary (`git-file-shard.exe` on Windows, `git-file-shard` on macOS and Linux, invoked by Git as the `git file-shard` subcommand) and as platform installers: an Inno Setup 7 EXE and a WiX Toolset 7 MSI for Windows, PKG and DMG packages for macOS, and a DEB package for Debian/Ubuntu.

- Language: Python 3.8+
- License: MIT (see `LICENSE.txt`)
- Default branch: `default`

## Repository Layout

```text
src/git_file_shard/     Python package (plugin core)
src/git_hooks/          Git hooks to copy into .git/hooks/
src/installer_windows_inno/   Inno Setup 7 EXE installer
src/installer_windows_wix/    WiX Toolset 7 MSI installer
src/installer_macos_pkg/      macOS PKG installer
src/installer_macos_dmg/      macOS DMG wrapper around the PKG
src/installer_linux_deb/      Debian package installer (dpkg-deb)
util/                   PKG/DMG/DEB build wrappers (arm64/x86_64, amd64/arm64)
doc/                    integration-guide.md and usage-guide.md
openspec/               OpenSpec artifacts (config.yaml, specs/, changes/)
.agents/skills/         Local agent skills (git-ignored, installed from skills-lock.json)
skills-lock.json        Locked agent skill sources (committed)
.github/workflows/      CI build workflow
GitFileShardPlugin.sln  Visual Studio solution for the WiX project
Directory.Build.props   Shared MSBuild output paths (bin/, obj/)
Directory.Build.rsp     Shared MSBuild switches
bin/, build/, dist/     Build artifacts (git-ignored)
.pip/, .venv/           Local caches (git-ignored)
uv.lock                 Locked Python dependencies (committed)
.python-version         Python version for uv (3.10)
```

## Build & Verification Commands

There is no test suite. Verification means: byte-compile all sources, shell-check the build scripts, then build the artifacts relevant to the change.

Python tooling is managed with `uv` (`uv.lock` is the source of truth and `pyproject.toml` declares dependencies). `pyinstaller` is the only direct dependency and lives in the `dev` dependency group:

```sh
# Create .venv from the lock file and install the project
uv sync --locked

# Verify the lock file is up to date
uv lock --check

# Syntax check
uv run --locked python -m compileall -q src
uv run --locked python -m py_compile git-file-shard.spec

# Build the standalone binary -> dist/git-file-shard.exe (Windows)
# or dist/git-file-shard (macOS, Linux)
uv run --locked pyinstaller git-file-shard.spec --noconfirm
```

Run the interpreter and PyInstaller through `uv run` (it uses `.venv/` and syncs it from the lock file). `uv` reads the interpreter version from `.python-version` (3.10). Build the binary on the target OS: PyInstaller does not cross-compile.

Dependency changes go through `pyproject.toml`: edit the `dev` group and run `uv lock` to refresh `uv.lock`:

```sh
uv lock
```

Shell syntax check (macOS and Linux build scripts; run on any bash-capable host):

```sh
bash -n src/installer_macos_pkg/build.sh
bash -n src/installer_macos_dmg/build.sh
bash -n src/installer_linux_deb/build.sh
bash -n util/build-pkg-arm64.sh
bash -n util/build-pkg-x86_64.sh
bash -n util/build-dmg-arm64.sh
bash -n util/build-dmg-x86_64.sh
bash -n util/build-deb-amd64.sh
bash -n util/build-deb-arm64.sh
```

Windows installers:

```sh
# Inno Setup 7 EXE -> bin/GitFileShardPlugin.exe
ISCC.exe src\installer_windows_inno\Setup.iss

# Compile check only, no output file
ISCC.exe --output=no src\installer_windows_inno\Setup.iss

# WiX Toolset 7 MSI -> bin/<culture>/GitFileShardPlugin.msi
dotnet build src\installer_windows_wix\GitFileShard.Installer.Wix.wixproj -c Release -o bin
```

`ISCC.exe` must be available on `PATH`. The Inno script expects `dist/git-file-shard.exe`, `README.md` and `LICENSE.txt` to exist, and writes output to `bin/`. Note: even `--output=no` deletes a stale file from the output directory, so rebuild after compile-only checks. The WiX build requires the .NET 8 SDK and the same payload; CI uploads `bin/en-US/GitFileShardPlugin.msi` and `bin/ru-RU/GitFileShardPlugin.msi`.

macOS installers (must run on macOS):

```sh
# Bundle the plugin first -> dist/git-file-shard
uv run --locked pyinstaller git-file-shard.spec --noconfirm

# Non-native architecture: spec builds ignore --target-arch,
# so pass the target architecture through the environment
GIT_FILE_SHARD_TARGET_ARCH=x86_64 uv run --locked pyinstaller git-file-shard.spec --noconfirm

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

Linux installer (must run on Linux):

```sh
# Bundle the plugin first -> dist/git-file-shard
uv run --locked pyinstaller git-file-shard.spec --noconfirm

# DEB -> bin/git-file-shard_<version>_<distro>_<arch>.deb
./util/build-deb-amd64.sh <version>
./util/build-deb-arm64.sh <version>

# Explicit distribution identifier (default: from /etc/os-release)
./util/build-deb-amd64.sh <version> --distro ubuntu22.04
```

The DEB build requires `dpkg-deb` and `readelf` on `PATH`, verifies that the payload ELF architecture matches `--arch` (`amd64` or `arm64`), and stages `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`, `README.md` and `LICENSE.txt` under `share/doc/`, plus the `/usr/local/bin/git-file-shard` symlink. The output name embeds a distribution identifier taken from `/etc/os-release` (`ID` + `VERSION_ID`, e.g. `ubuntu20.04`); `--distro <id>` overrides it and an empty value drops the segment. The identifier only labels the file: the package `Version` stays as passed.

CI: `.github/workflows/build-application.yml` sets up `uv` with `astral-sh/setup-uv`, runs `uv sync --locked` (which fails when `uv.lock` is stale), the byte-compile checks on `ubuntu-24.04`, then PyInstaller on `windows-2022`, `ubuntu-24.04` and `macos-15` and uploads `dist/`. The MSI, PKG, DMG and DEB jobs build from those artifacts; the Inno EXE job is currently disabled (`if: false`). Keep workflow commands and paths in sync with the local build steps above.

## Conventions

### OpenSpec

Spec-driven artifacts live in `openspec/` and are managed with the OpenSpec CLI
(`openspec` 2.x, installed globally; it is not a project dependency):

- `openspec/config.yaml` — workflow schema (`spec-driven`), project `context`,
  per-artifact `rules` and per-operation guidance. It replaces the former
  `openspec/project.md`: keep durable project context in the `context:` block
  instead of creating a new `project.md`.
- `openspec/specs/<capability>/spec.md` — current behavior (source of truth).
- `openspec/changes/<change-id>/` — `proposal.md`, optional `design.md`,
  `tasks.md`, and delta specs under `specs/<capability>/spec.md`.
- `.agents/skills/` — local agent skills (git-ignored), installed from the
  committed `skills-lock.json`. OpenSpec skills come from `Fission-AI/OpenSpec`;
  refresh them with `openspec config profile` and `openspec update` instead of
  editing them by hand.
- Delta specs use `## ADDED Requirements`, `## MODIFIED Requirements`,
  `## REMOVED Requirements` sections; requirements use RFC 2119 keywords and
  `### Requirement: <Name>` headings with `#### Scenario:` blocks
  (WHEN/THEN/AND bullets).
- Useful checks: `openspec doctor`, `openspec list`, `openspec list --specs`,
  `openspec validate --specs`, `openspec validate <change>`.
- Do not merge deltas or archive a change on your own initiative. An
  implementation request is not permission to archive. Archive only after an
  explicit user command and after the user has reviewed and verified the
  changes (build/manual test); until then keep the change under
  `openspec/changes/<change-id>/`.
- When the user asks to archive, merge `ADDED` / `MODIFIED` / `REMOVED`
  deltas into the capability spec, update the change's `tasks.md`, move the
  folder to `openspec/changes/archive/YYYY-MM-DD-<change-id>/`, and update the
  `context:` block in `openspec/config.yaml` if scope or history changed.
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

- `--version` and `--arch amd64|arm64` are required, with no defaults.
- Check that the script runs on Linux and that every required tool exists
  (`command -v dpkg-deb readelf`) before using it.
- The DEB build verifies the payload ELF architecture with `readelf`; run
  `readelf` under `LC_ALL=C` so its field names stay parseable on a
  localized build host.
- The payload is staged under `/opt/imesense/git-file-shard-plugin/`
  (`bin/git-file-shard`, `share/doc/README.md`, `share/doc/LICENSE.txt`)
  with a `/usr/local/bin/git-file-shard` symlink using an absolute target.

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

- The PKG build (`src/installer_macos_pkg/build.sh`) stages
  `dist/git-file-shard`, `README.md`, `LICENSE.txt` and `uninstall.sh`,
  ad-hoc signs the payload with `codesign --sign -`, and passes
  `Scripts/postinstall` to `pkgbuild`.
- Localized installer resources live in
  `src/installer_macos_pkg/Resources/en.lproj/` and `ru.lproj/`; the
  per-architecture distribution manifests are `distribution.arm64.xml` and
  `distribution.x86_64.xml` next to `build.sh`.
- The DMG build (`src/installer_macos_dmg/build.sh`) only wraps an existing
  plain `bin/GitFileShardPlugin.pkg`; it never builds the PKG.
- The DMG volume contains the plain PKG only; do not add an `Applications`
  symlink.

### Debian package (DEB)

- The payload is a vendor tree: `opt/imesense/git-file-shard-plugin/` with
  `bin/git-file-shard` and `share/doc/README.md`, `share/doc/LICENSE.txt`,
  plus `usr/local/bin/git-file-shard` as an absolute symlink to the binary.
- `DEBIAN/control` is generated by `build.sh`: `Package: git-file-shard`,
  `Section: vcs`, `Priority: optional`, `Depends: git`, `Homepage`,
  `Maintainer` and `Installed-Size` computed from the staged tree.
- Build with `dpkg-deb --root-owner-group -Zxz --build`; keep directory
  permissions deterministic (755) instead of inheriting the host umask.
- Output is `bin/git-file-shard_<version>_<distro>_<arch>.deb`, where
  `<distro>` comes from `/etc/os-release` (`ID` + `VERSION_ID`) or from
  `--distro <id>`; an empty value omits the segment. `arm64` packages
  must be built on an arm64 host.

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
- Never stage build artifacts (`bin/`, `build/`, `dist/`, `obj/`, `.venv/`,
  `.pip/`, `.agents/skills/`) or secrets.

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
