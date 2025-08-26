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

Template sensors are custom sensors that use Jinja2 templating to create new sensor entities based on existing Home Assistant data. They provide incredible flexibility for combining, transforming, and analyzing data from multiple sources to create meaningful insights and actionable information.

**Core Functionality:**

Template sensors evaluate expressions using the current state of your Home Assistant entities, allowing you to create sensors that:

- Combine data from multiple existing sensors
- Perform mathematical calculations and comparisons
- Apply conditional logic based on entity states
- Transform data formats and units
- Create derived metrics from raw sensor data

**Modern vs Legacy Configuration:**

Home Assistant now recommends the modern `template:` configuration format over the legacy `platform: template` approach. The modern format provides better organization, improved performance, and cleaner syntax while supporting advanced features like dynamic attributes and availability templates.

**Key Features:**

- **Real-time Updates**: Automatically recalculate when source entities change
- **Rich Data Types**: Support for numeric, text, boolean, and complex data structures
- **Conditional Logic**: Use if/else statements and comparison operators
- **Mathematical Operations**: Perform calculations, aggregations, and statistical functions
- **State History Access**: Reference previous states and timestamps
- **Custom Attributes**: Add contextual information for enhanced functionality

**Common Use Cases:**

Template sensors excel at creating energy cost calculations, comfort indices, maintenance alerts, occupancy detection, and environmental recommendations. They're essential for transforming raw sensor data into actionable intelligence that drives smart home automations and provides meaningful insights through your Home Assistant dashboard.

**Benefits:**

The primary advantage of template sensors is their ability to create sophisticated logic without requiring external services or custom components. They process data locally within Home Assistant, ensuring fast response times and reliable operation while providing unlimited customization possibilities for your specific monitoring and automation needs.

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

Advanced template sensors represent the pinnacle of Home Assistant's sensor capabilities, enabling sophisticated data processing, complex calculations, and intelligent decision-making through powerful Jinja2 templating. These sensors go beyond basic value transformations to create comprehensive monitoring solutions that combine multiple data sources, implement statistical analysis, and provide predictive insights for smart home automation.

**Multi-Entity Data Fusion:**

Advanced template sensors excel at aggregating and analyzing data from multiple sources simultaneously. They can monitor entire sensor groups, calculate averages across zones, and create composite health scores that reflect the overall state of complex systems. This capability is essential for creating unified dashboards and implementing system-wide automation logic.

**Statistical and Mathematical Operations:**

These sensors perform complex mathematical operations including statistical analysis, trend detection, and predictive modeling. They can calculate moving averages, detect anomalies, compute efficiency metrics, and generate forecasts based on historical data patterns. This analytical power transforms raw sensor data into actionable intelligence.

**Time-Aware Processing:**

Advanced template sensors incorporate temporal logic to create time-sensitive monitoring and recommendations. They can track duration-based metrics, implement time-weighted calculations, and create sensors that behave differently based on schedules, seasons, or historical patterns. This temporal awareness enables sophisticated automation strategies.

**Conditional Intelligence:**

These sensors implement complex conditional logic that adapts behavior based on multiple variables and environmental conditions. They can create dynamic recommendations, implement multi-stage decision trees, and provide context-aware responses that consider the full state of your smart home ecosystem.

**Performance Optimization:**

Advanced template sensors include optimization techniques such as state caching, conditional evaluation, and efficient data processing to maintain system performance while handling complex calculations. They implement proper error handling, availability checking, and graceful degradation to ensure reliable operation.

**Rich Attribute Systems:**

Beyond the primary state value, advanced template sensors provide extensive attribute data that offers deep insights into calculations, intermediate values, and diagnostic information. These attributes support debugging, provide context for automations, and enable detailed analysis of sensor behavior and data quality.

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

Binary sensors are essential components in Home Assistant that represent two-state (on/off, true/false) conditions and serve as the backbone for intelligent automations and system monitoring. These sensors monitor everything from physical device states like door/window positions and motion detection to logical conditions such as occupancy status and system alerts. Unlike regular sensors that provide numeric or text values, binary sensors simplify decision-making in automations by providing clear boolean states that can trigger immediate actions, making them indispensable for security systems, energy management, and smart home orchestration.

### Template Binary Sensors

Template binary sensors provide a powerful way to create custom on/off sensors using Jinja2 templates and data from other Home Assistant entities. They excel at creating logical conditions, combining multiple sensor states, and implementing complex decision-making logic that traditional platform binary sensors cannot handle.

**Key Features:**

- **Logical Conditions**: Combine multiple entities with AND, OR, and NOT logic
- **Time-Based States**: Create sensors based on time of day, schedules, or duration
- **Mathematical Comparisons**: Compare sensor values with thresholds
- **State Aggregation**: Monitor groups of sensors and determine overall status
- **Custom Attributes**: Add contextual information for debugging and display

