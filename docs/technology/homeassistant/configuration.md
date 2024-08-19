# Configuration

```yaml
# Loads default set of integrations. Do not remove.
default_config:

# Text to speech
tts:
  - platform: google_translate

automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

template:
  - sensor:
    - name: "outdoor_temp"
      state: >
        {% if (state_attr('climate.thermostat', 'current_temperature') | float <= states('sensor.oc_temp_upstairs_temperature') | float) %}
        Open Windows
        {% else %}
        Close Windows
        {% endif %}
```
