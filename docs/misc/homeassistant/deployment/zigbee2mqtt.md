---
uid: misc.homeassistant.deployment.zigbee2mqtt
title: Zigbee2MQTT Deployment
description: Dedicated Zigbee2MQTT deployment guide for Zigbee device integration
keywords: [zigbee2mqtt, zigbee, deployment, docker, iot, smart home]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Zigbee2MQTT Deployment

This guide focuses specifically on deploying Zigbee2MQTT for integrating Zigbee devices with Home Assistant via MQTT.

### Deployment Options

1. **Docker Container**: Recommended for containerized environments
2. **Native Installation**: Direct installation on Raspberry Pi or Linux
3. **Add-on Installation**: Home Assistant OS add-on (if using HAOS)

## Docker Deployment (Recommended)

### Basic Docker Compose Setup

```yaml
# docker-compose.yml
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
      - "8080:8080"    # Web interface
    environment:
      - TZ=America/Chicago
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # Adjust to your Zigbee adapter
    networks:
      - zigbee2mqtt
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Include MQTT broker if not running separately
  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/logs:/mosquitto/log
    networks:
      - zigbee2mqtt

networks:
  zigbee2mqtt:
    driver: bridge
```

### Production Docker Compose

```yaml
# production-docker-compose.yml
version: '3.8'

services:
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:latest
    restart: unless-stopped
    volumes:
      - zigbee2mqtt_data:/app/data
      - /run/udev:/run/udev:ro
      - ./zigbee2mqtt-config:/app/data/configuration.yaml:ro
    ports:
      - "8080:8080"
    environment:
      - TZ=America/Chicago
      - ZIGBEE2MQTT_CONFIG_MQTT_SERVER=mqtt://mosquitto:1883
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    networks:
      - zigbee2mqtt
    depends_on:
      - mosquitto
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 128M
          cpus: '0.1'

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - mosquitto_config:/mosquitto/config
      - mosquitto_data:/mosquitto/data
      - mosquitto_logs:/mosquitto/log
    networks:
      - zigbee2mqtt
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m test"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  zigbee2mqtt_data:
    driver: local
  mosquitto_config:
    driver: local
  mosquitto_data:
    driver: local
  mosquitto_logs:
    driver: local

networks:
  zigbee2mqtt:
    driver: bridge
```

## Initial Setup

### Directory Structure

```bash
# Create directory structure
mkdir -p zigbee2mqtt/{data,mosquitto/{config,data,logs}}
cd zigbee2mqtt

# Set proper permissions
chmod 755 data
chmod 755 mosquitto/{config,data,logs}
```

### Zigbee Adapter Detection

```bash
# Find your Zigbee adapter
ls -la /dev/tty*
dmesg | grep tty

# Common adapter paths:
# /dev/ttyUSB0 - USB adapters
# /dev/ttyACM0 - CDC ACM adapters
# /dev/serial/by-id/usb-... - Persistent device names

# Check adapter info
udevadm info --name=/dev/ttyUSB0 --attribute-walk
```

### Configuration Files

#### Basic Zigbee2MQTT Configuration

Create `data/configuration.yaml`:

```yaml
# Home Assistant integration
homeassistant: true

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
  user: zigbee2mqtt
  password: your_zigbee2mqtt_password
  keepalive: 60
  reject_unauthorized: true
  version: 4

# Serial port settings
serial:
  port: /dev/ttyUSB0
  adapter: auto
  baudrate: 115200
  rtscts: false

# Web interface
frontend:
  port: 8080
  host: 0.0.0.0
  auth_token: your_auth_token_here

# Advanced settings
advanced:
  legacy_api: false
  legacy_availability_payload: false
  log_level: info
  log_directory: /app/data/log
  log_file: zigbee2mqtt.log
  log_rotation: true
  log_output: ['console', 'file']
  
  # Home Assistant specific
  homeassistant_legacy_entity_attributes: false
  homeassistant_legacy_triggers: false
  homeassistant_status_topic: homeassistant/status
  
  # Network settings
  pan_id: GENERATE
  ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
  channel: 11
  network_key: GENERATE
  
  # Performance
  cache_state: true
  cache_state_persistent: true
  cache_state_send_on_startup: true

# Device options
device_options:
  legacy: false
  retain: true
  optimistic: true
  
# Permit join (disable after setup)
permit_join: false

# OTA updates
ota:
  update_check_interval: 1440
  disable_automatic_update_check: false

# Experimental features
experimental:
  output: json

# Groups
groups: groups.yaml

# Devices
devices: devices.yaml
```

