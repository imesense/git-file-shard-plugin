#!/bin/bash
# Convenience wrapper: builds the Debian package for amd64.
#
# Bundling the plugin (PyInstaller) is a separate step that must run
# beforehand and produce dist/git-file-shard. Every extra argument is
# forwarded to build.sh.
#
# Usage:
#     build-deb-amd64.sh <version> [extra build.sh arguments...]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <version> [extra build.sh arguments...]" >&2
    exit 1
fi

VERSION="$1"
shift

exec "$REPO_ROOT/src/installer_linux_deb/build.sh" \
    --version "$VERSION" \
    --arch amd64 \
    "$@"
