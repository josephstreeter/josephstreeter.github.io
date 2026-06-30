---
title: grep Command
description: Comprehensive reference for the grep command in Bash, including syntax, regex usage, recursive search, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `grep` command searches text for lines that match a pattern.
It is one of the most important tools for filtering logs, code, and command output.

## Overview

Use `grep` when you need to:

- Find matching lines in one or more files
- Search logs for errors, warnings, or identifiers
- Filter pipeline output by pattern
- Recursively search directories
- Match with basic or extended regular expressions

## Syntax

```bash
grep [options] pattern [file...]
```

Common forms:

```bash
# Simple text match
grep "error" app.log

# Case-insensitive match
grep -i "timeout" app.log

# Recursive search in directory
grep -R "TODO" ./src

# Extended regex
grep -E 'WARN|ERROR|FATAL' app.log
```

If no files are provided, `grep` reads from standard input.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-i` | Case-insensitive search | `grep -i "warning" app.log` |
| `-n` | Show line numbers | `grep -n "error" app.log` |
| `-v` | Invert match (non-matching lines) | `grep -v '^#' config.ini` |
| `-c` | Count matching lines | `grep -c "ERROR" app.log` |
| `-l` | List files with matches | `grep -l "needle" *.txt` |
| `-L` | List files without matches | `grep -L "needle" *.txt` |
| `-r`, `-R` | Recursive directory search | `grep -R "TODO" .` |
| `-w` | Match whole words only | `grep -w "cat" words.txt` |
| `-x` | Match whole lines only | `grep -x "SUCCESS" status.txt` |
| `-o` | Print only matched portion | `grep -o '[0-9]\+' ids.txt` |
| `-E` | Use extended regex | `grep -E 'foo|bar' file.txt` |
| `-F` | Fixed string search (no regex) | `grep -F 'a+b*c' text.txt` |
| `-A N` | Show N lines after match | `grep -A 3 "ERROR" app.log` |
| `-B N` | Show N lines before match | `grep -B 2 "ERROR" app.log` |
| `-C N` | Show N lines of context around match | `grep -C 2 "ERROR" app.log` |
| `--color=auto` | Highlight matches | `grep --color=auto "error" app.log` |

## Regular Expression Modes

`grep` supports multiple matching modes:

- Basic regex (default)
- Extended regex with `-E`
- Fixed strings with `-F`
- Perl-compatible regex with `-P` (GNU grep, may not be available everywhere)

Examples:

```bash
# Basic regex (escaped grouping)
grep '\(error\|warn\)' app.log
```

```bash
# Extended regex (cleaner alternation)
grep -E '(error|warn)' app.log
```

```bash
# Fixed string (fast and literal)
grep -F '[INFO]' app.log
```

## Anchors and Character Classes

Useful patterns:

- `^` start of line
- `$` end of line
- `.` any single character
- `[0-9]` character class
- `[^0-9]` negated class
- `[[:space:]]`, `[[:alpha:]]`, `[[:digit:]]` POSIX classes

Examples:

```bash
# Lines starting with ERROR
grep '^ERROR' app.log
```

```bash
# Lines ending with semicolon
grep ';$' statements.txt
```

```bash
# Find IPv4-like tokens (approximate)
grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log
```

## Recursive Search Patterns

Search source code while excluding build artifacts:

```bash
grep -R --exclude-dir=.git --exclude-dir=node_modules --exclude='*.min.js' "TODO" .
```

Search only specific file types:

```bash
grep -R --include='*.md' "sed" docs/
```

## Examples

```bash
# Show line numbers for matching log lines
grep -n "error" app.log
```

```bash
# Case-insensitive match in multiple files
grep -i "timeout" *.log
```

```bash
# Print only matching token(s)
grep -o -E 'ticket-[0-9]+' changes.txt
```

```bash
# Count number of matching lines
grep -c "ERROR" app.log
```

```bash
# Show files that contain a match
grep -l "DATABASE_URL" .env .env.example
```

```bash
# Exclude commented lines and empty lines
grep -Ev '^[[:space:]]*(#|$)' config.ini
```

```bash
# Show context around matches
grep -C 2 "Exception" service.log
```

```bash
# Invert selection: show lines that do not contain "DEBUG"
grep -v "DEBUG" app.log
```

## Pipeline Integration

Filter command output:

```bash
ps aux | grep -i nginx
```

Avoid matching the `grep` process itself:

```bash
ps aux | grep '[n]ginx'
```

With journald logs:

```bash
journalctl -u nginx -n 500 | grep -Ei 'error|warn|critical'
```

## Safe Usage Guidelines

1. Quote patterns in single quotes when possible to avoid shell expansion.
2. Use `-F` for literal strings to improve safety and speed.
3. Use `-E` for readability when alternation or grouping is needed.
4. Prefer `-R` with `--include` or exclusions for large trees.
5. Validate regex patterns on sample input before automation.

## Performance Tips

1. Use `-F` for exact substring searches.
2. Narrow search scope by file extension or directory.
3. Avoid recursive root-level searches unless necessary.
4. Use anchored patterns (`^`, `$`) when appropriate to reduce backtracking.

## Troubleshooting

### No matches found but text exists

Possible causes:

- Case mismatch
- Hidden characters or line endings
- Regex metacharacters interpreted unexpectedly

Fixes:

```bash
grep -in "pattern" file
grep -F "literal+text" file
cat -A file | grep "pattern"
```

### Too many results in recursive search

Cause: Search scope is too broad.

Fix:

```bash
grep -R --include='*.md' --exclude-dir=.git "topic" docs/
```

### Binary file matches message

Cause: File contains binary content.

Fixes:

- Use `-a` to treat binary as text when intentional
- Use `-I` to skip binary files

## Notes

GNU `grep` is common on Linux, but options may differ on other systems.
For portable scripts, avoid GNU-only features unless required.

For command details and implementation-specific behavior, run:

```bash
man grep
grep --help
```

## Related Commands

- [sed](sed.md)
- [awk](awk.md)
- [find](find.md)
- [head](head.md)
- [tail](tail.md)
