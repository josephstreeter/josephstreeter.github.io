---
uid: misc.homeassistant.homeassistant
title: Home Assistant - Complete Setup and Management Guide
description: Comprehensive guide to provisioning, operating, and maintaining Home Assistant for home automation
keywords: [home assistant, smart home, automation, iot, home automation platform, hassio]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Overview

**Home Assistant** is an open-source home automation platform that focuses on privacy and local control. It allows you to control all your devices from a single, unified interface while keeping all data local and secure.

## What is Home Assistant?

Home Assistant is a powerful home automation platform that:

- **Connects Everything**: Integrates with over 2000 different devices and services
- **Privacy First**: All data stays local, no cloud dependency required  
- **Highly Customizable**: Extensible through integrations, automations, and custom components
- **User-Friendly**: Beautiful, responsive web interface accessible from any device
- **Open Source**: Free, transparent, and community-driven development
- **Automation Engine**: Powerful rule-based and trigger-based automation system

### Key Features

- **Device Integration**: Connect lights, sensors, cameras, locks, thermostats, and more
- **Automation**: Create complex automations based on time, device states, or external events
- **Voice Control**: Integration with Google Assistant, Alexa, and local voice assistants
- **Mobile Apps**: Native iOS and Android apps with push notifications
- **Energy Management**: Monitor and optimize energy usage across your home
- **Security**: Secure access with multi-factor authentication and user management

### Architecture Overview

```mermaid
graph TB
    subgraph "Home Assistant Core"
        CORE[Home Assistant Core]
        HASS[HASS Supervisor]
        ADDONS[Add-ons]
    end
    
    subgraph "Communication Protocols"
        MQTT[MQTT Broker]
        ZIGBEE[Zigbee Coordinator]
        ZWAVE[Z-Wave Controller]
        WIFI[WiFi Devices]
    end
    
    subgraph "Devices & Services"
        LIGHTS[Smart Lights]
        SENSORS[Sensors]
        CAMERAS[Cameras]
        CLIMATE[Thermostats]
        LOCKS[Smart Locks]
        MEDIA[Media Players]
    end
    
    subgraph "User Interfaces"
        WEB[Web Interface]
        MOBILE[Mobile Apps]
        VOICE[Voice Assistants]
    end
    
    CORE --> MQTT
    CORE --> ZIGBEE
    CORE --> ZWAVE
    CORE --> WIFI
    
    MQTT --> LIGHTS
    ZIGBEE --> SENSORS
    ZWAVE --> LOCKS
    WIFI --> CAMERAS
    WIFI --> CLIMATE
    WIFI --> MEDIA
    
    CORE --> WEB
    CORE --> MOBILE
    CORE --> VOICE
    
    HASS --> ADDONS
    ADDONS --> MQTT
    
    class CORE central
    class MQTT,ZIGBEE,ZWAVE,WIFI protocol
    class LIGHTS,SENSORS,CAMERAS,CLIMATE,LOCKS,MEDIA device
    class WEB,MOBILE,VOICE interface
```

## Prerequisites

### Hardware Requirements

**Minimum Specifications:**

- **CPU**: 2 cores, 1.5GHz (Raspberry Pi 4 recommended)
- **RAM**: 2GB (4GB+ recommended for large installations)
- **Storage**: 32GB (64GB+ recommended, SSD preferred)
- **Network**: Ethernet strongly recommended for reliability
- **USB**: Available ports for Zigbee/Z-Wave controllers (if needed)

**Recommended Hardware:**

- **Intel NUC** or similar mini PC for best performance
- **Raspberry Pi 4 (4GB/8GB)** for budget-conscious installations
- **Dedicated SSD storage** for better performance and reliability
- **UPS backup** for power reliability
- **Gigabit Ethernet** connection

**Hardware Considerations:**

- **SD Card Limitations**: Use high-quality cards (Class 10, A2) or preferably SSD
- **Power Supply**: Ensure adequate, stable power supply
- **Cooling**: Proper ventilation/cooling for 24/7 operation
- **Expansion**: Plan for future device additions

### Network Requirements

