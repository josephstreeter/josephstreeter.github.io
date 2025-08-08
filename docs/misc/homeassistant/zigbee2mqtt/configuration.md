# Zigbee2MQTT Configuration Guide

Complete configuration guide for Zigbee2MQTT including basic setup, advanced options, and optimization.

## Prerequisites

> **Important**: Ensure you have a working MQTT broker before configuring Zigbee2MQTT. See the [Mosquitto MQTT Setup Guide](../mosquitto/index.md) for detailed installation and configuration instructions.

## Basic Configuration

### Configuration File Location

| Installation Method | Configuration Path |
|--------------------|--------------------|
| **Docker** | `./data/configuration.yaml` |
| **Native** | `/opt/zigbee2mqtt/data/configuration.yaml` |
| **HA Add-on** | `/config/zigbee2mqtt/configuration.yaml` |

### Minimal Configuration

Create or edit `configuration.yaml`:

```yaml
# Home Assistant integration (MQTT discovery)
homeassistant: true

# Allow new devices to join (disable after setup)
permit_join: false

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883

# Serial settings
serial:
  port: /dev/ttyUSB0

# Frontend settings
frontend:
  port: 8080
  host: 0.0.0.0
```

### Complete Configuration Example

```yaml
# Home Assistant integration
homeassistant: true

# Device joining
permit_join: false

# MQTT broker settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883
  user: mqtt_user
  password: mqtt_password
  client_id: zigbee2mqtt
  keepalive: 60
  clean: true
  retain: false
  qos: 0

# Zigbee adapter settings
serial:
  port: /dev/ttyUSB0
  adapter: zstack  # Options: zstack, deconz, zigate, ezsp
  baudrate: 115200

# Network configuration
advanced:
  # Zigbee channel (11-26, avoid WiFi channels)
  channel: 11
  
  # Network identifiers (change for security)
  pan_id: 0x1a62
  ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
  network_key: [1, 3, 5, 7, 9, 11, 13, 15, 0, 2, 4, 6, 8, 10, 12, 13]
  
  # Security settings
  security_key: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10]
  
  # Performance settings
  transmit_power: 20
  last_seen: ISO_8601_local
  cache_state: true

# Web interface
frontend:
  port: 8080
  host: 0.0.0.0
  auth_token: your_secret_token

# Logging configuration
advanced:
  log_level: info  # error, warn, info, debug
  log_output: ['console', 'file']
  log_directory: data/log/%TIMESTAMP%
  log_file: log.txt
  log_rotation: true

# Device availability tracking
availability:
  active:
    timeout: 10
  passive:
    timeout: 1500

# OTA firmware updates
ota:
  update_check_interval: 1440  # Check every 24 hours
  disable_automatic_update_check: false
```

## Network Configuration

### Channel Selection

Choose a Zigbee channel that doesn't interfere with WiFi:

```yaml
advanced:
  channel: 11  # Recommended channels: 11, 15, 20, 25, 26
```

**Channel Planning:**

| WiFi Channel | WiFi Frequency | Recommended Zigbee Channels |
|--------------|----------------|----------------------------|
| 1 | 2412 MHz | 15, 16, 17, 18, 19, 20 |
| 6 | 2437 MHz | 20, 21, 22, 23, 24, 25 |
| 11 | 2462 MHz | 25, 26 |

### Security Configuration

#### Generate Secure Keys

```yaml
advanced:
  # Auto-generate secure keys (recommended)
  network_key: GENERATE
  pan_id: GENERATE
  ext_pan_id: GENERATE
  security_key: GENERATE
```

#### Manual Key Configuration

```yaml
advanced:
  # Custom network key (16 bytes)
  network_key: [0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F, 
                0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E]
  
  # Unique PAN ID (avoid 0x0000, 0xFFFF)
  pan_id: 0x1A62
  
  # Extended PAN ID (8 bytes)
  ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
```

### Adapter Configuration

#### Common Adapter Settings

```yaml
serial:
  port: /dev/ttyUSB0
  adapter: zstack  # CC2652P, CC2531
  baudrate: 115200
  rtscts: false
```

#### Adapter-Specific Configuration

**CC2652P/CC2652R (Recommended):**

```yaml
serial:
  port: /dev/ttyUSB0
  adapter: zstack
  baudrate: 115200
```

**ConBee II:**

```yaml
serial:
  port: /dev/ttyACM0
  adapter: deconz
  baudrate: 38400
```

**CC2531:**

```yaml
serial:
  port: /dev/ttyACM0
  adapter: zstack
  baudrate: 115200
```

