"""Core file splitting, merging and hashing operations."""

import hashlib
import json
import os

from os import path

DEFAULT_CHUNK_MB = 50
MANIFEST_FILE = 'manifest.json'

def get_file_hash(file_path, algorithm='sha256'):
    """
    Compute hash of a file using the specified algorithm.
    """

    if not path.isfile(file_path):
        return None

    h = hashlib.new(algorithm)
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)

    return h.hexdigest()

def split_file(file_path, output_dir, chunk_mb=DEFAULT_CHUNK_MB):
    """
    Split a file into chunks. Returns the number of parts created.
    """

    chunk_size = chunk_mb * 1024 * 1024
    part_number = 1

    os.makedirs(output_dir, exist_ok=True)

    with open(file_path, 'rb') as f:
        while True:
            data = f.read(chunk_size)
            if not data:
                break

            part_path = path.join(output_dir, f'part-{part_number}')
            with open(part_path, 'wb') as pf:
                pf.write(data)

            part_number += 1

    return part_number - 1

def merge_file(shards_dir, output_path):
    """
    Merge parts from shards_dir into output_path. Returns total bytes written.
    """

    part_number = 1
    total_bytes = 0

    output_dir = path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(output_path, 'wb') as out:
        while True:
            part_path = path.join(shards_dir, f'part-{part_number}')
            if not path.isfile(part_path):
                break

            with open(part_path, 'rb') as pf:
                data = pf.read()
                out.write(data)
                total_bytes += len(data)

            part_number += 1

    return total_bytes

def create_manifest(output_dir, original_file, file_hash, algorithm,
                    part_count, part_size_mb, total_size):
    """
    Create a manifest file in the output directory.
    """

    manifest = {
        'original_file': original_file,
        'hash': file_hash,
        'algorithm': algorithm,
        'part_count': part_count,
        'part_size_mb': part_size_mb,
        'total_size': total_size,
    }
    manifest_path = path.join(output_dir, MANIFEST_FILE)
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)

def read_manifest(manifest_path):
    """
    Read a manifest file.
    """

    with open(manifest_path, 'r', encoding='utf-8') as f:
        return json.load(f)
