---
title: ps Command
description: Comprehensive guide to ps for listing and filtering Linux processes.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `ps` command displays process information from the process table.

It is commonly used for:

- Viewing running processes
- Checking CPU and memory usage
- Filtering for specific users or commands
- Finding process IDs before signaling with `kill` or `pkill`

## Overview

There are two widely used syntax styles:

- UNIX style options: `ps -ef`
- BSD style options: `ps aux`

Both are valid on most Linux systems.

## Syntax

```bash
ps [options]
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `ps aux` | Full process list in BSD format |
| `ps -ef` | Full process list in UNIX format |
| `ps -u <user>` | Show processes for a user |
| `ps -p <pid>` | Show one process by PID |
| `ps -C <name>` | Show processes by exact command name |
| `ps -eo ...` | Custom output columns |

## Core Workflows

### List All Processes

```bash
ps aux
ps -ef
```

### Filter by User or Command

```bash
ps -u root
ps -C nginx
ps aux | grep sshd
```

### Inspect Specific Process IDs

```bash
ps -p 1234
ps -fp 1234
```

`-f` adds full-format details (UID, PID, PPID, start time, command).

### Custom Output Columns

```bash
ps -eo pid,ppid,user,%cpu,%mem,etime,cmd --sort=-%cpu
```

This is useful when building repeatable diagnostics.

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `a` | Show processes for all users (BSD style) |
| `u` | User-oriented output |
| `x` | Include processes without a controlling terminal |
| `-e` | Select all processes |
| `-f` | Full format listing |
| `-o` | Custom output format |
| `--sort` | Sort by field |
| `-p` | Select specific PID(s) |

## Examples

```bash
ps aux
ps -ef
ps -eo pid,user,%cpu,%mem,cmd --sort=-%mem | head
```

## Troubleshooting

### grep Matches Itself

`ps aux | grep nginx` may include the `grep` process line.

Safer alternatives:

```bash
pgrep -af nginx
ps -C nginx -f
```

### Output Differences Across Systems

Some column names and defaults vary by distro and procps version.
Use explicit output format (`-o`) for stable automation.

## Best Practices

1. Prefer explicit output columns for scripts (`ps -eo ...`).
2. Use `pgrep` when your goal is PID lookup by name/pattern.
3. Combine with `head`, `sort`, and `grep` for focused diagnostics.
4. Avoid parsing human-formatted defaults in automation.

## Related Commands

- `pgrep`: Find process IDs by name/pattern
- `kill`: Send signals to specific PIDs
- `pkill`: Send signals by process name/pattern
- `top` or `htop`: Interactive process monitoring
