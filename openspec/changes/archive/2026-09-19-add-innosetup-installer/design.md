# Design: add-innosetup-installer

## Context

History of the capability (commits on `default`):

- `3a20e98` — Add Inno Setup 7 installer project for Windows: base `Setup.iss`
  (identity, `{autopf}` dir, x64 flags, license page, `[Icons]` shortcut,
  `{app}` root payload).
- `b881a55` — Disable creating Start menu shortcut: `[Icons]` section removed;
  payload moved to `{app}\bin` (icon path fix followed in `6909e5b`).
- `6909e5b` — Implement add to PATH option in EXE installer: `[Tasks]` +
  `[Code]` section, locales, `UninstallDisplayIcon` → `{app}\bin`.

## Goals / Non-Goals

- Goals: one-click install of the plugin binary; optional, reversible PATH
  registration; bilingual task UI; reproducible local build.
- Non-Goals: silent-mode custom UI.

## Decisions

### D1. Inno Setup 7 as the installer toolchain

Inno Setup gives scriptable Pascal `[Code]`, simple tasks UI, and bilingual
custom messages with minimal boilerplate.

### D2. Direct `SendMessageTimeoutW` import

The Inno script engine does not register `SendMessageTimeout`, and
`SendNotifyMessage` is unsafe for `WM_SETTINGCHANGE` broadcasts: the engine
frees the `lParam` string before receivers may read it (comment in Inno
Setup's own `Setup.InstFunc.pas`, based on KB 104011). The function is
imported directly:

```pascal
external 'SendMessageTimeoutW@user32.dll stdcall';
```

with `HWND_BROADCAST`, `WM_SETTINGCHANGE = $001A`,
`SMTO_ABORTIFHUNG = $0002`, 5 s timeout.

### D3. `HKA` root + `REG_EXPAND_SZ` write

Reading via `RegQueryStringValue` under `HKA` respects
`PrivilegesRequiredOverridesAllowed=commandline` (HKLM when elevated, HKCU
otherwise) and reads both `REG_SZ` and `REG_EXPAND_SZ`. Writing via
`RegWriteExpandStringValue` keeps `%SystemRoot%`-style entries functional.

### D4. Idempotent PATH update

`StringToPathEntries` splits on `;` (`stExcludeEmpty`), drops any entry equal
to `{app}\bin` (case-insensitive `SameText`, `AddBackslash` normalization),
then `UpdatePath` re-adds it exactly once and writes only if the joined value
differs. This makes install/reinstall/uninstall cycles safe and order-
preserving for foreign entries.

### D5. Task enabled by default

The `addtopath` task ships without `Flags: unchecked`: the primary install
scenario ("use the plugin from anywhere") is the default; unchecking one box
opts out.

## Risks / Trade-offs

- Editing the machine-wide `Path` is intrusive; mitigated by opt-out task,
  idempotency and clean uninstall removal.
- `{ }` Pascal comments cannot contain Inno constants (`{app}` breaks the
  comment) — doc-comments avoid constants.
- `ISCC --output=no` still deletes a stale output file; rebuild after
  compile-only checks.
