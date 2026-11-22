# pkg-installer Specification

## Purpose

macOS distribution package for the git-file-shard plugin, built with the
stock `pkgbuild` / `productbuild` tools. Installs the plugin binary into an
application folder under `/Library/Application Support/`, makes it reachable
through `PATH` via a symlink, and ships an uninstall script.

## Requirements

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

### Requirement: Host Architecture

The distribution manifest SHALL declare the target architecture through
the `hostArchitectures` attribute of the `options` element.

The build script SHALL select a per-architecture distribution manifest
(`distribution.arm64.xml`, `distribution.x86_64.xml`) based on the
`--arch` argument, so the built package never falls back to the
`productbuild` default of dual `arm64`+`x86_64` support (which makes
Intel machines evaluate the distribution under Rosetta 2 and prompt to
install Rosetta).

#### Scenario: Architecture recorded in the distribution

- **WHEN** `build.sh --version <version> --arch arm64` builds a package
- **THEN** the embedded `Distribution` declares
      `hostArchitectures="arm64"`

#### Scenario: No Rosetta prompt on Intel

- **WHEN** the arm64 package is opened on an Intel machine
- **THEN** the installer reports the package as unsupported for that
      architecture instead of prompting to install Rosetta 2

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

The script SHALL create the `/usr/local/bin` directory when it does not
exist yet (a stock macOS install has `/usr/local` but not always its
`bin` subfolder).

The script SHALL replace a stale symlink at that path but SHALL NOT
delete a regular file.

#### Scenario: Symlink after installation

- **WHEN** installation completes
- **THEN** `/usr/local/bin/git-file-shard` is a symlink to the installed
      binary and `git file-shard --help` resolves through `PATH`

#### Scenario: Missing /usr/local/bin directory

- **WHEN** `/usr/local` exists but `/usr/local/bin` does not
- **THEN** the `postinstall` script creates `/usr/local/bin` and the
      symlink inside it

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

### Requirement: Build Script and Output Artifact

The package SHALL be built from `src/installer_macos_pkg/build.sh`, which
stages the payload, runs `pkgbuild` and `productbuild`, and writes the
result to `bin/`.

The output name SHALL embed the version (prefixed with `v`) and the
architecture before the extension, for example
`GitFileShardPlugin.v0.1.0.arm64.pkg`.

The `--plain-name` option SHALL produce `bin/GitFileShardPlugin.pkg`
instead, with the version and architecture still recorded inside the
package.

#### Scenario: Local build

- **WHEN** `build.sh --version <version> --arch arm64` is executed on
      macOS after the plugin binary is bundled into `dist/`
- **THEN** `bin/GitFileShardPlugin.v<version>.arm64.pkg` is produced
      without errors

#### Scenario: Plain name

- **WHEN** `build.sh --version <version> --arch arm64 --plain-name` is
      executed
- **THEN** `bin/GitFileShardPlugin.pkg` is produced while the package
      still records the version and the architecture

### Requirement: Build Inputs

The build script SHALL require the version (`--version`) and the target
architecture (`--arch arm64|x86_64`) as command line arguments; neither
SHALL have a default.

Bundling the plugin (PyInstaller) SHALL be a separate step that runs
beforehand. The build script SHALL NOT bundle the plugin itself and SHALL
require `dist/git-file-shard`, `README.md` and `LICENSE.txt` to exist.

#### Scenario: Missing arguments

- **WHEN** `build.sh` is executed without `--version` or `--arch`
- **THEN** it exits with an error and prints the usage line

#### Scenario: Missing payload

- **WHEN** `build.sh` is executed before the plugin binary is bundled
      into `dist/`
- **THEN** it exits with an error instructing to bundle the plugin first

### Requirement: Code Signing

The payload SHALL be ad-hoc signed by default. When a signing identity is
provided, the built package SHALL be signed with `productsign` using that
identity.

#### Scenario: Signed build

- **WHEN** `build.sh --version <version> --arch arm64 --sign <identity>`
      is executed
- **THEN** the produced package is signed with the given identity

### Requirement: Convenience Wrappers

Convenience wrappers `util/build-pkg-arm64.sh` and
`util/build-pkg-x86_64.sh` SHALL take the version as their first
argument, pass the matching architecture to `build.sh`, and forward extra
arguments to it.

#### Scenario: Architecture selection

- **WHEN** `util/build-pkg-x86_64.sh <version>` is executed with the
      plugin bundled for `x86_64`
- **THEN** `bin/GitFileShardPlugin.v<version>.x86_64.pkg` is produced
