---
title: "Docker Monitoring and Logging Guide"
description: "Comprehensive guide to monitoring and logging Docker containers using ELK Stack, Fluentd, Prometheus, Grafana, and Jaeger"
author: "Joseph Streeter"
ms.date: "2025-07-17"
ms.topic: "how-to"
ms.service: "containers"
keywords: ["Docker", "Monitoring", "Logging", "Prometheus", "Grafana", "ELK Stack", "Fluentd", "Containers"]
---

Proper monitoring and logging are essential for maintaining healthy containerized applications. Docker Compose provides several approaches to collect, aggregate, and analyze logs and metrics. This guide covers various monitoring and logging strategies for Docker environments.

## Logging Configuration

Docker provides several logging drivers that can be configured in your Docker Compose files. The right logging approach depends on your application's scale, complexity, and monitoring requirements.

### Basic Logging Setup

The simplest way to configure logging is using the built-in json-file driver with rotation settings to prevent log files from consuming too much disk space:

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    ports:
      - "80:80"

  app:
    build: .
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://localhost:514"
        tag: "myapp"
```

### Centralized Logging with ELK Stack

For production environments, the ELK Stack (Elasticsearch, Logstash, Kibana) provides a robust centralized logging solution. This setup allows you to collect logs from multiple containers and services, parse them, and visualize them through a web interface:

```yaml
# docker-compose.logging.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - logging

  logstash:
    image: docker.elastic.co/logstash/logstash:7.14.0
    volumes:
      - ./logstash/config:/usr/share/logstash/pipeline
    ports:
      - "5000:5000"
    depends_on:
      - elasticsearch
    networks:
      - logging

  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - logging

  # Application services with logging
  web:
    image: nginx:alpine
    logging:
      driver: "gelf"
      options:
        gelf-address: "udp://localhost:12201"
        tag: "nginx"
    depends_on:
      - logstash
    networks:
      - app
      - logging

  app:
    build: .
    logging:
      driver: "gelf"
      options:
        gelf-address: "udp://localhost:12201"
        tag: "app"
    depends_on:
      - logstash
    networks:
      - app
      - logging

volumes:
  es_data:

networks:
  app:
  logging:
```

#### Logging with Fluentd

Fluentd is a lightweight alternative to the ELK Stack for log collection and processing. It can collect logs from various sources, process them, and forward them to multiple destinations like Elasticsearch, S3, or cloud logging services:

```yaml
# docker-compose.fluentd.yml
version: '3.8'

services:
  fluentd:
    build: ./fluentd
    volumes:
      - ./fluentd/conf:/fluentd/etc
      - ./logs:/var/log
    ports:
      - "24224:24224"
      - "24224:24224/udp"
    networks:
      - logging

  web:
    image: nginx:alpine
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: httpd.access
    ports:
      - "80:80"
    depends_on:
      - fluentd
    networks:
      - app
      - logging

networks:
  app:
  logging:
```

## Monitoring with Prometheus and Grafana

While logging focuses on events and messages, monitoring captures metrics and performance data over time. Prometheus and Grafana are powerful open-source tools for container monitoring.

### Complete Monitoring Stack

This stack provides comprehensive monitoring with:

- Prometheus for metrics collection and storage
- Grafana for visualization and dashboards
- Node Exporter for host-level metrics
- cAdvisor for container-level metrics

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=grafana
      - GF_USERS_ALLOW_SIGN_UP=false
    depends_on:
      - prometheus
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring

  # Your application services with metrics
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    networks:
      - app
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  app:
  monitoring:
```

### Prometheus Configuration

```yaml
# prometheus/prometheus.yml
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

  - job_name: 'nginx'
    static_configs:
      - targets: ['web:9113']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093
```

## Application Performance Monitoring (APM)

Metrics and logs provide valuable information, but for complex microservices architectures, distributed tracing helps understand request flows and identify bottlenecks.

### Jaeger for Distributed Tracing

Jaeger is an open-source distributed tracing system that helps track requests as they flow through distributed systems:

```yaml
# docker-compose.tracing.yml
version: '3.8'

services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - tracing

  # Application with tracing
  app:
    build: .
    environment:
      - JAEGER_AGENT_HOST=jaeger
      - JAEGER_AGENT_PORT=6831
      - JAEGER_SAMPLER_TYPE=const
      - JAEGER_SAMPLER_PARAM=1
    depends_on:
      - jaeger
    networks:
      - app
      - tracing

networks:
  app:
  tracing:
```

## Health Checks and Service Discovery

Docker supports built-in health checks to monitor the health of your containers. These checks help with automatic restarts, service discovery, and preventing routing to unhealthy containers.

### Advanced Health Monitoring

Health checks can be configured for various services to ensure they're responding correctly:

```yaml
# docker-compose.health.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    ports:
      - "80:80"

  db:
    image: postgres:13-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password

  redis:
    image: redis:6-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # Health check aggregator
  healthcheck:
    image: willfarrell/docker-healthcheck
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "8000:8000"
```

## Log Management Commands

Once your logging infrastructure is set up, you'll need to know how to access, filter, and manage your logs effectively.

### Useful Logging Commands

Here are essential Docker Compose commands for working with logs:

```bash
# View logs for all services
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for specific service
docker-compose logs web

# View logs with timestamps
docker-compose logs -t

# Limit log output
docker-compose logs --tail=50

# View logs since specific time
docker-compose logs --since="2024-01-01T12:00:00"

# Export logs to file
docker-compose logs > application.log

# Search logs for errors
docker-compose logs | grep -i error

# Monitor multiple services
docker-compose logs -f web db redis
```

## Monitoring Commands

In addition to dashboard-based monitoring, Docker provides CLI commands for real-time resource monitoring and troubleshooting.

### Container Resource Monitoring

Use these commands for quick insights into container performance:

```bash
# Real-time resource usage
docker stats $(docker-compose ps -q)

# Detailed container inspection
docker-compose top

# Check container health status
docker-compose ps

# Monitor specific service
docker stats container_name

# Export metrics to file
docker stats --no-stream $(docker-compose ps -q) > metrics.txt
```

## Alerting Configuration

Monitoring is only effective if you're notified when things go wrong. Alertmanager integrates with Prometheus to handle alerts and route them to the appropriate notification channels.

### Alertmanager Setup

This setup allows you to define alerting rules and notification channels:

```yaml
# docker-compose.alerting.yml
version: '3.8'

services:
  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    networks:
      - monitoring

volumes:
  alertmanager_data:

networks:
  monitoring:
    external: true
```

#### Sample Alert Rules

```yaml
# prometheus/alert_rules.yml
groups:
- name: docker_alerts
  rules:
  - alert: ContainerDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Container {{ $labels.instance }} is down"
      description: "Container {{ $labels.instance }} has been down for more than 5 minutes."

  - alert: HighMemoryUsage
    expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on {{ $labels.name }}"
      description: "Container {{ $labels.name }} is using {{ $value }}% of memory."

  - alert: HighCPUUsage
    expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.name }}"
      description: "Container {{ $labels.name }} CPU usage is above 80%."
```

## Best Practices for Monitoring and Logging

1. **Structured Logging**: Use JSON format for logs to enable better parsing
2. **Log Rotation**: Configure log rotation to prevent disk space issues
3. **Centralized Logging**: Use centralized logging solutions for production
4. **Metrics Collection**: Implement application-specific metrics
5. **Alerting**: Set up alerts for critical issues
6. **Regular Monitoring**: Monitor resource usage and performance trends
7. **Log Security**: Ensure logs don't contain sensitive information
8. **Backup Monitoring Data**: Regularly backup monitoring and logging data

This monitoring and logging setup provides comprehensive observability for your Docker Compose applications, enabling you to track performance, debug issues, and maintain high availability. By implementing these practices, you'll create a robust monitoring strategy that helps ensure the reliability and performance of your containerized applications.

## Conclusion

Setting up proper monitoring and logging for your Docker environment is a critical aspect of maintaining production-ready applications. By combining logging solutions like ELK or Fluentd with metrics-based monitoring tools like Prometheus and Grafana, you can achieve complete visibility into your application's health and performance.

Remember that the specific tools and configurations you choose should align with your application's scale, complexity, and specific needs. Start with the basics and expand your monitoring capabilities as your application grows.
