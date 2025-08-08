# Zigbee2MQTT Device Management

Complete guide for pairing, configuring, and managing Zigbee devices with Zigbee2MQTT.

## Device Pairing

### Enabling Pairing Mode

#### Method 1: Web Interface

1. Open http://[host-ip]:8080
2. Click "Permit Join" button
3. Set timer (default 5 minutes)
4. Monitor real-time device discovery

#### Method 2: MQTT Commands

```bash
# Enable pairing for 60 seconds
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/permit_join" \
  -m '{"value": true, "time": 60}'

# Disable pairing immediately
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/permit_join" \
  -m '{"value": false}'

# Enable pairing indefinitely (not recommended)
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/permit_join" \
  -m '{"value": true}'
```

#### Method 3: Configuration File

```yaml
# configuration.yaml
permit_join: true  # Restart Zigbee2MQTT to enable
```

> **Security Note**: Always disable pairing mode when not actively adding devices.

### Pairing Process

#### General Pairing Steps

1. **Enable pairing mode** using one of the methods above
2. **Put device in pairing mode**:
   - Press and hold reset button (typically 5-10 seconds)
   - Follow device-specific instructions
   - Watch for LED indicators (usually blinking)
3. **Monitor pairing progress** in logs or web interface
4. **Disable pairing mode** when complete

#### Device-Specific Pairing Instructions

**Philips Hue Devices:**

```text
1. Ensure device is powered on
2. Hold setup button for 10+ seconds until LED blinks
3. Device will appear as "Philips_[model]_[address]"
```

**IKEA TRÅDFRI Devices:**

```text
Bulbs: Press power button 6 times rapidly
Outlets: Press button for 10 seconds
Motion Sensors: Press pair button 4 times rapidly
Remote Controls: Press pair button for 10 seconds
```

**Aqara Sensors:**

```text
Temperature/Humidity: Press button for 3 seconds
Motion Sensors: Press button 3 times rapidly
Door/Window: Press button 3 times rapidly
```

**Sonoff Devices:**

```text
Switches: Hold button for 5 seconds until LED blinks rapidly
Sensors: Press reset button 3 times quickly
```

### Pairing Troubleshooting

#### Device Not Discovered

```bash
# Check if coordinator is working
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/info"

# Verify adapter connection
ls -la /dev/ttyUSB* /dev/ttyACM*

# Check pairing mode status
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/info" | grep permit_join
```

**Common Solutions:**

- Move device closer to coordinator (within 3 feet)
- Check device battery level
- Reset device and try pairing again
- Verify Zigbee channel isn't congested
- Ensure device is compatible with Zigbee2MQTT

#### Pairing Timeout Issues

```bash
# Increase pairing timeout
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/permit_join" \
  -m '{"value": true, "time": 300}'  # 5 minutes

# Check network capacity
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/logging"
```

#### Device Appears But Doesn't Work

