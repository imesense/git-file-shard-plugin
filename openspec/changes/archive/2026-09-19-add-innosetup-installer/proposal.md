# Change: Add Inno Setup installer with optional PATH integration

## Why

The plugin was distributed only as a bare `git-file-shard.exe` that users had
to place on `PATH` manually. A Windows installer makes distribution
user-friendly: one download, guided setup, optional automatic PATH
registration, and clean uninstall.

## What Changes

- Add an Inno Setup 7 project (`Setup.iss`) that packages
  `dist/git-file-shard.exe` with `README.md` and `LICENSE.txt` into
  `bin/GitFileShardPlugin.exe`.
- Install the binary into `{app}\bin` without Start menu shortcuts.
- Add an `addtopath` task (checked by default) that appends `{app}\bin` to
  the `Path` environment variable on install and removes it on uninstall,
  with a `WM_SETTINGCHANGE` broadcast so running applications pick up the
  change immediately.
- Provide English and Russian custom messages for the task UI.
- Fix the uninstall display icon to point at the new `{app}\bin` location.

## Impact

- Affected specs: `innosetup-installer` (new capability)
- Affected code: `src/ImeSense.GitFileShardPlugin.Setup.Inno/` (new)
