---
uid: misc.homeassistant.homeassistant.templates
title: Home Assistant Templates - Complete Guide
description: Comprehensive guide to Jinja2 templating in Home Assistant
keywords: [home assistant, templates, jinja2, automation, templating]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Templates

Templates in Home Assistant use the Jinja2 templating engine to create dynamic values based on entity states, time, and calculations. This guide covers all aspects of Home Assistant templating.

### Template Basics

Templates are expressions that process data and return values. They're used extensively in automations, sensors, and UI customizations.

## Accessing Entity States

### Basic State Access

```jinja2
<!-- Current approach (recommended) -->
{{ states('sensor.temperature') }}
{{ states('binary_sensor.motion') }}
{{ states('climate.thermostat') }}

<!-- Legacy approach (still works) -->
{{ states.sensor.temperature.state }}
{{ states.binary_sensor.motion.state }}
{{ states.climate.thermostat.state }}
```

### State Checking

```jinja2
<!-- Check if entity has specific state -->
{{ is_state('binary_sensor.door', 'on') }}
{{ is_state('light.living_room', 'off') }}
{{ is_state('device_tracker.phone', 'home') }}

<!-- Check for multiple states -->
{{ is_state_attr('climate.thermostat', 'hvac_action', 'heating') }}
{{ is_state_attr('media_player.tv', 'source', 'Netflix') }}
```

### Entity Attributes

```jinja2
<!-- Access all attributes -->
{{ states.light.kitchen.attributes }}
{{ state_attr('sensor.weather', 'temperature') }}
{{ state_attr('climate.thermostat', 'current_temperature') }}

<!-- Common attribute examples -->
{{ state_attr('sun.sun', 'next_sunset') }}
{{ state_attr('weather.home', 'humidity') }}
{{ state_attr('device_tracker.phone', 'battery_level') }}
```

## Advanced Template Functions

### Entity Groups and Expansion

```jinja2
<!-- Expand groups and domains -->
{{ expand('group.all_lights') | selectattr('state', 'eq', 'on') | list | length }}
{{ expand('binary_sensor') | selectattr('state', 'eq', 'on') | map(attribute='name') | list }}

<!-- Filter entities by attributes -->
{{ expand('group.climate_sensors') 
   | selectattr('attributes.device_class', 'eq', 'temperature') 
   | map(attribute='state') | map('float') | average | round(1) }}
```

### Time and Date Functions

```jinja2
<!-- Current time operations -->
{{ now() }}
{{ now().hour }}
{{ now().strftime('%Y-%m-%d %H:%M:%S') }}
{{ as_timestamp(now()) }}

<!-- Time comparisons -->
{{ (now() - states.sensor.motion.last_changed).total_seconds() < 300 }}
{{ now().hour >= 22 or now().hour <= 6 }}
{{ now().weekday() < 5 }}  <!-- Monday=0, Sunday=6 -->

<!-- Date calculations -->
{{ (now() + timedelta(days=1)).strftime('%A') }}
{{ now().replace(hour=0, minute=0, second=0) }}
```

### Mathematical Operations

```jinja2
<!-- Basic math -->
{{ (states('sensor.temperature') | float * 9/5) + 32 }}
{{ states('sensor.humidity') | int + 10 }}
{{ [states('sensor.temp1') | float, states('sensor.temp2') | float] | max }}

<!-- Statistical functions -->
{{ expand('group.temperature_sensors') | map(attribute='state') | map('float') | average }}
{{ expand('group.energy_meters') | map(attribute='state') | map('float') | sum }}
```

### String Manipulation

```jinja2
<!-- String operations -->
{{ states('sensor.device_name') | title }}
{{ states('sensor.description') | lower | replace(' ', '_') }}
{{ 'Temperature: {} °C'.format(states('sensor.temp')) }}

<!-- String conditionals -->
{{ 'High' if states('sensor.temperature') | float > 25 else 'Normal' }}
{{ states('sensor.status') | title if states('sensor.status') != 'unknown' else 'Unavailable' }}
```

