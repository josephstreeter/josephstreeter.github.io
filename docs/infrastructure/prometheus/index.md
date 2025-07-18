---
title: Prometheus Monitoring System
description: Complete guide to Prometheus, an open-source monitoring and alerting system designed for reliability and scalability in modern cloud-native environments.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: prometheus
keywords: Prometheus, monitoring, alerting, metrics, observability, time series, Grafana, DevOps
uid: docs.infrastructure.prometheus.index
---

Prometheus is an open-source monitoring and alerting system originally developed by SoundCloud in 2012. It has become the de facto standard for monitoring cloud-native applications and is a graduated project of the Cloud Native Computing Foundation (CNCF).

> [!NOTE]
> Prometheus is designed for reliability and scalability, making it ideal for monitoring microservices, containers, and distributed systems in dynamic environments.

## What is Prometheus?

Prometheus is a **time-series database** and **monitoring system** that collects metrics from configured targets at given intervals, evaluates rule expressions, displays results, and can trigger alerts when specified conditions are met.

### Key Characteristics

- **Pull-based model**: Prometheus scrapes metrics from HTTP endpoints
- **Time-series data**: All data is stored as time-series with timestamps
- **PromQL**: Powerful functional query language for data analysis
- **Multi-dimensional data**: Metrics can have multiple labels for flexible querying
- **No dependencies**: Single binary with local storage
- **Service discovery**: Automatic discovery of monitoring targets

## Core Components

### Prometheus Server

The main component that scrapes and stores time-series data, and serves queries via PromQL.

### Client Libraries

Libraries for instrumenting application code in various programming languages (Go, Java, Python, .NET, etc.).

### Pushgateway

Allows ephemeral and batch jobs to push metrics to Prometheus.

### Exporters

Third-party tools that export metrics from existing systems (databases, hardware, messaging systems, etc.).

### Alertmanager

Handles alerts sent by Prometheus server and routes them to various notification channels.

## How Prometheus Works

### 1. Metrics Collection

Prometheus uses a **pull model** to collect metrics:

```yaml
# prometheus.yml configuration
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'application'
    static_configs:
      - targets: ['app1:8080', 'app2:8080']
```

### 2. Data Model

Prometheus stores all data as time-series, identified by:

- **Metric name**: Describes the feature being measured
- **Labels**: Key-value pairs for multi-dimensional data
- **Timestamp**: When the measurement was taken
- **Value**: The numeric measurement

Example metric:

```text
http_requests_total{method="GET", handler="/api/users", status="200"} 1027
```

### 3. Metric Types

#### Counter

Cumulative metric that only increases (or resets to zero):

```text
http_requests_total
process_cpu_seconds_total
```

#### Gauge

Metric that can go up and down:

```text
memory_usage_bytes
cpu_temperature_celsius
active_connections
```

#### Histogram

Samples observations and counts them in configurable buckets:

```text
http_request_duration_seconds
response_size_bytes
```

#### Summary

Similar to histogram but calculates quantiles over a sliding time window:

```text
request_duration_seconds{quantile="0.5"}
request_duration_seconds{quantile="0.9"}
```

## PromQL - Prometheus Query Language

PromQL is a functional query language that allows you to select and aggregate time-series data.

### Basic Queries

```promql
# Select all time series with a specific metric name
http_requests_total

# Filter by labels
http_requests_total{method="GET"}

# Multiple label filters
http_requests_total{method="GET", status="200"}

# Regular expression matching
http_requests_total{handler=~"/api/.*"}
```

### Rate and Range Queries

```promql
# Rate of requests per second over 5 minutes
rate(http_requests_total[5m])

# Average CPU usage over 10 minutes
avg_over_time(cpu_usage_percent[10m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Aggregation

```promql
# Sum of requests across all instances
sum(http_requests_total)

# Average memory usage by job
avg by (job) (memory_usage_bytes)

# Top 5 endpoints by request rate
topk(5, rate(http_requests_total[5m]))
```

## Setting Up Prometheus

### Installation Options

#### Docker

```bash
# Run Prometheus in Docker
docker run -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

#### Binary Installation

