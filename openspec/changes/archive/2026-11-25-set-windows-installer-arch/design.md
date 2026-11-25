# Design

## Context

See `proposal.md` for motivation. The Windows installers package a
prebuilt PyInstaller payload (`dist/git-file-shard.exe`) that is produced on
the build host: PyInstaller does not cross-compile, and `target_arch` in
`git-file-shard.spec` only affects macOS. The payload architecture is
therefore a property of the artifact, not of the build command.

Before this change:

- `Setup.iss` hard-coded `ArchitecturesAllowed=x64compatible` and
  `ArchitecturesInstallIn64BitMode=x64compatible`, which describe the
  *target* Windows version, not the payload. An arm64 payload produced an
  x64-targeted setup that would install into a 64-bit Program Files on x64
  Windows.
- The WiX project did not set `Platform`, so
  `ImeSense.WixToolset.Sdk` mapped the empty/`AnyCPU` platform to `x86`.
  The resulting MSI had `Template=Intel;1033` and resolved
  `ProgramFiles6432Folder` to `ProgramFilesFolder`, installing an x64
  payload under `C:\Program Files (x86)`.

The macOS and Linux installers already require `--arch`, verify the payload
(`lipo`, `readelf`) and embed the architecture in the artifact name, so the
Windows path is brought in line with that pattern.

## Goals / Non-Goals

**Goals:**

- The installer architecture always matches the payload architecture, and a
  mismatch fails the build instead of producing a wrong package.
- The architecture is discoverable from the build output and from the
  artifact name.
- No silent default that contradicts the payload.

**Non-Goals:**

- Building an arm64 payload on an x64 host. PyInstaller cannot cross-compile,
  so arm64 installers require an arm64 Windows host with an arm64 Python.
- Producing x86 installers. The plugin ships only x64 and arm64 payloads.
- Signing, or changing install locations, registry keys or the PATH logic.

## Decisions

### The payload PE header is the source of truth

The wrappers read the `Machine` field of the PE header through
`util/detect-payload-arch.ps1` (`0x8664` -> `x64`, `0xAA64` -> `arm64`,
`0x014C` -> `x86`) instead of asking the Python interpreter. The interpreter
architecture equals the payload architecture only when the payload was built
in the same environment; a stale `dist/git-file-shard.exe` from an earlier
arm64 build would be misreported. The PE header describes the file that is
actually packaged.

PowerShell is used because reading a 16-bit field at a computed file offset
is not practical in `cmd`, and PowerShell ships with every supported
Windows version. The helper prints the architecture on stdout and fails with
a message on stderr for a missing or non-PE file.

### One wrapper per architecture instead of an `--arch` option

The PKG/DMG/DEB wrappers already follow a one-file-per-architecture
convention (`build-deb-amd64.sh`, `build-pkg-x86_64.sh`, ...). The Windows
wrappers mirror it (`build-exe-x64.bat`, `build-exe-arm64.bat`,
`build-msi-x64.bat`, `build-msi-arm64.bat`) so that a build command states
its architecture without extra arguments, tab-completion lists the supported
combinations, and a typo cannot silently change the target.

An `--arch x64|arm64` option was considered and rejected: it makes the
architecture a value that has to be parsed and validated, and the
architecture is already fixed by the payload, so the wrapper has nothing to
decide — only to verify.

Because the four wrappers differ only in the target (`exe`/`msi`) and the
architecture, the payload checks, tool discovery and argument forwarding live
in `util/_build-windows-installer.bat`; each wrapper is a two-line
`call`-forwarder with its own usage comment. The underscore marks the helper
as internal.

### The wrappers verify the payload and abort on a mismatch

The payload architecture is detected, not assumed, so a wrapper whose
architecture does not match fails fast instead of producing a package that
lies about its contents — for example when a developer builds on an x64 host
but names the arm64 wrapper. The error names both architectures and points
at the payload build step.

### Extras are forwarded from `%*`

Batch parameters (`%1`, `%2`, ...) split their argument on spaces, tabs,
commas, semicolons **and equals signs**, so a parser that rebuilds the
forwarded arguments from `%1` turns `/DMyAppVersion=1.2.3` into
`/DMyAppVersion 0.1.0` and `-p:Foo=Bar` into `-p:Foo Bar`. `%*` keeps the
original command tail verbatim but is not affected by `shift`.

The wrappers therefore pass `%*` through and the helper slices the two
leading tokens off `%*` with `for /f "tokens=1,2*"`, which keeps the
remaining text — including `=` — intact.