**Common Use Cases:**

- Security monitoring (doors/windows open during armed states)
- Energy efficiency alerts (AC running with windows open)
- Occupancy detection (combining motion, device presence, and time)
- Maintenance reminders (based on usage time or sensor values)
- Environmental monitoring (combining temperature, humidity, air quality)

**Benefits Over Platform Binary Sensors:**

- **Flexibility**: Any combination of entities and conditions
- **Real-time Updates**: Automatically update when source entities change
- **Rich Context**: Include diagnostic attributes for troubleshooting
- **No External Dependencies**: Pure Home Assistant logic without external services

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

Platform binary sensors are integration-specific sensors that connect to various services and devices to provide on/off state information. These sensors utilize Home Assistant's built-in platforms to monitor connectivity, status, and boolean conditions from external sources.

#### Common Platform Types

**Connectivity Sensors:**

```yaml
binary_sensor:
  # Ping sensor for network connectivity
  - platform: ping
    host: 192.168.1.1
    name: "Router Online"
    count: 3
    scan_interval: 30
    
  - platform: ping
    host: 8.8.8.8
    name: "Internet Connectivity"
    count: 2
    scan_interval: 60

# Trend sensor for monitoring value changes
  - platform: trend
    sensors:
      temperature_rising:
        entity_id: sensor.outdoor_temperature
        sample_duration: 1800  # 30 minutes
        max_samples: 10
        min_gradient: 0.5
        
      battery_draining:
        entity_id: sensor.phone_battery
        sample_duration: 3600  # 1 hour
        max_gradient: -5  # Alert if dropping more than 5% per hour
```

**Schedule-Based Sensors:**

```yaml
# Workday sensor for business day detection
  - platform: workday
    country: US
    state: CA
    name: "Workday"
    workdays: [mon, tue, wed, thu, fri]
    excludes: [sat, sun, holiday]
    days_offset: 1  # Tomorrow's workday status
    
  - platform: workday
    country: US
    name: "Weekend"
    workdays: []
    excludes: [mon, tue, wed, thu, fri]
```

**File System Monitoring:**

```yaml
# File sensor to monitor log files or system files
  - platform: file
    name: "System Log Error"
    file_path: /var/log/syslog
    filter: "ERROR"
    
# Folder watcher for file changes
  - platform: folder_watcher
    folder: /home/user/downloads
    patterns:
      - "*.pdf"
      - "*.zip"
```

**Time-Based Sensors:**

```yaml
# Times of day sensor
  - platform: tod
    name: "Business Hours"
    after: "09:00"
    before: "17:00"
    
  - platform: tod
    name: "Night Mode"
    after: "22:00"
    before: "06:00"
```

#### Device Integration Sensors

Device integration sensors are specialized binary sensors that connect directly to specific hardware devices or services through Home Assistant's integration ecosystem. These sensors provide real-time status monitoring for smart devices, IoT sensors, and connected services, automatically handling device communication protocols and presenting standardized on/off states for use in automations and monitoring dashboards.

```yaml
# Z-Wave door sensor
binary_sensor:
  - platform: zwave
    name: "Front Door Sensor"
    device_class: door
    
# Zigbee motion detector
  - platform: zigbee2mqtt
    name: "Living Room Motion"
    state_topic: "zigbee2mqtt/living_room_motion"
    device_class: motion
    
# WiFi device tracker
  - platform: device_tracker
    name: "Phone Presence"
    device_class: presence
    consider_home: 180
```

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

MQTT sensors are powerful components that receive real-time data from external devices and services through the MQTT messaging protocol. They serve as a bridge between IoT devices, microcontrollers, and third-party services, enabling seamless integration of sensor data from sources like ESP32 boards, Arduino projects, weather stations, and commercial IoT devices into your Home Assistant ecosystem.

**Core Functionality:**

MQTT sensors subscribe to specific topics on your MQTT broker and automatically update their states when new messages arrive. This publish-subscribe model enables efficient, real-time communication with minimal network overhead, making MQTT ideal for battery-powered devices and remote sensors that need to conserve power while maintaining reliable connectivity.

**Key Advantages:**

- **Real-time Updates**: Instant state changes when devices publish new data
- **Low Bandwidth**: Efficient messaging protocol optimized for IoT devices
- **Reliability**: Built-in quality of service (QoS) levels ensure message delivery
- **Scalability**: Single broker can handle hundreds of connected devices
- **Flexibility**: Support for complex JSON payloads and custom data structures
- **Standardization**: Industry-standard protocol with broad device compatibility

**Data Processing:**