```bash
# Download and extract
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# Run Prometheus
./prometheus --config.file=prometheus.yml
```

#### Kubernetes (Helm)

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack
```

### Basic Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
      
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 30s
    metrics_path: /metrics
```

## Common Use Cases

### Infrastructure Monitoring

> [!TIP]
> Use Node Exporter to monitor Linux/Unix system metrics like CPU, memory, disk, and network.

```bash
# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvfz node_exporter-*.tar.gz
./node_exporter
```

Key infrastructure metrics:

- CPU usage: `node_cpu_seconds_total`
- Memory usage: `node_memory_MemAvailable_bytes`
- Disk usage: `node_filesystem_avail_bytes`
- Network traffic: `node_network_receive_bytes_total`

### Application Monitoring

Instrument your applications to expose custom metrics:

#### Go Example

```go
package main

import (
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
}

func handler(w http.ResponseWriter, r *http.Request) {
    // Your application logic here
    httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
```

### Container Monitoring

Monitor Docker containers and Kubernetes:

```yaml
# Docker Compose with Prometheus
version: '3'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      
  cadvisor:
    image: google/cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
```

## Alerting with Prometheus

### Alert Rules

```yaml
# alert_rules.yml
groups:
  - name: example_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"
          
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"
          
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is above 90%"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@company.com'
        subject: 'Prometheus Alert'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

## Integration with Grafana

> [!IMPORTANT]
> While Prometheus provides basic graphing capabilities, Grafana is the preferred tool for creating rich, interactive dashboards.

### Setting up Grafana with Prometheus

```bash
# Run Grafana
docker run -d -p 3000:3000 grafana/grafana

# Access Grafana at http://localhost:3000
# Default credentials: admin/admin
```

### Adding Prometheus as Data Source

1. Go to Configuration → Data Sources
2. Add Prometheus data source
3. Set URL to `http://prometheus:9090`
4. Click "Save & Test"

## Best Practices

### Metric Naming

> [!TIP]
> Follow Prometheus naming conventions for consistency and clarity.

- Use snake_case: `http_requests_total`
- Include units: `process_cpu_seconds_total`
- Use descriptive names: `database_connection_pool_size`

### Label Usage

- Keep labels finite and low-cardinality
- Avoid putting IDs or high-cardinality data in labels
- Use consistent label names across metrics

```promql
# Good
http_requests_total{method="GET", status="200"}

# Avoid - high cardinality
http_requests_total{user_id="12345", session_id="abc123"}
```

### Performance Optimization

- Set appropriate scrape intervals (15s-1m for most cases)
- Use recording rules for expensive queries
- Monitor Prometheus itself
- Consider federation for large deployments

## Troubleshooting

### Common Issues

> [!WARNING]
> High cardinality metrics can cause memory issues and slow queries. Monitor your metrics carefully.

- **High memory usage**: Check for high-cardinality metrics
- **Slow queries**: Use `query_log` to identify expensive queries
- **Missing metrics**: Verify target discovery and scrape configs
- **Alert fatigue**: Fine-tune alert thresholds and conditions

### Monitoring Prometheus

```promql
# Prometheus self-monitoring queries
prometheus_tsdb_symbol_table_size_bytes
prometheus_config_last_reload_successful
rate(prometheus_http_requests_total[5m])
prometheus_notifications_total
```

## Next Steps

- Learn advanced [PromQL functions and operators](https://prometheus.io/docs/prometheus/latest/querying/functions/index.md)
- Explore [Grafana dashboard creation](https://grafana.com/docs/grafana/latest/dashboards/index.md)
- Study [alerting best practices](https://prometheus.io/docs/practices/alerting/index.md)
- Set up [high availability Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/index.md)

## Related Resources

- [Prometheus Official Documentation](https://prometheus.io/docs/index.md)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/index.md)
- [Grafana Documentation](https://grafana.com/docs/index.md)
- [Exporters and Integrations](https://prometheus.io/docs/instrumenting/exporters/index.md)
- [Prometheus Operator for Kubernetes](https://github.com/prometheus-operator/prometheus-operator)
- [Best Practices Guide](https://prometheus.io/docs/practices/naming/index.md)
