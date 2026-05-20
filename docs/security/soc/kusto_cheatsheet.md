# Kusto Cheatsheet for SOC Analyst

This page provides practical Kusto Query Language (KQL) patterns that support
SOC triage and investigations in the SOC analyst playbook.

## How to Use This Cheatsheet

- Start with a narrow time window, then expand only when needed
- Filter early to reduce noise and cost
- Keep output columns focused for case notes
- Save high-value queries as reusable templates

## Common Query Skeleton

Use this as a starting template for most investigations.

What it does:

- Defines a base table
- Applies time and investigation filters early
- Returns only key fields for review

When to use it:

- Building a new query from scratch
- Simplifying noisy queries before tuning

```kusto
<TableName>
| where TimeGenerated > ago(24h)
| where <important filters>
| project TimeGenerated, <key fields>
| order by TimeGenerated desc
```

## Time Window Patterns

These filters control scope and performance.

What it does:

- Provides common time constraints for triage and expanded hunts

When to use it:

- 24h for default triage
- Fixed datetime range for incident reconstruction
- 7d for repeated or low-and-slow behavior

```kusto
// Last 24 hours
| where TimeGenerated > ago(24h)

// Incident-centered window
| where TimeGenerated between (datetime(2026-05-19T00:00:00Z) .. datetime(2026-05-19T23:59:59Z))

// Expand to 7 days when needed
| where TimeGenerated > ago(7d)
```

## Identity and Sign-In Queries

### Failed to Success Chains

What it does:

- Finds user and IP pairs with repeated authentication failures followed by
    success in the same window
- Highlights potential password spray, brute force, or credential stuffing

When to use it:

- Early identity triage
- Validating suspicious sign-in alerts

```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| summarize Failed = countif(ResultType != 0), Success = countif(ResultType == 0)
    by UserPrincipalName, IPAddress
| where Failed >= 5 and Success > 0
| order by Failed desc
```

### Suspicious IP Clustering Across Users

What it does:

- Identifies IP and ASN sources authenticating multiple distinct users
- Surfaces shared infrastructure that may indicate coordinated abuse

When to use it:

- Investigating broad sign-in anomalies
- Checking for spray infrastructure affecting multiple accounts

```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| summarize DistinctUsers = dcount(UserPrincipalName), Users = make_set(UserPrincipalName, 20)
    by IPAddress, AutonomousSystemNumber
| where DistinctUsers >= 3
| order by DistinctUsers desc
```

### Conditional Access Fail Then Success

What it does:

- Finds user and IP combinations where Conditional Access failed but access
    still succeeded
- Helps reveal policy bypass paths or alternate sign-in routes

When to use it:

- Investigating potential control evasion
- Reviewing Conditional Access effectiveness

```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| summarize FailedCA = countif(ConditionalAccessStatus =~ "failure"),
    SuccessfulSignins = countif(ResultType == 0)
    by UserPrincipalName, IPAddress
| where FailedCA > 0 and SuccessfulSignins > 0
| order by FailedCA desc
```

## Email and Messaging Queries

### Inbox and Forwarding Rule Changes

What it does:

- Detects mailbox and transport rule creation or modification events
- Surfaces common persistence and exfiltration mechanisms in account takeover

When to use it:

- Any compromised mailbox investigation
- Internal phishing or business email compromise triage

```kusto
CloudAppEvents
| where TimeGenerated > ago(24h)
| where ActionType in ("New-InboxRule", "Set-InboxRule", "New-TransportRule")
| project TimeGenerated, AccountDisplayName, AccountObjectId, ActionType, RawEventData
| order by TimeGenerated desc
```

### Outbound Sender Volume Spike

What it does:

- Compares last 24-hour sender volume against prior 7-day baseline
- Flags statistically elevated outbound send patterns

When to use it:

- Detecting spam bursts from compromised accounts
- Prioritizing suspicious senders for deeper review

