---
uid: misc.homeassistant.homeassistant.automations
title: Home Assistant Automations - Complete Guide
description: Comprehensive guide to creating and managing Home Assistant automations
keywords: [home assistant, automations, triggers, conditions, actions, yaml, blueprint]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Automations

Automations are the heart of Home Assistant, allowing you to create intelligent responses to events and conditions in your home. This guide covers everything from basic automations to advanced scripting techniques.

## Overview

Home Assistant automations consist of three main components:

- **Triggers**: Events that start the automation
- **Conditions**: Optional tests that must pass for actions to run
- **Actions**: What happens when triggered (and conditions are met)

### Basic Automation Structure

```yaml
automation:
  - alias: "Descriptive Name"
    description: "Optional detailed description"
    trigger:
      # What starts the automation
    condition:
      # Optional conditions that must be met
    action:
      # What happens when triggered
    mode: single  # How to handle multiple triggers
```

## Triggers

### Time-Based Triggers

#### Time Pattern Trigger

```yaml
trigger:
  - platform: time_pattern
    # Every hour at 30 minutes
    minutes: 30
    
  - platform: time_pattern
    # Every 15 minutes
    minutes: "/15"
    
  - platform: time_pattern
    # At 2 AM every day
    hours: 2
    minutes: 0
```

#### Specific Time Trigger

```yaml
trigger:
  - platform: time
    at: "07:00:00"
    
  - platform: time
    at: 
      - "06:30:00"
      - "07:00:00"
      - "07:30:00"
```

#### Sun-Based Triggers

```yaml
trigger:
  - platform: sun
    event: sunrise
    offset: "-00:30:00"  # 30 minutes before sunrise
    
  - platform: sun
    event: sunset
    offset: "00:15:00"   # 15 minutes after sunset
```

### State-Based Triggers

#### Entity State Change

```yaml
trigger:
  - platform: state
    entity_id: binary_sensor.front_door
    from: "off"
    to: "on"
    
  - platform: state
    entity_id: sensor.temperature
    above: 25
    
  - platform: state
    entity_id: light.living_room
    to: "on"
    for:
      minutes: 10  # Must stay on for 10 minutes
```

#### Multiple Entity Trigger

```yaml
trigger:
  - platform: state
    entity_id: 
      - binary_sensor.motion_living_room
      - binary_sensor.motion_kitchen
      - binary_sensor.motion_bedroom
    from: "off"
    to: "on"
```

#### Attribute Change Trigger

```yaml
trigger:
  - platform: state
    entity_id: climate.thermostat
    attribute: temperature
    above: 22
```

### Event-Based Triggers

#### Device Triggers

```yaml
trigger:
  - platform: device
    device_id: abc123def456
    domain: zha
    type: remote_button_short_press
    subtype: button_1
```

#### MQTT Triggers

```yaml
trigger:
  - platform: mqtt
    topic: "zigbee2mqtt/button/action"
    payload: "single"
```

#### Webhook Triggers

```yaml
trigger:
  - platform: webhook
    webhook_id: doorbell_pressed
    local_only: true
```

### Zone and Location Triggers

```yaml
trigger:
  - platform: zone
    entity_id: person.john
    zone: zone.home
    event: enter
    
  - platform: zone
    entity_id: person.john
    zone: zone.work
    event: leave
```

## Conditions

### Time-Based Conditions

```yaml
condition:
  - condition: time
    after: "22:00:00"
    before: "06:00:00"
    weekday:
      - mon
      - tue
      - wed
      - thu
      - fri
```

### State-Based Conditions

```yaml
condition:
  - condition: state
    entity_id: input_boolean.vacation_mode
    state: "off"
    
  - condition: numeric_state
    entity_id: sensor.temperature
    below: 20
    
  - condition: state
    entity_id: person.john
    state: "home"
    for:
      minutes: 15
```

### Multiple Conditions

#### AND Conditions (all must be true)

```yaml
condition:
  - condition: state
    entity_id: light.living_room
    state: "off"
  - condition: sun
    after: sunset
```

#### OR Conditions (any must be true)

```yaml
condition:
  - condition: or
    conditions:
      - condition: state
        entity_id: input_boolean.guest_mode
        state: "on"
      - condition: state
        entity_id: input_boolean.party_mode
        state: "on"
```

#### Template Conditions

```yaml
condition:
  - condition: template
    value_template: >
      {{ states('sensor.outside_temperature') | float < 
         states('sensor.inside_temperature') | float }}
```

## Actions

### Service Calls