## Conditional Logic Templates

### If-Else Statements

```jinja2
<!-- Simple conditionals -->
{% if states('binary_sensor.motion') == 'on' %}
  Motion detected
{% else %}
  No motion
{% endif %}

<!-- Multiple conditions -->
{% if states('sensor.temperature') | float > 25 %}
  Hot
{% elif states('sensor.temperature') | float > 15 %}
  Warm
{% else %}
  Cold
{% endif %}

<!-- Complex logic -->
{% set temp = states('sensor.temperature') | float %}
{% set humidity = states('sensor.humidity') | float %}
{% if temp > 25 and humidity > 60 %}
  Hot and humid
{% elif temp > 25 %}
  Hot but dry
{% elif humidity > 60 %}
  Cool but humid
{% else %}
  Comfortable
{% endif %}
```

### Loop Constructs

```jinja2
<!-- Loop through entities -->
{% for entity in expand('group.security_sensors') %}
  {% if entity.state == 'on' %}
    {{ entity.name }} is active
  {% endif %}
{% endfor %}

<!-- Loop with conditions -->
{% set low_batteries = [] %}
{% for entity in expand('group.battery_sensors') %}
  {% if entity.state | int < 20 %}
    {% set low_batteries = low_batteries + [entity.name] %}
  {% endif %}
{% endfor %}
Low batteries: {{ low_batteries | join(', ') }}
```

### Variable Assignment

```jinja2
<!-- Set variables for reuse -->
{% set outdoor_temp = states('sensor.outdoor_temperature') | float %}
{% set indoor_temp = states('sensor.indoor_temperature') | float %}
{% set temp_diff = (outdoor_temp - indoor_temp) | abs %}

{% if temp_diff < 2 %}
  Temperatures are similar
{% else %}
  {{ 'Outdoor' if outdoor_temp > indoor_temp else 'Indoor' }} is warmer by {{ temp_diff }}°C
{% endif %}
```

## Advanced Template Patterns

### Multi-State Logic

```jinja2
<!-- Complex state evaluation -->
{% set door_sensors = [
  'binary_sensor.front_door',
  'binary_sensor.back_door',
  'binary_sensor.garage_door'
] %}
{% set open_doors = door_sensors | select('is_state', 'on') | list %}
{% set security_armed = is_state('alarm_control_panel.home', 'armed_away') %}

{% if open_doors | length > 0 and security_armed %}
  SECURITY ALERT: {{ open_doors | length }} door(s) open while armed
{% elif open_doors | length > 0 %}
  {{ open_doors | length }} door(s) currently open
{% else %}
  All doors secured
{% endif %}
```

### Dynamic Attribute Selection

```jinja2
<!-- Dynamic entity selection based on time -->
{% if now().hour >= 6 and now().hour < 18 %}
  {% set temp_sensor = 'sensor.outdoor_temperature' %}
{% else %}
  {% set temp_sensor = 'sensor.indoor_temperature' %}
{% endif %}
Current relevant temperature: {{ states(temp_sensor) }}°C

<!-- Dynamic threshold based on season -->
{% set month = now().month %}
{% if month in [12, 1, 2] %}
  {% set comfort_temp = 20 %}
{% elif month in [6, 7, 8] %}
  {% set comfort_temp = 24 %}
{% else %}
  {% set comfort_temp = 22 %}
{% endif %}
```

### Error Handling in Templates

```jinja2
<!-- Safe state access with defaults -->
{{ states('sensor.temperature') | float(0) }}
{{ state_attr('sensor.weather', 'humidity') | int(50) }}

<!-- Check for entity availability -->
{% if not is_state('sensor.temperature', 'unavailable') %}
  Temperature: {{ states('sensor.temperature') }}°C
{% else %}
  Temperature sensor unavailable
{% endif %}

<!-- Multiple fallback sensors -->
{% set temp_sensors = [
  'sensor.outdoor_temperature',
  'sensor.backup_temperature',
  'sensor.weather_temperature'
] %}
{% for sensor in temp_sensors %}
  {% if not is_state(sensor, 'unavailable') and not is_state(sensor, 'unknown') %}
    {% set temperature = states(sensor) %}
    {% break %}
  {% endif %}
{% endfor %}
{{ temperature | default('N/A') }}
```

