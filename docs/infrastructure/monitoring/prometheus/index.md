---
title: "Prometheus Monitoring System"
description: "Complete guide to Prometheus, an open-source monitoring and alerting system designed for reliability and scalability in modern cloud-native and containerized environments"
tags: ["prometheus", "monitoring", "alerting", "metrics", "observability", "containers", "kubernetes", "grafana", "promql"]
category: "infrastructure"
subcategory: "containers"
difficulty: "intermediate"
last_updated: "2025-01-14"
author: "Joseph Streeter"
---

Prometheus is an open-source monitoring and alerting system originally developed by SoundCloud in 2012 and is now a graduated project of the Cloud Native Computing Foundation (CNCF). It has become the de facto standard for monitoring cloud-native applications, containerized workloads, and distributed systems in dynamic environments.

## Overview

Prometheus fundamentally changes how you approach monitoring by using a pull-based model to collect metrics from instrumented jobs. It stores all data as time series, identified by metric names and key/value pairs called labels. This approach makes it particularly well-suited for dynamic, containerized environments where services come and go frequently.

### Core Concepts

- **Metrics**: Numerical measurements over time (CPU usage, request count, etc.)
- **Time Series**: A stream of timestamped values belonging to the same metric and label set
- **Labels**: Key-value pairs that identify different dimensions of a metric
- **Targets**: Endpoints that Prometheus scrapes for metrics
- **Jobs**: Collections of targets with the same purpose
- **Instances**: Individual endpoints of a job

### Key Characteristics

- **Pull-based model**: Prometheus scrapes metrics from HTTP endpoints
- **Time-series data**: All data is stored as time-series with timestamps
- **PromQL**: Powerful functional query language for data analysis
- **Multi-dimensional data**: Metrics can have multiple labels for flexible querying
- **No dependencies**: Single binary with local storage
- **Service discovery**: Automatic discovery of monitoring targets

### When to Use Prometheus

Prometheus is ideal for:

- **Microservices Monitoring**: Track distributed system performance
- **Container Orchestration**: Monitor Kubernetes, Docker Swarm, and similar platforms
- **Infrastructure Monitoring**: System metrics, network performance, storage usage
- **Application Monitoring**: Custom metrics, business KPIs, performance indicators
- **Real-time Alerting**: Proactive notifications based on metric thresholds

## Data Model and Metric Types

### Data Model

Prometheus stores all data as time-series, identified by:

- **Metric name**: Describes the feature being measured
- **Labels**: Key-value pairs for multi-dimensional data
- **Timestamp**: When the measurement was taken
- **Value**: The numeric measurement

Example metric:

```text
http_requests_total{method="GET", handler="/api/users", status="200"} 1027
```

### Metric Types

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

## Key Features

### Monitoring Capabilities

- **Multi-dimensional Data Model**: Time series identified by metric name and labels
- **Flexible Query Language**: PromQL for querying and aggregating data
- **Pull-based Collection**: Scrapes targets over HTTP for metrics
- **Service Discovery**: Automatic discovery of monitoring targets
- **Efficient Storage**: Custom time-series database optimized for monitoring data

### Alerting and Notification

- **Alertmanager Integration**: Sophisticated alerting with routing and notification
- **Alert Rules**: Define conditions that trigger alerts
- **Notification Channels**: Email, Slack, PagerDuty, webhooks, and more
- **Alert Grouping**: Intelligent grouping and deduplication of alerts
- **Silencing**: Temporarily suppress alerts during maintenance

### Ecosystem Integration

- **Visualization**: Grafana integration for rich dashboards
- **Client Libraries**: SDKs for major programming languages
- **Exporters**: Third-party integrations for databases, systems, and services
- **Federation**: Hierarchical aggregation of metrics across multiple instances
- **Remote Storage**: Integration with long-term storage solutions

## Architecture

