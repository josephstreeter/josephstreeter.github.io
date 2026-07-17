---
title: Infrastructure Examples
description: Example KQL queries for infrastructure monitoring in Azure Monitor and Log Analytics - VM and host metrics, availability, containers/AKS, Application Insights, and ingestion cost.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/17/2026
ms.topic: conceptual
ms.service: azure-monitor
keywords: KQL, Azure Monitor, Log Analytics, Perf, Heartbeat, KubePodInventory, Application Insights, monitoring
---

## Examples

These queries target **Azure Monitor / Log Analytics**, where infrastructure telemetry lands. Unless noted, they query tables that use the `TimeGenerated` timestamp column. Adapt the table names, thresholds, and time ranges to your environment.

> [!NOTE]
> These are infrastructure and observability examples (VM health, containers, application performance, and cost). For sign-in, email, and threat-hunting queries, see [Example Threat Hunts](../../security/threat-hunting/example-hunts.md) in the Security section. Both use the same language — see [Where KQL runs and why schemas differ](index.md#where-kql-runs-and-why-schemas-differ) before copying a query between products.

## Host and VM metrics

The `Perf` table holds performance-counter samples collected by the Log Analytics agent / Azure Monitor Agent (via a data collection rule).

**Average CPU per VM over the last hour:**

```kql
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| summarize AvgCPU = avg(CounterValue) by Computer
| order by AvgCPU desc
```

**VMs sustaining high CPU (95th percentile over the window):**

```kql
Perf
| where TimeGenerated > ago(4h)
| where CounterName == "% Processor Time" and InstanceName == "_Total"
| summarize p95CPU = percentile(CounterValue, 95) by Computer
| where p95CPU > 90
| order by p95CPU desc
```

**Available memory trend (charted):**

```kql
Perf
| where TimeGenerated > ago(6h)
| where CounterName == "Available MBytes"          // Windows; Linux: "Available MBytes Memory"
| summarize AvailableMB = avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart
```

**Logical disks below a free-space threshold:**

```kql
Perf
| where TimeGenerated > ago(15m)
| where CounterName == "% Free Space" and ObjectName == "LogicalDisk"
| where InstanceName !in ("_Total", "HarddiskVolume1")
| summarize FreePct = avg(CounterValue) by Computer, InstanceName
| where FreePct < 15
| order by FreePct asc
```

## Availability and agent health

The `Heartbeat` table records a periodic ping from every monitored machine — the simplest signal that a host (and its agent) is alive.

**Machines that have missed heartbeats (likely down or disconnected):**

```kql
Heartbeat
| summarize LastSeen = max(TimeGenerated) by Computer
| extend MinutesSinceLastSeen = datetime_diff("minute", now(), LastSeen)
| where MinutesSinceLastSeen > 10
| order by MinutesSinceLastSeen desc
```

**Daily availability percentage per machine (expected one heartbeat per minute):**

```kql
Heartbeat
| where TimeGenerated > ago(7d)
| summarize Heartbeats = count() by Computer, bin(TimeGenerated, 1d)
| extend AvailabilityPct = round(100.0 * Heartbeats / 1440, 2)
| order by bin_TimeGenerated asc, AvailabilityPct asc
```

## Windows and Linux logs

**Windows System/Application errors, grouped by source:**

```kql
Event
| where TimeGenerated > ago(24h)
| where EventLevelName == "Error"
| summarize Count = count() by Source, EventID, Computer
| order by Count desc
```

**Linux syslog errors from the auth and daemon facilities:**

```kql
Syslog
| where TimeGenerated > ago(24h)
| where SeverityLevel in ("err", "crit", "alert", "emerg")
| summarize Count = count() by Facility, HostName, SyslogMessage
| order by Count desc
```

## Containers and Kubernetes (AKS)

Container Insights populates `KubePodInventory`, `KubeNodeInventory`, `ContainerLogV2`, and `InsightsMetrics`.

**Pods that are not in a Running/Succeeded state:**

```kql
KubePodInventory
| where TimeGenerated > ago(15m)
| summarize arg_max(TimeGenerated, PodStatus) by Name, Namespace, ClusterName
| where PodStatus !in ("Running", "Succeeded")
| project ClusterName, Namespace, Name, PodStatus
| order by ClusterName asc, Namespace asc
```

**Highest pod restart counts in the last day:**

```kql
KubePodInventory
| where TimeGenerated > ago(1d)
| summarize Restarts = max(PodRestartCount) by Name, Namespace, ClusterName
| where Restarts > 0
| order by Restarts desc
| take 25
```

**Container CPU usage (nanocores) by node:**

```kql
InsightsMetrics
| where TimeGenerated > ago(1h)
| where Namespace == "container.azm.ms/cpu" and Name == "cpuUsageNanoCores"
| summarize AvgCpuNanoCores = avg(Val) by Computer
| order by AvgCpuNanoCores desc
```

**Search container stdout/stderr for errors:**

```kql
ContainerLogV2
| where TimeGenerated > ago(1h)
| where LogMessage has_cs "ERROR" or LogMessage has_cs "Exception"
| project TimeGenerated, PodNamespace, PodName, ContainerName, LogMessage
| order by TimeGenerated desc
| take 100
```

## Application Insights

Application Insights stores request, dependency, and exception telemetry in `AppRequests`, `AppDependencies`, and `AppExceptions`.

**Request failure rate and volume per operation:**

```kql
AppRequests
| where TimeGenerated > ago(1h)
| summarize Total = count(), Failed = countif(Success == false) by OperationName
| extend FailureRatePct = round(100.0 * Failed / Total, 2)
| where Total > 10
| order by FailureRatePct desc
```

**Slowest operations by 95th-percentile latency:**

```kql
AppRequests
| where TimeGenerated > ago(1h)
| summarize p95Ms = percentile(DurationMs, 95), Count = count() by OperationName
| where Count > 10
| order by p95Ms desc
```

**Top exceptions in the last day:**

```kql
AppExceptions
| where TimeGenerated > ago(1d)
| summarize Count = count() by ProblemId, type = tostring(ExceptionType)
| order by Count desc
| take 20
```

**Slow or failing outbound dependencies (databases, HTTP, queues):**

```kql
AppDependencies
| where TimeGenerated > ago(1h)
| summarize p95Ms = percentile(DurationMs, 95), FailRatePct = round(100.0 * countif(Success == false) / count(), 2), Calls = count()
    by Target, DependencyType
| where Calls > 10
| order by p95Ms desc
```

## Azure resource diagnostics

**Recent errors across Azure resources sending diagnostics to this workspace:**

```kql
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where Level == "Error"
| summarize Count = count() by ResourceProvider, Resource, Category
| order by Count desc
```

## Ingestion and cost

Watching your own ingestion keeps Log Analytics costs predictable and catches a misconfigured, chatty source before the bill does.

**Billable ingestion volume by table over the last week:**

```kql
Usage
| where TimeGenerated > ago(7d)
| where IsBillable == true
| summarize GB = round(sum(Quantity) / 1000, 2) by DataType
| order by GB desc
```

**Daily ingestion trend (all billable data):**

```kql
Usage
| where TimeGenerated > ago(30d)
| where IsBillable == true
| summarize GB = round(sum(Quantity) / 1000, 2) by bin(TimeGenerated, 1d)
| render columnchart
```

## Related

- [Query structure and statements](query-structure.md) - the pipeline model these examples use.
- [Functions and operators](functions-and-operators.md) - `summarize`, `percentile`, `bin`, `arg_max`, and the rest.
- [Best practices and performance](best-practices.md) - filter early and scope the time range first.
- [Example Threat Hunts](../../security/threat-hunting/example-hunts.md) - the security counterpart to this page.
