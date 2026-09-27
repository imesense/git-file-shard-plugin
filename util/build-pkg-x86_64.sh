#!/bin/bash
# Convenience wrapper: builds the macOS pkg installer for x86_64.
#
# Activates the repository virtual environment (.venv) when present, so the
# wrapper can be called directly, and forwards every extra argument to
# build.sh (e.g. --sign <identity>, --skip-payload).
#
# Cross-building the x86_64 payload requires a Python interpreter that
# supports that architecture (a universal2 build); otherwise the build fails
# with a clear payload architecture error.
#
# Usage:
#     build-pkg-x86_64.sh <version> [extra build.sh arguments...]

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
    --arch x86_64 \
    "$@"
