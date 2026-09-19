# Usage Guide

This document describes all available commands and options of the **git-file-shard** plugin.

## Table of Contents

- [Command Overview](#command-overview)
- [Commands list](#commands-list)
  - [Scan and split](#scan-and-split)
  - [Restore all files](#restore-all-files)
  - [Split a single file](#split-a-single-file)
  - [Merge a single file](#merge-a-single-file)
  - [Compute file hash](#compute-file-hash)
- [Common Options](#common-options)
- [Usage Examples](#usage-examples)
- [Exit Behavior](#exit-behavior)

---

## Command Overview

```log
git file-shard [-h] {scan,restore,split,merge,hash} ...

Git plugin for splitting large files into shards and merging them back.

commands:
  scan       Scan repository for large files and split them into shards
  restore    Merge all shards back to original files
  split      Split a single file into shards
  merge      Merge shards for a specific file back
  hash       Compute file hash
```

## Commands list

### Scan and split

Scans the repository for files exceeding the size threshold that have `file-shards=auto` set in `.gitattributes`.
Splits matching files into shards and adds originals to `.gitignore`.

#### Syntax

```log
git file-shard scan [--repo PATH] [--threshold MB] [--md5]
```

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `--repo` | `.` | Repository root path |
| `--threshold` | `50` | Size threshold in MB |
| `--md5` | off | Use MD5 instead of SHA-256 |

#### Examples

```sh
# Scan current directory with defaults (50 MB threshold, SHA-256)
git file-shard scan

# Scan a specific repository
git file-shard scan --repo /path/to/repo

# Use a custom threshold (e.g., 100 MB)
git file-shard scan --threshold 100

# Use MD5 instead of SHA-256
git file-shard scan --md5
```

### Restore all files

Reads all shard manifests in `.git-file-shards/` and reconstructs the original files in the working tree. Files that are already present with a matching hash are skipped.

#### Syntax

```log
git file-shard restore [--repo PATH] [--md5]
```

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `--repo` | `.` | Repository root path |
| `--md5` | off | Use MD5 instead of SHA-256 |

#### Examples

```sh
# Restore all files in the current repository
git file-shard restore

# Restore in a specific repository
git file-shard restore --repo /path/to/repo
```

### Split a single file

Splits a single file into shards and adds it to `.gitignore`. Useful for manual splitting outside of the scan workflow.

#### Syntax

```log
git file-shard split FILE [--repo PATH] [--threshold MB] [--md5]
```

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `FILE` | — | Path to the file to split (required) |
| `--repo` | `.` | Repository root path |
| `--threshold` | `50` | Part size in MB |
| `--md5` | off | Use MD5 instead of SHA-256 |

#### Examples

```sh
# Split a single file with defaults
git file-shard split largefile.bin

# Split with a custom part size
git file-shard split largefile.bin --threshold 100

# Split using MD5
git file-shard split largefile.bin --md5
```

### Merge a single file

Reconstructs a single file from its shards.
Useful for manual recovery outside of the restore workflow.

#### Syntax

```log
git file-shard merge FILE [--repo PATH] [--md5]
```

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `FILE` | — | Path to the original file (required) |
| `--repo` | `.` | Repository root path |
| `--md5` | off | Use MD5 instead of SHA-256 |

#### Examples

```sh
# Merge a single file
git file-shard merge largefile.bin

# Merge using MD5
git file-shard merge largefile.bin --md5
```

### Compute file hash

Computes and prints the hash of a file.
Useful for manual verification.

#### Syntax

```log
git file-shard hash FILE [--md5]
```

#### Options

| Option | Default | Description |
| --- | --- | --- |
| `FILE` | — | Path to the file to hash (required) |
| `--md5` | off | Use MD5 instead of SHA-256 |

#### Examples

```sh
# Compute SHA-256 hash (default)
git file-shard hash largefile.bin

# Compute MD5 hash
git file-shard hash largefile.bin --md5
```

## Common options

The following options are shared across multiple commands:

| Option | Description |
| --- | --- |
| `--repo PATH` | Specifies the repository root path. Defaults to the current directory (`.`). All file paths are resolved relative to this path. |
| `--threshold MB` | Sets the size threshold in megabytes. Files larger than this value are candidates for splitting. Defaults to `50`. |
| `--md5` | Switches the hash algorithm from SHA-256 (default) to MD5. Affects both hashing and hash verification during restore. |

## Usage examples

### Typical workflow with hooks

```sh
# Add a large file to the repo
cp /path/to/huge_asset.bin .

# Stage and commit — the pre-commit hook splits it automatically
git add .
git commit -m "Add huge asset"

# The original file is in .gitignore, only shards are committed.
# The file remains available in the working tree.

# After cloning or checking out another branch, the post-checkout
# hook restores the file automatically:
git checkout feature-branch
# huge_asset.bin is reconstructed from shards
```

### Manual operations

```sh
# Re-scan and split any new large files
git file-shard scan

# Manually restore all files
git file-shard restore

# Verify a file's hash
git file-shard hash huge_asset.bin
```

### Working with files in subdirectories

```sh
# A file at gamedata/levels/level_01/level.cform will produce:
#     .git-file-shards/gamedata/levels/level_01/level.cform/
#         manifest.json
#         part-1
#         part-2

# Split it manually
git file-shard split gamedata/levels/level_01/level.cform

# Merge it back manually
git file-shard merge gamedata/levels/level_01/level.cform
```

## Exit behavior

- All commands print progress information to stdout.
- Errors (missing files, missing parts, hash mismatches) are printed with `Error:` or `Warning:` prefixes.
- Hash mismatches during restore produce a warning but do not prevent the file from being written.
- If no command is provided, the help message is printed.
