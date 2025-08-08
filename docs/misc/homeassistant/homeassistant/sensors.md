---
uid: misc.homeassistant.homeassistant.sensors
title: Home Assistant Sensors - Complete Guide
description: Comprehensive guide to creating and managing sensors in Home Assistant
keywords: [home assistant, sensors, template sensors, mqtt sensors, binary sensors]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Sensors

Sensors are fundamental components in Home Assistant that provide data about your environment, devices, and system state. This guide covers all types of sensors and advanced configuration techniques.

### Sensor Types Overview

1. **Template Sensors**: Custom sensors using Jinja2 templates
2. **MQTT Sensors**: Sensors receiving data via MQTT
3. **Binary Sensors**: On/off state sensors
4. **Platform Sensors**: Integration-specific sensors
5. **REST Sensors**: API-based sensors
6. **Command Line Sensors**: System command output sensors

## Template Sensors

Template sensors allow creating custom sensors using data from other entities.

### Basic Template Sensors

```yaml
# Modern template format (recommended)
template:
  - sensor:
      - name: "AC On Window Open Alert"
        state: >
          {% if states('binary_sensor.windows') == 'off' and 
                states('climate.thermostat') == 'cool' %}
            true
          {% else %}
            false
          {% endif %}
        icon: >
          {% if this.state == 'true' %}
            mdi:alert-circle
          {% else %}
            mdi:check-circle
          {% endif %}
        
      - name: "Outdoor Temperature Recommendation"
        state: >
          {% set indoor = states('sensor.indoor_temperature') | float %}
          {% set outdoor = states('sensor.outdoor_temperature') | float %}
          {% if indoor > outdoor %}
            Open Windows
          {% else %}
            Close Windows
          {% endif %}
        unit_of_measurement: "advice"
        icon: mdi:window-open-variant
        
      - name: "Energy Cost Today"
        state: >
          {{ (states('sensor.energy_consumption_today') | float * 
              states('sensor.electricity_rate') | float) | round(2) }}
        unit_of_measurement: "USD"
        device_class: monetary
        
      - name: "Battery Status Summary"
        state: >
          {% set batteries = [
            states('sensor.phone_battery_level'),
            states('sensor.tablet_battery_level'),
            states('sensor.smoke_detector_battery')
          ] %}
          {% set low_batteries = batteries | select('lt', 20) | list | length %}
          {% if low_batteries > 0 %}
            {{ low_batteries }} devices low
          {% else %}
            All devices OK
          {% endif %}
        icon: >
          {% set batteries = [
            states('sensor.phone_battery_level') | int,
            states('sensor.tablet_battery_level') | int,
            states('sensor.smoke_detector_battery') | int
          ] %}
          {% set min_battery = batteries | min %}
          {% if min_battery < 20 %}
            mdi:battery-alert
          {% elif min_battery < 50 %}
            mdi:battery-30
          {% else %}
            mdi:battery
          {% endif %}
```

### Advanced Template Sensors

```yaml
template:
  - sensor:
      # Weather comfort index
      - name: "Weather Comfort Index"
        state: >
          {% set temp = states('sensor.outdoor_temperature') | float %}
          {% set humidity = states('sensor.outdoor_humidity') | float %}
          {% set heat_index = temp + (0.5 * (temp + 61.0 + ((temp-68.0)*1.2) + (humidity*0.094))) %}
          
          {% if heat_index < 80 %}
            Comfortable
          {% elif heat_index < 90 %}
            Caution
          {% elif heat_index < 105 %}
            Extreme Caution
          {% elif heat_index < 130 %}
            Danger
          {% else %}
            Extreme Danger
          {% endif %}
        attributes:
          temperature: "{{ states('sensor.outdoor_temperature') }}"
          humidity: "{{ states('sensor.outdoor_humidity') }}"
          heat_index: >
            {% set temp = states('sensor.outdoor_temperature') | float %}
            {% set humidity = states('sensor.outdoor_humidity') | float %}
            {{ (temp + (0.5 * (temp + 61.0 + ((temp-68.0)*1.2) + (humidity*0.094)))) | round(1) }}
      
      # Home occupancy confidence
      - name: "Home Occupancy Confidence"
        state: >
          {% set motion_sensors = [
            'binary_sensor.living_room_motion',
            'binary_sensor.kitchen_motion',
            'binary_sensor.bedroom_motion'
          ] %}
          {% set motion_count = motion_sensors | select('is_state', 'on') | list | length %}
          {% set device_count = expand('group.family_devices') | selectattr('state', 'eq', 'home') | list | length %}
          {% set lights_on = expand('group.all_lights') | selectattr('state', 'eq', 'on') | list | length %}
          
          {% set confidence = ((motion_count * 30) + (device_count * 40) + (lights_on * 10)) %}
          {{ [confidence, 100] | min }}
        unit_of_measurement: "%"
        attributes:
          motion_sensors_active: >
            {% set motion_sensors = [
              'binary_sensor.living_room_motion',
              'binary_sensor.kitchen_motion',
              'binary_sensor.bedroom_motion'
            ] %}
            {{ motion_sensors | select('is_state', 'on') | list | length }}
          devices_home: >
            {{ expand('group.family_devices') | selectattr('state', 'eq', 'home') | list | length }}
          lights_on: >
            {{ expand('group.all_lights') | selectattr('state', 'eq', 'on') | list | length }}
```

