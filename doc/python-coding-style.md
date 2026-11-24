# Coding Style

English | [Русский](./python-coding-style.rus.md)

This document defines the coding standards for the project.
This standard is designed for the Python code style.

## File Conventions

- Default file extension for Python files is `py`.
- File name must exactly match the module name.
- Files must be saved in __UTF-8__ encoding with __LF__ line endings and must end with one empty line.

## Naming Conventions

- Package and module names must be in the singular and __Lower Case__.
- Name of class should be written in __Pascal Case__.
  - Test class must have `Test` postfix.
- Names of the constants must be written in all caps __Snake Case__.
- Names of variables and functions must be in __Snake Case__.
- Names of private members must have `_` prefix.

## Code Formatting

- Max 120 characters per line.
- Use 4 spaces instead of tabs.
- Use single quotes for string literals and f-strings for interpolation.
- Use triple double quotes for docstrings of all public functions.
- Use 1 space between the keyword and the condition.

## Best Practices

- Group imports and separate them by:
  - Standard library (`os`, `hashlib`, `argparse`).
  - Third-party dependencies.
  - Project-specific (`git_file_shard.*`).
- Use one empty line between import groups.
- Prefer `from os import path` style for frequently used submodules.
- Print user-facing output with `print()` and use `Error:` / `Warning:` prefixes.
- Parse command line arguments with `argparse` subcommands and keep new flags consistent with the existing ones (`--repo`, `--threshold`, `--md5`).

## Examples

```python
if condition:
    # ...
else:
    # ...
```

```python
class UserService:
    def update_user(self, user):
        """Update the given user."""

        # ...
```

```python
for i in range(10):
    print(i)

if value == 1:
    # ...
else:
    # ...
```

```python
parts = [
    first,
    second,
    third
]
```

```python
import hashlib
import os

from os import path

from git_file_shard.splitter import get_file_hash

class UserService:
    """User service."""

    MAX_ATTEMPTS = 3

    def __init__(self, repository):
        self.repository = repository

    def find_by_id(self, user_id):
        """Find a user by identifier."""

        # ...
```
