# Delta for pkg-installer

## ADDED Requirements

### Requirement: Package Identity

The package SHALL identify the application as "ImeSense Git File Shard
Plugin" with bundle identifier `org.imesense.git-file-shard` and version
matching the plugin release (`0.1.0`).

The package SHALL be a distribution package built with `productbuild`
from a component package built with `pkgbuild`.

#### Scenario: Package identity

- **WHEN** the package receipt is inspected after installation
- **THEN** the package identifier is `org.imesense.git-file-shard`
- **AND** the package version is `0.1.0`

### Requirement: Payload Installation

The package SHALL install `git-file-shard` into the `bin` subfolder of
`/Library/Application Support/ImeSense/Git File Shard Plugin`, together
with `README.md`, `LICENSE.txt` and `uninstall.sh` in the installation
folder root.

The package SHALL NOT create Finder shortcuts or launch agents.

#### Scenario: Files after installation

- **WHEN** installation completes
- **THEN** `/Library/Application Support/ImeSense/Git File Shard Plugin/bin/git-file-shard`,
      `README.md`, `LICENSE.txt` and `uninstall.sh` exist
- **AND** no Finder shortcut or launch agent is created

### Requirement: PATH Integration via Symlink

The `postinstall` script SHALL create a `/usr/local/bin/git-file-shard`
symlink pointing to the installed binary.

The script SHALL replace a stale symlink at that path but SHALL NOT
delete a regular file.

#### Scenario: Symlink after installation

- **WHEN** installation completes
- **THEN** `/usr/local/bin/git-file-shard` is a symlink to the installed
      binary and `git file-shard --help` resolves through `PATH`

#### Scenario: Regular file preserved

- **WHEN** a regular file already exists at `/usr/local/bin/git-file-shard`
- **THEN** the installation fails with an explanatory error instead of
      overwriting the file

### Requirement: Uninstall Script

The package SHALL ship an `uninstall.sh` script in the installation
folder root that removes the `PATH` symlink, the installation folder,
the package receipt (`pkgutil --forget`) and the publisher folder
(`ImeSense`) when it is left empty.

The script SHALL refuse to run without administrator privileges and
SHALL NOT remove the publisher folder when it still contains other
applications.

#### Scenario: Uninstall

- **WHEN** the user runs `uninstall.sh` with administrator privileges
- **THEN** the symlink, the installation folder, the package receipt
      and the empty publisher folder are removed

#### Scenario: Publisher folder preserved

- **WHEN** the publisher folder still contains other applications at
      uninstall time
- **THEN** the publisher folder is left in place

#### Scenario: Uninstall without privileges

- **WHEN** the script is run without administrator privileges
- **THEN** it exits with an error without deleting anything

### Requirement: Localized Installer Resources

The distribution package SHALL provide welcome, license and conclusion
resources in English (`Resources/en.lproj/`) and Russian
(`Resources/ru.lproj/`).

#### Scenario: Russian interface

- **WHEN** the package is opened on a system with Russian as the
      preferred language
- **THEN** the installer shows the Russian welcome, license and
      conclusion texts

### Requirement: Build Reproducibility

The package SHALL be built from
`src/ImeSense.GitFileShardPlugin.Setup.Pkg/build.sh`, which stages the
payload, runs `pkgbuild` and `productbuild`, and produces
`bin/GitFileShardPlugin.v<version>.<arch>.pkg` (version prefixed with `v`
and architecture inserted before the extension, e.g.
`GitFileShardPlugin.v0.1.0.arm64.pkg`).

The build script SHALL require the version (`--version`) and the target
architecture (`--arch arm64|x86_64`) as command line arguments; neither
SHALL have a default.

The build SHALL require `dist/git-file-shard`, `README.md` and
`LICENSE.txt` to exist beforehand.

The build script SHALL accept an optional code signing identity
(ad-hoc signing of the payload by default, `productsign` with the given
identity when provided).

Convenience wrappers `util/build-pkg-arm64.sh` and
`util/build-pkg-x86_64.sh` SHALL pass the architecture to `build.sh`,
take the version as their first argument, forward extra arguments to
`build.sh` and activate the repository `.venv` when present.

#### Scenario: Local build

- **WHEN** `build.sh --version <version> --arch arm64` is executed on
      macOS after the PyInstaller payload is built
- **THEN** `bin/GitFileShardPlugin.v<version>.arm64.pkg` is produced
      without errors

#### Scenario: Missing arguments

- **WHEN** `build.sh` is executed without `--version` or `--arch`
- **THEN** it exits with an error and prints the usage line

#### Scenario: Architecture selection

- **WHEN** `util/build-pkg-x86_64.sh <version>` is executed with a
      suitable Python interpreter
- **THEN** the payload is built for `x86_64` and
      `bin/GitFileShardPlugin.v<version>.x86_64.pkg` is produced
