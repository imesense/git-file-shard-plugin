# Change: Add Debian package installer for Linux

## Why

The plugin already ships Windows (Inno Setup EXE, WiX MSI) and macOS
(PKG, DMG) installers, but Linux users must copy the PyInstaller binary
into a directory on `PATH` by hand. A native Debian package gives
Debian/Ubuntu users a managed install and removal path
(`apt install` / `apt remove`) that matches the other platforms.

## What Changes

- Add a Linux installer project `src/installer_linux_deb/` whose
  `build.sh` stages the prebuilt `dist/git-file-shard` binary and builds
  `bin/git-file-shard_<version>_<arch>.deb` with the stock `dpkg-deb`
  tool.
- Embed a distribution identifier in the output name
  (`git-file-shard_<version>_<distro>_<arch>.deb`, for example
  `git-file-shard_0.1.0_ubuntu22.04_amd64.deb`): detected from
  `/etc/os-release` by default and overridable with `--distro <id>`.
- Install the binary into a vendor directory as
  `/opt/imesense/git-file-shard-plugin/bin/git-file-shard` and expose it
  on `PATH` through a `/usr/local/bin/git-file-shard` symlink, so
  `git file-shard` resolves without editing shell profiles.
- Ship `README.md` and `LICENSE.txt` in the vendor documentation
  directory `/opt/imesense/git-file-shard-plugin/share/doc/`.
- Generate the `DEBIAN/control` metadata: package name
  `git-file-shard`, the requested version, Debian architecture
  (`amd64` or `arm64`), section `vcs`, `Depends: git`, homepage and a
  computed `Installed-Size`.
- Require `--version` and `--arch amd64|arm64` (no defaults) and verify
  the payload ELF architecture before packaging, mirroring the macOS PKG
  build.
- Add convenience wrappers `util/build-deb-amd64.sh` and
  `util/build-deb-arm64.sh`.
- Add a CI job that builds the amd64 package on `ubuntu-24.04` and
  uploads it as an artifact.
- Document the package installation in `doc/integration-guide.md` and
  record the Linux build rules in `AGENTS.md` and the OpenSpec project
  context.

## Capabilities

### New Capabilities

- `deb-installer`: Debian package for the git-file-shard plugin built
  with `dpkg-deb`, including payload layout, control metadata,
  architecture handling, build script and output artifact.

### Modified Capabilities

None.

## Impact

- Affected code: `src/installer_linux_deb/` (new), `util/` (new
  wrappers), `.github/workflows/build-application.yml`,
  `doc/integration-guide.md`, `AGENTS.md`, `openspec/config.yaml`.
- Affected specs: `deb-installer` (new capability).
- Installed paths: `/opt/imesense/git-file-shard-plugin/` and the
  `/usr/local/bin/git-file-shard` symlink. This is a deliberate
  deviation from Debian's `/usr/lib` + `/usr/bin` convention, kept for
  parity with the other platforms.
- Dependencies: the build host needs `dpkg-deb` and `readelf`; no new
  Python dependencies.
- The package bundles Python through PyInstaller, so no Python runtime
  dependency is added; `git` becomes the only declared runtime
  dependency.
