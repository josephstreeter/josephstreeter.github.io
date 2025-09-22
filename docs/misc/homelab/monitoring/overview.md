---
title: Home Lab Monitoring Stack
description: Complete monitoring and observability solution using Prometheus, Grafana, and Loki for comprehensive home lab visibility
author: Joseph Streeter
date: 2025-09-13
tags: [monitoring, prometheus, grafana, loki, observability, alerting]
---

Enterprise-grade monitoring and observability stack for home lab infrastructure with metrics, logs, and alerting.

## 🎯 **Monitoring Architecture Overview**

### Core Components

| Component | Purpose | Port | Resource Requirements |
|-----------|---------|------|----------------------|
| **Prometheus** | Metrics collection and storage | 9090 | 2 vCPU, 4GB RAM, 50GB storage |
| **Grafana** | Visualization and dashboards | 3000 | 1 vCPU, 2GB RAM, 10GB storage |
| **Loki** | Log aggregation and storage | 3100 | 2 vCPU, 4GB RAM, 100GB storage |
| **Promtail** | Log shipping agent | 9080 | 0.5 vCPU, 512MB RAM |
| **Alertmanager** | Alert routing and management | 9093 | 1 vCPU, 1GB RAM, 5GB storage |
| **Node Exporter** | System metrics collection | 9100 | 0.2 vCPU, 128MB RAM |

### Monitoring Data Flow

```text
Data Collection and Processing:

┌──────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Infrastructure │    │   Applications   │    │   Network       │
│   Servers/VMs    │    │   Services       │    │   Equipment     │
└─────────┬────────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
    ┌─────▼─────┐          ┌─────▼─────┐           ┌─────▼─────┐
    │Node       │          │App        │           │SNMP       │
    │Exporter   │          │Exporters  │           │Exporter   │
    └─────┬─────┘          └─────┬─────┘           └─────┬─────┘
          │                      │                       │
          └──────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │      Prometheus         │
                    │   (Metrics Storage)     │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │       Grafana           │
                    │   (Visualization)       │
                    └─────────────────────────┘

┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   System Logs   │    │   Application    │    │   Network       │
│   /var/log/*    │    │   Logs           │    │   Logs          │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
    ┌─────▼─────┐          ┌─────▼─────┐           ┌─────▼─────┐
    │Promtail   │          │Promtail   │           │Promtail   │
    │Agent      │          │Agent      │           │Agent      │
    └─────┬─────┘          └─────┬─────┘           └─────┬─────┘
          │                      │                       │
          └──────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │        Loki             │
                    │   (Log Storage)         │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │       Grafana           │
                    │   (Log Visualization)   │
                    └─────────────────────────┘
```

## 📊 **Prometheus Configuration**

### Server Installation and Setup

#### System Preparation

```bash
# Create Prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus

# Create directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Download and install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar xzf prometheus-2.47.0.linux-amd64.tar.gz

# Install binaries
sudo cp prometheus-2.47.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.47.0.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Install configuration files
sudo cp -r prometheus-2.47.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.47.0.linux-amd64/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
```

#### Prometheus Configuration (/etc/prometheus/prometheus.yml)