## Template Macros

### Reusable Template Functions

```jinja2
<!-- Define macro for battery status -->
{% macro battery_status(entity_id, threshold=20) -%}
  {% set level = states(entity_id) | int(0) %}
  {% if level < threshold %}
    🔴 {{ state_attr(entity_id, 'friendly_name') }}: {{ level }}%
  {% elif level < threshold * 2 %}
    🟡 {{ state_attr(entity_id, 'friendly_name') }}: {{ level }}%
  {% else %}
    🟢 {{ state_attr(entity_id, 'friendly_name') }}: {{ level }}%
  {% endif %}
{%- endmacro %}

<!-- Use the macro -->
{{ battery_status('sensor.phone_battery') }}
{{ battery_status('sensor.tablet_battery', 15) }}
```

### Climate Control Macros

```jinja2
{% macro hvac_recommendation(indoor_sensor, outdoor_sensor, target_temp) -%}
  {% set indoor = states(indoor_sensor) | float %}
  {% set outdoor = states(outdoor_sensor) | float %}
  {% set target = target_temp | float %}
  
  {% if indoor < target - 1 %}
    {% if outdoor > indoor %}
      💨 Open windows for natural heating
    {% else %}
      🔥 Use heating system
    {% endif %}
  {% elif indoor > target + 1 %}
    {% if outdoor < indoor %}
      💨 Open windows for natural cooling
    {% else %}
      ❄️ Use air conditioning
    {% endif %}
  {% else %}
    ✅ Temperature is optimal
  {% endif %}
{%- endmacro %}
```

## Filter Operations

### Common Filters

```jinja2
<!-- Numeric filters -->
{{ states('sensor.temperature') | float | round(1) }}
{{ states('sensor.pressure') | int }}
{{ states('sensor.energy') | float | abs }}

<!-- List filters -->
{{ expand('group.lights') | selectattr('state', 'eq', 'on') | list | length }}
{{ ['apple', 'banana', 'cherry'] | select('match', '.*a.*') | list }}
{{ [1, 2, 3, 4, 5] | select('gt', 3) | list }}

<!-- String filters -->
{{ states('sensor.device_name') | title | replace('_', ' ') }}
{{ 'hello world' | capitalize }}
{{ 'LOUD TEXT' | lower }}
```

### Advanced Filtering

```jinja2
<!-- Complex entity filtering -->
{{ expand('binary_sensor') 
   | selectattr('attributes.device_class', 'defined')
   | selectattr('attributes.device_class', 'eq', 'motion')
   | selectattr('state', 'eq', 'on')
   | map(attribute='name') | list | join(', ') }}

<!-- Time-based filtering -->
{{ expand('group.all_lights')
   | selectattr('last_changed', 'gt', now() - timedelta(minutes=5))
   | list | length }} lights changed in last 5 minutes
```

## Testing Templates

### Developer Tools Template Editor

Access **Developer Tools > Template** to test templates interactively:

```jinja2
<!-- Test basic functionality -->
Current time: {{ now() }}
Temperature: {{ states('sensor.temperature') }}
Is it night? {{ states('sun.sun') == 'below_horizon' }}

<!-- Test complex logic -->
{% set motion_sensors = expand('binary_sensor') | selectattr('attributes.device_class', 'eq', 'motion') | list %}
Motion sensors found: {{ motion_sensors | length }}
Active sensors: {{ motion_sensors | selectattr('state', 'eq', 'on') | list | length }}
```

### Template Validation

