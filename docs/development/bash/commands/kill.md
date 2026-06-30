---
title: kill Command
description: Comprehensive guide to kill for sending signals to Linux processes.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `kill` command sends a signal to one or more process IDs (PIDs).

Despite the name, it is not only for terminating processes.
It can also request reloads, interrupt jobs, or trigger custom signal handlers.

## Overview

Common signal usage:

- `SIGTERM` (15): graceful stop request (default)
- `SIGKILL` (9): immediate forced termination
- `SIGHUP` (1): often used to reload configuration
- `SIGINT` (2): interrupt signal (like Ctrl+C)

## Syntax

```bash
kill [options] pid...
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `kill <pid>` | Send default signal (TERM) |
| `kill -TERM <pid>` | Graceful terminate |
| `kill -KILL <pid>` | Force terminate |
| `kill -HUP <pid>` | Request reload behavior |
| `kill -l` | List available signals |

## Core Workflows

### Graceful Termination (Preferred)

```bash
kill 12345
kill -TERM 12345
```

### Force Termination (Last Resort)

```bash
kill -KILL 12345
```

Use only when the process does not respond to `TERM`.

### Signal Multiple Processes

```bash
kill -TERM 1234 5678 9012
```

### View Signal Names

```bash
kill -l
```

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `-s <signal>` | Specify signal by name |
| `-SIGNAL` | Specify signal by shorthand |
| `-l` | List signal names |

## Examples

```bash
kill -TERM 12345
kill -HUP 2211
kill -KILL 4242
```

## Troubleshooting

### Operation Not Permitted

You can only signal processes you own unless using elevated privileges.

```bash
sudo kill -TERM <pid>
```

### No Such Process

The PID may have exited already or changed.
Re-check with:

```bash
ps -fp <pid>
```

## Best Practices

1. Try `TERM` before `KILL`.
2. Confirm target PID carefully to avoid affecting the wrong process.
3. Use `pgrep` to locate PIDs reliably by name.
4. Prefer service managers (`systemctl`) for managed services.

## Related Commands

- `ps`: Inspect processes by PID
- `pgrep`: Find matching PIDs
- `pkill`: Signal by process pattern
- `systemctl`: Control systemd-managed services
