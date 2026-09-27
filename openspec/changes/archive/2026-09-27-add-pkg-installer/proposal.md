# Change: Add macOS PKG installer with symlink PATH integration

## Why

The plugin already ships as Windows installers (Inno Setup EXE, WiX MSI), but
there is no macOS distribution. A native distribution package (`.pkg`, built
with the stock `pkgbuild` / `productbuild` tools) gives macOS users the same
guided install experience: payload into an application folder, PATH
integration so `git file-shard` works, and a clean uninstall path.

## What Changes

- Add a macOS installer project
  (`src/ImeSense.GitFileShardPlugin.Setup.Pkg/`) producing
  `bin/GitFileShardPlugin.pkg` via a `build.sh` script that drives
  `pkgbuild` and `productbuild`.
- Package `dist/git-file-shard` into
  `/Library/Application Support/ImeSense/Git File Shard Plugin/bin`,
  with `README.md`, `LICENSE.txt` and `uninstall.sh` in the installation
  folder root (mirrors the Windows layout).
- Create a `/usr/local/bin/git-file-shard` symlink to the installed binary
  from the `postinstall` script (PATH integration without editing shell
  profiles).
- Ship an `uninstall.sh` script that removes the symlink, the installation
  folder and the package receipt (`pkgutil --forget`).
- Localize installer resources (welcome, license, conclusion) in English
  and Russian (`Resources/en.lproj/`, `Resources/ru.lproj/`).
- Make the payload architecture configurable (`arm64` default, `x86_64`
  supported) and code signing optional (ad-hoc by default, Developer ID
  Installer identity via a flag).

## Impact

- Affected specs: `pkg-installer` (new capability)
- Affected code: `src/ImeSense.GitFileShardPlugin.Setup.Pkg/` (new)
- CI is explicitly out of scope for this change.
