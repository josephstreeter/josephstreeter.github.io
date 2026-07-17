---
title: Kusto Query Language (KQL)
description: Complete guide to Kusto Query Language (KQL) for data exploration, pattern discovery, and threat hunting in Microsoft services like Azure Monitor, Sentinel, and Defender.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: overview
ms.service: azure-monitor
keywords: KQL, Kusto, query language, Azure Monitor, Sentinel, Defender, threat hunting, log analytics
uid: docs.infrastructure.kql.index
---

Kusto Query Language (KQL) is used to explore data and discover patterns, identify anomalies and outliers, create statistical modeling, and more. KQL is a simple yet powerful language to query structured, semi-structured, and unstructured data. The language is expressive, easy to read and understand the query intent, and optimized for authoring experiences.

## Microsoft services using KQL

- Azure Monitor
- Microsoft Sentinel
- Microsoft 365 Defender Advanced Hunting
- Azure Data Explorer
- Application Insights

## Where KQL runs and why schemas differ

The same language runs across several products, but the **table schemas are not the same** between them. The most common difference you will hit is the timestamp column:

| Environment | Query location | Timestamp column | Example tables |
| ----------- | -------------- | ---------------- | -------------- |
| Azure Monitor / Log Analytics / Microsoft Sentinel | Logs blade or Sentinel > Hunting | `TimeGenerated` | `SigninLogs`, `AuditLogs`, `SecurityEvent` |
| Microsoft 365 Defender Advanced Hunting | security.microsoft.com > Advanced hunting | `Timestamp` | `EmailEvents`, `DeviceEvents`, `AADSignInEventsBeta` |

> [!IMPORTANT]
> Queries are **not** portable as-is between these environments. A query written against `SigninLogs` (which uses `TimeGenerated`) will fail in Defender Advanced Hunting, and a query against `EmailEvents` (which uses `Timestamp`) will fail in Log Analytics. When you copy an example, check that its table and timestamp column match the product you are querying.

## In this section

If you are new to KQL, work through these pages in order:

1. [Query structure and statements](query-structure.md) - How statements, `let` bindings, and the pipeline (`|`) fit together.
2. [Functions and operators](functions-and-operators.md) - Common transformations and aggregations such as `where`, `join`, `parse_json`, and `summarize`.
3. [Best practices and performance](best-practices.md) - Write queries that are fast, readable, and maintainable.
4. [Infrastructure examples](examples.md) - Realistic VM, container, and Application Insights monitoring queries.
5. [Quick reference (cheat sheet)](cheat-sheet.md) - Condensed lookup of the most common operators and functions.
6. [Next steps and references](reference.md) - Further learning resources and official documentation.
