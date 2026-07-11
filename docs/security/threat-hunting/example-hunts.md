---
title: "Example Threat Hunts"
description: "Practical, query-driven threat hunts mapped to MITRE ATT&CK, using KQL against Microsoft Sentinel and Defender data"
tags: ["threat-hunting", "kql", "mitre-attack", "sentinel", "defender", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Example hunts

Each hunt below follows the same shape: a **hypothesis**, the **ATT&CK technique** it targets, the **data source**, a **query**, and **triage notes**. The queries are written in [Kusto Query Language (KQL)](../../infrastructure/kql/index.md) and are starting points - tune the thresholds, allowlists, and time ranges to your environment.

> [!WARNING]
> These queries surface *candidates*, not confirmed malicious activity. Every result requires analyst review and, ideally, corroboration from a second data source before escalation.

Note also which product each query targets, because the table schemas differ:

> [!NOTE]
> Queries against `SigninLogs`, `AuditLogs`, and `SecurityEvent` target **Microsoft Sentinel / Log Analytics** and use the `TimeGenerated` column. Queries against `Device*` tables target **Microsoft 365 Defender Advanced Hunting** and use the `Timestamp` column. See [Where KQL runs and why schemas differ](../../infrastructure/kql/index.md#where-kql-runs-and-why-schemas-differ).

## Identity hunts

### Password spray

- **Hypothesis:** an adversary is trying a small set of common passwords against many accounts from a single source.
- **ATT&CK:** T1110.003 - Brute Force: Password Spraying
- **Data source:** `SigninLogs` (Sentinel)

```kql
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType == "50126"          // invalid username or password
| summarize
    TargetedUsers = dcount(UserPrincipalName),
    Attempts = count(),
    Users = make_set(UserPrincipalName, 100)
    by IPAddress, tostring(LocationDetails.countryOrRegion)
| where TargetedUsers > 20
| order by TargetedUsers desc
```

**Triage:** a single IP failing against many distinct users is the spray signature. Check whether any of those users *succeeded* shortly after (a follow-up query on `ResultType == "0"` from the same IP). Legitimate sources of noise include misconfigured mail clients and VPN egress IPs - build an allowlist over time.

### Sign-in from a country the user has never used

- **Hypothesis:** a compromised account is being used from a location outside the user's normal pattern.
- **ATT&CK:** T1078 - Valid Accounts
- **Data source:** `SigninLogs` (Sentinel)

```kql
let Baseline =
    SigninLogs
    | where TimeGenerated between (ago(30d) .. ago(1d))
    | where ResultType == "0"
    | summarize KnownCountries = make_set(tostring(LocationDetails.countryOrRegion)) by UserPrincipalName;
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType == "0"
| extend Country = tostring(LocationDetails.countryOrRegion)
| join kind=inner Baseline on UserPrincipalName
| where Country !in (KnownCountries)
| project TimeGenerated, UserPrincipalName, Country, IPAddress, AppDisplayName
```

**Triage:** correlate with travel, VPN use, and the sensitivity of the accessed application. A new country plus a legacy-authentication protocol or an MFA failure is a stronger signal.

## Endpoint hunts

### Encoded PowerShell execution

- **Hypothesis:** an adversary is running obfuscated PowerShell to evade command-line inspection.
- **ATT&CK:** T1059.001 - Command and Scripting Interpreter: PowerShell
- **Data source:** `DeviceProcessEvents` (Defender)

```kql
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FileName in~ ("powershell.exe", "pwsh.exe")
| where ProcessCommandLine has_any ("-enc", "-EncodedCommand", "-ec", "FromBase64String")
| project Timestamp, DeviceName, AccountName, ProcessCommandLine, InitiatingProcessFileName
| order by Timestamp desc
```

**Triage:** decode the Base64 payload and inspect what it does. Some management and packaging tools legitimately use encoded commands - stack the `InitiatingProcessFileName` and allowlist known-good parents.

### Rundll32 running without a DLL

- **Hypothesis:** an adversary is abusing `rundll32.exe` as a living-off-the-land binary to proxy execution.
- **ATT&CK:** T1218.011 - System Binary Proxy Execution: Rundll32
- **Data source:** `DeviceProcessEvents` (Defender)

```kql
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FileName =~ "rundll32.exe"
| where ProcessCommandLine !has ".dll"
| project Timestamp, DeviceName, AccountName, ProcessCommandLine, InitiatingProcessFileName
| order by Timestamp desc
```

**Triage:** a `rundll32` invocation with no DLL argument, or one pointing at a file in a user-writable path, is unusual. Examine the parent process and the account context.

### Suspicious scheduled-task creation

- **Hypothesis:** an adversary is establishing persistence via a scheduled task.
- **ATT&CK:** T1053.005 - Scheduled Task/Job: Scheduled Task
- **Data source:** `DeviceProcessEvents` (Defender)

```kql
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FileName =~ "schtasks.exe"
| where ProcessCommandLine has "/create"
| project Timestamp, DeviceName, AccountName, ProcessCommandLine, InitiatingProcessFileName
| order by Timestamp desc
```

**Triage:** stack the resulting task names and the parent processes. Software installers create tasks routinely; a task created by a script interpreter or from a temp directory is more interesting.

## Defense-evasion hunts

### Security event log cleared

- **Hypothesis:** an adversary cleared the Windows Security log to destroy evidence.
- **ATT&CK:** T1070.001 - Indicator Removal: Clear Windows Event Logs
- **Data source:** `SecurityEvent` (Sentinel)

```kql
SecurityEvent
| where TimeGenerated > ago(7d)
| where EventID == 1102               // the audit log was cleared
| project TimeGenerated, Computer, Account, Activity
| order by TimeGenerated desc
```

**Triage:** log clearing is rarely legitimate outside of scripted maintenance. Correlate the timestamp with other activity on the host immediately before the clear, which the adversary was likely trying to hide.

## Cloud and application hunts

### Illicit OAuth application consent

- **Hypothesis:** a user was tricked into consenting to a malicious application that now has standing access to data.
- **ATT&CK:** T1528 - Steal Application Access Token
- **Data source:** `AuditLogs` (Sentinel)

```kql
AuditLogs
| where TimeGenerated > ago(7d)
| where OperationName has "Consent to application"
| extend App = tostring(TargetResources[0].displayName)
| extend Actor = tostring(InitiatedBy.user.userPrincipalName)
| project TimeGenerated, Actor, App, Result
| order by TimeGenerated desc
```

**Triage:** review the permissions granted (especially broad mail, file, or directory scopes) and whether the application publisher is verified. User-consented, unverified apps requesting sensitive scopes are the priority.

## From hunt to detection

When a query reliably separates malicious from benign with an acceptable false-positive rate, promote it:

1. Save it as a reusable function or a scheduled analytics rule.
2. Add the allowlists and thresholds you developed during triage.
3. Document the ATT&CK technique it covers so your coverage map (see [Hunting with MITRE ATT&CK](mitre-attack.md#attck-navigator-and-coverage-mapping)) stays current.

> [!TIP]
> For query performance and readability while you iterate on these hunts, see [KQL Best Practices and Performance](../../infrastructure/kql/best-practices.md).

## Next steps

- Review the [analytic techniques](techniques.md) behind these queries.
- Build a coverage map with [MITRE ATT&CK](mitre-attack.md).
- Explore the [tools and references](references.md) for platforms and further reading.
