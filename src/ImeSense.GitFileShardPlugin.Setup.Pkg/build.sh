#!/bin/bash
# Build script for the macOS distribution package of the git-file-shard plugin.
#
# Stages the PyInstaller payload, builds a component package with pkgbuild,
# wraps it into a distribution package with productbuild and optionally signs
# it with productsign. Run pyinstaller from the activated virtual environment
# (.venv) or make sure it is available on PATH.
#
# Usage:
#     build.sh --version <version> --arch arm64|x86_64 [--sign <identity>] [--skip-payload]

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
SKIP_PAYLOAD='false'

DIST_DIR="$REPO_ROOT/dist"
BUILD_DIR="$REPO_ROOT/build/pkg"
OUTPUT_DIR="$REPO_ROOT/bin"

usage() {
    echo "Usage: $0 --version <version> --arch arm64|x86_64 [--sign <identity>] [--skip-payload]"
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
        --skip-payload)
            SKIP_PAYLOAD='true'
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

# Build the PyInstaller payload for the requested architecture. The target
# architecture is passed through the GIT_FILE_SHARD_TARGET_ARCH environment
# variable because spec-file builds ignore the --target-arch command line
# option. Cross-building requires a Python interpreter that supports the
# target architecture (a universal2 build for the other architecture).
if [ "$SKIP_PAYLOAD" != 'true' ]; then
    if ! command -v pyinstaller >/dev/null 2>&1; then
        echo 'Error: pyinstaller was not found; activate the .venv virtual environment first.' >&2
        exit 1
    fi
    (cd "$REPO_ROOT" && GIT_FILE_SHARD_TARGET_ARCH="$ARCH" pyinstaller git-file-shard.spec --noconfirm)
fi

PAYLOAD="$DIST_DIR/git-file-shard"
if [ ! -f "$PAYLOAD" ]; then
    echo "Error: payload '$PAYLOAD' was not found; build it first or drop --skip-payload." >&2
    exit 1
fi

# Verify the payload architecture so a wrong interpreter cannot slip through.
ACTUAL_ARCH="$(lipo -info "$PAYLOAD" | awk '{ print $NF }')"
if [ "$ACTUAL_ARCH" != "$ARCH" ]; then
    echo "Error: payload architecture is '$ACTUAL_ARCH' but '$ARCH' was requested." >&2
    echo 'Cross-build with a Python interpreter that supports the target architecture (universal2 for the other one).' >&2
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

PRODUCT_PKG="$OUTPUT_DIR/GitFileShardPlugin.v$VERSION.$ARCH.pkg"
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
