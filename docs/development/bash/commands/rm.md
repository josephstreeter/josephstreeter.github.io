---
title: rm Command
description: Comprehensive reference for the rm command in Bash, including safe deletion patterns, recursive removal, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `rm` command removes files and directories.
It is powerful and irreversible in normal usage, so safe option selection and path validation are essential.

## Overview

Use `rm` when you need to:

- Delete one or more files
- Remove directory trees recursively
- Clean build artifacts and temporary files
- Perform controlled cleanup in automation scripts

## Syntax

```bash
rm [options] file...
rm [options] directory...
```

Common forms:

```bash
# Remove a single file
rm old.log

# Prompt before each removal
rm -i important.txt

# Recursively remove a directory tree
rm -r build/
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-i` | Prompt before every removal | `rm -i file.txt` |
| `-I` | Prompt once before removing many files | `rm -I *.tmp` |
| `-f` | Force removal; ignore nonexistent files; never prompt | `rm -f stale.pid` |
| `-r`, `-R` | Recursive removal for directories | `rm -r dist/` |
| `-d` | Remove empty directories | `rm -d emptydir` |
| `-v` | Verbose output | `rm -rv old-cache/` |
| `--` | End option parsing for unusual filenames | `rm -- -strange-file` |

## Core Semantics

- By default, `rm` removes files, not directories.
- Removing directories requires `-r` (or `-R`) unless directory is empty and `-d` is used.
- `rm` does not move items to a recycle bin.
- `-f` suppresses many safety checks and prompts.

## Safe Deletion Patterns

Preview before delete:

```bash
ls -la *.log
rm -i *.log
```

Use explicit path anchors for recursive deletes:

```bash
rm -rf -- ./build
```

Handle filenames beginning with `-` safely:

```bash
rm -- -example-file
```

## Examples

```bash
# Remove a single file
rm notes.txt
```

```bash
# Interactive delete for critical files
rm -i production.env
```

```bash
# Remove empty directory only
rm -d old-empty-folder
```

```bash
# Recursive delete with verbosity
rm -rv ./tmp/cache/
```

```bash
# Force delete generated artifacts
rm -rf ./dist ./coverage
```

```bash
# Delete files by extension in current directory
rm -i -- *.bak
```

## Script Guidance

Safer cleanup in scripts:

```bash
target_dir="./build"
if [[ -d "$target_dir" ]]; then
	rm -rf -- "$target_dir"
fi
```

Recommendations:

1. Validate variables before passing to `rm`.
2. Prefer explicit paths (`./dir`) over ambiguous relative values.
3. Avoid constructing dangerous commands from untrusted input.

## Troubleshooting

### `rm: cannot remove 'dir': Is a directory`

Cause: Attempted to remove directory without recursive option.

Fix:

```bash
rm -r dir
```

### `Permission denied`

Cause: Missing write/execute permission on parent directory or file restrictions.

Fixes:

- Check permissions with `ls -ld` and `ls -l`
- Adjust ownership/permissions if appropriate
- Use elevated privileges only when required

### Deleted wrong files

Cause: Broad glob or incorrect path.

Prevention:

- Preview with `ls` or `find` first
- Use interactive mode for risky operations
- Keep backups for important data

## Notes

Use caution with `rm -rf`.
Many teams adopt aliases such as `rm='rm -i'` for interactive shells, but scripts should be explicit and predictable.

For command details and implementation-specific behavior, run:

```bash
man rm
rm --help
```

## Related Commands

- [ls](ls.md)
- [find](find.md)
- [cp](cp.md)
- [mv](mv.md)
- [mkdir](mkdir.md)
