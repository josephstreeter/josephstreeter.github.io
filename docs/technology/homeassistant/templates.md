# Templates

## View Entities

State of an Entity

```jinger
{{ states.sensor.oc_temp_upstairs_temperature.state }}
```

or

```jinger
{{ states('sensor.oc_temp_upstairs_temperature') }}
```

Is State of an Entity Equal to 'x'

```jinger
{{ is_state('states.binary_sensor.oc_contact_bedroom_01_window_01_contact.state', "off") }}
```

List the attributes of an Entity

```jinger
{{ states.light.kitchen_sink_light.attributes }}
```

View the value of an attribute

```jinger
{{ state_attr('light.kitchen_sink_light', 'friendly_name') }}
```

### Manipulate Text

Capitalize

```jinger
{{ states('light.kitchen_sink_light') | capitalize}}
```

To Upper

```jinger
{{ states('light.kitchen_sink_light') | upper}
```

To Lower

```jinger
{{ states('light.kitchen_sink_light') | lower}

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

### Variables

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

### Math

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

### Conditions

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

### Snippets

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
