#!/bin/bash
# Build script for the macOS DMG disk image of the git-file-shard plugin.
#
# Wraps the PKG installer (bin/GitFileShardPlugin.pkg) into a compressed
# UDZO disk image with the stock hdiutil tool. The volume carries the PKG
# only. The PKG is a precondition: it must already exist in bin/ with the
# plain name, regardless of how it was produced. Building the DMG never
# builds the PKG itself.
#
# Usage:
#     build.sh --version <version> --arch arm64|x86_64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PUBLISHER='ImeSense'
APP_NAME='Git File Shard Plugin'
VOLUME_NAME="$APP_NAME"

VERSION=''
ARCH=''

PKG_DIR="$REPO_ROOT/bin"
BUILD_DIR="$REPO_ROOT/build/dmg"
OUTPUT_DIR="$REPO_ROOT/bin"

usage() {
    echo "Usage: $0 --version <version> --arch arm64|x86_64"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --version)
            if [ "$#" -lt 2 ]; then
                echo 'Error: --version requires a value.' >&2
                usage >&2
                exit 1
            fi
            VERSION="$2"
            shift 2
            ;;
        --arch)
            if [ "$#" -lt 2 ]; then
                echo 'Error: --arch requires a value.' >&2
                usage >&2
                exit 1
            fi
            ARCH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'." >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo 'Error: --version is required.' >&2
    usage >&2
    exit 1
fi

if [ -z "$ARCH" ]; then
    echo 'Error: --arch is required.' >&2
    usage >&2
    exit 1
fi

if [ "$ARCH" != 'arm64' ] && [ "$ARCH" != 'x86_64' ]; then
    echo "Error: unsupported architecture '$ARCH' (expected arm64 or x86_64)." >&2
    exit 1
fi

if [ "$(uname -s)" != 'Darwin' ]; then
    echo 'Error: this script must be run on macOS.' >&2
    exit 1
fi

for tool in hdiutil; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: required tool '$tool' was not found." >&2
        exit 1
    fi
done

# The PKG is a precondition, like the plugin binary for the PKG build:
# it must already exist in bin/ with the plain name. Version and
# architecture live in the DMG file name and inside the PKG itself.
PLAIN_PKG="$PKG_DIR/GitFileShardPlugin.pkg"
if [ ! -f "$PLAIN_PKG" ]; then
    echo "Error: PKG '$PLAIN_PKG' was not found; build the PKG first." >&2
    exit 1
fi

# Stage the volume contents: the PKG only.
STAGE_DIR="$BUILD_DIR/volume"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp "$PLAIN_PKG" "$STAGE_DIR/GitFileShardPlugin.pkg"

PRODUCT_DMG="$OUTPUT_DIR/GitFileShardPlugin.v$VERSION.$ARCH.dmg"
rm -f "$PRODUCT_DMG"
hdiutil create \
    -format UDZO \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE_DIR" \
    "$PRODUCT_DMG" >/dev/null

hdiutil verify "$PRODUCT_DMG"

echo "Built $PRODUCT_DMG"
