---
title: Bash Text Processing and Search Commands
description: Common Bash commands for searching, filtering, transforming, and inspecting text data.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 05/21/2026
ms.topic: conceptual
ms.service: development
---

Text processing is a core part of shell scripting and operations work. This page summarizes commands you will use frequently.

## Search and Filter Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `grep` | Match patterns in text | `grep -E "ERROR\|WARN" app.log` |
| `find` | Locate files by criteria | `find . -name "*.md"` |
| `sort` | Sort lines | `sort users.txt` |
| `uniq` | Remove adjacent duplicates | `sort users.txt \| uniq` |
| `cut` | Extract delimited fields | `cut -d',' -f1 data.csv` |

## Transform Commands

| Command | Purpose | Example |
| ------ | ------- | ------- |
| `awk` | Pattern scanning and field logic | `awk -F',' '{print $1}' data.csv` |
| `sed` | Stream editing and replacement | `sed 's/old/new/g' file.txt` |
| `tr` | Translate or delete characters | `tr '[:lower:]' '[:upper:]' < file.txt` |
| `xargs` | Build command arguments from input | `find . -name "*.log" \| xargs rm` |
| `paste` | Merge lines from files | `paste names.txt ids.txt` |

## Useful Pipelines

```bash
# Show top 10 IPs in a log file
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -n 10
```

```bash
# Find markdown files containing TODO comments
find . -name '*.md' -type f -print0 |
xargs -0 grep -n "TODO"
```

## Safe Usage Tips

1. Prefer `grep -n` while troubleshooting so line numbers are included.
2. Use `find ... -print0` with `xargs -0` to handle spaces safely.
3. Test `sed` commands on sample files before bulk updates.
4. Use `LC_ALL=C` for predictable byte-wise sorting in scripts.
