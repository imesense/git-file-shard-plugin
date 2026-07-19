"""
Repository scanning and restoring logic.
"""

import os

from os import path

from git_file_shard.splitter import (
    DEFAULT_CHUNK_MB,
    MANIFEST_FILE,
    create_manifest,
    get_file_hash,
    merge_file,
    read_manifest,
    split_file,
)
from git_file_shard.gitignore import (
    add_to_gitignore,
    get_ignored_dirs,
    is_in_gitignore
)
from git_file_shard.gitattributes import (
    is_file_shards_auto
)

SHARDS_DIR = '.git-file-shards'

def _build_skip_dirs(repo_root):
    """
    Build skip-directory data for scanning.
    Returns a tuple of:
    - basename_dirs: set of directory names to skip at any depth
    - anchored_dirs: set of root-relative paths to skip

    Always includes '.git' and SHARDS_DIR, plus all directory
    entries found in .gitignore.
    """

    basename_dirs = {'.git', SHARDS_DIR}
    gitignore_basenames, gitignore_anchored = get_ignored_dirs(repo_root)
    basename_dirs |= gitignore_basenames
    return basename_dirs, gitignore_anchored

def _normalize_rel_path(rel_path):
    """
    Normalize path separators to forward slashes.
    """

    return rel_path.replace('\\', '/')

def _get_shards_dir(repo_root, rel_path):
    """
    Build the shards output directory path for a file.
    Format: .git-file-shards/<file_path_with_file_name>/
    """

    parts = rel_path.split('/')
    return path.join(repo_root, SHARDS_DIR, *parts)

def _cleanup_shards(shards_dir):
    """
    Remove all existing part files and manifest from the shards
    directory before writing new ones. This prevents stale parts
    from a previous version (with a different part count) from
    corrupting the restored file.
    """

    if not path.isdir(shards_dir):
        return

    for entry in os.listdir(shards_dir):
        entry_path = path.join(shards_dir, entry)
        if path.isfile(entry_path):
            os.remove(entry_path)

def _needs_resplit(shards_dir, current_hash):
    """
    Check if the file needs to be re-split by comparing the
    hash stored in the existing manifest with the current file hash.
    Returns True if no manifest exists or the hash has changed.
    """

    manifest_path = path.join(shards_dir, MANIFEST_FILE)
    if not path.isfile(manifest_path):
        return True

    manifest = read_manifest(manifest_path)
    return manifest.get('hash') != current_hash

def scan_repo(repo_root='.', threshold_mb=DEFAULT_CHUNK_MB, algorithm='sha256'):
    """
    Scan repository for large files and split them into shards.
    """

    repo_root = path.abspath(repo_root)
    threshold_bytes = threshold_mb * 1024 * 1024

    skip_basename, skip_anchored = _build_skip_dirs(repo_root)
    large_files = []

    for root, dirs, files in os.walk(repo_root):
        # Skip unwanted directories by basename (any depth).
        dirs[:] = [d for d in dirs if d not in skip_basename]

        # Skip unwanted directories by anchored path (root-relative).
        if skip_anchored:
            rel_root = _normalize_rel_path(path.relpath(root, repo_root))
            dirs[:] = [
                d for d in dirs
                if _normalize_rel_path(path.join(rel_root, d)) not in skip_anchored
            ]

        for filename in files:
            file_path = path.join(root, filename)
            try:
                file_size = path.getsize(file_path)
            except OSError:
                continue

            if file_size > threshold_bytes:
                rel_path = _normalize_rel_path(path.relpath(file_path, repo_root))
                large_files.append((rel_path, file_path, file_size))

    if not large_files:
        print("No files exceeding the size threshold found.")
        return

    # Keep only files marked with file-shards=auto in .gitattributes.
    large_files = [
        (rel_path, abs_path, file_size)
        for rel_path, abs_path, file_size in large_files
        if is_file_shards_auto(repo_root, rel_path)
    ]

    if not large_files:
        print("No files with file-shards=auto exceeding the size threshold found.")
        return

    print(f"Found {len(large_files)} file(s) exceeding {threshold_mb} MB:")
    for rel_path, _, size in large_files:
        print(f"  {rel_path} ({size / (1024 * 1024):.1f} MB)")

    for rel_path, abs_path, file_size in large_files:
        print(f"\nProcessing: {rel_path}")

        file_hash = get_file_hash(abs_path, algorithm)
        if file_hash is None:
            print(f"  Error: could not read file '{rel_path}'")
            continue

        output_dir = _get_shards_dir(repo_root, rel_path)

        if _needs_resplit(output_dir, file_hash):
            print(f"  Splitting (hash: {file_hash})...")
            _cleanup_shards(output_dir)
            part_count = split_file(abs_path, output_dir, threshold_mb)
            create_manifest(output_dir, rel_path, file_hash, algorithm,
                            part_count, threshold_mb, file_size)
            print(f"  Split completed. Parts count: {part_count}")
        else:
            print(f"  Already split (hash: {file_hash}). Skipping.")

        # Update Git ignore config.
        if is_in_gitignore(repo_root, rel_path):
            print(f"  Already in .gitignore.")
        else:
            add_to_gitignore(repo_root, rel_path)
            print(f"  Added to .gitignore.")

    print("\nScan completed.")

