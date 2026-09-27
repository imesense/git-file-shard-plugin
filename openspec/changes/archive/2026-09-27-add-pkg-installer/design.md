# Design: add-pkg-installer

## Context

The Windows installers (Inno Setup, WiX) install `git-file-shard.exe` into
`<install root>\bin` and optionally add that folder to `PATH`. On macOS the
plugin binary comes from the same PyInstaller spec (`dist/git-file-shard`,
no `.exe` suffix). This change adds the macOS packaging project using only
stock Apple tools: `pkgbuild`, `productbuild`, `codesign`, `productsign`.

## Goals / Non-Goals

- Goals: native `.pkg` built from a shell script; installation layout
  mirroring Windows; `git file-shard` reachable through `PATH` without
  editing shell profiles; bilingual installer resources; uninstall script;
  configurable target architecture; optional code signing.
- Non-Goals: CI/CD packaging (skipped for now); notarization (no Apple
  Developer account yet); a GUI uninstaller; per-user (home directory)
  installation.

## Decisions

### D1. Installation layout mirrors Windows

Payload root: `/Library/Application Support/ImeSense/Git File Shard Plugin/`
with `bin/git-file-shard`, `README.md`, `LICENSE.txt`, `uninstall.sh`. This
mirrors the Windows `{app}\bin` layout, so both platforms share the same
mental model. `/Library/Application Support/` is the standard macOS location
for application support files and is writable by admin only (the installer
runs as admin through `productbuild`'s standard authorization).

Pitfall observed during development: composing the install location from a
single "publisher + product" name produced the flat folder
`/Library/Application Support/ImeSense Git File Shard Plugin/` instead of
the nested `ImeSense/Git File Shard Plugin/`. The path must be assembled
from separate publisher and product components, and the resulting
`install-location` verified in the package's `PackageInfo` after every
build (`pkgutil --expand` + grep).

### D2. PATH integration via symlink

Instead of editing `/etc/paths`, `~/.zshrc` or writing to `/etc/paths.d/`
(all of which have side effects: `path_helper` reordering, login-shell-only
application, files left behind on uninstall), the `postinstall` script
creates a single symlink:

```sh
ln -h -s '/Library/Application Support/ImeSense/Git File Shard Plugin/bin/git-file-shard' \
    /usr/local/bin/git-file-shard
```

`/usr/local/bin` is on `PATH` in every default shell and exists on all
supported macOS versions. The script removes any stale symlink first and
refuses to clobber a real file at that path. The symlink is removed again
on uninstall. Git finds `git-file-shard` in `PATH` the same way it does on
Windows.

### D3. pkgbuild + productbuild split

- `pkgbuild --root <staging> --identifier org.imesense.git-file-shard
  --version 0.1.0 --scripts Scripts` builds the component package from a
  staged payload tree.
- `productbuild --package <component.pkg> --distribution distribution.xml
  --resources Resources` wraps it into a distribution package with the
  title, license and localized welcome/conclusion resources
  (`en.lproj`, `ru.lproj` — the direct analogue of the Inno/WiX locale
  files).

Identifier: `org.imesense.git-file-shard` (reverse-DNS under the ImeSense
domain), version `0.1.0` (matches the WiX package version).

### D4. Optional signing, ad-hoc by default

There is no Apple Developer account, so signing must be optional:

- Default: the PyInstaller binary is ad-hoc signed (`codesign --force
  --sign -`), which is required for the binary to run at all on Apple
  Silicon; the `.pkg` itself stays unsigned (Gatekeeper shows the usual
  unsigned-package warning for downloads).
- `--sign <identity>`: after `productbuild`, the script runs
  `productsign --sign <identity>` for a Developer ID Installer identity,
  ready for when an account exists. Notarization remains a follow-up.

### D5. Explicit version, configurable architecture, separate bundling

`build.sh` takes the target architecture (`--arch arm64|x86_64`) and the
package version (`--version <version>`) strictly as command line arguments,
with no defaults: the version and architecture of a distributable package
must never be guessed. Bundling the plugin (PyInstaller) is a separate
step that runs beforehand and produces `dist/git-file-shard`; `build.sh`
only packages the prebuilt binary, verifies its architecture with `lipo`
and fails early with a clear message when the payload is missing or built
for the wrong architecture. Cross-bundling single architectures requires
a Python interpreter that supports the target architecture (a universal2
build for the other architecture).

The output name embeds the version and the architecture before the
extension (`GitFileShardPlugin.v0.1.0.arm64.pkg`) so artifacts for
different versions and architectures can coexist in `bin/`; the
`--plain-name` option produces `bin/GitFileShardPlugin.pkg` instead while
the package still records the version and architecture inside. The
`distribution.xml` carries no hardcoded version; `productbuild` fills the
`pkg-ref` version from the component package built with
`pkgbuild --version`.

Convenience wrappers `util/build-pkg-arm64.sh` and `util/build-pkg-x86_64.sh`
take the version as their first argument and forward any extra arguments to
`build.sh` (e.g. `--sign`, `--plain-name`).

### D6. Uninstall via script

macOS packages have no built-in uninstaller. `uninstall.sh` is installed
next to the payload and removes, in order: the symlink, the installation
folder, and the receipt (`pkgutil --forget org.imesense.git-file-shard` so
the package stops showing as installed). It refuses to run without admin
rights (`rm -rf` under `/Library` and `/usr/local/bin` need them).

## Risks / Trade-offs

- Unsigned packages trigger Gatekeeper warnings when quarantined
  (downloaded); local builds are unaffected. Accepted until a Developer
  account exists.
- `/usr/local` may be owned by Homebrew on Intel Macs; the script only
  creates a single symlink there and removes exactly that symlink on
  uninstall, so Homebrew usage is not disturbed.
- `/Library/Application Support/` with spaces in the path requires careful
  quoting in every script (the symlink target in particular).
- pkg receipts do not upgrade in place the way MSI `MajorUpgrade` does;
  reinstalling the same or newer version simply overwrites the payload,
  which is acceptable at this stage.
