---
title: Prometheus and Grafana Configuration
description: Detailed configuration guide for Prometheus, Grafana, and monitoring components
author: Your Name
ms.author: your-email
ms.topic: configuration
ms.date: 12/30/2025
keywords: prometheus, grafana, configuration, scrape_configs, recording rules, datasources
uid: docs.infrastructure.grafana.configuration
---

This guide covers production-grade configuration for Prometheus, Grafana, and related monitoring components including service discovery, recording rules, and dashboard provisioning.

## Prometheus Configuration

### Basic Configuration Structure

Create `/etc/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s  # How frequently to scrape targets
  evaluation_interval: 15s  # How frequently to evaluate rules
  scrape_timeout: 10s  # Timeout for scraping targets
  external_labels:
    cluster: 'production'
    environment: 'prod'
    region: 'us-east-1'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager:9093'
      timeout: 10s
      api_version: v2

# Load rules once and periodically evaluate them
rule_files:
  - 'rules/alert_rules.yml'
  - 'rules/recording_rules.yml'

# Scrape configurations
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          service: 'prometheus'
          environment: 'production'

  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - 'node1.example.com:9100'
          - 'node2.example.com:9100'
          - 'node3.example.com:9100'
        labels:
          environment: 'production'
          datacenter: 'dc1'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'
        replacement: '${1}'
      - source_labels: [__address__]
        target_label: __address__
        regex: '(.+):(\d+)'
        replacement: '${1}:9100'

  - job_name: 'cadvisor'
    static_configs:
      - targets:
          - 'docker-host1:8080'
          - 'docker-host2:8080'
        labels:
          environment: 'production'

  - job_name: 'alertmanager'
    static_configs:
      - targets:
          - 'alertmanager:9093'
```

### Service Discovery Configuration

#### File-Based Service Discovery

Create `/etc/prometheus/file_sd/nodes.yml`:

```yaml
- targets:
    - '192.168.1.10:9100'
    - '192.168.1.11:9100'
    - '192.168.1.12:9100'
  labels:
    environment: 'production'
    datacenter: 'dc1'
    role: 'application-server'

- targets:
    - '192.168.1.20:9100'
    - '192.168.1.21:9100'
  labels:
    environment: 'production'
    datacenter: 'dc1'
    role: 'database-server'
```

Update `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node-exporter-file-sd'
    file_sd_configs:
      - files:
          - '/etc/prometheus/file_sd/nodes.yml'
          - '/etc/prometheus/file_sd/containers.yml'
        refresh_interval: 5m
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'
        replacement: '${1}'
```

#### DNS Service Discovery

```yaml
scrape_configs:
  - job_name: 'node-exporter-dns'
    dns_sd_configs:
      - names:
          - 'node-exporter.service.consul'
        type: 'A'
        port: 9100
        refresh_interval: 30s
```

#### Consul Service Discovery

```yaml
scrape_configs:
  - job_name: 'consul-services'
    consul_sd_configs:
      - server: 'consul.example.com:8500'
        services:
          - 'node-exporter'
          - 'application'
        tags:
          - 'production'
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: [__meta_consul_node]
        target_label: instance
      - source_labels: [__meta_consul_tags]
        target_label: tags
```

#### Kubernetes Service Discovery

```yaml
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - default
            - production
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
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name
```

### Recording Rules

Create `/etc/prometheus/rules/recording_rules.yml`:

