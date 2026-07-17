---
title: Azure Alerts
description: Azure Monitor alerting - metric, log search, and activity-log alert rules, dynamic thresholds, action groups, and alert processing rules, with a mapping to Prometheus Alertmanager.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: how-to
ms.service: azure-monitor
keywords: Azure Alerts, alert rules, metric alerts, log alerts, action groups, alert processing rules, dynamic thresholds
uid: docs.infrastructure.azure-monitor.alerts
---

## Azure Alerts

Azure Alerts is the alerting engine of Azure Monitor — the managed counterpart to Prometheus alert rules plus [Alertmanager](../alertmanager/index.md). An **alert rule** watches a signal, evaluates a condition, and when it fires, invokes one or more **action groups** that deliver the notification and can trigger automated responses.

```text
 Signal (metric | log | activity log)
        │  evaluated on a schedule
        ▼
 Alert rule ──fires──► Alert (state: New → Acknowledged → Closed)
        │
        ▼
 Action group ──► email · SMS · push · voice · webhook · Logic App · Function · ITSM · Automation runbook
        ▲
 Alert processing rule (suppress during maintenance · add/override action groups at scale)
```

> [!NOTE]
> **Mapping from the Prometheus stack:** an Azure **alert rule** ≈ a Prometheus **alert rule**; an Azure **action group** ≈ an Alertmanager **receiver**; an Azure **alert processing rule** ≈ Alertmanager **silences / routing / inhibition**. If you know the [Prometheus alerting model](../prometheus/alerting.md), you already know the shape of this.

## Alert rule types

Azure has three alert rule types, distinguished by the signal they evaluate.

### Metric alerts

Evaluate a **platform or custom metric** on a schedule with low latency (near-real-time). Cheapest and fastest to fire; use them for anything expressible as a metric.

- **Static threshold** — `Percentage CPU > 90` over 5 minutes.
- **Dynamic threshold** — machine-learning baseline that adapts to the metric's historical pattern, good for seasonal signals where a fixed number would be wrong.
- **Multi-dimension** — split by a dimension (e.g. per disk, per instance) so one rule covers many time series and each fires independently.
- **Multi-resource** — one rule applied across all VMs in a subscription/region.

```bash
# Static metric alert: VM CPU over 90% for 5 minutes
az monitor metrics alert create \
  --name "vm-cpu-high" \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 90" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$ACTION_GROUP_ID" \
  --severity 2
```

```hcl
resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  name                = "vm-cpu-high"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [var.vm_id]
  description         = "VM CPU over 90% for 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.oncall_critical.id
  }
}
```

### Log search alerts

Run a scheduled **[KQL](../../kql/index.md) query** against a Log Analytics workspace or Application Insights and fire when the results meet a condition. More flexible than metric alerts (any log signal, joins, aggregations) but higher latency and cost.

- **Measurement** — number of results, or an aggregated value (`count`, `avg`) per dimension.
- **Threshold and frequency** — e.g. fire when the query returns `> 0` rows, evaluated every 5 minutes.
- **Dimensions** — group by columns so each host/app fires its own alert.

```kql
// Log search alert: machines with no heartbeat in the last 10 minutes
Heartbeat
| summarize LastSeen = max(TimeGenerated) by Computer
| where LastSeen < ago(10m)
```

As a Terraform scheduled query rule (v2), firing when the query returns any rows:

```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "host_down" {
  name                = "host-no-heartbeat"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  severity            = 1
  scopes              = [azurerm_log_analytics_workspace.core.id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"

  criteria {
    query                   = <<-KQL
      Heartbeat
      | summarize LastSeen = max(TimeGenerated) by Computer
      | where LastSeen < ago(10m)
    KQL
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.oncall_critical.id]
  }
}
```

> [!TIP]
> Prefer a **metric alert** over a log search alert whenever the signal exists as a metric — it fires faster, costs less, and does not consume query capacity. Reserve log alerts for conditions only expressible in KQL.

### Activity log alerts

Fire on **control-plane events** from the activity log — a resource deleted, a service-health incident in your region, a policy assignment changed. Use them for governance and platform-health awareness rather than performance.

```bash
# Alert on any VM delete in the subscription
az monitor activity-log alert create \
  --name "vm-deleted" \
  --resource-group "$RG" \
  --condition category=Administrative and operationName=Microsoft.Compute/virtualMachines/delete \
  --action-group "$ACTION_GROUP_ID"
```

