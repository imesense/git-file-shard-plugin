#!/bin/bash
# Build script for the macOS distribution package of the git-file-shard plugin.
#
# Stages the prebuilt plugin binary from dist/, builds a component package
# with pkgbuild, wraps it into a distribution package with productbuild and
# optionally signs it with productsign. Bundling the plugin (PyInstaller) is
# a separate step that must run beforehand and produce dist/git-file-shard.
#
# Usage:
#     build.sh --version <version> --arch arm64|x86_64 [--sign <identity>] [--plain-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IDENTIFIER='org.imesense.git-file-shard'
PUBLISHER='ImeSense'
APP_NAME='Git File Shard Plugin'
INSTALL_LOCATION="/Library/Application Support/$PUBLISHER/$APP_NAME"

VERSION=''
ARCH=''
SIGN_IDENTITY=''
PLAIN_NAME='false'

DIST_DIR="$REPO_ROOT/dist"
BUILD_DIR="$REPO_ROOT/build/pkg"
OUTPUT_DIR="$REPO_ROOT/bin"

usage() {
    echo "Usage: $0 --version <version> --arch arm64|x86_64 [--sign <identity>] [--plain-name]"
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
        --sign)
            if [ "$#" -lt 2 ]; then
                echo 'Error: --sign requires a value.' >&2
                usage >&2
                exit 1
            fi
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --plain-name)
            PLAIN_NAME='true'
            shift
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

for tool in pkgbuild productbuild codesign lipo; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: required tool '$tool' was not found." >&2
        exit 1
    fi
done

# The plugin binary is bundled in a separate step (PyInstaller) and must
# already exist in dist/.
PAYLOAD="$DIST_DIR/git-file-shard"
if [ ! -f "$PAYLOAD" ]; then
    echo "Error: payload '$PAYLOAD' was not found; bundle the plugin first." >&2
    exit 1
fi

# Verify the payload architecture so a wrong bundle cannot slip through.
ACTUAL_ARCH="$(lipo -info "$PAYLOAD" | awk '{ print $NF }')"
if [ "$ACTUAL_ARCH" != "$ARCH" ]; then
    echo "Error: payload architecture is '$ACTUAL_ARCH' but '$ARCH' was requested." >&2
    echo 'Rebundle the plugin for the requested architecture (a universal2 Python interpreter for the other one).' >&2
    exit 1
fi

# Ad-hoc sign the payload so it runs on Apple Silicon; real code signing with
# a Developer ID Application identity is a separate, future step.
codesign --force --sign - "$PAYLOAD"

# Stage the payload tree that pkgbuild turns into the component package.
STAGE_DIR="$BUILD_DIR/payload"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/bin"
cp "$PAYLOAD" "$STAGE_DIR/bin/git-file-shard"
chmod 755 "$STAGE_DIR/bin/git-file-shard"
cp "$REPO_ROOT/README.md" "$STAGE_DIR/README.md"
cp "$REPO_ROOT/LICENSE.txt" "$STAGE_DIR/LICENSE.txt"
cp "$SCRIPT_DIR/uninstall.sh" "$STAGE_DIR/uninstall.sh"
chmod 755 "$STAGE_DIR/uninstall.sh"

COMPONENT_PKG="$BUILD_DIR/GitFileShardPlugin-component.pkg"
pkgbuild \
    --root "$STAGE_DIR" \
    --install-location "$INSTALL_LOCATION" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --scripts "$SCRIPT_DIR/Scripts" \
    "$COMPONENT_PKG"

# By default the output name embeds the version and the architecture; the
# --plain-name option drops both (plain GitFileShardPlugin.pkg).
if [ "$PLAIN_NAME" = 'true' ]; then
    PRODUCT_PKG="$OUTPUT_DIR/GitFileShardPlugin.pkg"
else
    PRODUCT_PKG="$OUTPUT_DIR/GitFileShardPlugin.v$VERSION.$ARCH.pkg"
fi
mkdir -p "$OUTPUT_DIR"
productbuild \
    --distribution "$SCRIPT_DIR/distribution.xml" \
    --package-path "$BUILD_DIR" \
    --resources "$SCRIPT_DIR/Resources" \
    "$PRODUCT_PKG"

# Optionally sign the product with a Developer ID Installer identity.
if [ -n "$SIGN_IDENTITY" ]; then
    SIGNED_PKG="$BUILD_DIR/GitFileShardPlugin-signed.pkg"
    productsign --sign "$SIGN_IDENTITY" "$PRODUCT_PKG" "$SIGNED_PKG"
    mv "$SIGNED_PKG" "$PRODUCT_PKG"
fi

echo "Built $PRODUCT_PKG"
