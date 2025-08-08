---
uid: misc.homeassistant.homeassistant.groups
title: Home Assistant Groups - Complete Guide
description: Comprehensive guide to creating and managing groups in Home Assistant
keywords: [home assistant, groups, organization, entities, automation]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Groups

Groups allow you to organize entities into logical collections for easier management, automation, and UI organization. This guide covers all aspects of Home Assistant groups.

### Group Types Overview

1. **Basic Groups**: Simple entity collections
2. **Domain Groups**: All entities of a specific type
3. **Area-Based Groups**: Entities grouped by physical location
4. **Functional Groups**: Entities grouped by purpose
5. **Dynamic Groups**: Template-based entity selection

## Basic Groups Configuration

### Simple Entity Groups

```yaml
# Standard group configuration
group:
  living_room_lights:
    name: "Living Room Lights"
    entities:
      - light.ceiling_light
      - light.floor_lamp
      - light.table_lamp
    icon: mdi:lightbulb-group
    
  security_sensors:
    name: "Security Sensors"
    entities:
      - binary_sensor.front_door
      - binary_sensor.back_door
      - binary_sensor.motion_detector
      - binary_sensor.window_sensor
    icon: mdi:security
```

### Device Tracking Groups

```yaml
# Occupancy detection groups
group:
  family_devices:
    name: "Family Devices"
    entities:
      - device_tracker.john_phone
      - device_tracker.jane_phone
      - device_tracker.kids_tablet
    all: false  # Any device home = group home
    
  adults_only:
    name: "Adult Devices"
    entities:
      - device_tracker.john_phone
      - device_tracker.jane_phone
    all: true   # All devices must be home
    
  work_devices:
    name: "Work Devices"
    entities:
      - device_tracker.work_laptop
      - device_tracker.company_phone
    all: false
```

### Climate and Environmental Groups

```yaml
group:
  temperature_sensors:
    name: "Temperature Sensors"
    entities:
      - sensor.living_room_temperature
      - sensor.bedroom_temperature
      - sensor.kitchen_temperature
      - sensor.outdoor_temperature
    icon: mdi:thermometer
    
  humidity_sensors:
    name: "Humidity Sensors"
    entities:
      - sensor.living_room_humidity
      - sensor.bedroom_humidity
      - sensor.bathroom_humidity
    icon: mdi:water-percent
    
  climate_control:
    name: "Climate Control"
    entities:
      - climate.main_thermostat
      - climate.bedroom_ac
      - fan.ceiling_fan
      - switch.humidifier
```

## Advanced Group Configurations

### Room-Based Organization

```yaml
# Complete room groups
group:
  living_room:
    name: "Living Room"
    entities:
      - light.living_room_ceiling
      - light.living_room_lamp
      - media_player.living_room_tv
      - sensor.living_room_temperature
      - binary_sensor.living_room_motion
      - switch.living_room_fan
    icon: mdi:sofa
    
  bedroom:
    name: "Bedroom"
    entities:
      - light.bedroom_ceiling
      - light.bedside_lamp
      - climate.bedroom_ac
      - sensor.bedroom_temperature
      - binary_sensor.bedroom_motion
      - switch.bedroom_fan
    icon: mdi:bed
    
  kitchen:
    name: "Kitchen" 
    entities:
      - light.kitchen_ceiling
      - light.under_cabinet
      - sensor.kitchen_temperature
      - binary_sensor.kitchen_motion
      - switch.coffee_maker
      - switch.dishwasher
    icon: mdi:chef-hat
```

### Security and Safety Groups

```yaml
group:
  door_sensors:
    name: "Door Sensors"
    entities:
      - binary_sensor.front_door
      - binary_sensor.back_door
      - binary_sensor.garage_door
      - binary_sensor.patio_door
    icon: mdi:door
    
  window_sensors:
    name: "Window Sensors" 
    entities:
      - binary_sensor.living_room_window
      - binary_sensor.bedroom_window
      - binary_sensor.kitchen_window
    icon: mdi:window-closed
    
  motion_sensors:
    name: "Motion Sensors"
    entities:
      - binary_sensor.living_room_motion
      - binary_sensor.bedroom_motion
      - binary_sensor.kitchen_motion
      - binary_sensor.outdoor_motion
    icon: mdi:motion-sensor
    
  smoke_detectors:
    name: "Smoke Detectors"
    entities:
      - binary_sensor.living_room_smoke
      - binary_sensor.bedroom_smoke
      - binary_sensor.kitchen_smoke
    icon: mdi:smoke-detector
```