### Core Components

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │   Alertmanager  │    │     Grafana     │
│     Server      │◄──►│                 │    │   (Optional)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                        │                       ▲
         │                        ▼                       │
         │              ┌─────────────────┐               │
         │              │  Notification   │               │
         │              │   Channels      │               │
         │              │  (Email, Slack) │               │
         │              └─────────────────┘               │
         │                                                │
         ▼                                                │
┌─────────────────┐    ┌─────────────────┐               │
│    Targets      │    │    Exporters    │               │
│  (Applications, │    │   (Node, cAdvisor,│◄─────────────┘
│   Services)     │    │    MySQL, etc.)  │
└─────────────────┘    └─────────────────┘
```

#### Component Descriptions

**Prometheus Server**: The main component that scrapes and stores time-series data, and serves queries via PromQL.

**Client Libraries**: Libraries for instrumenting application code in various programming languages (Go, Java, Python, .NET, etc.).

**Pushgateway**: Allows ephemeral and batch jobs to push metrics to Prometheus.

**Exporters**: Third-party tools that export metrics from existing systems (databases, hardware, messaging systems, etc.).

**Alertmanager**: Handles alerts sent by Prometheus server and routes them to various notification channels.

### Prometheus Server Components

- **Retrieval**: Scrapes metrics from configured targets
- **Storage**: Time-series database for storing metrics
- **PromQL Engine**: Query language processor
- **Web UI**: Built-in expression browser and graph interface
- **API**: HTTP API for querying data and managing configuration

### Data Flow

1. **Service Discovery**: Identifies targets to monitor
2. **Scraping**: Pulls metrics from targets via HTTP
3. **Storage**: Stores time-series data locally
4. **Rule Evaluation**: Processes recording and alerting rules
5. **Alert Generation**: Sends alerts to Alertmanager
6. **Querying**: Serves queries via API or web interface

## Installation and Deployment

### Binary Installation

```bash
# Download and extract Prometheus binary
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# Run Prometheus with default configuration
./prometheus --config.file=prometheus.yml

# Run with custom configuration and storage options
./prometheus \
  --config.file=/path/to/prometheus.yml \
  --storage.tsdb.path=/path/to/data \
  --storage.tsdb.retention.time=30d \
  --web.enable-lifecycle
```

### Docker Container

```bash
# Basic Prometheus container
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest

# With additional configuration
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $(pwd)/alert_rules:/etc/prometheus/rules \
  -v prometheus-data:/prometheus \
  prom/prometheus:latest \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.console.templates=/etc/prometheus/consoles \
    --web.enable-lifecycle \
    --storage.tsdb.retention.time=30d
```

### Docker Compose

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alert_rules:/etc/prometheus/rules
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=10GB'
    networks:
      - monitoring
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /dev/disk:/dev/disk:ro
    networks:
      - monitoring
    restart: unless-stopped

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  prometheus-data:
  alertmanager-data:

networks:
  monitoring:
    driver: bridge
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--web.enable-lifecycle'
          - '--storage.tsdb.retention.time=30d'
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        - name: storage-volume
          mountPath: /prometheus
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
      - name: storage-volume
        persistentVolumeClaim:
          claimName: prometheus-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: LoadBalancer
```

### Helm Installation

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (includes Prometheus, Alertmanager, and Grafana)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set alertmanager.alertmanagerSpec.retention=120h

# Install standalone Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace \
  --set server.persistentVolume.size=50Gi \
  --set server.retention=30d
```

## Configuration

### Basic Configuration File

The main configuration file (`prometheus.yml`):

```yaml
global:
  # How frequently to scrape targets by default
  scrape_interval: 15s
  # How long until a scrape request times out
  scrape_timeout: 10s
  # How frequently to evaluate rules
  evaluation_interval: 15s
  # Attach labels to any time series or alerts when communicating with external systems
  external_labels:
    cluster: 'production'
    replica: '1'

# Rule files specify a list of globs
rule_files:
  - "alert_rules/*.yml"
  - "recording_rules/*.yml"

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
      scheme: http
      timeout: 10s
      api_version: v2

