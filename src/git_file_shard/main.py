import hashlib

from argparse import ArgumentParser
from os import path, remove

DEFAULT_CHUNK_MB = 50

def split_file(file_path, chunk_mb=DEFAULT_CHUNK_MB):
    if not path.isfile(file_path):
        print(f"Error: '{file_path}' file was not found!")
        return False

    chunk_size = chunk_mb * 1024 * 1024
    part_number = 1
    with open(file_path, 'rb') as file:
        while True:
            data = file.read(chunk_size)
            if not data:
                break

            part_name = f"{file_path}.part{part_number:03d}"
            with open(part_name, 'wb') as pf:
                pf.write(data)

            print(f"Created part: {part_name} ({len(data)} bytes)")
            part_number += 1

    print(f"Split completed. Parts count: {part_number - 1}")

    return True

def merge_files(base_name, output_path=None):
    if output_path is None:
        output_path = base_name + ".restored"

    part_number = 1
    total_bytes = 0
    with open(output_path, 'wb') as output_file:
        while True:
            part_name = f"{base_name}.part{part_number:03d}"
            if not path.isfile(part_name):
                break

            with open(part_name, 'rb') as part_file:
                data = part_file.read()
                output_file.write(data)
                total_bytes += len(data)

            print(f"Read part: {part_name} ({len(data)} bytes)")

            part_number += 1

    if part_number == 1:
        print("Error: no one part was not found!")

        if path.exists(output_path) and path.getsize(output_path) == 0:
            remove(output_path)
        return None

    print(f"Merge completed. Merged {total_bytes} bytes in '{output_path}'")

    return output_path

def get_file_hash(file_path, algorithm='sha256'):
    if not path.isfile(file_path):
        return None

    hash = hashlib.new(algorithm)
    with open(file_path, 'rb') as file:
        for chunk in iter(lambda: file.read(8192), b''):
            hash.update(chunk)

    return hash.hexdigest()

def main():
    parser = ArgumentParser(
        description='Split, merge and verify file hashes.'
    )
    parser.add_argument(
        '--split',
        metavar='FILE',
        help='Split the specified file into parts'
    )
    parser.add_argument(
        '--merge',
        metavar='BASE',
        help='Merge file from parts BASE.partXXX'
    )
    parser.add_argument(
        '--hash',
        metavar='FILE',
        help='Compute file hash (SHA-256)'
    )
    parser.add_argument(
        '--output',
        metavar='FILE',
        help='Output file name for merge (default: BASE.restored)'
    )
    parser.add_argument(
        '--size',
        type=int,
        default=DEFAULT_CHUNK_MB,
        help='Part size in MB (default: 50)'
    )
    parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    arguments = parser.parse_args()

    # Select action.
    if arguments.split:
        split_file(arguments.split, arguments.size)
    elif arguments.merge:
        output = arguments.output if arguments.output else None
        merged = merge_files(arguments.merge, output)
        if merged:
            # Compare hash with original.
            if path.isfile(arguments.merge):
                algorithm = 'md5' if arguments.md5 else 'sha256'
                original_hash = get_file_hash(arguments.merge, algorithm)
                marged_hash = get_file_hash(merged, algorithm)
                print(f"Original hash ({algorithm.upper()}): {original_hash}")
                print(f"Merged hash   ({algorithm.upper()}): {marged_hash}")
                if original_hash == marged_hash:
                    print("Hashes match.")
                else:
                    print("Hashes NOT match!")
            else:
                print("Source file was not found!")
    elif arguments.hash:
        algorithm = 'md5' if arguments.md5 else 'sha256'
        hash = get_file_hash(arguments.hash, algorithm)
        if hash is None:
            print(f"Error: file '{arguments.hash}' was not found!")
        else:
            print(f"{algorithm.upper()} file hash '{arguments.hash}': {hash}")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
