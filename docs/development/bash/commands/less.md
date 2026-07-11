---
title: less Command
description: Comprehensive reference for the less command in Bash, including navigation keys, options, search behavior, and practical usage patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `less` command is an interactive pager for viewing text one screen at a time.
It is ideal for reading large files, log output, and command pipelines without loading content into an editor.

## Overview

Use `less` when you need to:

- View large files without opening an editor
- Scroll through logs and command output interactively
- Search for patterns inside a file
- Follow growing files (similar to live log tailing)
- Navigate quickly by lines, percentages, and matches

## Syntax

```bash
less [options] [file...]
```

Common forms:

```bash
# View a file
less /var/log/syslog

# View command output
journalctl -u nginx | less

# Open at first match
less +/ERROR app.log

# Follow mode (live updates)
less +F app.log
```

If no file is supplied, `less` reads from standard input.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-N` | Show line numbers | `less -N app.log` |
| `-S` | Chop long lines (no wrap) | `less -S data.tsv` |
| `-R` | Display raw ANSI color escapes | `less -R build.log` |
| `-X` | Do not clear screen on exit | `less -X notes.txt` |
| `-F` | Quit if content fits one screen | `less -F README.md` |
| `-i` | Case-insensitive search unless uppercase in pattern | `less -i app.log` |
| `-I` | Always case-insensitive search | `less -I app.log` |
| `+N` | Start at line N | `less +120 app.log` |
| `+/PATTERN` | Start at first PATTERN match | `less +/timeout app.log` |

## Essential Navigation Keys

| Key | Action |
| --- | --- |
| `Space` | Next page |
| `b` | Previous page |
| `Enter` | Next line |
| `k` / `y` | Previous line |
| `g` | Go to first line |
| `G` | Go to last line |
| `N g` | Go to line N (example: `250g`) |
| `N%` | Go to percentage in file (example: `50%`) |
| `q` | Quit |

## Search and Match Navigation

- `/pattern` search forward
- `?pattern` search backward
- `n` jump to next match
- `N` jump to previous match

Examples while inside `less`:

- `/ERROR`
- `/connection timeout`
- `?Exception`

## Following Live Output

Use follow mode to watch files that are growing:

```bash
less +F /var/log/syslog
```

In follow mode:

- Press `Ctrl+C` to pause following and return to normal navigation
- Press `F` to resume following

This is similar to `tail -f` but allows full interactive navigation when paused.

## Examples

```bash
# Browse a large log with line numbers
less -N /var/log/nginx/access.log
```

```bash
# Preserve color output from grep
grep --color=always -n "ERROR" app.log | less -R
```

```bash
# View wide output without wrapping
ps aux | less -S
```

```bash
# Open directly at end of file
less +G app.log
```

```bash
# Open multiple files and move between them (:n and :p inside less)
less app.log app.log.1 app.log.2
```

```bash
# View compressed logs using zless wrapper
zless app.log.gz
```

## Useful In-Session Commands

- `h` open built-in help
- `:n` go to next file in argument list
- `:p` go to previous file in argument list
- `=` show current file position

## Safe Usage Guidelines

1. Use `less` instead of `cat` for large files to avoid terminal flooding.
2. Use `-R` when paging colorized output from other tools.
3. Use `-S` for wide tabular output to prevent wrapped, hard-to-read lines.
4. Prefer `less +/pattern` for quicker incident triage in large logs.

## Performance Tips

1. `less` streams data and is efficient for very large files.
2. Piping into `less` keeps interactive control while avoiding huge terminal output.
3. Disable line wrapping (`-S`) for large structured rows to improve readability.

## Troubleshooting

### Colors disappear when piping output into less

Cause: Color escapes are stripped or not rendered.

Fix:

```bash
grep --color=always "error" app.log | less -R
```

### Long lines wrap and become hard to read

Cause: Default line wrapping.

Fix:

```bash
less -S wide-output.txt
```

### File keeps updating and view jumps

Cause: Follow mode enabled.

Fix:

- Press `Ctrl+C` to pause follow mode
- Use normal navigation commands, then press `F` to resume

## Notes

`less` is often configured as the default pager through the `PAGER` environment variable.

For command details and implementation-specific behavior, run:

```bash
man less
less --help
```

## Related Commands

- [cat](cat.md)
- [head](head.md)
- [tail](tail.md)
- [grep](grep.md)
- [journalctl](journalctl.md)
