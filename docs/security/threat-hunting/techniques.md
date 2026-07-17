---
title: "Threat Hunting Analytic Techniques"
description: "Core analytic techniques for threat hunting including searching, clustering, grouping, stack counting, and baselining"
tags: ["threat-hunting", "analytics", "stack-counting", "baselining", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Analytic techniques

Once you have a hypothesis and the data to test it, you need methods to sift signal from noise. These techniques - drawn from the widely used hunting literature - are the analytical workhorses of the investigate phase. They are complementary: a single hunt often combines several.

## Searching

The most basic technique: querying data for specific artifacts or conditions. Searching works best when you have concrete criteria - a known-bad domain, a specific command-line pattern, a particular account.

- **Strength:** simple, fast, and precise when you know what you are looking for.
- **Weakness:** returns nothing if the adversary deviates even slightly, and produces overwhelming noise if the criteria are too broad.

Effective searching is about crafting selective filters. In [KQL](../../infrastructure/kql/functions-and-operators.md), prefer indexed term matches (`has`) over substring scans (`contains`), and always constrain the time range first.

## Stack counting (stacking)

**Stack counting** aggregates a field into its distinct values and counts the occurrences of each, then examines the extremes. It rests on the principle of **least frequency of occurrence**: on a well-managed fleet, malicious artifacts are usually rare, while legitimate ones are common.

Classic uses:

- Stack the names of processes running from user-writable directories - the rare ones are worth a look.
- Stack parent/child process relationships - unusual pairings (for example a browser spawning a shell) stand out.
- Stack autorun locations, scheduled-task names, or service binaries across the fleet.

```kql
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FolderPath has @"\AppData\Local\Temp\"
| summarize Hosts = dcount(DeviceName), Executions = count() by FileName
| order by Executions asc
```

> [!TIP]
> Stacking works best on populations that *should* be homogeneous - identically imaged workstations, or a farm of web servers. The more uniform the baseline, the more an outlier means something.

## Clustering

**Clustering** groups similar data points together based on shared characteristics, often statistically, to reveal natural groupings and the outliers that fall outside them. Where stacking looks at one dimension, clustering can consider several at once.

- Cluster sign-ins by combinations of location, device, and application to find sessions that do not fit any normal cluster.
- Cluster hosts by their outbound connection behavior to isolate a handful behaving unlike their peers.

Clustering frequently uses statistical or machine-learning tooling (for example, notebooks running Python), making it a natural fit for the **model-assisted** hunt style.

## Grouping

**Grouping** takes a set of already-interesting artifacts and identifies when multiple of them appear together within a defined boundary such as a time window or a single host. Whereas clustering discovers structure in unlabeled data, grouping starts from items you already consider suspicious and looks for co-occurrence.

- Take a list of discovery commands (`whoami`, `net group`, `nltest`) and group by host and a short time window to catch reconnaissance bursts.
- Group failed logons, a successful logon, and a new persistence artifact occurring together on one host.

## Baselining

**Baselining** establishes what "normal" looks like so that deviations become detectable. It underpins the PEAK **baseline** hunt style described in the [methodology](methodology.md).

- Baseline the set of countries your users normally sign in from, then hunt for first-time appearances.
- Baseline the daily volume of data each host sends externally, then investigate hosts that spike.
- Baseline which service accounts log on interactively (ideally none), then alert on any that do.

```kql
// Establish a per-user country baseline, then find first-seen countries in the last day
let Baseline =
    SigninLogs
    | where TimeGenerated between (ago(30d) .. ago(1d))
    | summarize KnownCountries = make_set(tostring(LocationDetails.countryOrRegion)) by UserPrincipalName;
SigninLogs
| where TimeGenerated > ago(1d)
| extend Country = tostring(LocationDetails.countryOrRegion)
| join kind=inner Baseline on UserPrincipalName
| where Country !in (KnownCountries)
| project TimeGenerated, UserPrincipalName, Country, IPAddress
```

## Anomaly and outlier detection

Building on baselining, anomaly detection uses statistical measures - standard deviation, time-series decomposition, or purpose-built functions - to flag values that deviate from the norm. Many platforms provide built-in helpers (for example KQL's `series_decompose_anomalies`). Anomaly detection is powerful but noisy: every candidate still requires human judgment to separate a genuinely malicious deviation from a benign one.

## Choosing a technique

| If you want to... | Use |
| ----------------- | --- |
| Find a specific known artifact | Searching |
| Surface rare items in a uniform population | Stack counting |
| Discover natural groupings and multi-dimensional outliers | Clustering |
| Find suspicious items that co-occur | Grouping |
| Detect deviations from normal | Baselining / anomaly detection |

> [!IMPORTANT]
> None of these techniques *confirm* malice on their own - they surface candidates. Every result needs analyst review and, ideally, corroboration from a second data source before it is escalated.

## Next steps

- Put these techniques to work in the [example hunts](example-hunts.md).
- Turn reliable findings into automated detections (see the [methodology](methodology.md#documenting-a-hunt)).
- Review the [tools and references](references.md) that support statistical and notebook-based hunting.
