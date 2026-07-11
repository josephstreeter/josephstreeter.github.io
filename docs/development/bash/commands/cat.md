---
title: cat Command
description: Comprehensive reference for the cat command in Bash, including syntax, options, common patterns, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `cat` command concatenates files and writes their contents to standard output.
It is commonly used to quickly inspect files, combine multiple files, and feed content into pipelines.

## Overview

Use `cat` when you need to:

- Display file contents directly in the terminal
- Concatenate several files into one output stream
- Create small files from terminal input
- Number lines or visualize non-printing characters
- Bridge content between files and pipelines

## Syntax

```bash
cat [options] [file...]
```

Common forms:

```bash
# Display one file
cat notes.txt

# Concatenate multiple files in order
cat part1.txt part2.txt part3.txt

# Read from standard input explicitly
cat -

# Write output to a new file via redirection
cat source.txt > copy.txt
```

If no files are provided, `cat` reads from standard input.

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-n` | Number all output lines | `cat -n file.txt` |
| `-b` | Number non-empty output lines | `cat -b file.txt` |
| `-s` | Squeeze repeated blank lines | `cat -s file.txt` |
| `-E` | Show `$` at end of each line | `cat -E file.txt` |
| `-T` | Show tab characters as `^I` | `cat -T file.txt` |
| `-v` | Show non-printing chars (except tab/newline) | `cat -v file.txt` |
| `-A` | Equivalent to `-vET` (show all) | `cat -A file.txt` |

## Behavior Notes

- Input files are processed left to right.
- `cat` does not modify source files.
- Binary files can produce unreadable terminal output; redirect when needed.
- Large outputs may scroll quickly, so pair with `less` when reviewing.

## Examples

```bash
# Display a configuration file
cat config.yaml
```

```bash
# Concatenate log segments into one file
cat app.log.1 app.log.2 app.log.3 > combined.log
```

```bash
# Number all lines
cat -n script.sh
```

```bash
# Number non-blank lines only
cat -b document.txt
```

```bash
# Visualize tabs and line endings
cat -A data.tsv
```

```bash
# Collapse repeated blank lines before viewing
cat -s notes.txt
```

```bash
# Create a file from terminal input (Ctrl+D to finish)
cat > quick-note.txt
```

```bash
# Append terminal input to existing file (Ctrl+D to finish)
cat >> quick-note.txt
```

```bash
# Combine with grep in a pipeline (usually grep can read files directly)
cat app.log | grep -i error
```

## Here-Document Alternative

For multi-line file creation in scripts, a here-document is often clearer:

```bash
cat > app.env <<'EOF'
APP_NAME=sample
APP_ENV=dev
LOG_LEVEL=info
EOF
```

## Safe Usage Guidelines

1. Use `less` for long output: `cat file | less`.
2. Be careful with redirection targets to avoid overwriting files accidentally.
3. Use `-A` when debugging whitespace-sensitive files.
4. Prefer direct command input over useless pipes when possible (`grep pattern file` instead of `cat file | grep pattern`).

## Performance and Practical Tips

1. For very large files, `less`, `head`, and `tail` are often more efficient for interactive inspection.
2. Use `cat` to concatenate files; use `paste`/`awk` when column-aware merging is required.
3. Avoid printing binary files directly to interactive terminals.

## Troubleshooting

### `cat: file: No such file or directory`

Cause: Wrong path or filename.

Fix: Verify path and current directory.

```bash
pwd
ls -la
cat ./relative/path/file.txt
```

### Terminal appears garbled after viewing a file

Cause: Binary or control characters were written to the terminal.

Fixes:

- Use `cat -v` or `hexdump -C` for inspection
- Reset terminal state with `reset`

### Unexpected overwrite when creating files with `cat > file`

Cause: `>` truncates destination before writing.

Fix: Use `>>` to append, or verify target path before running.

## Notes

`cat` is simple and ubiquitous, but it is best paired with other tools for filtering,
searching, and paging.

For command details and implementation-specific behavior, run:

```bash
man cat
cat --help
```

## Related Commands

- [less](less.md)
- [head](head.md)
- [tail](tail.md)
- [tee](tee.md)
- [grep](grep.md)
