# Delta for wix-installer

## MODIFIED Requirements

### Requirement: Payload Installation

The MSI SHALL install `git-file-shard.exe` into the `bin` subfolder of
the installation folder, together with `README.md` and `LICENSE.txt` in
the installation folder root.

The default installation folder SHALL be
`ProgramFiles6432Folder\ImeSense\Git File Shard Plugin`.

The MSI platform SHALL follow the architecture of the bundled payload, and
the platform SHALL determine the install target:

- for an `x64` payload the MSI platform SHALL be `x64` and
  `ProgramFiles6432Folder` SHALL resolve to the 64-bit `Program Files`
  directory;
- for an `arm64` payload the MSI platform SHALL be `Arm64` and
  `ProgramFiles6432Folder` SHALL resolve to the 64-bit `Program Files`
  directory.

The MSI SHALL NOT create shortcuts.

#### Scenario: Files after installation

- **WHEN** installation completes
- **THEN** `<INSTALLFOLDER>\bin\git-file-shard.exe`,
      `<INSTALLFOLDER>\README.md` and `<INSTALLFOLDER>\LICENSE.txt` exist
- **AND** no shortcut is created

#### Scenario: x64 package install location

- **WHEN** the MSI is built from an x64 payload
- **THEN** its platform is `x64`
- **AND** the plugin is installed under the 64-bit `Program Files`, not
      `Program Files (x86)`

#### Scenario: arm64 package install location

- **WHEN** the MSI is built from an arm64 payload
- **THEN** its platform is `Arm64`
- **AND** the plugin is installed under the 64-bit `Program Files`

### Requirement: Build Reproducibility

The MSI SHALL be built from
`src/installer_windows_wix/GitFileShard.Installer.Wix.wixproj`
with WiX Toolset 7 (`dotnet build`), producing
`bin/<culture>/GitFileShardPlugin.<arch>.msi` for the `en-US` and `ru-RU`
cultures, where `<arch>` is `x64` or `arm64`.

The MSBuild `Platform` property SHALL default to `x64` when it is empty or
`AnyCPU`, SHALL be passed through as the MSI platform, and SHALL determine
the output file name.

There SHALL be one wrapper per architecture, `util/build-msi-x64.bat` and
`util/build-msi-arm64.bat`, each passing its architecture through
`-p:Platform=<arch>`. Each wrapper SHALL read the architecture of
`dist/git-file-shard.exe` from its PE header and SHALL abort when it does not
match the wrapper's architecture. Remaining arguments SHALL be forwarded to
`dotnet build` verbatim.

The build SHALL require `dist/git-file-shard.exe`, `README.md` and
`LICENSE.txt` to exist beforehand.

#### Scenario: Local build

- **WHEN** `util\build-msi-x64.bat` runs after an x64 PyInstaller payload is
  built
- **THEN** `bin/en-US/GitFileShardPlugin.x64.msi` and
      `bin/ru-RU/GitFileShardPlugin.x64.msi` are produced without errors

#### Scenario: Default platform

- **WHEN** the WiX project is built without an explicit `Platform` property
- **THEN** an `x64` MSI is produced

#### Scenario: Architecture mismatch

- **WHEN** `util\build-msi-arm64.bat` runs with an x64 payload
- **THEN** the build aborts with an error naming both architectures
- **AND** no MSI is produced