#### Basic Service Call

```yaml
action:
  - service: light.turn_on
    target:
      entity_id: light.living_room
    data:
      brightness: 255
      color_name: "blue"
```

#### Multiple Entities

```yaml
action:
  - service: light.turn_on
    target:
      entity_id:
        - light.living_room
        - light.kitchen
        - light.bedroom
    data:
      brightness: 180
```

#### Area-Based Actions

```yaml
action:
  - service: light.turn_off
    target:
      area_id: living_room
```

### Notification Actions

#### Mobile App Notifications

```yaml
action:
  - service: notify.mobile_app_johns_phone
    data:
      title: "Security Alert"
      message: "Front door opened while away"
      data:
        push:
          sound: "alarm.wav"
        action_data:
          action: "SECURITY_ALERT"
        actions:
          - action: "DISARM"
            title: "Disarm Alarm"
          - action: "CALL_POLICE"
            title: "Call Police"
```

#### Persistent Notifications

```yaml
action:
  - service: persistent_notification.create
    data:
      title: "Maintenance Reminder"
      message: "Time to change HVAC filter"
      notification_id: "hvac_filter"
```

### Script and Scene Actions

```yaml
action:
  - service: script.bedtime_routine
  - service: scene.turn_on
    target:
      entity_id: scene.movie_night
```

### Delays and Wait Actions

```yaml
action:
  - service: light.turn_on
    target:
      entity_id: light.hallway
  - delay: "00:02:00"  # Wait 2 minutes
  - service: light.turn_off
    target:
      entity_id: light.hallway
```

#### Wait for State Change

```yaml
action:
  - service: cover.open_cover
    target:
      entity_id: cover.garage_door
  - wait_for_trigger:
      - platform: state
        entity_id: cover.garage_door
        to: "open"
    timeout: "00:01:00"
  - service: notify.mobile_app
    data:
      message: "Garage door is now open"
```

### Conditional Actions

```yaml
action:
  - choose:
      - conditions:
          - condition: state
            entity_id: input_select.house_mode
            state: "Away"
        sequence:
          - service: alarm_control_panel.alarm_arm_away
            target:
              entity_id: alarm_control_panel.home
      - conditions:
          - condition: state
            entity_id: input_select.house_mode
            state: "Night"
        sequence:
          - service: alarm_control_panel.alarm_arm_night
            target:
              entity_id: alarm_control_panel.home
    default:
      - service: alarm_control_panel.alarm_disarm
        target:
          entity_id: alarm_control_panel.home
```

## Automation Examples

### Security Automations

#### Motion-Activated Security Lighting

```yaml
automation:
  - alias: "Security Motion Lights"
    description: "Turn on outdoor lights when motion detected at night"
    trigger:
      - platform: state
        entity_id:
          - binary_sensor.front_motion
          - binary_sensor.back_motion
        from: "off"
        to: "on"
    condition:
      - condition: sun
        after: sunset
        before: sunrise
    action:
      - service: light.turn_on
        target:
          entity_id: light.outdoor_security
        data:
          brightness: 255
      - delay: "00:05:00"
      - service: light.turn_off
        target:
          entity_id: light.outdoor_security
```

#### Door/Window Alert When Away

```yaml
automation:
  - alias: "Security Alert - Doors/Windows"
    description: "Alert when doors or windows open while away"
    trigger:
      - platform: state
        entity_id:
          - binary_sensor.front_door
          - binary_sensor.back_door
          - binary_sensor.living_room_window
        from: "off"
        to: "on"
    condition:
      - condition: not
        conditions:
          - condition: state
            entity_id: group.family
            state: "home"
    action:
      - service: notify.family
        data:
          title: "🚨 Security Alert"
          message: >
            {{ trigger.to_state.attributes.friendly_name }} 
            opened while away at {{ now().strftime('%I:%M %p') }}
      - service: camera.snapshot
        target:
          entity_id: camera.front_door
        data:
          filename: "/config/www/snapshots/security_{{ now().strftime('%Y%m%d_%H%M%S') }}.jpg"
```

### Comfort and Convenience

#### Adaptive Lighting

