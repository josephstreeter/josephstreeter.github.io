---
title: cp Command
description: Comprehensive reference for the cp command in Bash, including syntax, options, recursive copy behavior, and safe usage patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `cp` command copies files and directories.
It is one of the core file management commands used for backups, staging, and deployment workflows.

## Overview

Use `cp` when you need to:

- Copy one or more files to a destination file or directory
- Recursively copy directory trees
- Preserve metadata such as timestamps, ownership, and permissions
- Interactively confirm overwrites
- Create simple local backups

## Syntax

```bash
cp [options] source... destination
```

Common forms:

```bash
# Copy one file to a new file
cp source.txt dest.txt

# Copy one or more files into a directory
cp a.txt b.txt ./backup/

# Recursively copy a directory
cp -r ./src ./backup/
```

## Core Copy Semantics

- If destination is a file path, one source file is copied to that file.
- If destination is an existing directory, each source is copied into it.
- Copying directories requires `-r` (or `-R`).
- Existing destination files may be overwritten unless prevented by options.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-r`, `-R` | Copy directories recursively | `cp -r src/ backup/` |
| `-a` | Archive mode (recursive + preserve metadata/symlinks) | `cp -a app/ app.bak/` |
| `-p` | Preserve mode, ownership, timestamps | `cp -p file.txt backup.txt` |
| `-i` | Prompt before overwrite | `cp -i file.txt dest.txt` |
| `-n` | Do not overwrite existing files | `cp -n *.conf backup/` |
| `-u` | Copy only when source is newer or dest missing | `cp -u *.json cache/` |
| `-v` | Verbose output | `cp -av src/ backup/` |
| `-f` | Force copy by removing destination if needed | `cp -f file.txt dest.txt` |
| `-t DIR` | Specify destination directory first (GNU cp) | `cp -t backup file1 file2` |
| `--parents` | Preserve source path under destination (GNU cp) | `cp --parents src/a.txt out/` |

## Recursive Copy Details

Directory copies can be subtle depending on trailing slashes and destination state.

Examples:

```bash
# If backup/ exists, creates backup/src/...
cp -r src backup/
```

```bash
# If backup/ does not exist, creates backup as a copy of src
cp -r src backup
```

```bash
# Copy only contents of src into existing backup/
cp -r src/. backup/
```

`src/.` is a reliable pattern when you want the directory contents,
not an additional nested `src` directory.

## Preservation and Attributes

Use `-a` for best-effort full preservation in local copies.

Archive mode generally implies:

- Recursive copy
- Preserve symlinks as symlinks
- Preserve permissions, ownership, timestamps
- Preserve special files where possible

For simpler preservation needs, `-p` is often sufficient.

## Symlink Behavior

Default behavior can vary with options and platform:

- `-a` typically preserves symlinks (does not dereference)
- `-L` dereferences symlinks (copy target content)
- `-P` never dereferences symlinks

Example:

```bash
# Copy symlink target contents instead of symlink itself
cp -RL linked-dir/ backup/
```

## Examples

```bash
# Copy one file
cp appsettings.json appsettings.backup.json
```

```bash
# Copy multiple files into directory
cp nginx.conf app.conf ./backup/
```

```bash
# Recursive copy with verbose output
cp -r src/ backup/
```

```bash
# Recursive archive backup (recommended for local backup copies)
cp -av ./project ./project.bak
```

```bash
# Prompt before overwrite
cp -i report.txt ./archive/report.txt
```

```bash
# Skip files that already exist
cp -n *.md ./staging/
```

```bash
# Update destination only when source is newer
cp -u build/*.js public/
```

```bash
# Preserve source path under destination (GNU cp)
cp --parents docs/development/bash/commands/cp.md ./snapshot/
```

## Safe Usage Guidelines

1. Use `-i` or `-n` when copying into directories with important data.
2. Prefer `-a` for backups to preserve metadata and symlink behavior.
3. Validate destination paths before recursive copies.
4. Use `-v` for visibility in scripts and manual operations.
5. Test with a small subset before copying very large trees.

## Performance and Operational Tips

1. For huge trees or repeated syncs, `rsync` is often faster and more controllable.
2. Use filesystem-local copies when possible for better performance.
3. Combine with `find` for selective copy workflows.

Example selective copy:

```bash
find ./logs -type f -name '*.log' -mtime -1 -exec cp -t ./recent-logs {} +
```

## Portability Notes

- GNU `cp` and BSD `cp` differ in some flags and semantics.
- `-a`, `--parents`, and `-t` are common GNU conveniences.
- On non-GNU systems, use portable alternatives when scripting across environments.

## Troubleshooting

### `cp: -r not specified; omitting directory`

Cause: Attempted to copy a directory without recursive option.

Fix:

```bash
cp -r source-dir destination-dir
```

### `Permission denied`

Cause: Missing read permission on source or write permission on destination.

Fixes:

- Check permissions with `ls -l`
- Copy to a writable location or adjust permissions
- Use `sudo` only when appropriate

### Existing files were overwritten unexpectedly

Cause: Default behavior permits overwrite.

Fix:

- Use `-i` (prompt) or `-n` (no-clobber)
- Keep backups with naming conventions like `*.bak`

## Notes

`cp` is ideal for straightforward local copy operations.
For robust synchronization, deletion mirroring, and remote transfer,
`rsync` is usually the better tool.

For command details and implementation-specific behavior, run:

```bash
man cp
cp --help
```

## Related Commands

- [mv](mv.md)
- [mkdir](mkdir.md)
- [rm](rm.md)
- [find](find.md)
- [touch](touch.md)
