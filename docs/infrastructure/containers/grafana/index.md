---
title: "Grafana"
description: "Comprehensive guide to Grafana for monitoring, visualization, and observability in containerized environments"
category: "infrastructure"
tags: ["containers", "monitoring", "visualization", "observability", "dashboards", "grafana"]
---

## Grafana

Grafana is an open-source platform for monitoring and observability that allows you to query, visualize, alert on, and understand your metrics no matter where they are stored. It's particularly powerful in containerized environments where it can aggregate data from multiple sources and provide unified dashboards for comprehensive system monitoring.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Installation Methods](#installation-methods)
- [Configuration](#configuration)
- [Data Sources](#data-sources)
- [Dashboard Management](#dashboard-management)
- [Alerting](#alerting)
- [Security](#security)
- [Container Deployment](#container-deployment)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

Grafana serves as a centralized visualization platform that connects to various data sources to create comprehensive dashboards and monitoring solutions. In containerized environments, Grafana excels at:

- **Unified Monitoring**: Consolidating metrics from multiple container platforms
- **Real-time Visualization**: Displaying live data through customizable dashboards
- **Alerting**: Proactive notification system for critical events
- **Multi-tenancy**: Supporting multiple teams and organizations
- **Extensibility**: Plugin ecosystem for enhanced functionality

### Architecture Components

- **Grafana Server**: Core application handling UI, API, and dashboard rendering
- **Database**: Stores dashboards, users, and configuration (SQLite, MySQL, PostgreSQL)
- **Data Sources**: External systems providing metrics and logs
- **Plugins**: Extensions for additional functionality
- **Authentication**: User management and access control

## Key Features

### Visualization Capabilities

- **Multiple Panel Types**: Time series, bar charts, heatmaps, tables, stat panels
- **Interactive Dashboards**: Drill-down capabilities and dynamic filtering
- **Template Variables**: Dynamic dashboard content based on selections
- **Annotations**: Contextual information overlay on graphs
- **Alerting Integration**: Visual indicators for alert states

### Data Source Support

- **Time Series Databases**: Prometheus, InfluxDB, Graphite
- **Logging Platforms**: Elasticsearch, Loki, Splunk
- **Cloud Platforms**: CloudWatch, Azure Monitor, Google Cloud Monitoring
- **Databases**: MySQL, PostgreSQL, Microsoft SQL Server
- **Application Monitoring**: Jaeger, Zipkin, New Relic

### Advanced Features

- **Team Management**: Role-based access control
- **Dashboard Sharing**: Public dashboards and snapshot sharing
- **API Access**: Programmatic dashboard and configuration management
- **Provisioning**: Configuration as code for automated deployments
- **Plugin Ecosystem**: Extensive marketplace for additional functionality

## Installation Methods

### Docker Container (Recommended)

```bash
# Basic Grafana container
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana:latest

# With environment variables
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=your-password" \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
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
      - ./config/grafana.ini:/etc/grafana/grafana.ini
      - ./dashboards:/var/lib/grafana/dashboards
      - ./provisioning:/etc/grafana/provisioning
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-secret
              key: password
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-config
          mountPath: /etc/grafana
      volumes:
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
      - name: grafana-config
        configMap:
          name: grafana-config
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
```

### Package Manager Installation

```bash
# Ubuntu/Debian
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana

# CentOS/RHEL
sudo yum install https://dl.grafana.com/oss/release/grafana-9.0.0-1.x86_64.rpm

# Enable and start service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

## Configuration

### Main Configuration File

The primary configuration is handled through `grafana.ini`:

```ini
[default]
# Paths
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning

[server]
# Protocol (http, https, socket)
protocol = http
http_addr = 0.0.0.0
http_port = 3000
domain = localhost
root_url = %(protocol)s://%(domain)s:%(http_port)s/

[database]
type = sqlite3
host = 127.0.0.1:3306
name = grafana
user = root
password = 

[session]
provider = file
provider_config = sessions

[security]
admin_user = admin
admin_password = admin
secret_key = SW2YcwTIb9zpOOhoPsMm
disable_gravatar = false

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.anonymous]
enabled = false

[smtp]
enabled = true
host = localhost:587
user = 
password = 
from_address = admin@grafana.localhost
```

### Environment Variables

Key environment variables for container deployments:

```bash
# Security
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=secure_password
GF_SECURITY_SECRET_KEY=your_secret_key

# Server settings
GF_SERVER_HTTP_PORT=3000
GF_SERVER_DOMAIN=your-domain.com
GF_SERVER_ROOT_URL=https://your-domain.com

# Database
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=postgres:5432
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=grafana
GF_DATABASE_PASSWORD=password

# Users
GF_USERS_ALLOW_SIGN_UP=false
GF_USERS_AUTO_ASSIGN_ORG=true
GF_USERS_AUTO_ASSIGN_ORG_ROLE=Viewer

# Authentication
GF_AUTH_ANONYMOUS_ENABLED=false
GF_AUTH_DISABLE_LOGIN_FORM=false
```

### Provisioning

Grafana supports configuration as code through provisioning:

#### Data Sources Provisioning

Create `/etc/grafana/provisioning/datasources/datasources.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    database: monitoring
    user: grafana
    password: password
    editable: false
```

#### Dashboard Provisioning

Create `/etc/grafana/provisioning/dashboards/dashboards.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

## Data Sources

### Prometheus Integration

Prometheus is the most common data source for container monitoring:

```yaml
# Prometheus configuration
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://prometheus:9090
  isDefault: true
  jsonData:
    timeInterval: "30s"
    httpMethod: "POST"
    queryTimeout: "60s"
```

### Common Queries for Container Monitoring

```promql
# CPU Usage by Container
sum(rate(container_cpu_usage_seconds_total[5m])) by (name)

# Memory Usage by Container
sum(container_memory_usage_bytes) by (name)

# Network Traffic
sum(rate(container_network_receive_bytes_total[5m])) by (name)

# Disk I/O
sum(rate(container_fs_reads_bytes_total[5m])) by (name)
```

### InfluxDB Integration

For time-series data storage:

```yaml
- name: InfluxDB
  type: influxdb
  url: http://influxdb:8086
  database: monitoring
  user: grafana
  password: ${INFLUXDB_PASSWORD}
  jsonData:
    timeInterval: "15s"
    httpMode: "GET"
```

### Elasticsearch/Loki for Logs

```yaml
- name: Loki
  type: loki
  url: http://loki:3100
  jsonData:
    maxLines: 1000
    derivedFields:
      - name: "traceID"
        matcherRegex: "trace_id=(\\w+)"
        url: "${__value.raw}"
```

## Dashboard Management

### Dashboard Best Practices

1. **Consistent Layout**: Use standard panel sizes and arrangements
2. **Meaningful Names**: Clear titles and descriptions for all panels
3. **Appropriate Time Ranges**: Set sensible default time windows
4. **Template Variables**: Use variables for dynamic filtering
5. **Alert Integration**: Include alert status indicators

### Template Variables

```javascript
// Query variable for container selection
label_values(container_cpu_usage_seconds_total, name)

// Custom variable for environment
production,staging,development

// Ad-hoc filters for dynamic exploration
```

### Panel Configuration Examples

#### Time Series Panel

```json
{
  "targets": [
    {
      "expr": "rate(container_cpu_usage_seconds_total{name=~\"$container\"}[5m])",
      "legendFormat": "{{name}}",
      "refId": "A"
    }
  ],
  "title": "Container CPU Usage",
  "type": "timeseries",
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100
    }
  }
}
```

#### Stat Panel

```json
{
  "targets": [
    {
      "expr": "count(up{job=\"node-exporter\"})",
      "refId": "A"
    }
  ],
  "title": "Active Nodes",
  "type": "stat",
  "options": {
    "colorMode": "background",
    "graphMode": "area",
    "justifyMode": "center"
  }
}
```

### Dashboard Organization

- **Folders**: Organize dashboards by team, environment, or service
- **Tags**: Use consistent tagging for easy discovery
- **Permissions**: Set appropriate access levels
- **Favorites**: Star frequently used dashboards
- **Search**: Implement searchable naming conventions

## Alerting

### Alert Rule Configuration

Grafana's unified alerting system provides comprehensive monitoring:

```yaml
# Example alert rule
groups:
  - name: container_alerts
    rules:
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
          service: "{{ $labels.name }}"
        annotations:
          summary: "High CPU usage detected"
          description: "Container {{ $labels.name }} CPU usage is above 80%"
```

### Notification Channels

#### Slack Integration

```json
{
  "type": "slack",
  "settings": {
    "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "channel": "#alerts",
    "username": "Grafana",
    "title": "Alert: {{ .GroupLabels.alertname }}",
    "text": "{{ .CommonAnnotations.description }}"
  }
}
```

#### Email Notifications

```json
{
  "type": "email",
  "settings": {
    "addresses": "admin@company.com;ops@company.com",
    "subject": "Grafana Alert: {{ .GroupLabels.alertname }}",
    "message": "{{ .CommonAnnotations.description }}"
  }
}
```

#### Webhook Integration

```json
{
  "type": "webhook",
  "settings": {
    "url": "https://your-webhook-endpoint.com/alerts",
    "httpMethod": "POST",
    "maxAlerts": 10
  }
}
```

### Alert Rule Best Practices

1. **Meaningful Thresholds**: Set realistic alert thresholds
2. **Appropriate Timing**: Use proper evaluation intervals
3. **Clear Labels**: Include relevant context in alert labels
4. **Escalation Paths**: Define different severity levels
5. **Documentation**: Provide runbook links in annotations

## Security

### Authentication Methods

#### Local Authentication

```ini
[auth]
disable_login_form = false

[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Viewer
```

#### LDAP Integration

```ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
```

LDAP configuration (`/etc/grafana/ldap.toml`):

```toml
[[servers]]
host = "ldap.company.com"
port = 389
use_ssl = false
start_tls = false
ssl_skip_verify = false
bind_dn = "cn=grafana,ou=services,dc=company,dc=com"
bind_password = 'password'
search_filter = "(uid=%s)"
search_base_dns = ["ou=users,dc=company,dc=com"]

[servers.attributes]
name = "givenName"
surname = "sn"
username = "uid"
member_of = "memberOf"
email = "email"
```

#### OAuth Integration

```ini
[auth.google]
enabled = true
client_id = your_google_client_id
client_secret = your_google_client_secret
scopes = https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email
auth_url = https://accounts.google.com/o/oauth2/auth
token_url = https://accounts.google.com/o/oauth2/token
allowed_domains = company.com
```

### Role-Based Access Control

```yaml
# Team permissions
teams:
  - name: "Infrastructure Team"
    permissions:
      - action: "dashboards:read"
        scope: "dashboards:*"
      - action: "dashboards:write"
        scope: "folders:infrastructure:*"

  - name: "Development Team"
    permissions:
      - action: "dashboards:read"
        scope: "dashboards:*"
      - action: "dashboards:write"
        scope: "folders:applications:*"
```

### Security Best Practices

1. **Change Default Credentials**: Never use default admin/admin
2. **Use HTTPS**: Enable TLS for production deployments
3. **Regular Updates**: Keep Grafana updated with security patches
4. **Access Control**: Implement least-privilege access
5. **Network Security**: Restrict network access appropriately
6. **Audit Logging**: Enable and monitor audit logs

## Container Deployment

### Complete Monitoring Stack

Docker Compose example with Prometheus, Grafana, and supporting services:

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
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
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

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_DOMAIN=localhost
      - GF_SMTP_ENABLED=true
      - GF_SMTP_HOST=smtp.gmail.com:587
      - GF_SMTP_USER=${SMTP_USER}
      - GF_SMTP_PASSWORD=${SMTP_PASSWORD}
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    depends_on:
      - prometheus
    networks:
      - monitoring
    restart: unless-stopped

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
      - monitoring
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail/promtail-config.yaml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  prometheus-data:
  grafana-data:
  loki-data:

networks:
  monitoring:
    driver: bridge
```

### Kubernetes Deployment with Helm

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana with custom values
helm install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --set adminPassword=your-secure-password \
  --set service.type=LoadBalancer \
  --set persistence.enabled=true \
  --set persistence.size=10Gi
```

Custom values file (`grafana-values.yaml`):

```yaml
adminUser: admin
adminPassword: your-secure-password

service:
  type: LoadBalancer
  port: 80
  targetPort: 3000

persistence:
  enabled: true
  type: pvc
  size: 10Gi
  storageClassName: fast-ssd

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server:80
      access: proxy
      isDefault: true

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    node-exporter:
      gnetId: 1860
      revision: 27
      datasource: Prometheus
```

## Best Practices

### Dashboard Design

1. **Consistent Color Schemes**: Use organization-standard colors
2. **Logical Grouping**: Group related metrics together
3. **Appropriate Visualizations**: Choose the right panel type for data
4. **Performance Optimization**: Limit query complexity and panel count
5. **Responsive Design**: Ensure dashboards work on different screen sizes

### Data Source Management

1. **Connection Pooling**: Configure appropriate connection limits
2. **Query Optimization**: Use efficient queries to reduce load
3. **Caching**: Enable appropriate caching mechanisms
4. **Backup Strategies**: Regular backup of data source configurations
5. **Monitoring**: Monitor data source health and performance

### Operational Excellence

1. **Version Control**: Store dashboard JSON in version control
2. **Testing**: Test dashboard changes in staging environments
3. **Documentation**: Maintain documentation for custom dashboards
4. **Standardization**: Use consistent naming conventions
5. **Training**: Provide user training and documentation

### Performance Optimization

```yaml
# Grafana performance settings
[database]
# Connection pool settings
max_idle_conn = 2
max_open_conn = 14
conn_max_lifetime = 14400

[session]
# Session provider optimization
provider = memory
provider_config = 

[caching]
# Enable query result caching
enabled = true
ttl = 300
```

### High Availability Setup

```yaml
# Load balancer configuration for HA Grafana
version: '3.8'
services:
  grafana-1:
    image: grafana/grafana:latest
    environment:
      - GF_DATABASE_TYPE=postgres
      - GF_DATABASE_HOST=postgres:5432
      - GF_DATABASE_NAME=grafana
    volumes:
      - ./grafana/config:/etc/grafana
    networks:
      - grafana-ha

  grafana-2:
    image: grafana/grafana:latest
    environment:
      - GF_DATABASE_TYPE=postgres
      - GF_DATABASE_HOST=postgres:5432
      - GF_DATABASE_NAME=grafana
    volumes:
      - ./grafana/config:/etc/grafana
    networks:
      - grafana-ha

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - grafana-1
      - grafana-2
    networks:
      - grafana-ha
```

## Troubleshooting

### Common Issues and Solutions

#### Dashboard Not Loading

```bash
# Check Grafana logs
docker logs grafana

# Check data source connectivity
curl -H "Authorization: Bearer <api-key>" \
  http://grafana:3000/api/datasources/proxy/1/api/v1/query?query=up

# Verify database connectivity
docker exec grafana grafana-cli admin data-migration --config /etc/grafana/grafana.ini
```

#### Performance Issues

```bash
# Monitor Grafana metrics
curl http://grafana:3000/metrics

# Check query performance
tail -f /var/log/grafana/grafana.log | grep "query took"

# Database connection monitoring
SELECT * FROM pg_stat_activity WHERE application_name = 'grafana';
```

#### Authentication Problems

```bash
# Reset admin password
docker exec -it grafana grafana-cli admin reset-admin-password newpassword

# Check LDAP configuration
docker exec grafana grafana-cli admin ldap-test

# Verify user permissions
curl -H "Authorization: Bearer <api-key>" \
  http://grafana:3000/api/user
```

### Monitoring Grafana Health

```yaml
# Health check endpoint monitoring
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Log Analysis

```bash
# Enable debug logging
[log]
level = debug
mode = console file

# Important log patterns to monitor
grep -E "(error|Error|ERROR)" /var/log/grafana/grafana.log
grep -E "(datasource|query)" /var/log/grafana/grafana.log
grep -E "(auth|login)" /var/log/grafana/grafana.log
```

### Backup and Recovery

```bash
# Backup Grafana database
docker exec postgres pg_dump -U grafana grafana > grafana_backup.sql

# Backup dashboards via API
curl -H "Authorization: Bearer <api-key>" \
  http://grafana:3000/api/search?type=dash-db \
  | jq -r '.[].uri' \
  | xargs -I {} curl -H "Authorization: Bearer <api-key>" \
    http://grafana:3000/api/dashboards/{} > dashboards_backup.json

# Restore dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <api-key>" \
  -d @dashboard.json \
  http://grafana:3000/api/dashboards/db
```

## Resources

### Official Documentation

- [Grafana Official Documentation](https://grafana.com/docs/)
- [Grafana API Documentation](https://grafana.com/docs/grafana/latest/http_api/)
- [Grafana Plugin Development](https://grafana.com/docs/grafana/latest/developers/plugins/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Container Resources

- [Grafana Docker Hub](https://hub.docker.com/r/grafana/grafana/)
- [Grafana Helm Charts](https://github.com/grafana/helm-charts)
- [Grafana Kubernetes Operator](https://github.com/grafana-operator/grafana-operator)

### Community and Learning

- [Grafana Community](https://community.grafana.com/)
- [Grafana Labs Blog](https://grafana.com/blog/)
- [Awesome Grafana](https://github.com/rtomayko/awesome-grafana)
- [Grafana Tutorials](https://grafana.com/tutorials/)

### Dashboard Libraries

- [Grafana Dashboard Repository](https://grafana.com/grafana/dashboards/)
- [Prometheus Node Exporter Dashboard](https://grafana.com/grafana/dashboards/1860)
- [Kubernetes Cluster Monitoring](https://grafana.com/grafana/dashboards/7249)
- [Docker Container Monitoring](https://grafana.com/grafana/dashboards/193)

### Integration Examples

- [Grafana + Prometheus](https://prometheus.io/docs/visualization/grafana/)
- [Grafana + InfluxDB](https://docs.influxdata.com/influxdb/v2.0/tools/grafana/)
- [Grafana + Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/monitoring-with-grafana.html)
- [Grafana + Jaeger](https://www.jaegertracing.io/docs/1.21/getting-started/#grafana)

### Best Practice Guides

- [Dashboard Design Best Practices](https://grafana.com/docs/grafana/latest/best-practices/dashboard-design/)
- [Alerting Best Practices](https://grafana.com/docs/grafana/latest/alerting/best-practices/)
- [Performance Optimization](https://grafana.com/docs/grafana/latest/administration/configuration/#performance)
- [Security Hardening](https://grafana.com/docs/grafana/latest/administration/security/)
