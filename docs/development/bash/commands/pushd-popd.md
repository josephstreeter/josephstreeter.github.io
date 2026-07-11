---
title: pushd and popd Commands
description: Comprehensive reference for the pushd and popd commands in Bash, including directory stack behavior, options, and practical navigation workflows.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `pushd` and `popd` commands manage a directory stack for fast navigation.
They are shell builtins (not standalone executables) and are most useful in interactive sessions and Bash scripts that need to return to previous locations reliably.

## Overview

Use `pushd` and `popd` when you need to:

- Temporarily change directories and return safely
- Jump between multiple working directories quickly
- Avoid manual `cd` backtracking in scripts
- Build predictable directory navigation flows

Related command:

- `dirs` displays the current directory stack

## Syntax

```bash
pushd [options] [directory]
popd [options] [+N | -N]
dirs [options] [+N | -N]
```

Common forms:

```bash
# Push current directory and switch to target
pushd /tmp

# Return to previous directory
popd

# Show current directory stack
dirs -v
```

## Directory Stack Basics

The stack stores directory paths in order. Conceptually:

- Left-most entry is the current directory
- Additional entries are previous locations

Typical flow:

1. Start in project directory
2. `pushd /tmp` (project directory is pushed, current becomes `/tmp`)
3. Do temporary work
4. `popd` returns to project directory

This pattern is safer than manual `cd` chains in scripts.

## pushd Behavior

`pushd` has two primary modes:

1. With a directory argument: push current directory and switch to the argument.
2. Without arguments: swap the top two entries in the stack.

Examples:

```bash
# Push and change
pushd /var/log
```

```bash
# Swap current directory with previous stack entry
pushd
```

## popd Behavior

`popd` removes stack entries.

- `popd` removes the top entry and changes to the new top
- `popd +N` removes the Nth entry from the left (0-based)
- `popd -N` removes the Nth entry from the right

Examples:

```bash
# Return to previous directory
popd
```

```bash
# Remove second entry from the left
popd +1
```

## dirs Command and Useful Options

Use `dirs` to inspect or format stack output.

| Command | Purpose | Example |
| --- | --- | --- |
| `dirs` | Print stack on one line | `dirs` |
| `dirs -v` | Show stack with index numbers | `dirs -v` |
| `dirs -p` | Print one entry per line | `dirs -p` |
| `dirs -c` | Clear the stack | `dirs -c` |
| `dirs +N` | Show specific stack entry from left | `dirs +0` |
| `dirs -N` | Show specific stack entry from right | `dirs -0` |

Useful Bash options for `pushd`/`popd` behavior:

```bash
# Do not auto-print stack after pushd/popd
pushd -n /tmp

# Enable automatic cd-like behavior with pushd
shopt -s autocd
```

Common shell options related to directory stacks:

- `shopt -s pushd_ignore_dups`: avoid duplicate entries
- `shopt -s pushdminus`: swap meaning of `+N` and `-N`
- `shopt -s pushd_silent`: suppress automatic stack output

## Examples

```bash
# Basic temporary navigation
pushd /etc
ls -la
popd
```

```bash
# Multi-hop stack usage
pushd /var/log
pushd /tmp
dirs -v
popd
popd
```

```bash
# Rotate top two directories quickly
pushd
```

```bash
# Clear directory stack
dirs -c
```

```bash
# Jump to stack item by index (via pushd rotation)
pushd +1
```

## Script Pattern (Safe Return)

A common robust pattern in shell scripts:

```bash
pushd "$target_dir" > /dev/null || exit 1

# Perform work in target directory
make build

popd > /dev/null || exit 1
```

Why this helps:

- Directory return is explicit and predictable
- Works even in nested navigation flows
- Redirection keeps logs cleaner when desired

## Safe Usage Guidelines

1. Quote directory variables: `pushd "$dir"`.
2. In scripts, check for failures and exit early if navigation fails.
3. Pair every `pushd` with a corresponding `popd`.
4. Use `dirs -v` to debug stack state before destructive operations.
5. Avoid clearing stack (`dirs -c`) in shared shell sessions unless intentional.

## Troubleshooting

### `bash: pushd: no other directory`

Cause: Stack has only one entry and `pushd` was called with no argument.

Fix:

- Use `pushd <directory>` first
- Check stack with `dirs -v`

### `bash: popd: directory stack empty`

Cause: `popd` called when stack has no removable entries.

Fix:

- Check stack state using `dirs -v`
- Ensure each `pushd` has one matching `popd`

### Script ends in wrong directory

Cause: Missing or skipped `popd` due to error path.

Fix:

- Add explicit error handling and cleanup
- Use a trap for guaranteed return in complex scripts

Example trap pattern:

```bash
pushd "$target_dir" > /dev/null || exit 1
trap 'popd > /dev/null' EXIT
```

## Notes

`pushd`, `popd`, and `dirs` are shell builtins.
Behavior can vary slightly between shells (Bash, Zsh, Fish), so verify when writing cross-shell scripts.

For Bash-specific details, run:

```bash
help pushd
help popd
help dirs
man bash
```

## Related Commands

- [cd](../index.md)
- [pwd](../index.md)
- [ls](ls.md)
- [mkdir](mkdir.md)
- [find](find.md)
