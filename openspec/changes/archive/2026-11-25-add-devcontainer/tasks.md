# Tasks: add-devcontainer

## 1. Container definition

- [x] 1.1 Add `.devcontainer/Dockerfile` based on
      `mcr.microsoft.com/devcontainers/python:1-3.10-bookworm` with the
      `shard` user (uid/gid 1001, passwordless `sudo`), `uv` copied from
      `ghcr.io/astral-sh/uv:0.13`, `UV_CACHE_DIR=/uv`,
      `UV_PROJECT_ENVIRONMENT=/opt/venv`, `UV_LINK_MODE=copy` and
      `WORKDIR /src`; verify `docker build --file .devcontainer/Dockerfile
      --build-arg ... .` succeeds and `uv --version` inside the image
      reports 0.13.x
- [x] 1.2 Add `.devcontainer/docker-compose.yaml` (image
      `ghcr.io/imesense/git-file-shard-plugin-devcontainer`, user `shard`,
      `/src` and `/uv` volumes, bridge network, `tail -f /dev/null`) and
      `.devcontainer/docker-compose.build.yaml` (build context `..`,
      Dockerfile and build arguments); verify `docker compose --file
      .devcontainer/docker-compose.yaml --file
      .devcontainer/docker-compose.build.yaml config` renders without
      errors
- [x] 1.3 Add `.devcontainer/devcontainer.json` (Compose files, service,
      `remoteUser: shard`, `workspaceFolder: /src`,
      `shutdownAction: stopCompose`, GitHub CLI feature,
      `postCreateCommand: uv sync --locked`, Python/Docker/YAML/Markdown
      extensions and settings) and `.devcontainer/.env.example`
      (`IMAGE_REGISTRY`, `IMAGE_TAG`, `VOLUME_SOURCES`, `VOLUME_UV`);
      verify the JSON parses and the documented defaults match the Compose
      file
- [x] 1.4 Add `.dockerignore` excluding Git metadata, CI and editor
      settings, `bin/`, `build/`, `dist/`, `obj/`, `.venv/`, `.pip/`,
      `__pycache__/`, `.agents/` and `*.env*`; verify `docker build` uses a
      context that does not contain those paths

## 2. Image build helper

- [x] 2.1 Add `util/build-devcontainer-image.bat` that builds the image
      from both Compose files, tags it with `latest`, the commit timestamp
      (`git show -s --pretty=format:%ct`) and the version argument, exports
      the tags to a tar archive and moves it under `out/<version>/`; verify
      the script prints the timestamp and writes the archive when run with
      a version argument

## 3. CI

- [x] 3.1 Add `.github/workflows/build-devcontainers.yml` that builds the
      image on `ubuntu-24.04` with Buildx, saves it as an artifact, and
      publishes `latest` plus the commit-timestamp tag to
      `ghcr.io/<repository>-devcontainer`; verify the workflow YAML parses
      and the image name matches the Compose file

## 4. Documentation and project instructions

- [x] 4.1 Add the "Open in Dev Containers" badge and a container
      development section to `README.md` and `README.rus.md`; verify the
      commands match the Compose files and the text does not promise
      native installer builds inside the container
- [x] 4.2 Recommend the Docker and Dev Containers extensions in
      `GitFileShardPlugin.code-workspace` and ignore `/out` and
      `.devcontainer/.env` in `.gitignore`; verify `git status` does not
      list the exported image archive or a local `.env`
- [x] 4.3 Record the container in `AGENTS.md` (layout, build command,
      Docker conventions) and in the `openspec/config.yaml` context
      (layout, capabilities, verification); verify both mention
      `.devcontainer/` and `devcontainer`

## 5. Verification

- [x] 5.1 Run `docker compose --file .devcontainer/docker-compose.yaml
      --file .devcontainer/docker-compose.build.yaml config` and
      `openspec validate --strict add-devcontainer`; verify both succeed
- [x] 5.2 Build the image and run `uv sync --locked`,
      `uv run --locked python -m compileall -q src` and
      `uv run --locked python -m py_compile git-file-shard.spec` inside
      the container; verify all commands succeed and `/src` contains no
      `.venv`
- [x] 5.3 Verify the container does not build native installers: confirm
      the image has no `dpkg-deb`, `pkgbuild`, `hdiutil`, `ISCC` or `dotnet`
      requirement and that the documentation points installer builds at the
      host OS or CI

## Workflow follow-up

- Archive the change after the user has reviewed and verified the
  implementation.
