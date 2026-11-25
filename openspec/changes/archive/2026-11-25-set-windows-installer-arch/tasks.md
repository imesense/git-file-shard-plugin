# Tasks: set-windows-installer-arch

## 1. Payload architecture detection

- [x] 1.1 Add `util/detect-payload-arch.ps1` that reads the PE `Machine`
      field and prints `x64`, `arm64` or `x86`, failing with a message for a
      missing or non-PE file; verify it prints `x64` for
      `dist/git-file-shard.exe` and fails for a text file
- [x] 1.2 Document the helper in `AGENTS.md` (build commands and Windows
      wrapper conventions); verify the file mentions
      `util/detect-payload-arch.ps1`

## 2. Inno Setup EXE installer

- [x] 2.1 Add the `/DArch=x64|arm64` define (default `x64`) with an `#error`
      for unsupported values, and derive `SetupArchitecture`,
      `ArchitecturesAllowed` and `ArchitecturesInstallIn64BitMode` from it;
      verify `ISCC.exe /DArch=arm64 src\installer_windows_inno\Setup.iss`
      compiles and `ISCC.exe /DArch=bad ...` fails on the `#error`
- [x] 2.2 Name the output `GitFileShardPlugin.{#Arch}.exe`; verify the
      compile produces `bin/GitFileShardPlugin.x64.exe` and
      `bin/GitFileShardPlugin.arm64.exe` for the matching `/DArch` values
- [x] 2.3 Split the wrapper into `util/build-exe-x64.bat` and
      `util/build-exe-arm64.bat` sharing `util/_build-windows-installer.bat`;
      verify `util\build-exe-x64.bat` builds
      `bin/GitFileShardPlugin.x64.exe`, `util\build-exe-arm64.bat` aborts
      against the x64 payload, and `util\build-exe-x64.bat
      /DMyAppVersion=0.1.0` forwards the define

## 3. WiX MSI installer

- [x] 3.1 Default `Platform` to `x64` in the WiX project and set
      `OutputName` to `GitFileShardPlugin.$(Platform)`; verify
      `dotnet build ... -o <temp>` produces `GitFileShardPlugin.x64.msi` and
      the MSI `Template` is `x64;1033` with `ProgramFiles64Folder`
- [x] 3.2 Verify `dotnet build ... -p:Platform=arm64 -o <temp>` produces
      `GitFileShardPlugin.arm64.msi` with `Template=Arm64;1033`
- [x] 3.3 Split the wrapper into `util/build-msi-x64.bat` and
      `util/build-msi-arm64.bat` sharing `util/_build-windows-installer.bat`;
      verify `util\build-msi-x64.bat` builds
      `bin/en-US/GitFileShardPlugin.x64.msi` and
      `bin/ru-RU/GitFileShardPlugin.x64.msi`, `util\build-msi-arm64.bat`
      aborts against the x64 payload, and `util\build-msi-x64.bat -v:m`
      forwards the extra switch

## 4. CI

- [x] 4.1 Switch the Windows EXE and MSI jobs to
      `util\build-exe-x64.bat` and `util\build-msi-x64.bat` and upload
      `bin/GitFileShardPlugin.x64.exe` and
      `bin/{en-US,ru-RU}/GitFileShardPlugin.x64.msi`; verify the workflow
      YAML parses and every path matches the build output

## 5. Documentation and project instructions

- [x] 5.1 Update the Windows build section of `AGENTS.md` (architecture
      wrapper commands, payload verification, Inno/WiX architecture mapping,
      CI upload paths) and add the Windows batch wrapper conventions; verify
      the commands match the wrappers and the produced file names
- [x] 5.2 Update the `openspec/config.yaml` context (layout, verification
      commands, artifact names); verify it mentions the Windows wrappers and
      the `<arch>` output names

## 6. Verification

- [x] 6.1 Run `uv run --locked python -m compileall -q src` and
      `uv run --locked python -m py_compile git-file-shard.spec`; verify
      both succeed
- [x] 6.2 Build the payload (`uv run --locked pyinstaller
      git-file-shard.spec --noconfirm`) and both installers through the
      wrappers; verify `bin/GitFileShardPlugin.x64.exe`,
      `bin/en-US/GitFileShardPlugin.x64.msi` and
      `bin/ru-RU/GitFileShardPlugin.x64.msi` are produced
- [x] 6.3 Run `openspec validate --strict set-windows-installer-arch`;
      verify the change validates without errors
- [x] 6.4 Manual install/uninstall test on x64 Windows: install
      `bin/en-US/GitFileShardPlugin.x64.msi` and
      `bin/GitFileShardPlugin.x64.exe`, run `git file-shard --help`, then
      uninstall; verify the plugin lands in `C:\Program Files\ImeSense\Git
      File Shard Plugin\bin` (not `Program Files (x86)`) and PATH is
      restored

## Workflow follow-up

- Archive the change after the user has reviewed and verified the
  implementation.
