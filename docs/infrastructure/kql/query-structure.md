---
title: Query Structure and Statements
description: Learn the core shape of KQL queries, including tabular statements, let statements, and the pipe operator.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: conceptual
ms.service: azure-monitor
keywords: KQL, Kusto, query structure, let, pipe, tabular statements
---

## Kusto Queries

A Kusto query is a read-only request to process data and return results. The request is stated in plain text, using a data-flow model that is easy to read, author, and automate. Kusto queries are composed of one or more query statements.

## Query Statements

There are three types of user query statements:

- **Tabular** - Both the input and output are composed of tables. The tabular statements consist of tabular input and tabular output and may include operators. As the data is piped (`|`) from one operator to another it is filtered, rearranged, and summarized.
- **Let** - A `let` statement is used to set a variable name equal to an expression or a function, or to create views. `let` statements are useful for:
  - Breaking up a complex expression into multiple parts, each represented by a variable.
  - Defining constants outside the query body for readability.
  - Defining a variable once and reusing it multiple times within a query.
- **Set** - Not actually part of the Kusto Query Language. It is used to set a request property for the duration of the query.

> [!NOTE]
> The pipe operator (`|`) is fundamental to KQL and allows you to chain operations together in a readable, left-to-right flow.

## Basic Query Pattern

A typical KQL query follows this general pattern:

```kql
SourceTable
| where condition
| project columns
| order by column desc
```

## Example: Filtering and projecting data

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| project TimeGenerated, UserPrincipalName, IPAddress, ResultDescription
| order by TimeGenerated desc
```

## Example: Reusing a variable with `let`

```kql
let Threshold = 30d;
SigninLogs
| where TimeGenerated > ago(Threshold)
| project TimeGenerated, UserPrincipalName, IPAddress
```

## Tips for writing readable queries

- Keep each pipeline step focused on one transformation.
- Use `project` to reduce the number of columns before later steps.
- Use `extend` when adding calculated columns.
- Prefer `where` early in the pipeline to reduce the amount of data processed.
