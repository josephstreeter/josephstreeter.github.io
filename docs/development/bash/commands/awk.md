---
title: awk Command
description: Comprehensive reference for the awk command in Bash, including syntax, patterns, fields, built-in variables, and practical examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/25/2026
ms.topic: reference
ms.service: development
---

The `awk` command is a pattern-scanning and text-processing language designed for structured text.
It is especially useful for log analysis, CSV-like data extraction, reporting, and one-line transformations.

## Overview

Use `awk` when you need to:

- Split lines into fields and operate on specific columns
- Filter records using conditions and regular expressions
- Aggregate data (sum, counts, min/max)
- Reformat text output into reports
- Perform lightweight ETL-style transformations in shell pipelines

## Syntax

```bash
awk [options] 'program' [file...]
```

Common invocation forms:

```bash
# Inline program
awk 'pattern { action }' input.txt

# Set field separator
awk -F',' '{ print $1, $3 }' data.csv

# Load program from file
awk -f script.awk input.txt

# Pass variables from shell
awk -v limit=100 '$2 > limit { print $0 }' metrics.txt
```

`awk` evaluates each input record (usually one line at a time), applies matching patterns,
and executes actions for records that match.

## Program Structure

An `awk` program is made of pattern-action pairs:

```awk
pattern { action }
```

Special blocks:

- `BEGIN { ... }`: Runs once before reading input
- `END { ... }`: Runs once after all input is processed
- Omitted pattern: Action runs for every record
- Omitted action: Matching records are printed by default

Example:

```bash
awk 'BEGIN { print "Start" } /ERROR/ { print NR, $0 } END { print "Done" }' app.log
```

## Fields and Records

By default:

- Record separator `RS` is newline
- Field separator `FS` is whitespace

Useful field and record references:

| Token | Meaning |
| --- | --- |
| `$0` | Entire current record (line) |
| `$1` ... `$N` | Individual fields |
| `NF` | Number of fields in current record |
| `NR` | Current overall record number |
| `FNR` | Current record number in current file |

Field separator examples:

```bash
# Comma-separated fields
awk -F',' '{ print $1, $2 }' users.csv

# Colon-separated fields (e.g., /etc/passwd)
awk -F: '{ print $1, $7 }' /etc/passwd
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-F` | Set input field separator | `-F','` |
| `-v` | Define variable before execution | `-v threshold=90` |
| `-f` | Read awk program from file | `-f report.awk` |
| `--` | End options (GNU awk) | `awk -- '...' file` |

## Operators and Conditions

Common comparison operators:

- `==`, `!=`, `<`, `<=`, `>`, `>=`

Common logical operators:

- `&&` (AND), `||` (OR), `!` (NOT)

Regex matching operators:

- `~` matches regex
- `!~` does not match regex

Examples:

```bash
# Numeric filter
awk '$3 >= 100 { print $1, $3 }' sales.txt

# Regex filter
awk '$0 ~ /ERROR|WARN/ { print NR, $0 }' app.log

# Combined logic
awk '$2 == "active" && $5 > 10 { print $1 }' accounts.txt
```

## Built-In Variables

| Variable | Meaning |
| --- | --- |
| `FS` | Input field separator |
| `OFS` | Output field separator |
| `RS` | Input record separator |
| `ORS` | Output record separator |
| `NF` | Number of fields in current record |
| `NR` | Total records read so far |
| `FNR` | Records read in current file |
| `FILENAME` | Current input filename |

Formatting output with `OFS`:

```bash
awk -F',' 'BEGIN { OFS=" | " } { print $1, $3, $5 }' data.csv
```

## Useful Built-In Functions

| Function | Purpose | Example |
| --- | --- | --- |
| `length(s)` | Length of string | `length($1)` |
| `substr(s, i, n)` | Substring | `substr($1, 1, 3)` |
| `index(s, t)` | Position of substring | `index($0, "ERROR")` |
| `tolower(s)` / `toupper(s)` | Case conversion | `tolower($1)` |
| `split(s, a, sep)` | Split string into array | `split($1, parts, ":")` |
| `gsub(r, x, s)` | Replace all matches | `gsub(/foo/, "bar", $0)` |
| `sub(r, x, s)` | Replace first match | `sub(/^[ ]+/, "", $0)` |
| `sprintf(fmt, ...)` | Build formatted string | `sprintf("%.2f", $3)` |

## Examples

```bash
# Print first and third columns from CSV
awk -F',' '{ print $1, $3 }' data.csv
```

```bash
# Print line numbers for matching log entries
awk '/ERROR/ { print NR ": " $0 }' app.log
```

```bash
# Sum values in column 2
awk '{ sum += $2 } END { print sum }' metrics.txt
```

```bash
# Count occurrences by key (column 1)
awk '{ count[$1]++ } END { for (k in count) print k, count[k] }' events.txt
```

```bash
# Print username and shell from /etc/passwd
awk -F: '{ print $1, $7 }' /etc/passwd
```

```bash
# Skip header row in CSV and print selected fields
awk -F',' 'NR > 1 { print $1, $4 }' users.csv
```

```bash
# Replace text inline in output stream (without modifying source file)
awk '{ gsub(/staging/, "production"); print }' config.txt
```

## Safe Usage Guidelines

1. Quote awk programs with single quotes in Bash to prevent shell expansion.
2. Validate delimiters (`-F`) before assuming column positions.
3. Test transformations on sample data before applying to production pipelines.
4. Use explicit numeric conversions when needed to avoid string/number confusion.
5. Prefer readable multi-line awk scripts (`-f`) for complex logic.

## Performance Tips

1. Filter early with patterns to avoid unnecessary action blocks.
2. Avoid expensive regex operations when simple field comparisons are sufficient.
3. Use one `awk` pass for multiple calculations instead of chaining many tools.
4. For very large inputs, reduce string allocations and unnecessary concatenation.

## Troubleshooting

### Fields are not splitting correctly

Cause: Incorrect field separator.

Fix: Verify delimiter and set `-F` explicitly.

```bash
awk -F',' '{ print NF, $0 }' data.csv
```

### Variables from shell are empty inside awk

Cause: Shell variable not passed with `-v`.

Fix: Pass values explicitly:

```bash
awk -v needle="$Needle" '$0 ~ needle { print }' app.log
```

### Output order from associative arrays looks random

Cause: Iteration order for `for (k in arr)` is not guaranteed.

Fix: Pipe output to `sort` when deterministic ordering is required.

```bash
awk '{ count[$1]++ } END { for (k in count) print k, count[k] }' events.txt | sort
```

## Notes

Most Linux distributions provide GNU Awk (`gawk`) by default.
Run `man awk` and `man gawk` for implementation-specific details.

## Related Commands

- [grep](grep.md)
- [sed](sed.md)
- [find](find.md)
- [tee](tee.md)