```yaml
automation:
  - alias: "Adaptive Living Room Lighting"
    description: "Adjust lighting based on time and occupancy"
    trigger:
      - platform: state
        entity_id: binary_sensor.living_room_motion
        to: "on"
      - platform: sun
        event: sunset
        offset: "-01:00:00"
    condition:
      - condition: state
        entity_id: binary_sensor.living_room_motion
        state: "on"
    action:
      - choose:
          - conditions:
              - condition: sun
                before: sunrise
                after: sunset
            sequence:
              - service: light.turn_on
                target:
                  entity_id: light.living_room
                data:
                  brightness: >
                    {% if now().hour < 6 or now().hour > 22 %}
                      50
                    {% else %}
                      200
                    {% endif %}
                  color_temp: >
                    {% if now().hour < 6 or now().hour > 22 %}
                      400
                    {% else %}
                      250
                    {% endif %}
        default:
          - service: light.turn_on
            target:
              entity_id: light.living_room
            data:
              brightness: 255
              color_temp: 200
```

#### Climate Control Automation

```yaml
automation:
  - alias: "Smart Thermostat Control"
    description: "Adjust temperature based on occupancy and time"
    trigger:
      - platform: state
        entity_id: group.family
        to: "home"
      - platform: state
        entity_id: group.family
        to: "not_home"
        for: "00:30:00"
      - platform: time
        at: "22:00:00"
      - platform: time
        at: "06:00:00"
    action:
      - choose:
          # Family comes home
          - conditions:
              - condition: state
                entity_id: group.family
                state: "home"
            sequence:
              - service: climate.set_temperature
                target:
                  entity_id: climate.main_thermostat
                data:
                  temperature: 22
          # Family leaves
          - conditions:
              - condition: state
                entity_id: group.family
                state: "not_home"
            sequence:
              - service: climate.set_temperature
                target:
                  entity_id: climate.main_thermostat
                data:
                  temperature: 18
          # Bedtime
          - conditions:
              - condition: time
                after: "22:00:00"
            sequence:
              - service: climate.set_temperature
                target:
                  entity_id: climate.main_thermostat
                data:
                  temperature: 19
          # Wake up
          - conditions:
              - condition: time
                after: "06:00:00"
                before: "08:00:00"
              - condition: state
                entity_id: group.family
                state: "home"
            sequence:
              - service: climate.set_temperature
                target:
                  entity_id: climate.main_thermostat
                data:
                  temperature: 21
```

### Energy Management

#### Smart Power Management

```yaml
automation:
  - alias: "High Energy Usage Alert"
    description: "Alert when energy usage is high"
    trigger:
      - platform: numeric_state
        entity_id: sensor.home_energy_usage
        above: 5000  # 5kW
        for: "00:15:00"
    action:
      - service: notify.family
        data:
          title: "⚡ High Energy Usage"
          message: >
            Current usage: {{ states('sensor.home_energy_usage') }}W
            Consider turning off non-essential devices.
      - service: switch.turn_off
        target:
          entity_id:
            - switch.pool_pump
            - switch.electric_heater
```

#### Solar Panel Optimization

```yaml
automation:
  - alias: "Solar Excess Energy Usage"
    description: "Use excess solar energy for heating/charging"
    trigger:
      - platform: numeric_state
        entity_id: sensor.solar_excess_power
        above: 2000  # 2kW excess
        for: "00:05:00"
    condition:
      - condition: time
        after: "09:00:00"
        before: "16:00:00"
    action:
      - service: water_heater.turn_on
        target:
          entity_id: water_heater.electric
      - service: switch.turn_on
        target:
          entity_id: switch.car_charger
```

### Health and Wellness

#### Air Quality Management

```yaml
automation:
  - alias: "Air Quality Response"
    description: "Respond to poor air quality"
    trigger:
      - platform: numeric_state
        entity_id: sensor.air_quality_pm25
        above: 35
        for: "00:10:00"
    action:
      - service: fan.turn_on
        target:
          entity_id: fan.air_purifier
        data:
          speed: "high"
      - service: notify.family
        data:
          title: "🌫️ Poor Air Quality"
          message: >
            PM2.5 level: {{ states('sensor.air_quality_pm25') }}μg/m³
            Air purifier activated.
      - service: climate.set_fan_mode
        target:
          entity_id: climate.main_thermostat
        data:
          fan_mode: "on"
```

#### Sleep Optimization

```yaml
automation:
  - alias: "Bedtime Routine"
    description: "Automated bedtime routine"
    trigger:
      - platform: time
        at: "22:00:00"
    condition:
      - condition: state
        entity_id: group.family
        state: "home"
    action:
      - service: scene.turn_on
        target:
          entity_id: scene.bedtime
      - service: media_player.turn_off
        target:
          entity_id: media_player.living_room_tv
      - delay: "00:30:00"
      - service: light.turn_off
        target:
          area_id: living_room
      - service: lock.lock
        target:
          entity_id: lock.front_door
```

