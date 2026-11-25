# wix-installer Specification

## Purpose

MSI package for the git-file-shard plugin, built with WiX Toolset 7.
Installs the plugin binary into a `bin` subfolder, optionally adds that
folder to the `PATH` environment variable through the MSI Environment
table, and cleanly removes everything on uninstall.

## Requirements

### Requirement: MSI Package Identity

The MSI SHALL identify the application as "ImeSense Git File Shard
Plugin" with manufacturer "ImeSense", version matching the plugin release,
and a stable `UpgradeCode` (`FF816155-5EE5-4543-A55B-5EC56D7A6561`).

The package SHALL use `Scope="perMachineOrUser"` and SHALL embed all
cabinets into a single-file MSI (`MediaTemplate EmbedCab="yes"`).

A `MajorUpgrade` SHALL handle version upgrades and SHALL refuse
downgrades with a localized error message.

#### Scenario: Downgrade blocked

- **WHEN** an older version is installed over a newer one
- **THEN** the installation aborts with the localized downgrade error

### Requirement: Payload Installation

The MSI SHALL install `git-file-shard.exe` into the `bin` subfolder of the
installation folder, with `README.md` and `LICENSE.txt` in the installation
folder root, SHALL default to
`ProgramFiles6432Folder\ImeSense\Git File Shard Plugin`, SHALL follow the
payload architecture in its MSI platform, and SHALL NOT create shortcuts.

#### Scenario: Files after installation

- **WHEN** installation completes
- **THEN** `<INSTALLFOLDER>\bin\git-file-shard.exe`,
      `<INSTALLFOLDER>\README.md` and `<INSTALLFOLDER>\LICENSE.txt` exist
- **AND** no shortcut is created

#### Scenario: x64 package install location

- **WHEN** the MSI is built from an x64 payload
- **THEN** its platform is `x64`
- **AND** `ProgramFiles6432Folder` resolves to the 64-bit `Program Files`,
      not `Program Files (x86)`

#### Scenario: arm64 package install location

- **WHEN** the MSI is built from an arm64 payload
- **THEN** its platform is `Arm64`
- **AND** `ProgramFiles6432Folder` resolves to the 64-bit `Program Files`

### Requirement: Add to PATH Option

The MSI SHALL provide an `OptionsDlg` dialog with an add-to-PATH checkbox
bound to the `ADDTOPATH` property, checked by default, localized in
English and Russian.

When `ADDTOPATH` is set, the MSI SHALL append the `bin` directory to the
system `PATH` environment variable via the MSI `Environment` table
(`Part="last"`, `Action="set"`, `System="yes"`), and SHALL remove the
entry on uninstall.

The `ADDTOPATH` property SHALL be `Secure="yes"` so its value survives
elevation.

#### Scenario: PATH updated on install

- **WHEN** the user completes installation with the checkbox checked
- **THEN** the `bin` directory appears in the system `PATH` exactly once

#### Scenario: Option declined

- **WHEN** the user unchecks the add-to-PATH checkbox
- **THEN** the `PATH` environment variable is not modified

#### Scenario: PATH restored on uninstall

- **WHEN** the application is uninstalled
- **THEN** the `bin` entry is removed from `PATH`
- **AND** all other PATH entries are preserved

### Requirement: Options Dialog Sequence

The `OptionsDlg` dialog SHALL appear between `InstallDirDlg` and
`VerifyReadyDlg` during first-time installation.

The maintenance (`Installed`) sequence SHALL fall back to the built-in
transitions without showing `OptionsDlg`.

#### Scenario: First-time install

- **WHEN** the user advances past the install directory page
- **THEN** the options dialog with the PATH checkbox is shown before the
      ready-to-install page

#### Scenario: Maintenance mode

- **WHEN** the MSI is launched in maintenance mode on an existing
      installation
- **THEN** the built-in dialog sequence is used and `OptionsDlg` is not
      shown

### Requirement: Dialog Transition Ordering

Dialog transitions SHALL be published with `Order` values greater than
the built-in `WixUI_InstallDir` publishes on the same controls
(`Order="5"` on `InstallDirDlg/Next`, `Order="2"` on
`VerifyReadyDlg/Back`), because MSI executes ControlEvents in ascending
`Order` and the last `NewDialog` event wins.

#### Scenario: Custom transition takes precedence

- **WHEN** the user clicks Next on `InstallDirDlg` during first-time
      installation
- **THEN** the custom publish runs after the built-in one and `OptionsDlg`
      is displayed

### Requirement: Localized Strings

Every user-visible MSI string SHALL be defined in both
`Package.en-us.wxl` (English) and `Package.ru-ru.wxl` (Russian)
localization files; the Russian file SHALL use codepage 1251.

#### Scenario: Russian interface

- **WHEN** the MSI runs with the Russian culture selected
- **THEN** the options dialog title, description and PATH task text are
      shown in Russian

### Requirement: Build Reproducibility

The MSI SHALL be built from
`src/installer_windows_wix/GitFileShard.Installer.Wix.wixproj` with WiX
Toolset 7 (`dotnet build`), producing
`bin/<culture>/GitFileShardPlugin.<arch>.msi` for the `en-US` and `ru-RU`
cultures, and SHALL require `dist/git-file-shard.exe`, `README.md` and
`LICENSE.txt` to exist beforehand.

#### Scenario: One wrapper per architecture

- **WHEN** the repository is inspected
- **THEN** `util/build-msi-x64.bat` and `util/build-msi-arm64.bat` exist,
  each passing its architecture through `-p:Platform=<arch>` and forwarding
  the remaining arguments to `dotnet build` verbatim

#### Scenario: Local build

- **WHEN** `util\build-msi-x64.bat` runs after an x64 PyInstaller payload is
  built
- **THEN** `bin/en-US/GitFileShardPlugin.x64.msi` and
      `bin/ru-RU/GitFileShardPlugin.x64.msi` are produced without errors

#### Scenario: Default platform

- **WHEN** the WiX project is built without an explicit `Platform` property
- **THEN** the empty or `AnyCPU` platform becomes `x64`
- **AND** the MSI platform and the output file name both use `x64`

#### Scenario: arm64 build

- **WHEN** the WiX project is built with `-p:Platform=arm64` after an arm64
  PyInstaller payload is built
- **THEN** `GitFileShardPlugin.arm64.msi` with platform `Arm64` is produced

#### Scenario: Architecture mismatch

- **WHEN** `util\build-msi-arm64.bat` runs with an x64 payload
- **THEN** the build aborts with an error naming both architectures
- **AND** no MSI is produced