- **Internet Connection**: For initial setup and updates (not required for operation)
- **Local Network Access**: Ethernet or reliable WiFi
- **Port Requirements**:
  - Port 8123 (HTTP interface)
  - Port 8443 (HTTPS if configured)
  - Various ports for integrations (documented per integration)

## Installation Methods

### Method 1: Home Assistant Operating System (Recommended)

Home Assistant Operating System (HAOS) is the recommended installation method, providing a complete operating system optimized for Home Assistant.

#### Raspberry Pi Installation

```bash
# Download the latest HAOS image for Raspberry Pi
wget https://github.com/home-assistant/operating-system/releases/latest/download/haos_rpi4-64-latest.img.xz

# Flash to SD card using Raspberry Pi Imager or balenaEtcher
# Insert SD card and boot Raspberry Pi
# Access via http://homeassistant.local:8123 after initial setup
```

#### x86-64 Installation (Intel NUC, etc.)

```bash
# Download HAOS for generic x86-64
wget https://github.com/home-assistant/operating-system/releases/latest/download/haos_generic-x86-64-latest.img.xz

# Flash to USB drive or SSD
# Boot from the drive
# Access via http://homeassistant.local:8123
```

### Method 2: Home Assistant Container (Docker)

For users who prefer Docker or want to run Home Assistant alongside other services.

#### Docker Compose Setup

Create directory structure:

```bash
mkdir -p ~/homeassistant/config
cd ~/homeassistant
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # Zigbee/Z-Wave dongle
      - /dev/ttyACM0:/dev/ttyACM0  # Alternative USB device
```

Start Home Assistant:

```bash
docker-compose up -d
```

#### Advanced Docker Configuration

For production environments with external databases and additional services:

```yaml
version: '3.8'

services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    depends_on:
      - mariadb
      - influxdb
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0

  mariadb:
    container_name: homeassistant-db
    image: mariadb:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: supersecretpassword
      MYSQL_DATABASE: homeassistant
      MYSQL_USER: homeassistant
      MYSQL_PASSWORD: homeassistantpassword
    volumes:
      - ./mariadb:/var/lib/mysql
    ports:
      - "3306:3306"

  influxdb:
    container_name: homeassistant-influxdb
    image: influxdb:2.7
    restart: unless-stopped
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: adminpassword
      DOCKER_INFLUXDB_INIT_ORG: homeassistant
      DOCKER_INFLUXDB_INIT_BUCKET: homeassistant
    volumes:
      - ./influxdb:/var/lib/influxdb2
    ports:
      - "8086:8086"

  grafana:
    container_name: homeassistant-grafana
    image: grafana/grafana:latest
    restart: unless-stopped
    user: "472"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: adminpassword
    volumes:
      - ./grafana:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - influxdb
```

### Method 3: Home Assistant Core (Python Virtual Environment)

For advanced users who want full control over the Python environment.

#### Prerequisites Installation

```bash
# Install Python and dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y python3 python3-dev python3-venv python3-pip libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff5-dev libturbojpeg0-dev tzdata

# Create user for Home Assistant
sudo useradd -rm homeassistant -G dialout,gpio,i2c

# Create installation directory
sudo mkdir /opt/homeassistant
sudo chown homeassistant:homeassistant /opt/homeassistant
```

#### Installation Process

```bash
# Switch to homeassistant user
sudo -u homeassistant -H -s

# Create virtual environment
cd /opt/homeassistant
python3 -m venv .
source bin/activate

# Upgrade pip
python3 -m pip install --upgrade pip

# Install Home Assistant
pip3 install homeassistant

# Create configuration directory
mkdir config

# Start Home Assistant (first run)
hass -c config
```

#### Systemd Service

```bash
# Create systemd service file
sudo nano /etc/systemd/system/home-assistant@homeassistant.service
```

Service file content:

```ini
[Unit]
Description=Home Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=%i
ExecStart=/opt/homeassistant/bin/hass -c "/opt/homeassistant/config"
RestartForceExitStatus=100
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable home-assistant@homeassistant
sudo systemctl start home-assistant@homeassistant
```

## Initial Configuration

### First-Time Setup

1. **Access Web Interface**: Navigate to `http://[IP]:8123`
2. **Create User Account**: Set up the first administrative user
3. **Name Your Home**: Set location and unit preferences
4. **Integration Discovery**: Home Assistant will automatically discover devices
5. **Complete Setup**: Follow the onboarding wizard

