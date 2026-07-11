---
title: Best Practices and Performance
description: Practical guidance for writing fast, readable, and maintainable KQL queries, including filter ordering, has vs contains, join tuning, and formatting conventions.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: conceptual
ms.service: azure-monitor
keywords: KQL, Kusto, performance, optimization, best practices, has, join, materialize, readability
uid: docs.infrastructure.kql.best-practices
---

## Writing efficient and readable KQL

KQL queries commonly run over billions of rows, so small changes in how a query is written can make the difference between a result that returns in seconds and one that times out. The guidance below is ordered from the highest-impact performance wins to formatting conventions that keep queries maintainable.

## Performance

### Filter early, and filter on time first

Every query should narrow the data as soon as possible. A time filter is the single most effective filter because the data is indexed by ingestion time, so restricting the time range lets the engine skip entire data shards.

```kql
// Good - time filter first, then narrow further
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType != "0"
| where AppDisplayName == "Microsoft Teams"
```

Put the most selective filters (the ones that eliminate the most rows) as early in the pipeline as you can.

### Prefer `has` over `contains`

`has` matches whole terms using the string index and scans far less data. `contains` performs an unindexed substring scan over every value. Use `contains` only when you genuinely need to match part of a word.

```kql
// Fast - term match against the index
SigninLogs | where ResultDescription has "password"

// Slow - substring scan of every value
SigninLogs | where ResultDescription contains "passw"
```

### Avoid unqualified full-text search

`search "value"` scans every column of every row. Always target a specific column instead.

```kql
// Avoid
search "admin@domain.com"

// Prefer
SigninLogs | where UserPrincipalName == "admin@domain.com"
```

### Reduce columns with `project` before expensive steps

Trimming to the columns you actually need before a `join`, `sort`, or `summarize` reduces the amount of data the engine has to move between nodes.

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| project TimeGenerated, UserPrincipalName, IPAddress
| summarize Signins = count() by UserPrincipalName
```

### Tune joins

- **Filter both sides before joining.** Apply `where` clauses to each table first so fewer rows participate in the join.
- **Put the smaller table on the left.** The left side of a join is loaded into memory, so it should be the smaller, more-filtered dataset.
- **Always specify the join kind.** The default is `innerunique`, which de-duplicates the left side and can silently change your results. State `kind=inner`, `kind=leftouter`, and so on explicitly.

```kql
let SuspectIPs =
    SigninLogs
    | where TimeGenerated > ago(1d)
    | where ResultType != "0"
    | distinct IPAddress;          // small, filtered - goes on the left
SuspectIPs
| join kind=inner (
    SigninLogs
    | where TimeGenerated > ago(1d)
) on IPAddress
```

### Get the latest record with `arg_max` instead of a join

To find the most recent row per key, `arg_max` (or `arg_min`) is far cheaper than joining a table back to itself.

```kql
SigninLogs
| where TimeGenerated > ago(7d)
| summarize arg_max(TimeGenerated, IPAddress, ResultType) by UserPrincipalName
```

### Reuse subqueries with `materialize()`

When the same tabular subquery is used more than once (for example on both sides of a `union` or `join`), wrap it in `materialize()` so it is computed a single time and cached for the duration of the query.

```kql
let RecentSignins = materialize(
    SigninLogs
    | where TimeGenerated > ago(1d)
);
RecentSignins | where ResultType == "0" | count
```

### Prefer `top` over `sort` + `take`

`top N by column` only tracks the N rows it needs, whereas `sort` orders the entire result set before `take` discards most of it.

```kql
// Prefer
SigninLogs | summarize c = count() by UserPrincipalName | top 10 by c desc
```

### Know that `dcount` is approximate

`dcount()` returns a fast, approximate distinct count that is accurate enough for almost all analytics. Only reach for exact counting (`count_distinct()`, or `summarize by` followed by `count`) when you have a specific need for an exact value, and expect it to cost more.

## Readability and maintainability

Fast queries are only useful if you can still understand them next month.

### Put one operator per line

Start each pipeline stage on its own line with the pipe (`|`) leading. This makes the data-flow easy to scan and simplifies commenting out individual steps while debugging.

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType != "0"
| summarize FailedAttempts = count() by UserPrincipalName
| top 10 by FailedAttempts desc
```

### Use `let` for constants and reused expressions

Pull thresholds, time windows, and reused lists into `let` statements at the top of the query. This names the intent and keeps the query body clean.

```kql
let LookbackWindow = 7d;
let WatchedUsers = dynamic(["admin@domain.com", "svc-account@domain.com"]);
SigninLogs
| where TimeGenerated > ago(LookbackWindow)
| where UserPrincipalName in (WatchedUsers)
```

### Comment the intent, not the syntax

Use `//` comments to explain *why* a step exists or what a magic value represents - not to restate what the operator does.

```kql
SigninLogs
| where ApplicationId == "4765445b-32c6-49b0-83e6-1d93765276ca"   // OfficeHome app
```

### Use meaningful column aliases

Name computed columns for what they represent (`FailedAttempts`, `DistinctCountries`) rather than leaving them as `count_` or `Column1`.

### Develop against a small sample

While iterating on a query, cap the data with `take` or a short time range so each run is quick, then remove the cap once the logic is correct.

```kql
SigninLogs
| where TimeGenerated > ago(1h)
| take 100
```

## Summary checklist

- Filter on time first, then apply the most selective filters early.
- Use `has` (not `contains`) for whole-word matches; avoid unqualified `search`.
- Project down to needed columns before `join`, `sort`, or `summarize`.
- Filter both sides of a join, keep the smaller table on the left, and always set the join kind.
- Use `arg_max`/`arg_min` for latest-record lookups and `materialize()` for reused subqueries.
- Prefer `top` over `sort` + `take`; remember `dcount` is approximate.
- One operator per line, `let` for constants, comments for intent, meaningful aliases.

## Reference links

- [Query best practices - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/best-practices)
- [Optimize queries by using materialized views - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/materialize-function)
- [join operator - Microsoft Documentation](https://learn.microsoft.com/en-us/kusto/query/join-operator)
