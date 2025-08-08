---
uid: misc.homeassistant.homeassistant.configuration
title: Home Assistant Configuration - Advanced Setup Guide
description: Advanced configuration options and best practices for Home Assistant
keywords: [home assistant, configuration, yaml, integrations, customization]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Advanced Configuration

This guide covers advanced Home Assistant configuration beyond the basic setup covered in the [main guide](index.md).

### Configuration File Organization

#### Split Configuration

Organize large configurations by splitting into multiple files:

```yaml
# configuration.yaml
homeassistant:
  packages: !include_dir_named packages

# Include separate files
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml
sensor: !include sensors.yaml
binary_sensor: !include binary_sensors.yaml
switch: !include switches.yaml
light: !include lights.yaml
group: !include groups.yaml
input_boolean: !include input_boolean.yaml
input_select: !include input_select.yaml
input_number: !include input_number.yaml
template: !include templates.yaml

# Include directories
automation old: !include_dir_list automations/
sensor manual: !include_dir_merge_list sensors/
```

#### Package Configuration

Group related configuration in packages:

```yaml
# packages/security.yaml
security:
  input_boolean:
    security_system:
      name: "Security System"
      initial: false
      icon: mdi:security
    
  automation:
    - alias: "Security Arm Away"
      trigger:
        - platform: state
          entity_id: input_boolean.security_system
          to: "on"
      action:
        - service: alarm_control_panel.alarm_arm_away
          target:
            entity_id: alarm_control_panel.home
    
  sensor:
    - platform: template
      sensors:
        security_status:
          friendly_name: "Security Status"
          value_template: >
            {% if is_state('input_boolean.security_system', 'on') %}
              Armed
            {% else %}
              Disarmed
            {% endif %}
```

### Database Configuration

#### PostgreSQL Setup

```yaml
# For better performance with large datasets
recorder:
  db_url: postgresql://homeassistant:password@localhost:5432/homeassistant
  purge_keep_days: 90
  commit_interval: 5
  auto_purge: true
  
  # Include only what you need
  include:
    domains:
      - sensor
      - binary_sensor
      - switch
      - light
      - climate
      - cover
      - lock
      - alarm_control_panel
    entity_globs:
      - sensor.energy_*
      - sensor.temperature_*
  
  exclude:
    domains:
      - automation
      - script
      - scene
      - zone
    entities:
      - sensor.time
      - sensor.date
      - sensor.uptime
    entity_globs:
      - sensor.*_battery
      - binary_sensor.*_update_available
```

#### InfluxDB Integration

```yaml
influxdb:
  host: localhost
  port: 8086
  database: homeassistant
  username: homeassistant
  password: !secret influxdb_password
  max_retries: 3
  default_measurement: state
  
  # Include specific measurements
  include:
    domains:
      - sensor
      - binary_sensor
    entities:
      - weather.home
  
  exclude:
    entity_globs:
      - sensor.*_battery
      - sensor.*_signal_strength
  
  # Custom measurements
  component_config:
    sensor.outside_temperature:
      override_measurement: temperature
    sensor.outside_humidity:
      override_measurement: humidity
```

### Network Configuration

#### HTTP Component Advanced Settings

```yaml
http:
  server_port: 8123
  server_host: 0.0.0.0
  
  # SSL Configuration
  ssl_certificate: /ssl/fullchain.pem
  ssl_key: /ssl/privkey.pem
  ssl_profile: intermediate
  
  # CORS settings
  cors_allowed_origins:
    - https://cast.home-assistant.io
    - https://yourdomain.duckdns.org
  
  # Trusted networks
  trusted_networks:
    - 192.168.1.0/24
    - 10.0.0.0/8
    - 172.16.0.0/12
    - 127.0.0.1
    - ::1
  
  # Trusted proxies (for reverse proxy setups)
  trusted_proxies:
    - 192.168.1.10  # Nginx proxy
  
  # IP ban configuration
  ip_ban_enabled: true
  login_attempts_threshold: 5
  
  # Use X-Forwarded-For headers
  use_x_forwarded_for: true
```