```yaml
# /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'homelab'
    environment: 'production'

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - 192.168.103.32:9093

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s

  # Node Exporter for system metrics
  - job_name: 'node-exporter'
    static_configs:
      - targets:
        - '192.168.127.10:9100'  # Proxmox-01
        - '192.168.127.11:9100'  # Proxmox-02
        - '192.168.127.12:9100'  # Proxmox-03
        - '192.168.103.10:9100'  # DNS Primary
        - '192.168.103.11:9100'  # DNS Secondary
        - '192.168.103.30:9100'  # Prometheus
        - '192.168.127.20:9100'  # Web-01
        - '192.168.127.21:9100'  # App-01
    scrape_interval: 10s
    metrics_path: /metrics

  # Proxmox monitoring
  - job_name: 'proxmox'
    static_configs:
      - targets:
        - '192.168.127.10:8006'
        - '192.168.127.11:8006'
        - '192.168.127.12:8006'
    scrape_interval: 30s
    metrics_path: /api2/prometheus/metrics
    params:
      format: ['prometheus']

  # BIND DNS monitoring
  - job_name: 'bind-exporter'
    static_configs:
      - targets:
        - '192.168.103.10:9119'  # DNS Primary
        - '192.168.103.11:9119'  # DNS Secondary
    scrape_interval: 30s

  # Network equipment (SNMP)
  - job_name: 'snmp-unifi'
    static_configs:
      - targets:
        - '192.168.1.1'   # UDM Pro
        - '192.168.1.20'  # Switch Main
        - '192.168.1.30'  # AP Main
    metrics_path: /snmp
    params:
      module: [unifi]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 192.168.103.34:9116  # SNMP exporter

  # Application monitoring
  - job_name: 'nginx-exporter'
    static_configs:
      - targets:
        - '192.168.104.10:9113'  # Web-01 Nginx
        - '192.168.104.11:9113'  # Web-02 Nginx
    scrape_interval: 15s

  # Database monitoring
  - job_name: 'postgres-exporter'
    static_configs:
      - targets:
        - '192.168.106.30:9187'  # PostgreSQL
    scrape_interval: 30s

  # Container monitoring
  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - '192.168.101.10:8080'  # Proxmox-01 cAdvisor
        - '192.168.101.11:8080'  # Proxmox-02 cAdvisor
        - '192.168.101.12:8080'  # Proxmox-03 cAdvisor
    scrape_interval: 15s
    metrics_path: /metrics

  # Blackbox monitoring (endpoint availability)
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://www.homelab.local
        - https://grafana.homelab.local
        - https://prometheus.homelab.local
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 192.168.103.35:9115  # Blackbox exporter

  # IoT and Home Automation
  - job_name: 'home-assistant'
    static_configs:
      - targets:
        - '192.168.107.10:8123'
    metrics_path: /api/prometheus
    authorization:
      credentials: 'your_long_lived_access_token'
    scrape_interval: 60s
```

#### Alerting Rules (/etc/prometheus/rules/homelab.yml)

```yaml
# /etc/prometheus/rules/homelab.yml
groups:
  - name: homelab.rules
    rules:
      # Node/System Alerts
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 2 minutes."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% for more than 2 minutes."

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 10% on {{ $labels.device }}."

      # DNS Specific Alerts
      - alert: DNSServerDown
        expr: up{job="bind-exporter"} == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "DNS server {{ $labels.instance }} is down"
          description: "DNS server has been down for more than 30 seconds."

      - alert: HighDNSQueryRate
        expr: rate(bind_query_recursions_total[5m]) > 100
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High DNS query rate on {{ $labels.instance }}"
          description: "DNS server is handling more than 100 queries per second."

      # Network Alerts
      - alert: HighNetworkTraffic
        expr: rate(node_network_receive_bytes_total[5m]) + rate(node_network_transmit_bytes_total[5m]) > 100000000
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High network traffic on {{ $labels.instance }}"
          description: "Network traffic is above 100MB/s for more than 2 minutes."

      # Proxmox Alerts
      - alert: ProxmoxNodeOffline
        expr: up{job="proxmox"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Proxmox node {{ $labels.instance }} offline"
          description: "Proxmox node has been offline for more than 1 minute."

      # Web Service Alerts
      - alert: WebsiteDown
        expr: probe_success{job="blackbox-http"} == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Website {{ $labels.instance }} is down"
          description: "Website check has failed for more than 30 seconds."

      - alert: SlowWebsiteResponse
        expr: probe_duration_seconds{job="blackbox-http"} > 5
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Slow response from {{ $labels.instance }}"
          description: "Website response time is above 5 seconds."
```

#### Systemd Service (/etc/systemd/system/prometheus.service)

```ini
# /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.external-url=http://prometheus.homelab.local:9090 \
    --storage.tsdb.retention.time=90d \
    --storage.tsdb.retention.size=20GB

[Install]
WantedBy=multi-user.target
```

## 📈 **Grafana Configuration**

### Installation and Setup

```bash
# Install Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install grafana

# Enable and start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Grafana Configuration (/etc/grafana/grafana.ini)

```ini
[server]
http_addr = 0.0.0.0
http_port = 3000
domain = grafana.homelab.local
root_url = https://grafana.homelab.local/