### Legacy Template Sensor Format

```yaml
# Legacy format (still supported)
sensor:
  - platform: template
    sensors:
      daily_energy_cost:
        friendly_name: "Daily Energy Cost"
        value_template: >
          {{ (states('sensor.daily_energy') | float * 
              states('input_number.electricity_rate') | float) | round(2) }}
        unit_of_measurement: "USD"
        device_class: monetary
        
      garage_door_status:
        friendly_name: "Garage Door Status"
        value_template: >
          {% if is_state('cover.garage_door', 'open') %}
            Open
          {% elif is_state('cover.garage_door', 'opening') %}
            Opening
          {% elif is_state('cover.garage_door', 'closing') %}
            Closing
          {% else %}
            Closed
          {% endif %}
        icon_template: >
          {% if is_state('cover.garage_door', 'open') %}
            mdi:garage-open
          {% else %}
            mdi:garage
          {% endif %}
```

## Binary Sensors

Binary sensors represent on/off states and are crucial for automations.

### Template Binary Sensors

```yaml
template:
  - binary_sensor:
      - name: "Work Hours"
        state: >
          {% set current_time = now().hour %}
          {% set weekday = now().weekday() %}
          {{ weekday < 5 and 9 <= current_time < 17 }}
        device_class: occupancy
        
      - name: "Night Time"
        state: >
          {% set current_hour = now().hour %}
          {{ current_hour >= 22 or current_hour <= 6 }}
        device_class: occupancy
        
      - name: "Security Breach"
        state: >
          {% set doors = [
            'binary_sensor.front_door',
            'binary_sensor.back_door'
          ] %}
          {% set windows = [
            'binary_sensor.living_room_window',
            'binary_sensor.bedroom_window'
          ] %}
          {% set away = is_state('alarm_control_panel.home', 'armed_away') %}
          {% set open_doors = doors | select('is_state', 'on') | list | length %}
          {% set open_windows = windows | select('is_state', 'on') | list | length %}
          {{ away and (open_doors > 0 or open_windows > 0) }}
        device_class: problem
        attributes:
          open_doors: >
            {% set doors = [
              'binary_sensor.front_door',
              'binary_sensor.back_door'
            ] %}
            {{ doors | select('is_state', 'on') | list }}
          open_windows: >
            {% set windows = [
              'binary_sensor.living_room_window',
              'binary_sensor.bedroom_window'
            ] %}
            {{ windows | select('is_state', 'on') | list }}
```

### Platform Binary Sensors

```yaml
# Ping binary sensor
binary_sensor:
  - platform: ping
    host: 192.168.1.1
    name: "Router Connectivity"
    count: 2
    scan_interval: 30
    
  - platform: template
    sensors:
      internet_connection:
        friendly_name: "Internet Connection"
        value_template: >
          {{ is_state('binary_sensor.router_connectivity', 'on') and
             is_state('binary_sensor.google_dns', 'on') }}
        device_class: connectivity
        
# Workday sensor
  - platform: workday
    country: US
    name: "Workday Sensor"
    workdays: [mon, tue, wed, thu, fri]
    excludes: [sat, sun, holiday]
```

## MQTT Sensors

For MQTT sensor configuration, see the [Mosquitto MQTT guide](../mosquitto/index.md).

### Basic MQTT Sensors

```yaml
# MQTT sensor configuration
mqtt:
  sensor:
    - name: "Garden Temperature"
      state_topic: "garden/sensor/temperature"
      unit_of_measurement: "°C"
      device_class: temperature
      value_template: "{{ value_json.temperature }}"
      
    - name: "Garden Humidity"
      state_topic: "garden/sensor/humidity"
      unit_of_measurement: "%"
      device_class: humidity
      value_template: "{{ value_json.humidity }}"
      
    - name: "Solar Power Production"
      state_topic: "solar/power"
      unit_of_measurement: "W"
      device_class: power
      value_template: "{{ value_json.current_power }}"
      
  binary_sensor:
    - name: "Garden Motion"
      state_topic: "garden/motion"
      device_class: motion
      payload_on: "detected"
      payload_off: "clear"
      
    - name: "Water Tank Level"
      state_topic: "water/tank/level"
      device_class: problem
      value_template: "{{ 'ON' if value_json.level < 20 else 'OFF' }}"
```

