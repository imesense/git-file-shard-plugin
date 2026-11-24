# Git File Shard Plugin

English | [Русский](./README.rus.md)

[![Language](https://img.shields.io/badge/Language-Python-blue.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE.txt)
[![Release](https://img.shields.io/github/v/release/imesense/git-file-shard-plugin?include_prereleases&label=Release)](https://github.com/imesense/git-file-shard-plugin/releases/latest)
[![Build application](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-application.yml/badge.svg)](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-application.yml)

Git plugin that splits large files into shards and merges them back, so repositories can track big binary assets without storing the originals in Git.

## Features

- Splits files larger than a configurable threshold (default 50 MB) into shards.
- Selects files by the custom `file-shards=auto` attribute in `.gitattributes`.
- Restores originals from shards and verifies their hash.
- Re-splits a file when its hash changes and cleans stale parts first.
- Manages `.gitignore` so that only shards are tracked by Git.
- Ships Git hooks for automatic splitting and restoring.

## Requirements

For building:

- __Python__ 3.10 (see `.python-version`),
- __uv__.

For development:

- __Visual Studio Code__ or any other editor.

## Building

- Restore the locked environment and build the standalone binary:

  ```sh
  uv sync --locked
  uv run --locked pyinstaller git-file-shard.spec --noconfirm
  ```

The binary is written to `dist/` (`git-file-shard.exe` on Windows, `git-file-shard` on macOS and Linux).
PyInstaller does not cross-compile, so build on the target OS.

## Verification

There is no test suite.
Verify the sources and the build scripts with:

```sh
uv lock --check
uv run --locked python -m compileall -q src
uv run --locked python -m py_compile git-file-shard.spec
```

Installers are built from the bundled binary on the target OS:

- Windows: `ISCC.exe src\installer_windows_inno\Setup.iss` and `dotnet build src\installer_windows_wix\GitFileShard.Installer.Wix.wixproj -c Release -o bin`.
- macOS: `./util/build-pkg-arm64.sh <version>` and `./util/build-dmg-arm64.sh <version>`.
- Linux: `./util/build-deb-amd64.sh <version>`.

## Installation

### Pre-built binary

Download the archive for your platform from releases and put the binary (`git-file-shard.exe` on Windows, `git-file-shard` on macOS and Linux) in a directory on your `PATH`.
Git detects it as the `git file-shard` subcommand.

Verify installation:

```sh
git file-shard --help
```

### Debian package

```sh
sudo apt install ./git-file-shard_0.1.0_ubuntu22.04_amd64.deb
```

### Python package

```sh
uv tool install .
```

## Usage

- Split matching files and add originals to `.gitignore`:

  ```sh
  git file-shard scan
  ```

- Restore originals from shards:

  ```sh
  git file-shard restore
  ```

- Split or merge a single file:

  ```sh
  git file-shard split path/to/file.bin
  git file-shard merge path/to/file.bin
  ```

- Compute a file hash:

  ```sh
  git file-shard hash path/to/file.bin
  ```

See the [usage guide](./doc/usage-guide.md) for all commands and options.

## Integration

Install the hooks from `src/git_hooks/` into `.git/hooks/` and mark the files to shard in `.gitattributes`:

```properties
*.cform file-shards=auto
```

See the [integration guide](./doc/integration-guide.md) for details.

## Environment Variables

| Variable | Description |
| --- | --- |
| `GIT_FILE_SHARD_TARGET_ARCH` | Target architecture of the macOS bundle (`arm64` or `x86_64`). |

## Documentation

- [Usage guide](./doc/usage-guide.md)
- [Integration guide](./doc/integration-guide.md)
- [Branching model](./doc/git-branching-model.md)
- [Coding style](./doc/python-coding-style.md)
- [Commit style](./doc/git-commit-style.md)

## Contributing

See the [contributing guide](./CONTRIBUTING.md) and the [code of conduct](./CODE_OF_CONDUCT.md).

## License

Contents of this repository licensed under terms of the __MIT license__ unless otherwise specified.
See [this](./LICENSE.txt) file for details.
