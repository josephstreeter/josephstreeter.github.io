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

- [Navigation and File Commands](navigation-and-files.md)
- [Text Processing and Search Commands](text-processing-and-search.md)
- [System, Process, and Network Commands](system-process-and-network.md)

## Getting Started

Use this script template as a baseline for most automation jobs.

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

### Validate Inputs Early

```bash
if [[ $# -lt 1 ]]
then
  echo "Usage: $0 <target-path>"
  exit 1
fi

TargetPath="$1"
```

### Handle Command Failures Explicitly

```bash
if ! rsync -az --partial ./source/ user@host:/backup/source/
then
  echo "Backup failed" >&2
  exit 1
fi
```

## Related Sections

- [Linux](../../infrastructure/linux/index.md) for OS-level administration context
- [PowerShell](../powershell/index.md) for cross-platform scripting alternatives
- [Python](../python/index.md) for higher-level automation workflows