MQTT sensors can process raw data using value templates, enabling data transformation, unit conversion, and selective extraction from complex JSON payloads. This preprocessing capability ensures clean, standardized data enters your Home Assistant database while reducing storage overhead and improving automation reliability.

**Device Integration:**

These sensors excel at integrating custom hardware projects, commercial IoT devices, and third-party services that support MQTT publishing. They're essential for DIY environmental monitoring systems, energy meters, security sensors, and any scenario where standard Home Assistant integrations don't exist for your specific hardware or service.

**Security and Authentication:**

MQTT sensors support TLS encryption and username/password authentication, ensuring secure communication with your MQTT broker. They can also validate message authenticity and implement topic-based access control for enhanced security in production environments.

### Advanced MQTT Sensor Configuration

MQTT sensors in Home Assistant provide extensive configuration options for handling complex data structures, implementing error handling, and optimizing performance. Advanced configurations enable sophisticated data processing, multi-sensor device support, and integration with enterprise MQTT infrastructures.

**JSON Payload Processing:**

MQTT sensors excel at extracting specific values from complex JSON messages, enabling a single device to publish multiple sensor readings in one message while Home Assistant creates separate entities for each data point.

**Device Discovery and Grouping:**

MQTT sensors support automatic device discovery through Home Assistant's MQTT discovery protocol, allowing devices to automatically register their sensors and capabilities when they first connect to the network.

**Quality of Service and Reliability:**

Advanced MQTT sensor configurations implement QoS levels, retained messages, and availability monitoring to ensure reliable data collection even in challenging network conditions or with intermittent device connectivity.

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

## REST and Command Line Sensors

REST sensors and command line sensors provide powerful methods for integrating external data sources and system information into Home Assistant. These sensors expand your monitoring capabilities beyond traditional IoT devices by fetching data from web APIs, monitoring system resources, and executing custom commands to gather information from virtually any source that can provide structured data.

### REST Sensors

REST sensors enable Home Assistant to fetch data from web APIs, third-party services, and any HTTP-accessible data source. They provide a standardized way to integrate external services that don't have dedicated Home Assistant integrations, making them essential for comprehensive smart home monitoring and automation systems.

**Core Functionality:**

REST sensors periodically make HTTP requests to specified endpoints and parse the response data to create sensor entities. They support various HTTP methods, authentication schemes, and data formats, making them compatible with most modern web APIs and services.

**Key Features:**

- **Flexible HTTP Requests**: Support for GET, POST, PUT methods with custom headers
- **Authentication**: Basic auth, API keys, OAuth tokens, and custom headers
- **Data Processing**: JSON and XML parsing with Jinja2 templating
- **Multiple Sensors**: Extract multiple values from single API responses
- **Error Handling**: Configurable timeouts, retry logic, and graceful degradation
- **Rate Limiting**: Customizable scan intervals to respect API limits

**Common Use Cases:**

REST sensors excel at integrating weather services, financial data, social media metrics, server monitoring APIs, and any web-based data source. They're particularly valuable for creating comprehensive dashboards that combine local sensor data with external context and services.

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
    timeout: 10
    headers:
      User-Agent: "HomeAssistant/2024.1"
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
        
      - name: "Weather Description"
        value_template: "{{ value_json.weather[0].description | title }}"
        icon: >
          {% set weather = value_json.weather[0].main | lower %}
          {% if weather == 'clear' %}
            mdi:weather-sunny
          {% elif weather == 'clouds' %}
            mdi:weather-cloudy
          {% elif weather == 'rain' %}
            mdi:weather-rainy
          {% elif weather == 'snow' %}
            mdi:weather-snowy
          {% else %}
            mdi:weather-partly-cloudy
          {% endif %}

  # Financial data integration
  - resource: https://api.coindesk.com/v1/bpi/currentprice.json
    method: GET
    scan_interval: 900  # 15 minutes
    sensor:
      - name: "Bitcoin Price USD"
        value_template: "{{ value_json.bpi.USD.rate_float | round(2) }}"
        unit_of_measurement: "USD"
        device_class: monetary
        attributes:
          last_updated: "{{ value_json.time.updated }}"
          currency_code: "{{ value_json.bpi.USD.code }}"

  # System status monitoring
  - resource: http://192.168.1.100:8080/api/status
    method: GET
    headers:
      Authorization: "Bearer !secret api_token"
    scan_interval: 60
    timeout: 5
    sensor:
      - name: "Server CPU Usage"
        value_template: "{{ value_json.system.cpu_percent }}"
        unit_of_measurement: "%"
        device_class: cpu
        
      - name: "Server Memory Usage"
        value_template: "{{ value_json.system.memory_percent }}"
        unit_of_measurement: "%"
        device_class: memory
        
      - name: "Server Uptime"
        value_template: "{{ value_json.system.uptime_days }}"
        unit_of_measurement: "days"
        icon: mdi:clock
