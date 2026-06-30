---
title: find Command
description: Comprehensive reference for the find command in Bash, including tests, actions, operators, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/25/2026
ms.topic: reference
ms.service: development
---

The `find` command recursively searches directories and evaluates each file path against an expression you define.
It is one of the most important Linux tools for file discovery, cleanup tasks, and automation pipelines.

## Overview

Use `find` when you need to:

- Locate files by name, type, size, age, owner, or permissions
- Execute actions on matched files (for example, delete, move, or run another command)
- Build reliable automation with null-safe output for paths that contain spaces
- Combine search criteria using logical operators for precise matching

## Syntax

```bash
find [path...] [expression]
```

The command has two major parts:

1. `path...`: One or more starting directories (for example, `.`, `/var/log`, `/home/user`).
2. `expression`: Tests, actions, options, and operators evaluated left to right.

If you omit the path, `find` defaults to the current directory (`.`).

## Core Concepts

### Common Tests

| Test | Purpose | Example |
| --- | --- | --- |
| `-name` | Case-sensitive filename match (glob pattern) | `-name "*.log"` |
| `-iname` | Case-insensitive filename match | `-iname "readme.md"` |
| `-type` | Match file type (`f`, `d`, `l`, etc.) | `-type f` |
| `-size` | Match by size (`k`, `M`, `G`) | `-size +100M` |
| `-mtime` | Modified time in days | `-mtime -7` |
| `-mmin` | Modified time in minutes | `-mmin -30` |
| `-user` | Match file owner | `-user root` |
| `-group` | Match group owner | `-group developers` |
| `-perm` | Match permissions | `-perm 644` |

### Common Actions

| Action | Purpose | Example |
| --- | --- | --- |
| `-print` | Print matching path (default in many cases) | `-print` |
| `-print0` | Print null-delimited paths (safe for scripting) | `-print0` |
| `-delete` | Delete matches | `-type f -name "*.tmp" -delete` |
| `-exec` | Run command per match | `-exec rm -f {} \;` |
| `-exec ... +` | Run command in batches | `-exec rm -f {} +` |
| `-ls` | Print long listing style output | `-ls` |

### Logical Operators

| Operator | Meaning | Notes |
| --- | --- | --- |
| `-a` | Logical AND | Default between adjacent terms |
| `-o` | Logical OR | Use parentheses to control precedence |
| `!` | Logical NOT | Negates the next test/expression |
| `( ... )` | Group expression | Escape in shell: `\(` and `\)` |

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-maxdepth N` | Limit recursion depth | `-maxdepth 2` |
| `-mindepth N` | Skip top levels before matching | `-mindepth 1` |
| `-xdev` | Stay on one filesystem | `-xdev` |
| `-L` | Follow symbolic links | `-L` |
| `-P` | Do not follow symbolic links (default) | `-P` |
| `-H` | Follow symlinks listed on command line | `-H` |

## Examples

```bash
find . -type f -name "*.md"
```

```bash
# Find directories named .git and prune them from traversal
find . -type d -name ".git" -prune -o -type f -name "*.md" -print
```

```bash
# Find files modified in the last 24 hours
find /var/log -type f -mtime -1
```

```bash
# Find files larger than 500 MB
find /data -type f -size +500M
```

```bash
# Find empty files and directories
find . -empty
```

```bash
# Safe pipeline: null-delimited output to xargs
find . -type f -name "*.log" -print0 | xargs -0 grep -n "ERROR"
```

```bash
# Batch-delete temporary files safely
find . -type f -name "*.tmp" -exec rm -f {} +
```

```bash
# Delete empty directories (review first without -delete)
find . -type d -empty
find . -type d -empty -delete
```

## Safe Usage Guidelines

1. Start with a non-destructive preview command before using `-delete`.
2. Prefer `-print0` with `xargs -0` for whitespace-safe scripting.
3. Use `-maxdepth` and `-mindepth` to prevent accidental broad scans.
4. Use `-xdev` when scanning system paths to avoid crossing mounted filesystems.
5. Quote glob patterns (`"*.log"`) so the shell does not expand them before `find` runs.

## Performance Tips

1. Restrict the search path to the smallest practical subtree.
2. Put cheap and highly selective tests early in expressions.
3. Use pruning (`-prune`) to skip large directories such as dependency caches.
4. Prefer `-exec ... +` to reduce process creation overhead versus one command per file.

## Troubleshooting

### "paths must precede expression"

Cause: The shell expanded a wildcard before `find` parsed the expression.

Fix: Quote patterns, for example `-name "*.txt"`.

### Permission denied errors

Cause: The current user cannot read parts of the tree.

Fix: Run with elevated permissions if appropriate (`sudo`) or suppress noise:

```bash
find / -type f -name "*.conf" 2>/dev/null
```

### Expression logic returns unexpected matches

Cause: `-o` precedence and implicit `-a` can be confusing.

Fix: Group logic explicitly:

```bash
find . \( -name "*.md" -o -name "*.txt" \) -type f
```

## Notes

`find` behavior is provided by GNU findutils on most Linux distributions.
Run `man find` for full platform-specific details.

## Related Commands

- [grep](grep.md)
- [sed](sed.md)
- [awk](awk.md)
- [xargs in text-processing reference](../text-processing-and-search.md)
