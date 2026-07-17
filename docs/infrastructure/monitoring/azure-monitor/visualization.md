---
title: Azure Monitor Visualization
description: Visualizing Azure Monitor telemetry - Metrics Explorer, Workbooks, Azure dashboards, and Azure Managed Grafana.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: how-to
ms.service: azure-monitor
keywords: Metrics Explorer, Azure Workbooks, Azure dashboards, Azure Managed Grafana, visualization
uid: docs.infrastructure.azure-monitor.visualization
---

## Visualization

Azure Monitor offers several ways to visualize telemetry, from quick ad-hoc charts to shared, parameterized reports. Pick by audience and lifespan.

| Tool | Best for | Data | Sharing |
| ---- | -------- | ---- | ------- |
| **Metrics Explorer** | Quick, ad-hoc metric charts | Metrics | Pin to a dashboard |
| **Workbooks** | Rich, parameterized, interactive reports | Metrics + logs (KQL) | Shared, RBAC, exportable as ARM |
| **Azure dashboards** | At-a-glance operational boards | Pinned tiles | Shared via RBAC |
| **Azure Managed Grafana** | Grafana experience over Azure (and other) sources | Metrics, logs, Managed Prometheus | Grafana sharing model |

## Metrics Explorer

The fastest way to look at a platform or custom metric. Select a resource, a metric (e.g. `Percentage CPU`), an aggregation (`avg`, `max`, `p95`), and optionally **split by a dimension** to break one chart into per-instance series. Pin the result to an Azure dashboard, or use **Save to workbook** for something more permanent. Metrics Explorer is where you validate a signal before building a [metric alert](alerts.md#metric-alerts) on it.

## Workbooks

**Workbooks** are the most capable visualization surface — interactive documents that combine text, parameters, metric charts, and [KQL](../../kql/index.md) log queries into a single report.

- **Parameters** — time range, subscription, resource, or free-text pickers that flow into every query on the page.
- **Mixed data** — a metrics chart and a KQL grid side by side, driven by the same parameters.
- **Templates** — Azure ships curated workbooks (VM performance, failures, cost) you can clone and adapt.
- **As code** — export a workbook's definition to JSON and deploy it with Terraform so dashboards are versioned alongside the resources they monitor.

```hcl
resource "azurerm_application_insights_workbook" "vm_perf" {
  name                = "11111111-1111-1111-1111-111111111111" # any GUID
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  display_name        = "VM Performance"
  # Author the workbook in the portal, then export "Gallery Template" JSON:
  data_json = file("${path.module}/workbooks/vm-perf.json")
}
```

> [!TIP]
> Workbooks are the natural home for a KQL query you have already written for investigation or alerting. Promote a good [infrastructure KQL example](../../kql/examples.md) into a workbook tile so the whole team gets it without touching the query editor.

## Azure dashboards

Azure portal **dashboards** are tile boards you assemble by pinning charts (from Metrics Explorer, Log Analytics, or Application Insights). They are good for a shared operational "single pane" but are less interactive than workbooks — no parameters, limited layout. Share via RBAC on the dashboard resource.

## Azure Managed Grafana

If your team already knows and prefers Grafana, **[Azure Managed Grafana](https://learn.microsoft.com/azure/managed-grafana/overview)** is a fully managed Grafana service with native Azure Monitor and Managed Prometheus data sources and Entra ID authentication. It lets you keep a single Grafana experience across the **self-hosted and Azure-native stacks** — the same dashboards can query Prometheus and Azure Monitor together.

- Native **Azure Monitor** data source (metrics + logs) and **Azure Monitor Managed Service for Prometheus** (PromQL).
- Managed upgrades, high availability, and Entra ID / RBAC integration.
- Import existing Grafana dashboards, including the [community dashboards used with the self-hosted stack](../grafana/dashboards.md).

> [!NOTE]
> This bridges the two stacks: teams standardizing on Grafana can run [self-hosted Grafana](../grafana/index.md) for on-prem/Kubernetes and Azure Managed Grafana for Azure — or point a single Managed Grafana instance at both Prometheus and Azure Monitor.

## Related

- [Azure Monitor overview](index.md) — the stack and its components.
- [Data Collection](data-collection.md) — the telemetry these tools visualize.
- [Azure Alerts](alerts.md) — alerting on the same signals.
- [Grafana](../grafana/index.md) — the self-hosted visualization layer.
- [KQL](../../kql/index.md) — the query language behind workbook log tiles.

## References

- [Metrics Explorer](https://learn.microsoft.com/azure/azure-monitor/essentials/metrics-getting-started)
- [Azure Workbooks](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Azure dashboards](https://learn.microsoft.com/azure/azure-monitor/visualize/tutorial-logs-dashboards)
- [Azure Managed Grafana](https://learn.microsoft.com/azure/managed-grafana/overview)
