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

**Packages** allow you to organize related Home Assistant configuration into logical units within a single file. This is particularly useful for grouping all entities, automations, and scripts related to a specific system or room. Unlike split configuration, which separates by entity type, packages organize by functionality or purpose.

**Benefits of Package Configuration:**

- **Logical Organization**: Keep all components of a feature together
- **Easy Management**: Enable/disable entire systems by commenting out one line
- **Modular Design**: Share packages between installations
- **Reduced Complexity**: Avoid searching across multiple files for related configurations

**Package Structure:**
Each package file contains a top-level key (the package name) with all related entities nested underneath. You can include any Home Assistant configuration domain within a package.

**Configuration Steps:**

1. Create a `packages` directory in your config folder
2. Add the packages include to your `configuration.yaml`
3. Create individual package files for each system

```yaml
# configuration.yaml - Enable packages
homeassistant:
  packages: !include_dir_named packages
```

```yaml
# packages/security.yaml - Complete security system package
security_system:
  # Input helpers for system control
  input_boolean:
    security_system:
      name: "Security System"
      initial: false
      icon: mdi:security
    
    vacation_mode:
      name: "Vacation Mode"
      initial: false
      icon: mdi:airplane
  
  input_select:
    security_mode:
      name: "Security Mode"
      options:
        - "Home"
        - "Away" 
        - "Night"
        - "Vacation"
      initial: "Home"
      icon: mdi:shield-home

  # Template sensors for status reporting
  sensor:
    - platform: template
      sensors:
        security_status:
          friendly_name: "Security Status"
          value_template: >
            {% if is_state('input_boolean.security_system', 'on') %}
              {% if is_state('input_select.security_mode', 'Away') %}
                Armed Away
              {% elif is_state('input_select.security_mode', 'Night') %}
                Armed Night
              {% elif is_state('input_select.security_mode', 'Vacation') %}
                Armed Vacation
              {% else %}
                Armed Home
              {% endif %}
            {% else %}
              Disarmed
            {% endif %}
          icon_template: >
            {% if is_state('input_boolean.security_system', 'on') %}
              mdi:shield-check
            {% else %}
              mdi:shield-off
            {% endif %}
        
        open_doors_windows:
          friendly_name: "Open Doors & Windows"
          value_template: >
            {{ states.binary_sensor 
               | selectattr('attributes.device_class', 'in', ['door', 'window'])
               | selectattr('state', 'eq', 'on')
               | list | count }}
          unit_of_measurement: "open"

  # Automation for security system
  automation:
    - alias: "Security Arm Away"
      description: "Arm security system when mode changes to Away"
      trigger:
        - platform: state
          entity_id: input_select.security_mode
          to: "Away"
        - platform: state
          entity_id: input_boolean.security_system
          to: "on"
      condition:
        - condition: state
          entity_id: input_boolean.security_system
          state: "on"
        - condition: state
          entity_id: input_select.security_mode
          state: "Away"
      action:
        - service: alarm_control_panel.alarm_arm_away
          target:
            entity_id: alarm_control_panel.home
        - service: notify.mobile_app_phone
          data:
            title: "Security System"
            message: "Security system armed in Away mode"

    - alias: "Security Breach Alert"
      description: "Send alert when security breach detected"
      trigger:
        - platform: state
          entity_id: group.all_doors_windows
          to: "on"
      condition:
        - condition: state
          entity_id: input_boolean.security_system
          state: "on"
      action:
        - service: notify.mobile_app_phone
          data:
            title: "🚨 Security Alert"
            message: "Door or window opened while security system is armed!"
            data:
              actions:
                - action: "DISARM_SECURITY"
                  title: "Disarm System"
                - action: "VIEW_CAMERAS"
                  title: "View Cameras"

  # Scripts for common actions
  script:
    arm_away_sequence:
      alias: "Arm Security Away Sequence"
      description: "Complete sequence to arm security system for away mode"
      sequence:
        - service: input_select.select_option
          target:
            entity_id: input_select.security_mode
          data:
            option: "Away"
        - service: input_boolean.turn_on
          target:
            entity_id: input_boolean.security_system
        - service: light.turn_off
          target:
            entity_id: group.all_lights
        - service: climate.set_temperature
          target:
            entity_id: climate.main_thermostat
          data:
            temperature: 65
        - service: lock.lock
          target:
            entity_id: group.all_locks

    disarm_security:
      alias: "Disarm Security System"
      description: "Disarm security system and restore home mode"
      sequence:
        - service: input_boolean.turn_off
          target:
            entity_id: input_boolean.security_system
        - service: input_select.select_option
          target:
            entity_id: input_select.security_mode
          data:
            option: "Home"
        - service: notify.mobile_app_phone
          data:
            title: "Security System"
            message: "Security system disarmed"

  # Groups for easier management
  group:
    security_controls:
      name: "Security Controls"
      entities:
        - input_boolean.security_system
        - input_select.security_mode
        - input_boolean.vacation_mode
        - sensor.security_status
        - sensor.open_doors_windows

  # Binary sensor for overall security status
  binary_sensor:
    - platform: template
      sensors:
        security_breach:
          friendly_name: "Security Breach"
          device_class: safety
          value_template: >
            {{ is_state('input_boolean.security_system', 'on') and 
               states('sensor.open_doors_windows') | int > 0 }}
```

**Additional Package Examples:**

```yaml
# packages/climate.yaml - Climate control package
climate_control:
  input_number:
    target_temperature:
      name: "Target Temperature"
      min: 60
      max: 80
      step: 1
      unit_of_measurement: "°F"
      icon: mdi:thermometer

  automation:
    - alias: "Climate Schedule Morning"
      trigger:
        - platform: time
          at: "06:00:00"
      action:
        - service: climate.set_temperature
          target:
            entity_id: climate.main_thermostat
          data:
            temperature: "{{ states('input_number.target_temperature') | int }}"
```

```yaml
# packages/lighting.yaml - Lighting automation package  
lighting_system:
  input_boolean:
    auto_lights:
      name: "Automatic Lights"
      initial: true
      icon: mdi:lightbulb-auto

  automation:
    - alias: "Motion Activated Lights"
      trigger:
        - platform: state
          entity_id: binary_sensor.motion_hallway
          to: "on"
      condition:
        - condition: state
          entity_id: input_boolean.auto_lights
          state: "on"
        - condition: sun
          after: sunset
      action:
        - service: light.turn_on
          target:
            entity_id: light.hallway
          data:
            brightness: 128
```

**Package Management Tips:**

- Use descriptive package names that reflect their purpose
- Include all related entities in a single package file
- Comment your packages thoroughly for future reference
- Test packages in isolation by temporarily disabling others
- Use consistent naming conventions across all packages
- Consider creating packages for: rooms, systems, seasonal automations, and device types

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
