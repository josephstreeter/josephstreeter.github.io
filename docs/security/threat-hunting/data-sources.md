---
title: "Threat Hunting Data Sources and Telemetry"
description: "The endpoint, identity, network, cloud, and email telemetry that threat hunts depend on, and how to assess visibility and coverage"
tags: ["threat-hunting", "telemetry", "logging", "edr", "siem", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Data sources and telemetry

A hunt can only find what the data can see. Before forming hypotheses, understand which telemetry you collect, how long it is retained, and where the blind spots are. **Visibility is the foundation of hunting** - the best analyst cannot find activity that was never logged.

## Core data sources

| Category | Examples of telemetry | What it reveals |
| -------- | --------------------- | --------------- |
| Endpoint / EDR | Process creation, command lines, file writes, registry, module loads, network connections | Execution, persistence, privilege escalation, lateral movement on hosts |
| Identity / authentication | Sign-in logs, audit logs, MFA events, directory changes | Credential abuse, brute force, impossible travel, privilege changes |
| Network | Firewall, DNS, proxy, NetFlow, TLS/SNI metadata | Command-and-control, exfiltration, beaconing, unusual destinations |
| Cloud / SaaS | Control-plane audit logs, cloud app activity, storage access | Cloud persistence, data staging, OAuth abuse, misconfiguration abuse |
| Email | Message events, URL clicks, attachment detonation | Phishing delivery, initial access, business email compromise |

## Endpoint telemetry

Endpoint data is the richest source for most hunts because so much adversary activity manifests as process execution. High-value fields include:

- **Process creation** with the full **command line**, parent process, and the account it ran as.
- **Image loads** (DLLs) to catch injection and side-loading.
- **File and registry modifications** for persistence and staging.
- **Network connections** initiated by processes, tying host activity to network destinations.

On Windows, Sysmon and the built-in EDR (Microsoft Defender for Endpoint) are common sources. In Defender Advanced Hunting these appear in tables such as `DeviceProcessEvents`, `DeviceNetworkEvents`, and `DeviceFileEvents`.

## Identity and authentication telemetry

Identity is the new perimeter, and many intrusions are visible first as anomalous authentication. Key signals:

- Interactive and non-interactive sign-ins, including source IP, location, device, and application.
- Result codes distinguishing success from the many varieties of failure.
- Directory audit events: role assignments, group changes, and application consent grants.

In Microsoft Sentinel / Log Analytics these live in `SigninLogs`, `AADNonInteractiveUserSignInLogs`, and `AuditLogs`.

> [!NOTE]
> Sentinel and Defender use different schemas. `SigninLogs` (Sentinel) uses a `TimeGenerated` column, while Defender's `AADSignInEventsBeta` uses `Timestamp`. See [Where KQL runs and why schemas differ](../../infrastructure/kql/index.md#where-kql-runs-and-why-schemas-differ).

## Network telemetry

Network data provides an account-independent view of activity and is essential for spotting command-and-control and exfiltration:

- **DNS** logs reveal domain-generation-algorithm patterns, newly registered domains, and DNS tunneling.
- **Proxy / web** logs expose unusual user agents, destinations, and data volumes.
- **Flow data** (NetFlow, firewall logs) supports beaconing and volume analysis even when payloads are encrypted.

## Cloud and SaaS telemetry

As workloads move to the cloud, control-plane and application logs become critical:

- Cloud provider audit logs (for example Azure Activity, AWS CloudTrail) record who did what to which resource.
- SaaS and cloud-app activity logs surface data access, sharing, and OAuth application consent.

## Assessing coverage

You cannot hunt what you cannot see. Periodically map your telemetry against the techniques you care about:

- **Map to ATT&CK.** For each technique in scope, ask "which data source would reveal this, and do we collect it?" (see [Hunting with MITRE ATT&CK](mitre-attack.md)).
- **Check retention.** A 7-day retention window makes it impossible to hunt a slow campaign. Match retention to your expected dwell time.
- **Verify data quality.** Confirm the important fields (command lines, parent processes, source IPs) are actually populated, not truncated or empty.
- **Track gaps.** Maintain a living list of blind spots; each one is a candidate for a logging or tooling improvement.

> [!TIP]
> A hunt that returns no findings *because the data was not collected* is a false sense of security. Always confirm the relevant telemetry exists and is complete before concluding a hypothesis is disproven.

## Next steps

- Use [MITRE ATT&CK](mitre-attack.md) to map techniques to the data sources that reveal them.
- Apply [analytic techniques](techniques.md) to the telemetry you collect.
- See [example hunts](example-hunts.md) that draw on these data sources.
