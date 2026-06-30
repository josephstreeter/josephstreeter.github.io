---
title: apt Command
description: Comprehensive guide to apt for package installation, upgrades, repository management, and troubleshooting on Debian-based Linux systems.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `apt` command is the primary package management interface on Debian-based distributions such as Ubuntu, Debian, Kali, and Linux Mint.

It is used to:

- Refresh package metadata
- Install and remove software packages
- Upgrade system packages
- Query package information
- Manage package dependencies and cached package files

## Overview

`apt` is a user-friendly front end for lower-level tools such as `apt-get`, `apt-cache`, and `dpkg`.

For interactive terminal usage, `apt` is usually preferred.
For strict script compatibility in older automation, `apt-get` and `apt-cache` are still common.

## Syntax

```bash
apt [command] [options]
```

Common pattern:

```bash
sudo apt <command> [package...]
```

## Command Quick Reference

| Command | Purpose | Typical Use |
| ------ | ------- | ------- |
| `apt update` | Refresh package indexes from repositories | Run before installs/upgrades |
| `apt upgrade` | Upgrade installed packages without removing/installing others | Regular maintenance |
| `apt full-upgrade` | Upgrade packages and allow dependency changes/removals | Major update cycles |
| `apt install <pkg>` | Install package | Add software |
| `apt remove <pkg>` | Remove package, keep config files | Remove software safely |
| `apt purge <pkg>` | Remove package and its config files | Complete cleanup |
| `apt autoremove` | Remove auto-installed packages no longer needed | Dependency cleanup |
| `apt search <term>` | Search package names/descriptions | Discover packages |
| `apt show <pkg>` | Show package metadata | Inspect package details |
| `apt list --installed` | List installed packages | Inventory |
| `apt clean` | Remove downloaded package files from cache | Reclaim disk space |
| `apt autoclean` | Remove outdated package files from cache | Light cache cleanup |

## Core Workflows

### Refresh Package Metadata

```bash
sudo apt update
```

Use this before installing or upgrading so your system has current repository metadata.

### Upgrade Installed Packages

```bash
sudo apt upgrade
```

This performs a conservative upgrade that avoids removing packages.

For broader dependency resolution:

```bash
sudo apt full-upgrade
```

Use `full-upgrade` carefully because it may remove packages to satisfy dependency changes.

### Install Packages

```bash
sudo apt install curl
sudo apt install git vim
```

Install a specific version when needed:

```bash
sudo apt install nginx=1.24.0-2ubuntu7
```

### Remove Packages

```bash
sudo apt remove nginx
sudo apt purge nginx
sudo apt autoremove
```

- `remove`: uninstall package binaries, keep config files
- `purge`: uninstall package and associated config files
- `autoremove`: remove no-longer-required dependencies

### Search and Inspect Packages

```bash
apt search openssh
apt show openssh-client
apt list --installed | grep openssh
```

### Clean Package Cache

```bash
sudo apt autoclean
sudo apt clean
```

- `autoclean`: remove obsolete cached packages
- `clean`: remove all cached package files

## Useful Options

| Option | Meaning |
| ------ | ------- |
| `-y` / `--yes` | Assume yes for prompts (automation use) |
| `-qq` | Very quiet output |
| `--reinstall` | Reinstall package even if already installed |
| `-f` / `--fix-broken` | Attempt to fix broken dependencies |
| `--only-upgrade` | Upgrade package only if already installed |
| `--download-only` | Download packages without installing |

Example:

```bash
sudo apt install -y --no-install-recommends tmux
```

`--no-install-recommends` helps keep installations minimal by skipping recommended (non-required) packages.

## Repository Management

Package repositories are typically configured in:

- `/etc/apt/sources.list`
- `/etc/apt/sources.list.d/*.list`

After changing repositories:

```bash
sudo apt update
```

When adding third-party repositories, verify vendor trust and signing key instructions before installation.

## Safe Automation Patterns

### Non-Interactive Install

```bash
sudo apt update && sudo apt install -y curl ca-certificates
```

### Fail-Fast Script Snippet

```bash
#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y jq
```

### Avoid Upgrading Everything Unintentionally

Prefer targeted operations in scripts:

```bash
sudo apt install -y python3-venv
```

instead of broad upgrades, unless your automation explicitly manages maintenance windows.

## Troubleshooting

### Lock File Errors

Symptoms include messages about a lock held by another process.

Common causes:

- Another package process is running (`apt`, `apt-get`, `dpkg`)
- Automatic background updates are active

Check running package processes:

```bash
ps aux | grep -E 'apt|dpkg'
```

Wait for active processes to finish before retrying.

### Broken Dependencies

```bash
sudo apt --fix-broken install
sudo dpkg --configure -a
```

Then run:

```bash
sudo apt update
sudo apt upgrade
```

### Package Not Found

1. Ensure metadata is current with `sudo apt update`.
2. Confirm repository configuration includes the package source.
3. Verify spelling and package naming with `apt search <term>`.

## Best Practices

1. Run `sudo apt update` before install/upgrade actions.
2. Use `apt upgrade` for routine maintenance and `full-upgrade` deliberately.
3. Use `--no-install-recommends` in container or minimal environments.
4. Follow installs/removals with `sudo apt autoremove` when appropriate.
5. Avoid adding untrusted third-party repositories.
6. Use explicit package names and versions for reproducible automation.

## Related Commands

- `dpkg`: Low-level package database and package file operations
- `apt-cache`: Package metadata queries (legacy interface)
- `apt-get`: Lower-level apt interface often used in older scripts
