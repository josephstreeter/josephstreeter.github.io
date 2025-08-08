---
uid: misc.homeassistant.zigbee2mqtt.integration
title: Zigbee2MQTT Home Assistant Integration
description: Complete guide to integrating Zigbee2MQTT with Home Assistant including MQTT discovery, entity customization, and automation examples
keywords: [zigbee2mqtt, home assistant, mqtt discovery, automations, entities, integration]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: how-to
---

This guide covers the complete integration of Zigbee2MQTT with Home Assistant, including MQTT discovery, entity customization, and advanced automation examples.

## Overview

Zigbee2MQTT provides seamless integration with Home Assistant through MQTT discovery, allowing automatic device detection and entity creation without manual configuration.

## Basic Integration Setup

### MQTT Discovery Configuration

Configure automatic device discovery in your Zigbee2MQTT configuration:

```yaml
# zigbee2mqtt/configuration.yaml
homeassistant:
  discovery_topic: homeassistant
  status_topic: homeassistant/status
  legacy_entity_attributes: false
  legacy_triggers: false
```

### Home Assistant MQTT Configuration

Ensure MQTT integration is configured in Home Assistant:

```yaml
# configuration.yaml
mqtt:
  broker: localhost
  port: 1883
  username: mqtt_user
  password: mqtt_password
  discovery: true
  discovery_prefix: homeassistant
```

## Entity Customization

### Device Naming and Organization

```yaml
# zigbee2mqtt/configuration.yaml
device_options:
  "0x00158d0001234567":
    friendly_name: "Living Room Temperature"
    homeassistant:
      name: "Living Room Sensor"
      device:
        name: "Xiaomi Temperature Sensor"
        model: "WSDCGQ11LM"
        manufacturer: "Xiaomi"
      
  "0x00158d0001234568":
    friendly_name: "Kitchen Motion"
    homeassistant:
      name: "Kitchen Motion Detector"
      expire_after: 600
      device_class: motion
```

### Entity Categories and Areas

```yaml
# Device options for organization
device_options:
  "living_room_light":
    homeassistant:
      entity_category: null
      area: "Living Room"
      
  "sensor_battery":
    homeassistant:
      entity_category: "diagnostic"
      device_class: "battery"
      unit_of_measurement: "%"
```

### Icon and Device Class Assignment

```yaml
# Customize entity appearance
device_options:
  "front_door_sensor":
    homeassistant:
      icon: "mdi:door"
      device_class: "door"
      
  "temperature_sensor":
    homeassistant:
      icon: "mdi:thermometer"
      device_class: "temperature"
      unit_of_measurement: "°C"
```

## Advanced Entity Configuration

### Availability Configuration

```yaml
# Global availability settings
availability:
  active:
    timeout: 10
  passive:
    timeout: 1500

# Per-device availability
device_options:
  "battery_sensor":
    availability: false  # Disable for battery devices
    
  "mains_device":
    availability: true
    availability_timeout: 30
```

### Entity Filtering

```yaml
# Control which entities are exposed
homeassistant:
  discovery_topic: homeassistant
  status_topic: homeassistant/status
  
# Block specific entities
blocklist:
  - "DEVICE_NAME/linkquality"
  - "DEVICE_NAME/update_available"

# Only allow specific entities
passlist:
  - "temperature"
  - "humidity"
  - "state"
```

## Automation Examples

### Motion-Based Lighting

```yaml
# automations.yaml
- id: motion_lighting
  alias: "Motion Activated Lighting"
  trigger:
    - platform: state
      entity_id: binary_sensor.hallway_motion
      to: 'on'
  condition:
    - condition: numeric_state
      entity_id: sensor.hallway_illuminance
      below: 100
    - condition: time
      after: "sunset"
      before: "sunrise"
  action:
    - service: light.turn_on
      target:
        entity_id: light.hallway_ceiling
      data:
        brightness_pct: 75
        transition: 2
    - delay: "00:05:00"
    - service: light.turn_off
      target:
        entity_id: light.hallway_ceiling
      data:
        transition: 5
```

### Temperature-Based Climate Control

