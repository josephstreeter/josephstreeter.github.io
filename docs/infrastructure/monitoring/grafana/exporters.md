---
title: "Exporters Configuration"
description: "Comprehensive guide to configuring and deploying Prometheus exporters for monitoring infrastructure and applications"
author: "josephstreeter"
ms.author: "joseph.streeter"
ms.topic: reference
ms.date: 12/30/2025
keywords: ["prometheus", "exporters", "node exporter", "cadvisor", "blackbox", "monitoring", "metrics"]
uid: docs.infrastructure.grafana.exporters
---

## Overview

Prometheus exporters are agents that expose metrics from third-party systems in a format that Prometheus can scrape. They bridge the gap between systems that don't natively expose Prometheus metrics and your monitoring infrastructure.

**Key Concepts:**

- **Pull-based Model**: Prometheus scrapes metrics from exporters via HTTP endpoints
- **Metric Types**: Counter, Gauge, Histogram, Summary
- **Target Discovery**: Static configs, service discovery, or Kubernetes annotations
- **Performance**: Exporters should be lightweight and have minimal impact on monitored systems

## Node Exporter

Node Exporter exposes hardware and OS metrics from *NIX kernels.

### Linux Installation

```bash
#!/bin/bash
# Install Node Exporter on Linux

VERSION="1.8.0"
ARCH="amd64"

# Download and extract
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz
tar xvfz node_exporter-${VERSION}.linux-${ARCH}.tar.gz
sudo cp node_exporter-${VERSION}.linux-${ARCH}/node_exporter /usr/local/bin/
sudo chown root:root /usr/local/bin/node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \\
    --collector.filesystem.mount-points-exclude='^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)' \\
    --collector.filesystem.fs-types-exclude='^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$' \\
    --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \\
    --web.listen-address=:9100

Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Create user and directories
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo chown -R node_exporter:node_exporter /var/lib/node_exporter

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

### Windows Installation

```powershell
# Install Node Exporter on Windows
$Version = "1.8.0"
$Url = "https://github.com/prometheus/node_exporter/releases/download/v$Version/node_exporter-$Version.windows-amd64.zip"
$InstallPath = "C:\Program Files\node_exporter"

# Download and extract
Invoke-WebRequest -Uri $Url -OutFile "$env:TEMP\node_exporter.zip"
Expand-Archive -Path "$env:TEMP\node_exporter.zip" -DestinationPath $InstallPath -Force

# Create Windows service using NSSM
nssm install node_exporter "$InstallPath\node_exporter-$Version.windows-amd64\node_exporter.exe"
nssm set node_exporter AppParameters "--collector.cpu --collector.cs --collector.logical_disk --collector.net --collector.os --collector.system --collector.memory"
nssm set node_exporter DisplayName "Prometheus Node Exporter"
nssm set node_exporter Description "Exports machine metrics to Prometheus"
nssm set node_exporter Start SERVICE_AUTO_START

# Start service
Start-Service node_exporter
```

### Docker Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  node_exporter:
    image: prom/node-exporter:v1.8.0
    container_name: node_exporter
    restart: unless-stopped
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    ports:
      - "9100:9100"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Custom Textfile Collector

```bash
#!/bin/bash
# Example: Custom metrics collection script
# Place in /etc/cron.d/custom-metrics (run every 5 minutes)

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
TEMP_FILE="${TEXTFILE_DIR}/custom_metrics.prom.$$"
PROM_FILE="${TEXTFILE_DIR}/custom_metrics.prom"

# Collect custom metrics
{
    echo "# HELP custom_backup_age_seconds Age of last backup in seconds"
    echo "# TYPE custom_backup_age_seconds gauge"
    BACKUP_AGE=$(( $(date +%s) - $(stat -c %Y /backup/latest.tar.gz 2>/dev/null || echo 0) ))
    echo "custom_backup_age_seconds ${BACKUP_AGE}"
    
    echo "# HELP custom_database_size_bytes Database size in bytes"
    echo "# TYPE custom_database_size_bytes gauge"
    DB_SIZE=$(sudo -u postgres psql -t -c "SELECT pg_database_size('mydb')" | tr -d ' ')
    echo "custom_database_size_bytes ${DB_SIZE}"
    
    echo "# HELP custom_certificate_expiry_seconds Certificate expiry time in seconds"
    echo "# TYPE custom_certificate_expiry_seconds gauge"
    CERT_EXPIRY=$(date -d "$(openssl x509 -in /etc/ssl/certs/myapp.crt -noout -enddate | cut -d= -f2)" +%s)
    echo "custom_certificate_expiry_seconds ${CERT_EXPIRY}"
} > "${TEMP_FILE}"

