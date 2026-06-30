---
title: mkdir Command
description: Comprehensive reference for the mkdir command in Bash, including syntax, options, permissions, and practical directory-creation patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `mkdir` command creates directories.
It is used in scripts and interactive workflows to prepare folder structures for logs, outputs, builds, and deployment artifacts.

## Overview

Use `mkdir` when you need to:

- Create one or more directories
- Create nested directory paths in a single command
- Set directory permissions at creation time
- Build predictable project or environment folder structures

## Syntax

```bash
mkdir [options] directory...
```

Common forms:

```bash
# Create one directory
mkdir reports

# Create multiple directories
mkdir logs tmp cache

# Create nested path safely
mkdir -p logs/archive/2026
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-p` | Create parent directories as needed; no error if directory exists | `mkdir -p app/data/cache` |
| `-m MODE` | Set directory permissions (mode) explicitly | `mkdir -m 750 secure` |
| `-v` | Verbose output for each created directory | `mkdir -pv out/reports/weekly` |

## Behavior Notes

- Without `-p`, parent directories must already exist.
- Without `-p`, existing target directories cause an error.
- New directory permissions are affected by the process `umask` unless `-m` is used.
- `mkdir` creates directories only; it does not create files.

## Permissions and umask

By default, permissions are derived from the requested mode and the active `umask`.

Examples:

```bash
# Create with explicit permissions
mkdir -m 700 private-data
```

```bash
# Check current umask value
umask
```

Typical secure patterns:

- `700` for private directories
- `750` for owner/group read-execute access

## Examples

```bash
# Create a single directory
mkdir backup
```

```bash
# Create several directories at once
mkdir bin config data
```

```bash
# Create nested directory tree
mkdir -p var/log/myapp/archive
```

```bash
# Create directory with explicit mode
mkdir -m 755 public-assets
```

```bash
# Verbose nested creation
mkdir -pv build/output/release
```

```bash
# Brace expansion for multiple environment folders
mkdir -p environments/{dev,test,prod}/logs
```

```bash
# Create date-based folder
mkdir -p "backups/$(date +%F)"
```

## Safe Usage Guidelines

1. Use `-p` in scripts to avoid failures when parents are missing.
2. Quote paths that may contain spaces.
3. Use explicit `-m` for security-sensitive directories.
4. Validate variables in scripts before path expansion.

## Scripting Patterns

Idempotent setup:

```bash
mkdir -p ./artifacts ./artifacts/logs ./artifacts/reports
```

Create per-service directory structure:

```bash
for service in api worker web; do
  mkdir -p "services/$service"/{config,logs,tmp}
done
```

## Portability Notes

- `-p` and `-m` are widely available across GNU and BSD systems.
- Brace expansion is a shell feature (Bash/Zsh), not a `mkdir` feature.
- Permission semantics still depend on platform and filesystem.

## Troubleshooting

### `mkdir: cannot create directory ... No such file or directory`

Cause: Parent path does not exist and `-p` was not used.

Fix:

```bash
mkdir -p parent/child/grandchild
```

### `mkdir: cannot create directory ... File exists`

Cause: Target directory already exists.

Fix:

- Use `-p` for idempotent operations
- Choose a different name when duplication is not intended

### `Permission denied`

Cause: Missing write permission in parent directory.

Fixes:

- Check ownership and permissions with `ls -ld parent`
- Create the directory in a writable location
- Use elevated privileges only when appropriate

## Notes

`mkdir` is foundational for repeatable environment setup.
Combining `mkdir -p` with predictable directory conventions improves script reliability.

For command details and implementation-specific behavior, run:

```bash
man mkdir
mkdir --help
```

## Related Commands

- [ls](ls.md)
- [mv](mv.md)
- [cp](cp.md)
- [rm](rm.md)
- [touch](touch.md)