## Advanced Automation Techniques

### Template-Based Automations

#### Dynamic Triggers

```yaml
automation:
  - alias: "Temperature Differential Control"
    description: "Control based on inside/outside temperature difference"
    trigger:
      - platform: template
        value_template: >
          {{ (states('sensor.outside_temperature') | float - 
              states('sensor.inside_temperature') | float) | abs > 5 }}
    action:
      - choose:
          - conditions:
              - condition: template
                value_template: >
                  {{ states('sensor.outside_temperature') | float > 
                     states('sensor.inside_temperature') | float }}
            sequence:
              - service: climate.set_hvac_mode
                target:
                  entity_id: climate.main_thermostat
                data:
                  hvac_mode: "cool"
        default:
          - service: climate.set_hvac_mode
            target:
              entity_id: climate.main_thermostat
            data:
              hvac_mode: "heat"
```

### Automation Modes

#### Single Mode (Default)

```yaml
automation:
  - alias: "Single Mode Example"
    mode: single  # Only one instance runs
    trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: light.hallway
      - delay: "00:05:00"
      - service: light.turn_off
        target:
          entity_id: light.hallway
```

#### Restart Mode

```yaml
automation:
  - alias: "Restart Mode Example"
    mode: restart  # Restart if triggered again
    trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: light.hallway
      - delay: "00:05:00"  # This will restart if motion detected again
      - service: light.turn_off
        target:
          entity_id: light.hallway
```

#### Queued Mode

```yaml
automation:
  - alias: "Queued Mode Example"
    mode: queued  # Queue multiple instances
    max: 5        # Maximum 5 in queue
    trigger:
      - platform: state
        entity_id: binary_sensor.doorbell
        to: "on"
    action:
      - service: media_player.play_media
        target:
          entity_id: media_player.chime
        data:
          media_content_id: "doorbell.mp3"
          media_content_type: "music"
```

#### Parallel Mode

```yaml
automation:
  - alias: "Parallel Mode Example"
    mode: parallel  # Run multiple instances simultaneously
    max: 10         # Maximum 10 parallel instances
    trigger:
      - platform: state
        entity_id: 
          - binary_sensor.motion_room1
          - binary_sensor.motion_room2
          - binary_sensor.motion_room3
        to: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: "light.{{ trigger.entity_id.split('.')[1].replace('motion_', '') }}"
      - delay: "00:05:00"
      - service: light.turn_off
        target:
          entity_id: "light.{{ trigger.entity_id.split('.')[1].replace('motion_', '') }}"
```

## Debugging and Troubleshooting

### Trace and Debug

Enable automation traces in the UI or add debugging:

```yaml
automation:
  - alias: "Debug Example"
    description: "Example with debugging"
    trigger:
      - platform: state
        entity_id: binary_sensor.test
    action:
      - service: system_log.write
        data:
          message: "Automation triggered by {{ trigger.entity_id }}"
          level: info
      - service: persistent_notification.create
        data:
          title: "Debug"
          message: >
            Triggered at: {{ now() }}
            Entity: {{ trigger.entity_id }}
            From: {{ trigger.from_state.state }}
            To: {{ trigger.to_state.state }}
```

### Common Issues and Solutions

1. **Automation Not Triggering**
   - Check entity IDs are correct
   - Verify conditions aren't preventing execution
   - Check automation is enabled

2. **Actions Not Working**
   - Verify service calls and entity IDs
   - Check entity states in Developer Tools
   - Review automation traces

3. **Performance Issues**
   - Use specific entity IDs instead of groups when possible
   - Avoid complex templates in triggers
   - Consider automation mode settings

## Best Practices

1. **Use Descriptive Names**: Make automation purposes clear
2. **Add Descriptions**: Document what each automation does
3. **Test Conditions**: Use Developer Tools to test templates
4. **Use Variables**: Store complex templates in variables
5. **Organize by Function**: Group related automations
6. **Monitor Performance**: Check automation execution times
7. **Version Control**: Back up automation configurations

## Blueprint Automations

Blueprints allow sharing and reusing automation templates:

```yaml
# Example blueprint usage
automation:
  - alias: "Motion Light from Blueprint"
    use_blueprint:
      path: motion_light.yaml
      input:
        motion_entity: binary_sensor.living_room_motion
        light_target:
          entity_id: light.living_room
        no_motion_wait: 300
```

Creating custom blueprints allows standardizing common automation patterns across your installation.
