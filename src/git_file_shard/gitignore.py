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
