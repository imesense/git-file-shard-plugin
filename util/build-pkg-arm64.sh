#!/bin/bash
# Convenience wrapper: builds the macOS pkg installer for arm64.
#
# Activates the repository virtual environment (.venv) when present, so the
# wrapper can be called directly, and forwards every extra argument to
# build.sh (e.g. --sign <identity>, --skip-payload).
#
# Usage:
#     build-pkg-arm64.sh <version> [extra build.sh arguments...]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <version> [extra build.sh arguments...]" >&2
    exit 1
fi

VERSION="$1"
shift

if [ -f "$REPO_ROOT/.venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    . "$REPO_ROOT/.venv/bin/activate"
fi

exec "$REPO_ROOT/src/ImeSense.GitFileShardPlugin.Setup.Pkg/build.sh" \
    --version "$VERSION" \
    --arch arm64 \
    "$@"