#### Reverse Proxy Configuration

Nginx configuration for Home Assistant:

```nginx
# /etc/nginx/sites-available/homeassistant
server {
    listen 443 ssl http2;
    server_name yourdomain.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/yourdomain.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.duckdns.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://192.168.1.100:8123;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name yourdomain.duckdns.org;
    return 301 https://$server_name$request_uri;
}
```

### Authentication and Security

#### Multi-Factor Authentication

```yaml
# Enable MFA for users
auth_mfa_modules:
  - type: totp
    name: Authenticator app
  - type: notify
    message: "Please confirm login from {{ user_name }}"
```

#### User Management

```yaml
# Advanced user configuration
homeassistant:
  auth_providers:
    - type: homeassistant
    - type: trusted_networks
      trusted_networks:
        - 192.168.1.0/24
      trusted_users:
        192.168.1.0/24: 
          - local_user
      allow_bypass_login: true
```

### Energy Management Configuration

```yaml
# Energy dashboard configuration
energy:
  # Electricity grid
  electricity:
    grid:
      - sensor: sensor.grid_consumption
        cost_entity: sensor.electricity_price
      - sensor: sensor.grid_production
        compensation_entity: sensor.feed_in_tariff
  
  # Solar panels
  solar:
    - sensor: sensor.solar_production
      config_entry_id: solar_config_id
  
  # Gas consumption
  gas:
    - sensor: sensor.gas_consumption
      cost_entity: sensor.gas_price
  
  # Individual devices
  device_consumption:
    - sensor: sensor.washing_machine_energy
    - sensor: sensor.dishwasher_energy
    - sensor: sensor.heat_pump_energy
```

### Advanced Logging

```yaml
# Detailed logging configuration
logger:
  default: info
  logs:
    homeassistant.core: debug
    homeassistant.components.mqtt: debug
    homeassistant.components.zha: info
    homeassistant.components.automation: info
    custom_components.my_integration: debug
    
    # Third-party libraries
    paho.mqtt.client: warning
    urllib3.connectionpool: warning
    
  # Log to file
  file: /config/home-assistant.log
  max_size: 10MB
  backup_count: 3
```

### Performance Optimization

#### History Configuration

```yaml
history:
  # Include only necessary domains
  include:
    domains:
      - sensor
      - binary_sensor
      - switch
      - light
      - climate
    entity_globs:
      - sensor.energy_*
      - sensor.temperature_*
  
  exclude:
    domains:
      - automation
      - script
    entities:
      - sensor.time
      - sensor.date
    entity_globs:
      - sensor.*_battery
      - binary_sensor.*_connectivity
```

#### Logbook Optimization

```yaml
logbook:
  include:
    domains:
      - light
      - switch
      - climate
      - cover
      - lock
      - alarm_control_panel
    entities:
      - binary_sensor.front_door
      - binary_sensor.back_door
  
  exclude:
    domains:
      - sensor
      - device_tracker
    entity_globs:
      - automation.*
      - script.*
```

### Custom Component Configuration

#### HACS Integration

```yaml
# HACS (Home Assistant Community Store)
hacs:
  token: !secret github_token
  sidepanel_title: Community Store
  sidepanel_icon: mdi:store
  experimental: true
  
  # Custom repositories
  repositories:
    - username/repository-name
```

#### Custom Integration Example

```yaml
# Custom weather integration
weather:
  - platform: custom_weather
    name: "Local Weather Station"
    api_key: !secret weather_api_key
    latitude: !secret home_latitude
    longitude: !secret home_longitude
    update_interval: 600  # 10 minutes
```

### Theme Configuration

