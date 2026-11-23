# Design

## Context

See `proposal.md` for motivation. The existing installers all follow the
same pattern: a `build.sh` in `src/installer_<platform>_<format>/` takes a
version and a target architecture, stages a prebuilt PyInstaller payload
from `dist/`, and writes the artifact to `bin/`. The macOS PKG build also
verifies the payload architecture before packaging. The Debian package
should reuse this pattern instead of introducing a second build system.

The Linux payload is `dist/git-file-shard` (no extension), produced by
the same `git-file-shard.spec` that builds the macOS payload.

## Goals / Non-Goals

**Goals:**

- Produce a standards-compliant `.deb` from the prebuilt binary with
  stock Debian tooling available on Ubuntu runners.
- Install and remove cleanly through `dpkg`/`apt`, with no manual `PATH`
  editing.
- Keep the build deterministic in naming and metadata, and consistent
  with the other installers' CLI.

**Non-Goals:**

- Publishing to a Debian repository or adding `apt` source configuration.
- Native Debian source packaging (`debian/` directory,
  `dpkg-buildpackage`, `debhelper`, source uploads).
- Building `arm64` packages in CI; PyInstaller does not cross-compile, so
  the package is built on a matching host.
- Code signing, package repositories, or distro-specific integration
  beyond Debian policy basics.

## Decisions

### Script-based `dpkg-deb` build instead of native `debian/` packaging

A staged tree plus `dpkg-deb --build` mirrors the PKG/DMG build scripts
and packages an already-built PyInstaller binary. Native source
packaging would add `debian/rules`, `changelog`, `compat` and debhelper
dependencies, and would rebuild the Python project rather than package
the standalone artifact. The script approach keeps the release artifact
identical to what PyInstaller produced.

### Vendor layout under `/opt` with a `/usr/local/bin` symlink

The payload lands in a single vendor directory:
`/opt/imesense/git-file-shard-plugin/bin/git-file-shard`, with `README.md`
and `LICENSE.txt` in the vendor documentation subdirectory
`/opt/imesense/git-file-shard-plugin/share/doc/`, and
`/usr/local/bin/git-file-shard` is an absolute symlink to the binary.
This mirrors the Windows (`{app}\bin`) and macOS
(`/Library/Application Support/ImeSense/Git File Shard Plugin/bin`)
installers, which keep everything under one application folder, and keeps
the distribution's own directories (`/usr/bin`, `/usr/lib`) free of a
private payload. The absolute target keeps the link valid regardless of
the caller's working directory and of `/usr/local/bin` being a symlink
itself (some distributions point it at `/usr/bin`).

Alternatives considered: `/usr/lib/git-file-shard` plus `/usr/bin`
(policy-clean, but scatters the payload and does not match the other
platforms), installing the binary directly into `/usr/local/bin` (mixes
the payload with administrator-managed files), and `/opt` without a
symlink (no `PATH` integration).

Documentation goes to the vendor `share/doc/` subdirectory instead of
`/usr/share/doc/git-file-shard/` so the documentation travels with the
application folder; the package therefore ships no `copyright` file under
the system-wide `/usr/share/doc`.

### Required `--version` and `--arch`, with ELF verification

Both arguments are mandatory and have no defaults, matching the macOS
scripts. `--arch` accepts only `amd64` and `arm64`. Before packaging the
build reads the ELF header (`readelf -h`) and maps `X86-64` to `amd64`
and `AArch64` to `arm64`; a mismatch aborts the build. This prevents a
package whose `Architecture` field lies about its contents, which would
break installation on the target host. `readelf` is part of binutils and
is present on Debian/Ubuntu build hosts; the script checks for it along
with `dpkg-deb`.

### Debian version validation

Debian versions must start with a digit. The build rejects empty values,
values not starting with a digit, and values containing whitespace, so
`dpkg-deb` cannot produce a package that `dpkg` later refuses.

### Distribution identifier in the output name

The output name carries the distribution after the version
(`git-file-shard_<version>_<distro>_<arch>.deb`), which is how distro
packages are told apart when one release is published for several
systems. The identifier is auto-detected from `/etc/os-release` by
concatenating `ID` and `VERSION_ID` (`ubuntu` + `20.04` ->
`ubuntu20.04`, `debian` + `12` -> `debian12`), because the PyInstaller
payload is bound to the build host's glibc, so the detected value
describes what the package actually runs on. `--distro <id>` overrides
the detection and an empty value drops the segment, which keeps the plain
`name_version_arch.deb` form available.

