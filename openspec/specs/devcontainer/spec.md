# devcontainer Specification

## Purpose

Reproducible Python development environment for the git-file-shard plugin,
delivered as a Dev Container image so a checkout can be built and verified
without installing Python or `uv` on the host.

## Requirements

### Requirement: Development Toolchain

The development container SHALL provide Python 3.10, `uv` from the 0.13
line and Git, so the documented build and verification commands run
unchanged inside the container.

#### Scenario: Tool versions inside the container

- **WHEN** a shell is opened in the running container
- **THEN** `python --version` reports Python 3.10
- **AND** `uv --version` reports a 0.13 release
- **AND** `git --version` succeeds

#### Scenario: Locked environment restore

- **WHEN** `uv sync --locked` runs in the container workspace
- **THEN** the command completes without errors
- **AND** `uv run --locked python -m compileall -q src` succeeds

### Requirement: Workspace and User

The container SHALL mount the repository at `/src` as the workspace folder
and SHALL run as a dedicated non-root user with passwordless `sudo`, so
files created in the workspace are owned by that user.

#### Scenario: Session identity

- **WHEN** a terminal is opened in the container
- **THEN** the working directory is `/src`
- **AND** the current user is the unprivileged development user, not `root`
- **AND** `sudo true` succeeds without a password prompt

### Requirement: Persistent Caches

The container SHALL keep the `uv` cache outside the workspace in a volume
that survives container rebuilds, and SHALL create the project virtual
environment outside the workspace, so a bind-mounted checkout is not
polluted with Linux-specific cache or environment files.

#### Scenario: Cache and environment location

- **WHEN** dependencies are installed in the container
- **THEN** the `uv` cache is written to the configured cache directory
- **AND** the project virtual environment is created outside `/src`
- **AND** no virtual environment directory is created in the bind-mounted
  workspace

### Requirement: Image Build

The container image SHALL be built from the Compose files in
`.devcontainer/`, which combine a base definition with a build overlay, and
SHALL be tagged in the project registry namespace with the `latest` tag.

#### Scenario: Local image build

- **WHEN** `docker compose --file .devcontainer/docker-compose.yaml --file
  .devcontainer/docker-compose.build.yaml build` is executed
- **THEN** the image builds successfully
- **AND** the resulting image is tagged
  `ghcr.io/imesense/git-file-shard-plugin-devcontainer:latest`

### Requirement: Image Export and Publishing

The repository SHALL provide a local image build helper that tags the image
with a commit timestamp and version and exports it as a tar archive, and a
CI workflow that builds the image and publishes it to the container
registry.

#### Scenario: Local image export

- **WHEN** `util/build-devcontainer-image.bat <version>` is executed on a
  host with Docker
- **THEN** the image is built and tagged with `latest`, the commit
  timestamp and `<version>`
- **AND** a tar archive of those tags is written under `out/<version>/`

#### Scenario: Registry publication

- **WHEN** the devcontainer workflow runs on a branch push
- **THEN** the image is pushed to the registry with the `latest` and
  commit-timestamp tags

### Requirement: Build Context Exclusions

The image build context SHALL exclude Git metadata, build artifacts,
caches, local editor settings, environment files and Python virtual
environments.

#### Scenario: Excluded paths

- **WHEN** the image is built
- **THEN** `.git/`, `bin/`, `build/`, `dist/`, `obj/`, `.venv/`, `.pip/`,
  `__pycache__/` and `*.env*` are not copied into the build context

### Requirement: Native Installers Out of Scope

The development container SHALL target the Python package only and SHALL
NOT be required to build the DEB, PKG, DMG, EXE or MSI installers, which
remain bound to their matching host operating system or CI runner.

#### Scenario: Installer builds stay on the host

- **WHEN** a contributor needs a native installer
- **THEN** the documented build commands run on the matching host OS or CI
  runner rather than inside the development container
- **AND** the container documentation does not promise installer output
