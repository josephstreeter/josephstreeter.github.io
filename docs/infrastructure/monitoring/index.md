---
title: "Infrastructure Monitoring"
description: "Comprehensive infrastructure monitoring, alerting, and observability solutions"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Infrastructure Monitoring

Infrastructure monitoring is essential for maintaining system reliability, performance, and availability. This guide covers monitoring solutions from basic system metrics to advanced observability platforms.

## Overview

Effective infrastructure monitoring provides:

- **Real-time visibility** into system health and performance
- **Proactive alerting** for potential issues before they become problems  
- **Historical data** for capacity planning and trend analysis
- **Root cause analysis** capabilities for faster incident resolution
- **Compliance reporting** for regulatory requirements

## Monitoring Stack Components

### Metrics Collection

- **System Metrics**: CPU, memory, disk, network utilization
- **Application Metrics**: Response times, error rates, throughput
- **Custom Metrics**: Business-specific measurements
- **Infrastructure Metrics**: Database, web server, load balancer performance

### Time Series Databases

- **Prometheus** - Open-source monitoring and alerting toolkit
- **InfluxDB** - Purpose-built time series database
- **Grafana Cloud** - Managed observability platform
- **Azure Monitor** - Cloud-native monitoring solution

### Visualization and Dashboards

- **Grafana** - Feature-rich visualization and analytics platform
- **Kibana** - Data visualization for Elasticsearch
- **Azure Monitor Workbooks** - Interactive reports and dashboards
- **Custom Dashboards** - Purpose-built monitoring interfaces

## Prometheus Monitoring

### Prometheus Setup

Prometheus is the de facto standard for metrics collection in modern infrastructure:

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

  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093
```

### Node Exporter for System Metrics

```bash
# Install and run node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
./node_exporter
```

### Docker Container Monitoring

```yaml
# docker-compose.yml for monitoring stack
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
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

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

volumes:
  prometheus_data:
  grafana_data:
```

## Grafana Dashboards

### System Overview Dashboard

Create comprehensive system dashboards for infrastructure monitoring:

```json
{
  "dashboard": {
    "id": null,
    "title": "Infrastructure Overview",
    "tags": ["infrastructure", "monitoring"],
    "panels": [
      {
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "refId": "A"
          }
        ]
      }
    ]
  }
}
```

### Container Monitoring Dashboard

Monitor Docker containers and Kubernetes pods:

```yaml
# Container metrics configuration
- name: container_cpu_usage
  query: rate(container_cpu_usage_seconds_total[5m])
  
- name: container_memory_usage
  query: container_memory_working_set_bytes / container_spec_memory_limit_bytes

- name: container_network_io
  query: rate(container_network_receive_bytes_total[5m])
```

## Alerting Configuration

### Prometheus Alerting Rules

```yaml
# alert_rules.yml
groups:
- name: infrastructure_alerts
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for more than 5 minutes"

  - alert: HighMemoryUsage
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 85% for more than 5 minutes"

  - alert: DiskSpaceLow
    expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Disk space is running low"
      description: "Disk usage is above 90% on {{ $labels.device }}"

  - alert: ServiceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service is down"
      description: "{{ $labels.job }} service is down"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@example.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  email_configs:
  - to: 'admin@example.com'
    subject: 'Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}

  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    title: 'Infrastructure Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

## Cloud Monitoring Solutions

### Azure Monitor

```bash
# Install Azure Monitor agent
wget https://aka.ms/azcmagent
sudo chmod +x azcmagent
sudo ./azcmagent connect --resource-group "rg-monitoring" --tenant-id "your-tenant-id"
```

### AWS CloudWatch

```yaml
# CloudWatch configuration
Resources:
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /aws/infrastructure/monitoring
      RetentionInDays: 30

  MetricFilter:
    Type: AWS::Logs::MetricFilter
    Properties:
      LogGroupName: !Ref LogGroup
      FilterPattern: "[timestamp, request_id, level=ERROR]"
      MetricTransformations:
        - MetricNamespace: "Custom/Application"
          MetricName: "ErrorCount"
          MetricValue: "1"
```

## Log Management

### Centralized Logging with ELK Stack

```yaml
# docker-compose-elk.yml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.2
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"

  logstash:
    image: docker.elastic.co/logstash/logstash:8.10.2
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"

  kibana:
    image: docker.elastic.co/kibana/kibana:8.10.2
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
```

### Fluentd for Log Collection

```yaml
# fluentd.conf
<source>
  @type tail
  path /var/log/containers/*.log
  pos_file /var/log/fluentd-containers.log.pos
  tag kubernetes.*
  format json
</source>

<match kubernetes.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  index_name kubernetes
  type_name _doc
</match>
```

## Performance Monitoring

### Application Performance Monitoring (APM)

Monitor application performance and user experience:

```yaml
# APM configuration
apm:
  enabled: true
  service_name: "my-application"
  environment: "production"
  
  instrumentation:
    - http_requests
    - database_queries
    - cache_operations
    - external_services

  sampling:
    rate: 0.1  # 10% sampling rate
    
  alerts:
    response_time_threshold: 500ms
    error_rate_threshold: 5%
```

### Database Monitoring

```sql
-- Database performance queries
SELECT 
    query,
    mean_time,
    calls,
    total_time
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
```

## Container and Kubernetes Monitoring

### Kubernetes Monitoring Stack

```yaml
# monitoring-namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
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
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
```

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
   # Check metric cardinality
   curl http://localhost:9090/api/v1/label/__name__/values | jq '.data | length'
   ```

2. **Missing metrics**

   ```bash
   # Verify scrape targets
   curl http://localhost:9090/api/v1/targets
   ```

3. **Alert fatigue**

   ```yaml
   # Review alert frequency
   - alert: HighAlertFrequency
     expr: increase(prometheus_notifications_total[1h]) > 10
   ```

### Performance Optimization

```yaml
# Prometheus optimization
global:
  scrape_interval: 30s       # Increase interval for less critical metrics
  evaluation_interval: 30s   # Match scrape interval

storage:
  tsdb:
    retention.time: 30d      # Adjust retention based on needs
    retention.size: 10GB     # Set size limits
```

## Related Documentation

- **[Grafana Configuration](../grafana/index.md)** - Dashboard and visualization setup
- **[Container Monitoring](../containers/docker/monitoring.md)** - Docker-specific monitoring
- **[Kubernetes Monitoring](../containers/kubernetes/monitoring.md)** - K8s cluster monitoring
- **[Infrastructure Security](../security/index.md)** - Securing monitoring infrastructure

---

*This guide provides comprehensive coverage of infrastructure monitoring from basic system metrics to enterprise-scale observability solutions. Choose the tools and approaches that best fit your infrastructure requirements and operational complexity.*
