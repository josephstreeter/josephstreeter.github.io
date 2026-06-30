---
title: touch Command
description: Comprehensive reference for the touch command in Bash, including timestamp control, file creation behavior, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `touch` command updates file access and modification timestamps, and can create files that do not already exist.
It is commonly used in build automation, file initialization, and timestamp management.

## Overview

Use `touch` when you need to:

- Create empty files quickly
- Update modification/access times to current time
- Apply specific timestamps to files
- Align timestamps between files

## Syntax

```bash
touch [options] file...
```

Common forms:

```bash
# Create file if it does not exist, else update timestamp
touch notes.txt

# Update timestamp without creating a new file
touch -c existing.txt

# Set explicit timestamp
touch -t 202606301200.00 report.txt
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-a` | Change access time only | `touch -a file.txt` |
| `-m` | Change modification time only | `touch -m file.txt` |
| `-c`, `--no-create` | Do not create file if missing | `touch -c maybe.txt` |
| `-d STRING` | Parse date/time string (GNU) | `touch -d '2026-06-30 12:00' file.txt` |
| `-t STAMP` | Use [[CC]YY]MMDDhhmm[.ss] format | `touch -t 202606301200 file.txt` |
| `-r FILE` | Use timestamps from reference file | `touch -r src.txt dst.txt` |

## Timestamp Basics

`touch` manages:

- `atime`: last access time
- `mtime`: last modification time

By default, both are set to current time (or file is created if missing).

## Examples

```bash
# Create one empty file
touch todo.md
```

```bash
# Create multiple files at once
touch file1.txt file2.txt file3.txt
```

```bash
# Update only modification time
touch -m app.log
```

```bash
# Update only access time
touch -a app.log
```

```bash
# Set timestamp from explicit date/time (GNU)
touch -d '2026-06-30 08:30:00' report.csv
```

```bash
# Copy timestamps from another file
touch -r source.bin target.bin
```

```bash
# Do not create missing files
touch -c maybe-missing.txt
```

## Build and Automation Use Cases

Trigger make-style rebuild behavior by changing mtime:

```bash
touch src/main.c
```

Initialize expected marker files:

```bash
mkdir -p .state
touch .state/initialized
```

## Safe Usage Guidelines

1. Use `-c` in scripts when file creation is not desired.
2. Prefer explicit timestamps (`-t` or `-d`) for reproducible workflows.
3. Verify timezone expectations in CI environments.
4. Do not rely on timestamps alone for security-sensitive logic.

## Troubleshooting

### `touch: cannot touch 'file': No such file or directory`

Cause: Parent directory does not exist.

Fix:

```bash
mkdir -p parent
touch parent/file.txt
```

### Timestamp did not change as expected

Possible causes:

- Filesystem mount behavior (atime policies)
- Option used (`-a` vs `-m`)
- Incorrect date format

Fixes:

- Validate with `ls -l` and `stat`
- Use explicit options and known timestamp format

### File was created unexpectedly

Cause: Default behavior creates missing files.

Fix:

```bash
touch -c file-that-may-not-exist
```

## Notes

`touch` is lightweight but important for deterministic automation.
Timestamp semantics can vary slightly by filesystem and operating system.

For command details and implementation-specific behavior, run:

```bash
man touch
touch --help
```

## Related Commands

- [ls](ls.md)
- [mkdir](mkdir.md)
- [cp](cp.md)
- [mv](mv.md)
- [find](find.md)
