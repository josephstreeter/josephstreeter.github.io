---
title: Bash Navigation and File Commands
description: Common Bash commands for directory navigation, file management, and file inspection.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 05/21/2026
ms.topic: conceptual
ms.service: development
---

This page covers frequently used Bash commands for moving around the filesystem and managing files and directories.

## Navigation Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `pwd` | Show current directory | `pwd` |
| `ls` | List directory contents | `ls -la` |
| `cd` | Change directory | `cd /var/log` |
| `pushd` | Save current directory and move | `pushd /etc` |
| `popd` | Return to previous directory | `popd` |

## File and Directory Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `mkdir` | Create directory | `mkdir -p ./build/output` |
| `cp` | Copy files or directories | `cp -r ./src ./backup/src` |
| `mv` | Move or rename files | `mv old.txt new.txt` |
| `rm` | Remove files or directories | `rm -rf ./temp` |
| `touch` | Create file or update timestamp | `touch notes.txt` |

## Inspecting File Content

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `cat` | Print full file content | `cat config.env` |
| `less` | Page through file content | `less /var/log/syslog` |
| `head` | Show first lines | `head -n 20 script.sh` |
| `tail` | Show last lines | `tail -n 50 app.log` |
| `wc` | Count lines/words/bytes | `wc -l app.log` |

## Safe Usage Tips

1. Use `ls -la` before deleting files in unfamiliar directories.
2. Use `cp -i` and `mv -i` when overwriting is risky.
3. Prefer `rm -r` over `rm -rf` unless you are certain.
4. Validate paths with `pwd` and `realpath` before destructive commands.