```hcl
data "azurerm_subscription" "current" {}

resource "azurerm_monitor_activity_log_alert" "vm_deleted" {
  name                = "vm-deleted"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Compute/virtualMachines/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.oncall_critical.id
  }
}
```

## Severity and state

- **Severity** runs from **Sev 0 (critical)** to **Sev 4 (verbose)** — set it deliberately so downstream routing and on-call escalation can key off it.
- **Alert state** is `New → Acknowledged → Closed`, tracked separately from the underlying **condition** (monitor) state of `Fired`/`Resolved`. Auto-resolution closes stateful alerts when the condition clears.

## Action groups

An **action group** is a reusable named set of notifications and actions. Reference the same group from many rules so on-call routing lives in one place.

**Notifications:** email, SMS, Azure mobile-app push, and voice.

**Actions:** webhook, Logic App, Azure Function, Automation runbook, Event Hub, and **ITSM** connectors (ServiceNow, etc.).

```bash
az monitor action-group create \
  --name "oncall-critical" \
  --resource-group "$RG" \
  --short-name "oncall" \
  --action email  primary  oncall@example.com \
  --action webhook pager    https://events.pagerduty.com/integration/XXXX/enqueue
```

```hcl
resource "azurerm_monitor_action_group" "oncall_critical" {
  name                = "oncall-critical"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "oncall"

  email_receiver {
    name          = "primary"
    email_address = "oncall@example.com"
  }

  webhook_receiver {
    name                    = "pager"
    service_uri             = "https://events.pagerduty.com/integration/XXXX/enqueue"
    use_common_alert_schema = true
  }
}
```

> [!IMPORTANT]
> Use **common alert schema** on your action groups so every downstream receiver (webhook, Logic App, ITSM) gets a consistent payload regardless of alert type. Without it, metric, log, and activity-log alerts send different shapes and your integrations must special-case each.

## Alert processing rules

**Alert processing rules** act on alerts *after* they fire, at scale — the Azure equivalent of Alertmanager silences and routing overrides:

- **Suppress notifications** during a planned maintenance window (by resource group, subscription, or tag).
- **Add or override action groups** across a scope without editing each rule — e.g. route everything tagged `env=prod` to the on-call group.

## Recommended baseline

A pragmatic starting set that mirrors the [canonical Prometheus alert rules](../prometheus/alerting.md):

| Alert | Signal | Type |
| ----- | ------ | ---- |
| Instance/host down | `Heartbeat` gap or `Percentage CPU` unavailable | Log / metric |
| High CPU | `Percentage CPU > 90` (5m) | Metric (dynamic) |
| Low memory | `Available Memory Bytes` below threshold | Metric |
| Low disk space | guest `% Free Space < 15` | Metric / log |
| High app failure rate | `AppRequests` failure ratio | Log search |
| Resource deleted | activity log `*/delete` | Activity log |
| Service health | Azure service-health event | Activity log |

> [!TIP]
> Azure's **recommended alert rules** experience can enable a curated metric-alert set for VMs and other resource types in one step. Start there, then layer log search alerts for application-specific conditions.

## Choosing: Azure Alerts vs Prometheus + Alertmanager

- **Azure Alerts** — no infrastructure, native to Azure resources, integrated action groups and ITSM. Best when your estate is Azure-centric.
- **Prometheus + Alertmanager** — richer routing/inhibition/grouping, portable across clouds, no per-rule/per-evaluation billing. Best for Kubernetes and multi-cloud.
- **Hybrid** — Managed Prometheus can also raise **Prometheus rule alerts** that flow into Azure action groups, letting you keep PromQL rules while using Azure's notification plumbing.

## Related

- [Azure Monitor overview](index.md) — the stack and choosing between it and Prometheus.
- [Data Collection](data-collection.md) — the metrics and logs these rules evaluate.
- [Prometheus — Alerting](../prometheus/alerting.md) and [Alertmanager](../alertmanager/index.md) — the self-hosted counterparts.

## References

- [Azure Monitor alerts overview](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-overview)
- [Metric alerts](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-types#metric-alerts)
- [Log search alerts](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-types#log-alerts)
- [Action groups](https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups)
- [Alert processing rules](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-processing-rules)
- [Common alert schema](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-common-schema)
