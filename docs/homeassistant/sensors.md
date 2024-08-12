# Sensors

## Template Sensor

```yml
- sensor:
    - name: "AC_On_Window_Open
      state: >
         {% if states.binary_sensor.windows.state == 'off' and states.climate.thermostat.state == 'cool'-%}
         true
         {%- else -%}
         false
         {%- endif %}

```

```yml
- sensor:
   - name: "outdoor_temp"
     state: >
       {% if (state_attr('climate.thermostat', 'current_temperature') | float <= states('sensor.oc_temp_upstairs_temperature') | float) %}
       Open Windows
       {% else %}
       Close Windows
       {% endif %}

```

```yml
  - sensor:
      - name: "Average temperature"
        unit_of_measurement: "°C"
        state: >
          {% set bedroom = states('sensor.bedroom_temperature') | float %}
          {% set kitchen = states('sensor.kitchen_temperature') | float %}

          {{ ((bedroom + kitchen) / 2) | round(1, default=0) }}
```

## Time of Day

```yml
- platform: tod
  name: Night
  after: sunset
  before: sunrise

- platform: tod
  name: Quiet TIme
  after: '21:00'
  before: '06:00'
```

## Workday

```yml
- platform: workday
  country: US
  province: WI
  workdays: [mon, tue, wed, thu, fri]
```

## History Stats

```yaml
- platform: history_stats
  name: Lamp on today
  entity_id: light.my_lamp
  state: "on"
  type: time
  start: "{{ now().replace(hour=0, minute=0, seconds=0 }}"
  end: "{{ now() }}
  
- platform: history_stats
  name: Washer Running
  entity_id: sensor.washer_status
  state: "running"
  type: time
  end: "{{ now() }}"
  duration:
    days: 7
```

## Utility

```yaml
- platform: history_stats
  name: Front Door Motion
  entity_id: binary_sensor.sensor.motion_front_door
  state: 'on'
  end: '{{ now() }}'
  duration:
    days: 7
    
utility_meter:
  hourly_frontdoor_motion:
    source: sensor.front_door_motion
    cycle: hourly
  daily_frontdoor_motion:
    source: sensor.front_door_motion
    cycle: daily
```

## Rest API

```yaml
binary_sensor:
  - platform: template
    sensors:
      nws_alerts_are_active:
        friendly_name: NWS Alerts Are Active
        #entity_id: sensor.nws_alerts
        value_template: >
          {{ states('sensor.nws_alerts') | int(0) > 0 }}
        icon_template: >-
          {% if states('sensor.nws_alerts') | int(0) > 0 %}
            mdi:weather-lightning
          {% else %}
            mdi:weather-sunny
          {% endif %}
```
