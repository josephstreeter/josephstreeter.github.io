---
title: Quick Reference (Cheat Sheet)
description: A condensed KQL cheat sheet of the most common operators and functions with one-line descriptions and tiny examples.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: reference
ms.service: azure-monitor
keywords: KQL, Kusto, cheat sheet, quick reference, operators, functions
uid: docs.infrastructure.kql.cheat-sheet
---

## KQL quick reference

A condensed lookup of the operators and functions covered in this section. For fuller explanations and examples, see [Functions and Operators](functions-and-operators.md) and [Best Practices and Performance](best-practices.md).

> [!NOTE]
> Examples use `SigninLogs` (Log Analytics / Sentinel, `TimeGenerated`). Defender Advanced Hunting tables use a `Timestamp` column instead.

## Filtering rows

| Operator | Purpose | Example |
| -------- | ------- | ------- |
| `where` | Keep rows matching a predicate | `T \| where TimeGenerated > ago(1d)` |
| `== / !=` | Case-sensitive equality | `where ResultType == "0"` |
| `=~ / !~` | Case-insensitive equality | `where Country =~ "us"` |
| `has / !has` | Whole-term match (indexed, fast) | `where ResultDescription has "failed"` |
| `contains` | Substring match (slower) | `where Account contains "adm"` |
| `startswith / endswith` | Prefix / suffix match | `where UPN endswith "domain.com"` |
| `in / !in` | Value in a set | `where UPN in ("a@x.com", "b@x.com")` |
| `has_any / has_all` | Match any / all terms in a list | `where Types has_any ("Phish", "Spam")` |
| `between` | Value within a range | `where TimeGenerated between (ago(2d) .. ago(1d))` |

## Shaping columns

| Operator | Purpose | Example |
| -------- | ------- | ------- |
| `project` | Select / compute columns (sets order) | `project TimeGenerated, UPN, IPAddress` |
| `extend` | Add a computed column, keep the rest | `extend Country = tostring(Loc.countryOrRegion)` |
| `project-away` | Remove named columns | `project-away TenantId, SourceSystem` |
| `project-rename` | Rename a column | `project-rename SignInTime = TimeGenerated` |

## Sorting and limiting

| Operator | Purpose | Example |
| -------- | ------- | ------- |
| `sort by` / `order by` | Order rows | `sort by TimeGenerated desc` |
| `top` | Highest/lowest N by a column | `top 10 by FailedAttempts desc` |
| `take` / `limit` | Return N arbitrary rows | `take 100` |
| `distinct` | Unique combinations of columns | `distinct UserPrincipalName` |
| `count` | Number of rows | `SigninLogs \| count` |

## Aggregating

| Function | Purpose | Example |
| -------- | ------- | ------- |
| `summarize` | Group and aggregate | `summarize c = count() by UPN` |
| `count()` | Count rows | `summarize Total = count()` |
| `countif()` | Count rows matching a predicate | `countif(ResultType != "0")` |
| `dcount()` | Approximate distinct count | `dcount(IPAddress)` |
| `sum / avg / min / max` | Numeric rollups | `avg(DurationMs)` |
| `make_set / make_list` | Collect values into an array | `make_set(Country)` |
| `arg_max / arg_min` | Row with the largest / smallest value | `arg_max(TimeGenerated, *) by UPN` |
| `bin()` | Time (or numeric) buckets | `by bin(TimeGenerated, 1h)` |

## Combining tables

| Operator | Purpose | Example |
| -------- | ------- | ------- |
| `union` | Concatenate compatible tables | `union T1, T2` |
| `join kind=inner` | Match rows on a key | `join kind=inner (T2) on Key` |
| `join kind=leftouter` | All left rows + matches | `join kind=leftouter (T2) on Key` |
| `join kind=leftanti` | Left rows with no match | `join kind=leftanti (T2) on Key` |

> [!IMPORTANT]
> The default join kind is `innerunique`, which de-duplicates the left table on the key. Always state the kind explicitly.

## Dynamic and JSON data

| Function | Purpose | Example |
| -------- | ------- | ------- |
| `parse_json` / `todynamic` | Parse a JSON string | `parse_json(AuthenticationDetails)` |
| `.` / `[ ]` accessor | Read a field from a dynamic value | `parse_json(x).SPF` |
| `mv-expand` | One row per array element | `mv-expand ConditionalAccessPolicies` |
| `array_length` | Number of elements in an array | `where array_length(Users) > 1` |

## Type conversions

| Function | Converts to | Function | Converts to |
| -------- | ----------- | -------- | ----------- |
| `tostring` | String | `todatetime` | Datetime |
| `toint` / `tolong` | Integer | `totimespan` | Timespan |
| `toreal` | Float | `tobool` | Boolean |

## Dates and times

| Function | Purpose | Example |
| -------- | ------- | ------- |
| `ago()` | Time relative to now | `where TimeGenerated > ago(7d)` |
| `now()` | Current UTC time | `extend Age = now() - TimeGenerated` |
| `bin()` | Round down to a bucket | `bin(TimeGenerated, 1h)` |
| `startofday / startofmonth` | Truncate to period start | `startofday(TimeGenerated)` |
| `format_datetime()` | Format as a string | `format_datetime(TimeGenerated, "yyyy-MM-dd")` |
| `datetime_diff()` | Difference in a unit | `datetime_diff('minute', t2, t1)` |

Timespan literals: `1d` (day), `1h` (hour), `30m` (minutes), `5s` (seconds).

## Conditionals and strings

| Function | Purpose | Example |
| -------- | ------- | ------- |
| `iff()` | Two-way conditional | `iff(ResultType == "0", "OK", "Fail")` |
| `case()` | Multi-branch conditional | `case(x > 90, "high", x > 50, "med", "low")` |
| `strcat()` | Concatenate strings | `strcat(FirstName, " ", LastName)` |
| `split()` | Split into an array | `split(UPN, "@")[1]` |
| `extract()` | Regex capture | `extract("id=(\\d+)", 1, Message)` |
| `replace_string()` | Replace a substring | `replace_string(Path, "\\", "/")` |

## Common patterns

**Failed sign-ins per user, last day:**

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType != "0"
| summarize FailedAttempts = count() by UserPrincipalName
| top 10 by FailedAttempts desc
```

**Sign-ins bucketed by hour and application:**

```kql
SigninLogs
| where TimeGenerated > ago(7d)
| summarize Signins = count() by bin(TimeGenerated, 1h), AppDisplayName
```

**Latest sign-in per user:**

```kql
SigninLogs
| where TimeGenerated > ago(30d)
| summarize arg_max(TimeGenerated, IPAddress, AppDisplayName) by UserPrincipalName
```

## Reference links

- [KQL quick reference - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/kql-quick-reference)
- [Functions and Operators](functions-and-operators.md)
- [Best Practices and Performance](best-practices.md)
