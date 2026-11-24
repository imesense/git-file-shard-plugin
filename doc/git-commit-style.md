---
title: git commit style
version: v0.1.0
---

<!-- markdownlint-disable MD025 -->

# Git commit style

<!-- markdownlint-enable MD025 -->

English | [Русский](./git-commit-style.rus.md)

This document defines standards for writing commit messages to maintain a clear, consistent, and meaningful history of project changes.

## Purpose

The described commit message format is necessary for:

- Convenient reading, understanding, and searching of changes.
- Building collaboration between team members.
- Supporting automatic changelog generation.
- Simplifying change tracking and issue debugging.

## Commit message structure

### 1. Header

- __Format__: `<Verb> <noun>`
- __Capitalized__ first letter.
- __Maximum length__: 72 characters.
- __Imperative mood__ (e.g., `Fix`/`Add`/`Remove`, not `Fixed`/`Added`).
- __No prefixes__ such as `[Fix]` or `[Feature]`.

Examples of correct commits:

- `Fix memory leak in data parser`
- `Add user profile validation`

Examples of commits that are not allowed to be merged:

- `Fixed bug` - too vague
- `[Feature] New login screen` - prefix is not allowed

### 2. Body (optional, for complex changes)

- Explain __what changed__ and __why__.
- Keep text within __72 characters__ per line.
- Use a bulleted list for multiple changes (when squashing).

Correct example:

```text
Optimize database query performance

- Replace nested queries with JOINs
- Add indexes on frequently filtered columns
- Reduces response time by ~40% in benchmarks
```

### 3. Footer (optional, for metadata)

- Issue references (e.g., `Closes #123`).
- Co-authors (e.g., `Co-authored-by: Name <email>`).

## Common mistakes

- Using tags or metadata:
  - Incorrect: `[BUGFIX] Fix null pointer exception`
  - Correct: `Fix null pointer exception in parser`

- Wrong verb form:
  - Incorrect: `Fixed broken tests`
  - Correct: `Fix broken unit tests`

- Verbs not in the imperative mood:
  - Incorrect: `Fixes rendering bug`
  - Correct: `Fix rendering bug`

- Vague messages:
  - Incorrect: `Make it better`
  - Correct: `Improve image loading performance`

- Incorrect noun placement:
  - Incorrect: `Add support compression`
  - Correct: `Add compression support`

## Commit message examples

### Single-line messages

```text
Fix race condition in thread manager
```

```text
Refactor configuration parser
```

```text
Update dependencies to latest versions
```

```text
Remove legacy compatibility layer
```

### Multi-line messages

```text
Improve error handling in network module

Added comprehensive error checking for socket operations and implemented
proper cleanup routines for failed connections. The changes prevent
memory leaks during network failures.
```

```text
Add performance benchmarks for core functions

Implemented a new benchmarking suite that measures execution time of
critical path operations. Includes tests for various input sizes and
edge cases.
```