## MQTT Configuration

### Basic MQTT Settings

```yaml
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883
  keepalive: 60
  clean: true
  retain: false
  qos: 0
```

### Authenticated MQTT

```yaml
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://homeassistant.local:1883
  user: zigbee2mqtt_user
  password: secure_password
  client_id: zigbee2mqtt_main
```

### SSL/TLS MQTT

```yaml
mqtt:
  base_topic: zigbee2mqtt
  server: mqtts://mqtt.example.com:8883
  user: mqtt_user
  password: mqtt_password
  ca: /etc/ssl/certs/ca-certificates.crt
  cert: /etc/ssl/private/client.crt
  key: /etc/ssl/private/client.key
  reject_unauthorized: true
```

### MQTT Quality of Service

```yaml
mqtt:
  # QoS levels: 0 = at most once, 1 = at least once, 2 = exactly once
  qos: 1
  retain: true  # Retain last known state
```

## Device Configuration

### Global Device Options

```yaml
device_options:
  # Apply to all devices
  retain: false
  qos: 0
  
  # Optimize for battery devices
  optimistic: true
  
  # Device reporting intervals
  temperature_precision: 2
  humidity_precision: 2
```

### Device-Specific Settings

```yaml
device_options:
  # Configure specific device by IEEE address
  '0x00158d0001abcdef':
    friendly_name: 'living_room_sensor'
    retain: true
    qos: 1
    
    # Calibration offsets
    temperature_calibration: -2.0
    humidity_calibration: 5.0
    
    # Reporting intervals (seconds)
    temperature_reporting_interval: 300
    humidity_reporting_interval: 300
    
    # Availability settings
    availability: true
  
  # Configure by friendly name
  'bedroom_motion_sensor':
    occupancy_timeout: 90
    sensitivity: 'medium'
    retain: true
```

## Groups Configuration

### Basic Groups

```yaml
groups:
  '1':
    friendly_name: living_room_lights
    retain: false
    optimistic: true
    devices:
      - ceiling_light_1
      - ceiling_light_2
      - table_lamp
  
  '2':
    friendly_name: bedroom_lights
    devices:
      - bedside_lamp_left
      - bedside_lamp_right
      - ceiling_fan_light
```

### Advanced Group Settings

```yaml
groups:
  '10':
    friendly_name: all_motion_sensors
    devices:
      - living_room_motion
      - kitchen_motion
      - bedroom_motion
    
    # Group-specific settings
    filtered_attributes:
      - occupancy_timeout
      - sensitivity
    
    # Optimize group commands
    optimistic: true
    off_state: 'last_member_state'
```

## Logging Configuration

### Log Levels and Output

```yaml
advanced:
  log_level: info  # error, warn, info, debug
  log_output: ['console', 'file']
  log_directory: data/log/%TIMESTAMP%
  log_file: log.txt
  log_rotation: true
  log_symlink_current: true
  log_syslog: {}  # Enable syslog output
```

### Structured Logging

```yaml
advanced:
  log_level: debug
  log_output: ['console']
  
  # Component-specific logging
  log_debug_to_mqtt_frontend: true
  log_debug_namespace_ignore: 'zhc:zstack:znp:SREQ'
```

### Log File Management

```yaml
advanced:
  log_rotation: true
  log_max_files: 10
  log_file: 'log_%DATE%.txt'  # Date-based rotation
```

## Performance Optimization

### Network Performance

```yaml
advanced:
  # Transmission power (0-20 dBm)
  transmit_power: 20
  
  # Adapter timing
  adapter_delay: 0
  adapter_concurrent: null
  
  # Network settings
  availability_timeout: 0
  availability_blocklist: []
  availability_passlist: []
```

### Memory and CPU Optimization

```yaml
advanced:
  # State caching
  cache_state: true
  cache_state_persistent: true
  cache_state_send_on_startup: true
  
  # Reduce memory usage
  soft_reset_timeout: 0
  report: true
  homeassistant_discovery_topic: 'homeassistant'
  homeassistant_status_topic: 'homeassistant/status'
```

### Battery Device Optimization

```yaml
# Global settings for battery devices
device_options:
  # Longer reporting intervals
  battery_reporting_interval: 3600
  temperature_reporting_interval: 600
  
  # Optimize for battery life
  optimistic: true
  
  # Debounce settings
  debounce: 1
  debounce_ignore: ['action']
```

## Frontend Configuration

### Web Interface Settings

```yaml
frontend:
  port: 8080
  host: 0.0.0.0  # Allow external access
  auth_token: your_very_long_random_token
  url: http://zigbee2mqtt.local:8080  # Public URL
```

