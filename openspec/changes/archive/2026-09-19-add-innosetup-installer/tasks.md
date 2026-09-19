# Tasks: add-innosetup-installer

## 1. Installer project

- [x] 1.1 Create `src/ImeSense.GitFileShardPlugin.Setup.Inno/Setup.iss` with
      application identity, x64 restrictions, privilege overrides, license
      page and solid compression
- [x] 1.2 Package `dist/git-file-shard.exe`, `README.md`, `LICENSE.txt`;
      install binary into `{app}\bin`
- [x] 1.3 Point `UninstallDisplayIcon` at `{app}\bin\git-file-shard.exe`
- [x] 1.4 Remove `[Icons]` section (no Start menu shortcut)

## 2. PATH integration

- [x] 2.1 Add `addtopath` task with localized descriptions in
      `Locales/Options.eng.isl` and `Locales/Options.rus.isl`
- [x] 2.2 Implement `[Code]` section: read/write PATH via `HKA` +
      `RegQueryStringValue` / `RegWriteExpandStringValue`
- [x] 2.3 Make updates idempotent (case-insensitive match, backslash
      normalization, drop empty entries, write only on change)
- [x] 2.4 Broadcast `WM_SETTINGCHANGE` via `SendMessageTimeoutW@user32.dll`
      (engine lacks `SendMessageTimeout`; `SendNotifyMessage` is unsafe for
      string `lParam`)
- [x] 2.5 Hook `CurStepChanged` (ssPostInstall) and
      `CurUninstallStepChanged` (usUninstall)
- [x] 2.6 Enable the task by default (remove `Flags: unchecked`) and add
      doc-comments to `[Code]` functions

## 3. Verification

- [x] 3.1 Compile with `ISCC.exe Setup.iss` → `bin/GitFileShardPlugin.exe`
- [x] 3.2 Manual install: PATH entry added, Explorer picks it up without
      logoff (confirmed by user)
- [x] 3.3 Manual uninstall: PATH entry removed, other entries preserved

## 4. Spec merge

- [x] 4.1 Merge deltas into `openspec/specs/innosetup-installer/spec.md` and
      archive this change
