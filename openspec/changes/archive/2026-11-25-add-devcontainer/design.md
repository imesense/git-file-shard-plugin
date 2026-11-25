# Design

## Context

See `proposal.md` for motivation. The plugin is a pure Python package whose
toolchain is already pinned by `.python-version` (3.10), `pyproject.toml`
(`requires-python = ">=3.8"`, `required-version = ">=0.13"`) and `uv.lock`.
A Dev Container only has to reproduce that toolchain; it does not have to
package the plugin or its native installers.

The sibling `mcforge1.12.2-modification-boilerplate` repository already
defines the layout this repository should follow: a `.devcontainer/`
directory with `devcontainer.json`, a `Dockerfile`, a base Compose file and
a build overlay, an `.env.example` with the registry, tag and volume paths,
a local image export script in `util/`, and a CI workflow that builds and
publishes the image.

## Goals / Non-Goals

**Goals:**

- One image that can build, byte-compile and verify the Python package with
  the same commands the README documents.
- Host-independent caches: rebuilding or switching the checkout does not
  force a full dependency download, and the bind-mounted workspace stays
  free of Linux virtual environments.
- Same Compose split as the sibling repository: a base file for running the
  container and a build overlay for building the image.
- Deterministic image tags: `latest`, a commit timestamp and the version
  passed to the local build helper.

**Non-Goals:**

- Building the DEB, PKG, DMG, EXE or MSI installers inside the container.
  PyInstaller does not cross-compile and `dpkg-deb`, `pkgbuild`/`hdiutil`
  and Inno Setup/WiX are platform-specific, so those builds stay on the
  matching host or CI runner. The container builds the Linux payload with
  PyInstaller, which is a plain `uv run` step and needs no extra tooling.
- Docker-in-Docker or a mounted Docker socket. The container is a Python
  build environment, not a container build host.
- Signing, notarization or registry authentication inside the container.
- GPU, GUI or X11 support.

## Decisions

### `mcr.microsoft.com/devcontainers/python:1-3.10-bookworm` as the base

The base image already provides Python 3.10, Git, `sudo`, a `vscode` user
and the Dev Containers plumbing, so the Dockerfile stays small. The tag is
parameterized (`ARG PYTHON_VERSION="1-3.10"`, `ARG DEBIAN_VARIANT="bookworm"`)
the same way the sibling repository parameterizes its Java base.

`bookworm` (Debian 12) is the current stable variant of the image and is
newer than the `bullseye` used by the Java boilerplate, which is
irrelevant here because the plugin has no glibc-sensitive native
dependencies beyond the PyInstaller runtime.

### Dedicated unprivileged user with passwordless `sudo`

The image follows the sibling repository and creates its own user
(`ARG USERNAME=shard`, uid/gid 1001) instead of reusing the image's `vscode`
user. A dedicated uid keeps the container identity stable if the base image
changes its default user, and 1001 avoids the uid 1000 that the base image
already assigns. `sudo` is needed for occasional `apt-get` installs while
developing; it is not used by the build itself.

The workspace is `/src` and `WORKDIR` is `/src`, matching the sibling
repository and the `workspaceFolder` in `devcontainer.json`.

### `uv` copied from the official image instead of installed by a script

`uv` is copied from `ghcr.io/astral-sh/uv:${UV_VERSION}` with
`COPY --from`, so the image gets the official static binary without
downloading an install script at build time and without a Python-level
bootstrap. The `uv` image is declared as a named build stage because
BuildKit does not expand build arguments in `COPY --from`. `UV_VERSION`
defaults to `0.13`, the line that
`pyproject.toml` requires and that CI already uses
(`astral-sh/setup-uv` with `version: "0.13.x"`), so local and CI
environments agree.

Alternatives considered: `pip install uv` (needs a second resolution path
and lags behind the standalone releases), the community Dev Container
feature `ghcr.io/devcontainer-community/devcontainer-features/astral.sh-uv`
(no official Astral feature exists, so a third-party feature would own the
version), and `curl | sh` in a `RUN` step (unpinned and unreproducible).

### Virtual environment and cache outside the workspace

`UV_CACHE_DIR=/uv` is a named bind mount from the host (`../.uv` by
default), mirroring the `GRADLE_USER_HOME=/gradle` volume of the sibling
repository. `UV_PROJECT_ENVIRONMENT=/opt/venv` keeps the virtual
environment out of the bind-mounted workspace: a Linux `venv` created in a
Windows or macOS checkout is unusable on the host and slows down the bind
mount with thousands of small files.

