---
title: sudo Command
description: Comprehensive reference for the sudo command in Bash, including privilege escalation patterns, safety practices, and configuration notes.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `sudo` command runs commands as another user (default: root), based on policy rules.
It is commonly used for administrative tasks that require elevated privileges.

## Overview

Use `sudo` when you need to:

- Perform administrative operations requiring root permissions
- Run specific commands as another user
- Refresh or validate privilege credentials
- Audit privileged command usage through logs

## Syntax

```bash
sudo [options] command [arguments...]
```

Common forms:

```bash
# Run a single command with elevated privileges
sudo systemctl restart nginx

# Run command as another user
sudo -u www-data id

# Open a root shell (use sparingly)
sudo -i
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-u USER` | Run command as specified user | `sudo -u postgres psql` |
| `-i` | Start login shell as target user (default root) | `sudo -i` |
| `-s` | Run shell as target user preserving environment style | `sudo -s` |
| `-k` | Invalidate cached credentials | `sudo -k` |
| `-v` | Validate or refresh cached credentials | `sudo -v` |
| `-l` | List allowed commands for current user | `sudo -l` |
| `-n` | Non-interactive mode; fail if password is needed | `sudo -n command` |
| `-E` | Preserve environment variables (policy-dependent) | `sudo -E env` |

## Privilege Model Basics

- Access is controlled by `sudoers` policy.
- Authentication may be cached briefly (timestamp timeout).
- Allowed commands can be fully open or tightly scoped.
- Command execution is often logged for auditing.

`sudo` configuration is typically managed with:

```bash
visudo
```

## Examples

```bash
# Install packages (distribution-specific command)
sudo apt update
sudo apt install curl
```

```bash
# Read root-owned file
sudo cat /etc/shadow
```

```bash
# Run command as service account
sudo -u nginx whoami
```

```bash
# Refresh sudo timestamp before a maintenance script
sudo -v
```

```bash
# Check permitted sudo commands
sudo -l
```

```bash
# Use non-interactive mode in automation
sudo -n systemctl status nginx
```

## Safe Usage Guidelines

1. Prefer `sudo <command>` over opening long-lived root shells.
2. Use least privilege: allow only required commands in policy.
3. Review commands before running with elevated privileges.
4. Avoid `sudo` with untrusted input or uncontrolled variable expansion.
5. Use `visudo` for policy edits to prevent syntax errors and lockouts.

## Automation Guidance

For scripts:

- Use `sudo -n` when prompts are not acceptable.
- Check exit codes and fail clearly on permission errors.
- Avoid embedding passwords or insecure workarounds.

Example:

```bash
if ! sudo -n true 2>/dev/null; then
	echo "sudo privileges are required" >&2
	exit 1
fi
```

## Troubleshooting

### `user is not in the sudoers file`

Cause: Account lacks sudo policy permission.

Fix:

- Request access from an administrator
- Add proper rule via `visudo` (admin only)

### `sudo: a password is required`

Cause: Non-interactive usage without cached credentials or NOPASSWD policy.

Fixes:

- Authenticate interactively first with `sudo -v`
- Use approved policy for automation

### `sudo: command not found`

Cause: Command unavailable in restricted `secure_path` or not installed.

Fixes:

- Use full path (for example `/usr/sbin/...`)
- Check policy and installed packages

## Notes

`sudo` behavior and policy defaults vary by distribution and organization security baseline.
Treat elevated shells and broad sudo rights as high risk.

For command details and implementation-specific behavior, run:

```bash
man sudo
man sudoers
sudo --help
```

## Related Commands

- [systemctl](systemctl.md)
- [journalctl](journalctl.md)
- [ps](ps.md)
- [ss](ss.md)
- [rm](rm.md)