## REST Sensors

Fetch data from web APIs and services.

### API-Based Sensors

```yaml
# REST platform sensors
rest:
  - resource: https://api.openweathermap.org/data/2.5/weather
    method: GET
    params:
      lat: !secret latitude
      lon: !secret longitude
      appid: !secret openweather_api_key
      units: metric
    scan_interval: 300
    sensor:
      - name: "Weather Temperature"
        value_template: "{{ value_json.main.temp }}"
        unit_of_measurement: "°C"
        device_class: temperature
        
      - name: "Weather Humidity"
        value_template: "{{ value_json.main.humidity }}"
        unit_of_measurement: "%"
        device_class: humidity
        
      - name: "Weather Pressure"
        value_template: "{{ value_json.main.pressure }}"
        unit_of_measurement: "hPa"
        device_class: atmospheric_pressure

# Internet speed test
  - resource: https://www.speedtest.net/api/js/servers
    method: GET
    scan_interval: 3600  # Once per hour
    timeout: 30
    sensor:
      - name: "Internet Speed Test"
        value_template: "{{ value_json[0].sponsor }}"
        json_attributes:
          - sponsor
          - name
          - country
```

### Command Line Sensors

```yaml
# System monitoring sensors
command_line:
  - sensor:
      name: "CPU Temperature"
      command: "cat /sys/class/thermal/thermal_zone0/temp"
      unit_of_measurement: "°C"
      value_template: "{{ value | multiply(0.001) | round(1) }}"
      device_class: temperature
      scan_interval: 60
      
  - sensor:
      name: "Disk Usage Home"
      command: 'df -h /home | tail -1 | awk "{print $5}" | sed "s/%//"'
      unit_of_measurement: "%"
      value_template: "{{ value | int }}"
      scan_interval: 300
      
  - sensor:
      name: "Memory Usage"
      command: "free -m | awk 'NR==2{printf \"%.1f\", $3*100/$2 }'"
      unit_of_measurement: "%"
      value_template: "{{ value | float | round(1) }}"
      scan_interval: 60
      
# Network connectivity
  - sensor:
      name: "Internet IP"
      command: "curl -s https://ipv4.icanhazip.com"
      scan_interval: 3600
      value_template: "{{ value }}"
```

## Statistics and Utility Sensors

Home Assistant provides built-in sensors for statistics and utilities.

### Statistics Sensors

```yaml
# Statistics platform
sensor:
  - platform: statistics
    name: "Temperature Stats"
    entity_id: sensor.outdoor_temperature
    state_characteristic: mean
    max_age:
      hours: 24
    precision: 1
    
  - platform: statistics
    name: "Daily Energy Statistics"
    entity_id: sensor.energy_meter
    state_characteristic: total
    max_age:
      hours: 24

# Utility meter for tracking consumption
utility_meter:
  daily_energy:
    source: sensor.energy_meter
    cycle: daily
    
  monthly_energy:
    source: sensor.energy_meter
    cycle: monthly
    
  yearly_energy:
    source: sensor.energy_meter
    cycle: yearly

# Integration platform for calculating totals
integration:
  - platform: integration
    source: sensor.power_consumption
    name: "Energy Consumed"
    unit_prefix: k
    round: 2
    method: trapezoidal
```

### Derivative and Filter Sensors

```yaml
# Derivative sensor for rate of change
derivative:
  - platform: derivative
    source: sensor.water_tank_level
    name: "Water Usage Rate"
    unit_time: h
    time_window: "00:15:00"

# Filter sensors for smoothing data
filter:
  - platform: filter
    name: "Filtered Temperature"
    entity_id: sensor.noisy_temperature
    filters:
      - filter: outlier
        window_size: 4
        radius: 2.0
      - filter: lowpass
        time_constant: 10
        precision: 2
      - filter: time_simple_moving_average
        window_size: "00:05:00"
```

## Sensor Groups and Organization

### Creating Sensor Groups

```yaml
# Group sensors by function
sensor:
  - platform: group
    name: "Average Temperature"
    type: mean
    unit_of_measurement: "°C"
    device_class: temperature
    entities:
      - sensor.living_room_temperature
      - sensor.bedroom_temperature
      - sensor.kitchen_temperature
      
  - platform: group
    name: "Total Energy Consumption"
    type: sum
    unit_of_measurement: "kWh"
    device_class: energy
    entities:
      - sensor.living_room_energy
      - sensor.bedroom_energy
      - sensor.kitchen_energy

# Min/Max sensors
  - platform: min_max
    name: "Temperature Range"
    type: range
    entity_ids:
      - sensor.outdoor_temperature
      - sensor.indoor_temperature
```

## Advanced Sensor Techniques

