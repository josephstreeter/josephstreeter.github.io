---
title: tail Command
description: Comprehensive reference for the tail command in Bash, including follow mode, byte and line output controls, and practical log-monitoring patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `tail` command prints the end of files or streams.
It is widely used for log monitoring, output inspection, and incremental troubleshooting.

## Overview

Use `tail` when you need to:

- Show the last N lines of a file
- Follow logs as new lines are appended
- Inspect the final bytes of binary or text output
- Monitor live service behavior in real time

## Syntax

```bash
tail [options] [file...]
```

Common forms:

```bash
# Default: last 10 lines
tail app.log

# Last 100 lines
tail -n 100 app.log

# Follow file growth
tail -f app.log
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-n N` | Show last N lines | `tail -n 50 app.log` |
| `-c N` | Show last N bytes | `tail -c 512 payload.bin` |
| `-f` | Follow appended data | `tail -f app.log` |
| `-F` | Follow by name and retry (handles rotation) | `tail -F app.log` |
| `--pid=PID` | Stop following when PID exits (GNU) | `tail -f --pid=1234 app.log` |
| `-q` | Never print file headers | `tail -q file1 file2` |
| `-v` | Always print file headers | `tail -v file1 file2` |

## Follow Mode and Log Rotation

- `-f` follows an open file descriptor.
- `-F` is usually better for rotated logs because it follows by filename and retries.

Typical production log monitoring:

```bash
tail -F /var/log/nginx/access.log
```

## Examples

```bash
# Show last 25 lines
tail -n 25 app.log
```

```bash
# Follow logs and filter for errors
tail -F app.log | grep -Ei 'error|warn|fatal'
```

```bash
# Show last 1 KiB from binary/text payload
tail -c 1024 artifact.bin
```

```bash
# Monitor two logs together
tail -f service-a.log service-b.log
```

```bash
# Start output from line 200 onward (GNU coreutils)
tail -n +200 app.log
```

## Integration Patterns

With system logs:

```bash
journalctl -u nginx -f
```

With file logs:

```bash
tail -F /var/log/syslog
```

With pager for review:

```bash
tail -n 200 app.log | less
```

## Safe Usage Guidelines

1. Use `-F` when monitoring logs that rotate.
2. Combine with `grep` carefully to avoid missing context.
3. Limit followed files to reduce noise in incident sessions.
4. Use explicit line counts for reproducible diagnostics.

## Troubleshooting

### No new output appears in follow mode

Possible causes:

- File is not actively written
- Wrong file path
- Rotation changed file handle

Fixes:

- Verify path and write activity
- Use `tail -F` instead of `tail -f`

### Output includes file headers unexpectedly

Cause: Multiple files provided.

Fix:

```bash
tail -q -n 20 file1 file2
```

### Need historical logs plus live updates

Fix:

```bash
tail -n 200 -F app.log
```

## Notes

`tail` and `head` are complementary tools for quick file boundary inspection.
For journald-managed services, `journalctl -f` is often preferable.

For command details and implementation-specific behavior, run:

```bash
man tail
tail --help
```

## Related Commands

- [head](head.md)
- [less](less.md)
- [grep](grep.md)
- [tee](tee.md)
- [journalctl](journalctl.md)