### Energy Management Groups

```yaml
group:
  energy_monitors:
    name: "Energy Monitors"
    entities:
      - sensor.total_power_usage
      - sensor.solar_power_production
      - sensor.battery_charge_level
      - sensor.grid_power_import
    icon: mdi:lightning-bolt
    
  high_power_devices:
    name: "High Power Devices"
    entities:
      - switch.water_heater
      - switch.dryer
      - switch.air_conditioner
      - switch.electric_vehicle_charger
    icon: mdi:flash
    
  always_on_devices:
    name: "Always On Devices"
    entities:
      - switch.refrigerator
      - switch.router
      - switch.security_system
      - switch.nas_server
```

## Dynamic and Template Groups

### Template-Based Groups

```yaml
# Template groups for dynamic membership
template:
  - sensor:
      - name: "Low Battery Devices"
        state: >
          {% set batteries = expand('group.battery_sensors') 
             | selectattr('state', 'is_number')
             | selectattr('state', 'lt', 20) 
             | map(attribute='name') | list %}
          {{ batteries | length }}
        attributes:
          devices: >
            {% set batteries = expand('group.battery_sensors') 
               | selectattr('state', 'is_number')
               | selectattr('state', 'lt', 20) 
               | map(attribute='name') | list %}
            {{ batteries }}
          icon: >
            {% set count = this.state | int %}
            {% if count == 0 %}
              mdi:battery
            {% elif count < 3 %}
              mdi:battery-alert
            {% else %}
              mdi:battery-alert-variant
            {% endif %}
            
  - binary_sensor:
      - name: "Any Windows Open"
        state: >
          {{ expand('group.window_sensors') 
             | selectattr('state', 'eq', 'on') 
             | list | length > 0 }}
        icon: >
          {% if this.state %}
            mdi:window-open
          {% else %}
            mdi:window-closed
          {% endif %}
```

### Conditional Groups

```yaml
# Groups that change based on conditions
automation:
  - id: update_active_lights_group
    alias: "Update Active Lights Group"
    trigger:
      - platform: state
        entity_id: 
          - group.all_lights
    action:
      - service: group.set
        target:
          entity_id: group.active_lights
        data:
          entities: >
            {{ expand('group.all_lights') 
               | selectattr('state', 'eq', 'on') 
               | map(attribute='entity_id') | list }}
```

## Domain Groups (All Entities)

### Automatic Domain Groups

```yaml
# These are created automatically by Home Assistant
# group.all_lights - all light entities
# group.all_switches - all switch entities  
# group.all_binary_sensors - all binary sensor entities
# group.all_sensors - all sensor entities

# You can create custom domain groups
group:
  all_motion_sensors:
    name: "All Motion Sensors"
    entities: >
      {{ expand('binary_sensor') 
         | selectattr('attributes.device_class', 'eq', 'motion')
         | map(attribute='entity_id') | list }}
    icon: mdi:motion-sensor
```

## Group Operations and Automation

### Group State Logic

```yaml
# Automation using group states
automation:
  - id: all_lights_off_notification
    alias: "All Lights Off Notification"
    trigger:
      - platform: state
        entity_id: group.all_lights
        to: 'off'
    action:
      - service: notify.mobile_app
        data:
          message: "All lights are now off"
          
  - id: any_door_open_security
    alias: "Any Door Open Security Alert"
    trigger:
      - platform: state
        entity_id: group.door_sensors
        to: 'on'
    condition:
      - condition: state
        entity_id: alarm_control_panel.home
        state: 'armed_away'
    action:
      - service: notify.security_team
        data:
          message: "Door opened while armed: {{ trigger.to_state.name }}"
```

### Group-Based Scene Control

```yaml
# Scenes using groups
scene:
  - name: "Movie Night"
    entities:
      group.living_room_lights:
        state: 'on'
        brightness: 30
      group.entertainment_devices:
        state: 'on'
      group.ambient_lights:
        state: 'on'
        color_name: 'blue'
        
  - name: "Good Night"
    entities:
      group.all_lights:
        state: 'off'
      group.entertainment_devices:
        state: 'off'
      group.security_sensors:
        state: 'armed'
```

## UI and Frontend Groups

