#!/bin/bash
# Build script for the Debian package of the git-file-shard plugin.
#
# Stages the prebuilt plugin binary from dist/ into a vendor tree under
# /opt, writes the DEBIAN/control metadata and builds the package with
# dpkg-deb. Bundling the plugin (PyInstaller) is a separate step that must
# run beforehand and produce dist/git-file-shard.
#
# Usage:
#     build.sh --version <version> --arch amd64|arm64 [--distro <id>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PACKAGE_NAME='git-file-shard'
PUBLISHER='imesense'
APP_NAME='git-file-shard-plugin'
INSTALL_DIR="/opt/$PUBLISHER/$APP_NAME"
LINK_PATH='/usr/local/bin/git-file-shard'
MAINTAINER='acidicMercury8 <acidicmercury8@outlook.com>'
HOMEPAGE='https://github.com/imesense/git-file-shard-plugin/'

VERSION=''
ARCH=''
DISTRO=''
DISTRO_SET='false'

DIST_DIR="$REPO_ROOT/dist"
BUILD_DIR="$REPO_ROOT/build/deb"
OUTPUT_DIR="$REPO_ROOT/bin"

usage() {
    echo "Usage: $0 --version <version> --arch amd64|arm64 [--distro <id>]"
}

# A distribution identifier becomes a file name segment: lowercase
# letters, digits, '.', '+', '~' and '-', starting with a letter or digit.
is_valid_distro() {
    case "$1" in
        ''|*[!a-z0-9.+~-]*)
            return 1
            ;;
        [a-z0-9]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Derive the identifier from the build host, e.g. ubuntu20.04 or debian12.
# The payload is bound to the host's glibc, so the host describes what the
# package runs on. Parsed with awk instead of sourcing the file so an
# unusual /etc/os-release cannot affect this script.
detect_distro() {
    [ -r '/etc/os-release' ] || return 0

    local os_id os_version
    os_id="$(awk -F= '$1 == "ID" { gsub(/"/, "", $2); print $2; exit }' '/etc/os-release')"
    os_version="$(awk -F= '$1 == "VERSION_ID" { gsub(/"/, "", $2); print $2; exit }' '/etc/os-release')"

    if [ -n "$os_id" ] && [ -n "$os_version" ]; then
        printf '%s%s' "$os_id" "$os_version"
    elif [ -n "$os_id" ]; then
        printf '%s' "$os_id"
    fi
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
        --distro)
            if [ "$#" -lt 2 ]; then
                echo 'Error: --distro requires a value (pass an empty value to omit the segment).' >&2
                usage >&2
                exit 1
            fi
            DISTRO="$2"
            DISTRO_SET='true'
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

if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
    echo "Error: unsupported architecture '$ARCH' (expected amd64 or arm64)." >&2
    exit 1
fi

# A Debian version must start with a digit and must not contain whitespace.
case "$VERSION" in
    [0-9]*) ;;
    *)
        echo "Error: invalid version '$VERSION' (it must start with a digit)." >&2
        exit 1
        ;;
esac
case "$VERSION" in
    *[[:space:]]*)
        echo "Error: invalid version '$VERSION' (whitespace is not allowed)." >&2
        exit 1
        ;;
esac

if [ "$(uname -s)" != 'Linux' ]; then
    echo 'Error: this script must be run on Linux.' >&2
    exit 1
fi

if [ "$DISTRO_SET" = 'true' ]; then
    if [ -n "$DISTRO" ] && ! is_valid_distro "$DISTRO"; then
        echo "Error: invalid distribution identifier '$DISTRO' (expected lowercase letters, digits, '.', '+', '~' or '-')." >&2
        exit 1
    fi
else
    DISTRO="$(detect_distro)"
    if [ -n "$DISTRO" ] && ! is_valid_distro "$DISTRO"; then
        echo "Warning: ignoring detected distribution identifier '$DISTRO'." >&2
        DISTRO=''
    fi
fi

for tool in dpkg-deb readelf; do
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

