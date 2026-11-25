# Change: Add a Python development container

## Why

Contributors must install Python 3.10, `uv` and the PyInstaller toolchain on
the host before they can build or verify the plugin, and the exact versions
are only pinned by `.python-version`, `pyproject.toml` and `uv.lock`. A
Dev Container reproduces that environment in one reproducible image, the same
way the sibling ImeSense repositories (for example
`mcforge1.12.2-modification-boilerplate`) already do, so a checkout can be
opened in a container and built without touching the host Python.

## What Changes

- Add a `.devcontainer/` definition that builds a Python 3.10 development
  image from `mcr.microsoft.com/devcontainers/python` with `uv` preinstalled,
  a dedicated non-root user, and separate cache volumes for `uv`.
- Add `.devcontainer/devcontainer.json` (Compose-based), `Dockerfile`,
  `docker-compose.yaml`, `docker-compose.build.yaml` and `.env.example`,
  following the layout of the sibling boilerplate repository.
- Add `.dockerignore` so the build context does not carry Git, build
  artifacts, caches or secrets.
- Add `util/build-devcontainer-image.bat` to build, tag and export the image
  locally, and a `.github/workflows/build-devcontainers.yml` workflow that
  builds and publishes the image to GHCR.
- Document the container in `README.md`/`README.rus.md` and recommend the
  container extensions in `GitFileShardPlugin.code-workspace`.
- Update `AGENTS.md`, `.gitignore` and the OpenSpec project context.

The container is a development environment for the Python package only: it
SHALL NOT be expected to build the native installers. Building the DEB, PKG,
DMG, EXE and MSI artifacts stays on the matching host OS or CI runner,
because PyInstaller does not cross-compile and the packaging tools are
platform-specific.

## Capabilities

### New Capabilities

- `devcontainer`: reproducible Python development environment (base image,
  user, `uv` toolchain, caches, workspace mount, image build and publishing,
  and the explicit non-goal of native installer builds).

### Modified Capabilities

None.

## Impact

- Affected code: `.devcontainer/` (new), `.dockerignore` (new),
  `util/build-devcontainer-image.bat` (new),
  `.github/workflows/build-devcontainers.yml` (new), `README.md`,
  `README.rus.md`, `GitFileShardPlugin.code-workspace`, `.gitignore`,
  `AGENTS.md`, `openspec/config.yaml`.
- Affected specs: `devcontainer` (new capability).
- Dependencies: the build host needs Docker with Buildx and Docker Compose;
  no new Python dependencies.
- The image pins the Python version to the `.python-version` value (3.10)
  and `uv` to the 0.13 line required by `pyproject.toml`.
