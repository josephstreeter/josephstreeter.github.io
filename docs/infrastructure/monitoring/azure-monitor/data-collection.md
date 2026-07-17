---
title: Azure Monitor Data Collection
description: How Azure Monitor collects telemetry - platform metrics, resource logs, the Azure Monitor Agent, Data Collection Rules, Log Analytics workspaces, and Application Insights.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: concept
ms.service: azure-monitor
keywords: Azure Monitor Agent, Data Collection Rules, Log Analytics, Application Insights, diagnostic settings, metrics, logs
uid: docs.infrastructure.azure-monitor.data-collection
---

## Data collection

Azure Monitor stores telemetry in two fundamentally different data stores. Understanding the split is the key to using the platform well.

| Store | Holds | Shape | Queried with | Rough cost driver |
| ----- | ----- | ----- | ------------ | ----------------- |
| **Metrics** | Numeric time series | Lightweight, dimensional, near-real-time | Metrics Explorer, Managed Prometheus (PromQL) | Custom metrics / API calls |
| **Logs** | Events, traces, and metric snapshots | Rich, schema-per-table records | [KQL](../../kql/index.md) | GB ingested + retention |

> [!NOTE]
> Platform **metrics** and the **activity log** are collected automatically for every Azure resource at no ingestion cost. Everything else — resource logs, guest OS telemetry, and application telemetry — requires explicit configuration (diagnostic settings, an agent, or an SDK) and is billed by ingestion.

## Platform metrics

Every Azure resource emits platform metrics automatically — CPU percentage for a VM, request count for App Service, DTU for SQL. They are retained for 93 days at no charge and are the first thing to alert on because they need zero setup. Query and chart them in **Metrics Explorer** (see [Visualization](visualization.md)).

## Resource logs and diagnostic settings

Resource logs (a.k.a. diagnostic logs) describe the internal operation of a resource — App Service HTTP logs, Key Vault access, NSG flow events. They are **off by default**; a **diagnostic setting** routes them to one or more destinations:

- **Log Analytics workspace** — to query with KQL and alert on.
- **Storage account** — cheap long-term archive.
- **Event Hub** — to stream to a SIEM or third-party tool.

```bash
az monitor diagnostic-settings create \
  --name to-law \
  --resource "$RESOURCE_ID" \
  --workspace "$WORKSPACE_ID" \
  --logs    '[{"categoryGroup":"allLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

The Terraform equivalent, targeting the same workspace:

```hcl
resource "azurerm_monitor_diagnostic_setting" "to_law" {
  name                       = "to-law"
  target_resource_id         = var.resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
```

> [!TIP]
> Use **diagnostic setting policies** (Azure Policy `DeployIfNotExists`) to enforce that every new resource of a given type routes its logs to your central workspace automatically. Manually configuring each resource does not scale. Terraform is the right tool for the handful of central resources (the workspace, DCRs, shared alerts); policy is the right tool for enforcing coverage across everything else.

## The activity log

The activity log is a subscription-level record of control-plane operations — resource creation, deletion, role assignments, and service health events. It is retained for 90 days for free; route it to a Log Analytics workspace (via a diagnostic setting on the subscription) to keep it longer, correlate it with other logs, and build [activity-log alerts](alerts.md#activity-log-alerts).

## Guest telemetry: the Azure Monitor Agent

Platform metrics stop at the VM boundary — they cannot see inside the guest OS. To collect CPU/memory/disk counters, syslog, Windows event logs, and custom text logs from **VMs, scale sets, and Azure Arc-enabled servers**, deploy the **Azure Monitor Agent (AMA)**.

> [!IMPORTANT]
> AMA replaces the legacy Log Analytics agent (MMA/OMS), which was **retired in August 2024**. New deployments must use AMA. If you still run the legacy agent, migrate with the [AMA migration guidance](https://learn.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration).

### Data Collection Rules

AMA is configured entirely through **Data Collection Rules (DCRs)** — reusable objects that declare *what* to collect (a **data source**) and *where* to send it (a **destination**). One DCR can be associated with many machines, and one machine can have many DCRs.

```text
 Data source                     Destination
 ───────────                     ───────────
 Performance counters ─┐
 Windows event logs   ─┼──►  DCR  ──►  Log Analytics workspace
 Syslog               ─┤            └►  Azure Monitor Metrics
 Custom text/JSON logs ┘
```

Key points when designing DCRs:

- **Scope by association**, not by editing each agent — associate a DCR with a VM, a resource group, or at scale via policy.
- **Transform at ingestion** with a KQL `transformKql` expression to drop noisy columns or filter rows *before* they are billed.
- **Separate concerns** — a DCR for security event logs, another for performance counters — so you can attach the right data to the right machines.

A DCR that collects a standard performance set and associates it with a VM:

```hcl
resource "azurerm_monitor_data_collection_rule" "vm_perf" {
  name                = "dcr-vm-perf"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.core.id
      name                  = "law-core"
    }
  }

  data_sources {
    performance_counter {
      name                          = "perfCounters"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\LogicalDisk(_Total)\\% Free Space",
      ]
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-core"]
  }
}

