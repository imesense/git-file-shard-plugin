# Git File Shard Plugin

[English](./README.md) | Русский

[![Language](https://img.shields.io/badge/Language-Python-blue.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE.txt)
[![Release](https://img.shields.io/github/v/release/imesense/git-file-shard-plugin?include_prereleases&label=Release)](https://github.com/imesense/git-file-shard-plugin/releases/latest)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/imesense/git-file-shard-plugin)
[![Build application](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-application.yml/badge.svg)](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-application.yml)
[![Build devcontainers](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-devcontainers.yml/badge.svg)](https://github.com/imesense/git-file-shard-plugin/actions/workflows/build-devcontainers.yml)

Git-плагин, который разбивает большие файлы на части и собирает их обратно, чтобы репозитории могли хранить крупные бинарные ресурсы, не сохраняя оригиналы в Git.

## Возможности

- Разбивает файлы больше настраиваемого порога (по умолчанию 50 МБ) на части.
- Отбирает файлы по пользовательскому атрибуту `file-shards=auto` в `.gitattributes`.
- Восстанавливает оригиналы из частей и проверяет их хеш.
- Повторно разбивает файл при изменении его хеша и предварительно удаляет устаревшие части.
- Управляет `.gitignore`, чтобы Git отслеживал только части.
- Поставляется с Git-хуками для автоматического разбиения и восстановления.

## Требования

Для сборки:

- __Python__ 3.10 (см. `.python-version`),
- __uv__.

Для разработки:

- __Visual Studio Code__ или любой другой редактор,
- __Docker__ и __Docker Compose__ (опционально, для Dev Container).

## Разработка в контейнере

Откройте репозиторий в __Visual Studio Code__ и выполните __Dev Containers: Reopen in Container__, или соберите образ напрямую:

```sh
docker compose \
    --file .devcontainer/docker-compose.yaml \
    --file .devcontainer/docker-compose.build.yaml \
    build
```

Контейнер предоставляет Python 3.10, `uv` и Git, устанавливает зафиксированные зависимости при первом запуске и хранит кеш `uv` и виртуальное окружение вне рабочей папки.
Это среда сборки Python-части: установщики DEB, PKG, DMG, EXE и MSI собираются на соответствующей хост-ОС или в CI.

## Сборка

- Восстановить зафиксированное окружение и собрать автономный бинарный файл:

  ```sh
  uv sync --locked
  uv run --locked pyinstaller git-file-shard.spec --noconfirm
  ```

Бинарный файл записывается в `dist/` (`git-file-shard.exe` в Windows, `git-file-shard` в macOS и Linux).
PyInstaller не выполняет кросс-компиляцию, поэтому собирайте на целевой ОС.

## Проверка

Тестового набора нет.
Проверьте исходники и скрипты сборки с помощью:

```sh
uv lock --check
uv run --locked python -m compileall -q src
uv run --locked python -m py_compile git-file-shard.spec
```

Установщики собираются из подготовленного бинарного файла на целевой ОС:

- Windows: `ISCC.exe src\installer_windows_inno\Setup.iss` и `dotnet build src\installer_windows_wix\GitFileShard.Installer.Wix.wixproj -c Release -o bin`.
- macOS: `./util/build-pkg-arm64.sh <version>` и `./util/build-dmg-arm64.sh <version>`.
- Linux: `./util/build-deb-amd64.sh <version>`.

## Установка

### Готовый бинарный файл

Скачайте архив для вашей платформы из релизов и поместите бинарный файл (`git-file-shard.exe` в Windows, `git-file-shard` в macOS и Linux) в каталог из `PATH`.
Git обнаружит его как подкоманду `git file-shard`.

Проверьте установку:

```sh
git file-shard --help
```

### Пакет Debian

```sh
sudo apt install ./git-file-shard_0.1.0_ubuntu22.04_amd64.deb
```

### Пакет Python

```sh
uv tool install .
```

## Использование

- Разбить подходящие файлы и добавить оригиналы в `.gitignore`:

  ```sh
  git file-shard scan
  ```

- Восстановить оригиналы из частей:

  ```sh
  git file-shard restore
  ```

- Разбить или собрать один файл:

  ```sh
  git file-shard split path/to/file.bin
  git file-shard merge path/to/file.bin
  ```

- Вычислить хеш файла:

  ```sh
  git file-shard hash path/to/file.bin
  ```

Смотрите [руководство по использованию](./doc/usage-guide.md) для всех команд и параметров.

## Интеграция

Установите хуки из `src/git_hooks/` в `.git/hooks/` и отметьте файлы для разбиения в `.gitattributes`:

```properties
*.cform file-shards=auto
```

Смотрите [руководство по интеграции](./doc/integration-guide.md) для деталей.

## Переменные окружения

| Переменная | Описание |
| --- | --- |
| `GIT_FILE_SHARD_TARGET_ARCH` | Целевая архитектура сборки macOS (`arm64` или `x86_64`). |

## Документация

- [Руководство по использованию](./doc/usage-guide.md)
- [Руководство по интеграции](./doc/integration-guide.md)
- [Модель ветвления](./doc/git-branching-model.rus.md)
- [Стиль кодирования](./doc/python-coding-style.rus.md)
- [Стиль фиксаций](./doc/git-commit-style.rus.md)

## Внесение вклада

Смотрите [руководство по внесению вклада](./CONTRIBUTING.rus.md) и [кодекс поведения](./CODE_OF_CONDUCT.rus.md).

## Лицензия

Содержимое данного репозитория лицензировано согласно условиям __лицензии MIT__, пока не указано иное.
Смотрите [этот](./LICENSE.txt) файл для деталей.
