---
title: Azure Monitor
description: Azure Monitor and Azure Alerts as the cloud-native, fully managed alternative to the self-hosted Prometheus + Grafana stack - metrics, logs, alerting, and visualization.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: overview
ms.service: azure-monitor
keywords: Azure Monitor, Azure Alerts, Log Analytics, Application Insights, Action Groups, monitoring, observability
uid: docs.infrastructure.azure-monitor.index
---

## Azure Monitor

[Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/) is Microsoft's **fully managed, cloud-native** observability platform. It is the alternate monitoring stack in this section — where [Prometheus + Grafana](../index.md) is self-hosted open source you run and scale yourself, Azure Monitor is a managed service that collects, stores, analyzes, and alerts on telemetry with no infrastructure for you to operate.

> [!NOTE]
> This section documents the two stacks side by side. See the [Monitoring overview](../index.md) for the self-hosted Prometheus + Grafana stack, and [choosing a stack](#choosing-a-stack) below for when each one fits. The two are not mutually exclusive — a common hybrid keeps Prometheus for Kubernetes workloads and uses Azure Monitor for Azure platform resources.

### What the Azure-native stack provides

| Component | Role | Prometheus-stack equivalent |
| --------- | ---- | --------------------------- |
| **Azure Monitor Metrics** | Near-real-time, dimensional platform and custom metrics | Prometheus TSDB |
| **Log Analytics** | Log and event store queried with [KQL](../../kql/index.md) | Loki / Prometheus (partial) |
| **Application Insights** | Application performance monitoring (APM) — requests, dependencies, traces, exceptions | Prometheus client libraries + Tempo |
| **Azure Monitor Agent (AMA)** | Collects guest metrics and logs from VMs and servers via Data Collection Rules | Node Exporter + scrape configs |
| **Azure Alerts** | Metric, log, and activity-log alert rules | Prometheus alert rules |
| **Action Groups** | Routes and delivers alert notifications (email, SMS, webhook, ITSM, Functions) | Alertmanager receivers |
| **Workbooks / Dashboards / Managed Grafana** | Visualization and reporting | Grafana |
| **Azure Monitor Managed Service for Prometheus** | Managed, Prometheus-compatible metrics with PromQL | Self-managed Prometheus |

### What Azure Monitor collects

- **Platform metrics** — emitted automatically by Azure resources (VMs, App Service, storage, SQL, AKS) at no ingestion cost.
- **Resource logs** — diagnostic logs from Azure resources, routed to Log Analytics via **diagnostic settings**.
- **Activity log** — control-plane events (who did what to which resource).
- **Guest OS telemetry** — CPU, memory, disk, and log files from inside VMs, collected by the **Azure Monitor Agent** through **Data Collection Rules**.
- **Application telemetry** — requests, dependencies, exceptions, and distributed traces from **Application Insights** SDKs / auto-instrumentation.

## Choosing a stack

Neither stack is strictly better — they optimize for different environments.

| Consideration | Prometheus + Grafana | Azure Monitor |
| ------------- | -------------------- | ------------- |
| **Hosting** | Self-hosted; you run and scale it | Fully managed SaaS |
| **Cost model** | Infrastructure + operational effort (no licensing) | Pay per GB ingested / metrics / alert rules |
| **Best for** | Kubernetes, multi-cloud, on-prem, full control | Azure-native workloads, hybrid with Arc, low ops overhead |
| **Query language** | PromQL | [KQL](../../kql/index.md) (logs) + Metrics Explorer (metrics) |
| **Data model** | Pull-based scraping, dimensional labels | Push/agent collection; metrics + logs stores |
| **Long-term retention** | Add Thanos/Cortex/VictoriaMetrics | Built-in; configurable retention per table/workspace |
| **Vendor lock-in** | Portable, open standards | Azure-coupled (mitigated by Managed Prometheus + Grafana) |

> [!TIP]
> If you already run in Azure, the fastest path to coverage is diagnostic settings + a handful of [Azure Alerts](alerts.md) — no agents, no servers. Reach for Prometheus when you need Kubernetes-native scraping, multi-cloud portability, or want to avoid per-GB ingestion costs at high volume.

## Architecture

```text
 Azure resources ──(platform metrics)──────────────┐
     │                                              ▼
     └──(diagnostic settings)──► Log Analytics ◄── Azure Monitor Agent ◄── VMs / Arc servers
                                   workspace              (Data Collection Rules)
 Application Insights SDK ─────────► (logs + metrics)
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    ▼                     ▼                      ▼
              Azure Alerts          Workbooks /            Azure Managed
              (rules)               Dashboards             Grafana
                    │
                    ▼
              Action Groups ──► email · SMS · webhook · ITSM · Logic App · Function
```

## Quick start

Bring an existing Azure resource under monitoring without deploying anything:

> [!NOTE]
> Examples throughout this section show both the **`az` CLI** (quick, ad-hoc changes) and **Terraform** (durable, version-controlled configuration). Terraform snippets use the [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) and reference a shared `azurerm_log_analytics_workspace.core` and `azurerm_resource_group.monitoring` defined once for the stack.

1. **Route resource logs.** On the resource, open **Diagnostic settings** and send logs and metrics to a **Log Analytics workspace**.

   ```bash
   az monitor diagnostic-settings create \
     --name to-law \
     --resource "$RESOURCE_ID" \
     --workspace "$WORKSPACE_ID" \
     --logs    '[{"categoryGroup":"allLogs","enabled":true}]' \
     --metrics '[{"category":"AllMetrics","enabled":true}]'
   ```

   Or as code with Terraform:

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

2. **Query the telemetry** in Log Analytics with KQL — see the [infrastructure KQL examples](../../kql/examples.md).
3. **Create an alert** on a metric or log signal — see [Azure Alerts](alerts.md).
4. **Visualize** it in a Workbook or Azure Managed Grafana — see [Visualization](visualization.md).

## In this section

- **[Data Collection](data-collection.md)** — metrics vs logs, the Azure Monitor Agent, Data Collection Rules, Log Analytics, and Application Insights.
- **[Azure Alerts](alerts.md)** — metric, log, and activity-log alert rules, dynamic thresholds, action groups, and alert processing rules.
- **[Visualization](visualization.md)** — Metrics Explorer, Workbooks, Azure dashboards, and Azure Managed Grafana.

## Related

- [Monitoring overview](../index.md) — the self-hosted Prometheus + Grafana stack and the section map.
- [Prometheus](../prometheus/index.md) — the open-source metrics engine, including the **managed** Prometheus option in Azure.
- [KQL](../../kql/index.md) — the query language for Log Analytics and Application Insights, with [infrastructure examples](../../kql/examples.md).

## References

- [Azure Monitor overview](https://learn.microsoft.com/azure/azure-monitor/overview)
- [Azure Monitor Metrics](https://learn.microsoft.com/azure/azure-monitor/essentials/data-platform-metrics)
- [Azure Monitor Logs](https://learn.microsoft.com/azure/azure-monitor/logs/data-platform-logs)
- [Azure Monitor Managed Service for Prometheus](https://learn.microsoft.com/azure/azure-monitor/essentials/prometheus-metrics-overview)