# Scrape configuration
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s
    metrics_path: /metrics

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s

  # cAdvisor for container metrics
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 15s

  # Application metrics
  - job_name: 'app-metrics'
    static_configs:
      - targets: ['app1:8080', 'app2:8080']
    metrics_path: /actuator/prometheus
    scrape_interval: 30s

# Remote write configuration (optional)
remote_write:
  - url: "https://remote-storage-endpoint/api/v1/write"
    basic_auth:
      username: "user"
      password: "password"
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'expensive_metric.*'
        action: drop
```

### Advanced Configuration Options

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  
  # Query log file
  query_log_file: /var/log/prometheus_queries.log
  
  # External labels for federation and remote storage
  external_labels:
    cluster: 'prod-cluster'
    region: 'us-west-2'
    environment: 'production'

# Recording rules for pre-computing expensive queries
rule_files:
  - "/etc/prometheus/rules/*.yml"

# Multiple Alertmanager instances for HA
alerting:
  alert_relabel_configs:
    - source_labels: [severity]
      target_label: priority
      regex: critical
      replacement: high
  alertmanagers:
    - static_configs:
        - targets: 
          - alertmanager-1:9093
          - alertmanager-2:9093
      timeout: 10s
      path_prefix: /alertmanager

# Federation configuration
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"prometheus"}'
        - '{__name__=~"up|instance:.*"}'
    static_configs:
      - targets:
        - 'prometheus-1:9090'
        - 'prometheus-2:9090'

  # Kubernetes service discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

## Service Discovery

### Static Configuration

```yaml
scrape_configs:
  - job_name: 'static-targets'
    static_configs:
      - targets: ['server1:9100', 'server2:9100']
        labels:
          environment: production
          team: infrastructure
      - targets: ['app1:8080', 'app2:8080']
        labels:
          environment: production
          team: backend
```

### File-based Service Discovery

```yaml
scrape_configs:
  - job_name: 'file-discovery'
    file_sd_configs:
      - files:
        - '/etc/prometheus/targets/*.json'
        - '/etc/prometheus/targets/*.yml'
        refresh_interval: 30s
```

Target file example (`/etc/prometheus/targets/web-servers.json`):

```json
[
  {
    "targets": ["web1:9100", "web2:9100", "web3:9100"],
    "labels": {
      "job": "web-servers",
      "environment": "production",
      "datacenter": "us-west-1"
    }
  },
  {
    "targets": ["db1:9100", "db2:9100"],
    "labels": {
      "job": "database-servers",
      "environment": "production",
      "datacenter": "us-west-1"
    }
  }
]
```

### Kubernetes Service Discovery

```yaml
scrape_configs:
  # Discover Kubernetes nodes
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # Discover Kubernetes pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

  # Discover Kubernetes services
  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: service
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

### Docker Service Discovery

```yaml
scrape_configs:
  - job_name: 'docker-containers'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 30s
    relabel_configs:
      - source_labels: [__meta_docker_container_label_prometheus_job]
        target_label: job
      - source_labels: [__meta_docker_container_name]
        target_label: container_name
      - source_labels: [__meta_docker_container_label_prometheus_port]
        target_label: __address__
        regex: (.+)
        replacement: ${1}
```

## PromQL Query Language

PromQL is a functional query language that allows you to select and aggregate time-series data in real-time. It's designed specifically for monitoring use cases.

### Basic Queries

```promql
# Simple metric selection
http_requests_total

# Filter by labels
http_requests_total{method="GET"}

# Multiple label filters
http_requests_total{method="GET", status="200"}

# Regular expression matching
http_requests_total{handler=~"/api/.*"}

# Negative matching  
http_requests_total{status!="200"}

# Time range selection
cpu_usage_seconds_total[5m]
```

### Rate and Range Queries