```yaml
groups:
  - name: node_recording_rules
    interval: 30s
    rules:
      # CPU usage percentage
      - record: instance:node_cpu_utilization:rate5m
        expr: |
          100 - (
            avg by(instance) (
              irate(node_cpu_seconds_total{mode="idle"}[5m])
            ) * 100
          )

      # Memory usage percentage
      - record: instance:node_memory_utilization:ratio
        expr: |
          (
            node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
          ) / node_memory_MemTotal_bytes * 100

      # Disk usage percentage
      - record: instance:node_filesystem_utilization:ratio
        expr: |
          (
            node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs|squashfs|vfat"}
            - node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs|squashfs|vfat"}
          ) / node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs|squashfs|vfat"} * 100

      # Network receive bandwidth
      - record: instance:node_network_receive_bytes:rate5m
        expr: |
          sum by(instance) (
            rate(node_network_receive_bytes_total[5m])
          )

      # Network transmit bandwidth
      - record: instance:node_network_transmit_bytes:rate5m
        expr: |
          sum by(instance) (
            rate(node_network_transmit_bytes_total[5m])
          )

  - name: application_recording_rules
    interval: 30s
    rules:
      # HTTP request rate per service
      - record: service:http_requests:rate5m
        expr: |
          sum by(service) (
            rate(http_requests_total[5m])
          )

      # HTTP error rate per service
      - record: service:http_errors:rate5m
        expr: |
          sum by(service) (
            rate(http_requests_total{status=~"5.."}[5m])
          )

      # HTTP request duration 95th percentile
      - record: service:http_request_duration_seconds:p95
        expr: |
          histogram_quantile(0.95,
            sum by(service, le) (
              rate(http_request_duration_seconds_bucket[5m])
            )
          )

  - name: container_recording_rules
    interval: 30s
    rules:
      # Container CPU usage
      - record: container:cpu_usage:rate5m
        expr: |
          sum by(container_name, pod_name, namespace) (
            rate(container_cpu_usage_seconds_total{container!=""}[5m])
          ) * 100

      # Container memory usage
      - record: container:memory_usage:bytes
        expr: |
          sum by(container_name, pod_name, namespace) (
            container_memory_usage_bytes{container!=""}
          )

      # Container network receive
      - record: container:network_receive_bytes:rate5m
        expr: |
          sum by(container_name, pod_name, namespace) (
            rate(container_network_receive_bytes_total[5m])
          )
```

### Remote Storage Configuration

#### Thanos Configuration

```yaml
# prometheus.yml
global:
  external_labels:
    cluster: 'production'
    replica: 'replica-1'

# Add Thanos sidecar
# Command line flags for Prometheus:
# --storage.tsdb.min-block-duration=2h
# --storage.tsdb.max-block-duration=2h
# --web.enable-lifecycle
```

#### VictoriaMetrics Remote Write

```yaml
# prometheus.yml
remote_write:
  - url: http://victoriametrics:8428/api/v1/write
    queue_config:
      max_samples_per_send: 10000
      batch_send_deadline: 5s
      min_shards: 2
      max_shards: 10
      capacity: 20000
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'expensive_metric.*'
        action: drop
```

#### Cortex Remote Write

```yaml
# prometheus.yml
remote_write:
  - url: https://cortex.example.com/api/prom/push
    basic_auth:
      username: 'prometheus'
      password_file: /run/secrets/cortex_password
    queue_config:
      capacity: 10000
      max_shards: 50
      min_shards: 1
      max_samples_per_send: 5000
      batch_send_deadline: 5s
      min_backoff: 30ms
      max_backoff: 100ms
```

### Retention and Storage Configuration

```yaml
# Command line flags or docker-compose.yml
command:
  - '--storage.tsdb.retention.time=30d'  # Keep data for 30 days
  - '--storage.tsdb.retention.size=10GB'  # Or until 10GB limit
  - '--storage.tsdb.path=/prometheus'
  - '--storage.tsdb.wal-compression'  # Enable WAL compression (Prometheus 2.11+)
```

## Grafana Configuration

### Configuration File

Create `/etc/grafana/grafana.ini`:

```ini
[server]
protocol = https
http_addr = 0.0.0.0
http_port = 3000
domain = grafana.example.com
root_url = https://grafana.example.com
cert_file = /etc/grafana/ssl/cert.pem
cert_key = /etc/grafana/ssl/key.pem

[security]
admin_user = admin
admin_password = $__file{/run/secrets/grafana_admin_password}
secret_key = $__file{/run/secrets/grafana_secret_key}
disable_gravatar = true
cookie_secure = true
cookie_samesite = strict
strict_transport_security = true
x_content_type_options = true
x_xss_protection = true

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer
default_theme = dark

[auth]
disable_login_form = false
oauth_auto_login = false

[auth.basic]
enabled = true

[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true

[smtp]
enabled = true
host = smtp.gmail.com:587
user = alerts@example.com
password = $__file{/run/secrets/smtp_password}
from_address = alerts@example.com
from_name = Grafana Alerts
skip_verify = false
startTLS_policy = MandatoryStartTLS

[log]
mode = console file
level = info
filters = rendering:debug

[alerting]
enabled = true
execute_alerts = true
max_attempts = 3
min_interval_seconds = 1

[unified_alerting]
enabled = true
execute_alerts = true
evaluation_timeout = 30s
max_attempts = 3

[metrics]
enabled = true
interval_seconds = 10

[tracing.jaeger]
address = jaeger:6831
always_included_tag = cluster=production

[feature_toggles]
enable = newNavigation,publicDashboards
```