# Atomic move
mv "${TEMP_FILE}" "${PROM_FILE}"
```

## cAdvisor

Container Advisor (cAdvisor) provides resource usage and performance characteristics of running containers.

### cAdvisor Docker Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.2
    container_name: cadvisor
    restart: unless-stopped
    privileged: true
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - /dev/kmsg
    command:
      - '--housekeeping_interval=30s'
      - '--docker_only=true'
      - '--disable_metrics=disk,network,tcp,udp,percpu,sched,process'
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Kubernetes Deployment

```yaml
# cadvisor-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: cadvisor
  template:
    metadata:
      labels:
        app: cadvisor
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      automountServiceAccountToken: false
      containers:
      - name: cadvisor
        image: gcr.io/cadvisor/cadvisor:v0.47.2
        ports:
        - name: metrics
          containerPort: 8080
          protocol: TCP
        resources:
          requests:
            memory: 200Mi
            cpu: 100m
          limits:
            memory: 400Mi
            cpu: 300m
        volumeMounts:
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: var-run
          mountPath: /var/run
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: docker
          mountPath: /var/lib/docker
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: var-run
        hostPath:
          path: /var/run
      - name: sys
        hostPath:
          path: /sys
      - name: docker
        hostPath:
          path: /var/lib/docker
      - name: disk
        hostPath:
          path: /dev/disk
```

## Blackbox Exporter

Blackbox Exporter probes endpoints over HTTP, HTTPS, DNS, TCP, ICMP, and gRPC.

### Configuration Examples

```yaml
# blackbox.yml
modules:
  # HTTP 2xx probe
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200, 201, 202, 204]
      method: GET
      preferred_ip_protocol: "ip4"
      follow_redirects: true
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: false

  # HTTP POST probe with authentication
  http_post_auth:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
        Authorization: Bearer {{ env "API_TOKEN" }}
      body: '{"health_check": true}'
      valid_status_codes: [200]
      fail_if_body_not_matches_regexp:
        - "status.*ok"

  # HTTP probe with specific headers and SSL verification
  http_ssl_check:
    prober: http
    timeout: 10s
    http:
      method: GET
      preferred_ip_protocol: "ip4"
      tls_config:
        insecure_skip_verify: false
      fail_if_not_ssl: true
      fail_if_body_not_matches_regexp:
        - "Copyright 2025"

  # TCP probe
  tcp_connect:
    prober: tcp
    timeout: 5s
    tcp:
      preferred_ip_protocol: "ip4"
      tls: false

  # TCP with TLS probe
  tcp_connect_tls:
    prober: tcp
    timeout: 5s
    tcp:
      preferred_ip_protocol: "ip4"
      tls: true
      tls_config:
        insecure_skip_verify: false

  # ICMP probe
  icmp_check:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
      source_ip_address: "0.0.0.0"

  # DNS probe
  dns_check:
    prober: dns
    timeout: 5s
    dns:
      preferred_ip_protocol: "ip4"
      query_name: "example.com"
      query_type: "A"
      valid_rcodes:
        - NOERROR
      validate_answer_rrs:
        fail_if_not_matches_regexp:
          - ".*"

  # DNS probe with specific record validation
  dns_mx_check:
    prober: dns
    timeout: 5s
    dns:
      query_name: "example.com"
      query_type: "MX"
      valid_rcodes:
        - NOERROR
      validate_answer_rrs:
        fail_if_not_matches_regexp:
          - "mail.*example.com"
```

### Docker Deployment

```yaml
# docker-compose.yml
version: '3.8'

