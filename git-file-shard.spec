# -*- mode: python ; coding: utf-8 -*-
# pyright: reportUndefinedVariable=false

"""
PyInstaller spec for git-file-shard plugin.
"""

import os

# Target binary architecture for macOS builds (arm64 or x86_64); the
# GIT_FILE_SHARD_TARGET_ARCH environment variable is set by the pkg build
# script, because spec-file builds ignore the --target-arch command line
# option. Unset (None) builds for the interpreter's native architecture.
target_arch = os.environ.get('GIT_FILE_SHARD_TARGET_ARCH')

block_cipher = None

a = Analysis(
    ['src/git_file_shard/main.py'],
    pathex=['src'],
    binaries=[],
    datas=[],
    hiddenimports=[
        'git_file_shard',
        'git_file_shard.main',
        'git_file_shard.splitter',
        'git_file_shard.scanner',
        'git_file_shard.gitignore',
        'git_file_shard.gitattributes',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(
    a.pure,
    a.zipped_data,
    cipher=block_cipher
)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='git-file-shard',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=target_arch,
    codesign_identity=None,
    entitlements_file=None,
)