#### Production Configuration

Create `data/configuration.yaml` for production:

```yaml
# Home Assistant integration
homeassistant:
  discovery_topic: homeassistant
  legacy_entity_attributes: false
  legacy_triggers: false
  status_topic: homeassistant/status

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
  user: !secret mqtt_user
  password: !secret mqtt_password
  client_id: zigbee2mqtt
  keepalive: 60
  reject_unauthorized: true
  ca: /app/data/ca.crt
  key: /app/data/client.key
  cert: /app/data/client.crt
  version: 4
  force_disable_retain: false

# Serial port settings
serial:
  port: /dev/ttyUSB0
  adapter: auto
  baudrate: 115200
  rtscts: false
  disable_led: false

# Web interface
frontend:
  port: 8080
  host: 0.0.0.0
  auth_token: !secret frontend_auth_token
  url: https://zigbee2mqtt.example.com

# Advanced settings
advanced:
  legacy_api: false
  legacy_availability_payload: false
  
  # Logging
  log_level: warn
  log_directory: /app/data/log
  log_file: zigbee2mqtt.log
  log_rotation: true
  log_symlink_current: false
  log_output: ['file']
  
  # Network security
  pan_id: 0x1a62
  ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
  channel: 11
  network_key: [1, 3, 5, 7, 9, 11, 13, 15, 0, 2, 4, 6, 8, 10, 12, 13]
  
  # Performance
  cache_state: true
  cache_state_persistent: true
  cache_state_send_on_startup: true
  last_seen: ISO_8601
  elapsed: true
  
  # Security
  soft_reset_timeout: 0
  report: true
  
  # Home Assistant
  homeassistant_legacy_entity_attributes: false
  homeassistant_legacy_triggers: false
  homeassistant_status_topic: homeassistant/status

# Device options
device_options:
  legacy: false
  retain: true
  optimistic: false
  qos: 1

# Permit join (always false in production)
permit_join: false

# OTA updates
ota:
  update_check_interval: 1440
  disable_automatic_update_check: false
  zigbee_ota_override_index_location: /app/data/ota_index.json

# Map options
map_options:
  graphviz:
    colors:
      fill:
        enddevice: '#fff8ce'
        coordinator: '#e04e5d'
        router: '#4ea3e0'
      font:
        coordinator: '#ffffff'
        router: '#ffffff'
        enddevice: '#000000'
      line:
        active: '#009900'
        inactive: '#994444'

# External configuration files
groups: groups.yaml
devices: devices.yaml
```

### Secrets Management

Create `data/secret.yaml`:

```yaml
# MQTT credentials
mqtt_user: zigbee2mqtt
mqtt_password: your_secure_password_here

# Frontend authentication
frontend_auth_token: your_secure_token_here
```

### MQTT Broker Configuration

If using the included Mosquitto, create `mosquitto/config/mosquitto.conf`:

```conf
# Basic configuration for Zigbee2MQTT
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice

# Network settings
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

# WebSocket support
listener 9001
protocol websockets
allow_anonymous false

# Performance settings
max_connections 100
max_inflight_messages 20
max_queued_messages 200
```

## Deployment Commands

### Start Services

```bash
# Identify Zigbee adapter first
ls -la /dev/tty*

# Update docker-compose.yml with correct device path
# Start services
docker-compose up -d

# Monitor startup logs
docker-compose logs -f zigbee2mqtt

# Check service health
docker-compose ps
```

### Initial Device Pairing

```bash
# Enable permit join via logs
docker-compose exec zigbee2mqtt mosquitto_pub -h mosquitto -t zigbee2mqtt/bridge/request/permit_join -m '{"value": true}'

# Or via web interface at http://localhost:8080

# Monitor device joining
docker-compose logs -f zigbee2mqtt | grep -i pair
```

## Native Installation on Raspberry Pi

### Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git and build tools
sudo apt-get install -y git build-essential

# Verify installation
node --version
npm --version
```

### Install Zigbee2MQTT

```bash
# Create user and directory
sudo useradd -r -s /bin/false zigbee2mqtt
sudo mkdir -p /opt/zigbee2mqtt
sudo chown -R zigbee2mqtt:zigbee2mqtt /opt/zigbee2mqtt

# Clone repository
sudo -u zigbee2mqtt git clone https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt

# Change to directory
cd /opt/zigbee2mqtt