def restore_repo(repo_root='.', algorithm='sha256'):
    """
    Merge all shards back to original files.
    """

    repo_root = path.abspath(repo_root)
    shards_root = path.join(repo_root, SHARDS_DIR)

    if not path.isdir(shards_root):
        print("No shards directory found. Nothing to restore.")
        return

    restored_count = 0

    for root, dirs, files in os.walk(shards_root):
        if MANIFEST_FILE not in files:
            continue

        manifest_path = path.join(root, MANIFEST_FILE)
        manifest = read_manifest(manifest_path)

        original_file = manifest['original_file']
        expected_hash = manifest['hash']
        output_path = path.join(
            repo_root, *_normalize_rel_path(original_file).split('/')
        )

        print(f"Restoring: {original_file}")

        # Skip if already restored with matching hash.
        if path.isfile(output_path):
            current_hash = get_file_hash(output_path, algorithm)
            if current_hash == expected_hash:
                print(f"  Already restored (hash matches). Skipping.")
                continue

        part_count = manifest['part_count']
        total_bytes = 0
        missing = False

        with open(output_path, 'wb') as out:
            for i in range(1, part_count + 1):
                part_path = path.join(root, f'part-{i}')
                if not path.isfile(part_path):
                    print(f"  Error: missing part {part_path}")
                    missing = True
                    break

                with open(part_path, 'rb') as pf:
                    data = pf.read()
                    out.write(data)
                    total_bytes += len(data)

        if missing:
            continue

        print(f"  Restored {total_bytes} bytes.")

        # Verify hash
        restored_hash = get_file_hash(output_path, algorithm)
        if restored_hash == expected_hash:
            print(f"  Hash verified: {restored_hash}")
        else:
            print(f"  Warning: hash mismatch! Expected {expected_hash}, got {restored_hash}")

        restored_count += 1

    if restored_count == 0:
        print("No shards were restored.")
    else:
        print(f"\nRestore completed. {restored_count} file(s) restored.")

def split_single(file_path, repo_root='.', threshold_mb=DEFAULT_CHUNK_MB, algorithm='sha256'):
    """
    Split a single file into shards and update Git ignore config.
    """

    repo_root = path.abspath(repo_root)
    file_abs_path = path.abspath(file_path)

    if not path.isfile(file_abs_path):
        print(f"Error: file '{file_path}' was not found!")
        return

    rel_path = _normalize_rel_path(path.relpath(file_abs_path, repo_root))
    file_hash = get_file_hash(file_abs_path, algorithm)

    if file_hash is None:
        print(f"Error: could not read file '{file_path}'")
        return

    output_dir = _get_shards_dir(repo_root, rel_path)

    if _needs_resplit(output_dir, file_hash):
        print(f"Splitting '{rel_path}' (hash: {file_hash})...")
        _cleanup_shards(output_dir)
        part_count = split_file(file_abs_path, output_dir, threshold_mb)
        create_manifest(output_dir, rel_path, file_hash, algorithm,
                        part_count, threshold_mb, path.getsize(file_abs_path))
        print(f"Split completed. Parts count: {part_count}")
    else:
        print(f"Already split (hash: {file_hash}). Skipping.")

    if is_in_gitignore(repo_root, rel_path):
        print(f"Already in .gitignore.")
    else:
        add_to_gitignore(repo_root, rel_path)
        print(f"Added to .gitignore.")

def merge_single(file_path, repo_root='.', algorithm='sha256'):
    """
    Merge shards for a specific file back to its original location.
    """

    repo_root = path.abspath(repo_root)
    file_abs_path = path.abspath(file_path)
    rel_path = _normalize_rel_path(path.relpath(file_abs_path, repo_root))

    shards_dir = _get_shards_dir(repo_root, rel_path)

    if not path.isdir(shards_dir):
        print(f"Error: no shards found for '{rel_path}'")
        return

    manifest_path = path.join(shards_dir, MANIFEST_FILE)

    if not path.isfile(manifest_path):
        print(f"Error: manifest not found in {shards_dir}")
        return

    manifest = read_manifest(manifest_path)
    output_path = path.join(repo_root, *rel_path.split('/'))

    print(f"Merging '{rel_path}'...")
    total_bytes = merge_file(shards_dir, output_path)
    print(f"Merged {total_bytes} bytes.")

    # Verify hash
    expected_hash = manifest['hash']
    restored_hash = get_file_hash(output_path, algorithm)

    if restored_hash == expected_hash:
        print(f"Hash verified: {restored_hash}")
    else:
        print(f"Warning: hash mismatch! Expected {expected_hash}, got {restored_hash}")
