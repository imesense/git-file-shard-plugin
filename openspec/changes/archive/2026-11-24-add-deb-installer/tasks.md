# Tasks: add-deb-installer

## 1. Debian package build script

- [x] 1.1 Create `src/installer_linux_deb/build.sh` with `--version`,
      `--arch` and `--help` argument parsing, the usage line and
      `Error:`-prefixed failures; verify `bash -n
      src/installer_linux_deb/build.sh` passes and running it without
      arguments prints the usage line and exits non-zero
- [x] 1.2 Add the host and tool checks (Linux, `dpkg-deb`, `readelf`) and
      the payload preconditions (`dist/git-file-shard`, `README.md`,
      `LICENSE.txt`); verify each missing precondition fails with an
      actionable error
- [x] 1.3 Add version validation (starts with a digit, no whitespace) and
      ELF architecture verification (`X86-64` -> `amd64`, `AArch64` ->
      `arm64`); verify a mismatched `--arch` and an invalid `--version`
      both abort without producing a package
- [x] 1.4 Stage `/opt/imesense/git-file-shard-plugin/bin/git-file-shard`,
      `README.md` and `LICENSE.txt` under
      `/opt/imesense/git-file-shard-plugin/share/doc/`, and the
      absolute `/usr/local/bin/git-file-shard` symlink, then generate
      `DEBIAN/control` with the metadata from `design.md`, including
      `Installed-Size`; verify the staged tree with `find
      build/deb/root` and the generated control file
- [x] 1.5 Run `dpkg-deb --root-owner-group -Zxz --build` and write
      `bin/git-file-shard_<version>_<arch>.deb`; verify the build
      produces the file and `dpkg-deb --info`/`--contents` show the
      expected metadata and the
      `opt/imesense/git-file-shard-plugin/` and
      `usr/local/bin/git-file-shard` paths

## 2. Convenience wrappers

- [x] 2.1 Add `util/build-deb-amd64.sh` and `util/build-deb-arm64.sh`
      (version as the first argument, matching `--arch`, extra arguments
      forwarded); verify `bash -n` passes for both and
      `util/build-deb-amd64.sh 0.1.0` produces
      `bin/git-file-shard_0.1.0_amd64.deb` on an amd64 host

## 3. Documentation and project instructions

- [x] 3.1 Add a "Debian package" installation section to
      `doc/integration-guide.md` (install, verify, remove); verify the
      documented commands match the produced artifact name and run as
      written
- [x] 3.2 Record the new installer in `AGENTS.md` (repository layout,
      build commands, Linux shell-script rules) and in the
      `openspec/config.yaml` context (layout, verification, capability
      list); verify both files mention `src/installer_linux_deb/` and
      `deb-installer`

## 4. CI

- [x] 4.1 Add a `pack-linux-installer-deb` job to
      `.github/workflows/build-application.yml` that runs
      `util/build-deb-amd64.sh ${{ env.PLUGIN_VERSION }}` on
      `ubuntu-24.04` and uploads
      `bin/git-file-shard_${{ env.PLUGIN_VERSION }}_amd64.deb`; verify a
      workflow run uploads the artifact and the path matches the build
      output

## 5. Verification

- [x] 5.1 Run `bash -n` on every new or modified shell script; verify
      all exit successfully
- [x] 5.2 Build the payload (`uv run --locked pyinstaller
      git-file-shard.spec --noconfirm`) and the package
      (`util/build-deb-amd64.sh 0.1.0`); verify `dpkg-deb --info` reports
      `Package: git-file-shard`, `Version: 0.1.0`, `Architecture:
      amd64`, `Depends: git`, and `dpkg-deb --contents` lists
      `opt/imesense/git-file-shard-plugin/bin/git-file-shard`,
      `opt/imesense/git-file-shard-plugin/share/doc/README.md`,
      `opt/imesense/git-file-shard-plugin/share/doc/LICENSE.txt` and the
      `usr/local/bin/git-file-shard` symlink
- [x] 5.3 Manual install/removal test (user, root): `dpkg -i
      bin/git-file-shard_0.1.0_amd64.deb`, `git file-shard --help`,
      `apt remove git-file-shard`; verify the command resolves and
      `/opt/imesense/git-file-shard-plugin` and
      `/usr/local/bin/git-file-shard` are gone afterwards
- [x] 5.4 Run `openspec validate --strict add-deb-installer`; verify the
      change validates without errors

## 6. Distribution identifier

- [x] 6.1 Add `--distro <id>` to `build.sh` (auto-detect `ID` +
      `VERSION_ID` from `/etc/os-release` when omitted, empty value drops
      the segment, charset validation) and use the identifier in the
      output name; verify `bash -n` passes, a build with `--distro
      ubuntu22.04` produces
      `bin/git-file-shard_0.1.0_ubuntu22.04_amd64.deb`, and an invalid
      value such as `--distro 'Ubuntu 22.04'` aborts without a package
- [x] 6.2 Rename the `doc/integration-guide.md` section to "Install as
      Deb package" and document `--distro`; verify the section title and
      the artifact names in the examples match the build output
- [x] 6.3 Update the DEB rules in `AGENTS.md` and the CI job to pass
      `--distro ubuntu24.04` and upload
      `bin/git-file-shard_${{ env.PLUGIN_VERSION }}_ubuntu24.04_amd64.deb`;
      verify the workflow YAML parses and the upload path matches the
      build output name
- [x] 6.4 Verify the identifier end to end: build with and without
      `--distro`, check `dpkg-deb -f` still reports the plain version,
      and run `openspec validate --strict add-deb-installer`

## Workflow follow-up

- Archive the change after the user has reviewed and verified the
  implementation.
