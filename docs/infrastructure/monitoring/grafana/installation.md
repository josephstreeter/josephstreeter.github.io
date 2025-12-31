---
title: Installation and Setup
description: Production-ready installation guide for Grafana and Prometheus monitoring stack
author: Your Name
ms.author: your-email
ms.topic: installation
ms.date: 12/30/2025
keywords: grafana, prometheus, installation, docker, docker-compose, monitoring
uid: docs.infrastructure.grafana.installation
---

This guide covers installing and configuring a production-ready Grafana and Prometheus monitoring stack using Docker Compose or native installation methods.

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+, or similar)
- **CPU**: Minimum 2 cores, recommended 4+ cores for production
- **Memory**: Minimum 4GB RAM, recommended 8GB+ for production
- **Disk**: Minimum 50GB, SSD recommended for Prometheus time-series database
- **Network**: Stable network connectivity for scraping targets

### Software Requirements

For Docker deployment:

- Docker Engine 20.10+
- Docker Compose 1.29+ or Docker Compose Plugin (v2)

For native deployment:

- Systemd (for service management)
- wget or curl (for downloading binaries)

## Docker Compose Installation (Recommended)

### Create Project Structure

```bash
# Create project directory
mkdir -p ~/monitoring-stack/{prometheus,grafana,alertmanager,exporters}
cd ~/monitoring-stack

# Create subdirectories for configurations
mkdir -p prometheus/rules grafana/provisioning/{datasources,dashboards,notifiers} alertmanager
```

### Create Docker Compose File

Create `docker-compose.yml` with pinned versions:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.1  # Pinned version
    container_name: prometheus
    user: "1000:1000"  # Run as non-root
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=10GB'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prometheus-data:/prometheus
    networks:
      - monitoring
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2048M
        reservations:
          cpus: '1.0'
          memory: 1024M

  grafana:
    image: grafana/grafana:10.2.3  # Pinned version
    container_name: grafana
    user: "1000:1000"  # Run as non-root
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GF_ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana_admin_password
      - GF_INSTALL_PLUGINS=
      - GF_SERVER_ROOT_URL=https://grafana.yourdomain.com
      - GF_SMTP_ENABLED=true
      - GF_SMTP_HOST=smtp.gmail.com:587
      - GF_SMTP_USER=${SMTP_USER}
      - GF_SMTP_PASSWORD_FILE=/run/secrets/smtp_password
      - GF_SMTP_FROM_ADDRESS=${SMTP_FROM:-alerts@yourdomain.com}
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_LOG_MODE=console file
      - GF_LOG_LEVEL=info
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
    secrets:
      - grafana_admin_password
      - smtp_password
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1024M
        reservations:
          cpus: '0.5'
          memory: 512M
    depends_on:
      prometheus:
        condition: service_healthy

  alertmanager:
    image: prom/alertmanager:v0.26.0  # Pinned version
    container_name: alertmanager
    user: "1000:1000"  # Run as non-root
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=https://alertmanager.yourdomain.com'
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-data:/alertmanager
    networks:
      - monitoring
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9093/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  node-exporter:
    image: prom/node-exporter:v1.7.0  # Pinned version
    container_name: node-exporter
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
      - '--collector.netclass.ignored-devices=^(veth.*|br.*|docker.*|virbr.*|lo)$$'
      - '--collector.netdev.device-exclude=^(veth.*|br.*|docker.*|virbr.*|lo)$$'
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - monitoring
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.48.1  # Pinned version
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - monitoring
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  blackbox-exporter:
    image: prom/blackbox-exporter:v0.24.0  # Pinned version
    container_name: blackbox-exporter
    ports:
      - "9115:9115"
    volumes:
      - ./exporters/blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    networks:
      - monitoring
    restart: unless-stopped
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
  alertmanager-data:
    driver: local

networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

secrets:
  grafana_admin_password:
    file: ./secrets/grafana_admin_password.txt
  smtp_password:
    file: ./secrets/smtp_password.txt
```

### Create Secrets Files

```bash
# Create secrets directory
mkdir -p secrets
chmod 700 secrets

# Create Grafana admin password (use strong password)
echo "YourSecureGrafanaPassword123!" > secrets/grafana_admin_password.txt
chmod 600 secrets/grafana_admin_password.txt

