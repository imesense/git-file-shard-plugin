# Change: Add macOS DMG installer wrapping the plain PKG

## Why

The plugin already ships as a native PKG installer for macOS, but PKG files
are commonly distributed inside DMG disk images: a single downloadable file
that mounts as a volume, shows the installer, and unmounts cleanly. A DMG
adds no installation semantics of its own — it is pure distribution
packaging around the existing PKG.

## What Changes

- Add a DMG packaging project (`src/ImeSense.GitFileShardPlugin.Setup.Dmg/`)
  producing `bin/GitFileShardPlugin.v<version>.<arch>.dmg` via a `build.sh`
  script that drives the stock `hdiutil` tool.
- The DMG wraps the PKG installer (`bin/GitFileShardPlugin.pkg`, the plain
  name without version or architecture). The PKG is a precondition: it
  must already exist in `bin/`, regardless of how it was produced; the DMG
  build never builds the PKG itself.
- The DMG volume contains the PKG only: the plugin has no .app bundle, so
  the standard drag-to-Applications layout does not apply and the
  Applications symlink would be misleading.
- Version and architecture are embedded in the DMG file name (the same
  `v<version>.<arch>` convention as the PKG).
- Convenience wrappers `util/build-dmg-arm64.sh` and
  `util/build-dmg-x86_64.sh` take the version as their first argument and
  forward extra arguments to `build.sh`.
- Bundling the plugin (PyInstaller) and building the PKG remain separate
  steps that run beforehand; the DMG build only wraps the existing PKG.

## Impact

- Affected specs: `dmg-installer` (new capability)
- Affected code: `src/ImeSense.GitFileShardPlugin.Setup.Dmg/` (new),
  `util/` (new wrappers)
- CI/CD remains out of scope.