```yaml
# Frontend themes
frontend:
  themes:
    dark_theme:
      # Main colors
      primary-color: "#1976D2"
      accent-color: "#FF9800"
      dark-primary-color: "#0D47A1"
      light-primary-color: "#BBDEFB"
      
      # Text colors
      primary-text-color: "#FFFFFF"
      secondary-text-color: "#BDBDBD"
      disabled-text-color: "#757575"
      
      # Background colors
      primary-background-color: "#121212"
      secondary-background-color: "#1E1E1E"
      divider-color: "#2C2C2C"
      
      # Card colors
      card-background-color: "#1E1E1E"
      paper-card-header-color: "var(--accent-color)"
      
      # Sidebar
      sidebar-icon-color: "#FFFFFF"
      sidebar-text-color: "#FFFFFF"
      sidebar-background-color: "#2C2C2C"
      
  # Extra module URLs for custom cards
  extra_module_url:
    - /hacsfiles/lovelace-card-mod/card-mod.js
    - /hacsfiles/mini-graph-card/mini-graph-card-bundle.js
```

### Notification Configuration

#### Advanced Notification Settings

```yaml
# iOS notifications
ios:
  push:
    categories:
      - name: Security Alert
        identifier: 'security_alert'
        actions:
          - identifier: 'DISARM_SECURITY'
            title: 'Disarm'
            activationMode: 'background'
            authenticationRequired: true
            destructive: false
          - identifier: 'CALL_POLICE'
            title: 'Call Police'
            activationMode: 'foreground'
            authenticationRequired: true
            destructive: true

# Email notifications
notify:
  - name: email_alerts
    platform: smtp
    server: smtp.gmail.com
    port: 587
    timeout: 15
    sender: !secret email_sender
    encryption: starttls
    username: !secret email_username
    password: !secret email_password
    recipient:
      - user1@example.com
      - user2@example.com
    sender_name: "Home Assistant"
```

### System Health Monitoring

```yaml
# System health sensors
system_health:

# System monitor
system_monitor:
  resources:
    - type: disk_use_percent
      arg: /config
    - type: disk_use
      arg: /config
    - type: disk_free
      arg: /config
    - type: memory_use_percent
    - type: memory_use
    - type: memory_free
    - type: load_1m
    - type: load_5m
    - type: load_15m
    - type: processor_use
    - type: processor_temperature
    - type: last_boot
    - type: throughput_network_in
      arg: eth0
    - type: throughput_network_out
      arg: eth0
```

### Backup Configuration

```yaml
# Automated backup configuration for HAOS
backup:
  create_backup: true
  keep_days: 7
  
# For container/core installations
shell_command:
  backup_config: 'tar -czf /config/backups/config_$(date +%Y%m%d_%H%M%S).tar.gz -C /config --exclude="backups" --exclude="*.log" --exclude="*.db" .'
  
automation:
  - alias: "Weekly Config Backup"
    trigger:
      - platform: time
        at: "02:00:00"
    condition:
      - condition: time
        weekday:
          - sun
    action:
      - service: shell_command.backup_config
```

### Integration-Specific Configuration

For MQTT and Zigbee integrations, refer to the dedicated guides:

- **[Mosquitto MQTT Configuration](../mosquitto/index.md)**
- **[Zigbee2MQTT Configuration](../zigbee2mqtt/index.md)**

### Environment Variables and Secrets

```yaml
# secrets.yaml
mqtt_username: your_mqtt_user
mqtt_password: your_mqtt_password
db_url: postgresql://user:pass@localhost/hass
influxdb_password: your_influxdb_password
email_password: your_email_app_password
github_token: your_github_token

# Using environment variables
homeassistant:
  latitude: !env_var HA_LATITUDE
  longitude: !env_var HA_LONGITUDE
```

### Configuration Validation

```bash
# Check configuration before restart
hass --script check_config

# Test specific configuration
hass --script check_config --info all
hass --script check_config --files
```

This advanced configuration guide provides the foundation for a robust, scalable Home Assistant installation. Remember to always backup your configuration before making significant changes.
