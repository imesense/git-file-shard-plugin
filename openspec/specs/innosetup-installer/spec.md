# innosetup-installer Specification

## Purpose

Windows installer for the git-file-shard plugin, built with Inno Setup 7.
Installs the plugin binary into a `bin` subfolder, optionally adds that folder
to the `PATH` environment variable, and cleanly removes everything on
uninstall.

## Requirements

### Requirement: Installer Package Identity

The installer SHALL identify the application as "ImeSense Git File Shard
Plugin" with AppId `{359E3F55-6620-4D88-B376-1636D7719F0A}`, publisher
"ImeSense", and project URL `https://github.com/imesense/git-file-shard-plugin/`.

#### Scenario: Installed application identity

- **WHEN** the installed application is inspected in Programs and Features
- **THEN** it is listed as "ImeSense Git File Shard Plugin" published by
  "ImeSense"

### Requirement: Installation Scope and Target

The installer SHALL default to `{autopf}\ImeSense\Git File Shard Plugin`.

The installer SHALL restrict installation to x64-compatible Windows
(`ArchitecturesAllowed=x64compatible`, 64-bit install mode) and SHALL
allow the privilege mode to be overridden on the command line
(`PrivilegesRequiredOverridesAllowed=commandline`).

#### Scenario: Default installation directory

- **WHEN** the user runs the installer without changing the directory
- **THEN** the plugin is installed under `{autopf}\ImeSense\Git File Shard Plugin`

#### Scenario: Silent per-user install

- **WHEN** the installer is launched with a command-line override for
  privileges
- **THEN** installation proceeds without requiring administrator rights

### Requirement: Payload Installation

The installer SHALL copy `git-file-shard.exe` from `dist/` into
`{app}\bin`, together with `README.md` and `LICENSE.txt` into `{app}`.

The uninstall display icon SHALL point to `{app}\bin\git-file-shard.exe`.

The installer SHALL NOT create Start menu shortcuts.

#### Scenario: Files after installation

- **WHEN** installation completes
- **THEN** `{app}\bin\git-file-shard.exe`, `{app}\README.md` and
  `{app}\LICENSE.txt` exist
- **AND** no Start menu shortcut for the application is created

### Requirement: Add to PATH Task

The installer SHALL provide an `addtopath` task, checked by default, with a
localized description ("Add program folder to PATH" / «Добавить папку
программы в переменную PATH») and a localized group description
("Additional tasks:" / «Дополнительные задачи:»).

When the task is selected, after installation the installer SHALL append
`{app}\bin` to the `Path` value of
`System\CurrentControlSet\Control\Session Manager\Environment` under the
`HKA` root (HKLM in admin mode, HKCU otherwise).

#### Scenario: PATH updated on install

- **WHEN** the user completes installation with the addtopath task selected
- **THEN** `{app}\bin` appears exactly once in the machine or user `Path`
  value

### Requirement: PATH Value Handling

The PATH value SHALL be read with `RegQueryStringValue` (accepting both
`REG_SZ` and `REG_EXPAND_SZ`) and written back with
`RegWriteExpandStringValue` so entries like `%SystemRoot%` keep working.

PATH updates SHALL be idempotent: the entry is matched case-insensitively
with backslash normalization, empty entries are dropped, and the registry is
written only when the resulting value differs from the current one.

#### Scenario: PATH entry is idempotent

- **WHEN** the installer runs on a machine where `{app}\bin` is already in
  PATH (any letter case, with or without trailing backslash)
- **THEN** the registry value is not rewritten and no duplicate entry is
  created

### Requirement: Environment Change Notification

After a successful update the installer SHALL broadcast `WM_SETTINGCHANGE`
with `SMTO_ABORTIFHUNG` using `SendMessageTimeoutW` imported from
`user32.dll`, so running applications (including Explorer) pick up the new
PATH without logoff or reboot.

#### Scenario: Running applications pick up the change

- **WHEN** the PATH is updated during installation
- **THEN** running processes are notified about the environment change and
  no logoff or reboot is required

### Requirement: PATH Removal on Uninstall

On uninstall, the `{app}\bin` entry SHALL be removed from PATH at the
`usUninstall` step, while the application folder still exists.

#### Scenario: PATH restored on uninstall

- **WHEN** the user uninstalls the application
- **THEN** the `{app}\bin` entry is removed from PATH
- **AND** all other PATH entries are preserved in their original order

### Requirement: Localized Task Messages

Every user-visible installer task message SHALL be defined in both
`Locales/Options.eng.isl` (English) and `Locales/Options.rus.isl` (Russian)
custom message files.

#### Scenario: Russian interface

- **WHEN** the installer runs with the Russian language selected
- **THEN** the add-to-PATH task and its group header are shown in Russian

### Requirement: Build Reproducibility

The installer SHALL be built from
`src/installer_windows_inno/Setup.iss` with Inno Setup 7
(`ISCC.exe`), producing `bin/GitFileShardPlugin.exe`.

The build SHALL require `dist/git-file-shard.exe`, `README.md` and
`LICENSE.txt` to exist beforehand.

#### Scenario: Local build

- **WHEN** `ISCC.exe Setup.iss` is executed from the installer directory
- **THEN** `bin/GitFileShardPlugin.exe` is produced without errors
