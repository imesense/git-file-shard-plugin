# Delta for innosetup-installer

## MODIFIED Requirements

### Requirement: Installation Scope and Target

The installer SHALL default to `{autopf}\ImeSense\Git File Shard Plugin`.

The setup program SHALL be the x64 stub (`SetupArchitecture=x64`), because
Inno Setup 7 ships no Arm64 setup stub; on Arm64 Windows 11 it runs through
the x64 emulation layer.

The target Windows architectures SHALL follow the architecture of the
bundled payload:

- for an `x64` payload, `ArchitecturesAllowed` and
  `ArchitecturesInstallIn64BitMode` SHALL be `x64compatible`, which matches
  x64 Windows and Arm64 Windows 11;
- for an `arm64` payload, `ArchitecturesAllowed` and
  `ArchitecturesInstallIn64BitMode` SHALL be `arm64`, so the setup refuses
  to install on x64 Windows and installs in 64-bit mode on Arm64 Windows.

The installer SHALL allow the privilege mode to be overridden on the command
line (`PrivilegesRequiredOverridesAllowed=commandline`).

#### Scenario: Default installation directory

- **WHEN** the user runs the installer without changing the directory
- **THEN** the plugin is installed under `{autopf}\ImeSense\Git File Shard Plugin`

#### Scenario: x64 payload targets x64-compatible Windows

- **WHEN** the installer is built from an x64 payload
- **THEN** it installs on x64 Windows and on Arm64 Windows 11
- **AND** it writes to the 64-bit `Program Files` directory

#### Scenario: arm64 payload targets Arm64 Windows

- **WHEN** the installer is built from an arm64 payload
- **THEN** it refuses to install on x64 Windows
- **AND** it installs in 64-bit mode on Arm64 Windows

#### Scenario: Silent per-user install

- **WHEN** the installer is launched with a command-line override for
  privileges
- **THEN** installation proceeds without requiring administrator rights

### Requirement: Build Reproducibility

The installer SHALL be built from `src/installer_windows_inno/Setup.iss`
with Inno Setup 7 (`ISCC.exe`), producing
`bin/GitFileShardPlugin.<arch>.exe`, where `<arch>` is `x64` or `arm64`.

The architecture SHALL come from the `/DArch=<arch>` preprocessor define and
SHALL default to `x64` when the define is absent. An unsupported value SHALL
stop compilation with an error.

There SHALL be one wrapper per architecture, `util/build-exe-x64.bat` and
`util/build-exe-arm64.bat`, each passing its architecture through
`/DArch`. Each wrapper SHALL read the architecture of
`dist/git-file-shard.exe` from its PE header and SHALL abort when it does not
match the wrapper's architecture. Remaining arguments SHALL be forwarded to
`ISCC.exe` verbatim.

The build SHALL require `dist/git-file-shard.exe`, `README.md` and
`LICENSE.txt` to exist beforehand.

#### Scenario: Local build

- **WHEN** `util\build-exe-x64.bat` runs after an x64 PyInstaller payload is
  built
- **THEN** `bin/GitFileShardPlugin.x64.exe` is produced without errors

#### Scenario: arm64 build

- **WHEN** `util\build-exe-arm64.bat` runs after an arm64 PyInstaller payload
  is built
- **THEN** `bin/GitFileShardPlugin.arm64.exe` is produced without errors

#### Scenario: Architecture mismatch

- **WHEN** `util\build-exe-arm64.bat` runs with an x64 payload
- **THEN** the build aborts with an error naming both architectures
- **AND** no installer is produced

#### Scenario: Unsupported architecture define

- **WHEN** `ISCC.exe /DArch=bad Setup.iss` runs
- **THEN** compilation fails with an error about the unsupported `Arch`
  value
