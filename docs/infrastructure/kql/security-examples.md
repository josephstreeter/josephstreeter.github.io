---
title: Security Examples
description: Example KQL queries for sign-in analysis, email security investigations, and threat hunting scenarios.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: conceptual
ms.service: azure-monitor
keywords: KQL, threat hunting, Sentinel, Defender, SigninLogs, EmailEvents
---

## Examples

> [!WARNING]
> The examples below contain sample data and should be adapted to your specific environment. Always test queries in a safe environment before using them in production.

> [!NOTE]
> These examples target two different products with different schemas. The **Azure Log Analytics / Sentinel** examples query tables such as `SigninLogs` and use the `TimeGenerated` timestamp column. The **Microsoft 365 Defender Advanced Hunting** examples query tables such as `EmailEvents` and `AADSignInEventsBeta` and use the `Timestamp` column. See [Where KQL runs and why schemas differ](index.md#where-kql-runs-and-why-schemas-differ) before copying a query between environments.

### Azure Log Analytics Workspaces

#### Bad actor hunting

This query takes a list of known bad actors and searches for other sign-ins from the same IP addresses.

```kql
let UPNs = dynamic(['hmitchell2@domain.com',
'rrueth@domain.com',
'ebendel@domain.com',
'nmarzette@domain.com',
'againes4@domain.com',
'apage5@domain.com',
'thazelwood@domain.com',
'whelms@domain.com',
'lmalaluan@domain.com']);
let KBAs = SigninLogs
| where TimeGenerated > ago(3d)
| where UserPrincipalName in (UPNs)
| extend city_ = tostring(LocationDetails.city)
| extend countryOrRegion_ = tostring(LocationDetails.countryOrRegion)
| extend state_ = tostring(LocationDetails.state)
| extend browser_ = tostring(DeviceDetail.browser)
| extend operatingSystem_ = tostring(DeviceDetail.operatingSystem)
| project
    TimeGenerated,
    UserDisplayName,
    UserPrincipalName,
    IPAddress,
    AppDisplayName,
    countryOrRegion_,
    state_,
    city_,
    ResultDescription;
let IPs = KBAs | distinct IPAddress;
let PBAs = SigninLogs
| where TimeGenerated > ago(3d)
| where IPAddress in (IPs)
| where UserPrincipalName !in (UPNs)
| extend city_ = tostring(LocationDetails.city)
| extend countryOrRegion_ = tostring(LocationDetails.countryOrRegion)
| extend state_ = tostring(LocationDetails.state)
| project
    TimeGenerated,
    UserDisplayName,
    UserPrincipalName,
    IPAddress,
    AppDisplayName,
    countryOrRegion_,
    state_,
    city_,
    ResultDescription;
KBAs | union PBAs
```

#### Additional security queries

**All sign-ins from IPs used by known bad actors:**

```kql
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
| distinct UserPrincipalName
| order by UserPrincipalName asc
```

**IP addresses in non-US countries used by more than one user:**

This surfaces shared source IP addresses outside the United States where multiple distinct users signed in from the same address and country — a useful indicator of shared infrastructure, proxies, or coordinated activity. Add a `TimeGenerated` filter to scope it to a specific window.

```kql
SigninLogs
| where tostring(LocationDetails["countryOrRegion"]) != "US"
| where tostring(LocationDetails["countryOrRegion"]) != ""
| where not(isnull(UserPrincipalName)) and UserPrincipalName != "Unknown"
| summarize UniqueUsers = make_set(UserPrincipalName) by IPAddress, OffendingCountry = tostring(LocationDetails["countryOrRegion"])
| where array_length(UniqueUsers) > 1
| project IPAddress, UniqueUsers, OffendingCountry
| sort by OffendingCountry asc
```

### Microsoft 365 Defender Advanced Hunting

> [!NOTE]
> Microsoft 365 Defender Advanced Hunting uses KQL to query security data across endpoints, email, identities, and cloud apps.

#### Email security queries

**All messages sent to a specific email address:**

```kql
EmailEvents
| where SenderMailFromAddress endswith "edu-noreply@github.com"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| distinct RecipientEmailAddress
```

**Users sending more than 700 messages in one day:**

```kql
EmailEvents
| where EmailDirection == "Outbound"
| where SenderFromAddress !startswith "mailer"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| summarize count_ = count() by bin(Timestamp, 1d), SenderFromAddress
| where count_ >= 700
```

**Number of messages sent by a user:**

```kql
EmailEvents
| where RecipientEmailAddress == "salewis1@domain.com"
| summarize count_ = count() by SenderMailFromAddress
| order by count_
```

**All spam and phishing messages sent to a list of users:**

```kql
EmailEvents
| where RecipientEmailAddress in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| where ThreatTypes has_any ("Phish", "Spam")
```

#### Authentication security queries

**AiTM (Adversary-in-the-Middle) attack detection:**

> [!CAUTION]
> This query is designed to detect potential adversary-in-the-middle attacks by identifying sessions where users access different applications from different countries within the same session.

```kql
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