```promql
# Rate of requests per second over 5 minutes
rate(http_requests_total[5m])

# Average CPU usage over 10 minutes
avg_over_time(cpu_usage_percent[10m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Increase function (total increase over time range)
increase(http_requests_total[1h])

# Delta function (difference between first and last values)
delta(memory_usage_bytes[10m])
```

### Time Series Functions

```promql
# Rate function (per-second rate)
rate(cpu_usage_seconds_total[5m])

# Average CPU usage over 10 minutes
avg_over_time(cpu_usage_percent[10m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Increase function (total increase over time range)
increase(http_requests_total[1h])

# Delta function (difference between first and last values)
delta(memory_usage_bytes[10m])

# Derivative function (per-second derivative)
deriv(disk_usage_bytes[5m])
```

```promql
# Rate function (per-second rate)
rate(cpu_usage_seconds_total[5m])

# Increase function (total increase over time range)
increase(http_requests_total[1h])

# Delta function (difference between first and last values)
delta(memory_usage_bytes[10m])

# Derivative function (per-second derivative)
deriv(disk_usage_bytes[5m])
```

### Aggregation Functions

```promql
# Sum across all series
sum(rate(http_requests_total[5m]))

# Sum by specific labels
sum by (job) (rate(http_requests_total[5m]))

# Average CPU usage per instance
avg by (instance) (rate(cpu_usage_seconds_total[5m]))

# Maximum memory usage
max(memory_usage_bytes)

# Count number of instances
count(up == 1)

# Top 5 instances by CPU usage
topk(5, rate(cpu_usage_seconds_total[5m]))

# Bottom 3 instances by memory
bottomk(3, memory_available_bytes)
```

### Mathematical Operations

```promql
# Calculate CPU utilization percentage
100 - (avg by (instance) (rate(cpu_usage_seconds_total{mode="idle"}[5m])) * 100)

# Memory utilization percentage
(1 - (memory_available_bytes / memory_total_bytes)) * 100

# Network bandwidth utilization
rate(network_receive_bytes_total[5m]) + rate(network_transmit_bytes_total[5m])

# Disk space usage percentage
(1 - (filesystem_free_bytes / filesystem_size_bytes)) * 100
```

### Advanced PromQL Examples

```promql
# Service availability over time
avg_over_time(up[1h])

# 99th percentile response time
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Error rate percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# Predict disk full time (linear regression)
predict_linear(filesystem_free_bytes[1h], 3600 * 24)

# Alert if service is down for more than 5 minutes
absent_over_time(up[5m])

# Container CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])

# Memory pressure detection
(container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
```

## Alerting

### Alert Rules Configuration

Create alert rules file (`/etc/prometheus/rules/alerts.yml`):

```yaml
groups:
  - name: infrastructure.rules
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."
          runbook_url: "https://runbooks.example.com/InstanceDown"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% on {{ $labels.instance }} for more than 10 minutes."
          current_value: "{{ $value }}%"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% on {{ $labels.instance }}."
          current_value: "{{ $value }}%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 5m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Low disk space"
          description: "Disk space is below 10% on {{ $labels.instance }}."
          current_value: "{{ $value }}%"

  - name: application.rules
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5% for {{ $labels.job }} service."
          current_value: "{{ $value }}%"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 10m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High response time"
          description: "95th percentile response time is above 2 seconds for {{ $labels.job }}."
          current_value: "{{ $value }}s"

      - alert: ServiceUnavailable
        expr: absent(up{job="critical-service"})
        for: 1m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "Critical service is not available"
          description: "The critical-service job is not reporting any metrics."
```

### Alertmanager Configuration

Create Alertmanager configuration (`alertmanager.yml`):

