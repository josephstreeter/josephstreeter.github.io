---
title: pgrep Command
description: Comprehensive guide to pgrep for locating process IDs by name and pattern.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `pgrep` command searches running processes and prints matching PIDs.

It is safer and cleaner than parsing `ps` output with `grep` in many cases.

## Overview

You can match by:

- Process name
- Full command line
- User
- Parent PID
- Terminal

## Syntax

```bash
pgrep [options] pattern
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `pgrep nginx` | Find PIDs with name matching nginx |
| `pgrep -x nginx` | Exact name match |
| `pgrep -f "python app.py"` | Match full command line |
| `pgrep -u root` | Match processes owned by root |
| `pgrep -af nginx` | Show PID and full command |

## Core Workflows

### Find PID by Name

```bash
pgrep sshd
pgrep -x sshd
```

### Match Full Command Line

```bash
pgrep -f "node server.js"
```

### Include Process Details

```bash
pgrep -af nginx
```

This prints PID and command line, which helps validate matches.

### Restrict by User

```bash
pgrep -u www-data -af php-fpm
```

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `-f` | Match against full command line |
| `-x` | Require exact process name match |
| `-a` | Print full command line with PID |
| `-u` | Match by effective user ID/name |
| `-P` | Match by parent PID |
| `-n` | Only newest matching process |
| `-o` | Only oldest matching process |

## Examples

```bash
pgrep -af nginx
pgrep -u root sshd
pgrep -n -f "python worker.py"
```

## Troubleshooting

### Too Many Matches

Tighten criteria with `-x`, `-u`, or a more specific `-f` pattern.

### No Matches Found

1. Confirm process is running with `ps aux`.
2. Try `-f` if command name differs from executable name.
3. Check user context with `-u`.

## Best Practices

1. Prefer `pgrep` over `ps | grep` in scripts.
2. Use `-a` when validating patterns interactively.
3. Combine with `kill` only after confirming the matched command lines.
4. Use `-x` for exact service names where possible.

## Related Commands

- `pkill`: Signal matching processes directly
- `ps`: Inspect process table details
- `kill`: Signal specific PIDs
