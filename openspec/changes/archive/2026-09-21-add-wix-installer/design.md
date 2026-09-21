# Design: add-wix-installer

## Context

The Inno Setup installer (`innosetup-installer` capability) covers the EXE
distribution. This change adds a parallel MSI distribution built with
WiX Toolset 7 (`WixToolset.Sdk/7.0.0`, `WixToolset.UI.wixext/7.0.0`),
packaging the same PyInstaller payload `dist/git-file-shard.exe`.

## Goals / Non-Goals

- Goals: MSI package built from the solution; optional, reversible PATH
  registration driven by the MSI Environment table; bilingual UI; custom
  options dialog in the `WixUI_InstallDir` sequence.
- Non-Goals: replacing the Inno Setup EXE installer; silent-mode custom
  UI; per-user vs per-machine scope dialog (MSI defaults apply).

## Decisions

### D1. WiX v4+ authoring style

The project uses WiX v4/v7 schema (`http://wixtoolset.org/schemas/v4/wxs`)
with a `Package` element instead of the legacy `Product`, `MediaTemplate
EmbedCab="yes"` for a single-file MSI, and `MajorUpgrade` for version
upgrade handling. The UI set is referenced via
`<ui:WixUI Id="WixUI_InstallDir" InstallDirectory="INSTALLFOLDER" />`.

### D2. PATH via the MSI Environment table

Unlike Inno Setup (which needs hand-written `[Code]` registry logic), MSI
has a native `Environment` table. A dedicated component with
`Condition="ADDTOPATH"` wraps the `<Environment>` element:

```xml
<Component Id="AddToPath" Directory="INSTALLBIN"
           Guid="F1CAFAE6-4997-4D72-A17B-9B5E8A45ADA3"
           Condition="ADDTOPATH">
    <CreateFolder />
    <Environment Id="PathEntry" Name="PATH" Value="[INSTALLBIN]"
                 Part="last" Action="set" System="yes" />
</Component>
```

MSI itself appends the entry on install and removes it on uninstall
(`Action="set"` + `Part="last"`), so idempotency and cleanup come for free.
`System="yes"` targets the machine PATH; the `ADDTOPATH` property is
`Secure="yes"` so the value survives elevation.

### D3. Custom dialog insertion into WixUI_InstallDir

The built-in `WixUI_InstallDir` (from
`src/ext/UI/wixlib/WixUI_InstallDir.wxs` in the WiX sources) already
publishes an **unconditional** `NewDialog → VerifyReadyDlg` with
`Order="4"` on `InstallDirDlg/Next`, and `NewDialog → InstallDirDlg` with
`Order="1"` on `VerifyReadyDlg/Back`.

MSI executes all ControlEvents of a button in ascending `Order`, and when
several `NewDialog` events fire, the **last one wins**. Therefore:

- `InstallDirDlg/Next → OptionsDlg` must use `Order="5"` (after the
  built-in `Order="4"`), otherwise the built-in transition to
  `VerifyReadyDlg` silently overrides it and the custom dialog never
  appears — the exact bug observed during development;
- `VerifyReadyDlg/Back → OptionsDlg` must use `Order="2"` (after the
  built-in `Order="1"`).

The `Installed` (maintenance) branch needs no custom publishes: the
built-in transitions already route it correctly.

### D4. Checkbox bound to a public property

The `OptionsDlg` checkbox binds directly to the `ADDTOPATH` property
(`Property="ADDTOPATH" CheckBoxValue="1"`), initialized to `1` in
`Package.wxs` so the option is checked by default. No custom actions are
needed: the component condition is evaluated at install time.

### D5. Localization

Two `.wxl` files (`Package.en-us.wxl`, `Package.ru-ru.wxl`) carry all
user-visible strings, including the options dialog title/description and
the PATH task text. The Russian file sets `Codepage="1251"`.

## Risks / Trade-offs

- `Scope="perMachineOrUser"` relies on MSI default elevation behavior; no
  explicit scope dialog is offered (unlike Inno's command-line override).
- The `AddToPath` component carries an explicit `Guid` because its
  conditional installation must stay stable across upgrades.
- The dialog-order pitfall (D3) is invisible at compile time — WiX happily
  builds a package whose custom dialog can never open. Documented in
  `context.toon` to avoid regressions.
