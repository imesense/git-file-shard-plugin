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
    is_in_gitignore
)

SHARDS_DIR = '.git-file-shards'

# Directories to skip during scanning.
SKIP_DIRS = {'.git', SHARDS_DIR, '.venv', '__pycache__', 'build', 'dist', '.pip'}

def _normalize_rel_path(rel_path):
    """
    Normalize path separators to forward slashes.
    """

    return rel_path.replace('\\', '/')

def _get_shards_dir(repo_root, rel_path, file_hash):
    """
    Build the shards output directory path for a file.
    """

    parts = rel_path.split('/')
    return path.join(repo_root, SHARDS_DIR, *parts, file_hash[:20])

def scan_repo(repo_root='.', threshold_mb=DEFAULT_CHUNK_MB, algorithm='sha256'):
    """
    Scan repository for large files and split them into shards.
    """

    repo_root = path.abspath(repo_root)
    threshold_bytes = threshold_mb * 1024 * 1024

    large_files = []

    for root, dirs, files in os.walk(repo_root):
        # Skip unwanted directories in-place.
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

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

    print(f"Found {len(large_files)} file(s) exceeding {threshold_mb} MB:")
    for rel_path, _, size in large_files:
        print(f"  {rel_path} ({size / (1024 * 1024):.1f} MB)")

    for rel_path, abs_path, file_size in large_files:
        print(f"\nProcessing: {rel_path}")

        file_hash = get_file_hash(abs_path, algorithm)
        if file_hash is None:
            print(f"  Error: could not read file '{rel_path}'")
            continue

        output_dir = _get_shards_dir(repo_root, rel_path, file_hash)

        # Skip if already split with the same hash.
        manifest_path = path.join(output_dir, MANIFEST_FILE)
        if path.isfile(manifest_path):
            print(f"  Already split (hash: {file_hash}). Skipping.")
        else:
            print(f"  Splitting (hash: {file_hash})...")
            part_count = split_file(abs_path, output_dir, threshold_mb)
            create_manifest(output_dir, rel_path, file_hash, algorithm,
                            part_count, threshold_mb, file_size)
            print(f"  Split completed. Parts count: {part_count}")

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

    output_dir = _get_shards_dir(repo_root, rel_path, file_hash)

    manifest_path = path.join(output_dir, MANIFEST_FILE)
    if path.isfile(manifest_path):
        print(f"Already split (hash: {file_hash}). Skipping.")
    else:
        print(f"Splitting '{rel_path}' (hash: {file_hash})...")
        part_count = split_file(file_abs_path, output_dir, threshold_mb)
        create_manifest(output_dir, rel_path, file_hash, algorithm,
                        part_count, threshold_mb, path.getsize(file_abs_path))
        print(f"Split completed. Parts count: {part_count}")

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

    file_shards_dir = path.join(repo_root, SHARDS_DIR, *rel_path.split('/'))

    if not path.isdir(file_shards_dir):
        print(f"Error: no shards found for '{rel_path}'")
        return

    hash_dirs = [d for d in os.listdir(file_shards_dir)
                 if path.isdir(path.join(file_shards_dir, d))]

    if not hash_dirs:
        print(f"Error: no hash directories found for '{rel_path}'")
        return

    if len(hash_dirs) > 1:
        print(f"Warning: multiple versions found: {hash_dirs}")
        print(f"Using: {hash_dirs[0]}")

    hash_dir = path.join(file_shards_dir, hash_dirs[0])
    manifest_path = path.join(hash_dir, MANIFEST_FILE)

    if not path.isfile(manifest_path):
        print(f"Error: manifest not found in {hash_dir}")
        return

    manifest = read_manifest(manifest_path)
    output_path = path.join(repo_root, *rel_path.split('/'))

    print(f"Merging '{rel_path}'...")
    total_bytes = merge_file(hash_dir, output_path)
    print(f"Merged {total_bytes} bytes.")

    # Verify hash
    expected_hash = manifest['hash']
    restored_hash = get_file_hash(output_path, algorithm)

    if restored_hash == expected_hash:
        print(f"Hash verified: {restored_hash}")
    else:
        print(f"Warning: hash mismatch! Expected {expected_hash}, got {restored_hash}")