### Basic Configuration File

Home Assistant uses YAML configuration files. The main configuration file is `configuration.yaml`:

```yaml
# Loads default set of integrations. Do not remove.
default_config:

# Configure Home Assistant
homeassistant:
  name: My Home
  latitude: 40.7128
  longitude: -74.0060
  elevation: 10
  unit_system: metric
  time_zone: America/New_York
  currency: USD
  country: US
  
  # External URLs for remote access
  external_url: "https://yourdomain.duckdns.org"
  internal_url: "http://192.168.1.100:8123"

# Text to speech
tts:
  - platform: google_translate
    service_name: google_say

# HTTP configuration
http:
  # Server port
  server_port: 8123
  # CORS settings for external access
  cors_allowed_origins:
    - https://cast.home-assistant.io
  
  # Trusted networks
  trusted_networks:
    - 192.168.1.0/24
    - 127.0.0.1

# Database configuration (optional - defaults to SQLite)
recorder:
  db_url: mysql://homeassistant:password@localhost/homeassistant
  purge_keep_days: 30
  commit_interval: 10
  
  # Include/exclude specific entities
  include:
    domains:
      - sensor
      - switch
      - light
  exclude:
    entities:
      - sensor.date_time
      - sensor.time

# History configuration
history:
  include:
    domains:
      - sensor
      - switch
      - light

# Logbook configuration
logbook:
  include:
    domains:
      - light
      - switch
      - sensor

# Energy monitoring
energy:

# Person tracking
person:
  - name: John Doe
    id: john_doe
    device_trackers:
      - device_tracker.john_phone

# Zones
zone:
  - name: Work
    latitude: 40.7589
    longitude: -73.9851
    radius: 100
    icon: mdi:office-building

# Input helpers
input_boolean:
  vacation_mode:
    name: Vacation Mode
    initial: false
    icon: mdi:airplane

input_select:
  house_mode:
    name: House Mode
    options:
      - Normal
      - Away
      - Night
      - Vacation
    initial: Normal

# Separate configuration files
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml
sensor: !include sensors.yaml
```

## Integrations and Add-ons

### Popular Integrations

#### MQTT Integration

See the [Mosquitto MQTT Setup Guide](../mosquitto/index.md) for broker configuration.

```yaml
# MQTT configuration
mqtt:
  broker: localhost
  port: 1883
  username: homeassistant
  password: !secret mqtt_password
  discovery: true
  discovery_prefix: homeassistant
  birth_message:
    topic: "homeassistant/status"
    payload: "online"
  will_message:
    topic: "homeassistant/status"
    payload: "offline"
```

#### Zigbee Integration

For Zigbee2MQTT integration, see the [Zigbee2MQTT Setup Guide](../zigbee2mqtt/index.md).

Alternative native Zigbee integration:

```yaml
# Native Zigbee Home Assistant integration
zha:
  usb_path: /dev/ttyUSB0
  database_path: /config/zigbee.db
```

#### Weather Integration

```yaml
# Weather integration
weather:
  - platform: met
    name: Home Weather
```

#### Device Tracker Integration

```yaml
# Device tracking
device_tracker:
  - platform: nmap_tracker
    hosts: 192.168.1.0/24
    home_interval: 10
    consider_home: 180
    scan_options: " --privileged -sS "
```

### Essential Add-ons (HAOS/Supervised Only)

#### File Editor

Easy configuration file editing through the web interface.

#### SSH & Web Terminal

Secure shell access to the Home Assistant host.

#### DuckDNS

Dynamic DNS service for remote access:

```yaml
# DuckDNS Add-on configuration
lets_encrypt: true
token: your_duckdns_token
domains:
  - yourdomain.duckdns.org
aliases: []
certfile: fullchain.pem
keyfile: privkey.pem
```

#### ESPHome

Manage ESP32/ESP8266 devices:

```yaml
# ESPHome configuration
esphome:
  dashboard_use_ping: true
```

#### Node-RED

Visual programming for home automation:

```yaml
# Node-RED add-on configuration
credential_secret: your_secret_key
dark_mode: true
```

#### InfluxDB & Grafana