# Create SMTP password
echo "YourSMTPPassword" > secrets/smtp_password.txt
chmod 600 secrets/smtp_password.txt
```

### Create Environment File

Create `.env` file for environment variables:

```bash
# Grafana Configuration
GF_ADMIN_USER=admin

# SMTP Configuration
SMTP_USER=alerts@yourdomain.com
SMTP_FROM=alerts@yourdomain.com

# Prometheus Configuration
PROMETHEUS_RETENTION_TIME=30d
PROMETHEUS_RETENTION_SIZE=10GB
```

### Deploy the Stack

```bash
# Pull all images
docker compose pull

# Start services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

### Verify Installation

```bash
# Check Prometheus
curl http://localhost:9090/-/healthy

# Check Grafana
curl http://localhost:3000/api/health

# Check Alert Manager
curl http://localhost:9093/-/healthy

# Check Node Exporter
curl http://localhost:9100/metrics

# Check cAdvisor
curl http://localhost:8080/metrics
```

## Native Installation (Linux)

### Install Prometheus

```bash
#!/bin/bash
# install-prometheus.sh

set -e

PROMETHEUS_VERSION="2.48.1"
ARCH="linux-amd64"

# Create prometheus user
sudo groupadd -f prometheus
sudo useradd -g prometheus --no-create-home --shell /bin/false prometheus

# Create directories
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Download and install Prometheus
cd /tmp
wget "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.${ARCH}.tar.gz"
tar -zxvf "prometheus-${PROMETHEUS_VERSION}.${ARCH}.tar.gz"
cd "prometheus-${PROMETHEUS_VERSION}.${ARCH}"

# Copy binaries
sudo cp prometheus promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Copy console files
sudo cp -r consoles console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/consoles /etc/prometheus/console_libraries

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --storage.tsdb.retention.time=30d \\
  --storage.tsdb.retention.size=10GB \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries \\
  --web.listen-address=0.0.0.0:9090 \\
  --web.enable-lifecycle \\
  --web.enable-admin-api

SyslogIdentifier=prometheus
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Cleanup
rm -rf "/tmp/prometheus-${PROMETHEUS_VERSION}.${ARCH}.tar.gz" "/tmp/prometheus-${PROMETHEUS_VERSION}.${ARCH}"

echo "Prometheus ${PROMETHEUS_VERSION} installed successfully!"
echo "Access Prometheus at: http://localhost:9090"
```

### Install Grafana

```bash
#!/bin/bash
# install-grafana.sh

set -e

# Add Grafana repository (Ubuntu/Debian)
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Update and install
sudo apt-get update
sudo apt-get install -y grafana

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "Grafana installed successfully!"
echo "Access Grafana at: http://localhost:3000"
echo "Default credentials: admin/admin"
```

### Install Alertmanager

```bash
#!/bin/bash
# install-alertmanager.sh

set -e

ALERTMANAGER_VERSION="0.26.0"
ARCH="linux-amd64"

# Create alertmanager user
sudo groupadd -f alertmanager
sudo useradd -g alertmanager --no-create-home --shell /bin/false alertmanager

# Create directories
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo chown alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

# Download and install
cd /tmp
wget "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.${ARCH}.tar.gz"
tar -zxvf "alertmanager-${ALERTMANAGER_VERSION}.${ARCH}.tar.gz"
cd "alertmanager-${ALERTMANAGER_VERSION}.${ARCH}"

# Copy binaries
sudo cp alertmanager amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool

# Create systemd service
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Alertmanager
Documentation=https://prometheus.io/docs/alerting/latest/alertmanager/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \\
  --config.file=/etc/alertmanager/alertmanager.yml \\
  --storage.path=/var/lib/alertmanager \\
  --web.listen-address=0.0.0.0:9093

SyslogIdentifier=alertmanager
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Cleanup
rm -rf "/tmp/alertmanager-${ALERTMANAGER_VERSION}.${ARCH}.tar.gz" "/tmp/alertmanager-${ALERTMANAGER_VERSION}.${ARCH}"

echo "Alertmanager ${ALERTMANAGER_VERSION} installed successfully!"
echo "Access Alertmanager at: http://localhost:9093"
```