```jinja2
<!-- Check for common errors -->
<!-- ❌ Wrong: Missing quotes -->
{{ is_state(sensor.temp, on) }}

<!-- ✅ Correct: Proper quoting -->
{{ is_state('sensor.temp', 'on') }}

<!-- ❌ Wrong: Unsafe state access -->
{{ states.sensor.temp.state | float }}

<!-- ✅ Correct: Safe state access -->
{{ states('sensor.temp') | float(0) }}
```

## Performance Considerations

1. **Avoid Frequent Updates**: Use `states()` instead of `states.entity.state` in triggers
2. **Cache Expensive Calculations**: Store complex calculations in variables
3. **Limit Entity Expansion**: Be selective when using `expand()` with large groups
4. **Use Appropriate Scan Intervals**: Don't update template sensors too frequently
5. **Validate Entity Availability**: Always check for `unavailable` and `unknown` states

## Common Template Patterns

### Home Occupancy Detection

```jinja2
<!-- Multi-factor occupancy detection -->
{% set motion_count = expand('group.motion_sensors') | selectattr('state', 'eq', 'on') | list | length %}
{% set device_count = expand('group.family_devices') | selectattr('state', 'eq', 'home') | list | length %}
{% set recent_activity = expand('group.activity_sensors') | selectattr('last_changed', 'gt', now() - timedelta(minutes=30)) | list | length %}

Occupancy confidence: {{ ((motion_count * 30) + (device_count * 50) + (recent_activity * 20)) | min(100) }}%
```

### Energy Management

```jinja2
<!-- Dynamic pricing and usage -->
{% set current_hour = now().hour %}
{% set peak_hours = range(16, 21) %}
{% set rate = 0.15 if current_hour in peak_hours else 0.10 %}
{% set usage = states('sensor.current_power') | float %}

Current cost: ${{ (usage * rate / 1000) | round(3) }}/hour
{% if current_hour in peak_hours %}
  ⚠️ Peak rate period - consider reducing usage
{% endif %}
```

This comprehensive template guide provides the foundation for creating powerful, dynamic Home Assistant configurations using Jinja2 templating.

```jinger
{{ state_attr('light.kitchen_sink_light', 'friendly_name') }}
```

## Manipulate Text

Capitalize

```jinger
{{ states('light.kitchen_sink_light') | capitalize}}
```

To Upper

```jinger
{{ states('light.kitchen_sink_light') | upper}}
```

To Lower

```jinger
{{ states('light.kitchen_sink_light') | lower}}

```

Concatination

```jinger
{% for state in states.sensor %}
{{state.name ~ '=' ~ state.state }}
{% endfor %}
```

Join

```jinger
{% set output = namespace(sensors=[]) %}
{% for state in states.sensor %}
{% set output.sensors = output.sensors + [state.name ~ "(" ~ state.state ~ ")"] %}
{% endfor %}
{{ output.sensors | join(',') }}
```

## Variables

Set Variable

```jinger
{% set outside_temp = state_attr('climate.thermostat', 'current_temperature') %}
```

Print variable

```jinger
{{ outside_temp }}
```

Create an Array

```jinger
{% set my_array = (1,2,4,5) %}
```

Create an Array from HA data

```jinger
{% set output = namespace(sensors=[]) %}
{% for state in states.sensor %}
{% set output.sensors = output.sensors + [state.name] %}
{% endfor %}
{{ output.sensors }}
```

## Math

Subtraction

```jinger
{% set outside_temp = state_attr('climate.thermostat', 'current_temperature') %}
{% set inside_temp = states('sensor.oc_temp_upstairs_temperature') %}
{% set difference = (outside_temp | float - inside_temp | float) %}
{{ difference }}
```

Greater than or less than

```jinger
{% set outside_temp = state_attr('climate.thermostat', 'current_temperature') %}
{% set inside_temp = states('sensor.oc_temp_upstairs_temperature') %}
{% set difference = (outside_temp | float < inside_temp | float) %}
{{ difference }}
```

Average

