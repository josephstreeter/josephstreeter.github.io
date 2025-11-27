---
title: Regular Expressions (Regex) Guide (Full)
description: "Full, language-agnostic regex reference: syntax, examples, engine notes, performance tips, and testing tools."
ms.topic: reference
ms.date: 2025-11-27
---

This is the full Regular Expressions (regex) guide. It is language-agnostic and focuses on practical patterns, engine differences, testing tools, performance, and recipes you can adapt.

## Quick start

- Regex is a compact language for matching and manipulating text.
- Engines differ in features (lookbehind, atomic groups, recursion). Test in your target environment.
- Build patterns incrementally and validate with realistic inputs.

## Metacharacters and tokens

- `.` — any character except newline (unless dotall)
- `\d` — digit
- `\D` — non-digit
- `\w` — word character (letter, digit, underscore)
- `\W` — non-word
- `\s` — whitespace
- `\S` — non-whitespace
- `^` — start of string/line (with `m`)
- `$` — end of string/line (with `m`)
- `[]` — character class
- `[^...]` — negated class
- `|` — alternation

## Quantifiers

- `*` — 0 or more
- `+` — 1 or more
- `?` — 0 or 1
- `{n}` — exactly n
- `{n,}` — n or more
- `{n,m}` — between n and m

Greedy vs lazy: add `?` to make quantifiers lazy (`.*?`). Use possessive or atomic groups where supported to avoid backtracking.

## Groups and captures

- `( ... )` — capturing group
- `(?: ... )` — non-capturing
- Named groups: `(?<name>...)` or `(?P<name>...)` (syntax varies)
- Backrefs: `\1`, `\k<name>`

## Lookarounds

- Positive lookahead: `(?=...)`
- Negative lookahead: `(?!...)`
- Positive lookbehind: `(?<=...)` (may require fixed width)
- Negative lookbehind: `(?<!...)`

Example: `foo(?=bar)` matches `foo` only when followed by `bar`.

## Common patterns

- Simple email (not RFC): `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
- URL (basic): `\bhttps?://[\w.-]+(?:/[^\s]*)?`
- US phone: `^(?:\+1[-.\s]?)?(?:\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}$`

## Flags / modifiers

- `i` — case-insensitive
- `m` — multiline
- `s` — dotall (dot matches newline)
- `x` — verbose (ignore whitespace in pattern)
- `u` — unicode (language dependent)

## Engine notes

- PCRE: feature-rich (lookbehind, recursion, conditionals)
- JavaScript: modern ES engines support named groups and (in many runtimes) lookbehind
- Python `re`: solid feature set; `regex` package adds more
- .NET: advanced constructs (balancing groups)
- PowerShell: uses .NET regex engine; supports `-match`, `-replace` operators and `[regex]` type
- Java: `java.util.regex` — note string literal escaping

## Performance

- Avoid catastrophic backtracking (nested ambiguous quantifiers).
- Prefer explicit character classes to `.` when possible.
- Anchor patterns when validating full strings (`^...$`).
- Use atomic/possessive groups where available to prevent backtracking.

## Tools

- regex101.com — interactive debugger and explanation
- regexr.com — visual tester
- language REPLs, `pcretest`, and CLI tools for quick checks

## Recipes

1) Remove dots and aliases from email local-part

   - Find: `(\.(?=[^@]*@))|\+[^@]*?(?=@)`
   - Replace with empty string

2) Quote each line (multiline)

   - Find: `^(.+)$`
   - Replace: `"$1"`

3) Convert CRLF to commas

   - Find: `\r\n` — Replace: `,`

## Further reading

- [Regular-Expressions.info](https://www.regular-expressions.info/) — canonical tutorials and reference.
- Jeffrey Friedl — Mastering Regular Expressions

If you want, I can make this the canonical `index.md` content or keep `index.md` as a short landing that links to this file. Which do you prefer?

## JavaScript examples {#javascript}

- Basic test (ES2018+):

```javascript
// match simple email
const re = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/i;
re.test('user@example.com');
```

- Named capture and usage:

```javascript
const re2 = /(?<user>[A-Za-z0-9._%+-]+)@(?<host>[A-Za-z0-9.-]+\.[A-Za-z]{2,})/;
const m = re2.exec('user@example.com');
console.log(m.groups.user, m.groups.host);
```

## Python examples {#python}

- Basic test:

```python
import re
re.match(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'user@example.com') is not None
```

- Named groups and search:

```python
import re
pat = re.compile(r'(?P<user>[A-Za-z0-9._%+-]+)@(?P<host>[A-Za-z0-9.-]+\.[A-Za-z]{2,})')
m = pat.search('user@example.com')
if m:
   print(m.group('user'), m.group('host'))
```

## .NET examples {#dotnet}

- C# (System.Text.RegularExpressions):

```csharp
using System.Text.RegularExpressions;
var re = new Regex(@"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$", RegexOptions.IgnoreCase);
re.IsMatch("user@example.com");
```

- Named groups and captures:

```csharp
var re2 = new Regex(@"(?<user>[A-Za-z0-9._%+-]+)@(?<host>[A-Za-z0-9.-]+\.[A-Za-z]{2,})");
var m = re2.Match("user@example.com");
if (m.Success) Console.WriteLine(m.Groups["user"].Value + " " + m.Groups["host"].Value);
```

## PowerShell examples {#powershell}

- Basic test using `-match` operator:

```powershell
# Test if string matches pattern (case-insensitive by default)
'user@example.com' -match '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

# Case-sensitive match
'user@example.com' -cmatch '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
```

- Access captured groups using `$Matches`:

```powershell
# After a successful -match, $Matches contains captured groups
if ('user@example.com' -match '(?<User>[A-Za-z0-9._%+-]+)@(?<Host>[A-Za-z0-9.-]+\.[A-Za-z]{2,})') 
{
    Write-Output "User: $($Matches.User)"
    Write-Output "Host: $($Matches.Host)"
}
```

- Using `[regex]` type accelerator for advanced operations:

```powershell
# Create regex object with options
$Regex = [regex]::new('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'IgnoreCase')
$Regex.IsMatch('user@example.com')

# Replace operation
$Text = 'Contact: user@example.com'
[regex]::Replace($Text, '\b[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}\b', '[redacted]')
```

- Select-String for file search (grep-like):

```powershell
# Find lines matching pattern in files
Get-Content .\logfile.txt | Select-String -Pattern '\b\d{3}-\d{3}-\d{4}\b'

# With named captures
$Results = Select-String -Path .\data.txt -Pattern '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Level>\w+)'
$Results | ForEach-Object { $_.Matches.Groups }
```

- Replace using `-replace` operator:

```powershell
# Replace all digits with 'X'
'Order ID: 12345' -replace '\d', 'X'

# Remove non-alphanumeric characters
'Hello, World! 2025' -replace '[^\w\s]', ''

# Named group substitution
'user@example.com' -replace '(?<Local>.+)@(?<Domain>.+)', '${Local} at ${Domain}'
```
