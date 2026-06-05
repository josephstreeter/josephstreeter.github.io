---
title: systemctl Command
description: Comprehensive guide to systemctl for managing systemd services, targets, and unit states.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `systemctl` command is the main interface for controlling systemd units.

Units include:

- Services (`.service`)
- Timers (`.timer`)
- Sockets (`.socket`)
- Targets (`.target`)
- Mounts (`.mount`)

## Overview

Typical administrative tasks include:

- Starting and stopping services
- Enabling services at boot
- Checking status and failed units
- Reloading configuration
- Managing user and system instances

## Syntax

```bash
systemctl [command] [unit]
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `systemctl status <unit>` | Show service status and recent logs |
| `systemctl start <unit>` | Start a unit |
| `systemctl stop <unit>` | Stop a unit |
| `systemctl restart <unit>` | Restart a unit |
| `systemctl reload <unit>` | Reload configuration without full restart (if supported) |
| `systemctl enable <unit>` | Enable at boot |
| `systemctl disable <unit>` | Disable at boot |
| `systemctl is-active <unit>` | Check if running |
| `systemctl is-enabled <unit>` | Check boot-enable state |
| `systemctl daemon-reload` | Reload unit files after changes |
| `systemctl list-units --type=service` | List active service units |
| `systemctl --failed` | List failed units |

## Core Workflows

### Inspect Service State

```bash
sudo systemctl status ssh
systemctl is-active ssh
systemctl is-enabled ssh
```

### Start, Stop, Restart

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
```

### Reload Config and Unit Definitions

```bash
sudo systemctl reload nginx
sudo systemctl daemon-reload
```

Use `daemon-reload` after modifying files in `/etc/systemd/system`.

### Enable or Disable on Boot

```bash
sudo systemctl enable nginx
sudo systemctl disable nginx
```

### View Failed Units

```bash
systemctl --failed
```

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `--type=service` | Restrict unit listing to services |
| `--all` | Include inactive units in lists |
| `--no-pager` | Print full output without pager |
| `--user` | Operate on user-level units |
| `-l` | Show full lines without truncation |

## Examples

```bash
sudo systemctl status ssh
sudo systemctl restart docker
systemctl list-units --type=service --all
```

## Troubleshooting

### Unit Not Found

1. Confirm unit name with `systemctl list-unit-files | grep <name>`.
2. If you added a new unit file, run `sudo systemctl daemon-reload`.
3. Use fully qualified unit names when needed (example: `nginx.service`).

### Service Fails to Start

Check details with:

```bash
sudo systemctl status <unit>
sudo journalctl -u <unit> -n 200 --no-pager
```

### Enable Fails Due to Missing Install Section

Unit file may not include an `[Install]` section, or may not be designed for enabling.

## Best Practices

1. Prefer `systemctl` for service lifecycle control over manual process killing.
2. Use `reload` when possible to avoid unnecessary downtime.
3. Check `status` and related journal logs after changes.
4. Run `daemon-reload` after any unit file edits.
5. Use `is-active` and `is-enabled` in health checks and scripts.

## Related Commands

- `journalctl`: Inspect service logs from systemd journal
- `ps`: Process-level inspection
- `kill` and `pkill`: Direct process signaling
