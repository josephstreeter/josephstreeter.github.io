---
title: sed Command
description: Comprehensive reference for the sed command in Bash, including syntax, addressing, regex usage, scripts, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `sed` command (stream editor) performs non-interactive text transformations on input streams.
It is commonly used in shell pipelines for substitutions, filtering, and line-oriented edits.

## Overview

Use `sed` when you need to:

- Replace text using regular expressions
- Print, suppress, or delete lines that match patterns
- Edit files in place (with caution)
- Perform lightweight structured edits in scripts and CI pipelines
- Transform command output without opening an interactive editor

## Syntax

```bash
sed [options] 'script' [file...]
```

Common forms:

```bash
# One inline expression
sed 's/old/new/g' file.txt

# Multiple expressions
sed -e 's/foo/bar/' -e '/^#/d' config.ini

# Script file
sed -f edits.sed input.txt

# In-place edit (GNU and BSD sed; semantics differ slightly)
sed -i.bak 's/dev/prod/g' app.env
```

`sed` reads input line by line into a pattern space, applies commands, then writes output.
By default, each processed line is printed once unless output behavior is changed.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-n` | Suppress automatic printing | `sed -n '/ERROR/p' app.log` |
| `-e` | Add expression | `sed -e 's/a/b/' -e '/^$/d' file` |
| `-f` | Load expressions from script file | `sed -f script.sed input.txt` |
| `-i[SUFFIX]` | Edit files in place (optional backup suffix) | `sed -i.bak 's/x/y/' file` |
| `-E` | Extended regex (portable modern choice) | `sed -E 's/(foo|bar)/x/g' file` |
| `-r` | Extended regex (GNU sed legacy alias) | `sed -r 's/(foo|bar)/x/g' file` |

## How sed Processes Input

Core concepts:

- Pattern space: Current line or multiline buffer being edited
- Hold space: Secondary buffer for temporary storage
- Address: Selector for where a command applies
- Command: Action performed on selected input

Basic cycle:

1. Read next line into pattern space
2. Apply matching commands in order
3. Print pattern space (unless `-n` or deleted)
4. Repeat

## Addressing

Addresses scope commands to specific lines or matches.

Single-address examples:

```bash
# Apply substitution only on line 3
sed '3s/foo/bar/' file.txt

# Print only lines matching a pattern
sed -n '/ERROR/p' app.log
```

Range-address examples:

```bash
# Delete lines 5 through 10
sed '5,10d' file.txt

# Print from first START to next END
sed -n '/START/,/END/p' doc.txt
```

Negated address example:

```bash
# Delete all lines except line 1
sed '1!d' file.txt
```

## Core sed Commands

| Command | Meaning | Example |
| --- | --- | --- |
| `s/old/new/flags` | Substitute text | `s/error/warn/g` |
| `p` | Print pattern space | `/ERROR/p` |
| `d` | Delete pattern space and restart cycle | `/^#/d` |
| `a\` | Append text after current line | `/host/a\\127.0.0.1 localhost` |
| `i\` | Insert text before current line | `/host/i\\# local mapping` |
| `c\` | Change addressed lines to new text | `2,4c\\REDACTED` |
| `y/src/dst/` | Transliterate characters | `y/abc/ABC/` |
| `q` | Quit early | `100q` |
| `=` | Print current line number | `sed -n '/foo/{=;p;}' file` |
| `r file` | Read and insert file content after line | `/MARK/r extra.txt` |
| `w file` | Write matched pattern space to file | `/ERROR/w errors.log` |
| `h`, `H`, `g`, `G`, `x` | Hold-space operations | see hold-space examples |
| `n`, `N`, `P`, `D` | Multiline control commands | see multiline examples |

## Substitution Flags

Common `s///` flags:

- `g`: Replace all matches on the line
- `N` (number): Replace only the Nth match, such as `s/x/y/2`
- `p`: Print line when substitution occurred (often with `-n`)
- `I` or `i`: Case-insensitive match (GNU sed; portability varies)

Examples:

```bash
# Replace first match per line
sed 's/cat/dog/' file.txt

# Replace all matches per line
sed 's/cat/dog/g' file.txt

# Replace only second occurrence per line
sed 's/cat/dog/2' file.txt

# Print only lines where replacement happened
sed -n 's/cat/dog/p' file.txt
```

## Regular Expressions

`sed` uses Basic Regular Expressions (BRE) by default.
Use `-E` for Extended Regular Expressions (ERE).

BRE vs ERE examples:

```bash
# BRE: group with escaped parentheses
sed 's/\(foo\|bar\)/X/g' file.txt

# ERE: cleaner grouping and alternation
sed -E 's/(foo|bar)/X/g' file.txt
```

Useful patterns:

- `^` start of line
- `$` end of line
- `.` any single character
- `[0-9]` character class
- `[^ ]` negated class
- `*` zero or more
- `+`, `?`, `|`, `()` with `-E`

## Script Files

For complex edits, keep commands in a `.sed` script file.

Example `cleanup.sed`:

```sed
# Remove comments and empty lines
/^[[:space:]]*#/d
/^[[:space:]]*$/d

# Normalize key-value separator spacing
s/[[:space:]]*=[[:space:]]*/ = /g
```

Run it:

```bash
sed -f cleanup.sed config.ini
```

## In-Place Editing Safely

In-place editing is useful but can be destructive.

Safer pattern:

```bash
sed -i.bak 's/localhost/127.0.0.1/g' app.conf
```

Guidelines:

1. Always use a backup suffix (`-i.bak`) for critical files.
2. Test with output-only mode before writing:
   `sed 's/old/new/g' file | less`
3. For many files, use `find` with care and test a subset first.

GNU/BSD portability note:

- GNU sed: `-i` without suffix is valid.
- BSD sed (macOS): often expects an explicit suffix argument or empty string pattern.
- The most portable habit is providing a suffix: `-i.bak`.

## Examples

```bash
# Replace all tabs with four spaces
sed 's/\t/    /g' script.sh
```

```bash
# Remove blank lines
sed '/^[[:space:]]*$/d' file.txt
```

```bash
# Remove comment lines beginning with #
sed '/^[[:space:]]*#/d' config.ini
```

```bash
# Print only lines 20 to 40
sed -n '20,40p' app.log
```

```bash
# Replace only in a section (from [prod] to next [section])
sed -E '/^\[prod\]/,/^\[.*\]/{ s/(timeout[[:space:]]*=[[:space:]]*)[0-9]+/\130/g; }' app.ini
```

```bash
# Swap first two CSV columns (simple CSV without quoted commas)
sed -E 's/^([^,]*),([^,]*)/\2,\1/' data.csv
```

```bash
# Delete trailing whitespace
sed 's/[[:space:]]\+$//' file.txt
```

```bash
# Prefix each line with line number and colon
sed = file.txt | sed 'N;s/\n/: /'
```

## Multiline and Hold-Space Examples

Join lines ending with backslash continuation:

```bash
sed -E ':a; /\\$/ { N; s/\\\n//; ba; }' input.txt
```

Print paragraph blocks separated by blank lines:

```bash
sed -n '/./{H;$!d}; x; s/^\n//; p' file.txt
```

Reverse lines in a file (illustrates hold space usage):

```bash
sed '1!G;h;$!d' file.txt
```

## Integration Patterns

Use with pipelines:

```bash
journalctl -u nginx -n 500 | sed -n '/error/Ip'
```

Use with `find` and null-safe loops for batch edits:

```bash
find . -type f -name '*.md' -print0 |
  while IFS= read -r -d '' f; do
    sed -i.bak 's/OldProduct/NewProduct/g' "$f"
  done
```

## Safe Usage Guidelines

1. Quote expressions with single quotes in Bash to avoid accidental shell expansion.
2. Prefer `-E` when patterns need grouping or alternation for readability.
3. Validate commands on sample data before using `-i`.
4. Use explicit backups for production edits.
5. Keep complex transformations in script files for maintainability.

## Troubleshooting

### `sed: ... unterminated 's' command`

Cause: Delimiter collision or missing delimiter.

Fix: Use a different delimiter if your pattern contains `/`.

```bash
sed 's|/var/www|/srv/www|g' paths.txt
```

### Replacement contains `&` unexpectedly

Cause: In replacement text, `&` expands to the full matched string.

Fix: Escape literal ampersands as `\&`.

```bash
sed 's/R&D/R\&D/g' file.txt
```

### Works on Linux but fails on macOS

Cause: GNU vs BSD sed option or regex differences.

Fixes:

- Use `-E` instead of GNU-only `-r`
- Use `-i.bak` for in-place editing portability
- Avoid GNU-specific escapes unless required

## Notes

For very complex parsing of nested or fully structured formats (JSON, XML),
use dedicated tools such as `jq`, `yq`, or language-specific parsers.

For command details and implementation-specific behavior, run:

```bash
man sed
sed --help
```

## Related Commands

- [awk](awk.md)
- [grep](grep.md)
- [find](find.md)
- [tee](tee.md)