```yaml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'password'

# Template files
templates:
  - '/etc/alertmanager/templates/*.tmpl'

# Route tree
route:
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    # Critical alerts go to PagerDuty and Slack
    - match:
        severity: critical
      receiver: 'critical-alerts'
      continue: true
    
    # Infrastructure team alerts
    - match:
        team: infrastructure
      receiver: 'infrastructure-team'
    
    # Backend team alerts
    - match:
        team: backend
      receiver: 'backend-team'
    
    # Maintenance window silencing
    - match:
        alertname: 'MaintenanceMode'
      receiver: 'null'

# Inhibit rules
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

# Notification receivers
receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@example.com'
        subject: 'Prometheus Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          Severity: {{ .Labels.severity }}
          {{ end }}

  - name: 'critical-alerts'
    pagerduty_configs:
      - service_key: 'your-pagerduty-service-key'
        description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#critical-alerts'
        title: 'Critical Alert: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Instance:* {{ .Labels.instance }}
          *Severity:* {{ .Labels.severity }}
          {{ end }}

  - name: 'infrastructure-team'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#infrastructure'
        username: 'Prometheus'
        title: 'Infrastructure Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: 'backend-team'
    email_configs:
      - to: 'backend-team@example.com'
        subject: 'Backend Service Alert'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#backend-alerts'

  - name: 'null'
    # Silent receiver for maintenance windows
```

## Storage

### Local Storage Configuration

```yaml
# Prometheus startup flags for storage configuration
command:
  - '--storage.tsdb.path=/prometheus'
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=50GB'
  - '--storage.tsdb.min-block-duration=2h'
  - '--storage.tsdb.max-block-duration=36h'
  - '--storage.tsdb.wal-compression'
```

### Remote Storage Integration

```yaml
# Remote write configuration
remote_write:
  - url: "https://cortex.example.com/api/prom/push"
    basic_auth:
      username: "user"
      password: "password"
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'expensive_metric_.*'
        action: drop
    queue_config:
      capacity: 10000
      max_shards: 200
      min_shards: 1
      max_samples_per_send: 5000
      batch_send_deadline: 5s

# Remote read configuration
remote_read:
  - url: "https://cortex.example.com/api/prom/read"
    basic_auth:
      username: "user"
      password: "password"
    read_recent: true
```

### Storage Optimization

```yaml
# Recording rules for pre-aggregation
groups:
  - name: recording.rules
    interval: 30s
    rules:
      # Pre-calculate CPU usage
      - record: instance:cpu_usage:rate5m
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
      
      # Pre-calculate memory usage
      - record: instance:memory_usage:percentage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
      
      # Pre-calculate disk usage
      - record: instance:disk_usage:percentage
        expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100
      
      # Application-specific recording rules
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      
      - record: job:http_request_duration:p95
        expr: histogram_quantile(0.95, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))
```

## Security

### Basic Authentication

```yaml
# Enable basic authentication
global:
  # Basic auth for scraping
  scrape_configs:
    - job_name: 'secure-app'
      static_configs:
        - targets: ['app:8080']
      basic_auth:
        username: 'prometheus'
        password: 'secure_password'
      scheme: https
      tls_config:
        ca_file: /etc/prometheus/ca.pem
        cert_file: /etc/prometheus/prometheus.pem
        key_file: /etc/prometheus/prometheus-key.pem
        insecure_skip_verify: false
```

### TLS Configuration

```yaml
# TLS configuration for secure communication
global:
  scrape_configs:
    - job_name: 'tls-enabled-service'
      static_configs:
        - targets: ['secure-service:8443']
      scheme: https
      tls_config:
        ca_file: /etc/prometheus/certs/ca.crt
        cert_file: /etc/prometheus/certs/prometheus.crt
        key_file: /etc/prometheus/certs/prometheus.key
        server_name: secure-service.example.com
        insecure_skip_verify: false
```

### Network Security

```yaml
# Network policies for Kubernetes
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-network-policy
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    - podSelector:
        matchLabels:
          app: grafana
    ports:
    - protocol: TCP
      port: 9090
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 9100  # Node exporter
    - protocol: TCP
      port: 8080  # cAdvisor
```

### RBAC Configuration

```yaml
# ServiceAccount for Prometheus
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
# ClusterRole with necessary permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
```

## Container Monitoring

