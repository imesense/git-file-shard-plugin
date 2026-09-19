# Integration Guide

This document describes how to install and integrate **Git File Shard** plugin into a Git repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Get pre-built binary](#get-pre-built-binary)
  - [Build from source](#build-from-source)
  - [Install as Python package](#install-as-python-package)
- [Git hook integration](#git-hook-integration)
- [Git attributes configuration](#git-attributes-configuration)
- [How it works](#how-it-works)

---

## Prerequisites

- **Git** (any recent version).
- **Python** 3.8+ (only needed for building from source or installing as a package).

## Installation

### Get pre-built binary

Download `git-file-shard.exe` from releases and place it in a directory that is on your `PATH`.
Git will automatically detect it as `git file-shard` subcommand.

Verify installation:

```sh
git file-shard --help
```

### Build from source

```sh
# Create virtual environment
python -m venv .venv

# Activate virtual environment
./.venv/Scripts/activate

# Install dependencies
pip install -r requirements.txt --cache-dir .pip

# Build bundle
pyinstaller --clean --noconfirm --distpath dist --workpath build git-file-shard.spec
```

The binary will be at `dist/git-file-shard.exe`.
Add it to your `PATH`.

### Install as Python package

```sh
pip install .
```

This registers `git-file-shard` console script.
As long as the Python Scripts directory is in your `PATH`, `git file-shard` will work.

## Git hook integration

The plugin ships with three Git hooks located in `src/git_hooks/`.
Copy hooks into your repository's `.git/hooks/` directory:

```sh
cp src/git_hooks/pre-commit .git/hooks/pre-commit
cp src/git_hooks/post-checkout .git/hooks/post-checkout
cp src/git_hooks/post-merge .git/hooks/post-merge
```

On Unix, make hooks executable:

```sh
chmod +x .git/hooks/pre-commit .git/hooks/post-checkout .git/hooks/post-merge
```

| Hook | Command | Purpose |
| --- | --- | --- |
| `pre-commit` | `git file-shard scan` | Split large files into shards before committing |
| `post-checkout` | `git file-shard restore` | Reconstruct original files after checkout |
| `post-merge` | `git file-shard restore` | Reconstruct original files after merge |

### How hooks work together

```text
  ┌──────────────┐
  │  git commit  │
  └──────┬───────┘
         │
         ▼
  ┌────────────────────┐
  │  pre-commit hook   │
  │  git file-shard    │
  │      scan          │
  │                    │
  │  - Finds files     │
  │    > 50 MB with    │
  │    file-shards=auto│
  │  - Splits into     │
  │    shards          │
  │  - Adds originals  │
  │    to .gitignore   │
  └────────┬───────────┘
           │
           ▼
  ┌────────────────────┐
  │  Only shards are   │
  │  committed;        │
  │  original files    │
  │  remain in working │
  │  tree              │
  └────────────────────┘

  ┌──────────────┐     ┌──────────────┐
  │ git checkout │     │  git merge   │
  └──────┬───────┘     └──────┬───────┘
         │                    │
         ▼                    ▼
  ┌────────────────────┐
  │ post-checkout /    │
  │ post-merge hook    │
  │  git file-shard    │
  │      restore       │
  │                    │
  │  - Reads manifests │
  │  - Merges shards   │
  │    back to files   │
  │  - Verifies hash   │
  └────────────────────┘
```

## Git attributes configuration

The plugin uses a custom `file-shards` attribute in `.gitattributes` to determine which files should be sharded.
Only files that exceed the size threshold **and** have `file-shards=auto` will be processed.

### Enabling sharding

```properties
# Shard all `*.cform` files larger than 50 MB
*.cform file-shards=auto

# Shard all `*.psb` files
*.psb file-shards=auto
```

### Enabling for all files

```properties
# Shard any large file regardless of extension
* file-shards=auto
```

### Disabling for specific files

Use the `-` prefix to unset the attribute (standard Git attributes syntax).
Last-match-wins applies:

```properties
# Enable for all files
* file-shards=auto

# But disable for text and source files
*.txt  -file-shards
*.md   -file-shards
*.py   -file-shards
*.json -file-shards
```

### Scoped to a directory

```properties
# Only shard files inside assets/
/assets/** file-shards=auto
```

## How it works

### Shards directory structure

When a file is split, its shards are stored under `.git-file-shards/` folder mirroring the original file's relative path:

```properties
.git-file-shards/
    level.cform/    # Mirrors the original file path
        manifest.json # Metadata: hash, part count, sizes
        part-1
        part-2
```

For a file at `gamedata/levels/level_01/level.cform`:

```properties
.git-file-shards/
    gamedata/
        levels/
            level_01/
                level.cform/
                    manifest.json
                    part-1
                    part-2
```

### Manifest format

Each split creates a `manifest.json` with the following fields:

| Field | Description |
| --- | --- |
| `original_file` | Relative path of the original file |
| `hash` | Full hash of the original file (SHA-256 by default) |
| `algorithm` | Hash algorithm used (`sha256` or `md5`) |
| `part_count` | Number of shard parts |
| `part_size_mb` | Maximum part size in MB |
| `total_size` | Original file size in bytes |

### File modification handling

When a large file is modified (its hash changes), the plugin:

1. Detects the hash change by comparing with the manifest.
2. Cleans all old parts and the old manifest from the shards directory.
3. Re-splits the file into new parts.
4. Writes a new manifest with the updated hash.

This ensures stale parts from a previous version (e.g., a third part when the file shrank) are removed and cannot corrupt the restored file.

### Git ignore management

Original large files are automatically added to `.gitignore` so that only shards are tracked by Git.
The plugin checks whether the file is already listed before appending.
