---
title: "Infrastructure Monitoring"
description: "Comprehensive infrastructure monitoring, alerting, and observability solutions"
author: "Joseph Streeter"
ms.author: josephstreeter
ms.date: "2025-09-08"
ms.topic: "article"
---

## Infrastructure Monitoring

Infrastructure monitoring is essential for maintaining system reliability, performance, and availability. This page is the **overview and map** of the monitoring section; the detailed, authoritative guides live in the linked sub-sections. To avoid drift, this page intentionally keeps only orientation and breadth — configuration details are not duplicated here.

## Overview

Effective infrastructure monitoring provides:

- **Real-time visibility** into system health and performance
- **Proactive alerting** for potential issues before they become problems
- **Historical data** for capacity planning and trend analysis
- **Root cause analysis** capabilities for faster incident resolution
- **Compliance reporting** for regulatory requirements

## Two Monitoring Stacks

This section documents two complete stacks that solve the same problem in different ways. Pick the one that fits your environment — or run both in a hybrid.

| Stack | What it is | Best for |
| ----- | ---------- | -------- |
| **[Prometheus + Grafana](prometheus/index.md)** (self-hosted) | Open-source metrics, alerting, and dashboards you run and scale yourself | Kubernetes, multi-cloud, on-prem, full control, no per-GB cost |
| **[Azure Monitor + Azure Alerts](azure-monitor/index.md)** (managed) | Cloud-native, fully managed metrics, logs, alerting, and visualization | Azure-native and Arc-managed workloads, minimal operational overhead |

