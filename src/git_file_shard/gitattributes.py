"""
Git attributes config management.
"""

import fnmatch

from os import path

def parse_gitattributes(repo_root):
    """
    Parse .gitattributes and return a list of (pattern, file_shards_value) tuples
    in the order they appear. Only rules with the file-shards attribute are included.
    Returns an empty list if .gitattributes does not exist.
    """

    gitattributes_path = path.join(repo_root, '.gitattributes')
    if not path.isfile(gitattributes_path):
        return []

    rules = []

    with open(gitattributes_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue

            parts = stripped.split()
            if len(parts) < 2:
                continue

            pattern = parts[0]

            # Look for file-shards attribute.
            # file-shards=auto  — enable auto-sharding
            # -file-shards      — unset/disable sharding (standard Git attributes syntax)
            file_shards_value = None
            for attr in parts[1:]:
                if attr == 'file-shards=auto':
                    file_shards_value = 'auto'
                elif attr == '-file-shards':
                    file_shards_value = 'off'

            if file_shards_value is not None:
                rules.append((pattern, file_shards_value))

    return rules

def _match_pattern(pattern, rel_path):
    """
    Match a .gitattributes pattern against a relative file path.
    Supports glob patterns like *.ext, path/to/file, and ** wildcards.
    """

    # Handle leading slash (root-relative pattern).
    if pattern.startswith('/'):
        pattern = pattern[1:]
        return fnmatch.fnmatch(rel_path, pattern)

    # Handle ** wildcards by converting to fnmatch-compatible form.
    if '**' in pattern:
        # Replace ** with a placeholder that matches everything including slashes.
        # fnmatch doesn't support **, so we use a two-step approach.
        expanded = pattern.replace('**/', '')
        expanded = expanded.replace('**', '*')
        return fnmatch.fnmatch(rel_path, expanded) or fnmatch.fnmatch(rel_path, '**/' + expanded)

    # Patterns without a slash match against basename only.
    if '/' not in pattern:
        return fnmatch.fnmatch(path.basename(rel_path), pattern)

    # Patterns with a slash match against the full relative path.
    return fnmatch.fnmatch(rel_path, pattern)

def is_file_shards_auto(repo_root, rel_path):
    """
    Check if file-shards=auto is enabled for a given file path.
    Uses last-match-wins semantics (like Git attributes).
    Returns True only if the last matching rule sets file-shards=auto.
    """

    rules = parse_gitattributes(repo_root)

    result = None
    for pattern, value in rules:
        if _match_pattern(pattern, rel_path):
            result = value

    return result == 'auto'
