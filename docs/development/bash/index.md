---
title: Bash Scripting
description: Practical Bash scripting guidance for automation, reliability, and secure shell workflows.
tags: ["development", "bash", "linux", "automation", "shell-scripting"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-05-21"
author: "Joseph Streeter"
---

Bash is a foundational shell for Linux and Unix-like systems. This section focuses on practical scripting patterns that are reliable in automation workflows and easy to maintain over time.

## What You Will Find Here

- Script structure and safety defaults for predictable execution
- Input validation and defensive parameter handling
- Quoting, globbing, and whitespace-safe file processing
- Logging, exit codes, and troubleshooting patterns
- SSH-centric automation patterns (SCP, SFTP, rsync)

## Command References

- [Command Reference Index](commands/index.md)
- [Navigation and File Commands](navigation-and-files.md)
- [Text Processing and Search Commands](text-processing-and-search.md)
- [System, Process, and Network Commands](system-process-and-network.md)

## Getting Started

Use this script template as a baseline for most automation jobs.

This template gives you a safe default structure for production scripts. It separates helper logic from execution flow, enables strict error handling, and preserves command-line arguments exactly as they were provided.

```bash
#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

main()
{
  log "Starting task"
}

main "$@"
```

Detailed explanation:

1. `#!/usr/bin/env bash` selects Bash from the current environment so the script runs correctly across systems where Bash may be installed in different locations.
2. `set -euo pipefail` enables strict mode:
   - `-e` stops execution when a command fails.
   - `-u` treats unset variables as errors.
   - `pipefail` makes pipelines fail if any command in the chain fails.
3. `log()` is a reusable helper that prints timestamped messages in a consistent format, which improves traceability in CI jobs and cron logs.
4. `main()` isolates the primary workflow in one place, which makes the script easier to test, read, and extend.
5. `main "$@"` forwards all original arguments safely to `main` without breaking on spaces or special characters.

## Bash Safety Essentials

1. Use strict mode (`set -euo pipefail`) for scripts that should fail fast.
2. Quote variable expansions: `"${Variable}"`.
3. Prefer `[[ ... ]]` for tests over `[ ... ]`.
4. Use functions for reusable logic and easier testing.
5. Return non-zero exit codes on failure and log useful context.

## Common Automation Patterns

### Iterate Over Files Safely

```bash
find /var/log -type f -name '*.log' -print0 |
while IFS= read -r -d '' FilePath
do
  printf 'Processing %s\n' "$FilePath"
done
```

Detailed explanation:

1. `find /var/log -type f -name '*.log' -print0` discovers matching files and emits null-delimited paths instead of newline-delimited paths.
2. Null-delimited output is important because file names can legally contain spaces, tabs, or newlines.
3. `while IFS= read -r -d '' FilePath` reads one null-delimited entry at a time:
   - `IFS=` preserves leading and trailing whitespace.
   - `-r` disables backslash escaping so paths are read literally.
   - `-d ''` tells `read` to use the null byte as the delimiter.
4. `printf 'Processing %s\n' "$FilePath"` prints each path safely with quoting, avoiding word splitting and glob expansion.
5. This pattern is preferred over `for f in $(find ...)` because command substitution breaks on whitespace and special characters.

### Validate Inputs Early

```bash
if [[ $# -lt 1 ]]
then
  echo "Usage: $0 <target-path>"
  exit 1
fi

TargetPath="$1"
```

Detailed explanation:

1. `[[ $# -lt 1 ]]` checks whether fewer than one positional argument was provided.
2. The early guard clause fails fast with a usage message, which prevents the script from running in an invalid state.
3. `echo "Usage: $0 <target-path>"` prints a clear invocation format using `$0` (the script name) so users can quickly correct their command.
4. `exit 1` returns a non-zero status to signal invalid input to calling tools, automation pipelines, or parent scripts.
5. `TargetPath="$1"` stores the first argument in a named variable to improve readability and reduce mistakes in later logic.

### Handle Command Failures Explicitly

```bash
if ! rsync -az --partial ./source/ user@host:/backup/source/
then
  echo "Backup failed" >&2
  exit 1
fi
```

Detailed explanation:

1. `if ! rsync ...` inverts the command result so the `then` block executes only on failure.
2. `rsync -az --partial` uses common backup-friendly flags:
   - `-a` enables archive mode (recursive copy with metadata preservation).
   - `-z` compresses data in transit, useful for remote transfers.
   - `--partial` keeps partially transferred files so interrupted transfers can resume more efficiently.
3. `echo "Backup failed" >&2` writes the error message to standard error, keeping diagnostic output separate from normal script output.
4. `exit 1` surfaces failure immediately to schedulers and CI systems so they can alert or retry.
5. This explicit pattern is valuable even with strict mode because it lets you attach a clear, human-readable error message at the exact failure point.

## Related Sections

- [Linux](../../infrastructure/linux/index.md) for OS-level administration context
- [PowerShell](../powershell/index.md) for cross-platform scripting alternatives
- [Python](../python/index.md) for higher-level automation workflows