[database]
type = sqlite3
path = grafana.db

[session]
provider = file

[analytics]
reporting_enabled = false
check_for_updates = false

[security]
admin_user = admin
admin_password = $__file{/etc/grafana/admin_password}
secret_key = $__file{/etc/grafana/secret_key}
disable_gravatar = true

[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.anonymous]
enabled = false

[log]
mode = file
level = info

[alerting]
enabled = true
execute_alerts = true

[unified_alerting]
enabled = true

[smtp]
enabled = true
host = smtp.homelab.local:587
user = grafana@homelab.local
password = $__file{/etc/grafana/smtp_password}
from_address = grafana@homelab.local
from_name = Grafana
```

### Key Dashboards

#### Infrastructure Overview Dashboard

```json
{
  "dashboard": {
    "title": "Home Lab Infrastructure Overview",
    "panels": [
      {
        "title": "System Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Disk Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)",
            "legendFormat": "{{ instance }}:{{ mountpoint }}"
          }
        ]
      },
      {
        "title": "Network Traffic",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total[5m])",
            "legendFormat": "{{ instance }} RX"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total[5m])",
            "legendFormat": "{{ instance }} TX"
          }
        ]
      }
    ]
  }
}
```

## 📝 **Loki Log Aggregation**

### Loki Installation

```bash
# Download and install Loki
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo cp loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki

# Create Loki user and directories
sudo useradd --system --no-create-home --shell /bin/false loki
sudo mkdir -p /etc/loki /var/lib/loki
sudo chown loki:loki /etc/loki /var/lib/loki
```

### Loki Configuration (/etc/loki/loki.yml)

```yaml
# /etc/loki/loki.yml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
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
  alertmanager_url: http://192.168.103.32:9093

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
```

### Promtail Configuration (/etc/promtail/promtail.yml)

```yaml
# /etc/promtail/promtail.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: http://192.168.103.33:3100/loki/api/v1/push

scrape_configs:
  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
          
  # Nginx access logs
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*log
    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>[\w\.]+) - (?P<remote_user>[^ ]*) \[(?P<time_local>.*)\] "(?P<method>[^ ]*) (?P<request>[^ ]*) (?P<protocol>[^ ]*)" (?P<status>[\d]+) (?P<body_bytes_sent>[\d]+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"'
      - labels:
          method:
          status:

  # Application logs
  - job_name: applications
    static_configs:
      - targets:
          - localhost
        labels:
          job: applications
          __path__: /var/log/applications/*log

  # DNS logs
  - job_name: bind
    static_configs:
      - targets:
          - localhost
        labels:
          job: bind
          __path__: /var/log/bind/*log
```

## 🚨 **Alertmanager Configuration**

### Alertmanager Installation and Setup

```bash
# Download and install Alertmanager
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xzf alertmanager-0.26.0.linux-amd64.tar.gz

# Install binary
sudo cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/

# Create user and directories
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir /etc/alertmanager /var/lib/alertmanager
sudo chown alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
```

### Alertmanager Configuration (/etc/alertmanager/alertmanager.yml)

```yaml
# /etc/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'smtp.homelab.local:587'
  smtp_from: 'alerts@homelab.local'
  smtp_auth_username: 'alerts@homelab.local'
  smtp_auth_password: 'your_smtp_password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@homelab.local'
        subject: 'Home Lab Alert'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}

  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@homelab.local'
        subject: 'CRITICAL: Home Lab Alert'
        body: |
          {{ range .Alerts }}
          CRITICAL ALERT: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          {{ end }}

  - name: 'warning-alerts'
    email_configs:
      - to: 'admin@homelab.local'
        subject: 'WARNING: Home Lab Alert'
        body: |
          {{ range .Alerts }}
          Warning: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

---

> **💡 Pro Tip**: Start with basic monitoring and gradually add more sophisticated dashboards and alerts. Focus on the "golden signals" - latency, traffic, errors, and saturation.

*This monitoring stack provides comprehensive visibility into your home lab infrastructure with enterprise-grade observability tools.*
