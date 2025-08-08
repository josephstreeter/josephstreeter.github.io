---
uid: misc.homeassistant.homeassistant.guidelines
title: Home Assistant Configuration Guidelines
description: Best practices and architectural guidelines for Home Assistant configuration
keywords: [home assistant, guidelines, best practices, architecture, configuration]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Configuration Guidelines

This guide establishes architectural principles and best practices for configuring Home Assistant to maximize functionality and flexibility while minimizing complexity.

### Design Philosophy

1. **Layered Architecture**: Build functionality in logical layers
2. **Modularity**: Keep components focused and reusable
3. **Maintainability**: Design for long-term maintenance and updates
4. **Scalability**: Plan for growth and expansion
5. **Reliability**: Prioritize stable, predictable operation

## Architectural Layers

### Layer 1: Device Entities (Foundation)

The foundation layer consists of physical devices and their raw entity states.

**Components:**

- Physical sensors (temperature, motion, contact)
- Smart devices (lights, switches, thermostats)
- External APIs and services
- Device trackers and presence detection

**Examples:**

```yaml
# Raw device entities
binary_sensor.front_door_contact
sensor.living_room_temperature  
light.kitchen_ceiling
climate.main_thermostat
device_tracker.john_phone
```

**Best Practices:**

- Use descriptive, consistent naming conventions
- Group related devices with area assignments
- Document device purposes and locations
- Maintain device-specific configurations separately

### Layer 2: Data Consolidation (Logic)

This layer processes and consolidates raw entity data into meaningful information.

**Components:**

- Template sensors for calculations and comparisons
- Groups for entity collections
- Binary sensors for state evaluation
- Statistical sensors for aggregation

**Examples:**

```yaml
# Temperature comparison template
template:
  - sensor:
      - name: "Temperature Recommendation"
        state: >
          {% set indoor = states('sensor.indoor_temp') | float %}
          {% set outdoor = states('sensor.outdoor_temp') | float %}
          {% if indoor > outdoor + 2 %}
            Open Windows
          {% elif outdoor > indoor + 2 %}
            Close Windows
          {% else %}
            Optimal
          {% endif %}

# Occupancy group
group:
  family_presence:
    name: "Family Home"
    entities:
      - device_tracker.john_phone
      - device_tracker.jane_phone
    all: false  # Anyone home = group home

# Security status binary sensor
template:
  - binary_sensor:
      - name: "Security Breach"
        state: >
          {% set armed = is_state('alarm_control_panel.home', 'armed_away') %}
          {% set doors_open = expand('group.door_sensors') | selectattr('state', 'eq', 'on') | list | length %}
          {{ armed and doors_open > 0 }}
```

**Best Practices:**

- Create single-purpose template sensors
- Use groups to simplify multi-entity logic
- Include error handling and default values
- Document template logic with comments

### Layer 3: Automation Logic (Actions)

Automations use consolidated data to trigger actions based on conditions.

**Components:**

- Event-driven automations
- Time-based automations
- State change automations
- Conditional logic chains

**Example Automation:**

```yaml
automation:
  - id: energy_efficiency_notification
    alias: "Energy Efficiency Notification"
    trigger:
      - platform: state
        entity_id: sensor.temperature_recommendation
        to: "Open Windows"
        for: "00:05:00"
    condition:
      - condition: state
        entity_id: climate.main_thermostat
        state: "cool"
      - condition: state
        entity_id: group.family_presence
        state: "home"
      - condition: time
        after: "08:00:00"
        before: "22:00:00"
    action:
      - service: notify.family_group
        data:
          title: "Energy Saving Opportunity"
          message: >
            It's cooler outside ({{ states('sensor.outdoor_temp') }}°C) 
            than inside ({{ states('sensor.indoor_temp') }}°C). 
            Consider opening windows and turning off AC.
          data:
            priority: low
            category: energy
```

**Best Practices:**

- Use descriptive automation IDs and aliases
- Include meaningful conditions to prevent false triggers
- Add delays to avoid rapid-fire triggers
- Group related automations by function

### Layer 4: Execution Layer (Implementation)

This layer handles the execution of complex actions through scripts, scenes, and area-based controls.

**Components:**

- Scripts for multi-step procedures
- Scenes for device state presets
- Area-based device control
- Service calls and integrations

**Example Script:**

```yaml
script:
  security_night_mode:
    alias: "Security Night Mode"
    sequence:
      - service: scene.turn_on
        target:
          entity_id: scene.all_lights_off
      - service: climate.set_temperature
        target:
          entity_id: climate.main_thermostat
        data:
          temperature: 68
      - service: alarm_control_panel.alarm_arm_night
        target:
          entity_id: alarm_control_panel.home
      - service: notify.security_log
        data:
          message: "Night mode activated at {{ now() }}"
    mode: single
```

**Example Scene:**

```yaml
scene:
  - name: "Movie Night"
    entities:
      light.living_room_main:
        state: on
        brightness: 20
        color_name: blue
      light.kitchen_under_cabinet:
        state: off
      media_player.living_room_tv:
        state: on
        source: "Netflix"
      climate.main_thermostat:
        temperature: 70
```

**Best Practices:**

- Create reusable scripts for common procedures
- Use scenes for comprehensive state management
- Implement proper error handling in scripts
- Test scripts individually before integration

### Layer 5: Notification and User Interface

The top layer manages user interactions and notifications.

**Components:**

- Notification groups and services
- Lovelace UI organization
- Mobile app integrations
- External service integrations

