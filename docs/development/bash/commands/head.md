---
title: head Command
description: Comprehensive reference for the head command in Bash, including syntax, options, and practical examples for file and stream inspection.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `head` command prints the beginning of files or input streams.
It is commonly used to preview data, inspect headers, and limit output in scripts.

## Overview

Use `head` when you need to:

- Preview the first lines of large files
- Inspect file headers (CSV, logs, configs)
- Limit pipeline output for quick checks
- Read the first N bytes of binary/text streams
- Reduce noisy output during debugging

## Syntax

```bash
head [options] [file...]
```

Common forms:

```bash
# Default: first 10 lines
head app.log

# First 20 lines
head -n 20 app.log

# First 100 bytes
head -c 100 payload.bin
```

If no files are provided, `head` reads from standard input.

## Default Behavior

- Without options, `head` prints the first 10 lines.
- With multiple files, file headers are printed before each section.
- `head` is read-only and does not modify input files.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-n N` | Show first N lines | `head -n 30 app.log` |
| `-c N` | Show first N bytes | `head -c 256 data.bin` |
| `-q` | Never print file name headers | `head -q file1 file2` |
| `-v` | Always print file name headers | `head -v file1 file2` |

GNU `head` also supports suffixes with `-c` such as `K`, `M`, and `G`.

## Examples

```bash
# Preview first 20 lines of a log
head -n 20 app.log
```

```bash
# Show first line (useful for CSV headers)
head -n 1 users.csv
```

```bash
# Show first 500 bytes of a file
head -c 500 archive.dat
```

```bash
# Preview first 3 lines from each of multiple files
head -n 3 server1.log server2.log
```

```bash
# Suppress per-file headers when reading multiple files
head -n 2 -q a.txt b.txt c.txt
```

```bash
# Force per-file headers when reading multiple files
head -n 2 -v a.txt b.txt c.txt
```

```bash
# Limit command output in a pipeline
journalctl -u nginx | head -n 50
```

```bash
# Inspect first few paths from find output
find . -type f | head -n 10
```

## Working with Bytes vs Lines

- `-n` is line-oriented and respects line boundaries.
- `-c` is byte-oriented and may cut in the middle of a line or multibyte character.

Use `-n` for human-readable text previews.
Use `-c` for protocol headers, binary checks, or fixed-size reads.

## Integration Patterns

Quick log inspection:

```bash
head -n 40 /var/log/syslog
```

Preview generated output from scripts:

```bash
./generate-report.sh | head -n 25
```

Validate sorted output quickly:

```bash
sort big-list.txt | head -n 10
```

## Safe Usage Guidelines

1. Use `head` before full processing to validate file format and structure.
2. Combine with `-n 1` to safely inspect headers in CSV or TSV files.
3. Use `-q` in scripts when predictable output formatting is required.
4. Prefer `-n` for text and `-c` for byte-accurate inspection.

## Performance Tips

1. `head` is efficient for large files because it stops reading after requested output.
2. Use `head` early in pipelines during debugging to reduce processing time.
3. For bottom-of-file inspection, use `tail` instead of reading full file then filtering.

## Troubleshooting

### Output includes `==> file <==` headers unexpectedly

Cause: Multiple files were passed, so `head` shows per-file labels.

Fix:

```bash
head -q -n 5 file1 file2
```

### `head -c` output looks truncated or garbled

Cause: Byte truncation may split multibyte text characters.

Fix:

- Use `-n` for text data
- Keep `-c` for raw byte inspection use cases

### Need first N lines but from piped command

Fix:

```bash
some_command | head -n 20
```

## Notes

`head` and `tail` are complementary tools for quick top/bottom inspection of data.

For command details and implementation-specific behavior, run:

```bash
man head
head --help
```

## Related Commands

- [tail](tail.md)
- [cat](cat.md)
- [less](less.md)
- [grep](grep.md)
- [wc](wc.md)