```yaml
- id: temperature_control
  alias: "Smart Climate Control"
  trigger:
    - platform: state
      entity_id: sensor.living_room_temperature
  condition:
    - condition: numeric_state
      entity_id: sensor.living_room_temperature
      above: 24
  action:
    - choose:
        - conditions:
            - condition: state
              entity_id: climate.living_room_ac
              state: 'off'
          sequence:
            - service: climate.turn_on
              target:
                entity_id: climate.living_room_ac
            - service: climate.set_temperature
              target:
                entity_id: climate.living_room_ac
              data:
                temperature: 22
```

### Battery Level Monitoring

```yaml
- id: low_battery_alert
  alias: "Low Battery Alert"
  trigger:
    - platform: numeric_state
      entity_id: 
        - sensor.door_sensor_battery
        - sensor.motion_sensor_battery
        - sensor.window_sensor_battery
      below: 20
  action:
    - service: notify.mobile_app
      data:
        title: "Low Battery Warning"
        message: "{{ trigger.to_state.attributes.friendly_name }} battery is at {{ trigger.to_state.state }}%"
        data:
          tag: "low_battery_{{ trigger.entity_id }}"
          priority: high
```

### Device Offline Detection

```yaml
- id: device_offline_notification
  alias: "Device Offline Notification"
  trigger:
    - platform: state
      entity_id:
        - sensor.critical_sensor
        - binary_sensor.security_sensor
      to: 'unavailable'
      for: "00:10:00"
  action:
    - service: notify.admin
      data:
        title: "Device Offline"
        message: "{{ trigger.to_state.attributes.friendly_name }} has been offline for 10 minutes"
```

## Dashboard Integration

### Lovelace Card Examples

#### Device Status Card

```yaml
# Dashboard configuration
type: entities
title: Zigbee Device Status
entities:
  - entity: sensor.coordinator_version
    name: "Coordinator Version"
  - entity: sensor.zigbee_network_devices
    name: "Connected Devices"
  - entity: sensor.zigbee_permit_join
    name: "Permit Join"
  - type: divider
  - entity: sensor.living_room_temperature
  - entity: sensor.living_room_humidity
  - entity: binary_sensor.living_room_motion
```

#### Battery Level Overview

```yaml
type: custom:battery-state-card
title: "Zigbee Battery Levels"
entities:
  - entity: sensor.door_sensor_battery
  - entity: sensor.motion_sensor_battery
  - entity: sensor.window_sensor_battery
  - entity: sensor.remote_battery
sort_by_level: "asc"
collapse: 5
```

#### Network Map Visualization

```yaml
type: iframe
url: "http://localhost:8080/map"
title: "Zigbee Network Map"
aspect_ratio: 100%
```

## Groups and Scenes Integration

### Creating Groups via MQTT

```bash
# Create lighting group
mosquitto_pub -t "zigbee2mqtt/bridge/request/group/add" -m '{
  "friendly_name": "Living Room Lights",
  "id": 1
}'

# Add devices to group
mosquitto_pub -t "zigbee2mqtt/bridge/request/group/members/add" -m '{
  "group": "Living Room Lights",
  "device": "ceiling_light"
}'
```

### Scene Configuration

```yaml
# Home Assistant scenes.yaml
- name: "Movie Night"
  entities:
    light.living_room_lights:
      state: on
      brightness: 30
      color_temp: 350
    light.accent_lights:
      state: on
      brightness: 10
      rgb_color: [139, 69, 19]
    media_player.living_room_tv:
      state: on
```

## Advanced Integrations

### Node-RED Integration

```javascript
// Node-RED flow for complex automations
[
    {
        "id": "zigbee_processing",
        "type": "mqtt in",
        "topic": "zigbee2mqtt/+/+",
        "qos": "2",
        "broker": "mqtt_broker",
        "output": "auto",
        "name": "Zigbee Events"
    },
    {
        "id": "device_filter",
        "type": "function",
        "func": "if (msg.topic.includes('temperature')) {\n    return msg;\n}",
        "name": "Temperature Filter"
    }
]
```

### InfluxDB Integration

```yaml
# configuration.yaml
influxdb:
  host: localhost
  port: 8086
  database: homeassistant
  username: influx_user
  password: influx_password
  max_retries: 3
  default_measurement: state
  exclude:
    entities:
      - sensor.zigbee_coordinator_version
    domains:
      - camera
  include:
    entities:
      - sensor.living_room_temperature
      - sensor.living_room_humidity
```

