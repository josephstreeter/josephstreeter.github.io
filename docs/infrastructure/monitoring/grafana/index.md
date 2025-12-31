---
title: Grafana and Prometheus Monitoring Stack
description: Production-ready guide to deploying Grafana and Prometheus for comprehensive infrastructure monitoring with security, high availability, and automation.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 12/30/2025
ms.topic: architecture
ms.service: monitoring
keywords: Grafana, Prometheus, monitoring, observability, metrics, alerting, high availability, security
uid: docs.infrastructure.grafana.index
---

This guide covers deploying a production-ready monitoring stack with Grafana and Prometheus, including system metrics, container monitoring, network device monitoring, alerting, and high availability.

## Overview

Grafana and Prometheus form a powerful open-source monitoring solution that provides comprehensive observability for infrastructure, applications, and services.

### Why This Stack?

- **Open Source**: No licensing costs, community-driven development
- **Scalable**: Handles millions of time-series metrics efficiently
- **Flexible**: Extensive ecosystem of exporters and integrations
- **Powerful Query Language**: PromQL for complex metric analysis
- **Active Community**: Large community, extensive documentation
- **Cloud Native**: Kubernetes-native with Helm charts and operators

### Key Components

1. **Prometheus**: Time-series database and monitoring system
2. **Grafana**: Visualization and dashboarding platform
3. **Alertmanager**: Alert routing and notification management
4. **Node Exporter**: System metrics collection (CPU, memory, disk, network)
5. **cAdvisor**: Container metrics and resource usage
6. **Blackbox Exporter**: Endpoint monitoring and network probing
7. **Exporters**: Application-specific and database metrics
8. **Thanos/Cortex**: Long-term storage and high availability (optional)

### Production Considerations

- **High Availability**: Deploy multiple Prometheus instances with Thanos or federation
- **Security**: Implement TLS/mTLS, authentication, and secrets management
- **Scalability**: Use remote storage, recording rules, and efficient scrape configs
- **Backup**: Automated backup procedures for Prometheus and Grafana data
- **Monitoring**: Monitor the monitoring stack itself with self-monitoring
- **Performance**: Optimize retention, cardinality, and query performance

## Quick Start

```bash
# Clone example configuration
git clone https://github.com/example/prometheus-stack-example
cd prometheus-stack-example

# Review and customize .env file
cp .env.example .env
vim .env

# Deploy stack
docker-compose up -d

# Access services
# Grafana: http://localhost:3000 (see .env for credentials)
# Prometheus: http://localhost:9090
# Alertmanager: http://localhost:9093
```

> **Warning**: This quick start uses default configurations unsuitable for production. Follow the security guide before exposing to networks.

## Documentation Structure

For comprehensive configuration details, see:

- **[Installation Guide](installation.md)**: Docker Compose setup, native installation, secrets management
- **[Configuration Guide](configuration.md)**: Prometheus scrape configs, service discovery, recording rules, Grafana provisioning
- **[Security Configuration](security.md)**: TLS/mTLS, authentication, secrets management, network security
- **[Exporters Guide](exporters.md)**: Node Exporter, cAdvisor, Blackbox, database exporters, custom metrics
- **[Alerting Guide](alerting.md)**: Alert rules, Alertmanager, notification channels, runbooks
- **[High Availability](high-availability.md)**: HA architecture, Thanos, Grafana clustering, federation
- **[Backup and Recovery](backup-recovery.md)**: Automated backups, restore procedures, disaster recovery

## Quick Example: Node Exporter

Basic Node Exporter installation:

```bash
# Download and install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -zxvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

# Create service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

Add to Prometheus configuration:

```yaml
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
```

## Recommended Grafana Dashboards

Popular dashboards for import:

1. **Node Exporter Full** (ID: 1860) - System metrics
2. **Docker Container & Host Metrics** (ID: 10619) - Container monitoring
3. **UniFi Poller** (ID: 11315) - UniFi network devices
4. **Blackbox Exporter** (ID: 13659) - Network probing

## Quick Troubleshooting

Check Prometheus targets:

```bash
curl http://localhost:9090/api/v1/targets
```

Verify metrics collection:

```bash
curl http://localhost:9100/metrics
```

Test Grafana connection:

```bash
curl -u admin:password http://localhost:3000/api/health
```

## Best Practices Summary

1. **Security**: Enable TLS, use strong passwords, implement authentication
2. **Performance**: Use recording rules, set appropriate retention, optimize queries
3. **Reliability**: Implement HA, set up backups, monitor the monitoring stack
4. **Alerting**: Create meaningful alerts, avoid alert fatigue, document runbooks
5. **Maintenance**: Keep components updated, review configurations regularly

For detailed information on each topic, refer to the specific guides listed above.

## Next Steps

1. **Install**: Follow the [Installation Guide](installation.md) to set up the stack
2. **Configure**: Review [Configuration Guide](configuration.md) for advanced setups
3. **Secure**: Implement recommendations from [Security Configuration](security.md)
4. **Monitor**: Add exporters using [Exporters Guide](exporters.md)
5. **Alert**: Set up alerting with [Alerting Guide](alerting.md)
6. **Scale**: Implement [High Availability](high-availability.md) for production
7. **Protect**: Configure [Backup and Recovery](backup-recovery.md) procedures

## References

- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [Grafana Official Documentation](https://grafana.com/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
