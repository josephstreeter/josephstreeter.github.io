---
uid: misc.homeassistant.deployment
title: Home Assistant Stack Deployment Guide
description: Complete deployment guide for Home Assistant, Mosquitto MQTT, and Zigbee2MQTT
keywords: [home assistant, deployment, docker, docker-compose, mosquitto, zigbee2mqtt, installation]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Stack Deployment Guide

This guide covers the complete deployment of a Home Assistant stack including Home Assistant Core, Mosquitto MQTT broker, and Zigbee2MQTT for Zigbee device integration.

### Complete Stack Overview

The complete Home Assistant ecosystem consists of:

1. **Home Assistant Core**: Main automation platform
2. **Mosquitto MQTT**: Message broker for device communication
3. **Zigbee2MQTT**: Zigbee device integration bridge
4. **PostgreSQL**: Database for long-term storage (optional)
5. **Nginx**: Reverse proxy for secure external access (optional)

## Quick Start - Complete Stack

### Prerequisites

```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login to apply group changes
```

### Directory Structure Setup

```bash
# Create complete project structure
mkdir -p homeassistant-stack/{homeassistant/config,mosquitto/{config,data,logs},zigbee2mqtt/data,postgres/data,nginx/{conf,ssl},backups}
cd homeassistant-stack

# Set proper permissions
chmod 755 homeassistant/config
chmod 755 mosquitto/{config,data,logs}
chmod 755 zigbee2mqtt/data
chmod 700 postgres/data
chmod 755 nginx/{conf,ssl}
chmod 755 backups
```

### Complete Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Home Assistant Core
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    restart: unless-stopped
    privileged: true
    environment:
      - TZ=America/Chicago
    volumes:
      - ./homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
      - /dev:/dev
    ports:
      - "8123:8123"
    networks:
      - homeassistant
    depends_on:
      - mosquitto
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  # Mosquitto MQTT Broker
  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    restart: unless-stopped
    ports:
      - "1883:1883"    # MQTT
      - "9001:9001"    # WebSockets
      - "8883:8883"    # MQTT SSL
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/logs:/mosquitto/log
    networks:
      - homeassistant
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m test"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Zigbee2MQTT
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:latest
    restart: unless-stopped
    volumes:
      - ./zigbee2mqtt/data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      - "8080:8080"    # Web interface
    environment:
      - TZ=America/Chicago
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # Adjust to your Zigbee adapter
    networks:
      - homeassistant
    depends_on:
      - mosquitto
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

  # PostgreSQL Database
  postgres:
    container_name: homeassistant_postgres
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=homeassistant
      - POSTGRES_USER=homeassistant
      - POSTGRES_PASSWORD=your_secure_password_here
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
    networks:
      - homeassistant
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U homeassistant"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Nginx Reverse Proxy
  nginx:
    container_name: homeassistant_nginx
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    networks:
      - homeassistant
    depends_on:
      - homeassistant
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backup Service
  backup:
    container_name: homeassistant_backup
    image: offen/docker-volume-backup:v2
    restart: unless-stopped
    environment:
      - BACKUP_CRON_EXPRESSION=0 2 * * *  # Daily at 2 AM
      - BACKUP_FILENAME=homeassistant-stack-%Y%m%d-%H%M%S.tar.gz
      - BACKUP_RETENTION_DAYS=30
    volumes:
      - ./homeassistant/config:/backup/homeassistant:ro
      - ./mosquitto:/backup/mosquitto:ro
      - ./zigbee2mqtt/data:/backup/zigbee2mqtt:ro
      - ./postgres/data:/backup/postgres:ro
      - ./backups:/archive

networks:
  homeassistant:
    driver: bridge

volumes:
  homeassistant_config:
  mosquitto_config:
  mosquitto_data:
  mosquitto_logs:
  zigbee2mqtt_data:
  postgres_data:
```

## Service Configuration

### Mosquitto MQTT Configuration

Create `mosquitto/config/mosquitto.conf`:

```conf
# Network settings
listener 1883
protocol mqtt

listener 9001
protocol websockets

# SSL/TLS listener (optional)
listener 8883
protocol mqtt
cafile /mosquitto/config/ca.crt
certfile /mosquitto/config/server.crt
keyfile /mosquitto/config/server.key

# Security settings
allow_anonymous false
password_file /mosquitto/config/passwd

# Persistence
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information
log_timestamp true

# Connection limits
max_connections 1000
max_inflight_messages 20
max_queued_messages 200

# Security
acl_file /mosquitto/config/acl
```

Create MQTT users:

```bash
# Create password file
docker exec mosquitto mosquitto_passwd -c /mosquitto/config/passwd homeassistant
docker exec mosquitto mosquitto_passwd /mosquitto/config/passwd zigbee2mqtt
```

Create ACL file `mosquitto/config/acl`:

```text
# Home Assistant permissions
user homeassistant
topic readwrite #

# Zigbee2MQTT permissions
user zigbee2mqtt
topic readwrite zigbee2mqtt/#
topic readwrite homeassistant/#
```

### Zigbee2MQTT Configuration

Create `zigbee2mqtt/data/configuration.yaml`:

```yaml
# Home Assistant integration
homeassistant: true

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
  user: zigbee2mqtt
  password: your_zigbee2mqtt_password

# Serial port settings
serial:
  port: /dev/ttyUSB0  # Adjust to your adapter
  adapter: auto

# Web interface
frontend:
  port: 8080
  host: 0.0.0.0

# Advanced settings
advanced:
  legacy_api: false
  legacy_availability_payload: false
  log_level: info
  log_directory: /app/data/log
  log_file: zigbee2mqtt.log
  homeassistant_legacy_entity_attributes: false
  homeassistant_legacy_triggers: false
  homeassistant_status_topic: homeassistant/status

