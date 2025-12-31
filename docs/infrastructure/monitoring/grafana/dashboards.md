---
title: "Grafana Dashboards"
description: "Comprehensive guide to creating, managing, and optimizing Grafana dashboards for monitoring infrastructure and applications"
author: "josephstreeter"
ms.author: "joseph.streeter"
ms.topic: how-to
ms.date: 12/30/2025
keywords: ["grafana", "dashboards", "visualization", "panels", "promql", "queries", "templates"]
uid: docs.infrastructure.grafana.dashboards
---

This guide covers creating, managing, and optimizing Grafana dashboards for effective monitoring and visualization of metrics from Prometheus and other data sources.

## Overview

Grafana dashboards provide a visual interface for monitoring metrics, logs, and traces. Effective dashboards enable quick identification of issues and understanding of system behavior.

**Key Concepts:**

- **Panels**: Individual visualizations (graphs, tables, gauges)
- **Rows**: Horizontal containers for organizing panels
- **Variables**: Dynamic values for filtering and templating
- **Time Range**: Control the data window being displayed
- **Annotations**: Mark events on time series graphs
- **Links**: Navigate between dashboards

## Dashboard Design Principles

### The Four Golden Signals

Monitor these key metrics for any system:

1. **Latency**: Time to service requests
2. **Traffic**: Demand on your system
3. **Errors**: Rate of failed requests
4. **Saturation**: Resource utilization

### Dashboard Best Practices

**Organization:**

- One dashboard per service or component
- Group related metrics together
- Use consistent naming conventions
- Arrange panels logically (top-to-bottom, left-to-right)

**Visualization:**

- Choose appropriate visualization types
- Use consistent time ranges
- Set meaningful Y-axis ranges
- Add units to metrics
- Use color coding consistently

**Performance:**

- Limit panels to 15-20 per dashboard
- Use recording rules for expensive queries
- Set appropriate refresh intervals
- Use template variables to reduce query count

## Creating Dashboards

### Manual Creation

1. **Create New Dashboard**

```text
1. Click "+" icon → Dashboard
2. Click "Add new panel"
3. Select data source (Prometheus)
4. Write query
5. Choose visualization
6. Configure panel options
7. Click "Apply"
```

1. **Dashboard Settings**

```json
{
  "title": "Service Overview",
  "tags": ["production", "service"],
  "timezone": "browser",
  "refresh": "30s",
  "time": {
    "from": "now-6h",
    "to": "now"
  }
}
```

### Dashboard as Code

Create dashboard JSON for version control:

```json
{
  "dashboard": {
    "title": "Node Exporter System Metrics",
    "uid": "node-exporter-system",
    "tags": ["infrastructure", "linux"],
    "timezone": "browser",
    "schemaVersion": 38,
    "refresh": "30s",
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "datasource": {
          "type": "prometheus",
          "uid": "prometheus-uid"
        },
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "color": {"mode": "palette-classic"}
          }
        }
      }
    ]
  }
}
```

### Provisioning Dashboards

Create provisioning configuration:

```yaml
# /etc/grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1

providers:
  - name: 'Infrastructure'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/infrastructure
```

Place dashboard JSON files in the specified path:

```bash
# Store dashboards in version control
mkdir -p /var/lib/grafana/dashboards/infrastructure
cp node-exporter.json /var/lib/grafana/dashboards/infrastructure/
cp postgres-metrics.json /var/lib/grafana/dashboards/infrastructure/
chown -R grafana:grafana /var/lib/grafana/dashboards
```

## Popular Pre-Built Dashboards

### Node Exporter Full (ID: 1860)

Comprehensive Linux system metrics:

```text
Import from grafana.com/dashboards/1860

Metrics:
- CPU utilization per core
- Memory usage and swap
- Disk I/O and utilization
- Network traffic
- System load
- Filesystem usage
```

**Customization Example:**

```promql
# Modify CPU query to exclude idle
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle",instance="$instance"}[5m])) * 100)

# Add temperature monitoring
node_hwmon_temp_celsius{instance="$instance"}

# Add custom filesystem filtering
node_filesystem_avail_bytes{instance="$instance",fstype!~"tmpfs|fuse.lxcfs"}
```

### Docker Container & Host Metrics (ID: 10619)

Container resource monitoring:

```text
Import from grafana.com/dashboards/10619

Metrics:
- Container CPU usage
- Container memory usage
- Container network I/O
- Container filesystem I/O
- Host metrics
```

### Kubernetes Cluster Monitoring (ID: 7249)

Kubernetes cluster overview:

```text
Import from grafana.com/dashboards/7249

Metrics:
- Cluster CPU/Memory usage
- Pod status and restarts
- Node status
- Namespace resource usage
- Persistent volume usage
```

