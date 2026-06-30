---
title: mv Command
description: Comprehensive reference for the mv command in Bash, including rename semantics, overwrite controls, and practical move workflows.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `mv` command moves or renames files and directories.
It is commonly used to reorganize directory trees, archive files, and perform in-place renames.

## Overview

Use `mv` when you need to:

- Rename a file or directory
- Move one or more files into a directory
- Reorganize project structures
- Apply safe overwrite controls during file moves

## Syntax

```bash
mv [options] source... destination
```

Common forms:

```bash
# Rename a file
mv old-name.txt new-name.txt

# Move files into a directory
mv app.log error.log ./archive/

# Rename directory
mv old-dir new-dir
```

## Core Semantics

- If destination is a non-existing path with one source, `mv` renames source to that path.
- If destination is an existing directory, sources are moved into it.
- Moving within the same filesystem is typically a metadata rename (fast).
- Moving across filesystems may copy data then remove source (slower).

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-i` | Prompt before overwrite | `mv -i report.txt archive/` |
| `-n` | Do not overwrite existing files | `mv -n *.conf backup/` |
| `-f` | Force overwrite without prompt | `mv -f build.out latest.out` |
| `-v` | Verbose output | `mv -v *.log archive/` |
| `-t DIR` | Specify destination directory first (GNU mv) | `mv -t archive file1 file2` |
| `-u` | Move only when source is newer or destination missing | `mv -u *.json staging/` |

Option precedence note (GNU coreutils):

- If conflicting overwrite options are provided (`-i`, `-n`, `-f`), the last one typically wins.

## Rename vs Move Examples

Rename single file:

```bash
mv draft.md final.md
```

Rename directory:

```bash
mv service-old service-new
```

Move multiple files into target directory:

```bash
mv *.log ./archive/
```

## Practical Examples

```bash
# Prompt before replacing existing file
mv -i config.new.yml config.yml
```

```bash
# Move all markdown files to docs
mv *.md docs/
```

```bash
# Verbose reorganization of output artifacts
mv -v build/* release/
```

```bash
# Move with destination first (GNU)
mv -t archive app.log.1 app.log.2 app.log.3
```

```bash
# Skip overwriting existing files
mv -n *.txt ./imported/
```

```bash
# Rename files by replacing spaces with underscores (Bash loop)
for f in *\ *; do
  mv -v "$f" "${f// /_}"
done
```

## Safe Usage Guidelines

1. Use `-i` when moving into directories with important data.
2. Quote paths with spaces and special characters.
3. Use `-v` in scripts and maintenance sessions for auditability.
4. Test globs before moving (`printf '%s\n' *.log`).
5. Use `-n` to avoid accidental overwrite in bulk operations.

## Cross-Filesystem Considerations

When source and destination are on different filesystems:

- Move may take significantly longer (copy + delete behavior)
- Metadata preservation and permissions can vary by filesystem
- Interruptions can leave partial state

For large and resumable migrations, consider `rsync` followed by cleanup.

## Portability Notes

- GNU and BSD `mv` differ in available options.
- `-t` is a GNU convenience and may not exist on BSD/macOS.
- For portable scripts, prefer standard positional form:

```bash
mv file1 file2 destination_dir/
```

## Troubleshooting

### `mv: cannot move ... to ...: Not a directory`

Cause: Multiple sources provided but destination is not an existing directory.

Fix:

```bash
mkdir -p destination_dir
mv file1 file2 destination_dir/
```

### `mv: cannot stat ...: No such file or directory`

Cause: Source path typo, unmatched glob, or wrong working directory.

Fix:

```bash
pwd
ls -la
```

### Existing files were replaced unexpectedly

Cause: Default behavior allows overwrite in many cases.

Fix:

- Use `-i` for interactive confirmation
- Use `-n` for no-clobber behavior

### `Permission denied`

Cause: Missing write permission in source parent or destination directory.

Fixes:

- Check permissions with `ls -ld` on relevant directories
- Move to a writable location
- Use elevated privileges only when justified

## Notes

`mv` is fast and simple for local reorganizations.
For complex bulk renames, consider shell loops or dedicated rename utilities.

For command details and implementation-specific behavior, run:

```bash
man mv
mv --help
```

## Related Commands

- [cp](cp.md)
- [rm](rm.md)
- [mkdir](mkdir.md)
- [ls](ls.md)
- [find](find.md)