services:
  blackbox_exporter:
    image: prom/blackbox-exporter:v0.24.0
    container_name: blackbox_exporter
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Prometheus Configuration for Blackbox

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'blackbox_http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://example.com
        - https://api.example.com/health
        - https://app.example.com/status
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox_exporter:9115

  - job_name: 'blackbox_icmp'
    metrics_path: /probe
    params:
      module: [icmp_check]
    static_configs:
      - targets:
        - 8.8.8.8
        - 1.1.1.1
        - 192.168.1.1
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox_exporter:9115
```

## Unpoller (UniFi)

Unpoller collects metrics from UniFi Controller for network monitoring.

### Unpoller Docker Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  unpoller:
    image: golift/unifi-poller:v2.10.0
    container_name: unpoller
    restart: unless-stopped
    ports:
      - "9130:9130"
    environment:
      # Prometheus Settings
      UP_PROMETHEUS_DISABLE: "false"
      UP_PROMETHEUS_NAMESPACE: "unifi"
      
      # UniFi Controller Settings
      UP_UNIFI_CONTROLLER_0_URL: "https://unifi.example.com:8443"
      UP_UNIFI_CONTROLLER_0_USER: "prometheus"
      UP_UNIFI_CONTROLLER_0_PASS: "${UNIFI_PASSWORD}"
      UP_UNIFI_CONTROLLER_0_VERIFY_SSL: "false"
      
      # Polling Settings
      UP_UNIFI_DEFAULT_SAVE_SITES: "true"
      UP_UNIFI_DEFAULT_SAVE_IDS: "true"
      UP_UNIFI_DEFAULT_SAVE_DPI: "true"
      UP_UNIFI_DEFAULT_SAVE_ALARMS: "true"
      UP_UNIFI_DEFAULT_SAVE_ANOMALIES: "true"
      UP_UNIFI_DEFAULT_SAVE_EVENTS: "false"
      
      # Interval Settings
      UP_POLLER_DEBUG: "false"
      UP_INTERVAL: "30s"
      
      # InfluxDB (optional)
      UP_INFLUXDB_DISABLE: "true"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Configuration File Example

```toml
# unpoller.conf
[prometheus]
  disable = false
  namespace = "unifi"
  http_listen = "0.0.0.0:9130"

[unifi]
  dynamic = false

[unifi.defaults]
  role = "main-controller"
  verify_ssl = false
  save_sites = true
  save_ids = true
  save_dpi = true
  save_alarms = true
  save_anomalies = true
  save_events = false

[[unifi.controller]]
  url = "https://unifi.example.com:8443"
  user = "prometheus"
  pass = "secure_password_here"
  sites = ["all"]

[poller]
  debug = false
  quiet = false
```

### Key Metrics Overview

```promql
# Device status
unifi_device_uptime_seconds{site="default"}

# Client statistics
unifi_client_received_bytes_total{site="default"}
unifi_client_transmitted_bytes_total{site="default"}

# Access Point metrics
unifi_access_point_station_count{site="default"}
unifi_access_point_user_experience_score{site="default"}

# Network statistics
unifi_network_received_bytes_total{site="default"}
unifi_network_transmitted_bytes_total{site="default"}

# Alarm count
unifi_alarms_total{site="default"}
```

## Database Exporters

### PostgreSQL Exporter

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres_exporter:
    image: prometheuscommunity/postgres-exporter:v0.15.0
    container_name: postgres_exporter
    restart: unless-stopped
    ports:
      - "9187:9187"
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres_exporter:${DB_PASSWORD}@postgres:5432/postgres?sslmode=disable"
      PG_EXPORTER_EXTEND_QUERY_PATH: "/etc/postgres_exporter/queries.yaml"
    volumes:
      - ./postgres_queries.yaml:/etc/postgres_exporter/queries.yaml:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

Custom queries file:

```yaml
# postgres_queries.yaml
pg_database_size:
  query: |
    SELECT
      datname as database,
      pg_database_size(datname) as size_bytes
    FROM pg_database
    WHERE datname NOT IN ('template0', 'template1')
  metrics:
    - database:
        usage: "LABEL"
        description: "Database name"
    - size_bytes:
        usage: "GAUGE"
        description: "Database size in bytes"

pg_table_bloat:
  query: |
    SELECT
      schemaname,
      tablename,
      pg_total_relation_size(schemaname||'.'||tablename) AS total_bytes,
      pg_relation_size(schemaname||'.'||tablename) AS table_bytes
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  metrics:
    - schemaname:
        usage: "LABEL"
        description: "Schema name"
    - tablename:
        usage: "LABEL"
        description: "Table name"
    - total_bytes:
        usage: "GAUGE"
        description: "Total size including indexes"
    - table_bytes:
        usage: "GAUGE"
        description: "Table size"
```

### MySQL Exporter

```yaml
# docker-compose.yml
version: '3.8'