## Upgrade Procedures

### Upgrading Docker Deployments

```bash
# Backup current configuration and data
docker compose down
tar -czf monitoring-backup-$(date +%Y%m%d).tar.gz prometheus grafana alertmanager exporters

# Update image versions in docker-compose.yml
# Test configuration
docker compose config

# Pull new images
docker compose pull

# Start services
docker compose up -d

# Verify services are healthy
docker compose ps
docker compose logs
```

### Upgrading Native Installations

```bash
# Backup configuration files
sudo tar -czf /tmp/prometheus-config-backup-$(date +%Y%m%d).tar.gz /etc/prometheus

# Stop service
sudo systemctl stop prometheus

# Download new version
PROMETHEUS_VERSION="2.49.0"  # New version
wget "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

# Extract and replace binaries
tar -zxvf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/

# Verify configuration
/usr/local/bin/promtool check config /etc/prometheus/prometheus.yml

# Start service
sudo systemctl start prometheus
sudo systemctl status prometheus
```

## Post-Installation Configuration

### Configure Firewall

```bash
# UFW firewall rules
sudo ufw allow 9090/tcp comment 'Prometheus'
sudo ufw allow 3000/tcp comment 'Grafana'
sudo ufw allow 9093/tcp comment 'Alertmanager'
sudo ufw allow 9100/tcp comment 'Node Exporter'
sudo ufw reload

# For production, restrict to specific IPs
sudo ufw delete allow 9090/tcp
sudo ufw allow from 192.168.1.0/24 to any port 9090 proto tcp comment 'Prometheus internal'
```

### Initial Grafana Setup

1. Access Grafana at `http://localhost:3000`
2. Login with admin credentials
3. **Change default password immediately**
4. Configure SMTP for email notifications
5. Add Prometheus data source
6. Import initial dashboards

### Verify Monitoring Stack

```bash
# Check all services are running
docker compose ps

# Test Prometheus targets
curl http://localhost:9090/api/v1/targets

# Test Grafana API
curl -u admin:password http://localhost:3000/api/health

# Check metrics collection
curl http://localhost:9090/api/v1/query?query=up
```

## Troubleshooting Installation

### Docker Issues

```bash
# Check container logs
docker compose logs prometheus
docker compose logs grafana
docker compose logs alertmanager

# Restart individual service
docker compose restart prometheus

# Check resource usage
docker stats

# Verify network connectivity
docker compose exec prometheus ping grafana
```

### Native Installation Issues

```bash
# Check service status
sudo systemctl status prometheus
sudo systemctl status grafana-server

# View logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f

# Verify configuration
/usr/local/bin/promtool check config /etc/prometheus/prometheus.yml

# Check file permissions
ls -la /etc/prometheus
ls -la /var/lib/prometheus
```

### Common Errors

**Permission denied errors:**

```bash
# Fix ownership
sudo chown -R prometheus:prometheus /var/lib/prometheus /etc/prometheus
sudo chown -R grafana:grafana /var/lib/grafana /etc/grafana
```

**Port already in use:**

```bash
# Find process using port
sudo netstat -tulpn | grep :9090
sudo lsof -i :9090

# Kill process or change port in configuration
```

**Out of memory errors:**

```bash
# Increase Docker memory limits in docker-compose.yml
# Or reduce retention time
- '--storage.tsdb.retention.time=15d'
- '--storage.tsdb.retention.size=5GB'
```

## Next Steps

After successful installation:

1. Review [Configuration Guide](configuration.md) for detailed Prometheus and Grafana configuration
2. Set up [Security](security.md) with TLS, authentication, and secrets management
3. Configure [Exporters](exporters.md) for additional metrics collection
4. Set up [Alerting](alerting.md) with Prometheus alert rules and Alertmanager
5. Implement [High Availability](high-availability.md) for production deployments
6. Configure [Backup and Recovery](backup-recovery.md) procedures

## References

- [Prometheus Installation Documentation](https://prometheus.io/docs/prometheus/latest/installation/)
- [Grafana Installation Documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Alertmanager Installation](https://prometheus.io/docs/alerting/latest/alertmanager/)
