---
uid: misc.homeassistant.deployment.mosquitto
title: Mosquitto MQTT Deployment
description: Dedicated Mosquitto MQTT broker deployment guide
keywords: [mosquitto, mqtt, deployment, docker, broker, messaging]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Mosquitto MQTT Broker Deployment

This guide focuses specifically on deploying Mosquitto MQTT broker for Home Assistant integration and IoT device communication.

### Deployment Options

1. **Docker Container**: Recommended for most deployments
2. **Native Installation**: Direct installation on Linux systems
3. **Raspberry Pi**: Optimized for resource-constrained environments

## Docker Deployment (Recommended)

### Basic Docker Compose Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    restart: unless-stopped
    ports:
      - "1883:1883"    # MQTT
      - "9001:9001"    # WebSockets
      - "8883:8883"    # MQTT SSL
    volumes:
      - ./config:/mosquitto/config
      - ./data:/mosquitto/data
      - ./logs:/mosquitto/log
    networks:
      - mqtt_network
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m test"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  mqtt_network:
    driver: bridge
```

### Production Docker Compose

```yaml
# production-docker-compose.yml
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
      - mosquitto_config:/mosquitto/config
      - mosquitto_data:/mosquitto/data
      - mosquitto_logs:/mosquitto/log
      - ./ssl:/mosquitto/config/ssl:ro
    networks:
      - mqtt_network
    environment:
      - TZ=America/Chicago
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t health/check -m ok"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 64M
          cpus: '0.1'

  # Optional: MQTT Web Client
  mqtt-web-client:
    container_name: mqtt-web-client
    image: hivemq/hivemq-mqtt-web-client
    restart: unless-stopped
    ports:
      - "8000:80"
    networks:
      - mqtt_network
    depends_on:
      - mosquitto

volumes:
  mosquitto_config:
    driver: local
  mosquitto_data:
    driver: local
  mosquitto_logs:
    driver: local

networks:
  mqtt_network:
    driver: bridge
```

## Initial Setup

### Directory Structure

```bash
# Create directory structure
mkdir -p mosquitto/{config,data,logs,ssl}
cd mosquitto

# Set proper permissions
chmod 755 config data logs
chmod 700 ssl
```

### Configuration Files

#### Basic Configuration

Create `config/mosquitto.conf`:

```conf
# Basic Mosquitto Configuration
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_dest stdout
log_type error
log_type warning
log_type notice
log_type information
log_timestamp true

# Network settings
listener 1883
protocol mqtt
allow_anonymous false

# WebSocket support
listener 9001
protocol websockets
allow_anonymous false

# SSL/TLS listener
listener 8883
protocol mqtt
cafile /mosquitto/config/ssl/ca.crt
certfile /mosquitto/config/ssl/server.crt
keyfile /mosquitto/config/ssl/server.key
require_certificate false

# Security
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl

# Connection limits
max_connections 1000
max_keepalive 65535
max_packet_size 100

# Message limits
message_size_limit 100
```

#### Production Configuration

Create `config/mosquitto.conf` for production:

```conf
# Production Mosquitto Configuration
persistence true
persistence_location /mosquitto/data/
autosave_interval 1800
autosave_on_changes false

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice
log_timestamp true
log_facility 5

# Network settings - MQTT
listener 1883
protocol mqtt
socket_domain ipv4
allow_anonymous false

# Network settings - WebSockets
listener 9001
protocol websockets
socket_domain ipv4
allow_anonymous false

# Network settings - SSL/TLS
listener 8883
protocol mqtt
socket_domain ipv4
cafile /mosquitto/config/ssl/ca.crt
certfile /mosquitto/config/ssl/server.crt
keyfile /mosquitto/config/ssl/server.key
require_certificate false
use_identity_as_username false

# Security
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl

# Performance and limits
max_connections 1000
max_inflight_messages 20
max_queued_messages 200
max_keepalive 65535
max_packet_size 100
message_size_limit 268435456
allow_zero_length_clientid true
auto_id_prefix auto-

# Persistence
persistence_file mosquitto.db
```

### User and Access Control

#### Create MQTT Users

```bash
# Start mosquitto to create initial setup
docker-compose up -d

# Create password file and users
docker exec mosquitto mosquitto_passwd -c /mosquitto/config/passwd homeassistant
docker exec mosquitto mosquitto_passwd /mosquitto/config/passwd zigbee2mqtt
docker exec mosquitto mosquitto_passwd /mosquitto/config/passwd iot_device
docker exec mosquitto mosquitto_passwd /mosquitto/config/passwd monitoring

# Restart to apply changes
docker-compose restart mosquitto
```

#### Access Control List

Create `config/acl`:

```text
# Home Assistant - full access
user homeassistant
topic readwrite #

# Zigbee2MQTT - specific topics
user zigbee2mqtt
topic readwrite zigbee2mqtt/#
topic readwrite homeassistant/#

# IoT devices - device-specific topics
user iot_device
topic readwrite devices/%u/#
topic read broadcast/#

# Monitoring - read-only access
user monitoring
topic read #
topic read $SYS/#
```

### SSL/TLS Configuration

#### Generate SSL Certificates

```bash
cd ssl