### Grafana Dashboards

```json
{
  "dashboard": {
    "title": "Zigbee Sensor Data",
    "panels": [
      {
        "title": "Temperature Trends",
        "type": "graph",
        "targets": [
          {
            "measurement": "state",
            "where": [
              {
                "key": "entity_id",
                "operator": "=",
                "value": "sensor.living_room_temperature"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## Security Integration

### Alarm System Integration

```yaml
# Binary sensor for security
binary_sensor:
  - platform: template
    sensors:
      security_breach:
        friendly_name: "Security Breach"
        value_template: >
          {{
            is_state('binary_sensor.front_door', 'on') or
            is_state('binary_sensor.back_door', 'on') or
            is_state('binary_sensor.window_sensor', 'on')
          }}

# Automation for security alerts
automation:
  - alias: "Security Alert"
    trigger:
      - platform: state
        entity_id: binary_sensor.security_breach
        to: 'on'
    condition:
      - condition: state
        entity_id: alarm_control_panel.home
        state: 'armed_away'
    action:
      - service: notify.security_team
        data:
          message: "Security breach detected!"
      - service: camera.snapshot
        target:
          entity_id: camera.front_door
```

## Energy Management

### Smart Plug Monitoring

```yaml
# Energy monitoring automation
automation:
  - alias: "High Energy Usage Alert"
    trigger:
      - platform: numeric_state
        entity_id: sensor.smart_plug_power
        above: 1500
        for: "00:05:00"
    action:
      - service: notify.mobile_app
        data:
          title: "High Energy Usage"
          message: "Device consuming {{ states('sensor.smart_plug_power') }}W"
```

### Load Balancing

```yaml
- alias: "Load Balancing"
  trigger:
    - platform: numeric_state
      entity_id: sensor.total_power_consumption
      above: 8000
  action:
    - service: switch.turn_off
      target:
        entity_id: 
          - switch.non_essential_device_1
          - switch.non_essential_device_2
```

## Backup and Restore Integration

### Automated Backups

```yaml
# Shell command for backups
shell_command:
  backup_zigbee: "/home/homeassistant/scripts/backup_zigbee.sh"

# Automation for scheduled backups
automation:
  - alias: "Weekly Zigbee Backup"
    trigger:
      - platform: time
        at: "02:00:00"
    condition:
      - condition: time
        weekday:
          - sun
    action:
      - service: shell_command.backup_zigbee
```

## Troubleshooting Integration Issues

### Common Problems

1. **Entities Not Appearing:**
   - Check MQTT discovery configuration
   - Verify Home Assistant MQTT integration
   - Review entity filtering settings

2. **Entities Unavailable:**
   - Check device availability settings
   - Verify MQTT broker connectivity
   - Review device power status

3. **Automations Not Triggering:**
   - Verify entity IDs in automations
   - Check automation conditions
   - Review automation trace logs

### Diagnostic Commands

```bash
# Check MQTT discovery messages
mosquitto_sub -t "homeassistant/+/+/config" | head -20

# Monitor device state changes
mosquitto_sub -t "zigbee2mqtt/+/set"

# Check Home Assistant logs
tail -f /config/home-assistant.log | grep -i zigbee
```

## Best Practices

### Performance Optimization

1. **Use Groups:** Minimize MQTT traffic for multiple devices
2. **Configure Availability:** Disable for battery devices to reduce traffic
3. **Filter Entities:** Only expose necessary entities to Home Assistant
4. **Optimize Reporting:** Configure appropriate intervals for sensors

### Security Considerations

1. **MQTT Authentication:** Always use username/password
2. **Network Isolation:** Consider VLAN separation
3. **Access Control:** Limit MQTT topic access
4. **Regular Updates:** Keep both systems updated

### Maintenance Tasks

1. **Regular Monitoring:** Check entity states and availability
2. **Log Review:** Monitor for integration errors
3. **Performance Checks:** Monitor MQTT message rates
4. **Backup Verification:** Test restore procedures

---

> **Note:** This integration guide focuses on Home Assistant specifically. For other platforms like OpenHAB or Node-RED, similar principles apply but with platform-specific configuration methods.
