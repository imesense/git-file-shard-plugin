# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project Overview

**git-file-shard** is a Git plugin that splits large files into shards and merges them back, so repositories can track big binary assets without storing the originals in Git. It ships as a standalone PyInstaller binary (`git-file-shard.exe`, invoked by Git as the `git file-shard` subcommand) and as a Windows installer built with Inno Setup 7.

- Language: Python 3.8+
- License: MIT (see `LICENSE.txt`)
- Default branch: `default`

## Repository Layout

```
src/git_file_shard/     Python package (plugin core)
src/git_hooks/          Git hooks to copy into .git/hooks/
src/ImeSense.GitFileShardPlugin.Setup.Inno/   Inno Setup 7 installer
doc/                    integration-guide.md and usage-guide.md
openspec/               OpenSpec artifacts (project.md, specs/, changes/)
bin/, build/, dist/     Build artifacts (git-ignored)
.pip/, .venv/           Local caches (git-ignored)
```

## Build & Verification Commands

There is no test suite. Verification means: byte-compile all sources, then build the artifacts.

Python tooling (virtual environment in `.venv/`, pip cache in `.pip/`; `pyinstaller` is the only pinned dependency, from `requirements.txt`):

```sh
python -m venv .venv
pip install --cache-dir .pip -r requirements.txt

# Syntax check
python -m compileall -q src
python -m py_compile git-file-shard.spec

# Build the standalone binary -> dist/git-file-shard.exe
pyinstaller git-file-shard.spec --noconfirm
```

Run the interpreter and PyInstaller from the activated virtual environment (on Windows: `.venv\Scripts\activate`).

Windows installer (Inno Setup 7, script `Setup.iss`):

```sh
# Full build -> bin/GitFileShardPlugin.exe
ISCC.exe src\ImeSense.GitFileShardPlugin.Setup.Inno\Setup.iss

# Compile check only, no output file
ISCC.exe --output=no src\ImeSense.GitFileShardPlugin.Setup.Inno\Setup.iss
```

`ISCC.exe` must be available on `PATH`. The installer script expects `dist/git-file-shard.exe`, `README.md` and `LICENSE.txt` to exist, and writes output to `bin/`. Note: even `--output=no` deletes a stale file from the output directory, so rebuild after compile-only checks.

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
- When a change is implemented and verified, merge its deltas into the
  capability spec and move the change folder under
  `openspec/changes/archive/` (name: `YYYY-MM-DD-<change-id>`).

### Python

- Docstrings in triple double quotes on all public functions.
- Single quotes for string literals; f-strings for interpolation.
- 4-space indentation (`.editorconfig`).
- Imports: stdlib first, then project (`from os import path` style is used).
- User-facing output via `print()` with `Error:` / `Warning:` prefixes.
- CLI parsing uses `argparse` with subcommands; keep new flags consistent
  with the existing ones (`--repo`, `--threshold`, `--md5`).

### Inno Setup (`Setup.iss`)

- 4-space indentation.
- Pascal script comments use `{ ... }` braces. Never put `{app}` or other
  Inno constants inside such a comment — the closing brace terminates it.
- Every user-visible task needs a `CustomMessages` entry in **both** locales:
  `Locales/Options.eng.isl` and `Locales/Options.rus.isl`.
- Registry writes for machine/user scope use the `HKA` root key so behavior
  follows the install mode (admin -> HKLM, otherwise HKCU).

### Markdown

- CRLF line endings, 2-space list indentation, final newline
  (`.editorconfig`).
- MarkdownLint rules in `.markdownlint.yaml` / `.markdownlint-cli2.yaml`;
  the CLI2 config excludes `.github/**` markdown files.

### Git

- Commit messages are short imperative summaries, e.g.
  `Add Inno Setup 7 installer project for Windows`.

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