For advanced data visualization:

```yaml
# InfluxDB configuration
influxdb:
  host: localhost
  port: 8086
  database: homeassistant
  username: homeassistant
  password: !secret influxdb_password
  max_retries: 3
  default_measurement: state
```

## User Interface Customization

### Lovelace Dashboard

Home Assistant uses Lovelace for the user interface. You can customize it through the UI or YAML.

#### Basic Dashboard Configuration

```yaml
# ui-lovelace.yaml
title: My Home
views:
  - title: Home
    path: home
    icon: mdi:home
    cards:
      - type: entities
        title: Living Room
        entities:
          - light.living_room_main
          - sensor.living_room_temperature
          - sensor.living_room_humidity
          
      - type: weather-forecast
        entity: weather.home_weather
        
      - type: gauge
        entity: sensor.cpu_temperature
        min: 0
        max: 100
        severity:
          green: 0
          yellow: 60
          red: 80

  - title: Security
    path: security
    icon: mdi:security
    cards:
      - type: alarm-panel
        entity: alarm_control_panel.home_alarm
        
      - type: picture-glance
        title: Front Door
        image: /local/front_door.jpg
        entities:
          - binary_sensor.front_door
          - lock.front_door
        camera_image: camera.front_door

  - title: Climate
    path: climate
    icon: mdi:thermometer
    cards:
      - type: thermostat
        entity: climate.main_thermostat
        
      - type: history-graph
        entities:
          - sensor.living_room_temperature
          - sensor.bedroom_temperature
        hours_to_show: 24
```

#### Custom Cards

Popular custom cards that enhance the interface:

- **Mini Graph Card**: Compact sensor graphs
- **Button Card**: Highly customizable buttons
- **Layout Card**: Advanced layout options
- **Mushroom Cards**: Modern, clean card designs
- **Swipe Card**: Swipeable card navigation

### Themes

```yaml
# themes.yaml
Material Dark Red:
  # Main colors
  primary-color: '#F44336'
  accent-color: '#FF5722'
  dark-primary-color: '#D32F2F'
  light-primary-color: '#FFCDD2'
  
  # Text colors
  primary-text-color: '#FFFFFF'
  text-primary-color: '#FFFFFF'
  secondary-text-color: '#BDBDBD'
  disabled-text-color: '#757575'
  
  # Sidebar
  sidebar-icon-color: '#FFF'
  sidebar-text-color: '#FFF'
  sidebar-background-color: '#263137'
  
  # Background colors
  primary-background-color: '#303030'
  secondary-background-color: '#424242'
  divider-color: 'rgba(255, 255, 255, 0.12)'
  
  # Card colors
  card-background-color: '#424242'
  paper-card-header-color: 'var(--accent-color)'
  paper-card-background-color: '#424242'
  
  # Toggle colors
  paper-toggle-button-checked-button-color: 'var(--accent-color)'
  paper-toggle-button-checked-bar-color: 'var(--accent-color)'
  paper-toggle-button-unchecked-button-color: 'var(--disabled-text-color)'
  paper-toggle-button-unchecked-bar-color: 'var(--disabled-text-color)'
```

## Advanced Topics

This comprehensive Home Assistant guide references specialized documentation for:

- **[Automations](automations.md)**: Complete automation configuration and examples
- **[Sensors](sensors.md)**: Sensor configuration and templates  
- **[Groups](groups.md)**: Device grouping and organization
- **[Templates](templates.md)**: Template syntax and examples
- **[Configuration](configuration.md)**: Advanced configuration options
- **[Deployment](deployment.md)**: Production deployment strategies

For integration-specific setup:

- **[Mosquitto MQTT](../mosquitto/index.md)**: MQTT broker configuration
- **[Zigbee2MQTT](../zigbee2mqtt/index.md)**: Zigbee device integration

## References

- [Home Assistant Official Documentation](https://www.home-assistant.io/docs/)
- [Home Assistant Community](https://community.home-assistant.io/)
- [Home Assistant GitHub](https://github.com/home-assistant)
- [HACS (Home Assistant Community Store)](https://hacs.xyz/)
- [ESPHome Documentation](https://esphome.io/)
- [Node-RED Documentation](https://nodered.org/docs/)
