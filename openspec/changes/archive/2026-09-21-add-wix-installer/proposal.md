# Change: Add WiX Toolset MSI installer with optional PATH integration

## Why

The plugin already ships as an Inno Setup EXE installer, but an MSI package
built with WiX Toolset 7 gives a standards-compliant Windows Installer
database: Group Policy deployment, cleaner transactional install/rollback,
and PATH management handled natively by the MSI Environment table (no
hand-written registry code).

## What Changes

- Add a WiX Toolset 7 project
  (`src/ImeSense.GitFileShardPlugin.Setup.Wix/`) producing
  `bin/GitFileShardPlugin.msi` via `dotnet build`.
- Package `dist/git-file-shard.exe` into `INSTALLBIN` (`...\bin`) and
  `README.md` / `LICENSE.txt` into `INSTALLFOLDER`, with no shortcuts.
- Add a custom `OptionsDlg` dialog (inserted between `InstallDirDlg` and
  `VerifyReadyDlg` in the `WixUI_InstallDir` sequence) with an
  add-to-PATH checkbox, checked by default.
- Register `INSTALLBIN` in the `PATH` environment variable through a
  conditionally installed component using the MSI `Environment` table.
- Provide English and Russian localized strings
  (`Package.en-us.wxl`, `Package.ru-ru.wxl`).

## Impact

- Affected specs: `wix-installer` (new capability)
- Affected code: `src/ImeSense.GitFileShardPlugin.Setup.Wix/` (new),
  `GitFileShardPlugin.sln` (project added)