### Docker Container Metrics

Key metrics for container monitoring:

```promql
# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory usage
container_memory_usage_bytes

# Container memory limit
container_spec_memory_limit_bytes

# Memory utilization percentage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# Network I/O
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])

# Disk I/O
rate(container_fs_reads_bytes_total[5m])
rate(container_fs_writes_bytes_total[5m])

# Container restart count
increase(container_restart_count[1h])
```

### Kubernetes Monitoring

```promql
# Pod CPU usage
sum by (pod) (rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m]))

# Pod memory usage
sum by (pod) (container_memory_usage_bytes{container!="POD",container!=""})

# Node resource utilization
(1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100

# Cluster capacity
sum(node_memory_MemTotal_bytes) / 1024 / 1024 / 1024

# Pod status
kube_pod_status_phase{phase!="Running"}

# Deployment replica status
kube_deployment_status_replicas_available / kube_deployment_spec_replicas

# Persistent volume usage
(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100
```

### Application Instrumentation

Example Go application with Prometheus metrics:

```go
package main

import (
    "net/http"
    "time"
    
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "The total number of processed HTTP requests",
        },
        []string{"method", "endpoint", "status_code"},
    )
    
    httpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "The HTTP request latencies in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
    
    activeConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_connections",
            Help: "The current number of active connections",
        },
    )
)

func instrumentHandler(endpoint string, handler http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        activeConnections.Inc()
        defer activeConnections.Dec()
        
        handler(w, r)
        
        duration := time.Since(start).Seconds()
        httpRequestDuration.WithLabelValues(r.Method, endpoint).Observe(duration)
        httpRequestsTotal.WithLabelValues(r.Method, endpoint, "200").Inc()
    }
}

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.HandleFunc("/", instrumentHandler("/", homeHandler))
    http.HandleFunc("/api/health", instrumentHandler("/api/health", healthHandler))
    
    http.ListenAndServe(":8080", nil)
}
```

## Best Practices

### Configuration Management

1. **Version Control**: Store all configuration files in version control
2. **Environment Separation**: Use different configurations for different environments
3. **Validation**: Validate configuration syntax before deployment
4. **Documentation**: Document custom metrics and alert rules
5. **Standardization**: Use consistent naming conventions and labels

### Metric Design

1. **Naming Conventions**: Use clear, consistent metric names
2. **Label Usage**: Use labels wisely - avoid high cardinality
3. **Metric Types**: Choose appropriate metric types (counter, gauge, histogram, summary)
4. **Documentation**: Include help text for all custom metrics
5. **Aggregation**: Design metrics for efficient aggregation

### Query Optimization

```promql
# Good: Efficient query with specific labels
rate(http_requests_total{job="api", method="GET"}[5m])

# Avoid: High cardinality queries
rate(http_requests_total{user_id=~".*"}[5m])

# Good: Use recording rules for expensive queries
instance:cpu_usage:rate5m

# Avoid: Complex calculations in dashboards
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Alert Design

1. **Clear Criteria**: Define specific, actionable alert conditions
2. **Appropriate Thresholds**: Set realistic thresholds based on historical data
3. **Timing**: Use appropriate `for` clauses to avoid flapping
4. **Context**: Include relevant context in alert annotations
5. **Escalation**: Design multi-level alert escalation

### Storage Management

1. **Retention Policies**: Set appropriate retention based on requirements
2. **Disk Space**: Monitor disk usage and set size limits
3. **Backup Strategy**: Implement regular backup procedures
4. **Compaction**: Understand TSDB compaction behavior
5. **Remote Storage**: Consider remote storage for long-term retention

### High Availability

```yaml
# Prometheus HA setup with shared storage
version: '3.8'
services:
  prometheus-1:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
      - '--web.external-url=http://prometheus-1:9090'
      - '--storage.tsdb.min-block-duration=2h'
      - '--storage.tsdb.max-block-duration=36h'
    external_labels:
      replica: '1'
      cluster: 'production'

  prometheus-2:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
      - '--web.external-url=http://prometheus-2:9090'
      - '--storage.tsdb.min-block-duration=2h'
      - '--storage.tsdb.max-block-duration=36h'
    external_labels:
      replica: '2'
      cluster: 'production'