### Inno Setup: x64 setup stub, architecture-specific target

Inno Setup 7 has no Arm64 setup stub: `SetupArchitecture` accepts only `x86`
and `x64` (verified against Inno Setup 7.1, which rejects `arm64`). For an
x64 payload the script uses `SetupArchitecture=x64` with
`ArchitecturesAllowed`/`ArchitecturesInstallIn64BitMode` set to
`x64compatible`, which matches both x64 Windows and Arm64 Windows 11.

For an arm64 payload the script keeps `SetupArchitecture=x64` (the x64 stub
runs on Arm64 Windows 11 through emulation) and sets both target directives
to `arm64`, so the setup refuses to install on x64 Windows and installs in
64-bit mode on Arm64. Arm64 Windows 10 cannot run the x64 stub; this is
inherent to Inno Setup 7 and documented in the build notes.

The architecture is passed as the `/DArch` ISPP define, defaulting to `x64`
inside `Setup.iss` so a direct `ISCC.exe Setup.iss` invocation still works.
An unsupported value stops compilation through `#error`.

### WiX: `Platform` drives both the MSI platform and the output name

`ImeSense.WixToolset.Sdk` maps `Platform` to `InstallerPlatform`, which
becomes the MSI platform (verified: `x64` -> `Template=x64;1033` with
`ProgramFiles64Folder`, `arm64` -> `Template=Arm64;1033`). The project now
defaults `Platform` to `x64` when it is empty or `AnyCPU`, which removes the
silent x86 default, and derives `OutputName` from it so the artifact name
matches the platform.

`OutputName` is evaluated as a property before the SDK computes
`InstallerPlatform`, so `$(Platform)` is used rather than
`$(InstallerPlatform)`; the wrapper passes `-p:Platform=<arch>`, which
overrides the project default.

### Architecture suffix in the artifact names

`bin/GitFileShardPlugin.<arch>.exe` and
`bin/<culture>/GitFileShardPlugin.<arch>.msi` follow the existing
`GitFileShardPlugin.v<version>.<arch>.pkg` / `.dmg` and
`git-file-shard_<version>_<distro>_<arch>.deb` conventions, and stop builds
for different architectures from overwriting each other in `bin/`.

This is a breaking rename for anything that consumes the old paths (CI
upload steps, release notes, download links). The alternative — keeping the
plain names — was rejected because the artifacts are indistinguishable in a
release directory and `bin/` would only ever hold the last build.

### CI uses the wrappers

The CI jobs call `util\build-exe-x64.bat` and `util\build-msi-x64.bat`
instead of raw `ISCC.exe` / `dotnet build`, so the payload check and the
naming live in one place and CI fails if the payload architecture ever
differs from `x64`. The Inno job remains disabled (`if: false`) as before;
its commands are kept in sync.

## Risks / Trade-offs

- **Arm64 EXE installer needs the x64 emulation layer** → only Arm64
  Windows 11 is supported; Inno Setup 7 cannot emit an Arm64 stub. Recorded
  in the spec and build notes instead of being hidden behind
  `x64compatible`.
- **The rename breaks existing consumers** → CI, `AGENTS.md` and the specs
  are updated in the same change; the old files remain valid MSI/EXE
  packages if someone already has them.
- **`%*` slicing drops the two leading tokens** → the helper is only called
  by the four wrappers, which always pass exactly `<target> <arch>` first;
  forwarded extras keep their `=` intact.
- **Detecting the payload requires a real PE file** → a truncated or
  non-PE `dist/git-file-shard.exe` fails with a clear error instead of
  producing an installer, which is the desired behavior.
- **MSI default platform changes from x86 to x64** → intended fix; the
  shared `UpgradeCode` keeps upgrades working, and no x86 payload was ever
  shipped.

## Migration Plan

1. Rebuild the payload for the target architecture on a matching host.
2. Run `util\build-exe-<arch>.bat` / `util\build-msi-<arch>.bat`; the output
   name now includes the architecture.
3. Update any release script or documentation that referenced
   `bin/GitFileShardPlugin.exe`, `bin/en-US/GitFileShardPlugin.msi`,
   `util/build-exe.bat` or `util/build-msi.bat`.

Rollback: revert the `Setup.iss`, `.wixproj`, wrapper, CI and documentation
changes; the previous artifacts can still be built with a direct
`ISCC.exe Setup.iss` / `dotnet build` invocation.

## Open Questions

None.
