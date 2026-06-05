---
title: nohup Command
description: Comprehensive guide to nohup for running long-lived commands that survive terminal disconnects.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/05/2026
ms.topic: reference
ms.service: development
---

The `nohup` command runs a command immune to the hangup signal (`SIGHUP`).

It is useful when you need a process to continue running after:

- Closing your terminal
- Disconnecting SSH sessions
- Ending an interactive shell

## Overview

When a command is launched with `nohup`, standard behavior is:

- Ignore `SIGHUP`
- Redirect output to `nohup.out` if not explicitly redirected
- Continue running in the background when combined with `&`

`nohup` is simple and portable for quick jobs, but does not provide full service management.

## Syntax

```bash
nohup command [arguments...]
```

Common usage pattern:

```bash
nohup command [arguments...] > output.log 2>&1 &
```

## Command Quick Reference

| Command | Purpose |
| ------ | ------- |
| `nohup cmd &` | Run command detached from hangup signal |
| `nohup cmd > out.log 2>&1 &` | Run in background with explicit logging |
| `nohup bash -c "..." &` | Run a small command sequence detached |
| `jobs -l` | Show background jobs in current shell |
| `ps -fp <pid>` | Inspect launched process by PID |

## Core Workflows

### Launch a Long-Running Command

```bash
nohup ./long-running-job.sh > job.log 2>&1 &
```

This is the most common pattern for SSH sessions and remote automation.

### Capture the Process ID

```bash
nohup ./worker.sh > worker.log 2>&1 &
echo $!
```

`$!` is the PID of the most recent background command.

### Run a Pipeline Through a Shell

```bash
nohup bash -c 'tar -czf backup.tgz /data && echo done' > backup.log 2>&1 &
```

Use `bash -c` when the command requires shell features such as `&&`, pipes, or redirects.

### Monitor Process and Logs

```bash
ps -fp <pid>
tail -f job.log
```

### Stop a nohup-Launched Process

```bash
kill -TERM <pid>
```

Use `kill -KILL <pid>` only if graceful termination fails.

## Output and Redirection Behavior

If no redirection is provided:

- Standard output is appended to `nohup.out`
- Standard error is often redirected to standard output

Recommended explicit redirection:

```bash
nohup command > command.log 2>&1 &
```

This keeps logs predictable and avoids unexpected files in the working directory.

## Useful Patterns

### Run from Any Directory with Absolute Paths

```bash
nohup /usr/local/bin/sync-task --config /etc/sync/config.yml > /var/log/sync-task.log 2>&1 &
```

### Start and Disown in Interactive Shells

```bash
nohup ./dev-server.sh > dev-server.log 2>&1 &
disown
```

`disown` removes the job from shell job tracking.

### Use with Environment Variables

```bash
nohup env APP_ENV=prod ./app-worker > app-worker.log 2>&1 &
```

## Examples

```bash
nohup ./long-running-job.sh &
nohup ./long-running-job.sh > job.log 2>&1 &
nohup bash -c 'python3 sync.py --once' > sync.log 2>&1 &
```

## Troubleshooting

### Command Stops Unexpectedly

`nohup` protects against `SIGHUP`, but not all failures.
Check:

1. Application-level errors in log files
2. Resource limits (memory, disk, ulimit)
3. Manual termination or system restart

### nohup.out Is Growing Unexpectedly

You likely did not redirect output explicitly.
Use:

```bash
nohup command > command.log 2>&1 &
```

### Process Not Found After Disconnect

Verify command started successfully and capture PID immediately with `$!`.
Also check logs for startup failures.

### Permission Denied Writing Logs

Ensure target log path is writable by the current user, or run with proper privileges.

## Best Practices

1. Always redirect output to a named log file.
2. Capture and store PID (`$!`) when launching background jobs.
3. Prefer absolute paths in long-running detached commands.
4. Use `systemd` (`systemctl`) for production services requiring restart policies and boot integration.
5. Combine with log rotation for long-running jobs.

## When to Use Alternatives

- Use `systemd` services for production daemons.
- Use `tmux` or `screen` when you want to keep an interactive session.
- Use workload schedulers (cron, systemd timers, CI runners) for scheduled tasks.

## Related Commands

- `ps`: Inspect running process details
- `pgrep`: Find matching process IDs
- `kill` and `pkill`: Stop or signal background processes
- `systemctl`: Manage long-running services via systemd
- `disown`: Remove jobs from shell tracking
