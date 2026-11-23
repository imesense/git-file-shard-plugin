# Spec Delta

## Purpose

Debian package for the git-file-shard plugin, built with the stock
`dpkg-deb` tool. Installs the standalone binary into a vendor directory
under `/opt`, exposes it on `PATH` through `/usr/local/bin`, and lets
Debian/Ubuntu users manage the plugin with `apt`.

## ADDED Requirements

### Requirement: Package Identity

The package SHALL be named `git-file-shard` and SHALL record the release
version passed to the build, the Debian architecture (`amd64` or
`arm64`), section `vcs`, priority `optional`, a maintainer, the project
homepage `https://github.com/imesense/git-file-shard-plugin/` and the
description "Git plugin for splitting large files into shards and merging
them back".

#### Scenario: Package metadata

- **WHEN** `dpkg-deb -f <package>.deb` is executed
- **THEN** the `Package` field is `git-file-shard`
- **AND** the `Version` field equals the version passed to the build
- **AND** the `Architecture` field is `amd64` or `arm64`
- **AND** the `Section` field is `vcs`
- **AND** the `Homepage` field points to the project repository

### Requirement: Payload Installation

The package SHALL install the plugin binary into the vendor directory as
`/opt/imesense/git-file-shard-plugin/bin/git-file-shard`, with
`README.md` and `LICENSE.txt` in the vendor documentation directory
`/opt/imesense/git-file-shard-plugin/share/doc/`.

The package SHALL NOT install desktop entries, launchers, Git hooks or
documentation files outside the vendor directory.

#### Scenario: Files after installation

- **WHEN** the package is installed with `dpkg -i` or `apt install`
- **THEN** `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`
  exists and is executable
- **AND** `/opt/imesense/git-file-shard-plugin/share/doc/README.md` and
  `/opt/imesense/git-file-shard-plugin/share/doc/LICENSE.txt` exist
- **AND** no desktop entry, launcher or Git hook is installed

### Requirement: PATH Integration

The package SHALL install a `/usr/local/bin/git-file-shard` symlink that
points to `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`, so
the plugin is reachable through `PATH` without editing shell profiles.

The symlink SHALL use an absolute target, so it resolves independently of
the caller's working directory and of `/usr/local/bin` itself being a
symlink.

#### Scenario: Command resolution

- **WHEN** the package is installed
- **THEN** `/usr/local/bin/git-file-shard` is a symlink to
  `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`
- **AND** `git file-shard --help` succeeds

### Requirement: Runtime Dependency

The package SHALL declare a runtime dependency on `git` and SHALL NOT
declare a Python runtime dependency, because the plugin binary bundles
its own interpreter.

#### Scenario: Dependency declaration

- **WHEN** the package metadata is inspected
- **THEN** the `Depends` field contains `git`
- **AND** the `Depends` field does not contain a Python package

### Requirement: Architecture Handling

The build SHALL accept only `amd64` and `arm64` as target architectures
and SHALL verify that the payload is a 64-bit ELF executable for the
requested architecture before packaging.

#### Scenario: Matching payload

- **WHEN** an `amd64` payload is packaged with `--arch amd64`
- **THEN** the build completes and the package records `Architecture:
  amd64`

#### Scenario: Payload architecture mismatch

- **WHEN** the payload architecture differs from the `--arch` value
- **THEN** the build fails with an error naming the actual and requested
  architectures
- **AND** no package is produced

#### Scenario: Unsupported architecture

- **WHEN** `--arch` is neither `amd64` nor `arm64`
- **THEN** the build fails with an explanatory error

### Requirement: Build Script and Output Artifact

The package SHALL be built from `src/installer_linux_deb/build.sh` on a
Linux host, which stages the payload and control metadata, runs
`dpkg-deb --build` and writes the result to `bin/`.

The output name SHALL be
`git-file-shard_<version>[_<distro>]_<arch>.deb`, for example
`git-file-shard_0.1.0_ubuntu22.04_amd64.deb`; the distribution segment
is defined by the Distribution Identifier requirement.

#### Scenario: Local build

- **WHEN** `build.sh --version 0.1.0 --arch amd64 --distro ubuntu22.04`
  is executed on a Linux host after the plugin binary is bundled into
  `dist/`