1. **Check device support** on [Supported Devices List](https://www.zigbee2mqtt.io/supported-devices/)
2. **Update Zigbee2MQTT** to latest version
3. **Check for external converters** if device is new/unsupported
4. **Verify device configuration** in web interface

## Device Configuration

### Renaming Devices

#### Via Web Interface

1. Navigate to **Devices** tab
2. Click on the device you want to rename
3. Change the **Friendly Name** field
4. Click **Save** to apply changes

#### Via MQTT

```bash
# Rename device by IEEE address
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/rename" \
  -m '{"from": "0x00158d0001abcdef", "to": "living_room_sensor"}'

# Rename using current friendly name
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/rename" \
  -m '{"from": "old_name", "to": "new_descriptive_name"}'
```

### Device-Specific Settings

#### Configuration File Method

```yaml
device_options:
  living_room_sensor:
    # Friendly name
    friendly_name: 'Living Room Temperature'
    
    # Reporting intervals (seconds)
    temperature_reporting_interval: 300  # 5 minutes
    humidity_reporting_interval: 300
    battery_reporting_interval: 3600     # 1 hour
    
    # Sensor calibration
    temperature_calibration: -2.0        # Offset in degrees
    humidity_calibration: 5.0            # Offset in percentage
    pressure_calibration: 10             # Offset in hPa
    
    # MQTT settings
    retain: true
    qos: 1
    
    # Availability tracking
    availability: true
    
    # Device-specific features
    occupancy_timeout: 90                # Motion sensor timeout
    sensitivity: 'medium'                # Motion sensitivity
    illuminance_lux_calibration: 1.2     # Light sensor calibration
```

#### Advanced Device Settings

```yaml
device_options:
  bedroom_switch:
    # Button configuration
    legacy: false
    
    # Power-on behavior
    power_on_behavior: 'previous'  # previous, on, off, toggle
    
    # LED indicator
    led_indication: true
    
    # Child lock
    child_lock: false
    
    # Click modes
    action_transition_time: 0.5
    action_group: null
```

#### Battery Device Optimization

```yaml
device_options:
  # Apply to all battery devices
  '*/battery_devices/*':
    # Longer reporting intervals to save battery
    battery_reporting_interval: 3600     # 1 hour
    temperature_reporting_interval: 600  # 10 minutes
    
    # Optimize for battery life
    optimistic: true
    
    # Disable availability checking for battery devices
    availability: false
```

### Device Control

#### Basic Device Control

```bash
# Turn light on/off
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"state": "ON"}'

mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"state": "OFF"}'

# Set brightness (0-254)
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"state": "ON", "brightness": 150}'

# Set color temperature (warm/cool)
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"color_temp": 300}'

# Set RGB color
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"color": {"hex": "#FF0000"}}'
```

#### Advanced Device Control

```bash
# Transition effects
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"state": "ON", "brightness": 200, "transition": 5}'

# Color cycling
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_light/set" \
  -m '{"effect": "colorloop"}'

# Smart plug control
mosquitto_pub -h localhost -t "zigbee2mqtt/smart_plug/set" \
  -m '{"state": "ON"}'

# Thermostat control
mosquitto_pub -h localhost -t "zigbee2mqtt/thermostat/set" \
  -m '{"occupied_heating_setpoint": 21, "system_mode": "heat"}'
```

### Device Information

#### Get Device Status

```bash
# Get current device state
mosquitto_sub -h localhost -t "zigbee2mqtt/device_name" -C 1

# Get all device states
mosquitto_sub -h localhost -t "zigbee2mqtt/+" -C 10

# Monitor device changes
mosquitto_sub -h localhost -t "zigbee2mqtt/+/set"
```

#### Device Details via MQTT

```bash
# Get device information
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/info" \
  -m '{"id": "living_room_sensor"}'

# Get device attributes
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/response/device/info"
```

## Groups and Scenes

### Creating Groups

#### Via Configuration File

```yaml
groups:
  '1':
    friendly_name: living_room_lights
    retain: false
    optimistic: true
    devices:
      - ceiling_light_1
      - ceiling_light_2
      - table_lamp
      - floor_lamp
  
  '2':
    friendly_name: bedroom_lights
    devices:
      - bedside_lamp_left
      - bedside_lamp_right
      - ceiling_fan_light
  
  '3':
    friendly_name: kitchen_lighting
    devices:
      - under_cabinet_lights
      - pendant_lights
      - recessed_lights
```

#### Via MQTT Commands

```bash
# Create new group
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/add" \
  -m '{"friendly_name": "outdoor_lights"}'

# Add device to group
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/members/add" \
  -m '{"group": "outdoor_lights", "device": "porch_light"}'

# Add multiple devices to group
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/members/add" \
  -m '{"group": "outdoor_lights", "device": ["porch_light", "garden_lights", "driveway_light"]}'

# Remove device from group
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/members/remove" \
  -m '{"group": "outdoor_lights", "device": "porch_light"}'
```

#### Via Web Interface (Groups)

1. Navigate to **Groups** tab
2. Click **Add Group**
3. Enter group name and settings
4. Add devices by dragging or using controls
5. Save group configuration

### Group Control

#### Basic Group Commands

```bash
# Control entire group
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_lights/set" \
  -m '{"state": "ON"}'

# Set group brightness
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_lights/set" \
  -m '{"state": "ON", "brightness": 150}'

# Set group color
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_lights/set" \
  -m '{"color": {"hex": "#FF6600"}}'

# Group transition effects
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_lights/set" \
  -m '{"state": "ON", "brightness": 200, "transition": 3}'
```

#### Advanced Group Features

```yaml
groups:
  '10':
    friendly_name: synchronized_lights
    devices:
      - light_1
      - light_2
      - light_3
    
    # Advanced settings
    optimistic: false          # Wait for device confirmation
    off_state: 'last_member_state'  # Group off when all members off
    filtered_attributes:       # Sync these attributes
      - brightness
      - color_temp
      - color
```

### Scene Management

#### Create Scenes via MQTT

```bash
# Store current state as scene
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/scene/store" \
  -m '{"group": "living_room_lights", "scene": 1}'

# Recall scene
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/scene/recall" \
  -m '{"group": "living_room_lights", "scene": 1}'

# Remove scene
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/group/scene/remove" \
  -m '{"group": "living_room_lights", "scene": 1}'
```

#### Scene Control

```bash
# Activate scene with transition
mosquitto_pub -h localhost -t "zigbee2mqtt/living_room_lights/set" \
  -m '{"scene_recall": 1, "transition": 2}'
```

## Device Removal

### Safe Device Removal

#### Via Web Interface (Removal)

1. Go to **Devices** tab
2. Select the device to remove
3. Click **Remove** button
4. Confirm removal in dialog
5. Device will be unpaired from network

#### Via MQTT (Removal)

```bash
# Remove device by friendly name
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/remove" \
  -m '{"id": "old_sensor"}'

# Force remove (if device is unresponsive)
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/remove" \
  -m '{"id": "broken_device", "force": true}'

# Remove by IEEE address
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/remove" \
  -m '{"id": "0x00158d0001abcdef"}'
```

### Cleanup After Removal

```bash
# Check for orphaned entries
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1

# Clear retained MQTT messages
mosquitto_pub -h localhost -t "zigbee2mqtt/removed_device" -n -r

# Update Home Assistant discovery
mosquitto_pub -h localhost -t "homeassistant/sensor/removed_device/config" -n -r
```

## Device Maintenance

### Battery Monitoring

#### Battery Status Checking

```bash
# Monitor all battery levels
mosquitto_sub -h localhost -t "zigbee2mqtt/+/battery"

# Get specific device battery
mosquitto_sub -h localhost -t "zigbee2mqtt/sensor_name/battery" -C 1

# Battery alerts in Home Assistant
mosquitto_sub -h localhost -t "homeassistant/sensor/+/battery/state"
```

#### Low Battery Alerts

```yaml
# configuration.yaml - Battery reporting optimization
device_options:
  # All battery devices
  battery_percentage_remaining:
    # Report battery every hour
    battery_reporting_interval: 3600
    
    # Alert thresholds
    battery_low_threshold: 20
    battery_critical_threshold: 10
```

### Firmware Updates (OTA)

#### Check for Updates

```bash
# Check if updates are available
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/ota_update/check" \
  -m '{"id": "device_name"}'

# Listen for update availability
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/response/device/ota_update/check"
```

#### Perform OTA Updates

```bash
# Start firmware update
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/ota_update/update" \
  -m '{"id": "device_name"}'

# Monitor update progress
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/logging"
```

#### OTA Configuration

```yaml
# configuration.yaml
ota:
  update_check_interval: 1440  # Check daily
  disable_automatic_update_check: false
  
  # Custom OTA index
  zigbee_ota_override_index_location: 'https://raw.githubusercontent.com/Koenkk/zigbee-OTA/master/index.json'
  
  # IKEA test updates
  ikea_ota_use_test_url: false
```

### Device Health Monitoring

#### Link Quality Monitoring

```bash
# Monitor link quality for all devices
mosquitto_sub -h localhost -t "zigbee2mqtt/+/linkquality"

# Get network map with link quality
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "raw"}'
```

#### Device Availability

```yaml
# configuration.yaml - Availability tracking
availability:
  active:
    timeout: 10  # Ping every 10 minutes
  passive:
    timeout: 1500  # Mark offline after 25 minutes
  
  # Exclude battery devices from active checking
  blocklist:
    - battery_sensor_1
    - battery_sensor_2
```

### Performance Optimization

#### Network Optimization

```bash
# Heal network (redistribute routes)
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/health_check" -m '{}'

# Check coordinator health
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/info" -C 1
```

#### Device-Specific Optimization

```yaml
device_options:
  # Optimize motion sensors
  motion_sensors:
    occupancy_timeout: 60
    sensitivity: 'medium'
    
    # Reduce unnecessary reports
    illuminance_reporting_interval: 300
    
  # Optimize smart plugs
  smart_plugs:
    # Faster state updates
    state_reporting_interval: 5
    power_reporting_interval: 60
    
  # Optimize lights
  smart_lights:
    # Smooth transitions
    transition: 1
    
    # Color sync
    color_sync: true
```

## Troubleshooting Device Issues

### Device Not Responding

```bash
# Ping specific device
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/ping" \
  -m '{"id": "unresponsive_device"}'

# Check device in network map
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "graphviz"}'

# Force interview device
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/interview" \
  -m '{"id": "problematic_device"}'
```

### Device State Issues

```bash
# Get current device configuration
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/get" \
  -m '{"id": "device_name"}'

# Reset device to defaults
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/configure" \
  -m '{"id": "device_name"}'
```

### Network Connectivity Issues

```bash
# Check network map for orphaned devices
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "raw", "routes": true}'

# Rebuild network routes
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/health_check" -m '{}'
```

## Next Steps

After device management setup:

1. **[Set Up Monitoring](monitoring.md)** - Configure logging and maintenance schedules
2. **[Integrate with Home Assistant](integration.md)** - Connect devices to automation platform
3. **[Configure Advanced Features](advanced.md)** - Set up security and performance optimization

## Related Topics

- [Configuration Guide](configuration.md) - Zigbee2MQTT configuration options
- [Monitoring and Maintenance](monitoring.md) - System monitoring and backup
- [Troubleshooting](troubleshooting.md) - Solving device and network issues
- [Home Assistant Integration](integration.md) - Automation platform integration