**Example Notification Groups:**

```yaml
# Notification groups
notify:
  - name: family_group
    platform: group
    services:
      - service: mobile_app_john_phone
      - service: mobile_app_jane_phone
        
  - name: security_alerts
    platform: group
    services:
      - service: mobile_app_john_phone
      - service: mobile_app_jane_phone
      - service: email_security

  - name: maintenance_alerts
    platform: group
    services:
      - service: mobile_app_john_phone
      - service: email_maintenance
```

## Configuration Organization

### File Structure

```text
config/
├── configuration.yaml          # Main configuration
├── secrets.yaml               # Sensitive data
├── automations.yaml           # All automations
├── scripts.yaml               # All scripts
├── scenes.yaml                # All scenes
├── groups.yaml                # All groups
├── customize.yaml             # Entity customizations
├── packages/                  # Feature-based packages
│   ├── climate.yaml
│   ├── security.yaml
│   ├── lighting.yaml
│   └── energy.yaml
├── integrations/              # Integration configs
│   ├── mqtt.yaml
│   ├── weather.yaml
│   └── notifications.yaml
└── ui-lovelace.yaml          # Lovelace configuration
```

### Package-Based Organization

```yaml
# packages/climate.yaml
climate_package:
  sensor:
    - platform: template
      sensors:
        climate_efficiency:
          # Climate-related template sensors
          
  automation:
    - id: climate_automation_1
      # Climate-related automations
      
  script:
    climate_comfort_mode:
      # Climate-related scripts
      
  group:
    climate_sensors:
      # Climate-related groups
```

## Naming Conventions

### Entity Naming Standards

```yaml
# Pattern: [area]_[device_type]_[specific_name]
sensor.living_room_temperature
binary_sensor.front_door_contact
light.kitchen_under_cabinet
switch.bedroom_fan

# Template sensors: descriptive purpose
sensor.energy_cost_today
binary_sensor.work_hours_active
sensor.temperature_recommendation

# Groups: function or area based
group.security_sensors
group.living_room_lights
group.family_devices

# Automations: descriptive action
automation.energy_efficiency_notification
automation.security_breach_alert
automation.morning_routine_workday
```

### Documentation Standards

```yaml
automation:
  - id: example_automation
    alias: "Descriptive Automation Name"
    description: |
      Detailed description of what this automation does,
      when it triggers, and what actions it performs.
      Include any special conditions or considerations.
    trigger:
      # Trigger configuration
    condition:
      # Condition configuration  
    action:
      # Action configuration
```

## Error Handling and Reliability

### Template Error Prevention

```yaml
# Always include default values
{{ states('sensor.temperature') | float(0) }}
{{ state_attr('climate.thermostat', 'current_temperature') | float(20) }}

# Check entity availability
{% if not is_state('sensor.outdoor_temp', 'unavailable') %}
  {{ states('sensor.outdoor_temp') }}
{% else %}
  N/A
{% endif %}

# Use safe entity references
{% set temp = states('sensor.temp') %}
{% if temp not in ['unavailable', 'unknown'] %}
  Temperature: {{ temp }}°C
{% endif %}
```

### Automation Safety

```yaml
automation:
  - id: safe_automation_example
    alias: "Safe Automation Example"
    trigger:
      - platform: state
        entity_id: sensor.example
    condition:
      # Multiple conditions for safety
      - condition: state
        entity_id: input_boolean.automation_enabled
        state: 'on'
      - condition: template
        value_template: "{{ trigger.to_state.state != 'unavailable' }}"
    action:
      - service: system_log.write
        data:
          message: "Automation {{ automation.entity_id }} triggered"
          level: info
      # Actual automation actions
    mode: single  # Prevent overlapping executions
```

## Performance Optimization

### Template Efficiency

```yaml
# ❌ Inefficient: Multiple state calls
{{ states('sensor.temp1') | float + states('sensor.temp2') | float + states('sensor.temp3') | float }}

# ✅ Efficient: Variable assignment
{% set temp1 = states('sensor.temp1') | float %}
{% set temp2 = states('sensor.temp2') | float %}
{% set temp3 = states('sensor.temp3') | float %}
{{ temp1 + temp2 + temp3 }}
```

### Resource Management

```yaml
# Reasonable scan intervals
sensor:
  - platform: template
    sensors:
      example_sensor:
        value_template: "{{ states('sensor.source') }}"
        # Don't update too frequently for expensive calculations
    scan_interval: 300  # 5 minutes
```

## Testing and Validation

### Configuration Testing

```bash
# Check configuration before restart
hass --script check_config

# Test specific components
hass --script check_config --info automation
hass --script check_config --info template
```

### Template Testing

Use Developer Tools > Template to test complex templates:

```jinja2
{% set entities = expand('group.test_group') %}
Entity count: {{ entities | list | length }}
States: {{ entities | map(attribute='state') | list }}
```

## Security Considerations

### Sensitive Data Management

```yaml
# Use secrets.yaml for sensitive data
http:
  api_password: !secret http_password
  
mqtt:
  username: !secret mqtt_username
  password: !secret mqtt_password
```

### Access Control

```yaml
# Limit external access
http:
  trusted_networks:
    - 192.168.1.0/24
    - 127.0.0.1
  ip_ban_enabled: true
  login_attempts_threshold: 5
```

This comprehensive guidelines document provides the architectural foundation for building maintainable, scalable Home Assistant configurations following industry best practices.