- **THEN** `bin/git-file-shard_0.1.0_ubuntu22.04_amd64.deb` is produced
  without errors

#### Scenario: Non-Linux host

- **WHEN** the build script is executed on a non-Linux host
- **THEN** it exits with an error stating that Linux is required

### Requirement: Distribution Identifier

The build SHALL accept an optional `--distro <id>` argument that selects
the distribution identifier recorded in the output file name, so one
release can be published for several distributions without ambiguity.

When `--distro` is omitted, the build SHALL derive the identifier from
`/etc/os-release` by concatenating `ID` and `VERSION_ID`. The identifier
SHALL NOT change the `Version` field in the package metadata.

#### Scenario: Explicit identifier

- **WHEN** the build runs with `--distro ubuntu22.04`
- **THEN** the output is
  `bin/git-file-shard_<version>_ubuntu22.04_<arch>.deb`
- **AND** the package metadata still reports the plain version

#### Scenario: Auto-detected identifier

- **WHEN** the build runs without `--distro` on a host whose
  `/etc/os-release` reports `ID=debian` and `VERSION_ID=12`
- **THEN** the output is `bin/git-file-shard_<version>_debian12_<arch>.deb`

#### Scenario: No identifier available

- **WHEN** the build runs without `--distro` and `/etc/os-release` is
  missing or does not provide `ID`
- **THEN** the output name omits the distribution segment

### Requirement: Identifier Format

An identifier SHALL consist of lowercase letters, digits, `.`, `+`, `~`
or `-`, and SHALL start with a letter or digit. An explicitly provided
identifier SHALL be used verbatim; an empty value SHALL omit the segment.

#### Scenario: Empty identifier

- **WHEN** the build runs with `--distro ''`
- **THEN** the output name omits the distribution segment

#### Scenario: Invalid identifier

- **WHEN** the identifier contains characters other than lowercase
  letters, digits, `.`, `+`, `~` or `-`, or does not start with a letter
  or digit
- **THEN** the build fails with an explanatory error
- **AND** no package is produced

### Requirement: Build Inputs

The build script SHALL require `--version` and `--arch` as command line
arguments; neither SHALL have a default. The version SHALL start with a
digit and SHALL NOT contain whitespace, as required by Debian version
syntax.

Bundling the plugin with PyInstaller SHALL remain a separate step. The
build script SHALL NOT bundle the plugin and SHALL require
`dist/git-file-shard`, `README.md` and `LICENSE.txt` to exist.

#### Scenario: Missing arguments

- **WHEN** `build.sh` is executed without `--version` or `--arch`
- **THEN** it exits with an error and prints the usage line

#### Scenario: Invalid version

- **WHEN** `--version` does not start with a digit or contains
  whitespace
- **THEN** the build fails with an explanatory error
- **AND** no package is produced

#### Scenario: Missing payload

- **WHEN** the build script is executed before the plugin binary is
  bundled into `dist/`
- **THEN** it exits with an error instructing to bundle the plugin first

### Requirement: Package Removal

Removing the package with `dpkg -r`, `dpkg -P`, `apt remove` or
`apt purge` SHALL remove the installed binary, the `PATH` symlink and the
documentation files, together with the vendor directories that the
installation created and left empty.

#### Scenario: Removal

- **WHEN** the installed package is removed with `apt remove
  git-file-shard`
- **THEN** `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`
  and `/usr/local/bin/git-file-shard` no longer exist
- **AND** `/opt/imesense/git-file-shard-plugin` and `/opt/imesense` are
  removed when they are left empty

### Requirement: Convenience Wrappers

Convenience wrappers `util/build-deb-amd64.sh` and
`util/build-deb-arm64.sh` SHALL take the version as their first
argument, pass the matching architecture to `build.sh`, and forward extra
arguments to it, including `--distro`.

#### Scenario: Architecture selection

- **WHEN** `util/build-deb-arm64.sh 0.1.0 --distro debian12` is executed
  with an arm64 payload
- **THEN** `bin/git-file-shard_0.1.0_debian12_arm64.deb` is produced
