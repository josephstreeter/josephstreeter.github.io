---
title: Grafana and Prometheus Monitoring
description: Comprehensive guide to setting up Grafana and Prometheus for home network monitoring with various exporters and data sources.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: monitoring
keywords: Grafana, Prometheus, monitoring, home network, node exporter, cAdvisor, UniFi
uid: docs.infrastructure.grafana.index
---

This comprehensive guide covers setting up Grafana and Prometheus to monitor a home network, including system metrics, container monitoring, and network device monitoring.

## Overview

**Grafana** is an open-source analytics and interactive visualization web application that provides charts, graphs, and alerts when connected to supported data sources.

**Prometheus** is an open-source systems monitoring and alerting toolkit that collects and stores metrics as time series data.

### Architecture

```mermaid
graph TB
    A[Prometheus Server] --> B[Grafana Dashboard]
    C[Node Exporter] --> A
    D[cAdvisor] --> A
    E[UniFi Controller] --> F[Unpoller]
    F --> A
    G[Other Exporters] --> A
    
    A --> H[Alert Manager]
    H --> I[Notifications]
```

### Key Components

- **Prometheus Server**: Collects and stores metrics
- **Grafana**: Visualizes metrics and creates dashboards
- **Node Exporter**: Exports system metrics
- **cAdvisor**: Exports container metrics
- **Unpoller**: Exports UniFi network metrics
- **Alert Manager**: Handles alerts and notifications

## Prometheus Setup

### Installation via Docker Compose

Create a `docker-compose.yml` file for your monitoring stack:

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

### Prometheus Configuration

Create a `prometheus.yml` configuration file:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'unpoller'
    static_configs:
      - targets: ['unpoller:9130']
```

## Grafana Setup

### Initial Configuration

1. **Access Grafana**: Navigate to `http://localhost:3000`
2. **Login**: Use `admin/admin` (change password on first login)
3. **Add Data Source**: Configure Prometheus as data source

### Add Prometheus Data Source

1. Navigate to **Configuration** > **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **URL**: `http://prometheus:9090`
   - **Access**: Server (default)
   - **Scrape interval**: 15s
5. Click **Save & Test**

### Import Dashboards

Popular dashboard IDs for import:

- **Node Exporter Full**: 1860
- **Docker Container & Host Metrics**: 10619
- **UniFi Poller**: 11315

## Node Exporter Setup

Node Exporter exports hardware and OS metrics for *nix systems.

### Linux Installation

1. **Create Node Exporter user and directories**:

```bash
sudo groupadd -f node_exporter
sudo useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
sudo mkdir /etc/node_exporter
sudo chown node_exporter:node_exporter /etc/node_exporter
```

1. **Download and install Node Exporter**:

```bash
# Download latest version
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz

# Extract and install
tar -zxvf node_exporter-1.9.0.linux-amd64.tar.gz
sudo cp node_exporter-1.9.0.linux-amd64/node_exporter /usr/bin/
sudo chown node_exporter:node_exporter /usr/bin/node_exporter
```

1. **Create systemd service**:

```bash
sudo tee /usr/lib/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF
```

1. **Enable and start the service**:

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

1. **Verify metrics**:

```bash
curl http://localhost:9100/metrics
```

### Docker Installation

Add to your `docker-compose.yml`:

```yaml
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
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
```

### Automated Installation Script

```bash
#!/bin/bash

# Node Exporter Installation Script
# Usage: sudo ./install_node_exporter.sh

set -e

NODE_EXPORTER_VERSION="1.9.0"
ARCH="linux-amd64"

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or with sudo" 1>&2
   exit 1
fi

echo "Installing Node Exporter v${NODE_EXPORTER_VERSION}"

# Create user and group
echo "Creating node_exporter user and group..."
groupadd -f node_exporter
useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
mkdir -p /etc/node_exporter
chown node_exporter:node_exporter /etc/node_exporter

# Download and install
echo "Downloading Node Exporter..."
cd /tmp
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
tar -zxvf "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/bin/
chown node_exporter:node_exporter /usr/bin/node_exporter

# Create systemd service
echo "Creating systemd service..."
cat << EOF > /usr/lib/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

chmod 664 /usr/lib/systemd/system/node_exporter.service

# Enable and start service
echo "Enabling and starting Node Exporter..."
systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter

# Cleanup
rm -rf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz" "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}"

echo "Node Exporter installation completed!"
echo "Access metrics at: http://localhost:9100/metrics"
```