### Lovelace Card Groups

```yaml
# Use groups in Lovelace cards
type: entities
title: "Living Room Controls"
entities:
  - group.living_room_lights
  - group.living_room_climate
  - group.living_room_entertainment

# Or expand group entities
type: entities
title: "All Lights"
entities:
  - entity: group.all_lights
    type: custom:fold-entity-row
    head:
      type: section
      label: "Lights"
    entities:
      - light.living_room
      - light.bedroom
      - light.kitchen
```

### Group Badges and Monitoring

```yaml
# Create monitoring dashboards
type: horizontal-stack
cards:
  - type: entity
    entity: group.security_sensors
    name: "Security"
    icon: mdi:shield-home
    
  - type: entity
    entity: group.climate_sensors
    name: "Climate"
    icon: mdi:home-thermometer
    
  - type: entity
    entity: group.energy_monitors
    name: "Energy"
    icon: mdi:flash
```

## Advanced Group Patterns

### Nested Groups

```yaml
group:
  # Sub-groups
  upstairs_lights:
    name: "Upstairs Lights"
    entities:
      - light.master_bedroom
      - light.guest_bedroom
      - light.upstairs_hall
      
  downstairs_lights:
    name: "Downstairs Lights"
    entities:
      - light.living_room
      - light.kitchen
      - light.dining_room
      
  # Parent group containing sub-groups
  house_lights:
    name: "House Lights"
    entities:
      - group.upstairs_lights
      - group.downstairs_lights
      - light.outdoor_front
      - light.outdoor_back
```

### Smart Group Management

```yaml
# Automatically maintain groups based on entity attributes
automation:
  - id: update_battery_group
    alias: "Update Battery Sensors Group"
    trigger:
      - platform: homeassistant
        event: start
      - platform: time
        at: "00:00:00"
    action:
      - service: group.set
        target:
          entity_id: group.battery_sensors
        data:
          entities: >
            {{ states.sensor 
               | selectattr('attributes.device_class', 'eq', 'battery')
               | map(attribute='entity_id') | list +
               states.binary_sensor 
               | selectattr('attributes.device_class', 'eq', 'battery')
               | map(attribute='entity_id') | list }}
```

### Group Statistics and Monitoring

```yaml
# Create statistical sensors from groups
sensor:
  - platform: template
    sensors:
      average_temperature:
        friendly_name: "Average Temperature"
        unit_of_measurement: "°C"
        value_template: >
          {{ expand('group.temperature_sensors') 
             | map(attribute='state') | map('float') 
             | average | round(1) }}
             
      total_power_usage:
        friendly_name: "Total Power Usage"
        unit_of_measurement: "W"
        value_template: >
          {{ expand('group.power_sensors') 
             | map(attribute='state') | map('float') 
             | sum | round(1) }}
             
      lights_on_count:
        friendly_name: "Lights On Count"
        value_template: >
          {{ expand('group.all_lights') 
             | selectattr('state', 'eq', 'on') 
             | list | length }}
```

## Best Practices

1. **Logical Organization**: Group entities by function, location, or type
2. **Descriptive Names**: Use clear, descriptive names for groups
3. **Icon Selection**: Choose appropriate icons for visual identification
4. **Nested Structure**: Use hierarchical groups for complex organizations
5. **Documentation**: Comment group purposes in configuration files
6. **Dynamic Updates**: Use automations to maintain group membership
7. **Performance**: Keep groups reasonably sized for better performance
8. **UI Integration**: Design groups with frontend usage in mind

## Troubleshooting Groups

### Common Issues

1. **Entity Not Found**: Verify entity IDs are correct
2. **Group Not Updating**: Check entity states and group logic
3. **Performance Issues**: Reduce group size or update frequency
4. **UI Display Problems**: Verify group configuration in Lovelace

### Debug Group States

```yaml
# Template to debug group composition
template:
  - sensor:
      - name: "Group Debug Info"
        state: "{{ expand('group.test_group') | list | length }}"
        attributes:
          entities: "{{ expand('group.test_group') | map(attribute='entity_id') | list }}"
          states: "{{ expand('group.test_group') | map(attribute='state') | list }}"
          on_count: "{{ expand('group.test_group') | selectattr('state', 'eq', 'on') | list | length }}"
```

This comprehensive groups guide provides the foundation for organizing and managing entities effectively in Home Assistant.