# Install dependencies
sudo -u zigbee2mqtt npm ci --production

# Create configuration
sudo -u zigbee2mqtt cp data/configuration.example.yaml data/configuration.yaml
```

### Native Configuration

Edit `/opt/zigbee2mqtt/data/configuration.yaml`:

```yaml
# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883
  user: zigbee2mqtt
  password: your_password

# Serial settings
serial:
  port: /dev/ttyUSB0

# Enable web interface
frontend:
  port: 8080

# Other settings...
```

### Systemd Service

Create `/etc/systemd/system/zigbee2mqtt.service`:

```ini
[Unit]
Description=zigbee2mqtt
After=network.target

[Service]
Environment=NODE_ENV=production
Type=notify
ExecStart=/usr/bin/node index.js
WorkingDirectory=/opt/zigbee2mqtt
StandardOutput=inherit
StandardError=inherit
Restart=always
RestartSec=10s
User=zigbee2mqtt

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable zigbee2mqtt
sudo systemctl start zigbee2mqtt
sudo systemctl status zigbee2mqtt
```

## Device Management

### Common Zigbee Adapters

```yaml
# ConBee II / RaspBee II
serial:
  port: /dev/ttyACM0
  adapter: deconz

# CC2531 USB Stick
serial:
  port: /dev/ttyUSB0
  adapter: zstack

# CC26X2R1 (Texas Instruments)
serial:
  port: /dev/ttyUSB0
  adapter: zstack3x0

# Sonoff Zigbee 3.0 USB Dongle Plus
serial:
  port: /dev/ttyUSB0
  adapter: ezsp
```

### Device Configuration

Example device configuration in `data/devices.yaml`:

```yaml
'0x00158d0001a2b3c4':
  friendly_name: living_room_temperature
  retain: true
  qos: 1
  
'0x00158d0001a2b3c5':
  friendly_name: bedroom_motion_sensor
  retain: true
  occupancy_timeout: 120
```

### Group Configuration

Example group configuration in `data/groups.yaml`:

```yaml
'1':
  friendly_name: living_room_lights
  retain: true
  devices:
    - living_room_bulb_1
    - living_room_bulb_2
    - living_room_strip
```

## Monitoring and Maintenance

### Health Monitoring

```bash
# Check Zigbee2MQTT logs
docker-compose logs -f zigbee2mqtt

# Monitor MQTT messages
docker-compose exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/#' -v

# Check device status
docker-compose exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/bridge/state' -C 1
```

### Network Map

```bash
# Generate network map
docker-compose exec zigbee2mqtt wget -O /app/data/networkmap.svg "http://localhost:8080/api/networkmap"

# View via web interface
# Navigate to http://localhost:8080 > Map tab
```

### Backup and Restore

```bash
# Backup Zigbee2MQTT data
docker run --rm -v zigbee2mqtt_data:/source -v $(pwd):/backup alpine \
  tar czf /backup/zigbee2mqtt-$(date +%Y%m%d).tar.gz -C /source .

# Backup coordinator
docker exec zigbee2mqtt cp /app/data/coordinator_backup.json /tmp/
docker cp zigbee2mqtt:/tmp/coordinator_backup.json ./coordinator_backup-$(date +%Y%m%d).json

# Restore data
docker run --rm -v zigbee2mqtt_data:/target -v $(pwd):/backup alpine \
  tar xzf /backup/zigbee2mqtt-20241120.tar.gz -C /target
```

## Troubleshooting

### Common Issues

```bash
# Check adapter detection
docker-compose exec zigbee2mqtt ls -la /dev/ttyUSB*

# Verify permissions
docker-compose exec zigbee2mqtt id
ls -la /dev/ttyUSB0

# Check coordinator communication
docker-compose logs zigbee2mqtt | grep -i coordinator

# Reset coordinator (last resort)
docker-compose exec zigbee2mqtt mosquitto_pub -h mosquitto -t zigbee2mqtt/bridge/request/coordinator_check -m '{}'
```

### Debug Mode

```yaml
# Enable debug logging temporarily
advanced:
  log_level: debug
  log_output: ['console', 'file']
```

### Adapter Issues

```bash
# For ConBee adapters
sudo systemctl stop zigbee2mqtt
sudo deCONZ-firmware-update.sh
sudo systemctl start zigbee2mqtt

# For CC2531 adapters - may need firmware flash
# Use CC2531 firmware flasher tools
```

For integration with Home Assistant and complete stack deployment, see the [main deployment guide](index.md).