### Security Settings

```yaml
frontend:
  # Restrict to localhost (use reverse proxy)
  host: 127.0.0.1
  port: 8080
  
  # Strong authentication
  auth_token: !secret zigbee2mqtt_token
  
  # SSL termination at reverse proxy
  ssl_cert: /path/to/cert.pem
  ssl_key: /path/to/key.pem
```

## Availability Tracking

### Active Availability Checking

```yaml
availability:
  active:
    # Ping devices every 10 minutes
    timeout: 10
  passive:
    # Mark offline after 25 minutes
    timeout: 1500
  
  # Blocklist problematic devices
  blocklist:
    - 'IKEA_bulb_bedroom'
  
  # Allowlist only specific devices
  passlist:
    - 'important_sensor'
```

## OTA Update Configuration

### Automatic Updates

```yaml
ota:
  update_check_interval: 1440  # Daily checks
  disable_automatic_update_check: false
  zigbee_ota_override_index_location: 'https://raw.githubusercontent.com/Koenkk/zigbee-OTA/master/index.json'
  ikea_ota_use_test_url: false
```

### Manual Update Control

```yaml
ota:
  # Disable automatic checks
  disable_automatic_update_check: true
  
  # Custom OTA server
  zigbee_ota_override_index_location: 'http://local-ota-server/index.json'
```

## External Converters

### Custom Device Support

```yaml
external_converters:
  - external_converters.js

# Advanced external converter settings
advanced:
  legacy_api: false
  legacy_availability_payload: false
```

## Configuration Validation

### Test Configuration

```bash
# Docker
docker exec zigbee2mqtt npm run start:dev

# Native installation
cd /opt/zigbee2mqtt
npm run start:dev

# Check logs for errors
tail -f data/log/log.txt
```

### Backup Configuration

```bash
# Create backup before changes
cp configuration.yaml configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)

# Git version control
git init
git add configuration.yaml
git commit -m "Initial configuration"
```

## Configuration Examples

### Home Assistant Integration

```yaml
homeassistant: true

mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://homeassistant.local:1883
  user: homeassistant
  password: !secret mqtt_password

advanced:
  homeassistant_discovery_topic: 'homeassistant'
  homeassistant_status_topic: 'homeassistant/status'
  homeassistant_legacy_entity_attributes: false
  homeassistant_legacy_triggers: false
```

### Large Network Configuration

```yaml
# For networks with 100+ devices
advanced:
  channel: 11
  transmit_power: 20
  
  # Network optimization
  adapter_concurrent: 6
  adapter_delay: 0
  
  # Availability optimization
  availability_timeout: 60
  
  # Logging optimization
  log_level: warn
  log_rotation: true

# Device optimization
device_options:
  optimistic: true
  retain: false
  qos: 0
```

### Security-Focused Configuration

```yaml
# Maximum security settings
advanced:
  network_key: GENERATE
  pan_id: GENERATE
  ext_pan_id: GENERATE
  security_key: GENERATE

permit_join: false

frontend:
  host: 127.0.0.1  # Localhost only
  auth_token: !secret zigbee2mqtt_frontend_token

mqtt:
  server: mqtts://mqtt.local:8883
  user: !secret mqtt_user
  password: !secret mqtt_password
  ca: /etc/ssl/certs/ca.pem
  cert: /etc/ssl/private/client.crt
  key: /etc/ssl/private/client.key
```

## Configuration Management

### Environment-Specific Configs

```bash
# Development
cp configuration.yaml configuration.dev.yaml

# Production
cp configuration.yaml configuration.prod.yaml

# Use environment variable
export NODE_ENV=production
```

### Configuration Templates

```yaml
# Use templates for common settings
defaults: &defaults
  log_level: info
  retain: false
  qos: 1

mqtt:
  <<: *defaults
  server: mqtt://localhost:1883

device_options:
  <<: *defaults
  optimistic: true
```

## Next Steps

After configuration:

1. **[Start Device Management](device-management.md)** - Pair and configure devices
2. **[Set Up Monitoring](monitoring.md)** - Configure logging and maintenance
3. **[Integrate with Home Assistant](integration.md)** - Connect to automation platform

## Related Topics

- [Installation Guide](installation.md) - Installation methods and setup
- [Device Management](device-management.md) - Pairing and configuring devices
- [Troubleshooting](troubleshooting.md) - Configuration issues and solutions
- [Mosquitto MQTT Setup](../mosquitto/index.md) - MQTT broker configuration
