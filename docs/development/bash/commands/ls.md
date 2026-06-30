---
title: ls Command
description: Comprehensive reference for the ls command in Bash, including common options, sorting, filtering, and practical listing patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `ls` command lists directory contents.
It is one of the most frequently used commands for inspecting files, permissions, sizes, and timestamps.

## Overview

Use `ls` when you need to:

- View files and directories in a path
- Inspect file metadata in long format
- Include hidden files in listings
- Sort results by time, size, or name
- Produce machine-friendlier output with one entry per line

## Syntax

```bash
ls [options] [path...]
```

Common forms:

```bash
# List current directory
ls

# Long listing with hidden files
ls -la

# Human-readable long listing
ls -lh

# List a specific path
ls /var/log
```

If no path is provided, `ls` lists the current working directory.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-l` | Long listing format (permissions, owner, size, time) | `ls -l` |
| `-a` | Include hidden files (`.` prefixed) | `ls -a` |
| `-h` | Human-readable sizes (use with `-l`) | `ls -lh` |
| `-t` | Sort by modification time (newest first) | `ls -lt` |
| `-S` | Sort by file size (largest first) | `ls -lS` |
| `-r` | Reverse sort order | `ls -ltr` |
| `-R` | Recursive listing through subdirectories | `ls -R` |
| `-d` | List directories themselves, not contents | `ls -ld /etc` |
| `-1` | One entry per line | `ls -1` |
| `-F` | Append type indicator (`/`, `*`, `@`, etc.) | `ls -F` |
| `-p` | Append `/` to directories | `ls -p` |
| `-i` | Show inode numbers | `ls -li` |
| `-A` | Almost all (exclude `.` and `..`) | `ls -A` |
| `--color=auto` | Colorize output (GNU ls) | `ls --color=auto` |

## Understanding Long Format

Example output:

```text
-rw-r--r-- 1 user group  4096 Jun 30 10:15 app.log
drwxr-xr-x 5 user group  4096 Jun 30 09:00 scripts
```

Fields in order:

1. File type and permissions
2. Link count
3. Owner
4. Group
5. Size in bytes
6. Timestamp (usually modification time)
7. File or directory name

## Hidden Files and Directory Entries

- `ls -a` includes hidden files and also shows `.` and `..`
- `ls -A` includes hidden files but omits `.` and `..`

Common pattern:

```bash
ls -la
```

## Sorting and Filtering Patterns

Sort by newest first:

```bash
ls -lt
```

Sort by oldest first:

```bash
ls -ltr
```

Sort by size:

```bash
ls -lS
```

Show only directories in current path:

```bash
ls -d */
```

Show markdown files sorted by time:

```bash
ls -lt *.md
```

## Examples

```bash
# Human-readable long listing including hidden entries
ls -lah
```

```bash
# Recursive listing from current directory
ls -R
```

```bash
# List directory metadata only (not its children)
ls -ld /home
```

```bash
# One entry per line for easier scripting
ls -1
```

```bash
# Show inode numbers and metadata
ls -li
```

```bash
# Show file type indicators
ls -F
```

## Safe Usage Guidelines

1. Quote paths with spaces: `ls -l "My Folder"`.
2. Use `-1` or null-delimited alternatives in scripts when parsing output.
3. Prefer explicit globs (`*.log`) over broad recursive listings in large trees.
4. Use `ls -ld dir` when you want directory metadata, not contents.

## Scripting and Reliability Notes

Parsing plain `ls` output in scripts can be fragile (spaces, locale, color).
For robust file iteration, prefer tools such as `find`.

Example robust listing:

```bash
find . -maxdepth 1 -type f -print
```

## Portability Notes

- GNU and BSD `ls` support slightly different flags and defaults.
- `--color=auto` is GNU-specific.
- On macOS and BSD systems, color and date formatting options differ.

## Troubleshooting

### `ls: cannot access 'path': No such file or directory`

Cause: Path typo or current directory mismatch.

Fix:

```bash
pwd
ls -la
ls ./relative/path
```

### Hidden files are missing

Cause: Default listing excludes dotfiles.

Fix:

```bash
ls -la
```

### Colors are not shown

Cause: Color may be disabled, unsupported, or alias missing.

Fix:

```bash
ls --color=auto
```

### Recursive listing is too large

Cause: `-R` traverses all subdirectories.

Fix:

- Narrow the path scope
- Use `find` with depth limits

## Notes

`ls` is ideal for quick interactive inspection.
For advanced querying, filtering, and automation, combine `find`, `stat`, and `grep`.

For command details and implementation-specific behavior, run:

```bash
man ls
ls --help
```

## Related Commands

- [find](find.md)
- [touch](touch.md)
- [cp](cp.md)
- [mv](mv.md)
- [rm](rm.md)