### Datasource Provisioning

Create `/etc/grafana/provisioning/datasources/prometheus.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    version: 1
    editable: false
    jsonData:
      httpMethod: POST
      timeInterval: 30s
      queryTimeout: 60s
      exemplarTraceIdDestinations:
        - name: trace_id
          datasourceUid: 'tempo'
    secureJsonData:
      httpHeaderValue1: 'Bearer ${PROMETHEUS_TOKEN}'

  - name: Prometheus-HA
    type: prometheus
    access: proxy
    url: http://prometheus-ha:9090
    version: 1
    editable: false
    jsonData:
      httpMethod: POST
      timeInterval: 30s

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    version: 1
    editable: false
    jsonData:
      maxLines: 1000

  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
    uid: tempo
    version: 1
    editable: false

  - name: Alertmanager
    type: alertmanager
    access: proxy
    url: http://alertmanager:9093
    version: 1
    editable: false
    jsonData:
      implementation: prometheus
```

### Dashboard Provisioning

Create `/etc/grafana/provisioning/dashboards/default.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/default

  - name: 'infrastructure'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/infrastructure

  - name: 'applications'
    orgId: 1
    folder: 'Applications'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/applications
```

### Alert Notification Provisioning

Create `/etc/grafana/provisioning/notifiers/default.yml`:

```yaml
apiVersion: 1

notifiers:
  - name: Email Notifications
    type: email
    uid: email-notifier
    org_id: 1
    is_default: true
    send_reminder: true
    frequency: 24h
    disable_resolve_message: false
    settings:
      addresses: 'admin@example.com;ops-team@example.com'
      singleEmail: false

  - name: Slack Alerts
    type: slack
    uid: slack-notifier
    org_id: 1
    is_default: false
    send_reminder: true
    frequency: 4h
    settings:
      url: '$__file{/run/secrets/slack_webhook_url}'
      recipient: '#alerts'
      username: 'Grafana'
      icon_emoji: ':chart_with_upwards_trend:'
      mentionChannel: 'here'
      mentionUsers: ''
      mentionGroups: ''
      token: ''

  - name: PagerDuty Critical
    type: pagerduty
    uid: pagerduty-critical
    org_id: 1
    is_default: false
    settings:
      integrationKey: '$__file{/run/secrets/pagerduty_key}'
      severity: 'critical'
      autoResolve: true
      messageInDetails: false

  - name: Microsoft Teams
    type: teams
    uid: teams-notifier
    org_id: 1
    settings:
      url: '$__file{/run/secrets/teams_webhook_url}'
```

### LDAP Configuration

Create `/etc/grafana/ldap.toml`:

```toml
[[servers]]
host = "ldap.example.com"
port = 636
use_ssl = true
start_tls = false
ssl_skip_verify = false
root_ca_cert = "/etc/grafana/ssl/ca.crt"

bind_dn = "cn=grafana,ou=services,dc=example,dc=com"
bind_password = '$__file{/run/secrets/ldap_bind_password}'

search_filter = "(uid=%s)"
search_base_dns = ["ou=users,dc=example,dc=com"]

[servers.attributes]
name = "givenName"
surname = "sn"
username = "uid"
member_of = "memberOf"
email = "mail"

[[servers.group_mappings]]
group_dn = "cn=admins,ou=groups,dc=example,dc=com"
org_role = "Admin"
grafana_admin = true

[[servers.group_mappings]]
group_dn = "cn=editors,ou=groups,dc=example,dc=com"
org_role = "Editor"

[[servers.group_mappings]]
group_dn = "cn=viewers,ou=groups,dc=example,dc=com"
org_role = "Viewer"
```

## Advanced Prometheus Configuration

### Multi-Tenancy with Relabeling

