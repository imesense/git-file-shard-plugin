# Delta for dmg-installer

## ADDED Requirements

### Requirement: Image Identity

The DMG SHALL be a UDZO (compressed, zlib) read-only disk image named
`GitFileShardPlugin.v<version>.<arch>.dmg` (version prefixed with `v`
and architecture inserted before the extension, e.g.
`GitFileShardPlugin.v0.1.0.arm64.dmg`), built with the stock `hdiutil`
tool.

#### Scenario: Image identity

- **WHEN** the DMG is inspected after the build
- **THEN** its file name embeds the version and the architecture
- **AND** `hdiutil imageinfo` reports the UDZO format

### Requirement: Volume Contents

The DMG volume SHALL contain the PKG installer
(`GitFileShardPlugin.pkg`, without version or architecture in the name)
and nothing else; the volume SHALL NOT contain an `Applications` symlink
because the plugin has no .app bundle to drag there.

The PKG SHALL be a precondition of the DMG build: it must already exist
in `bin/` with the plain name, regardless of how it was produced. The
DMG build SHALL NOT build or modify the PKG.

#### Scenario: Volume contents

- **WHEN** the DMG is mounted
- **THEN** the volume contains `GitFileShardPlugin.pkg` and no other
      user-visible entries
- **AND** installing the PKG performs the installation defined by the
      pkg-installer capability

### Requirement: Build Reproducibility

The DMG SHALL be built from
`src/ImeSense.GitFileShardPlugin.Setup.Dmg/build.sh`, which stages the
volume contents, runs `hdiutil create` and `hdiutil verify`, and
produces `bin/GitFileShardPlugin.v<version>.<arch>.dmg`.

The build script SHALL require the version (`--version`) and the target
architecture (`--arch arm64|x86_64`) as command line arguments; neither
SHALL have a default.

The build SHALL require the PKG (`bin/GitFileShardPlugin.pkg`) to exist
beforehand and SHALL fail with a clear error otherwise.

Bundling the plugin (PyInstaller) and building the PKG SHALL remain
independent steps; the DMG build SHALL only wrap the existing PKG.

Convenience wrappers `util/build-dmg-arm64.sh` and
`util/build-dmg-x86_64.sh` SHALL pass the architecture to `build.sh`,
take the version as their first argument and forward extra arguments to
`build.sh`.

#### Scenario: Local build

- **WHEN** `build.sh --version <version> --arch arm64` is executed on
      macOS after the plain PKG is built
- **THEN** `bin/GitFileShardPlugin.v<version>.arm64.dmg` is produced
      without errors

#### Scenario: Missing arguments

- **WHEN** `build.sh` is executed without `--version` or `--arch`
- **THEN** it exits with an error and prints the usage line

#### Scenario: Missing PKG

- **WHEN** `build.sh` is executed before the PKG exists in `bin/`
- **THEN** it exits with an error instructing to build the PKG first

#### Scenario: Architecture selection

- **WHEN** `util/build-dmg-x86_64.sh <version>` is executed with the
      plain PKG built for `x86_64`
- **THEN** `bin/GitFileShardPlugin.v<version>.x86_64.dmg` is produced
