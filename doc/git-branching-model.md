---
title: git branching model
version: v0.1.0
---

<!-- markdownlint-disable MD025 -->

# Git branching model

<!-- markdownlint-enable MD025 -->

English | [Русский](./git-git-branching-model.rus.md)

This document describes the principles of maintaining the project repository and the branch management strategy.

## Change history style

The project follows linear history in order to:

- Simplify code review and component separation.
- Preserve a clear chronological sequence.
- Reduce the number of merge conflicts.
- Make changes easier to understand.

## Branch types

### Long-lived branches

- `default`:
  - Main branch for active development.
  - Holds the stable state of the project.
  - Protected branch (direct access is granted only to maintainers).
  - Changes are made via merge requests.
  - Direct commits are prohibited.

### Working branches

- `feature`:
  - Each new feature is developed in a separate branch, which helps isolate changes.
- `fix`:
  - Used for fixes directly in the release version of the project.

### Format

Working branch names use the following naming format:

```text
feature/<short-descriptive-name>
fix/<short-descriptive-name>
```

For example: `feature/user-authentication`

## Branch management rules

### 1. Creation

- Branch from `default`; changes are merged back after the work is complete.
- Keep branches short-lived: strive to minimize branch lifetime by merging changes into `default` often and regularly.
- Limit the scope of a branch to one logically complete change: do not mix refactoring with new functionality or problem fixes.

### 2. Naming

- Use lowercase letters.
- Separate words with hyphens.
- Keep branch names within 30 characters.
- Do not use special characters.

### 3. Change synchronization

- Rebase onto `default` regularly.
- Resolve conflicts in the working branch.

### 4. Cleanup

- Delete merged branches.
- Archive experimental branches if any remain.
- Delete stale branches regularly.

## Change merge procedure

Changes are made according to this workflow:

1. Create a branch from `default`.
2. Work on the current task and commit the changes.
3. Create a merge or pull request.
4. Conduct code review and CI/CD checks.
5. Rebase onto the latest `default`.
6. Squash commits if necessary.
7. Obtain maintainer approval for the merge.
8. Merge using the fast-forward strategy.
