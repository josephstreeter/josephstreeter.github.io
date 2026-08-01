---
title: "Loki"
description: "Comprehensive guide to Grafana Loki for log aggregation, analysis, and observability in containerized environments"
category: "infrastructure"
tags: ["containers", "logging", "loki", "grafana", "observability", "log-aggregation", "promtail"]
---

## Loki

Grafana Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus. Unlike traditional logging systems that index the full text of log lines, Loki only indexes metadata (labels) about logs, making it extremely cost-effective and performant for storing and querying large volumes of log data.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Installation and Deployment](#installation-and-deployment)
- [Configuration](#configuration)
- [Log Shipping with Promtail](#log-shipping-with-promtail)
- [LogQL Query Language](#logql-query-language)
- [Grafana Integration](#grafana-integration)
- [Storage](#storage)
- [Security](#security)
- [Container Log Collection](#container-log-collection)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

Loki takes a different approach to logging compared to traditional systems like Elasticsearch. Instead of indexing log content, it only indexes labels (metadata) and keeps logs compressed and unindexed. This design provides several advantages, especially in containerized environments where log volumes can be massive.

### Core Concepts

- **Labels**: Key-value pairs that identify log streams (similar to Prometheus labels)
- **Log Streams**: A sequence of log entries with the same set of labels
- **Log Entries**: Individual log lines with timestamps
- **Chunks**: Compressed groups of log entries stored in object storage
- **Index**: Stores label information and references to chunks

### Design Philosophy

Loki follows these principles:

- **Labels, not full-text indexing**: Only index metadata for cost efficiency
- **Prometheus-compatible**: Use the same service discovery and labeling
- **Multi-tenancy**: Support multiple isolated tenants in a single deployment
- **Cloud-native**: Designed for containerized, distributed deployments
- **Cost-effective**: Significantly lower storage and operational costs

### When to Use Loki

Loki is ideal for:

- **Kubernetes Log Aggregation**: Centralized logging for container orchestration
- **Microservices Logging**: Distributed application log collection
- **Cost-sensitive Environments**: Where traditional logging solutions are too expensive
- **Prometheus Integration**: When you want unified observability with metrics
- **Multi-tenant Scenarios**: Shared logging infrastructure with tenant isolation

## Key Features

### Efficient Storage and Indexing

- **Label-based Indexing**: Only indexes labels, not log content
- **Compressed Storage**: Logs stored compressed in object storage
- **Chunk-based Architecture**: Efficient compression and querying
- **Horizontal Scaling**: Scale components independently
- **Cost Optimization**: Dramatically lower storage costs than traditional solutions

### Querying and Analysis

- **LogQL**: Powerful query language similar to PromQL
- **Label Filtering**: Fast filtering based on indexed labels
- **Log Stream Processing**: Aggregate and analyze log streams
- **Regular Expression Support**: Pattern matching within log lines
- **Metrics Extraction**: Generate metrics from log data

### Integration and Compatibility

- **Grafana Native**: Deep integration with Grafana dashboards
- **Prometheus Service Discovery**: Reuse existing Prometheus configuration
- **Cloud Storage**: Support for S3, GCS, Azure Blob, and more
- **Alerting**: Integration with Grafana alerting and Prometheus Alertmanager
- **Multi-tenant**: Built-in support for tenant isolation

## Architecture

### Component Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Loki Cluster                             │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Distributor   │    Ingester     │        Querier              │
│                 │                 │                             │
│ • Validates     │ • Builds chunks │ • Handles queries           │
│   logs          │ • Writes to     │ • Fetches data from         │
│ • Applies rate  │   storage       │   ingesters and storage     │
│   limiting      │ • Indexes       │ • Merges results            │
│ • Forwards to   │   labels        │                             │
│   ingesters     │                 │                             │
└─────────────────┴─────────────────┴─────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Storage Layer                                │
├─────────────────────────┬───────────────────────────────────────┤
│      Index Store        │           Object Store                │
│                         │                                       │
│ • Stores label indexes  │ • Stores compressed log chunks        │
│ • DynamoDB, Cassandra,  │ • S3, GCS, Azure Blob Storage,        │
│   BoltDB, etc.          │   Filesystem                          │
│                         │                                       │
└─────────────────────────┴───────────────────────────────────────┘
                           ▲
                           │
┌─────────────────────────────────────────────────────────────────┐
│                    Log Shippers                                 │
├─────────────────┬─────────────────┬─────────────────────────────┤
│    Promtail     │   Fluent Bit    │       Other Agents          │
│                 │                 │                             │
│ • Grafana's     │ • Lightweight   │ • Fluentd                   │
│   agent         │   shipper       │ • Vector                    │
│ • Service       │ • Plugin-based  │ • Filebeat                  │
│   discovery     │   configuration │ • Custom applications       │
│ • Log parsing   │                 │                             │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

### Data Flow

1. **Log Collection**: Promtail or other agents collect logs from applications
2. **Processing**: Agents apply labels, parse logs, and format for shipping
3. **Distribution**: Logs sent to Loki distributors
4. **Ingestion**: Distributors forward logs to ingesters
5. **Storage**: Ingesters build chunks and store in object storage
6. **Indexing**: Label information stored in index store
7. **Querying**: Queriers retrieve data for LogQL queries
8. **Visualization**: Grafana displays logs and derived metrics

### Deployment Models

#### Monolithic Mode

Single binary running all components - suitable for small deployments.

#### Microservices Mode

Each component runs separately - suitable for large, scalable deployments.

#### Simple Scalable Mode

Separates read and write paths - balance between simplicity and scalability.

## Installation and Deployment

### Docker Container

```bash
# Basic Loki container
docker run -d \
  --name loki \
  -p 3100:3100 \
  -v $(pwd)/loki-config.yaml:/etc/loki/local-config.yaml \
  grafana/loki:latest

# With custom configuration
docker run -d \
  --name loki \
  -p 3100:3100 \
  -v $(pwd)/loki-config.yaml:/etc/loki/local-config.yaml \
  -v loki-data:/loki \
  grafana/loki:latest \
  -config.file=/etc/loki/local-config.yaml
```

### Docker Compose

Complete logging stack with Loki, Promtail, and Grafana:

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yaml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - logging
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail/promtail-config.yaml:/etc/promtail/config.yml
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/config.yml
    networks:
      - logging
    restart: unless-stopped
    depends_on:
      - loki

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    networks:
      - logging
    restart: unless-stopped
    depends_on:
      - loki

  # Example application that generates logs
  log-generator:
    image: mingrammer/flog
    container_name: log-generator
    command: 
      - -f
      - apache_common
      - -o
      - /var/log/generated.log
      - -t
      - log
      - -w
    volumes:
      - ./logs:/var/log
    networks:
      - logging
    restart: unless-stopped

volumes:
  loki-data:
  grafana-data:

networks:
  logging:
    driver: bridge
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: grafana/loki:latest
        ports:
        - containerPort: 3100
          name: http
        args:
          - -config.file=/etc/loki/local-config.yaml
        volumeMounts:
        - name: config
          mountPath: /etc/loki
        - name: storage
          mountPath: /loki
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /ready
            port: 3100
          initialDelaySeconds: 45
        readinessProbe:
          httpGet:
            path: /ready
            port: 3100
          initialDelaySeconds: 45
      volumes:
      - name: config
        configMap:
          name: loki-config
      - name: storage
        persistentVolumeClaim:
          claimName: loki-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: loki-service
  namespace: logging
spec:
  selector:
    app: loki
  ports:
  - port: 3100
    targetPort: 3100
  type: ClusterIP
```

### Helm Installation

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
helm install loki grafana/loki-stack \
  --namespace logging \
  --create-namespace \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=100Gi \
  --set promtail.enabled=true \
  --set grafana.enabled=true \
  --set grafana.adminPassword=your-secure-password

# Install Loki with custom values
helm install loki grafana/loki-stack \
  --namespace logging \
  --create-namespace \
  --values loki-values.yaml
```

Custom values file (`loki-values.yaml`):

```yaml
loki:
  enabled: true
  persistence:
    enabled: true
    storageClassName: fast-ssd
    size: 100Gi
  config:
    auth_enabled: false
    server:
      http_listen_port: 3100
    ingester:
      lifecycler:
        address: 127.0.0.1
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
      chunk_idle_period: 3m
      chunk_retain_period: 1m
    schema_config:
      configs:
      - from: 2020-10-24
        store: boltdb-shipper
        object_store: filesystem
        schema: v11
        index:
          prefix: index_
          period: 24h

promtail:
  enabled: true
  config:
    logLevel: info
    serverPort: 3101
    clients:
      - url: http://loki:3100/loki/api/v1/push

grafana:
  enabled: true
  adminUser: admin
  adminPassword: your-secure-password
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki:3100
        isDefault: true
```

## Configuration

### Basic Loki Configuration

Create `loki-config.yaml`:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://alertmanager:9093

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/usagestats/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false
```

### Production Configuration

```yaml
auth_enabled: true

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: info

distributor:
  ring:
    kvstore:
      store: consul
      consul:
        host: consul:8500

ingester:
  ring:
    kvstore:
      store: consul
      consul:
        host: consul:8500
    replication_factor: 3
  lifecycler:
    heartbeat_period: 5s
    join_after: 10s
    min_ready_duration: 10s
    final_sleep: 0s
  chunk_idle_period: 1m
  chunk_retain_period: 30s
  max_transfer_retries: 0
  wal:
    enabled: true
    dir: /loki/wal

schema_config:
  configs:
    - from: 2020-10-24
      store: aws
      object_store: s3
      schema: v11
      index:
        prefix: loki_index_
        period: 24h

storage_config:
  aws:
    s3: s3://us-west-2/my-loki-bucket
    dynamodb:
      dynamodb_url: dynamodb://us-west-2
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    shared_store: s3
    cache_location: /loki/boltdb-shipper-cache

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 4
  ingestion_burst_size_mb: 6
  per_stream_rate_limit: 3MB
  per_stream_rate_limit_burst: 15MB
  max_streams_per_user: 10000
  max_line_size: 256000

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 2160h  # 90 days

ruler:
  storage:
    type: local
    local:
      directory: /loki/rules
  rule_path: /loki/rules
  alertmanager_url: http://alertmanager:9093
  ring:
    kvstore:
      store: consul
      consul:
        host: consul:8500
  enable_api: true

frontend:
  compress_responses: true
  max_outstanding_per_tenant: 256

query_range:
  align_queries_with_step: true
  max_retries: 5
  split_queries_by_interval: 30m
  cache_results: true
  results_cache:
    cache:
      redis_cache:
        endpoint: redis:6379
```

### Multi-tenant Configuration

```yaml
auth_enabled: true

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

limits_config:
  # Per-tenant limits
  per_tenant_override_config: /etc/loki/overrides.yaml
  ingestion_rate_mb: 4
  ingestion_burst_size_mb: 6
  max_streams_per_user: 10000
  max_line_size: 256000
  reject_old_samples: true
  reject_old_samples_max_age: 168h

# Tenant overrides file (overrides.yaml)
overrides:
  "tenant-a":
    ingestion_rate_mb: 8
    max_streams_per_user: 20000
  "tenant-b":
    ingestion_rate_mb: 2
    max_streams_per_user: 5000
```

## Log Shipping with Promtail

### Basic Promtail Configuration

Create `promtail-config.yaml`:

```yaml
server:
  http_listen_port: 3101
  grpc_listen_port: 9096

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*log

  # Parse JSON logs
  - job_name: json-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: json-app
          __path__: /var/log/app.json
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            timestamp: timestamp
      - timestamp:
          source: timestamp
          format: RFC3339
      - labels:
          level:
```

### Advanced Promtail Configuration

```yaml
server:
  http_listen_port: 3101
  grpc_listen_port: 9096
  log_level: info

positions:
  filename: /tmp/positions.yaml
  sync_period: 10s

clients:
  - url: http://loki:3100/loki/api/v1/push
    batchwait: 1s
    batchsize: 1048576
    
    # Authentication for multi-tenant setup
    tenant_id: my-tenant
    
    # External labels applied to all logs
    external_labels:
      cluster: production
      region: us-west-2

scrape_configs:
  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          __path__: /var/log/syslog
          
  # Application logs with parsing
  - job_name: webapp
    static_configs:
      - targets:
          - localhost
        labels:
          job: webapp
          __path__: /var/log/webapp/*.log
    pipeline_stages:
      # Parse Apache Common Log Format
      - regex:
          expression: '(?P<ip>\S+) \S+ \S+ \[(?P<timestamp>[\w:/]+\s[+\-]\d{4})\] "(?P<method>\S+) (?P<url>\S+) (?P<protocol>\S+)" (?P<status>\d{3}) (?P<size>\d+)'
      - timestamp:
          source: timestamp
          format: 02/Jan/2006:15:04:05 -0700
      - labels:
          method:
          status:
      - output:
          source: url

  # Container logs with service discovery
  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: 'container_name'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'
    pipeline_stages:
      - cri: {}
      - json:
          expressions:
            level: level
            message: message
            service: service
      - labels:
          level:
          service:

  # Kubernetes logs
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape
        action: keep
        regex: true
      - source_labels:
          - __meta_kubernetes_pod_container_name
        target_label: container_name
      - source_labels:
          - __meta_kubernetes_pod_name
        target_label: pod_name
      - source_labels:
          - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
          - __meta_kubernetes_pod_label_app
        target_label: app
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
          - __meta_kubernetes_pod_uid
          - __meta_kubernetes_pod_container_name
        target_label: __path__
    pipeline_stages:
      - cri: {}

  # Nginx access logs
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/access.log
    pipeline_stages:
      - regex:
          expression: '(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[\w:/]+\s[+\-]\d{4})\] "(?P<method>\S+) (?P<request>\S+) (?P<protocol>\S+)" (?P<status>\d{3}) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"'
      - timestamp:
          source: time_local
          format: 02/Jan/2006:15:04:05 -0700
      - labels:
          method:
          status:
      - metrics:
          nginx_requests_total:
            type: Counter
            description: "Total number of nginx requests"
            config:
              match_all: true
              count_entry_bytes: false
          nginx_request_size_bytes:
            type: Histogram
            description: "Size of nginx requests"
            config:
              buckets: [10, 100, 1000, 10000, 100000]
              value: body_bytes_sent
```

### Promtail Docker Configuration

For containerized Promtail collecting Docker logs:

```yaml
scrape_configs:
  - job_name: flog_scrape
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
        filters:
          - name: label
            values: ["logging=promtail"]
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container_name'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_logging_jobname']
        target_label: 'job'
    pipeline_stages:
      - json:
          expressions:
            level: level
            timestamp: timestamp
            message: message
      - timestamp:
          source: timestamp
          format: RFC3339Nano
      - labels:
          level:
```

## LogQL Query Language

### Basic Queries

```logql
# Select all logs for a job
{job="webapp"}

# Select logs with multiple label filters
{job="webapp", level="error"}

# Regular expression matching
{job=~"webapp|api"}

# Negative matching  
{job!="system"}

# Line filtering
{job="webapp"} |= "error"

# Regex line filtering
{job="webapp"} |~ "error|Error|ERROR"

# Negative line filtering
{job="webapp"} != "debug"

# Case-insensitive search
{job="webapp"} |~ "(?i)error"
```

### Log Stream Processing

```logql
# Extract JSON fields
{job="webapp"} | json

# Extract specific JSON field
{job="webapp"} | json level="level", message="message"

# Extract using regex
{job="webapp"} | regexp "level=(?P<level>\\w+)"

# Parse logfmt format
{job="webapp"} | logfmt

# Line formatting
{job="webapp"} | line_format "{{.timestamp}} [{{.level}}] {{.message}}"

# Label formatting
{job="webapp"} | label_format level="{{.level | upper}}"
```

### Aggregation Functions

```logql
# Count log lines
count_over_time({job="webapp"}[5m])

# Rate of log lines
rate({job="webapp"}[5m])

# Count by level
sum by (level) (count_over_time({job="webapp"}[5m]))

# Error rate
sum(rate({job="webapp", level="error"}[5m])) /
sum(rate({job="webapp"}[5m]))

# Bytes rate
bytes_rate({job="webapp"}[5m])

# Bytes over time
bytes_over_time({job="webapp"}[5m])
```

### Metric Queries

```logql
# Top 10 error messages
topk(10, 
  sum by (message) (
    count_over_time({job="webapp", level="error"}[1h])
  )
)

# Request duration histogram
histogram_quantile(0.95,
  sum by (le) (
    rate({job="webapp"} | json | duration < 100 [5m])
  )
)

# Average response time extracted from logs
avg_over_time(
  {job="webapp"} 
  | json 
  | unwrap duration [5m]
)

# Standard deviation of response times  
stddev_over_time(
  {job="webapp"} 
  | json 
  | unwrap duration [5m]
)
```

### Advanced LogQL Examples

```logql
# Multi-line log parsing
{job="java-app"} |= "Exception" 
| pattern "<timestamp> <level> [<thread>] <logger>: <message>"
| line_format "{{.timestamp}} {{.level}} {{.message}}"

# Extract metrics from nginx logs
{job="nginx"} 
| pattern '<ip> - - [<timestamp>] "<method> <path> <protocol>" <status> <size>'
| status >= 400
| line_format "{{.method}} {{.path}} returned {{.status}}"

# Complex filtering and aggregation
sum by (pod) (
  count_over_time(
    {namespace="production", container="app"}
    |= "ERROR" 
    | json 
    | level="ERROR" [5m]
  )
) > 10

# Log-based alerting query
(
  sum by (service) (
    rate({job=~"webapp|api", level="error"}[5m])
  ) / 
  sum by (service) (
    rate({job=~"webapp|api"}[5m])  
  )
) > 0.01
```

## Grafana Integration

### Data Source Configuration

Configure Loki as a data source in Grafana:

```yaml
# Grafana provisioning datasource config
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: true
    editable: false
    jsonData:
      maxLines: 1000
      derivedFields:
        - name: "TraceID"
          matcherRegex: "trace_id=(\\w+)"
          url: "http://jaeger:16686/trace/$${__value.raw}"
        - name: "UserID"  
          matcherRegex: "user_id=(\\w+)"
          url: "/dashboard/user/$${__value.raw}"
```

### Dashboard Configuration

Example log dashboard JSON:

```json
{
  "dashboard": {
    "title": "Application Logs",
    "panels": [
      {
        "title": "Log Volume",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(count_over_time({job=~\"webapp|api\"}[5m]))",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1000},
                {"color": "red", "value": 5000}
              ]
            }
          }
        }
      },
      {
        "title": "Error Rate",
        "type": "timeseries", 
        "targets": [
          {
            "expr": "sum(rate({job=~\"webapp|api\", level=\"error\"}[5m])) / sum(rate({job=~\"webapp|api\"}[5m]))",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Recent Logs",
        "type": "logs",
        "targets": [
          {
            "expr": "{job=~\"webapp|api\"}",
            "refId": "A"
          }
        ],
        "options": {
          "showTime": true,
          "showLabels": true,
          "showCommonLabels": false,
          "wrapLogMessage": true,
          "sortOrder": "Descending"
        }
      }
    ]
  }
}
```

### Alerting Rules

Create log-based alerting rules:

```yaml
groups:
  - name: loki-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum by (job) (rate({job=~"webapp|api", level="error"}[5m])) /
            sum by (job) (rate({job=~"webapp|api"}[5m]))
          ) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate for {{ $labels.job }} is {{ $value | humanizePercentage }}"

      - alert: LogVolumeHigh
        expr: |
          sum(rate({job=~"webapp|api"}[5m])) > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High log volume detected"
          description: "Log volume is {{ $value }} logs per second"

      - alert: ServiceDown
        expr: |
          (
            count by (job) (count_over_time({job=~"webapp|api"}[5m])) or
            vector(0)
          ) == 0
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "Service appears to be down"
          description: "No logs received from {{ $labels.job }} for 5 minutes"
```

## Storage

### Local Storage Configuration

```yaml
# Local filesystem storage
storage_config:
  filesystem:
    directory: /loki/chunks

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
```

### Cloud Storage Integration

#### Amazon S3

```yaml
storage_config:
  aws:
    s3: s3://us-west-2/my-loki-bucket
    s3forcepathstyle: false
    bucketnames: my-loki-bucket
    endpoint: 
    region: us-west-2
    access_key_id: ${AWS_ACCESS_KEY_ID}
    secret_access_key: ${AWS_SECRET_ACCESS_KEY}
    insecure: false
    sse_encryption: false
    http_config:
      idle_conn_timeout: 90s
      response_header_timeout: 0s
      insecure_skip_verify: false

  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: s3

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: s3
      schema: v11
      index:
        prefix: loki_index_
        period: 24h
```

#### Google Cloud Storage

```yaml
storage_config:
  gcs:
    bucket_name: my-loki-bucket
    
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: gcs

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: gcs
      schema: v11
      index:
        prefix: loki_index_
        period: 24h
```

#### Azure Blob Storage

```yaml
storage_config:
  azure:
    account_name: ${AZURE_ACCOUNT_NAME}
    account_key: ${AZURE_ACCOUNT_KEY}
    container_name: loki-container
    endpoint_suffix: core.windows.net
    max_retries: 3

  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: azure

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: azure
      schema: v11
      index:
        prefix: loki_index_
        period: 24h
```

### Retention and Compaction

```yaml
# Table manager for retention
table_manager:
  retention_deletes_enabled: true
  retention_period: 2160h  # 90 days
  
# Compactor for cleaning up
compactor:
  working_directory: /loki/compactor
  shared_store: s3
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

## Security

### Authentication and Authorization

```yaml
# Enable multi-tenant authentication
auth_enabled: true

# Configure authentication
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  
# Basic authentication example
limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  per_tenant_override_config: /etc/loki/overrides.yaml
```

### TLS Configuration

```yaml
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  http_tls_config:
    cert_file: /etc/loki/tls/loki.crt
    key_file: /etc/loki/tls/loki.key
  grpc_tls_config:
    cert_file: /etc/loki/tls/loki.crt
    key_file: /etc/loki/tls/loki.key

# Client configuration for TLS
clients:
  - url: https://loki:3100/loki/api/v1/push
    tls_config:
      ca_file: /etc/promtail/tls/ca.crt
      cert_file: /etc/promtail/tls/promtail.crt
      key_file: /etc/promtail/tls/promtail.key
      server_name: loki.example.com
```

### Network Security

```yaml
# Kubernetes NetworkPolicy for Loki
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loki-network-policy
  namespace: logging
spec:
  podSelector:
    matchLabels:
      app: loki
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: logging
    - podSelector:
        matchLabels:
          app: promtail
    - podSelector:
        matchLabels:
          app: grafana
    ports:
    - protocol: TCP
      port: 3100
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
      port: 443  # HTTPS for object storage
```

## Container Log Collection

### Docker Log Collection

Configure Docker daemon for structured logging:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3",
    "labels": "service,environment",
    "env": "LOG_LEVEL"
  }
}
```

### Kubernetes Log Collection

Deploy Promtail as DaemonSet:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail
  namespace: logging
spec:
  selector:
    matchLabels:
      app: promtail
  template:
    metadata:
      labels:
        app: promtail
    spec:
      serviceAccount: promtail
      containers:
      - name: promtail
        image: grafana/promtail:latest
        args:
          - -config.file=/etc/promtail/config.yml
        volumeMounts:
        - name: config
          mountPath: /etc/promtail
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        ports:
        - name: http-metrics
          containerPort: 3101
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 128Mi
      volumes:
      - name: config
        configMap:
          name: promtail-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      tolerations:
      - effect: NoSchedule
        operator: Exists
```

### Application Instrumentation

#### Structured Logging Example (Go)

```go
package main

import (
    "encoding/json"
    "log"
    "net/http"
    "time"
    
    "github.com/sirupsen/logrus"
)

type LogEntry struct {
    Timestamp   time.Time `json:"timestamp"`
    Level       string    `json:"level"`
    Message     string    `json:"message"`
    Service     string    `json:"service"`
    TraceID     string    `json:"trace_id,omitempty"`
    UserID      string    `json:"user_id,omitempty"`
    Duration    int64     `json:"duration_ms,omitempty"`
    StatusCode  int       `json:"status_code,omitempty"`
}

func setupLogging() *logrus.Logger {
    logger := logrus.New()
    logger.SetFormatter(&logrus.JSONFormatter{
        TimestampFormat: time.RFC3339Nano,
    })
    logger.SetLevel(logrus.InfoLevel)
    return logger
}

func loggingMiddleware(logger *logrus.Logger, next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Extract trace ID from headers
        traceID := r.Header.Get("X-Trace-ID")
        userID := r.Header.Get("X-User-ID")
        
        // Wrap ResponseWriter to capture status code
        wrapped := &responseWriter{ResponseWriter: w, statusCode: 200}
        
        next(wrapped, r)
        
        duration := time.Since(start)
        
        logger.WithFields(logrus.Fields{
            "service":     "webapp",
            "method":      r.Method,
            "path":        r.URL.Path,
            "trace_id":    traceID,
            "user_id":     userID,
            "duration_ms": duration.Milliseconds(),
            "status_code": wrapped.statusCode,
            "user_agent":  r.UserAgent(),
            "remote_addr": r.RemoteAddr,
        }).Info("HTTP request completed")
    }
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

func main() {
    logger := setupLogging()
    
    http.HandleFunc("/", loggingMiddleware(logger, func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("Hello, World!"))
    }))
    
    logger.WithField("service", "webapp").Info("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

## Best Practices

### Label Design

1. **Keep Label Cardinality Low**: Avoid high-cardinality labels
2. **Use Consistent Labels**: Standardize label names across services
3. **Meaningful Labels**: Use labels that help with filtering and grouping
4. **Avoid Dynamic Labels**: Don't use timestamps or IDs as label values
5. **Service-Level Labels**: Include service, environment, region labels

### Query Optimization

```logql
# Good: Use specific labels
{job="webapp", environment="production"} |= "error"

# Avoid: Overly broad queries
{job=~".*"} |= "error"

# Good: Filter early
{job="webapp"} |= "error" | json | level="ERROR"

# Avoid: Parse then filter
{job="webapp"} | json | level="ERROR" |= "error"

# Good: Use time ranges appropriately
{job="webapp"}[5m]

# Avoid: Excessive time ranges for detailed queries
{job="webapp"}[24h]
```

### Storage Optimization

1. **Retention Policies**: Set appropriate retention based on compliance and cost
2. **Compression**: Logs are automatically compressed in chunks
3. **Index Optimization**: Use boltdb-shipper for cost-effective indexing
4. **Object Storage**: Use cloud object storage for scalability
5. **Monitoring**: Monitor storage usage and query performance

### Operational Excellence

1. **Monitoring**: Monitor Loki itself with metrics and logs
2. **Alerting**: Set up alerts for Loki component health
3. **Backup**: Regular backup of index and configuration
4. **Capacity Planning**: Plan for log volume growth
5. **Testing**: Test log shipping and querying regularly

### Performance Tuning

```yaml
# Ingester optimization
ingester:
  chunk_idle_period: 1m
  chunk_retain_period: 30s
  max_transfer_retries: 0
  
# Query optimization  
limits_config:
  max_query_parallelism: 32
  max_streams_per_user: 10000
  max_line_size: 256000

# Caching
query_range:
  cache_results: true
  results_cache:
    cache:
      redis_cache:
        endpoint: redis:6379
        expiration: 1h
```

## Troubleshooting

### Common Issues

#### Ingestion Problems

```bash
# Check Loki health
curl http://loki:3100/ready

# Check ingestion rate
curl http://loki:3100/metrics | grep loki_ingester_samples_received_total

# Check for rate limiting
curl http://loki:3100/metrics | grep loki_discarded_samples_total

# Promtail logs
docker logs promtail
```

#### Query Performance

```bash
# Enable query stats
curl "http://loki:3100/loki/api/v1/query?query={job=\"webapp\"}&stats=all"

# Check query cache hit rate
curl http://loki:3100/metrics | grep loki_cache

# Monitor query duration
curl http://loki:3100/metrics | grep loki_query_duration_seconds
```

#### Storage Issues

```bash
# Check disk usage
df -h /loki

# Monitor chunk creation
curl http://loki:3100/metrics | grep loki_ingester_chunks

# Check object storage
aws s3 ls s3://my-loki-bucket/fake/

# Index health
curl http://loki:3100/loki/api/v1/index/stats
```

### Debugging Tools

```bash
# LogCLI for command-line querying
logcli --addr=http://loki:3100 query '{job="webapp"}'

# Query with time range
logcli --addr=http://loki:3100 query --since=1h '{job="webapp"} |= "error"'

# Tail logs in real-time
logcli --addr=http://loki:3100 query --follow '{job="webapp"}'

# Export logs
logcli --addr=http://loki:3100 query --since=24h '{job="webapp"}' > logs.txt
```

### Health Monitoring

```yaml
# Loki health check endpoints
http://loki:3100/ready      # Ready for queries
http://loki:3100/metrics    # Prometheus metrics
http://loki:3100/config     # Current configuration
http://loki:3100/services   # Service status
```

## Resources

### Official Documentation

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Configuration Reference](https://grafana.com/docs/loki/latest/configuration/)

### Container Resources

- [Loki Docker Images](https://hub.docker.com/r/grafana/loki)
- [Helm Charts](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack)
- [Kubernetes Examples](https://github.com/grafana/loki/tree/main/production/ksonnet)
- [Docker Compose Examples](https://github.com/grafana/loki/tree/main/production/docker)

### Client Libraries and Tools

- [LogCLI](https://grafana.com/docs/loki/latest/tools/logcli/) - Command-line client
- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) - Official log shipper
- [Fluent Bit Plugin](https://grafana.com/docs/loki/latest/clients/fluentbit/)
- [Fluentd Plugin](https://grafana.com/docs/loki/latest/clients/fluentd/)

### Integration Examples

- [Loki + Prometheus](https://grafana.com/docs/loki/latest/operations/observability/)
- [Loki + Grafana](https://grafana.com/docs/grafana/latest/datasources/loki/)
- [Loki + Jaeger](https://grafana.com/docs/loki/latest/logql/template_functions/#examples)
- [Alert Integration](https://grafana.com/docs/loki/latest/alert/)

### Community Resources

- [Grafana Community](https://community.grafana.com/c/loki/)
- [GitHub Repository](https://github.com/grafana/loki)
- [Best Practices Guide](https://grafana.com/docs/loki/latest/best-practices/)
- [Performance Tips](https://grafana.com/docs/loki/latest/operations/storage/retention/)

### Learning Resources

- [Getting Started Guide](https://grafana.com/docs/loki/latest/getting-started/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/tutorial/)
- [Migration Guides](https://grafana.com/docs/loki/latest/operations/upgrade/)
- [Architecture Deep Dive](https://grafana.com/docs/loki/latest/architecture/)
