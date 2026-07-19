"""
Git ignore config management.
"""

from os import path

def is_in_gitignore(repo_root, file_path):
    """
    Check if file_path is already listed in Git ignore config.
    """

    gitignore_path = path.join(repo_root, '.gitignore')
    if not path.isfile(gitignore_path):
        return False

    with open(gitignore_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            if stripped == file_path or stripped == '/' + file_path:
                return True

    return False

def add_to_gitignore(repo_root, file_path):
    """
    Append file_path to Git ignore config.
    """

    gitignore_path = path.join(repo_root, '.gitignore')

    content = ''
    if path.isfile(gitignore_path):
        with open(gitignore_path, 'r', encoding='utf-8') as f:
            content = f.read()

    if content and not content.endswith('\n'):
        content += '\n'

    content += file_path + '\n'

    with open(gitignore_path, 'w', encoding='utf-8') as f:
        f.write(content)

def get_ignored_dirs(repo_root):
    """
    Parse .gitignore and return two sets of directory patterns:
    - basename_dirs: directory names to skip anywhere (patterns without '/')
    - anchored_dirs: full relative paths to skip at root (patterns with '/')

    Only entries ending with '/' are treated as directories.
    Entries added by this plugin (file paths without trailing '/')
    are naturally excluded.

    This follows Git's .gitignore semantics: a pattern without a slash
    matches at any depth, while a pattern with a slash is anchored to
    the repository root.
    """

    gitignore_path = path.join(repo_root, '.gitignore')
    if not path.isfile(gitignore_path):
        return set(), set()

    basename_dirs = set()
    anchored_dirs = set()

    with open(gitignore_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            if stripped.endswith('/'):
                # Remove trailing slash.
                dir_path = stripped.rstrip('/')

                # Remove leading slash if present.
                if dir_path.startswith('/'):
                    dir_path = dir_path[1:]

                if not dir_path:
                    continue

                if '/' in dir_path:
                    # Pattern with a slash — anchored to root.
                    anchored_dirs.add(dir_path)
                else:
                    # Pattern without a slash — matches at any depth.
                    basename_dirs.add(dir_path)

    return basename_dirs, anchored_dirs