`UV_LINK_MODE=copy` is set explicitly because hard links do not work
reliably across bind mounts on Windows and macOS; without it `uv` warns on
every sync.

`postCreateCommand` runs `uv sync --locked`, so the first container start
produces the environment and later starts reuse the cache. Failing the
command on a stale lock file is intended: `uv.lock` is the source of truth.

### Compose split and environment file

`docker-compose.yaml` holds the runtime definition (image name, user,
working directory, volumes, network, keep-alive command) and
`docker-compose.build.yaml` adds the `build` section with the context and
build arguments. This is the same split as the sibling repository: the
runtime file can reference a published image without a local checkout of the
build inputs, and the build overlay is only used when building.

`.env.example` documents `IMAGE_REGISTRY`, `IMAGE_TAG`, `VOLUME_SOURCES`
and `VOLUME_UV`; all of them have defaults in the Compose file, so the
container runs without a `.env` file.

`shutdownAction: stopCompose` stops the container when the window closes,
and the service runs `tail -f /dev/null` to stay alive, which is the
standard pattern for Compose-based Dev Containers.

### Image tags and publishing

The local helper `util/build-devcontainer-image.bat` builds the image with
both Compose files, tags it with `latest`, the commit timestamp and the
version argument, and exports the tagged images to
`out/<version>/git-file-shard-plugin-devcontainer-<version>-devcontainer-image.tar`.
The timestamp is the commit timestamp (`git show -s --pretty=format:%ct`),
so the tag is identical to the one the CI workflow computes without
timezone-dependent date parsing.

The CI workflow follows `build-devcontainers.yml` of the sibling
repository: build on `ubuntu-24.04` with Buildx, save the image to a tar
artifact, then push `latest` and the timestamp tag to
`ghcr.io/<repository>-devcontainer`. The workflow triggers on
`.devcontainer/**`, `.dockerignore`, the workflow itself, and the Python
toolchain files (`pyproject.toml`, `uv.lock`, `.python-version`) that the
image installs.

### `.dockerignore` scope

The build context is the repository root because the Dockerfile is in
`.devcontainer/` and the context is `..`. `.dockerignore` excludes Git
metadata, CI and editor settings, build outputs (`bin/`, `build/`, `dist/`,
`obj/`), Python caches and virtual environments, local skills and
environment files. The image needs no repository files at all, so a tight
ignore list keeps the context small and prevents secrets or local state
from entering the image.

### Documentation and workspace recommendations

`README.md` and `README.rus.md` gain the "Open in Dev Containers" badge and
a short section on opening the checkout in the container. The
`GitFileShardPlugin.code-workspace` recommends the Docker and Dev Containers
extensions, matching the sibling repository.

## Risks / Trade-offs

- **Base image tag drift** → the image tag is a major-version tag
  (`1-3.10`), which can pick up base image updates; the Python minor
  version stays pinned by the tag and by `.python-version`.
- **`uv` image tag drift** → `UV_VERSION` is a minor-version tag (`0.13`);
  a patch update is accepted, a breaking change is avoided by the
  `required-version = ">=0.13"` constraint in `pyproject.toml`.
- **Bind-mounted `uv` cache from another OS** → the cache directory is
  shared across rebuilds; if it is ever corrupted, deleting the host `.uv`
  directory restores a clean state without affecting the repository.
- **`postCreateCommand` fails on a stale lock file** → this is the desired
  behavior, but it means a contributor who edits `pyproject.toml` must run
  `uv lock` on the host or in the container before the next start.
- **Container builds only the Linux payload** → a contributor on Windows or
  macOS who needs the Windows or macOS binary still builds it on that OS;
  the container is not a cross-compilation environment.
- **Publishing to GHCR needs package permissions** → the workflow requests
  `packages: write` and uses `GITHUB_TOKEN`; a fork without package
  permissions fails at the push step, while the build step still validates
  the Dockerfile.

## Migration Plan

This is a new development environment; no existing behavior changes. If the
change must be rolled back, remove `.devcontainer/`, `.dockerignore`,
`util/build-devcontainer-image.bat` and the workflow, and revert the
documentation and workspace edits. No build artifact depends on them.

## Open Questions

None.