```

### Command Line Sensors

Command line sensors execute system commands and shell scripts to gather information directly from the operating system, making them powerful tools for system monitoring, custom data collection, and integration with command-line utilities. These sensors bridge the gap between Home Assistant and system-level information that's not available through standard integrations.

**System Integration Capabilities:**

Command line sensors can monitor CPU usage, memory consumption, disk space, network statistics, and any other system metrics accessible through command-line tools. They're essential for comprehensive system monitoring and alerting.

**Custom Data Collection:**

These sensors excel at executing custom scripts, parsing log files, querying databases, and collecting data from proprietary systems that don't provide API access. They enable integration with legacy systems and specialized monitoring tools.

**Security Considerations:**

Command line sensors run with Home Assistant's permissions, making proper command validation and security practices essential. They should use absolute paths, avoid user input in commands, and implement appropriate error handling to prevent system vulnerabilities.

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
      name: "CPU Usage"
      command: "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//'"
      unit_of_measurement: "%"
      value_template: "{{ value | float | round(1) }}"
      device_class: cpu
      scan_interval: 30
      
  - sensor:
      name: "Disk Usage Home"
      command: 'df -h /home | tail -1 | awk "{print $5}" | sed "s/%//"'
      unit_of_measurement: "%"
      value_template: "{{ value | int }}"
      device_class: data_size
      scan_interval: 300
      
  - sensor:
      name: "Memory Usage"
      command: "free -m | awk 'NR==2{printf \"%.1f\", $3*100/$2 }'"
      unit_of_measurement: "%"
      value_template: "{{ value | float | round(1) }}"
      device_class: memory
      scan_interval: 60
      
  - sensor:
      name: "Load Average"
      command: "uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//'"
      value_template: "{{ value | float | round(2) }}"
      scan_interval: 120
      
# Network monitoring
  - sensor:
      name: "Internet IP"
      command: "curl -s --max-time 10 https://ipv4.icanhazip.com"
      scan_interval: 3600
      value_template: "{{ value.strip() }}"
      
  - sensor:
      name: "Network Speed Download"
      command: "speedtest-cli --simple | grep Download | awk '{print $2}'"
      unit_of_measurement: "Mbit/s"
      value_template: "{{ value | float | round(2) }}"
      scan_interval: 1800  # 30 minutes
      
# Custom log monitoring
  - sensor:
      name: "System Error Count"
      command: "grep -c 'ERROR' /var/log/syslog | tail -1"
      value_template: "{{ value | int }}"
      scan_interval: 300
      
# Docker container monitoring
  - sensor:
      name: "Docker Container Count"
      command: "docker ps -q | wc -l"
      value_template: "{{ value | int }}"
      scan_interval: 120
      
  - sensor:
      name: "Home Assistant Container Memory"
      command: "docker stats homeassistant --no-stream --format 'table {{.MemUsage}}' | tail -1 | awk '{print $1}' | sed 's/MiB//'"
      unit_of_measurement: "MiB"
      value_template: "{{ value | float | round(1) }}"
      device_class: data_size
      scan_interval: 60
```

### Advanced REST and Command Line Configurations

**Authentication and Security:**

```yaml
rest:
  # OAuth bearer token authentication
  - resource: https://api.example.com/data
    method: GET
    headers:
      Authorization: "Bearer !secret oauth_token"
      Content-Type: "application/json"
    verify_ssl: true
    timeout: 15
    
  # Basic authentication
  - resource: https://secure-api.example.com/metrics
    method: GET
    username: !secret api_username
    password: !secret api_password
    scan_interval: 120

command_line:
  # Secure command execution with error handling
  - sensor:
      name: "Secure System Info"
      command: "/usr/local/bin/secure_script.sh"
      command_timeout: 30
      scan_interval: 300
      value_template: >
        {% if value != "" %}
          {{ value | from_json }}
        {% else %}
          unavailable
        {% endif %}
```

**Error Handling and Reliability:**

```yaml
rest:
  - resource: https://unreliable-api.com/data
    method: GET
    timeout: 10
    sensor:
      - name: "API Data"
        value_template: >
          {% if value_json is defined %}
            {{ value_json.data }}
          {% else %}
            unavailable
          {% endif %}
        availability: >
          {{ value_json is defined and value_json.status == 'ok' }}

command_line:
  - sensor:
      name: "Robust System Check"
      command: "/bin/bash -c 'command -v systemctl >/dev/null 2>&1 && systemctl is-active home-assistant || echo unavailable'"
      value_template: >
        {% if value != "unavailable" %}
          {{ value }}
        {% else %}
          unknown
        {% endif %}
      scan_interval: 180
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