```

## Troubleshooting

### Common Issues

#### Target Discovery Issues

```bash
# Check service discovery
curl http://prometheus:9090/api/v1/targets

# Verify DNS resolution
nslookup target-service

# Test connectivity
telnet target-service 9100

# Check logs
docker logs prometheus 2>&1 | grep -i "discovery\|scrape"
```

#### Query Performance

```bash
# Enable query logging
--query.log-file=/var/log/prometheus_queries.log

# Monitor query performance
tail -f /var/log/prometheus_queries.log | grep -E "took|ms"

# Check for expensive queries
curl "http://prometheus:9090/api/v1/query?query=topk(10,count by (__name__)({__name__=~\".+\"}))"
```

#### Storage Issues

```bash
# Check TSDB stats
curl http://prometheus:9090/api/v1/status/tsdb

# Monitor disk usage
df -h /prometheus

# Check WAL status
ls -la /prometheus/wal/

# Verify block integrity
promtool tsdb analyze /prometheus
```

#### Memory Issues

```bash
# Monitor memory usage
ps aux | grep prometheus

# Check for memory leaks
curl http://prometheus:9090/debug/pprof/heap

# Optimize memory usage
--storage.tsdb.head-chunks-write-queue-size=10000
--query.max-concurrency=20
--query.max-samples=50000000
```

### Debugging Tools

```bash
# Validate configuration
promtool check config prometheus.yml

