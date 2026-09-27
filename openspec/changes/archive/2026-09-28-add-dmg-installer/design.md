# Design: add-dmg-installer

## Context

The `pkg-installer` capability produces `bin/GitFileShardPlugin.v<version>.<arch>.pkg`
(optionally a plain-named `bin/GitFileShardPlugin.pkg`). This change adds a
DMG disk image around that PKG using only the stock `hdiutil` tool, giving
macOS users the familiar download-mount-install flow.

## Goals / Non-Goals

- Goals: DMG built from a shell script wrapping the plain PKG; standard
  drag-to-Applications volume layout; version and architecture in the DMG
  file name; convenience wrappers; no new tool dependencies.
- Non-Goals: CI/CD packaging; code signing or notarization of the DMG
  (follows the PKG signing story, deferred until a Developer account
  exists); custom volume icons or background images; hybrid HFS+/ISO
  layouts.

## Decisions

### D1. DMG wraps the plain PKG

The PKG inside the DMG is the plain-named `bin/GitFileShardPlugin.pkg`
(no version or architecture in the name): the version and architecture
live in the DMG file name
(`bin/GitFileShardPlugin.v<version>.<arch>.dmg`) and inside the PKG
itself, so a plain PKG name inside the volume does not lose any
information and keeps the volume layout stable across releases. The PKG
is a precondition of the DMG build, exactly like the plugin binary is a
precondition of the PKG build: it must already exist in `bin/` with the
plain name, and the DMG build does not care how it was produced.

### D2. Volume layout: the PKG only

The mounted volume contains only `GitFileShardPlugin.pkg` — the installer.
The standard drag-to-Applications layout (an `Applications` symlink next to
an .app bundle) does not apply here: the plugin has no .app bundle, the PKG
performs the real installation, and an Applications symlink without a
bundle to drag would be misleading. The PKG itself still installs into
`/Library/Application Support/ImeSense/Git File Shard Plugin` and manages
the `PATH` symlink.

### D3. Build with hdiutil, UDZO, no extra tools

`build.sh` stages a folder, then:

- `hdiutil create -format UDZO -srcfolder <staging> -volname
  'Git File Shard Plugin' <output>.dmg` — a compressed, zlib-flattened
  read-only image, the standard distribution format;
- `hdiutil verify` — sanity-check the produced image.

No `create-dmg`/`node-dmg` third-party tools, no AppleScript window
styling (needs GUI tools and adds fragile moving parts); the plain
Finder layout is sufficient at this stage.

### D4. Version and architecture as required arguments

Same convention as the PKG build script: `--version <version>` and
`--arch arm64|x86_64` are required command line arguments with no
defaults. The build requires the plain PKG to exist beforehand
(`bin/GitFileShardPlugin.pkg`); like the plugin binary for the PKG build,
the PKG is a pure precondition — bundling the plugin, building the PKG
and building the DMG are three independent steps, each assuming the
previous artifact already exists.

### D5. Wrappers mirror the PKG ones

`util/build-dmg-arm64.sh` and `util/build-dmg-x86_64.sh` take the version
as their first argument and forward extra arguments to `build.sh`
(no `.venv` activation, no bundling).

## Risks / Trade-offs

- An unsigned DMG triggers the same Gatekeeper warnings as the unsigned
  PKG when quarantined; accepted until a Developer account exists.
- The Applications symlink was removed from the volume layout after review:
  without an .app bundle to drag it is misleading. Users run the PKG from
  the mounted volume directly.
- UDZO images are not sparse; the DMG size is roughly the compressed
  payload size — acceptable for a ~6 MB payload.
