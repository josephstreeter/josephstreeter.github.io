---
title: Bash System, Process, and Network Commands
description: Common Bash commands for system visibility, process control, and network troubleshooting.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 05/21/2026
ms.topic: conceptual
ms.service: development
---

These commands are useful for diagnosing runtime issues, checking system state, and validating connectivity.

## System and Process Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `ps` | List running processes | `ps aux \| grep nginx` |
| `top` | Interactive process and resource view | `top` |
| `htop` | Improved interactive process view | `htop` |
| `kill` | Send signal to process | `kill -TERM 1234` |
| `df` | Disk usage by filesystem | `df -h` |
| `du` | File and directory size usage | `du -sh ./artifacts` |
| `free` | Memory usage | `free -h` |
| `uname` | Kernel and OS info | `uname -a` |

## Network and Remote Access Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `ip` | Interface and route information | `ip addr show` |
| `ss` | Socket/listening port inspection | `ss -ltnp` |
| `ping` | Basic connectivity test | `ping -c 4 8.8.8.8` |
| `curl` | HTTP/API requests | `curl -I https://example.com` |
| `dig` | DNS lookup and troubleshooting | `dig example.com` |
| `ssh` | Secure remote shell | `ssh user@host` |
| `scp` | Secure copy over SSH | `scp file.txt user@host:/tmp/` |
| `rsync` | Efficient sync over SSH | `rsync -az ./data/ user@host:/data/` |

## Troubleshooting Quick Checks

```bash
# Verify a service is listening on expected port
ss -ltnp | grep :443
```

```bash
# Check route and DNS before debugging app-level issues
ip route
dig internal-api.example.com
```

## Safe Usage Tips

1. Prefer `kill -TERM` before `kill -KILL`.
2. Use `ss` instead of deprecated networking tools where possible.
3. Confirm destination paths before running `rsync --delete`.
4. Avoid running long-lived SSH commands without timeouts in automation.