for file in "$REPO_ROOT/README.md" "$REPO_ROOT/LICENSE.txt"; do
    if [ ! -f "$file" ]; then
        echo "Error: required file '$file' was not found." >&2
        exit 1
    fi
done

# Verify the payload architecture so a wrong bundle cannot slip through.
# LC_ALL=C keeps the field names parseable regardless of the build host
# locale.
if ! LC_ALL=C readelf -h "$PAYLOAD" >/dev/null 2>&1; then
    echo "Error: payload '$PAYLOAD' is not an ELF executable." >&2
    exit 1
fi

ELF_MACHINE="$(LC_ALL=C readelf -h "$PAYLOAD" | awk -F ': *' '/Machine:/ { print $2 }')"
case "$ELF_MACHINE" in
    *X86-64*)
        ACTUAL_ARCH='amd64'
        ;;
    *AArch64*)
        ACTUAL_ARCH='arm64'
        ;;
    *)
        echo "Error: unsupported payload architecture '$ELF_MACHINE'." >&2
        exit 1
        ;;
esac

if [ "$ACTUAL_ARCH" != "$ARCH" ]; then
    echo "Error: payload architecture is '$ACTUAL_ARCH' but '$ARCH' was requested." >&2
    echo 'Rebundle the plugin on a host of the requested architecture (PyInstaller does not cross-compile).' >&2
    exit 1
fi

# Stage the vendor tree that dpkg-deb turns into the package payload.
STAGE_DIR="$BUILD_DIR/root"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR$INSTALL_DIR/bin"
mkdir -p "$STAGE_DIR$INSTALL_DIR/share/doc"
mkdir -p "$STAGE_DIR$(dirname "$LINK_PATH")"
cp "$PAYLOAD" "$STAGE_DIR$INSTALL_DIR/bin/git-file-shard"
chmod 755 "$STAGE_DIR$INSTALL_DIR/bin/git-file-shard"
cp "$REPO_ROOT/README.md" "$STAGE_DIR$INSTALL_DIR/share/doc/README.md"
cp "$REPO_ROOT/LICENSE.txt" "$STAGE_DIR$INSTALL_DIR/share/doc/LICENSE.txt"
chmod 644 "$STAGE_DIR$INSTALL_DIR/share/doc/README.md"
chmod 644 "$STAGE_DIR$INSTALL_DIR/share/doc/LICENSE.txt"
# Absolute target so the link resolves regardless of the caller's working
# directory and of /usr/local/bin being a symlink itself.
ln -s "$INSTALL_DIR/bin/git-file-shard" "$STAGE_DIR$LINK_PATH"

# Deterministic directory permissions: mkdir inherits the build host umask.
find "$STAGE_DIR" -type d -exec chmod 755 {} +

# Installed-Size is the payload size in KiB, computed before DEBIAN/ is
# added to the staged tree.
INSTALLED_SIZE="$(du -k -s "$STAGE_DIR" | awk '{ print $1 }')"

CONTROL_DIR="$STAGE_DIR/DEBIAN"
mkdir -p "$CONTROL_DIR"
cat > "$CONTROL_DIR/control" <<EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: vcs
Priority: optional
Architecture: $ARCH
Depends: git
Installed-Size: $INSTALLED_SIZE
Maintainer: $MAINTAINER
Homepage: $HOMEPAGE
Description: Git plugin for splitting large files into shards and merging them back
 Git File Shard splits large files into shards under .git-file-shards/ and
 merges them back, so repositories can track large binary assets without
 storing the originals in Git.
EOF

# The distribution identifier only labels the file; the Version field keeps
# the plain release version.
if [ -n "$DISTRO" ]; then
    DEB_PATH="$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${DISTRO}_${ARCH}.deb"
else
    DEB_PATH="$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
fi
mkdir -p "$OUTPUT_DIR"
rm -f "$DEB_PATH"
dpkg-deb --root-owner-group -Zxz --build "$STAGE_DIR" "$DEB_PATH"

echo "Built $DEB_PATH"
