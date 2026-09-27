#!/bin/bash
# Uninstall script for the ImeSense Git File Shard Plugin package.
#
# Removes the PATH symlink, the installation folder and the package
# receipt. Must be run with administrator privileges:
#
#     sudo '/Library/Application Support/ImeSense/Git File Shard Plugin/uninstall.sh'

set -u

IDENTIFIER='org.imesense.git-file-shard'
APP_NAME='Git File Shard Plugin'
INSTALL_DIR="/Library/Application Support/ImeSense/$APP_NAME"
LINK_PATH='/usr/local/bin/git-file-shard'

if [ "$(id -u)" -ne 0 ]; then
    echo 'Error: this script must be run with administrator privileges (use sudo).' >&2
    exit 1
fi

# Remove the PATH symlink only when it points into the installation folder,
# so a link managed by something else is left untouched.
if [ -L "$LINK_PATH" ]; then
    TARGET="$(readlink "$LINK_PATH")"
    case "$TARGET" in
        "$INSTALL_DIR"/*)
            rm -f "$LINK_PATH"
            ;;
        *)
            echo "Warning: symlink '$LINK_PATH' points elsewhere ('$TARGET'), left untouched."
            ;;
    esac
fi

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
else
    echo "Warning: installation folder '$INSTALL_DIR' not found, nothing to remove."
fi

# Remove the publisher folder when it is left empty, so the uninstall does
# not leave an orphan directory behind. rmdir only removes empty folders,
# so other ImeSense applications there stay untouched.
INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
if [ -d "$INSTALL_PARENT" ]; then
    rmdir "$INSTALL_PARENT" 2>/dev/null || true
fi

# Forget the package receipt so the package no longer shows as installed.
if pkgutil --pkg-info "$IDENTIFIER" >/dev/null 2>&1; then
    pkgutil --forget "$IDENTIFIER"
fi

echo 'ImeSense Git File Shard Plugin uninstalled.'

exit 0
