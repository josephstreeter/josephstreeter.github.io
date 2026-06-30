---
title: wc Command
description: Comprehensive reference for the wc command in Bash, including line, word, byte, and character counting patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `wc` command counts lines, words, bytes, and characters in files or standard input.
It is commonly used in data validation, scripting checks, and quick content sizing.

## Overview

Use `wc` when you need to:

- Count total lines in a file
- Measure word counts for text content
- Compare file sizes by bytes/characters
- Build simple validation checks in pipelines

## Syntax

```bash
wc [options] [file...]
```

Common forms:

```bash
# Default output: lines, words, bytes
wc notes.txt

# Line count only
wc -l app.log

# Count from pipeline
grep -i error app.log | wc -l
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-l` | Count lines | `wc -l file.txt` |
| `-w` | Count words | `wc -w file.txt` |
| `-c` | Count bytes | `wc -c file.txt` |
| `-m` | Count characters | `wc -m file.txt` |
| `-L` | Print maximum display line length | `wc -L file.txt` |

## Default Output Columns

Without options, `wc` prints:

1. Line count
2. Word count
3. Byte count
4. Filename (when file input is used)

For multiple files, `wc` also prints a `total` line.

## Examples

```bash
# Full count for one file
wc report.txt
```

```bash
# Count lines in all markdown files
wc -l *.md
```

```bash
# Count words in documentation file
wc -w README.md
```

```bash
# Count bytes from command output
cat payload.json | wc -c
```

```bash
# Count matching log lines
grep -i "ERROR" app.log | wc -l
```

```bash
# Show longest line length in file
wc -L data.txt
```

## Pipeline and Script Patterns

Count files matched by `find` safely:

```bash
find . -type f -name '*.log' | wc -l
```

Validate minimum line count in a script:

```bash
line_count=$(wc -l < input.txt)
if [[ "$line_count" -lt 10 ]]; then
	echo "input.txt has too few lines" >&2
	exit 1
fi
```

Note: using input redirection (`wc -l < file`) returns just the number,
which is easier to parse in scripts.

## Safe Usage Guidelines

1. Use explicit flags (`-l`, `-w`, etc.) for clarity.
2. Prefer `< file` form in scripts for parse-friendly output.
3. Be aware that word counting depends on locale and whitespace rules.
4. For Unicode-heavy content, compare `-c` and `-m` when needed.

## Troubleshooting

### Counts do not match expectations

Possible causes:

- Trailing newline differences
- Locale or encoding differences
- Hidden characters or unusual whitespace

Fixes:

```bash
cat -A file.txt
wc -lwmc file.txt
```

### Script parsing fails due to filename in output

Cause: `wc` includes filename when file argument is used.

Fix:

```bash
count=$(wc -l < file.txt)
```

## Notes

`wc` is simple but effective for quick quantification and pipeline checks.
For advanced text analytics, combine with `awk`, `sed`, or language-specific tooling.

For command details and implementation-specific behavior, run:

```bash
man wc
wc --help
```

## Related Commands

- [cat](cat.md)
- [grep](grep.md)
- [awk](awk.md)
- [sed](sed.md)
- [tee](tee.md)
