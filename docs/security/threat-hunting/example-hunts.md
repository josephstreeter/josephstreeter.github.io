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

### Accounts sharing a source IP with known-bad accounts

- **Hypothesis:** an adversary who controls one set of accounts is signing in to *other* accounts from the same infrastructure. Starting from confirmed-bad users, pivot on their source IPs to surface the rest of the compromised estate.
- **ATT&CK:** T1078 - Valid Accounts
- **Data source:** `SigninLogs` (Sentinel)

```kql
let KnownBad = dynamic([
    "user1@domain.com",
    "user2@domain.com",
    "user3@domain.com"]);
// Sign-ins by the known-bad accounts, and the IPs they used
let BadActorSignins =
    SigninLogs
    | where TimeGenerated > ago(3d)
    | where UserPrincipalName in (KnownBad)
    | extend Country = tostring(LocationDetails.countryOrRegion),
             City = tostring(LocationDetails.city)
    | project TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName, Country, City, ResultDescription;
let BadIPs = BadActorSignins | distinct IPAddress;
// Other accounts seen on those same IPs
let PivotSignins =
    SigninLogs
    | where TimeGenerated > ago(3d)
    | where IPAddress in (BadIPs)
    | where UserPrincipalName !in (KnownBad)
    | extend Country = tostring(LocationDetails.countryOrRegion),
             City = tostring(LocationDetails.city)
    | project TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName, Country, City, ResultDescription;
BadActorSignins
| union PivotSignins
| order by IPAddress asc, TimeGenerated asc
```

**Triage:** the pivoted accounts are candidates, not confirmed victims — shared IPs also arise from NAT, VPN egress, and corporate proxies. Weight the result by how *specific* the IP is (a residential or hosting-provider address shared by several unrelated users is far more suspicious than a corporate gateway). Corroborate with a successful sign-in (`ResultType == "0"`) followed by sensitive activity.

### Shared source IP outside the home country

- **Hypothesis:** multiple distinct users signing in from a single foreign IP indicates shared adversary infrastructure, an anonymizing proxy, or coordinated access rather than normal travel.
- **ATT&CK:** T1090 - Proxy / T1078 - Valid Accounts
- **Data source:** `SigninLogs` (Sentinel)

```kql
SigninLogs
| where TimeGenerated > ago(7d)
| extend Country = tostring(LocationDetails.countryOrRegion)
| where Country != "US" and Country != ""      // set to your home country
| where isnotempty(UserPrincipalName) and UserPrincipalName != "Unknown"
| summarize Users = make_set(UserPrincipalName, 100), UserCount = dcount(UserPrincipalName)
    by IPAddress, Country
| where UserCount > 1
| project IPAddress, Country, UserCount, Users
| sort by UserCount desc
```

**Triage:** rank by `UserCount` — one IP serving many unrelated users is the strongest signal. Confirm the country is genuinely off-pattern for your organization, and drop known egress ranges (VPN concentrators, satellite offices) into an allowlist as you tune.

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

### Adversary-in-the-middle session

- **Hypothesis:** an AiTM phishing proxy captured a session token and is replaying it, so the same session is seen accessing different applications from different countries within a short window.
- **ATT&CK:** T1557 - Adversary-in-the-Middle
- **Data source:** `AADSignInEventsBeta` (Defender)

> [!CAUTION]
> This pattern flags sessions where a browser reaches a second application from a different country than the initial Office portal sign-in. It is a strong AiTM indicator but can also fire on VPN transitions — validate before acting.

```kql
let OfficeHomeSessions =
    AADSignInEventsBeta
    | where Timestamp > ago(1d)
    | where ErrorCode == 0
    | where ApplicationId == "4765445b-32c6-49b0-83e6-1d93765276ca"   // OfficeHome
    | where ClientAppUsed == "Browser"
    | where LogonType has "interactiveUser"
    | summarize arg_min(Timestamp, Country) by SessionId;
AADSignInEventsBeta
| where Timestamp > ago(1d)
| where ApplicationId != "4765445b-32c6-49b0-83e6-1d93765276ca"
| where ClientAppUsed == "Browser"
| project OtherTimestamp = Timestamp, Application, ApplicationId,
          AccountObjectId, AccountDisplayName, OtherCountry = Country, SessionId
| join kind=inner OfficeHomeSessions on SessionId
| where OtherTimestamp > Timestamp and OtherCountry != Country
| project AccountDisplayName, AccountObjectId, SessionId,
          Timestamp, Country, OtherTimestamp, OtherCountry, Application
```

**Triage:** a single session touching multiple apps from two countries minutes apart is not normal travel. Pull the full session, reset the user's credentials and revoke sessions, and check for mailbox rule creation or OAuth consent that often follows token theft.

## Email and initial-access hunts

### Phishing or spam delivered to a target list

- **Hypothesis:** a set of high-value users received malicious mail that bypassed filtering and may have led to initial access.
- **ATT&CK:** T1566 - Phishing
- **Data source:** `EmailEvents` (Defender)

```kql
let Targets = dynamic([
    "exec1@domain.com",
    "exec2@domain.com",
    "finance@domain.com"]);
EmailEvents
| where Timestamp > ago(7d)
| where RecipientEmailAddress in (Targets)
| where ThreatTypes has_any ("Phish", "Spam")
| project Timestamp, SenderFromAddress, SenderMailFromAddress,
          RecipientEmailAddress, Subject, ThreatTypes, DeliveryAction
| order by Timestamp desc
```

**Triage:** prioritize messages with `DeliveryAction == "Delivered"` (they reached the inbox). Pivot on the sender and subject to find the full campaign, then join to `UrlClickEvents` / `EmailUrlInfo` to see whether any recipient clicked.

### Outbound email volume spike from a single sender

- **Hypothesis:** a compromised mailbox is being used to send spam or phishing in bulk to internal or external recipients.
- **ATT&CK:** T1566 - Phishing (outbound abuse) / T1078 - Valid Accounts
- **Data source:** `EmailEvents` (Defender)

```kql
EmailEvents
| where Timestamp > ago(7d)
| where EmailDirection == "Outbound"
| where SenderFromAddress !startswith "mailer"   // drop known bulk senders
| summarize MessageCount = count(), Recipients = dcount(RecipientEmailAddress)
    by bin(Timestamp, 1d), SenderFromAddress
| where MessageCount >= 700
| order by MessageCount desc
```

**Triage:** a normal user rarely sends hundreds of messages a day to hundreds of recipients. Confirm against the sender's baseline, check for a matching inbound phish that compromised them, and inspect for newly created inbox forwarding rules.

## Scoping queries for triage

These are not hunts on their own — they are fast lookups for scoping an incident once you have a lead (a suspect address, IP, or user).

**Every account seen on a set of known-bad IPs:**

```kql
let BadIPs = dynamic(["203.0.113.10", "198.51.100.24"]);
SigninLogs
| where TimeGenerated > ago(30d)
| where IPAddress in (BadIPs)
| distinct UserPrincipalName
| order by UserPrincipalName asc
```

**Who a suspect address has emailed (and how much):**

```kql
EmailEvents
| where Timestamp > ago(30d)
| where SenderMailFromAddress == "suspect@external.example"
| summarize Messages = count() by RecipientEmailAddress
| order by Messages desc
```

**Volume a mailbox received, by sender — for a suspected compromised inbox:**

```kql
EmailEvents
| where Timestamp > ago(30d)
| where RecipientEmailAddress == "victim@domain.com"
| summarize Messages = count() by SenderMailFromAddress
| order by Messages desc
```

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
