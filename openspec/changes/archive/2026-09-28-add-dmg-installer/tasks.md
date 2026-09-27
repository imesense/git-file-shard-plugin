# Tasks: add-dmg-installer

## 1. DMG packaging project

- [x] 1.1 Create `src/ImeSense.GitFileShardPlugin.Setup.Dmg/` project with
      `build.sh`
- [x] 1.2 Implement staging: copy the PKG (`bin/GitFileShardPlugin.pkg`)
      into the staging folder (PKG only, no Applications symlink)
- [x] 1.3 Implement `hdiutil create` (UDZO, volume name) and
      `hdiutil verify` producing
      `bin/GitFileShardPlugin.v<version>.<arch>.dmg`
- [x] 1.4 Implement required `--version` and `--arch` arguments (no
      defaults) and the missing-PKG precondition check

## 2. Wrappers

- [x] 2.1 Add `util/build-dmg-arm64.sh` and `util/build-dmg-x86_64.sh`
      wrappers (version as first argument, extra arguments forwarded)

## 3. Verification

- [x] 3.1 `bash -n` syntax check of all shell scripts
- [x] 3.2 Local build produces
      `bin/GitFileShardPlugin.v0.1.0.arm64.dmg` from the existing PKG
      in `bin/`
- [x] 3.3 `hdiutil verify` passes; the mounted volume contains the PKG
      only (the Applications symlink was dropped after review)
- [x] 3.4 Manual test (user): mount the DMG, run the PKG from the
      volume, install and uninstall work as with the bare PKG

## 4. Spec merge

- [x] 4.1 Merge deltas into `openspec/specs/dmg-installer/spec.md` and
      archive this change
