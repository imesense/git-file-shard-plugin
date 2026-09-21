# Tasks: add-wix-installer

## 1. Installer project

- [x] 1.1 Create `src/ImeSense.GitFileShardPlugin.Setup.Wix/` project
      (`WixToolset.Sdk/7.0.0`, `WixToolset.UI.wixext/7.0.0`,
      `OutputName=GitFileShardPlugin`) and add it to
      `GitFileShardPlugin.sln`
- [x] 1.2 Author `Package.wxs`: identity (name, manufacturer, version,
      `UpgradeCode`), `Scope="perMachineOrUser"`, `MajorUpgrade`,
      `MediaTemplate EmbedCab="yes"`, license RTF
- [x] 1.3 Author `Folders.wxs`: `INSTALLFOLDER` under
      `ProgramFiles6432Folder` with `INSTALLBIN` (`bin`) subfolder
- [x] 1.4 Author `ApplicationComponents.wxs`: `git-file-shard.exe` into
      `INSTALLBIN`, `README.md` and `LICENSE.txt` into `INSTALLFOLDER`

## 2. PATH integration

- [x] 2.1 Author `Environment.wxs`: `AddToPath` component with
      `Condition="ADDTOPATH"` and an `Environment` table entry
      (`Name="PATH"`, `Part="last"`, `Action="set"`, `System="yes"`)
- [x] 2.2 Define `ADDTOPATH` property (`Secure="yes"`, default `1`) in
      `Package.wxs`
- [x] 2.3 Reference both component groups from the `Main` feature

## 3. Options dialog

- [x] 3.1 Author `OptionsDlg` (banner, description, checkbox bound to
      `ADDTOPATH`, Back/Next/Cancel) inside the `UI` element
- [x] 3.2 Insert into the `WixUI_InstallDir` sequence with correct
      `Order` values: `InstallDirDlg/Next → OptionsDlg` `Order="5"`,
      `VerifyReadyDlg/Back → OptionsDlg` `Order="2"` (built-in
      publishes use `Order="4"` / `Order="1"`; last `NewDialog` wins)
- [x] 3.3 Add localized strings to `Package.en-us.wxl` and
      `Package.ru-ru.wxl` (dialog title/description, task text)

## 4. Verification

- [x] 4.1 `dotnet build` of the `.wixproj` compiles without WiX errors
      (requires `dist/git-file-shard.exe` to exist)
- [x] 4.2 Manual install: options dialog visible between the install
      directory and ready pages; PATH entry added when checked
      (confirmed by user)
- [x] 4.3 Manual uninstall: PATH entry removed by MSI, other entries
      preserved
- [x] 4.4 Maintenance mode: dialog sequence falls back to built-in
      `Installed` transitions

## 5. Spec merge

- [x] 5.1 Merge deltas into `openspec/specs/wix-installer/spec.md` and
      archive this change