# Generate CA key and certificate
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=MQTT-CA"

# Generate server key and certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=mqtt.example.com"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650

# Set permissions
chmod 600 *.key
chmod 644 *.crt
rm server.csr
```

## Deployment Commands

### Start Services

```bash
# Start mosquitto
docker-compose up -d

# Monitor logs
docker-compose logs -f mosquitto

# Check service health
docker-compose ps
```

### Testing MQTT Connectivity

```bash
# Test basic connectivity
docker exec mosquitto mosquitto_pub -h localhost -t test/topic -m "Hello MQTT"
docker exec mosquitto mosquitto_sub -h localhost -t test/topic

# Test with authentication
docker exec mosquitto mosquitto_pub -h localhost -u homeassistant -P password -t test/auth -m "Authenticated"
docker exec mosquitto mosquitto_sub -h localhost -u homeassistant -P password -t test/auth

# Test SSL connection
docker exec mosquitto mosquitto_pub -h localhost -p 8883 --cafile /mosquitto/config/ssl/ca.crt -t test/ssl -m "SSL Test"
```

## Native Installation

### Ubuntu/Debian Installation

```bash
# Update package list
sudo apt update

# Install Mosquitto and clients
sudo apt install -y mosquitto mosquitto-clients

# Enable and start service
sudo systemctl enable mosquitto
sudo systemctl start mosquitto

# Check status
sudo systemctl status mosquitto
```

### Configuration for Native Installation

Edit `/etc/mosquitto/mosquitto.conf`:

```conf
# Include custom configuration directory
include_dir /etc/mosquitto/conf.d

# Basic settings
persistence true
persistence_location /var/lib/mosquitto/

# Logging
log_dest file /var/log/mosquitto/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information

# Network
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd

# WebSockets (if needed)
listener 9001
protocol websockets
```

Create users:

```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd homeassistant
sudo mosquitto_passwd /etc/mosquitto/passwd zigbee2mqtt

# Restart service
sudo systemctl restart mosquitto
```

## Raspberry Pi Optimization

### Installation on Raspberry Pi

```bash
# Install on Raspberry Pi
sudo apt update
sudo apt install -y mosquitto mosquitto-clients

# Optimize for Pi resources
sudo nano /etc/mosquitto/mosquitto.conf
```

#### Pi-Specific Configuration

```conf
# Raspberry Pi optimizations
max_connections 100
max_inflight_messages 10
max_queued_messages 100
memory_limit 33554432  # 32MB limit

# Reduce logging for SD card longevity
log_dest syslog
log_type error
log_type warning

# Persistence optimization
autosave_interval 3600
autosave_on_changes false
```

## Monitoring and Maintenance

### Log Management

```bash
# View mosquitto logs
docker-compose logs mosquitto

# Follow logs in real-time
docker-compose logs -f mosquitto

# Log rotation (add to crontab)
docker exec mosquitto logrotate /etc/logrotate.conf
```

### Performance Monitoring

```bash
# Monitor MQTT system topics
docker exec mosquitto mosquitto_sub -h localhost -t '$SYS/#' -v

# Check connection count
docker exec mosquitto mosquitto_sub -h localhost -t '$SYS/broker/clients/connected' -C 1

# Monitor message statistics
docker exec mosquitto mosquitto_sub -h localhost -t '$SYS/broker/messages/received' -C 1
docker exec mosquitto mosquitto_sub -h localhost -t '$SYS/broker/messages/sent' -C 1
```

### Backup and Restore

```bash
# Backup mosquitto data
docker run --rm -v mosquitto_config:/source -v $(pwd):/backup alpine \
  tar czf /backup/mosquitto-config-$(date +%Y%m%d).tar.gz -C /source .

docker run --rm -v mosquitto_data:/source -v $(pwd):/backup alpine \
  tar czf /backup/mosquitto-data-$(date +%Y%m%d).tar.gz -C /source .

# Restore mosquitto data
docker run --rm -v mosquitto_config:/target -v $(pwd):/backup alpine \
  tar xzf /backup/mosquitto-config-20241120.tar.gz -C /target

docker run --rm -v mosquitto_data:/target -v $(pwd):/backup alpine \
  tar xzf /backup/mosquitto-data-20241120.tar.gz -C /target
```

## Troubleshooting

### Common Issues

```bash
# Check mosquitto status
docker-compose ps
docker inspect mosquitto

# Check configuration
docker exec mosquitto mosquitto -c /mosquitto/config/mosquitto.conf -v

# Test port connectivity
telnet localhost 1883
telnet localhost 9001
telnet localhost 8883

# Check file permissions
docker exec mosquitto ls -la /mosquitto/config/
docker exec mosquitto ls -la /mosquitto/data/
```

### Debug Configuration

```bash
# Enable verbose logging temporarily
docker exec mosquitto sh -c 'echo "log_type debug" >> /mosquitto/config/mosquitto.conf'
docker-compose restart mosquitto

# Remove debug logging
docker exec mosquitto sed -i '/log_type debug/d' /mosquitto/config/mosquitto.conf
docker-compose restart mosquitto
```

For integration with Home Assistant and complete stack deployment, see the [main deployment guide](index.md).
