---
title: pkill Command
description: Comprehensive guide to pkill for signaling processes by name or pattern.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `pkill` command sends a signal to processes selected by name or pattern.

It combines process matching (similar to `pgrep`) with signaling behavior (similar to `kill`).

## Overview

By default, `pkill` sends `SIGTERM`.
Use explicit options when you need a different signal or tighter matching.

## Syntax

```bash
pkill [options] pattern
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `pkill nginx` | Send TERM to matching nginx processes |
| `pkill -x nginx` | Exact process name match |
| `pkill -f "python worker.py"` | Match full command line |
| `pkill -HUP nginx` | Send HUP (often reload) |
| `pkill -u www-data php-fpm` | Signal matching processes owned by user |

## Core Workflows

### Graceful Stop by Name

```bash
pkill -TERM -x nginx
```

### Reload a Daemon (When Supported)

```bash
pkill -HUP -x nginx
```

### Signal by Full Command Pattern

```bash
pkill -f "node server.js"
```

### Restrict by User

```bash
pkill -u appuser -f "python worker.py"
```

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `-f` | Match full command line |
| `-x` | Exact process name match |
| `-u` | Match by effective user ID/name |
| `-SIGNAL` | Signal shorthand (example: `-KILL`) |
| `-s <signal>` | Signal by name |
| `-n` | Match newest process only |
| `-o` | Match oldest process only |

## Examples

```bash
pkill -f my-worker
pkill -TERM -x sshd
pkill -KILL -f "stuck-process"
```

## Troubleshooting

### Unexpected Processes Were Signaled

Pattern was too broad. Validate matches first with:

```bash
pgrep -af <pattern>
```

Then tighten with `-x`, `-u`, or a more specific `-f` string.

### Permission Denied

You need ownership of target processes or elevated privileges.

## Best Practices

1. Validate with `pgrep -af` before running broad `pkill` patterns.
2. Prefer graceful signals (`TERM`, `HUP`) before `KILL`.
3. Use exact matching (`-x`) when possible.
4. For system services, prefer `systemctl` over direct signaling.

## Related Commands

- `pgrep`: Preview process matches
- `kill`: Signal specific PIDs
- `systemctl`: Service-oriented control for systemd units