```jinger
{% set outside_temp = state_attr('climate.thermostat', 'current_temperature') %}
{% set inside_temp = states('sensor.oc_temp_upstairs_temperature') %}
{% set average = (((outside_temp | float + inside_temp | float)) / 2) | round(2)%}
{{ average }}
```

## Conditions

For

```jinger
{%- for light in states.light -%}
  {%- if light.state == 'off' -%}
    {{ light.entity_id }},
  {%- endif -%}
{%- endfor -%}
```

or

```jinger
{% set output = namespace(sensors=[]) %}
{% for state in states.sensor %}
{{ state.entity_id }} = {{ state.state }}
{% endfor %}
```

For (Print Index)

```jinger
{%- for light in states.light if light.state == 'off'-%}
    {{loop.index}} - {{ light.entity_id }}
{% endfor %}
```

For (filtered)

```jinger
{%- for light in states.light if light.state == 'off'-%}
    {{ light.entity_id }},
{%- endfor -%}
```

Assign results of loop to an array

```jinger
{% set output = namespace(sensors=[]) %}
{% for state in states.sensor %}
{% set output.sensors = output.sensors + [state.name ~ ',' ~ state.state] %}
{% endfor %}
{{ output.sensors }}
```

If/Else

```jinger
{% if is_state('climate.thermostat', 'cool') %}
A window or door is open and the AC is on
{% endif %}
```

If/Else If

```jinger
{% if is_state('climate.thermostat', 'cool') %}
The AC is on
{% elseid %}
The AC is off
{% endif %}
```

If with And/Or Logic

```jinger
{% if 
is_state('binary_sensor.oc_contact_bedroom_01_window_01_contact', 'on') 
or is_state('binary_sensor.oc_contact_bedroom_01_window_02_contact', 'on')
or is_state('binary_sensor.oc_contact_livingroom_window_01_contact', 'on')
or is_state('binary_sensor.oc_contact_door_patio_contact', 'on')
or is_state('binary_sensor.oc_contact_office_window_contact', 'off')
%}
{% endif %}
```

or

```jinger
{% if 
is_state('binary_sensor.oc_contact_bedroom_01_window_01_contact', 'off') 
and if is_state('climate.thermostat', 'cool') %}
{% endif %}
```

Nested If

```jinger
{% if 
is_state('binary_sensor.oc_contact_bedroom_01_window_01_contact', 'on') 
%}
  {% if is_state('climate.thermostat', 'cool') %}
    A window or door is open and the AC is on
  {% endif %}
{% endif %}
```

## Snippets

Show the state of an entity

```jinger
{{ states.binary_sensor.oc_contact_bedroom_01_window_01_contact.state }}
{{ states.binary_sensor.oc_contact_bedroom_01_window_02_contact.state }}
{{ states.binary_sensor.oc_contact_livingroom_window_01_contact.state }}
{{ states.binary_sensor.oc_contact_door_patio_contact.state }}
{{ states.binary_sensor.oc_contact_office_window_contact.state }}
{{ states.climate.thermostat.state }}
```

Alert if there is a door or window open when the AC is on

```jinger
{% if 
is_state('binary_sensor.oc_contact_bedroom_01_window_01_contact', 'on') 
or is_state('binary_sensor.oc_contact_bedroom_01_window_02_contact', 'on')
or is_state('binary_sensor.oc_contact_livingroom_window_01_contact', 'on')
or is_state('binary_sensor.oc_contact_door_patio_contact', 'on')
or is_state('binary_sensor.oc_contact_office_window_contact', 'off')
%}
  {% if is_state('climate.thermostat', 'cool') %}
    A window or door is open and the AC is on
  {% endif %}
{% endif %}
```

Show a filtered list of entities

```jinger
{{ 
  expand(states.light) 
  |selectattr('state', 'eq', 'off') 
  |map(attribute='entity_id')
  |list  
}}
```

Show all entities from an integraion

```jinger
{{ integration_entities('mqtt') }}
```