```yaml
scrape_configs:
  - job_name: 'multi-tenant-apps'
    static_configs:
      - targets: ['app1.example.com:8080']
        labels:
          tenant: 'customer-a'
      - targets: ['app2.example.com:8080']
        labels:
          tenant: 'customer-b'
    metric_relabel_configs:
      # Add tenant label to all metrics
      - source_labels: [tenant]
        target_label: tenant_id
      # Drop expensive metrics for specific tenants
      - source_labels: [__name__, tenant]
        regex: 'expensive_metric.*;customer-c'
        action: drop
```

### Blackbox Exporter Integration

Create `/etc/prometheus/blackbox.yml`:

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200, 201, 202, 204]
      method: GET
      headers:
        Accept: application/json
      fail_if_ssl: false
      fail_if_not_ssl: true
      tls_config:
        insecure_skip_verify: false

  http_post_2xx:
    prober: http
    http:
      method: POST
      headers:
        Content-Type: application/json
      body: '{"status":"check"}'

  tcp_connect:
    prober: tcp
    timeout: 5s

  icmp_check:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
```

Add to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://example.com
          - https://api.example.com
          - https://app.example.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  - job_name: 'blackbox-tcp'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
          - database.example.com:5432
          - redis.example.com:6379
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

## Configuration Validation

### Validate Prometheus Configuration

```bash
# Check configuration syntax
promtool check config /etc/prometheus/prometheus.yml

# Check rules syntax
promtool check rules /etc/prometheus/rules/*.yml

# Test rule queries
promtool test rules /etc/prometheus/tests/test_rules.yml

# Check metrics
promtool query instant http://localhost:9090 'up'

# Unit test configuration
promtool test rules /etc/prometheus/tests/*.yml
```

### Validate Grafana Configuration

```bash
# Check configuration file
grafana-cli --configOverrides cfg:default.paths.data=/var/lib/grafana admin reset-admin-password newpassword

# Validate datasource
curl -u admin:password http://localhost:3000/api/datasources

# Test dashboard provisioning
ls -la /var/lib/grafana/dashboards/
```

## Performance Tuning

### Prometheus Performance

```yaml
# Storage optimization
command:
  - '--storage.tsdb.retention.time=15d'
  - '--storage.tsdb.retention.size=50GB'
  - '--storage.tsdb.wal-compression'
  - '--storage.tsdb.min-block-duration=2h'
  - '--storage.tsdb.max-block-duration=2h'
  
# Query optimization
  - '--query.timeout=2m'
  - '--query.max-concurrency=20'
  - '--query.max-samples=50000000'
```

### Grafana Performance

```ini
[database]
type = postgres
host = postgres:5432
name = grafana
user = grafana
password = $__file{/run/secrets/postgres_password}
max_open_conn = 300
max_idle_conn = 100
conn_max_lifetime = 14400

[dataproxy]
timeout = 30
keep_alive_seconds = 30
max_idle_connections = 100
max_idle_connections_per_host = 10

[rendering]
server_url = http://renderer:8081/render
callback_url = http://grafana:3000/
```

## Configuration Best Practices

1. **Use External Labels**: Always set cluster, environment, region labels
2. **Recording Rules**: Pre-calculate expensive queries
3. **Service Discovery**: Automate target discovery instead of static configs
4. **Retention Policies**: Balance storage costs with data retention needs
5. **High Cardinality**: Avoid labels with high cardinality (user IDs, timestamps)
6. **Relabeling**: Drop unnecessary metrics early in the pipeline
7. **TLS Everywhere**: Enable TLS for all communications
8. **Secrets Management**: Never hardcode credentials
9. **Resource Limits**: Set appropriate CPU/memory limits
10. **Monitoring the Monitor**: Monitor Prometheus and Grafana themselves

## Next Steps

- Review [Security Configuration](security.md) for TLS and authentication
- Configure [Exporters](exporters.md) for additional metrics
- Set up [Alerting Rules](alerting.md) and notification channels
- Implement [High Availability](high-availability.md) architecture
- Configure [Backup and Recovery](backup-recovery.md) procedures

## References

- [Prometheus Configuration Documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Configuration Documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)
- [Recording Rules Best Practices](https://prometheus.io/docs/practices/rules/)
- [Relabeling Documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)