### Node Exporter Prometheus Config

Add the following job to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node-servers'
    scrape_interval: 15s
    scrape_timeout: 10s
    static_configs:
      - targets: 
          - 'server1:9100'
          - 'server2:9100'
          - '192.168.1.100:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'
        replacement: '${1}'
```

## Container Advisor (cAdvisor)

cAdvisor provides container users an understanding of the resource usage and performance characteristics of their running containers.

### cAdvisor Docker Setup

Add to your `docker-compose.yml`:

```yaml
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    restart: unless-stopped
```

### Standalone Installation

```bash
# Pull and run cAdvisor
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  gcr.io/cadvisor/cadvisor:latest
```

### Accessing cAdvisor

- **Web Interface**: `http://localhost:8080`
- **Metrics Endpoint**: `http://localhost:8080/metrics`

### cAdvisor Prometheus Config

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'cadvisor'
    scrape_interval: 5s
    static_configs:
      - targets: ['cadvisor:8080']
```

## UniFi Monitoring with Unpoller

Unpoller exports UniFi Controller metrics to Prometheus.

### Prerequisites

1. **UniFi Controller Account**: Create a read-only user named `unpoller`
2. **Controller Access**: Ensure Prometheus can reach the controller

### Unpoller Docker Setup

Add to your `docker-compose.yml`:

```yaml
  unpoller:
    image: ghcr.io/unpoller/unpoller:latest
    container_name: unpoller
    ports:
      - "9130:9130"
    environment:
      # Disable InfluxDB
      - UP_INFLUXDB_DISABLE=true
      
      # Prometheus settings
      - UP_PROMETHEUS_HTTP_LISTEN=0.0.0.0:9130
      - UP_PROMETHEUS_NAMESPACE=unpoller
      
      # UniFi Controller settings
      - UP_UNIFI_DYNAMIC=false
      - UP_UNIFI_CONTROLLER_0_URL=https://192.168.1.1:8443
      - UP_UNIFI_CONTROLLER_0_USER=unpoller
      - UP_UNIFI_CONTROLLER_0_PASS=your-secure-password
      
      # Data collection settings
      - UP_UNIFI_CONTROLLER_0_SAVE_SITES=true
      - UP_UNIFI_CONTROLLER_0_SAVE_DPI=true
      - UP_UNIFI_CONTROLLER_0_SAVE_EVENTS=true
      - UP_UNIFI_CONTROLLER_0_SAVE_ALARMS=true
      - UP_UNIFI_CONTROLLER_0_SAVE_ANOMALIES=true
      - UP_UNIFI_CONTROLLER_0_SAVE_IDS=true
      
      # Debugging
      - UP_POLLER_DEBUG=false
    restart: unless-stopped
```

### Configuration File Method

Create `/etc/unpoller/unpoller.conf`:

```ini
[unifi]
  dynamic = false
  
  [[unifi.controller]]
    url = "https://192.168.1.1:8443"
    user = "unpoller"
    pass = "your-secure-password"
    save_sites = true
    save_dpi = true
    save_events = true
    save_alarms = true
    save_anomalies = true
    save_ids = true

[prometheus]
  http_listen = "0.0.0.0:9130"
  namespace = "unpoller"

[influxdb]
  disable = true
```

### Unpoller Prometheus Config

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'unpoller'
    scrape_interval: 30s
    static_configs:
      - targets: ['unpoller:9130']
```

## Additional Exporters

### Blackbox Exporter (Network Probing)

```yaml
  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    container_name: blackbox-exporter
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox.yml:/etc/blackbox_exporter/config.yml
    restart: unless-stopped
```