services:
  mysql_exporter:
    image: prom/mysqld-exporter:v0.15.1
    container_name: mysql_exporter
    restart: unless-stopped
    ports:
      - "9104:9104"
    environment:
      DATA_SOURCE_NAME: "exporter:${MYSQL_PASSWORD}@(mysql:3306)/"
      collect.info_schema.innodb_metrics: "true"
      collect.info_schema.tables: "true"
      collect.info_schema.tablestats: "true"
      collect.perf_schema.tableiowaits: "true"
      collect.perf_schema.indexiowaits: "true"
    command:
      - "--config.my-cnf=/etc/mysqld-exporter/.my.cnf"
      - "--collect.global_status"
      - "--collect.info_schema.innodb_metrics"
      - "--collect.auto_increment.columns"
      - "--collect.perf_schema.tableiowaits"
      - "--collect.perf_schema.file_events"
    volumes:
      - ./my.cnf:/etc/mysqld-exporter/.my.cnf:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### MongoDB Exporter

```yaml
# docker-compose.yml
version: '3.8'

services:
  mongodb_exporter:
    image: percona/mongodb_exporter:0.40.0
    container_name: mongodb_exporter
    restart: unless-stopped
    ports:
      - "9216:9216"
    environment:
      MONGODB_URI: "mongodb://exporter:${MONGO_PASSWORD}@mongodb:27017"
      MONGODB_ENABLE_DIAGNOSTIC_DATA: "true"
      MONGODB_ENABLE_REPLICASET: "true"
    command:
      - "--mongodb.direct-connect=false"
      - "--mongodb.global-conn-pool=false"
      - "--collector.diagnosticdata"
      - "--collector.replicasetstatus"
      - "--collector.dbstats"
      - "--collector.topmetrics"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Redis Exporter

```yaml
# docker-compose.yml
version: '3.8'

services:
  redis_exporter:
    image: oliver006/redis_exporter:v1.58.0
    container_name: redis_exporter
    restart: unless-stopped
    ports:
      - "9121:9121"
    environment:
      REDIS_ADDR: "redis://redis:6379"
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      REDIS_EXPORTER_CHECK_KEYS: "myapp:user:*,myapp:session:*"
      REDIS_EXPORTER_CHECK_SINGLE_KEYS: "myapp:config,myapp:feature_flags"
    command:
      - "--include-system-metrics"
      - "--is-tile38=false"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

## SNMP Exporter

### Generator Usage

```bash
#!/bin/bash
# Generate SNMP exporter configuration

# Clone generator repository
git clone https://github.com/prometheus/snmp_exporter.git
cd snmp_exporter/generator

# Install dependencies
sudo apt-get install -y unzip build-essential libsnmp-dev
go install

# Create generator configuration
cat > generator.yml <<EOF
modules:
  cisco_switch:
    walk:
      - sysUpTime
      - interfaces
      - ifXTable
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      - 1.3.6.1.2.1.2.2.1.8     # ifOperStatus
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifAlias
      - source_indexes: [ifIndex]
        lookup: ifDescr
    overrides:
      ifAlias:
        ignore: true
      ifDescr:
        ignore: true
      ifName:
        ignore: true
      ifType:
        type: EnumAsInfo

  pdu:
    walk:
      - sysUpTime
      - 1.3.6.1.4.1.318.1.1.12.2.3.1.1.2  # rPDUOutletStatusOutletName
      - 1.3.6.1.4.1.318.1.1.12.2.3.1.1.4  # rPDUOutletStatusOutletState
      - 1.3.6.1.4.1.318.1.1.12.2.3.1.1.6  # rPDUOutletStatusLoad
    lookups:
      - source_indexes: [rPDUOutletStatusIndex]
        lookup: rPDUOutletStatusOutletName
EOF

# Generate snmp.yml
export MIBDIRS=/usr/share/snmp/mibs
./generator generate
```

### Configuration Example

```yaml
# snmp.yml (example output from generator)
modules:
  cisco_switch:
    walk:
      - 1.3.6.1.2.1.1.3.0      # sysUpTime
      - 1.3.6.1.2.1.2.2.1      # interfaces
      - 1.3.6.1.2.1.31.1.1.1   # ifXTable
    get:
      - 1.3.6.1.2.1.1.3.0
    metrics:
      - name: sysUpTime
        oid: 1.3.6.1.2.1.1.3.0
        type: gauge
      - name: ifInOctets
        oid: 1.3.6.1.2.1.2.2.1.10
        type: counter
        indexes:
          - labelname: ifIndex
            type: gauge
    version: 2
    auth:
      community: public
```

### SNMP Docker Deployment