```kusto
EmailEvents
| where TimeGenerated > ago(8d)
| summarize DailyCount = count() by SenderFromAddress, bin(TimeGenerated, 1d)
| summarize Last24h = maxif(DailyCount, TimeGenerated > ago(24h)),
    PriorAvg = avgif(DailyCount, TimeGenerated between (ago(8d) .. ago(24h)))
    by SenderFromAddress
| where Last24h > PriorAvg * 3 and Last24h > 20
| order by Last24h desc
```

### Internal Phish Candidate Messages

What it does:

- Filters internal-domain senders with suspicious phishing-like subject terms
- Returns message IDs for pivoting into detailed email analysis

When to use it:

- Rapid hunting for internal phishing waves
- Building an initial message triage queue

```kusto
EmailEvents
| where TimeGenerated > ago(24h)
| where SenderFromDomain has "yourdomain.edu"
| where Subject has_any ("urgent", "verify", "password", "invoice")
| project TimeGenerated, SenderFromAddress, RecipientEmailAddress, Subject, NetworkMessageId
| order by TimeGenerated desc
```

## Privilege and Audit Queries

### Role Assignment Changes

What it does:

- Finds privileged role membership or activation changes in directory audit logs
- Highlights potential privilege escalation activity

When to use it:

- Privileged account investigations
- Verifying whether elevated access changed near incident time

```kusto
AuditLogs
| where TimeGenerated > ago(24h)
| where ActivityDisplayName has_any (
    "Add member to role",
    "Add eligible member to role",
    "Activate eligible role"
  )
| project TimeGenerated, ActivityDisplayName, InitiatedBy, TargetResources
| order by TimeGenerated desc
```

### Sensitive Directory Changes

What it does:

- Detects high-impact identity and policy modifications
- Helps identify account takeover or persistence-related admin actions

When to use it:

- Identity incident scope assessment
- Post-compromise change review

```kusto
AuditLogs
| where TimeGenerated > ago(24h)
| where ActivityDisplayName has_any (
    "Update user",
    "Reset user password",
    "Update application",
    "Update policy"
  )
| project TimeGenerated, ActivityDisplayName, InitiatedBy, TargetResources
| order by TimeGenerated desc
```

## Investigation Helpers

### Build a User Timeline

What it does:

- Combines sign-in and audit events into a chronological user-centric timeline
- Enables fast reconstruction of a single identity investigation narrative

When to use it:

- Case timeline generation
- Confirming event sequence before containment or closure

```kusto
union isfuzzy=true SigninLogs, AuditLogs
| where TimeGenerated > ago(24h)
| where tostring(UserPrincipalName) =~ "user@yourdomain.edu"
    or tostring(InitiatedBy) has "user@yourdomain.edu"
| project TimeGenerated,
    SourceTable = $table,
    UserPrincipalName,
    InitiatedBy,
    IPAddress,
    ResultType,
    ActivityDisplayName
| order by TimeGenerated asc
```

### Correlate by IP and Device

What it does:

- Groups sign-ins by IP and maps associated users and devices
- Surfaces shared-source activity that may indicate lateral or coordinated use

When to use it:

- Multi-user anomaly review
- Prioritizing IP clusters for containment decisions

```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| summarize Users = make_set(UserPrincipalName, 20),
    Devices = make_set(DeviceDetail.deviceId, 20),
    Count = count()
    by IPAddress
| where array_length(Users) > 1 and Count >= 5
| order by Count desc
```

## Case Note Minimum Fields

For each query result saved to a case, capture:

- Timestamp in UTC
- User principal name and object ID
- Source IP and location
- Device ID and compliance state
- Alert ID or message ID
- Action taken and approver

## Tuning Tips

- Raise thresholds for known high-volume service accounts
- Exclude approved scanner or integration accounts using allow-lists
- Separate student and staff baselines when behavior differs materially
- Validate query assumptions after major identity or mail policy changes

## Related SOC Pages

- [SOC Analyst Playbook](soc_analyst.md)
- [SOC Home](index.md)
- [Microsoft Defender Outline](ms_defender.md)
