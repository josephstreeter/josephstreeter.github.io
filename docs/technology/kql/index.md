# Kusto Query Language

Kusto Query Language (KQL) is used to explore data and discover patterns, identify anomalies and outliers, create statistical modeling, and more. KQL is a simple yet powerful language to query structured, semi-structured, and unstructured data. The language is expressive, easy to read and understand the query intent, and optimized for authoring experiences. Kusto Query Language is optimal for querying telemetry, metrics, and logs with deep support for text search and parsing, time-series operators and functions, analytics and aggregation, geospatial, vector similarity searches, and many other language constructs that provide the most optimal language for data analysis. The query uses schema entities that are organized in a hierarchy similar to SQLs: databases, tables, and columns.

KQL is used in a number of Microsoft services:

- Azure Monitor
- Microsoft Sentinel
- Microsoft 365 Defender Threat Hunter

## Kusto Queries

A Kusto query is a read-only request to process data and return results. The request is stated in plain text, using a data-flow model that is easy to read, author, and automate. Kusto queries are made of one or more query statements.

## Query Statements

The three types of user query statements are:

- **Tabular** - Both the input and output are made of tables or tabular data. The tabular statements consist of tabular input and tabular output and may have operators. As the data is piped (|) from one operator to another it is filtered, rearranged, or summarized.
- **Let** - A let statement is used to set a variable name equal to an expression or a function, or to create views. let statements are useful for:
  - Breaking up a complex expression into multiple parts, each represented by a variable.
  - Defining constants outside of the query body for readability.
  - Defining a variable once and using it multiple times within a query.
- **Set** - Not actually part of the Kusto Query Language. It is used to set a request property for the duration of the query.

## Parse JSON into Columns

```kql
extend SPF_ = parse_json(AuthenticationDetails).SPF
```

Example:

```kql
EmailEvents
| where RecipientEmailAddress endswith "gmail.com"
| extend SPF_ = parse_json(AuthenticationDetails).SPF
| extend DKIM_ = parse_json(AuthenticationDetails).DKIM
| extend DMARC_ = parse_json(AuthenticationDetails).DMARC
| project Timestamp, RecipientEmailAddress, SenderFromAddress, SenderIPv4, SenderIPv6, SPF_, DMARC_, DKIM_, LatestDeliveryAction
```

## mv-expand

- [mv-expand Operator](https://learn.microsoft.com/en-us/kusto/query/mv-expand-operator?view=microsoft-fabric)
- [MV-Expand - Fun with KQL](https://arcanecode.com/2022/11/21/fun-with-kql-mv-expand/)
- [text](https://ninoburini.wordpress.com/2020/03/22/split-an-array-into-multiple-rows-in-kusto-azure-data-explorer-with-mv-expand/)

## References

[https://rodtrent.substack.com/p/must-learn-kql-part-13-the-extend](https://rodtrent.substack.com/p/must-learn-kql-part-13-the-extend)