### SNMP Exporter

```yaml
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    ports:
      - "9116:9116"
    volumes:
      - ./snmp.yml:/etc/snmp_exporter/snmp.yml
    restart: unless-stopped
```

### PostgreSQL Exporter

```yaml
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    environment:
      - DATA_SOURCE_NAME=postgresql://username:password@hostname:5432/database
    restart: unless-stopped
```

## Alert Manager

### Configuration

Create `alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@yourdomain.com'
  smtp_auth_username: 'alerts@yourdomain.com'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email-notifications'

receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@yourdomain.com'
    subject: 'Prometheus Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
```

### Docker Compose

```yaml
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    restart: unless-stopped
```

## Dashboards and Visualization

### Recommended Grafana Dashboards

1. **Node Exporter Full** (ID: 1860)
   - System metrics, CPU, memory, disk, network
   
2. **Docker Container & Host Metrics** (ID: 10619)
   - Container resource usage and performance
   
3. **UniFi Poller** (ID: 11315)
   - UniFi network device metrics
   
4. **Blackbox Exporter** (ID: 13659)
   - Network connectivity and response times

### Custom Dashboard Creation

1. **Create New Dashboard**: Click **+** → **Dashboard**
2. **Add Panel**: Click **Add panel**
3. **Configure Query**: Select Prometheus data source
4. **Example Queries**:
   - CPU Usage: `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
   - Memory Usage: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
   - Disk Usage: `100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)`

## Troubleshooting

### Common Issues

**Prometheus can't scrape targets:**

```bash
# Check network connectivity
curl http://target-host:9100/metrics

# Check Prometheus logs
docker logs prometheus

# Verify configuration
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

**Grafana connection issues:**

```bash
# Check data source connectivity
# In Grafana: Configuration → Data Sources → Test

# Check Prometheus availability
curl http://prometheus:9090/api/v1/query?query=up
```

**Node Exporter service issues:**

```bash
# Check service status
sudo systemctl status node_exporter

# Check logs
sudo journalctl -u node_exporter -f

# Restart service
sudo systemctl restart node_exporter
```

### Performance Optimization

**Prometheus Storage:**

```yaml
# Add to prometheus command
- '--storage.tsdb.retention.time=30d'
- '--storage.tsdb.retention.size=10GB'
```

**Grafana Performance:**

```yaml
# Environment variables
- GF_RENDERING_SERVER_URL=http://renderer:8081/render
- GF_RENDERING_CALLBACK_URL=http://grafana:3000/
```

## Security Considerations

### Authentication

**Grafana:**

- Change default admin password
- Enable LDAP/OAuth integration
- Set up user roles and permissions

**Prometheus:**

- Enable basic authentication
- Use reverse proxy with SSL
- Implement IP whitelisting

### Network Security

```yaml
# Docker network isolation
networks:
  monitoring:
    driver: bridge
    internal: true
  web:
    driver: bridge
```

### SSL/TLS Configuration

```yaml
# Nginx reverse proxy
server {
    listen 443 ssl;
    server_name grafana.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://grafana:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Best Practices

### Monitoring Strategy

1. **Start Simple**: Begin with basic system metrics
2. **Gradual Expansion**: Add more exporters as needed
3. **Meaningful Alerts**: Avoid alert fatigue
4. **Regular Maintenance**: Keep exporters updated
5. **Documentation**: Document custom dashboards and alerts

### Performance

1. **Scrape Intervals**: Balance between data granularity and performance
2. **Retention Policies**: Set appropriate data retention
3. **Resource Limits**: Monitor Prometheus resource usage
4. **Query Optimization**: Use efficient PromQL queries

### Backup and Recovery

```bash
# Backup Prometheus data
docker exec prometheus tar -czf - /prometheus > prometheus-backup.tar.gz

# Backup Grafana data
docker exec grafana tar -czf - /var/lib/grafana > grafana-backup.tar.gz
```

This comprehensive guide provides a solid foundation for monitoring your home network with Grafana and Prometheus. Start with the basic setup and gradually add more monitoring components as needed.
