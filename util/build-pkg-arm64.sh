#!/bin/bash
# Convenience wrapper: builds the macOS pkg installer for arm64.
#
# Bundling the plugin (PyInstaller) is a separate step that must run
# beforehand and produce dist/git-file-shard. Every extra argument is
# forwarded to build.sh (e.g. --sign <identity>, --plain-name).
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

exec "$REPO_ROOT/src/ImeSense.GitFileShardPlugin.Setup.Pkg/build.sh" \
    --version "$VERSION" \
    --arch arm64 \
    "$@"