# Device options
device_options:
  legacy: false
  retain: true

# Permit join
permit_join: false

# OTA updates
ota:
  update_check_interval: 1440
  disable_automatic_update_check: false
```

### Home Assistant Configuration

Update `homeassistant/config/configuration.yaml`:

```yaml
# Basic configuration
default_config:

# Database
recorder:
  db_url: postgresql://homeassistant:your_secure_password_here@postgres:5432/homeassistant
  purge_keep_days: 30
  auto_purge: true

# MQTT
mqtt:
  broker: mosquitto
  port: 1883
  username: homeassistant
  password: your_homeassistant_password
  discovery: true
  discovery_prefix: homeassistant

# HTTP (for reverse proxy)
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12  # Docker network range
  ip_ban_enabled: true
  login_attempts_threshold: 5

# Zigbee2MQTT integration
zigbee2mqtt:
  # No additional configuration needed with MQTT discovery
```

### Nginx Reverse Proxy Configuration

Create `nginx/conf/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream homeassistant {
        server homeassistant:8123;
    }
    
    upstream zigbee2mqtt {
        server zigbee2mqtt:8080;
    }
    
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }
    
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$server_name$request_uri;
    }
    
    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name _;
        
        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        
        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
        
        # Home Assistant
        location / {
            proxy_pass http://homeassistant;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_buffering off;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
        }
        
        # Zigbee2MQTT web interface
        location /zigbee2mqtt/ {
            proxy_pass http://zigbee2mqtt/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support for Zigbee2MQTT
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
        }
    }
}
```

## Deployment Process

### 1. Initial Setup

```bash
# Clone or create project directory
cd homeassistant-stack

# Update passwords in docker-compose.yml and configuration files
# Replace all instances of 'your_secure_password_here' with actual passwords

# Identify your Zigbee adapter
ls -la /dev/tty*
# Update device mapping in docker-compose.yml if needed
```

### 2. Start Services

```bash
# Start all services
docker-compose up -d

# Monitor startup
docker-compose logs -f

# Check service health
docker-compose ps
```

### 3. Initial Configuration

```bash
# Set up MQTT users (after mosquitto is running)
docker exec mosquitto mosquitto_passwd -c /mosquitto/config/passwd homeassistant
docker exec mosquitto mosquitto_passwd /mosquitto/config/passwd zigbee2mqtt

# Restart mosquitto to apply auth changes
docker-compose restart mosquitto

# Check Zigbee2MQTT logs for adapter detection
docker-compose logs zigbee2mqtt
```

### 4. Access Services

- **Home Assistant**: `http://localhost:8123` (or `https://your-domain.com`)
- **Zigbee2MQTT**: `http://localhost:8080` (or `https://your-domain.com/zigbee2mqtt/`)

## Individual Service Deployment

### Home Assistant Only

```yaml
version: '3.8'

services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    restart: unless-stopped
    privileged: true
    environment:
      - TZ=America/Chicago
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
      - /dev:/dev
    ports:
      - "8123:8123"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
```

### Mosquitto MQTT Only

```yaml
version: '3.8'

services:
  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
      - "8883:8883"
    volumes:
      - ./config:/mosquitto/config
      - ./data:/mosquitto/data
      - ./logs:/mosquitto/log
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m test"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Zigbee2MQTT Only

```yaml
version: '3.8'

services:
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:latest
    restart: unless-stopped
    volumes:
      - ./data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      - "8080:8080"
    environment:
      - TZ=America/Chicago
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Management and Maintenance

### Update Services

```bash
# Update all services
docker-compose pull
docker-compose down
docker-compose up -d

# Update specific service
docker-compose pull homeassistant
docker-compose up -d homeassistant

# Force recreation
docker-compose down
docker-compose up -d --force-recreate
```

### Backup and Restore

```bash
# Manual backup
docker-compose exec backup /backup.sh

# Restore from backup
docker-compose down
tar -xzf backups/homeassistant-stack-20241120-020000.tar.gz -C ./
docker-compose up -d
```

### Monitoring and Logs

```bash
# View all logs
docker-compose logs

# Follow specific service logs
docker-compose logs -f homeassistant
docker-compose logs -f mosquitto
docker-compose logs -f zigbee2mqtt

# Check container health
docker-compose ps
docker inspect homeassistant | grep Health

# Resource usage
docker stats
```

### Troubleshooting

```bash
# Check network connectivity
docker-compose exec homeassistant ping mosquitto
docker-compose exec zigbee2mqtt ping mosquitto

# Test MQTT connectivity
docker-compose exec homeassistant mosquitto_pub -h mosquitto -t test -m "hello"
docker-compose exec homeassistant mosquitto_sub -h mosquitto -t test

# Check Zigbee adapter
docker-compose exec zigbee2mqtt ls -la /dev/ttyUSB*

# Restart individual services
docker-compose restart homeassistant
docker-compose restart mosquitto
docker-compose restart zigbee2mqtt
```

## Security Considerations

### MQTT Security

```bash
# Generate SSL certificates for MQTT
cd mosquitto/config
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650
```

### Network Security

```yaml
# Add to docker-compose.yml for network isolation
networks:
  homeassistant:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  database:
    driver: bridge
    internal: true  # No external access
```

### Access Control

```yaml
# Home Assistant security settings
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.20.0.0/16
  ip_ban_enabled: true
  login_attempts_threshold: 3
  cors_allowed_origins:
    - https://your-domain.com
```

This comprehensive deployment guide provides everything needed to deploy a complete Home Assistant stack with MQTT and Zigbee integration in a production-ready containerized environment.
