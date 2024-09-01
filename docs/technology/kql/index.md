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

## Azure Log Analyitics Workspaces

### Threat Hunting

All Sign-ins from IPs used by known bad actors

```text
let IPAddresses = SigninLogs
| where TimeGenerated > ago(30d)
| where UserPrincipalName in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| distinct IPAddress;
SigninLogs
| where TimeGenerated > ago(30d)
| where IPAddress in (IPAddresses)
| project TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName, LocationDetails, ResultDescription
| order by UserPrincipalName
| distinct UserPrincipalName
```

## Defender Advanced Threat Hunting

### Email Activity

All messages sent to ```edu-noreply@github.com```

```text
EmailEvents
| where SenderMailFromAddress endswith "edu-noreply@github.com"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| distinct RecipientEmailAddress
```

Users sending more than 700 messages in one day

```text
EmailEvents
| where EmailDirection == "Outbound"
| where SenderFromAddress !startswith "mailer"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| summarize count_ = count() by bin(Timestamp, 1d), SenderFromAddress
| where count_ >= 700
```

Number of messages sent by a user

```text
EmailEvents
| where RecipientEmailAddress == "salewis1@madisoncollege.edu"
| summarize count_ = count() by SenderMailFromAddress
| order by count_
```

Messages sent by a list of users

```text
EmailEvents
| where RecipientEmailAddress in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| project Timestamp, SenderMailFromAddress, RecipientEmailAddress, Subject, LatestDeliveryLocation, LatestDeliveryAction
```

All Spam and Phishing Messages sent to a list of users

```text
EmailEvents
| where RecipientEmailAddress in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| where ThreatTypes == @"Phish, Spam"
```

### Authentication

AiTM Attack Authentication

```text
let OfficeHomeSessionIds = 
AADSignInEventsBeta
| where Timestamp > ago(1d)
| where ErrorCode == 0
| where ApplicationId == "4765445b-32c6-49b0-83e6-1d93765276ca" //OfficeHome application 
| where ClientAppUsed == "Browser" 
| where LogonType has "interactiveUser" 
| summarize arg_min(Timestamp, Country) by SessionId;
AADSignInEventsBeta
| where Timestamp > ago(1d)
| where ApplicationId != "4765445b-32c6-49b0-83e6-1d93765276ca"
| where ClientAppUsed == "Browser" 
| project OtherTimestamp = Timestamp, Application, ApplicationId, AccountObjectId, AccountDisplayName, OtherCountry = Country, SessionId
| join OfficeHomeSessionIds on SessionId
| where OtherTimestamp > Timestamp and OtherCountry != Country
```