`/etc/os-release` is parsed with `awk` instead of being sourced, so an
unusual file cannot affect the script's own variables or fail under
`set -u`. The identifier is restricted to lowercase letters, digits,
`.`, `+`, `~` and `-`, and must start with a letter or digit, so it stays
a valid file-name segment. An invalid auto-detected value is dropped with
a warning; an invalid explicit value aborts the build, since it means the
caller passed something wrong.

The identifier affects only the file name: the `Version` field keeps the
plain `--version` value, so the package installs and compares the same
way regardless of which distribution build is used. Encoding the distro
in the version (`0.1.0~ubuntu20.04`) was considered and rejected as it
changes upgrade ordering semantics for no benefit here.

### Control metadata

- `Package: git-file-shard`
- `Version`: from `--version`
- `Architecture`: from `--arch`
- `Section: vcs`, `Priority: optional`
- `Depends: git`; no Python dependency because PyInstaller bundles the
  interpreter
- `Maintainer`: `acidicMercury8 <acidicmercury8@outlook.com>` (the
  repository author; Debian requires a name plus email)
- `Homepage: https://github.com/imesense/git-file-shard-plugin/`
- `Installed-Size`: computed from the staged tree with `du -k -s`
- `Description`: one-line summary plus an indented extended description

No `DEBIAN/postinst`, `prerm` or `postrm` scripts are needed: the symlink
and documentation are normal payload files, and `dpkg` removes them (and
the directories it created, once empty) on removal.

### Deterministic ownership and compression

The build uses `dpkg-deb --root-owner-group` so files are owned by
`root:root` even when the build runs as an unprivileged user, and
`-Zxz` for an explicit xz compression instead of relying on the host
default.

### CI scope

CI builds the `amd64` package on the existing `ubuntu-24.04` runner,
where PyInstaller runs natively. The job passes `--distro ubuntu24.04`
explicitly instead of relying on the runner's `/etc/os-release`, so the
artifact name is deterministic, and uploads
`bin/git-file-shard_<version>_ubuntu24.04_amd64.deb`. The `arm64` wrapper
exists for local or future arm64 runners but is not wired into CI in this
change.

## Risks / Trade-offs

- **`readelf` missing on a minimal build host** → the script checks for
  the tool up front and fails with an actionable error; binutils is a
  normal build dependency.
- **`--root-owner-group` requires dpkg 1.19+** → available on all
  supported Ubuntu runners (18.04 and newer); the script fails clearly
  if `dpkg-deb` rejects the option.
- **Payloads under `/opt` and files under `/usr/local` are discouraged by
  Debian policy** → accepted as a deliberate vendor layout requested for
  cross-platform parity. `dpkg` still owns both paths, so install and
  removal stay managed, and an existing regular file at
  `/usr/local/bin/git-file-shard` makes the installation refuse to
  overwrite it instead of silently replacing it. Expect lintian warnings
  (`dir-or-file-in-opt`, `dir-or-file-in-usr-local`,
  `no-copyright-file`); a policy-clean layout can be adopted later
  without changing the build logic.
- **`/opt/imesense` may already exist from another ImeSense package** →
  `dpkg` only removes the directories it created and only when they are
  empty, so a shared `/opt/imesense` is left in place.
- **Binary size in `/opt`** → PyInstaller one-file binaries are large,
  but this is the same artifact shipped on other platforms; xz
  compression keeps the `.deb` reasonable.
- **Package name collision with a future distro package** → the name
  matches the project and the Python distribution; if a distro package
  appears, a conflict can be declared later without changing the payload
  layout.
- **arm64 packages are not produced by CI** → users on arm64 must build
  on an arm64 host; this is inherent to PyInstaller and documented in
  the build instructions.

## Migration Plan

This is a new artifact; no existing behavior changes. If the change must
be rolled back, remove `src/installer_linux_deb/`, the two `util/`
wrappers, and the CI job; no installed system state depends on them.

## Open Questions

None.