```yaml
# docker-compose.yml
version: '3.8'

services:
  snmp_exporter:
    image: prom/snmp-exporter:v0.25.0
    container_name: snmp_exporter
    restart: unless-stopped
    ports:
      - "9116:9116"
    volumes:
      - ./snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    command:
      - '--config.file=/etc/snmp_exporter/snmp.yml'
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Prometheus Configuration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'snmp_cisco'
    static_configs:
      - targets:
        - 192.168.1.10  # Cisco switch
        - 192.168.1.11  # Another switch
    metrics_path: /snmp
    params:
      module: [cisco_switch]
      auth: [public_v2]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp_exporter:9116
```

## Custom Exporters

### Writing Custom Exporter in Python

```python
#!/usr/bin/env python3
"""
Custom Prometheus Exporter Example
Exposes custom application metrics
"""

from prometheus_client import start_http_server, Gauge, Counter, Histogram
import time
import random

# Define metrics
app_requests = Counter(
    'app_requests_total',
    'Total application requests',
    ['method', 'endpoint', 'status']
)

app_request_duration = Histogram(
    'app_request_duration_seconds',
    'Application request duration',
    ['method', 'endpoint']
)

app_active_connections = Gauge(
    'app_active_connections',
    'Number of active connections'
)

app_queue_size = Gauge(
    'app_queue_size',
    'Size of processing queue'
)

app_last_success_timestamp = Gauge(
    'app_last_success_timestamp_seconds',
    'Timestamp of last successful operation'
)

def collect_metrics():
    """Simulate metric collection"""
    while True:
        # Simulate request metrics
        method = random.choice(['GET', 'POST', 'PUT'])
        endpoint = random.choice(['/api/users', '/api/products', '/api/orders'])
        status = random.choice(['200', '200', '200', '404', '500'])
        
        app_requests.labels(method=method, endpoint=endpoint, status=status).inc()
        
        # Simulate request duration
        duration = random.uniform(0.01, 2.0)
        app_request_duration.labels(method=method, endpoint=endpoint).observe(duration)
        
        # Simulate gauge metrics
        app_active_connections.set(random.randint(10, 100))
        app_queue_size.set(random.randint(0, 50))
        app_last_success_timestamp.set(time.time())
        
        time.sleep(1)

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8000)
    print("Metrics server started on port 8000")
    
    # Collect metrics
    collect_metrics()
```

### Custom Exporter in Go

```go
package main

import (
    "log"
    "math/rand"
    "net/http"
    "time"

    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    // Define metrics
    appRequests = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "app_requests_total",
            Help: "Total application requests",
        },
        []string{"method", "endpoint", "status"},
    )

    appRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "app_request_duration_seconds",
            Help:    "Application request duration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )

    appActiveConnections = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "app_active_connections",
            Help: "Number of active connections",
        },
    )

    appQueueSize = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "app_queue_size",
            Help: "Size of processing queue",
        },
    )
)

func init() {
    // Register metrics
    prometheus.MustRegister(appRequests)
    prometheus.MustRegister(appRequestDuration)
    prometheus.MustRegister(appActiveConnections)
    prometheus.MustRegister(appQueueSize)
}

func collectMetrics() {
    methods := []string{"GET", "POST", "PUT"}
    endpoints := []string{"/api/users", "/api/products", "/api/orders"}
    statuses := []string{"200", "200", "200", "404", "500"}

    for {
        // Simulate request metrics
        method := methods[rand.Intn(len(methods))]
        endpoint := endpoints[rand.Intn(len(endpoints))]
        status := statuses[rand.Intn(len(statuses))]

        appRequests.WithLabelValues(method, endpoint, status).Inc()

        // Simulate request duration
        duration := rand.Float64() * 2.0
        appRequestDuration.WithLabelValues(method, endpoint).Observe(duration)

        // Simulate gauge metrics
        appActiveConnections.Set(float64(rand.Intn(90) + 10))
        appQueueSize.Set(float64(rand.Intn(51)))

        time.Sleep(time.Second)
    }
}

func main() {
    // Start metric collection
    go collectMetrics()

    // Expose metrics endpoint
    http.Handle("/metrics", promhttp.Handler())
    log.Println("Metrics server started on :8000")
    log.Fatal(http.ListenAndServe(":8000", nil))
}
```

### Pushgateway Usage