### Time-Based Sensors

```yaml
template:
  - sensor:
      - name: "Season"
        state: >
          {% set month = now().month %}
          {% if month in [12, 1, 2] %}
            Winter
          {% elif month in [3, 4, 5] %}
            Spring
          {% elif month in [6, 7, 8] %}
            Summer
          {% else %}
            Autumn
          {% endif %}
        icon: >
          {% set season = this.state %}
          {% if season == 'Winter' %}
            mdi:snowflake
          {% elif season == 'Spring' %}
            mdi:flower
          {% elif season == 'Summer' %}
            mdi:white-balance-sunny
          {% else %}
            mdi:leaf
          {% endif %}
          
      - name: "Time Until Sunset"
        state: >
          {% set sunset = state_attr('sun.sun', 'next_sunset') %}
          {% set now_time = now() %}
          {% if sunset %}
            {% set time_diff = (sunset - now_time).total_seconds() %}
            {% if time_diff > 0 %}
              {% set hours = (time_diff // 3600) | int %}
              {% set minutes = ((time_diff % 3600) // 60) | int %}
              {% if hours > 0 %}
                {{ hours }}h {{ minutes }}m
              {% else %}
                {{ minutes }}m
              {% endif %}
            {% else %}
              Sunset passed
            {% endif %}
          {% else %}
            Unknown
          {% endif %}
```

### Conditional Sensors

```yaml
template:
  - sensor:
      - name: "Heating Recommendation"
        state: >
          {% set outdoor = states('sensor.outdoor_temperature') | float %}
          {% set indoor = states('sensor.indoor_temperature') | float %}
          {% set target = states('input_number.target_temperature') | float %}
          
          {% if indoor < target - 1 %}
            {% if outdoor < indoor %}
              Use Heat Pump
            {% else %}
              Open Windows
            {% endif %}
          {% elif indoor > target + 1 %}
            {% if outdoor > indoor %}
              Use AC
            {% else %}
              Open Windows
            {% endif %}
          {% else %}
            Temperature OK
          {% endif %}
        attributes:
          outdoor_temp: "{{ states('sensor.outdoor_temperature') }}"
          indoor_temp: "{{ states('sensor.indoor_temperature') }}"
          target_temp: "{{ states('input_number.target_temperature') }}"
          efficiency_mode: >
            {% set outdoor = states('sensor.outdoor_temperature') | float %}
            {% set indoor = states('sensor.indoor_temperature') | float %}
            {{ 'Natural' if (outdoor - indoor) | abs < 3 else 'HVAC' }}
```

## Sensor Customization

### Device Classes and Units

```yaml
# Customize sensor attributes
homeassistant:
  customize:
    sensor.custom_temperature:
      device_class: temperature
      unit_of_measurement: "°C"
      icon: mdi:thermometer
      friendly_name: "Custom Temperature Sensor"
      
    sensor.energy_cost:
      device_class: monetary
      unit_of_measurement: "USD"
      icon: mdi:currency-usd
      
    binary_sensor.custom_motion:
      device_class: motion
      icon: mdi:motion-sensor
```

### Sensor Availability

```yaml
template:
  - sensor:
      - name: "Reliable Temperature"
        state: "{{ states('sensor.temperature_sensor') }}"
        availability: >
          {{ not is_state('sensor.temperature_sensor', 'unavailable') and
             not is_state('sensor.temperature_sensor', 'unknown') }}
        unit_of_measurement: "°C"
        device_class: temperature
```

## Troubleshooting Sensors

### Common Issues

1. **Template Errors**: Check logs for template parsing errors
2. **Unavailable Sensors**: Verify entity IDs and integration status
3. **Performance**: Avoid complex templates in frequently updated sensors
4. **Units**: Ensure consistent units of measurement

### Debug Template Sensors

```yaml
# Debug template in Developer Tools > Template
{% set outdoor = states('sensor.outdoor_temperature') | float %}
{% set indoor = states('sensor.indoor_temperature') | float %}
Outdoor: {{ outdoor }}
Indoor: {{ indoor }}
Difference: {{ (outdoor - indoor) | abs }}
Recommendation: {% if outdoor < indoor %}Heat{% else %}Cool{% endif %}
```

## Best Practices

1. **Use Modern Template Format**: Prefer `template:` over legacy `platform: template`
2. **Group Related Sensors**: Organize sensors logically
3. **Add Attributes**: Include additional context in sensor attributes
4. **Use Device Classes**: Proper classification enables better UI and automations
5. **Error Handling**: Include availability checks for reliable sensors
6. **Performance**: Cache expensive calculations using `states.sensor.name.last_changed`
7. **Documentation**: Comment complex templates for future maintenance

This comprehensive sensor guide provides the foundation for creating powerful, reliable sensor networks in Home Assistant.