# Attach the rule to a VM (repeat, or use for_each, to scale out)
resource "azurerm_monitor_data_collection_rule_association" "vm_perf" {
  name                    = "dcra-vm-perf"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_perf.id
}
```

## VM insights and Container insights

Two curated experiences build on this plumbing:

- **VM insights** — deploys a DCR that collects a standard performance set plus (optionally) the Dependency Agent for a process/connection map. Populates `InsightsMetrics`.
- **Container insights** — for AKS and Arc-enabled Kubernetes, collects node/pod/container metrics and stdout/stderr into `KubePodInventory`, `ContainerLogV2`, and `InsightsMetrics`. See the [KQL container examples](../../kql/examples.md#containers-and-kubernetes-aks).

## Application Insights

**Application Insights** is the APM feature of Azure Monitor. Instrument an app (SDK or agentless auto-instrumentation for App Service, Functions, and AKS) and it captures:

- **Requests** (`AppRequests`) — server-side request rate, duration, and success.
- **Dependencies** (`AppDependencies`) — outbound calls to databases, HTTP services, and queues.
- **Exceptions** (`AppExceptions`) — server and browser errors with stack traces.
- **Traces and custom events** — distributed traces (W3C Trace Context) and telemetry you emit.

Modern (workspace-based) Application Insights stores everything in a Log Analytics workspace, so the same [KQL](../../kql/index.md) and [alerting](alerts.md) apply. See the [Application Insights KQL examples](../../kql/examples.md#application-insights).

```hcl
resource "azurerm_application_insights" "app" {
  name                = "appi-web"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  workspace_id        = azurerm_log_analytics_workspace.core.id   # workspace-based
  application_type    = "web"
}
```

> [!TIP]
> Adaptive sampling reduces the volume (and cost) of high-throughput application telemetry while preserving statistical accuracy. Tune it rather than disabling it, and remember that sampled counts are already scaled back up in `summarize` via `itemCount`.

## Log Analytics workspace design

The workspace is where logs land and are retained. A few decisions shape cost and governance:

- **How many workspaces** — prefer few, central workspaces for correlation; split only for hard data-sovereignty, RBAC, or retention-policy boundaries.
- **Retention and archive** — set interactive retention per table, then a cheaper long-term **archive** tier for compliance data.
- **Table plans** — put high-volume, rarely-queried logs on the **Basic/Auxiliary** plan to cut ingestion cost (with query limitations).
- **Watch ingestion** — the `Usage` table shows GB per table; see the [ingestion/cost KQL examples](../../kql/examples.md#ingestion-and-cost).

The central workspace that the rest of this section's examples reference:

```hcl
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring"
  location = "eastus"
}

resource "azurerm_log_analytics_workspace" "core" {
  name                = "law-core"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

## Related

- [Azure Monitor overview](index.md) — the stack and how the pieces fit.
- [Azure Alerts](alerts.md) — alerting on the metrics and logs collected here.
- [Visualization](visualization.md) — charting metrics and building Workbooks.
- [KQL](../../kql/index.md) — querying Log Analytics and Application Insights.

## References

- [Azure Monitor Agent overview](https://learn.microsoft.com/azure/azure-monitor/agents/agents-overview)
- [Data Collection Rules](https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-rule-overview)
- [Diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)
- [Application Insights overview](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Log Analytics workspace design](https://learn.microsoft.com/azure/azure-monitor/logs/workspace-design)
