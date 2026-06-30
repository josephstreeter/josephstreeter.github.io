---
title: tee Command
description: Comprehensive reference for the tee command in Bash, including stream duplication, append behavior, and pipeline usage patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `tee` command reads from standard input and writes simultaneously to standard output and one or more files.
It is useful for logging pipelines while still seeing output in real time.

## Overview

Use `tee` when you need to:

- Save command output to a file while viewing it in terminal
- Capture logs from long-running scripts
- Feed output to additional pipeline stages
- Append or overwrite output files explicitly

## Syntax

```bash
tee [options] [file...]
```

Common forms:

```bash
# Write output to terminal and file
some_command | tee output.log

# Append instead of overwrite
some_command | tee -a output.log

# Write to multiple files
some_command | tee out1.log out2.log
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-a` | Append to files instead of overwriting | `cmd | tee -a run.log` |
| `-i` | Ignore interrupt signals | `cmd | tee -i run.log` |
| `-p` | Diagnose errors writing to non pipes (GNU) | `cmd | tee -p out.log` |

## Core Behavior

- Input always comes from standard input.
- Output is written to standard output and each named file.
- Without `-a`, files are truncated before writing.
- Exit status reflects write behavior and pipeline context.

## Examples

```bash
# Save script output while keeping it visible
./build.sh | tee build.log
```

```bash
# Append daily run output
./backup.sh | tee -a backup.log
```

```bash
# Save and continue processing
cat app.log | tee snapshot.log | grep -i error
```

```bash
# Split output into two log files
journalctl -u nginx -n 500 | tee nginx-recent.log nginx-audit.log
```

```bash
# Capture both stdout and stderr
./deploy.sh 2>&1 | tee deploy.log
```

## Pipeline Patterns

Capture intermediate output for debugging:

```bash
generate_data | tee raw.out | transform_data | tee transformed.out | summarize
```

Log and inspect in pager:

```bash
long_command 2>&1 | tee command.log | less
```

## Safe Usage Guidelines

1. Use `-a` for append-only logs; omit it when fresh logs are desired.
2. Redirect stderr (`2>&1`) when full diagnostics are needed.
3. Choose deterministic file paths for script logs.
4. Be mindful of sensitive data when logging command output.

## Troubleshooting

### Log file was overwritten unexpectedly

Cause: `tee` defaults to truncation.

Fix:

```bash
cmd | tee -a existing.log
```

### Missing stderr content in log

Cause: Only stdout was piped.

Fix:

```bash
cmd 2>&1 | tee run.log
```

### Pipeline succeeded even when command failed

Cause: Shell pipeline exit behavior may return last command status.

Fix:

- In Bash scripts, use `set -o pipefail`
- Check exit codes explicitly

## Notes

`tee` is most useful in observability-heavy workflows and CI logs where real-time output and persistent records are both required.

For command details and implementation-specific behavior, run:

```bash
man tee
tee --help
```

## Related Commands

- [cat](cat.md)
- [grep](grep.md)
- [tail](tail.md)
- [less](less.md)
- [wc](wc.md)
