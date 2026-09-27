#!/bin/bash
# Convenience wrapper: builds the macOS DMG installer for arm64.
#
# The PKG (bin/GitFileShardPlugin.pkg) is a precondition and must already
# exist; the DMG build never builds the PKG itself. Every extra argument
# is forwarded to build.sh.
#
# Usage:
#     build-dmg-arm64.sh <version> [extra build.sh arguments...]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <version> [extra build.sh arguments...]" >&2
    exit 1
fi

VERSION="$1"
shift

exec "$REPO_ROOT/src/ImeSense.GitFileShardPlugin.Setup.Dmg/build.sh" \
    --version "$VERSION" \
    --arch arm64 \
    "$@"
