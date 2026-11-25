# Change: Make Windows installers architecture-aware

## Why

The Windows installers never looked at the architecture of the payload they
package. Inno Setup was pinned to `x64compatible` regardless of the bundled
`git-file-shard.exe`, and the WiX project left the MSBuild `Platform` unset,
so the MSI silently defaulted to an x86 package that installs into
`C:\Program Files (x86)` while the payload is x64. Nothing aborted when the
payload architecture and the installer architecture disagreed, and both
artifacts were written under names without an architecture, so builds for
different architectures overwrote each other.

The macOS and Linux installers already carry the architecture in the
artifact name and verify it before packaging; the Windows path should behave
the same way.

## What Changes

- Add `util/detect-payload-arch.ps1`, which reads the PE machine type of a
  Windows executable and reports `x64`, `arm64` or `x86`.
- Split the Windows wrappers by architecture, mirroring the PKG/DMG/DEB
  wrappers: `util/build-exe-x64.bat`, `util/build-exe-arm64.bat`,
  `util/build-msi-x64.bat` and `util/build-msi-arm64.bat`. Each one names its
  architecture explicitly, reads the payload PE header and aborts when it
  disagrees, and forwards the remaining arguments to `ISCC.exe` /
  `dotnet build` verbatim; the shared checks live in
  `util/_build-windows-installer.bat`.
- `Setup.iss` accepts `/DArch=x64|arm64` (default `x64`), selects
  `SetupArchitecture`, `ArchitecturesAllowed` and
  `ArchitecturesInstallIn64BitMode` from it, and writes
  `bin/GitFileShardPlugin.<arch>.exe`.
- The WiX project defaults `Platform` to `x64` and names the output
  `GitFileShardPlugin.$(Platform)`, producing
  `bin/<culture>/GitFileShardPlugin.<arch>.msi` (the SDK maps `Platform` to
  the MSI platform and the install target).
- **BREAKING**: the Windows artifacts are renamed from
  `GitFileShardPlugin.exe` / `GitFileShardPlugin.msi` to
  `GitFileShardPlugin.<arch>.exe` / `GitFileShardPlugin.<arch>.msi`.
- CI builds the Windows installers through the x64 wrappers and uploads the
  architecture-suffixed artifacts.
- Record the architecture rules in `AGENTS.md`, the OpenSpec project context
  and the `innosetup-installer` / `wix-installer` capability specs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `innosetup-installer`: the setup architecture and the target Windows
  architectures follow the payload architecture, and the artifact name
  carries it.
- `wix-installer`: the MSI platform follows the payload architecture (no
  more silent x86 default) and the artifact name carries it.

## Impact

- Affected code: `src/installer_windows_inno/Setup.iss`,
  `src/installer_windows_wix/GitFileShard.Installer.Wix.wixproj`,
  `util/build-exe-<arch>.bat`, `util/build-msi-<arch>.bat`,
  `util/_build-windows-installer.bat`, `util/detect-payload-arch.ps1`
  (new), `.github/workflows/build-application.yml`, `AGENTS.md`,
  `openspec/config.yaml`.
- Affected specs: `innosetup-installer`, `wix-installer`.
- Artifact names change: any script, release note or download page that
  references `bin/GitFileShardPlugin.exe` or
  `bin/en-US/GitFileShardPlugin.msi` must use the architecture-suffixed
  names.
- No new dependencies: the detection helper uses the PowerShell that ships
  with Windows; Inno Setup 7 and the .NET 8 SDK are already required.
- MSI packages built without `-p:Platform` change from an x86 package to an
  x64 package; existing x86 MSI installations upgrade through the shared
  `UpgradeCode`.
