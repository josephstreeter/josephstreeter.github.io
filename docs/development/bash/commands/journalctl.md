---
title: journalctl Command
description: Comprehensive guide to journalctl for querying and filtering systemd journal logs.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `journalctl` command reads logs from the systemd journal.

It provides structured and filterable access to logs for services, boot sessions,
kernel events, and system components.

## Overview

`journalctl` is commonly used to:

- Troubleshoot service startup failures
- Follow live logs
- Filter logs by unit, time, priority, or boot ID
- Correlate incidents across restarts

## Syntax

```bash
journalctl [options]
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `journalctl` | Show full journal |
| `journalctl -u <unit>` | Show logs for a specific unit |
| `journalctl -u <unit> -f` | Follow logs for a unit |
| `journalctl -b` | Logs from current boot |
| `journalctl -b -1` | Logs from previous boot |
| `journalctl --since "1 hour ago"` | Time-based filtering |
| `journalctl -p err..alert` | Filter by priority range |
| `journalctl -k` | Kernel logs |
| `journalctl -n 200` | Show last 200 entries |

## Core Workflows

### Inspect Service Logs

```bash
sudo journalctl -u ssh
sudo journalctl -u nginx -n 200 --no-pager
```

### Follow Logs in Real Time

```bash
sudo journalctl -u docker -f
```

### Investigate Across Boots

```bash
journalctl -b
journalctl -b -1
```

### Filter by Time Window

```bash
journalctl --since "2026-06-05 10:00:00" --until "2026-06-05 11:00:00"
journalctl --since "30 minutes ago"
```

### Filter by Severity

```bash
journalctl -p warning..emerg
```

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `-u <unit>` | Filter by systemd unit |
| `-f` | Follow new entries |
| `-n <count>` | Show last N lines |
| `-b [offset]` | Filter by boot (current or previous) |
| `-p <range>` | Filter by priority |
| `-k` | Kernel messages only |
| `--since` / `--until` | Time-range filtering |
| `-o json` | JSON output format |
| `--no-pager` | Print directly, no pager |

## Examples

```bash
journalctl -u ssh -n 100
journalctl -b -1 -p err..alert --no-pager
journalctl -u nginx --since "1 hour ago"
```

## Troubleshooting

### No Entries Returned

1. Confirm correct unit name with `systemctl status <unit>`.
2. Expand time window (`--since`).
3. Check if logs were rotated/vacuumed.

### Permission Denied

Some journal entries require elevated privileges:

```bash
sudo journalctl -u <unit>
```

### Output Is Too Large

Use `-n`, `--since`, `-u`, and `-p` together to narrow results.

## Best Practices

1. Start with unit and time filters for faster diagnosis.
2. Use `--no-pager` in scripts or log collection jobs.
3. Pair `systemctl status` with `journalctl -u` for full context.
4. Capture previous-boot logs (`-b -1`) after crash recovery.

## Related Commands

- `systemctl`: Check service state and lifecycle
- `dmesg`: Kernel ring buffer output
- `tail`: Follow plain-text log files
- `pgrep` / `pkill`: Find and signal processes by name