```bash
#!/bin/bash
# Example: Push metrics from batch job to Pushgateway

JOB_NAME="backup_job"
INSTANCE="db-server-01"
PUSHGATEWAY_URL="http://pushgateway:9091"

# Capture job start time
START_TIME=$(date +%s)

# Run backup job (example)
if /usr/local/bin/backup-database.sh; then
    STATUS="success"
    EXIT_CODE=0
else
    STATUS="failure"
    EXIT_CODE=$?
fi

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Push metrics to Pushgateway
cat <<EOF | curl --data-binary @- "${PUSHGATEWAY_URL}/metrics/job/${JOB_NAME}/instance/${INSTANCE}"
# TYPE backup_job_success gauge
# HELP backup_job_success Backup job success status (1=success, 0=failure)
backup_job_success{job="${JOB_NAME}",instance="${INSTANCE}"} $([[ $STATUS == "success" ]] && echo 1 || echo 0)

# TYPE backup_job_duration_seconds gauge
# HELP backup_job_duration_seconds Backup job duration in seconds
backup_job_duration_seconds{job="${JOB_NAME}",instance="${INSTANCE}"} ${DURATION}

# TYPE backup_job_last_completion_timestamp gauge
# HELP backup_job_last_completion_timestamp Timestamp of last job completion
backup_job_last_completion_timestamp{job="${JOB_NAME}",instance="${INSTANCE}"} ${END_TIME}

# TYPE backup_job_exit_code gauge
# HELP backup_job_exit_code Exit code of backup job
backup_job_exit_code{job="${JOB_NAME}",instance="${INSTANCE}"} ${EXIT_CODE}
EOF

echo "Metrics pushed to Pushgateway"
```

## Best Practices

### Deployment Considerations

1. **Resource Isolation**: Run exporters in dedicated containers or services
2. **Network Security**: Restrict exporter access using firewalls or network policies
3. **Authentication**: Use authentication where supported (basic auth, TLS client certs)
4. **Minimal Privileges**: Run exporters with minimal required permissions
5. **Health Checks**: Implement liveness/readiness probes for containerized exporters

### Performance Optimization

```yaml
# Optimize scrape intervals based on metric importance
scrape_configs:
  - job_name: 'critical_metrics'
    scrape_interval: 15s
    static_configs:
      - targets: ['api-server:9090']

  - job_name: 'standard_metrics'
    scrape_interval: 30s
    static_configs:
      - targets: ['app-server:9090']

  - job_name: 'low_priority_metrics'
    scrape_interval: 60s
    static_configs:
      - targets: ['batch-server:9090']
```

### Labeling Standards

```yaml
# Use consistent labels across exporters
global:
  external_labels:
    environment: 'production'
    datacenter: 'us-east-1'
    cluster: 'main'

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node1:9100']
        labels:
          role: 'webserver'
          tier: 'frontend'
      - targets: ['node2:9100']
        labels:
          role: 'database'
          tier: 'backend'
```

### Security Best Practices

1. **TLS Encryption**: Enable TLS for exporter endpoints in production
2. **Authentication**: Implement basic auth or mutual TLS
3. **Network Segmentation**: Isolate exporters in monitoring network
4. **Least Privilege**: Run exporters with minimal required permissions
5. **Regular Updates**: Keep exporters updated to latest stable versions

### Monitoring Exporters

```yaml
# prometheus.yml - Monitor exporter health
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

# Alert on exporter down
groups:
  - name: exporter_health
    rules:
      - alert: ExporterDown
        expr: up{job!~"prometheus|alertmanager"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Exporter {{ $labels.job }} is down"
          description: "Exporter {{ $labels.job }} on {{ $labels.instance }} has been down for more than 5 minutes"
```

## Troubleshooting

### Common Issues

**Exporter Not Reachable:**

```bash
# Test exporter endpoint
curl -v http://localhost:9100/metrics

# Check if port is listening
sudo netstat -tlnp | grep 9100

# Check firewall rules
sudo iptables -L -n | grep 9100
```

**High Cardinality Metrics:**

```promql
# Find metrics with high cardinality
topk(10, count by (__name__)({__name__=~".+"}))

# Check label cardinality
count by (job, instance) (up)
```

**Permission Issues:**

```bash
# Node exporter can't read system metrics
sudo setcap cap_dac_read_search+ep /usr/local/bin/node_exporter

# Grant access to textfile collector directory
sudo chown -R node_exporter:node_exporter /var/lib/node_exporter
```

**Memory Issues:**

```bash
# Limit exporter memory usage
# Add to systemd service file
[Service]
MemoryLimit=500M
MemoryAccounting=true
```

## See Also

- [Prometheus Configuration](index.md)
- [Alerting Configuration](alerting.md)
- [Configuration Guide](configuration.md)
- [Grafana Dashboards](dashboards.md)
- [High Availability](high-availability.md)