### PostgreSQL Database (ID: 9628)

Database performance metrics:

```text
Import from grafana.com/dashboards/9628

Metrics:
- Connections and sessions
- Transaction rates
- Query performance
- Cache hit ratio
- Disk I/O
```

## PromQL Query Examples

### System Metrics

**CPU Usage by Core:**

```promql
# Per-core CPU usage
100 - (avg by(instance, cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Average CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage by mode
sum by(mode) (irate(node_cpu_seconds_total[5m])) * 100
```

**Memory Usage:**

```promql
# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memory used in GB
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

# Swap usage
(node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes * 100
```

**Disk Usage:**

```promql
# Disk usage percentage
100 - ((node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} * 100) / node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs"})

# Disk I/O operations per second
rate(node_disk_io_time_seconds_total[5m])

# Disk read/write bytes per second
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])
```

**Network Traffic:**

```promql
# Network receive rate (MB/s)
rate(node_network_receive_bytes_total[5m]) / 1024 / 1024

# Network transmit rate (MB/s)
rate(node_network_transmit_bytes_total[5m]) / 1024 / 1024

# Network errors
rate(node_network_receive_errs_total[5m])
rate(node_network_transmit_errs_total[5m])
```

### Container Metrics

**Container CPU:**

```promql
# Container CPU usage percentage
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (container, pod) * 100

# Container CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])
```

**Container Memory:**

```promql
# Container memory usage
container_memory_usage_bytes{container!=""}

# Container memory percentage
(container_memory_usage_bytes{container!=""} / container_spec_memory_limit_bytes{container!=""}) * 100

# Container memory cache
container_memory_cache{container!=""}
```

**Container Network:**

```promql
# Container network receive
rate(container_network_receive_bytes_total[5m])

# Container network transmit
rate(container_network_transmit_bytes_total[5m])
```

### Application Metrics

**HTTP Request Rate:**

```promql
# Requests per second
sum(rate(http_requests_total[5m])) by (method, status)

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Success rate percentage
(sum(rate(http_requests_total{status=~"2.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

**Request Latency:**

```promql
# 95th percentile latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# 99th percentile latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Average latency
sum(rate(http_request_duration_seconds_sum[5m])) / sum(rate(http_request_duration_seconds_count[5m]))
```

**Database Query Performance:**

```promql
# Query rate
rate(pg_stat_database_xact_commit[5m])

# Active connections
pg_stat_database_numbackends

# Cache hit ratio
sum(rate(pg_stat_database_blks_hit[5m])) / (sum(rate(pg_stat_database_blks_hit[5m])) + sum(rate(pg_stat_database_blks_read[5m]))) * 100
```

## Template Variables

### Variable Types

**Query Variable:**

```json
{
  "name": "instance",
  "type": "query",
  "datasource": "Prometheus",
  "query": "label_values(up, instance)",
  "refresh": 1,
  "multi": true,
  "includeAll": true
}
```

**Custom Variable:**

```json
{
  "name": "environment",
  "type": "custom",
  "options": [
    {"text": "Production", "value": "prod"},
    {"text": "Staging", "value": "staging"},
    {"text": "Development", "value": "dev"}
  ]
}
```

**Interval Variable:**

```json
{
  "name": "interval",
  "type": "interval",
  "options": ["1m", "5m", "15m", "30m", "1h"],
  "auto": true,
  "auto_min": "10s"
}
```

### Using Variables in Queries

```promql
# Filter by instance variable
node_cpu_seconds_total{instance=~"$instance"}

# Filter by multiple variables
http_requests_total{instance=~"$instance",environment="$environment"}

# Use interval variable for rate
rate(http_requests_total[$interval])