# Check rules syntax
promtool check rules /etc/prometheus/rules/*.yml

# Query Prometheus API
curl "http://prometheus:9090/api/v1/query?query=up"

# Test alerts
curl "http://prometheus:9090/api/v1/alerts"

# Check metrics metadata
curl "http://prometheus:9090/api/v1/metadata"
```

### Log Analysis

```bash
# Important log patterns
tail -f /var/log/prometheus.log | grep -E "(error|Error|ERROR)"
tail -f /var/log/prometheus.log | grep -E "(scrape|discovery)"
tail -f /var/log/prometheus.log | grep -E "(rule|alert)"
tail -f /var/log/prometheus.log | grep -E "(storage|tsdb)"
```

## Resources

### Official Documentation

- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Configuration Reference](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

### Container Resources

- [Prometheus Docker Images](https://hub.docker.com/u/prom)
- [Helm Charts](https://github.com/prometheus-community/helm-charts)
- [Kubernetes Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Docker Compose Examples](https://github.com/vegasbrianc/prometheus)

### Client Libraries

- [Go Client](https://github.com/prometheus/client_golang)
- [Java Client](https://github.com/prometheus/client_java)
- [Python Client](https://github.com/prometheus/client_python)
- [Node.js Client](https://github.com/siimon/prom-client)

### Exporters

- [Node Exporter](https://github.com/prometheus/node_exporter) - Hardware and OS metrics
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) - HTTP, DNS, TCP probing
- [MySQL Exporter](https://github.com/prometheus/mysqld_exporter) - MySQL metrics
- [PostgreSQL Exporter](https://github.com/prometheus-community/postgres_exporter) - PostgreSQL metrics
- [Redis Exporter](https://github.com/oliver006/redis_exporter) - Redis metrics
- [NGINX Exporter](https://github.com/nginxinc/nginx-prometheus-exporter) - NGINX metrics

### Community Resources

- [Prometheus Community](https://prometheus.io/community/)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [PromCon Talks](https://promcon.io/talks/)
- [Monitoring Mixins](https://monitoring.mixins.dev/)

### Tutorials and Guides

- [Getting Started Guide](https://prometheus.io/docs/prometheus/latest/getting_started/)
- [Best Practices](https://prometheus.io/docs/practices/naming/)
- [Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Alerting Rules Examples](https://awesome-prometheus-alerts.grep.to/)

## Application Monitoring

Instrument your applications to expose custom metrics for comprehensive monitoring.

### Go Application Example

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
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "Duration of HTTP requests in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
    prometheus.MustRegister(httpRequestDuration)
}

func instrumentedHandler(w http.ResponseWriter, r *http.Request) {
    timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues(r.Method, r.URL.Path))
    defer timer.ObserveDuration()
    
    // Your application logic here
    w.WriteHeader(http.StatusOK)
    
    httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.HandleFunc("/", instrumentedHandler)
    http.ListenAndServe(":8080", nil)
}
```

### Key Application Metrics

- **Request rate**: `http_requests_total`
- **Request duration**: `http_request_duration_seconds`
- **Active connections**: `active_connections`
- **Queue depth**: `queue_depth`
- **Business metrics**: Custom counters/gauges for domain-specific events

## Integration with Grafana

> [!IMPORTANT]
> While Prometheus provides basic graphing capabilities, Grafana is the preferred tool for creating rich, interactive dashboards.

### Setting up Grafana with Prometheus

```bash
# Run Grafana with Docker
docker run -d -p 3000:3000 --name grafana grafana/grafana

# Or with Docker Compose
version: '3'
services:
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

### Adding Prometheus as Data Source

1. Access Grafana at `http://localhost:3000` (admin/admin)
2. Go to **Configuration → Data Sources**
3. Click **Add data source** and select **Prometheus**
4. Set URL to `http://prometheus:9090` (or your Prometheus URL)
5. Click **Save & Test**

### Sample Dashboard Queries

```promql
# CPU Usage Panel
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage Panel
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Request Rate Panel
rate(http_requests_total[5m])

# Response Time Percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))
```

## Advanced Monitoring Patterns

### Recording Rules for Performance

```yaml
# /etc/prometheus/rules/recording.yml
groups:
  - name: performance_rules
    interval: 30s
    rules:
      - record: node:cpu_utilization:rate5m
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
      
      - record: node:memory_utilization:ratio
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
      
      - record: instance:request_rate:rate5m
        expr: rate(http_requests_total[5m])
```

### Metric Naming Best Practices

> [!TIP]
> Follow Prometheus naming conventions for consistency and clarity across your monitoring infrastructure.

**Naming Guidelines:**

- Use snake_case: `http_requests_total`
- Include units in the name: `process_cpu_seconds_total`
- Use descriptive, unambiguous names: `database_connection_pool_size`
- End counters with `_total`: `api_requests_total`
- End gauges with descriptive units: `memory_usage_bytes`

**Examples:**

```promql
# Good naming
http_requests_total{method="GET", status="200"}
database_connections_active
memory_usage_bytes
disk_write_bytes_total

# Avoid these patterns
requests  # Too generic, missing _total
db_conn   # Abbreviated, unclear
mem       # Too short, no units
```

### Monitoring Prometheus Self-Health

Essential self-monitoring queries:

```promql
# Prometheus health
prometheus_config_last_reload_successful
prometheus_tsdb_reloads_total
prometheus_build_info

# Performance metrics
rate(prometheus_http_requests_total[5m])
prometheus_tsdb_head_samples_appended_total
prometheus_tsdb_compaction_duration_seconds

# Storage metrics
prometheus_tsdb_symbol_table_size_bytes
prometheus_tsdb_head_series
prometheus_tsdb_retention_limit_bytes
```

## Related Resources

- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [PromQL Tutorial and Examples](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Exporters Directory](https://prometheus.io/docs/instrumenting/exporters/)
- [Prometheus Operator for Kubernetes](https://github.com/prometheus-operator/prometheus-operator)
- [Awesome Prometheus Alerts](https://awesome-prometheus-alerts.grep.to/)
- [Prometheus Best Practices Guide](https://prometheus.io/docs/practices/naming/)
