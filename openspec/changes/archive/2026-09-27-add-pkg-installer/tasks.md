# Tasks: add-pkg-installer

## 1. Installer project

- [x] 1.1 Create `src/ImeSense.GitFileShardPlugin.Setup.Pkg/` project with
      `build.sh`, `distribution.xml`, `Resources/` and `Scripts/`
- [x] 1.2 Author `distribution.xml`: title, options, license and resource
      references for the distribution package
- [x] 1.3 Author localized resources: `Resources/en.lproj/` and
      `Resources/ru.lproj/` with welcome, license and conclusion texts

## 2. Installation behavior

- [x] 2.1 Author `Scripts/postinstall`: create the
      `/usr/local/bin/git-file-shard` symlink (replace stale symlink,
      refuse to overwrite a regular file)
- [x] 2.2 Author `uninstall.sh` (shipped in the payload): remove the
      symlink, the installation folder, the package receipt and the
      empty publisher folder; refuse to run without admin rights

## 3. Build script

- [x] 3.1 Implement payload staging in `build.sh` (copy
      `dist/git-file-shard`, `README.md`, `LICENSE.txt`, `uninstall.sh`)
- [x] 3.2 Implement `pkgbuild` and `productbuild` invocations producing
      `bin/GitFileShardPlugin.pkg` (identifier
      `org.imesense.git-file-shard`, version `0.1.0`)
- [x] 3.3 Implement the `--arch` flag (default `arm64`, `x86_64`
      supported) passed to PyInstaller
- [x] 3.4 Implement optional signing: ad-hoc `codesign` of the payload
      by default, `--sign <identity>` running `productsign`
- [x] 3.5 Make `--version` and `--arch` required arguments (no defaults)
      and embed the version (`v`-prefixed) and architecture in the output
      name (`bin/GitFileShardPlugin.v<version>.<arch>.pkg`); drop the
      hardcoded version from `distribution.xml` (filled by `productbuild`)
- [x] 3.6 Add `util/build-pkg-arm64.sh` and `util/build-pkg-x86_64.sh`
      wrappers (version as first argument, extra arguments forwarded,
      `.venv` activated when present)

## 4. Verification

- [x] 4.1 `bash -n` syntax check of all shell scripts
- [x] 4.2 Local build produces `bin/GitFileShardPlugin.v0.1.0.arm64.pkg`
      via `util/build-pkg-arm64.sh 0.1.0`
- [x] 4.2.1 Missing `--version` / `--arch` fail with usage errors
- [x] 4.3 Manual install (user): files land in
      `/Library/Application Support/ImeSense/Git File Shard Plugin/`,
      symlink works, `git file-shard --help` runs
      (first attempt installed into a flat
      `/Library/Application Support/ImeSense Git File Shard Plugin/`
      folder due to an install-location composition bug, fixed)
- [x] 4.4 Manual uninstall (user): symlink, folder and receipt removed
      (the flat folder from the first attempt must be removed manually)

## 5. Spec merge

- [x] 5.1 Merge deltas into `openspec/specs/pkg-installer/spec.md` and
      archive this change