The bulk of this section details the **Prometheus + Grafana** stack (below). The **[Azure Monitor](azure-monitor/index.md)** subsection covers the managed alternative and maps each Azure component back to its Prometheus-stack equivalent. A common hybrid keeps Prometheus for Kubernetes and uses Azure Monitor for Azure platform resources, with a single [Azure Managed Grafana](azure-monitor/visualization.md#azure-managed-grafana) pane over both.

## Monitoring Stack Components

### Metrics Collection

- **System Metrics**: CPU, memory, disk, network utilization
- **Application Metrics**: Response times, error rates, throughput
- **Custom Metrics**: Business-specific measurements
- **Infrastructure Metrics**: Database, web server, load balancer performance

### Time Series Databases

- **[Prometheus](prometheus/index.md)** - Open-source monitoring and alerting toolkit (the primary metrics store in this stack)
- **InfluxDB** - Purpose-built time series database
- **Grafana Cloud** - Managed observability platform
- **[Azure Monitor](azure-monitor/index.md)** - Cloud-native, fully managed metrics and logs (the alternate stack)

### Visualization and Dashboards

- **[Grafana](grafana/index.md)** - Feature-rich visualization and analytics platform
- **Kibana** - Data visualization for Elasticsearch
- **[Azure Monitor Workbooks](azure-monitor/visualization.md)** - Interactive reports and dashboards

## The Prometheus + Grafana Stack

The core of this section is an open-source Prometheus + Grafana stack — no licensing cost, a large exporter ecosystem, PromQL for analysis, and Kubernetes-native deployment. Its components:

| Component | Role |
| --------- | ---- |
| **Prometheus** | Time-series database that scrapes and stores metrics and evaluates alert rules |
| **Grafana** | Visualization, dashboards, and (optionally) unified alerting |
| **Alertmanager** | Routes, groups, silences, and delivers alerts from Prometheus |
| **Node Exporter / cAdvisor / Blackbox** | Expose host, container, and endpoint metrics for Prometheus to scrape |
| **Thanos / Cortex / VictoriaMetrics** | Long-term storage and high availability (optional) |

Production concerns — high availability, TLS/auth, retention/cardinality, and backups — are covered in the per-component guides below.

Each component has a complete guide:

| Guide | Covers |
| ----- | ------ |
| [Prometheus — Overview](prometheus/index.md) | Installation, scrape configs, service discovery, PromQL, recording/alerting rules, retention, securing the server |
| [Prometheus — Exporters](prometheus/exporters.md) | Node Exporter, cAdvisor, Blackbox, and database exporters |
| [Prometheus — Alerting](prometheus/alerting.md) | Prometheus alert rules, Alertmanager routing, and Grafana unified alerting (choose one) |
| [Prometheus — High Availability](prometheus/high-availability.md) | Multiple replicas, Thanos, federation, and remote storage for the metrics pipeline |
| [Prometheus — Backup and Recovery](prometheus/backup-recovery.md) | TSDB snapshots, shared backup storage, disaster recovery, and automation |
| [Alertmanager](alertmanager/index.md) | Alert routing, grouping, silences, inhibition, time intervals, receivers, clustering |
| [Grafana — Overview](grafana/index.md) | Grafana landing page — visualization, dashboards, and the Grafana-specific guides |
| [Grafana — Installation](grafana/installation.md) | Docker Compose and native install, secrets |
| [Grafana — Configuration](grafana/configuration.md) | `grafana.ini`, provisioning, data sources |
| [Grafana — Dashboards](grafana/dashboards.md) | Building and provisioning dashboards |
| [Grafana — Security](grafana/security.md) | TLS/mTLS, authentication, hardening |
| [Grafana — High Availability](grafana/high-availability.md) | Grafana clustering — shared database backend and load balancing |
| [Grafana — Backup and Recovery](grafana/backup-recovery.md) | Backing up the Grafana database, dashboards, and provisioning |

### Quick Start

Follow [Grafana — Installation](grafana/installation.md) for a complete `docker compose` stack (Prometheus, Grafana, Alertmanager, Node Exporter, cAdvisor). A minimal `prometheus.yml` shows the shape of the configuration:

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']
```

> [!NOTE]
> The **canonical alert-rule set** (InstanceDown, HighCPUUsage, HighMemoryUsage, DiskSpaceLow, HighErrorRate) and full scrape/relabel configuration live in the [Prometheus guide](prometheus/index.md). Alert **routing and notification** live in the [Alertmanager guide](alertmanager/index.md). This stack can alert through either **Prometheus + Alertmanager** or **Grafana unified alerting** — pick one per environment to avoid duplicate notifications (see [Prometheus — Alerting](prometheus/alerting.md)).

## Beyond the Core Stack

The following are complementary approaches this section references but does not document in depth.

### Cloud Monitoring

- **Azure Monitor** — the managed alternate stack, documented in depth in the [Azure Monitor subsection](azure-monitor/index.md); agent-based and agentless monitoring for Azure and hybrid resources, integrating Log Analytics, Application Insights, Azure Alerts, and Workbooks.
- **AWS CloudWatch** — metrics, logs, and alarms for AWS workloads; metric filters extract metrics from log groups.
- **Grafana Cloud** — managed Prometheus/Loki/Grafana if you prefer not to self-host.

### Log Management

Metrics answer "what is happening"; logs answer "why". Common log pipelines:

- **ELK / Elastic Stack** (Elasticsearch + Logstash + Kibana) — see the [ELK Stack container guide](../containers/elk-stack/index.md).
- **Grafana Loki** — a log store that pairs with Grafana, using labels like Prometheus.
- **Fluentd / Fluent Bit** — log collectors/forwarders, common in Kubernetes.

### Application Performance Monitoring (APM)

Distributed tracing and request-level telemetry (latency, error rate, dependencies) complement infrastructure metrics. Options include OpenTelemetry (vendor-neutral instrumentation), Grafana Tempo (traces), Jaeger, and Elastic APM. Use consistent sampling and correlate traces with metrics and logs.

### Container and Kubernetes Monitoring

- **Docker** — container and host metrics via cAdvisor and Node Exporter. See [Docker monitoring](../containers/docker/monitoring.md).
- **Kubernetes** — the kube-prometheus-stack (Prometheus Operator) is the standard, adding kube-state-metrics and service discovery. See [Kubernetes monitoring](../containers/kubernetes/monitoring.md).

## Best Practices

### Monitoring Strategy

- **Start with the basics**: CPU, memory, disk, network
- **Monitor what matters**: Focus on business-critical metrics
- **Set meaningful alerts**: Avoid alert fatigue with proper thresholds
- **Document your monitoring**: Maintain runbooks for common alerts
- **Regular review**: Continuously refine and improve monitoring

### Alert Design

- **Clear alert names**: Use descriptive alert names and summaries
- **Actionable alerts**: Every alert should have a clear resolution path
- **Severity levels**: Use appropriate severity levels (info, warning, critical)
- **Alert grouping**: Group related alerts to reduce noise
- **Escalation policies**: Define clear escalation procedures

### Dashboard Design

- **User-focused**: Design dashboards for specific audiences
- **Key metrics first**: Most important metrics should be prominently displayed
- **Consistent layout**: Use consistent colors, fonts, and layouts
- **Drill-down capability**: Enable users to explore details
- **Regular updates**: Keep dashboards current and relevant

## Troubleshooting

### Common Monitoring Issues

1. **High cardinality metrics**

   ```bash
   # Check total number of series/label values
   curl http://localhost:9090/api/v1/label/__name__/values | jq '.data | length'
   ```

2. **Missing metrics**

   ```bash
   # Verify scrape targets and their health
   curl http://localhost:9090/api/v1/targets
   ```

3. **Alert fatigue** — review how often alerts fire and tune thresholds/grouping. A meta-alert can flag noisy rules:

   ```yaml
   - alert: HighAlertFrequency
     expr: increase(prometheus_notifications_total[1h]) > 10
   ```

### Performance and Retention

Prometheus retention and storage limits are set with **command-line flags** (not a config-file section):

```bash
# In the Prometheus startup command / docker-compose command:
--storage.tsdb.retention.time=30d    # keep 30 days of data
--storage.tsdb.retention.size=10GB   # cap on-disk size
```

For less critical targets, raise `scrape_interval`/`evaluation_interval` in `prometheus.yml` to reduce load. See the [Prometheus guide](prometheus/index.md) for cardinality, recording rules, and remote storage.

## Related Documentation

- **[Prometheus](prometheus/index.md)** - Complete Prometheus monitoring system documentation
- **[Alertmanager](alertmanager/index.md)** - Alert routing and notification management
- **[Grafana](grafana/index.md)** - Dashboards, configuration, security, exporters, alerting, HA, and backup
- **[Azure Monitor](azure-monitor/index.md)** - The managed alternate stack: data collection, Azure Alerts, and visualization
- **[Container Monitoring](../containers/docker/monitoring.md)** - Docker-specific monitoring
- **[Kubernetes Monitoring](../containers/kubernetes/monitoring.md)** - K8s cluster monitoring
- **[Infrastructure Security](../security/index.md)** - Securing monitoring infrastructure