# Use regex for filtering
node_filesystem_avail_bytes{mountpoint=~"$mountpoint",fstype!~"tmpfs|fuse.*"}
```

### Chained Variables

```json
[
  {
    "name": "datacenter",
    "query": "label_values(datacenter)"
  },
  {
    "name": "cluster",
    "query": "label_values(up{datacenter=\"$datacenter\"}, cluster)"
  },
  {
    "name": "instance",
    "query": "label_values(up{datacenter=\"$datacenter\",cluster=\"$cluster\"}, instance)"
  }
]
```

## Panel Configuration

### Time Series Graph

**Configuration:**

```json
{
  "type": "timeseries",
  "title": "CPU Usage",
  "targets": [
    {
      "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "CPU Usage"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "color": {
        "mode": "thresholds"
      },
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 70, "color": "yellow"},
          {"value": 90, "color": "red"}
        ]
      }
    }
  },
  "options": {
    "legend": {"displayMode": "list", "placement": "bottom"},
    "tooltip": {"mode": "multi"}
  }
}
```

### Stat Panel

**Single Value Display:**

```json
{
  "type": "stat",
  "title": "Total Requests",
  "targets": [
    {
      "expr": "sum(http_requests_total)"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "short",
      "color": {"mode": "thresholds"},
      "mappings": [],
      "thresholds": {
        "steps": [
          {"value": 0, "color": "blue"}
        ]
      }
    }
  },
  "options": {
    "graphMode": "area",
    "colorMode": "value",
    "textMode": "auto"
  }
}
```

### Gauge Panel

**Progress Indicator:**

```json
{
  "type": "gauge",
  "title": "Disk Usage",
  "targets": [
    {
      "expr": "100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 70, "color": "yellow"},
          {"value": 85, "color": "red"}
        ]
      }
    }
  },
  "options": {
    "showThresholdLabels": true,
    "showThresholdMarkers": true
  }
}
```

### Table Panel

**Tabular Data:**

```json
{
  "type": "table",
  "title": "Instance Status",
  "targets": [
    {
      "expr": "up",
      "format": "table",
      "instant": true
    }
  ],
  "fieldConfig": {
    "overrides": [
      {
        "matcher": {"id": "byName", "options": "Value"},
        "properties": [
          {
            "id": "custom.displayMode",
            "value": "color-background"
          },
          {
            "id": "mappings",
            "value": [
              {"type": "value", "value": "0", "text": "Down", "color": "red"},
              {"type": "value", "value": "1", "text": "Up", "color": "green"}
            ]
          }
        ]
      }
    ]
  },
  "transformations": [
    {
      "id": "organize",
      "options": {
        "excludeByName": {"Time": true},
        "renameByName": {"instance": "Instance", "Value": "Status"}
      }
    }
  ]
}
```

### Heatmap Panel

**Distribution Visualization:**

```json
{
  "type": "heatmap",
  "title": "Request Latency Distribution",
  "targets": [
    {
      "expr": "sum(rate(http_request_duration_seconds_bucket[5m])) by (le)",
      "format": "heatmap",
      "legendFormat": "{{le}}"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "s"
    }
  },
  "options": {
    "calculate": true,
    "cellGap": 2,
    "color": {
      "mode": "scheme",
      "scheme": "Spectral"
    }
  }
}
```

## Dashboard Organization

### Folder Structure

```text
Infrastructure/
├── System Metrics/
│   ├── Node Exporter Overview
│   ├── CPU Analysis
│   ├── Memory Analysis
│   └── Disk Performance
├── Container Metrics/
│   ├── Docker Overview
│   ├── Kubernetes Cluster
│   └── Pod Performance
└── Network/
    ├── Network Traffic
    ├── UniFi Devices
    └── Blackbox Probes

Applications/
├── Backend Services/
│   ├── API Gateway
│   ├── Authentication Service
│   └── Database Connections
├── Frontend/
│   ├── Web Application
│   └── Mobile API
└── Batch Jobs/
    └── Job Monitoring

Business Metrics/
├── User Analytics
├── Revenue Metrics
└── SLA Compliance
```

### Row Organization

```json
{
  "panels": [
    {
      "type": "row",
      "title": "System Overview",
      "collapsed": false,
      "panels": [
        /* CPU, Memory, Disk panels */
      ]
    },
    {
      "type": "row",
      "title": "Network Performance",
      "collapsed": true,
      "panels": [
        /* Network panels */
      ]
    },
    {
      "type": "row",
      "title": "Application Metrics",
      "collapsed": true,
      "panels": [
        /* Application panels */
      ]
    }
  ]
}
```

## Advanced Features

### Annotations

**Query-Based Annotations:**

```json
{
  "annotations": {
    "list": [
      {
        "datasource": "Prometheus",
        "name": "Deployments",
        "expr": "changes(process_start_time_seconds[1m]) > 0",
        "step": "60s",
        "tagKeys": "instance,version",
        "titleFormat": "Deployment",
        "textFormat": "{{instance}}"
      },
      {
        "datasource": "Prometheus",
        "name": "Alerts",
        "expr": "ALERTS{alertstate=\"firing\"}",
        "tagKeys": "alertname,severity",
        "titleFormat": "{{alertname}}",
        "textFormat": "{{severity}}: {{alertname}}"
      }
    ]
  }
}
```

### Dashboard Links

**Navigation Links:**

```json
{
  "links": [
    {
      "title": "System Dashboards",
      "type": "dashboards",
      "tags": ["system"],
      "icon": "external link"
    },
    {
      "title": "Related Dashboard",
      "type": "link",
      "url": "/d/xyz/other-dashboard",
      "targetBlank": false
    },
    {
      "title": "Prometheus",
      "type": "link",
      "url": "http://prometheus:9090",
      "targetBlank": true
    }
  ]
}
```

### Transformations

**Data Transformations:**

```json
{
  "transformations": [
    {
      "id": "merge",
      "options": {}
    },
    {
      "id": "organize",
      "options": {
        "excludeByName": {"Time": true},
        "indexByName": {"instance": 0, "Value": 1},
        "renameByName": {"Value": "CPU Usage"}
      }
    },
    {
      "id": "calculateField",
      "options": {
        "alias": "Usage %",
        "binary": {
          "left": "Value",
          "operator": "*",
          "right": "100"
        },
        "mode": "binary"
      }
    }
  ]
}
```

## Performance Optimization

### Query Optimization

**Use Recording Rules:**

```yaml
# Prometheus recording rules
groups:
  - name: dashboard_rules
    interval: 30s
    rules:
      - record: instance:node_cpu_utilization:rate5m
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Use in dashboard:

```promql
# Instead of complex query
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Use recording rule
instance:node_cpu_utilization:rate5m
```

**Limit Time Range:**

```json
{
  "targets": [
    {
      "expr": "rate(http_requests_total[5m])",
      "maxDataPoints": 1000
    }
  ]
}
```

**Use Appropriate Step:**

```promql
# Automatic step based on dashboard time range
rate(metric[5m])

# Manual step for specific resolution
rate(metric[5m])[$__interval]
```

### Dashboard Settings

**Optimize Refresh Rate:**

```json
{
  "refresh": "30s",  // Not "5s" for production
  "time": {
    "from": "now-6h",
    "to": "now"
  }
}
```

**Limit Panel Count:**

- Maximum 15-20 panels per dashboard
- Use rows to collapse less important metrics
- Create separate dashboards for detailed views

**Cache Settings:**

```json
{
  "targets": [
    {
      "expr": "up",
      "interval": "30s",
      "intervalFactor": 2
    }
  ]
}
```

## Dashboard Export and Import

### Export Dashboard

```bash
# Export via API
curl -H "Authorization: Bearer ${API_KEY}" \
  "http://grafana:3000/api/dashboards/uid/${DASHBOARD_UID}" \
  | jq '.dashboard' > dashboard.json

# Export via UI
# Dashboard → Settings → JSON Model → Copy to clipboard
```

### Import Dashboard

```bash
# Import via API
curl -X POST \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d @dashboard.json \
  "http://grafana:3000/api/dashboards/db"

# Import via UI
# + → Import → Upload JSON file
```

### Version Control

```bash
# Store dashboards in Git
mkdir -p dashboards/{infrastructure,applications,business}

# Export all dashboards
./scripts/export-dashboards.sh

# Commit to version control
git add dashboards/
git commit -m "Update dashboards"
git push

# Restore from version control
git pull
./scripts/import-dashboards.sh
```

## Troubleshooting

### Common Issues

**No Data in Panels:**

```bash
# Check data source connectivity
curl "http://grafana:3000/api/datasources/proxy/1/api/v1/query?query=up"

# Verify Prometheus has data
curl "http://prometheus:9090/api/v1/query?query=up"

# Check query syntax
# Use Prometheus UI to test queries first
```

**Slow Dashboard Loading:**

```bash
# Check query performance
# Use Prometheus → Status → Query Log

# Reduce time range
# Use smaller intervals

# Optimize queries with recording rules
```

**Variables Not Loading:**

```bash
# Check variable query syntax
label_values(metric_name, label_name)

# Verify data source is selected
# Check variable refresh settings
```

## Best Practices Checklist

- ✅ Use meaningful dashboard titles and descriptions
- ✅ Add tags for organization
- ✅ Use template variables for flexibility
- ✅ Set appropriate time ranges and refresh intervals
- ✅ Add units to all metrics
- ✅ Use thresholds and color coding
- ✅ Group related panels in rows
- ✅ Add annotations for deployments and incidents
- ✅ Use recording rules for expensive queries
- ✅ Version control dashboard JSON
- ✅ Document custom queries and transformations
- ✅ Test dashboards before deploying
- ✅ Set up alerts for critical metrics
- ✅ Regularly review and optimize

## See Also

- [Prometheus Configuration](index.md)
- [Configuration Guide](configuration.md)
- [Alerting Configuration](alerting.md)
- [Exporters Configuration](exporters.md)

## References

- [Grafana Dashboard Documentation](https://grafana.com/docs/grafana/latest/dashboards/)
- [Grafana Panel Documentation](https://grafana.com/docs/grafana/latest/panels/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Variables](https://grafana.com/docs/grafana/latest/variables/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
