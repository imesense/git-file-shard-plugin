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

The MSI SHALL install `git-file-shard.exe` into the `bin` subfolder of
the installation folder, together with `README.md` and `LICENSE.txt` in
the installation folder root.

The default installation folder SHALL be
`ProgramFiles6432Folder\ImeSense\Git File Shard Plugin`.

The MSI SHALL NOT create shortcuts.

#### Scenario: Files after installation

- **WHEN** installation completes
- **THEN** `<INSTALLFOLDER>\bin\git-file-shard.exe`,
      `<INSTALLFOLDER>\README.md` and `<INSTALLFOLDER>\LICENSE.txt` exist
- **AND** no shortcut is created

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

Dialog transitions SHALL be published with `Order` values greater than
the built-in `WixUI_InstallDir` publishes on the same controls
(`Order="5"` on `InstallDirDlg/Next`, `Order="2"` on
`VerifyReadyDlg/Back`), because MSI executes ControlEvents in ascending
`Order` and the last `NewDialog` event wins.

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
`src/ImeSense.GitFileShardPlugin.Setup.Wix/ImeSense.GitFileShardPlugin.Setup.Wix.wixproj`
with WiX Toolset 7 (`dotnet build`), producing
`bin/GitFileShardPlugin.msi`.

The build SHALL require `dist/git-file-shard.exe`, `README.md` and
`LICENSE.txt` to exist beforehand.

#### Scenario: Local build

- **WHEN** `dotnet build` is executed on the WiX project after the
      PyInstaller payload is built
- **THEN** `bin/GitFileShardPlugin.msi` is produced without errors
