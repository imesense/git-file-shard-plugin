"""
Application entry point for Git plugin.
"""

from argparse import ArgumentParser

from git_file_shard.scanner import (
    scan_repo,
    restore_repo,
    split_single,
    merge_single
)
from git_file_shard.splitter import (
    DEFAULT_CHUNK_MB,
    get_file_hash
)

def main():
    parser = ArgumentParser(
        description='Git plugin for splitting large files into shards and merging them back.'
    )
    subparsers = parser.add_subparsers(
        dest='command',
        help='Available commands'
    )

    # Scan commands.
    scan_parser = subparsers.add_parser(
        'scan',
        help='Scan repository for large files and split them into shards'
    )
    scan_parser.add_argument(
        '--repo',
        default='.',
        help='Repository root path (default: current directory)'
    )
    scan_parser.add_argument(
        '--threshold',
        type=int,
        default=DEFAULT_CHUNK_MB,
        help=f'Size threshold in MB (default: {DEFAULT_CHUNK_MB})'
    )
    scan_parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    # Restore commands.
    restore_parser = subparsers.add_parser(
        'restore',
        help='Merge all shards back to original files'
    )
    restore_parser.add_argument(
        '--repo',
        default='.',
        help='Repository root path (default: current directory)'
    )
    restore_parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    # Split commands.
    split_parser = subparsers.add_parser(
        'split',
        help='Split a single file into shards'
    )
    split_parser.add_argument(
        'file',
        help='File to split')
    split_parser.add_argument(
        '--repo',
        default='.',
        help='Repository root path (default: current directory)'
    )
    split_parser.add_argument(
        '--threshold',
        type=int,
        default=DEFAULT_CHUNK_MB,
        help=f'Part size in MB (default: {DEFAULT_CHUNK_MB})'
    )
    split_parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    # Merge commands.
    merge_parser = subparsers.add_parser(
        'merge',
        help='Merge shards for a specific file back'
    )
    merge_parser.add_argument(
        'file',
        help='Original file path'
    )
    merge_parser.add_argument(
        '--repo',
        default='.',
        help='Repository root path (default: current directory)'
    )
    merge_parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    # Hashing commands.
    hash_parser = subparsers.add_parser(
        'hash',
        help='Compute file hash'
    )
    hash_parser.add_argument(
        'file',
        help='File to hash'
    )
    hash_parser.add_argument(
        '--md5',
        action='store_true',
        help='Use MD5 instead of SHA-256'
    )

    arguments = parser.parse_args()
    if not arguments.command:
        parser.print_help()
        return

    algorithm = 'md5' if arguments.md5 else 'sha256'

    if arguments.command == 'scan':
        scan_repo(arguments.repo, arguments.threshold, algorithm)
    elif arguments.command == 'restore':
        restore_repo(arguments.repo, algorithm)
    elif arguments.command == 'split':
        split_single(arguments.file, arguments.repo, arguments.threshold, algorithm)
    elif arguments.command == 'merge':
        merge_single(arguments.file, arguments.repo, algorithm)
    elif arguments.command == 'hash':
        hash_value = get_file_hash(arguments.file, algorithm)
        if hash_value is None:
            print(f"Error: file '{arguments.file}' was not found!")
        else:
            print(f"{algorithm.upper()} file hash '{arguments.file}': {hash_value}")

if __name__ == "__main__":
    main()
