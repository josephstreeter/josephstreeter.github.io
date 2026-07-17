---
title: Functions and Operators
description: Reference material for common KQL operators and functions including where, project, join, summarize, parse_json, and datetime handling.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: conceptual
ms.service: azure-monitor
keywords: KQL, Kusto, where, project, extend, join, union, summarize, parse_json, mv-expand, datetime
---

## Common KQL Operators and Functions

This page walks through the operators in roughly the order you use them when building a query: filter rows, shape columns, sort and limit, aggregate, combine tables, and work with dynamic, date, and string values.

> [!NOTE]
> The examples on this page use `SigninLogs` (a Log Analytics / Sentinel table with a `TimeGenerated` column) unless noted otherwise. In Microsoft 365 Defender Advanced Hunting the equivalent tables use a `Timestamp` column instead. See [Where KQL runs and why schemas differ](index.md#where-kql-runs-and-why-schemas-differ).

## Filtering rows with `where`

The `where` operator keeps only the rows that match a predicate. Putting `where` early in the pipeline - especially a time filter - is the most important thing you can do for query performance, because it reduces how much data every later step has to process.

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType != "0"
| where AppDisplayName == "Microsoft Teams"
```

### String and comparison operators

| Operator | Meaning | Notes |
| ---------- | --------- | ------- |
| `==` / `!=` | Equals / not equals | Case-sensitive for strings; use `=~` / `!~` for case-insensitive |
| `has` / `!has` | Whole-term match | **Indexed and fast** - prefer this for word matches |
| `contains` / `!contains` | Substring match | Not indexed and slower - only when you truly need a partial match |
| `startswith` / `endswith` | Prefix / suffix match | Case-insensitive; `_cs` variants are case-sensitive |
| `in` / `!in` | Value in a set | Case-sensitive; use `in~` / `!in~` for case-insensitive |
| `has_any` / `has_all` | Matches any / all terms in a list | Useful for keyword lists |
| `matches regex` | Regular-expression match | Powerful but slower than `has` |
| `between` | Value within a range | Works for numbers and datetimes: `between (datetime(2025-01-01) .. datetime(2025-01-31))` |

> [!TIP]
> Prefer `has` over `contains` whenever you are matching whole words. `has` uses the string index and scans far less data; `contains` inspects every character of every value.

## Shaping columns with `project` and `extend`

Use these operators to control which columns flow down the pipeline and to add calculated columns.

- `project` - Select the columns to keep, in the order listed. Also used to compute new columns.
- `extend` - Add calculated columns **without** removing the existing ones.
- `project-away` - Remove specific columns, keeping everything else.
- `project-keep` - Keep only columns matching the given names or patterns.
- `project-rename` - Rename a column.

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| extend Country = tostring(LocationDetails.countryOrRegion)
| project-rename SignInTime = TimeGenerated
| project SignInTime, UserPrincipalName, IPAddress, Country
```

> [!TIP]
> Reach for `project` early to drop columns you do not need, and use `extend` when you only want to add a computed column while keeping the rest of the row intact.

## Sorting, limiting, and de-duplicating

| Operator | Purpose |
| ---------- | --------- |
| `sort by <col> [asc\|desc]` | Order rows by one or more columns (`order by` is a synonym) |
| `top <N> by <col>` | Return the N rows with the highest/lowest value of a column |
| `take <N>` / `limit <N>` | Return N arbitrary rows - useful for quickly sampling a table |
| `distinct <cols>` | Return the unique combinations of the listed columns |
| `count` | Return the number of rows as a single value |

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType != "0"
| summarize FailedAttempts = count() by UserPrincipalName
| top 10 by FailedAttempts desc
```

> [!TIP]
> `top N by <col>` is more efficient than `sort` followed by `take`, because the engine only has to track the top N rows rather than order the entire result set.

## Aggregating data with `summarize`

The KQL operator is `summarize` (not `summary`). It groups rows into buckets and calculates aggregate values for each group. This is the primary way to roll up logs into counts, totals, averages, or sets.

```kql
SigninLogs
| where TimeGenerated > ago(7d)
| summarize
    TotalAttempts = count(),
    FailedAttempts = countif(ResultType != "0"),
    DistinctUsers = dcount(UserPrincipalName),
    DistinctIPs = dcount(IPAddress),
    Countries = make_set(tostring(LocationDetails.countryOrRegion))
    by bin(TimeGenerated, 1h), AppDisplayName
```

The aggregation functions below also include numeric rollups such as `avg()`, `sum()`, `min()`, and `max()` for tables that carry numeric measures (for example `Perf` or `AzureMetrics`).

Common aggregation functions include:

- `count()` - Counts the number of rows in each group.
- `countif(predicate)` - Counts rows where the predicate evaluates to `true`.
- `sum(column)` - Adds numeric values across the group.
- `avg(column)` - Calculates the average value.
- `min(column)` and `max(column)` - Return the smallest or largest value.
- `dcount(column)` - Returns the approximate distinct count for a column.
- `make_set(column)` and `make_list(column)` - Collect values into an array.
- `arg_min(column, ...)` and `arg_max(column, ...)` - Return other columns from the row with the smallest/largest value.

Use the `by` clause to define grouping keys, and `bin()` when you want time-based buckets such as hourly or daily summaries.

```kql
EmailEvents
| where Timestamp > ago(1d)
| summarize MessagesSent = count(), PhishDetected = countif(ThreatTypes has "Phish") by bin(Timestamp, 1h), SenderFromAddress
| order by Timestamp desc
```

## Combining tables with `union` and `join`

### `union`

`union` concatenates the rows of two or more tables that have compatible schemas. Use `withsource` to record which table each row came from.

```kql
union withsource = SourceTable SigninLogs, AADNonInteractiveUserSignInLogs
| where TimeGenerated > ago(1d)
| summarize Events = count() by SourceTable
```

### `join`

`join` merges rows from two tables on a matching key, similar to a SQL join.

```kql
let FailedSignins =
    SigninLogs
    | where TimeGenerated > ago(1d)
    | where ResultType != "0"
    | distinct UserPrincipalName;
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType == "0"
| join kind=inner FailedSignins on UserPrincipalName
| distinct UserPrincipalName
```

> [!IMPORTANT]
> The **default join kind is `innerunique`**, not `inner`. `innerunique` first de-duplicates the left table on the join key, which can silently drop rows you expected to see. Always state the kind explicitly (`kind=inner`, `kind=leftouter`, and so on) so the result is predictable.

Common join kinds:

- `inner` - Rows with a matching key in both tables (keeps all matches).
- `innerunique` - The default; de-duplicates the left side on the key first.
- `leftouter` - All rows from the left table, with matches from the right where they exist.
- `leftsemi` / `leftanti` - Left rows that **do** / **do not** have a match on the right (the right table's columns are not returned).

## Working with dynamic and JSON data

### Parse JSON into columns

The `parse_json()` function extracts values from JSON strings. This is particularly common in log data that stores complex payloads as strings. (`todynamic()` is a synonym.)

```kql
extend SPF_ = parse_json(AuthenticationDetails).SPF
```

**Example - Extracting email authentication details:**

```kql
EmailEvents
| where RecipientEmailAddress endswith "gmail.com"
| extend SPF_ = parse_json(AuthenticationDetails).SPF
| extend DKIM_ = parse_json(AuthenticationDetails).DKIM
| extend DMARC_ = parse_json(AuthenticationDetails).DMARC
| project Timestamp, RecipientEmailAddress, SenderFromAddress, SenderIPv4, SenderIPv6, SPF_, DMARC_, DKIM_, LatestDeliveryAction
```

> [!TIP]
> Values pulled out of a dynamic object keep the `dynamic` type. Wrap them in `tostring()`, `toint()`, or a similar conversion function before comparing, sorting, or joining on them.

### `mv-expand` operator

The `mv-expand` operator expands multi-value dynamic arrays or property bags into multiple records.

> [!IMPORTANT]
> `mv-expand` is essential when working with arrays in KQL. It transforms one row with an array into multiple rows, one for each array element.

**Example - Expanding conditional access policies:**

Each sign-in event stores its applied conditional access policies as an array. Use `mv-expand` to produce one row per policy, then pull individual fields out of each element.

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| mv-expand ConditionalAccessPolicies
| extend PolicyName = tostring(ConditionalAccessPolicies.displayName)
| extend PolicyResult = tostring(ConditionalAccessPolicies.result)
| project TimeGenerated, UserPrincipalName, PolicyName, PolicyResult
```

## Converting data types

Log fields are often stored as strings or `dynamic` values, so explicit conversion is frequently required before comparison or arithmetic.

| Function | Converts to |
| ---------- | ------------- |
| `tostring(x)` | String |
| `toint(x)` / `tolong(x)` | 32-bit / 64-bit integer |
| `toreal(x)` | Floating-point number |
| `tobool(x)` | Boolean |
| `todatetime(x)` | Datetime |
| `totimespan(x)` | Timespan |
| `todynamic(x)` / `parse_json(x)` | Dynamic (JSON) object |

```kql
SigninLogs
| extend City = tostring(LocationDetails.city)
| extend RiskLevel = toint(RiskLevelDuringSignIn)
```

## Working with dates and times

Datetime and timespan handling underpins nearly every query. Timespan literals combine a number with a unit: `1d` (day), `1h` (hour), `30m` (minutes), `5s` (seconds).

| Function | Purpose |
| ---------- | --------- |
| `ago(timespan)` | A time relative to now, e.g. `ago(7d)` for seven days ago |
| `now()` | The current UTC time |
| `bin(value, roundTo)` | Round a value down to a bucket, e.g. `bin(TimeGenerated, 1h)` |
| `startofday()` / `startofweek()` / `startofmonth()` | Truncate a datetime to the start of the period |
| `format_datetime(dt, format)` | Format a datetime as a string |
| `datetime_diff('unit', a, b)` | Difference between two datetimes in the given unit |

```kql
SigninLogs
| where TimeGenerated > ago(30d)
| summarize DailySignins = count() by Day = startofday(TimeGenerated)
| order by Day asc
```

> [!NOTE]
> KQL datetimes are always in **UTC**. If you need local time, convert explicitly - the query engine does not apply a time zone for you.

## Conditionals and string functions

### Conditional logic

- `iff(condition, ifTrue, ifFalse)` - Returns one of two values based on a condition (`iif` is a synonym).
- `case(pred1, val1, pred2, val2, ..., default)` - Multi-branch conditional; returns the value for the first matching predicate.

```kql
SigninLogs
| extend SignInResult = iff(ResultType == "0", "Success", "Failure")
| extend Severity = case(
    RiskLevelDuringSignIn == "high", "Investigate",
    RiskLevelDuringSignIn == "medium", "Monitor",
    "Normal")
```

### String manipulation

- `strcat(a, b, ...)` - Concatenate strings; `strcat_delim(delim, ...)` joins with a separator.
- `substring(source, start, length)` - Extract part of a string.
- `split(source, delimiter)` - Split a string into an array.
- `extract(regex, captureGroup, source)` - Pull a value out of a string with a regular expression.
- `replace_string(source, lookup, rewrite)` - Replace occurrences of a substring.
- `toupper()` / `tolower()` / `trim()` - Change case or strip characters.

```kql
SigninLogs
| extend Domain = tostring(split(UserPrincipalName, "@")[1])
| summarize Signins = count() by Domain
| order by Signins desc
```

## Reference links

- [where operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/where-operator)
- [project operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/project-operator)
- [join operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/join-operator)
- [summarize operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/summarize-operator)
- [countif() (aggregation function) - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/countif-aggregation-function)
- [aggregation functions - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/aggregation-functions)
- [mv-expand operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/mv-expand-operator)
- [Scalar data types - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/scalar-data-types/)
- [String operators - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/datatypes-string-operators)
