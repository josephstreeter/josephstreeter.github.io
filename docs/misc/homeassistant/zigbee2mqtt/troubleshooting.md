---
uid: misc.homeassistant.zigbee2mqtt.troubleshooting
title: Zigbee2MQTT Troubleshooting Guide
description: Comprehensive troubleshooting guide for common Zigbee2MQTT issues, diagnostics, and recovery procedures
keywords: [zigbee2mqtt, troubleshooting, debugging, logs, diagnostics, recovery]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: troubleshooting
---

This guide covers common issues, diagnostic procedures, and solutions for Zigbee2MQTT problems.

## Quick Diagnostic Steps

### 1. Check System Status

```bash
# Check if Zigbee2MQTT is running
sudo systemctl status zigbee2mqtt

# Check Docker container status
docker ps | grep zigbee2mqtt

# Check resource usage
htop | grep zigbee2mqtt
```

### 2. Verify Basic Connectivity

```bash
# Test MQTT broker connection
mosquitto_pub -h localhost -t test -m "hello"
mosquitto_sub -h localhost -t test

# Check Zigbee adapter
lsusb | grep -i zigbee
ls -la /dev/ttyUSB* /dev/ttyACM*
```

### 3. Review Recent Logs

```bash
# System logs
journalctl -u zigbee2mqtt -f --since "1 hour ago"

# Docker logs
docker logs zigbee2mqtt --since 1h -f

# Application logs
tail -f /opt/zigbee2mqtt/data/log/*/debug.log
```

## Common Connection Issues

### Adapter Not Found

**Symptoms:**

- Error: "Failed to connect to the adapter"
- "No such file or directory" errors
- Zigbee2MQTT fails to start

**Solutions:**

1. **Check USB Connection:**

    ```bash
    # List USB devices
    lsusb
    dmesg | grep -i usb | tail -20

    # Check device permissions
    ls -la /dev/ttyUSB* /dev/ttyACM*
    sudo usermod -a -G dialout $USER
    ```

2. **Update Device Path:**

    ```yaml
    # configuration.yaml
    serial:
    port: /dev/ttyUSB0  # or /dev/ttyACM0
    adapter: zstack     # or ezsp, deconz
    ```

3. **Docker USB Passthrough:**

    ```yaml
    # docker-compose.yml
    devices:
    - /dev/ttyUSB0:/dev/ttyUSB0
    # Or for dynamic detection:
    volumes:
    - /dev:/dev
    privileged: true
    ```

### MQTT Connection Failed

**Symptoms:**

- "Connection refused" errors
- "MQTT publish failed" messages
- Devices not updating in Home Assistant

**Solutions:**

1. **Verify MQTT Broker:**

    ```bash
    # Test MQTT connection
    mosquitto_pub -h mqtt_broker_ip -p 1883 -t test -m "test"
    mosquitto_sub -h mqtt_broker_ip -p 1883 -t zigbee2mqtt/bridge/state
    ```

2. **Check Configuration:**

    ```yaml
    # configuration.yaml
    mqtt:
    server: mqtt://localhost:1883
    user: mqtt_user
    password: mqtt_password
    client_id: zigbee2mqtt
    keepalive: 60
    reject_unauthorized: true
    ```

3. **Network Connectivity:**

    ```bash
    # Test network reach
    ping mqtt_broker_ip
    telnet mqtt_broker_ip 1883
    nmap -p 1883 mqtt_broker_ip
    ```

## Device Pairing Issues

### Device Won't Pair

**Common Causes and Solutions:**

1. **Network Full (254 device limit):**

    ```bash
    # Check network size
    mosquitto_sub -t "zigbee2mqtt/bridge/devices" | jq length
    ```

2. **Permit Join Disabled:**

    ```bash
    # Enable pairing mode
    mosquitto_pub -t "zigbee2mqtt/bridge/request/permit_join" -m '{"value": true, "time": 120}'
    ```

3. **Device Already Paired:**

    ```bash
    # Check existing devices
    mosquitto_sub -t "zigbee2mqtt/bridge/devices" | jq '.[] | .friendly_name'

    # Force remove if needed
    mosquitto_pub -t "zigbee2mqtt/bridge/request/device/remove" -m '{"id": "0x00158d0001234567"}'
    ```

4. **Reset Device:**

- **Xiaomi sensors:** Press and hold button for 5+ seconds
- **Philips Hue:** Use dimmer switch or bridge app
- **IKEA:** Press button 4 times quickly
- **Aqara:** Press and hold for 5 seconds until blue light

### Pairing Timeout

**Solutions:**

1. **Increase Pairing Timeout:**

    ```yaml
    # configuration.yaml
    advanced:
    network_key: GENERATE
    channel: 11
    pan_id: 0x1a62
    ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
    log_level: debug
    homeassistant_discovery_topic: homeassistant
    homeassistant_status_topic: homeassistant/status
    permit_join: true
    last_seen: ISO_8601_local
    elapsed: true
    network_scan: false
    soft_reset_timeout: 3000
    ```

2. **Bring Device Closer:**

    - Move device within 1-2 meters of coordinator during pairing
    - Ensure no interference from WiFi, microwaves, etc.
    - Try different USB extension cable if needed

3. **Check Coordinator Range:**

    ```bash
    # View network topology
    mosquitto_sub -t "zigbee2mqtt/bridge/networkmap" | jq .
    ```

## Performance Issues

### High CPU/Memory Usage

**Diagnostic Steps:**

1. **Monitor Resource Usage:**

    ```bash
    # Check system resources
    htop | grep zigbee2mqtt
    docker stats zigbee2mqtt

    # Check log file sizes
    du -sh /opt/zigbee2mqtt/data/log/
    ```

2. **Optimize Logging:**

    ```yaml
    # configuration.yaml
    advanced:
    log_level: info  # Change from debug
    log_output: ['console', 'file']
    log_file: debug.log
    log_rotation: true
    log_max_files: 5
    ```

3. **Reduce Reporting Frequency:**

    ```yaml
    # For battery devices
    device_options:
    "0x00158d0001234567":
        reporting_config:
        temperature:
            min_interval: 300    # 5 minutes
            max_interval: 3600   # 1 hour
            change: 0.5         # 0.5°C change
    ```

### Network Congestion

**Symptoms:**

- Slow device responses
- Messages timing out
- Network map showing poor links

**Solutions:**

1. **Optimize Zigbee Channel:**

    ```bash
    # Scan for interference
    iwlist scan | grep -i channel
    # Choose channel 11, 15, 20, or 25 (avoid WiFi overlap)
    ```

2. **Add Router Devices:**

    - Place mains-powered devices strategically
    - Use dedicated Zigbee routers for large networks
    - Ensure good mesh topology

3. **Reduce Network Load:**

    ```yaml
    # configuration.yaml
    advanced:
    availability_timeout: 0  # Disable if not needed
    availability_blocklist: []
    availability_passlist: ['important_device_1', 'important_device_2']
    ```

## Log Analysis

### Understanding Log Levels

```yaml
# configuration.yaml
advanced:
  log_level: debug  # error, warn, info, debug
```

**Log Level Meanings:**

- **error:** Critical issues only
- **warn:** Warnings and errors
- **info:** General information (recommended)
- **debug:** Detailed debugging (use temporarily)

### Common Error Messages

1. **"Failed to ping":**

    ```bash
    # Device may be sleeping or out of range
    # For battery devices, this is often normal
    mosquitto_pub -t "zigbee2mqtt/DEVICE_NAME/get" -m '{"state": ""}'
    ```

2. **"Publish failed":**

    ```bash
    # MQTT connection issue
    # Check broker status and credentials
    sudo systemctl status mosquitto
    ```

3. **"Device announce":**

    ```bash
    # Device rejoining network (normal after power cycle)
    # May indicate power issues if frequent
    ```

4. **"Interview failed":**

    ```bash
    # Device pairing incomplete
    # Try re-pairing or factory reset
    mosquitto_pub -t "zigbee2mqtt/bridge/request/device/interview" -m '{"id": "DEVICE_NAME"}'
    ```

### Log Analysis Scripts

```bash
#!/bin/bash
# analyze_logs.sh - Analyze Zigbee2MQTT logs for common issues

LOG_FILE="/opt/zigbee2mqtt/data/log/$(date +%Y-%m-%d).debug.log"

echo "=== Zigbee2MQTT Log Analysis ==="
echo "Analyzing: $LOG_FILE"
echo

echo "Error Summary:"
grep -i "error" "$LOG_FILE" | cut -d' ' -f3- | sort | uniq -c | sort -nr

echo -e "\nWarning Summary:"
grep -i "warn" "$LOG_FILE" | cut -d' ' -f3- | sort | uniq -c | sort -nr

echo -e "\nDevice Issues:"
grep -E "(failed to ping|interview failed|device announce)" "$LOG_FILE" | \
  grep -o '0x[0-9a-fA-F]\+\|[a-zA-Z_][a-zA-Z0-9_]*' | sort | uniq -c | sort -nr

echo -e "\nNetwork Events:"
grep -E "(permit join|device joined|device left)" "$LOG_FILE" | wc -l
echo "Network events found"

echo -e "\nMQTT Issues:"
grep -i "mqtt" "$LOG_FILE" | grep -i "error\|fail\|timeout" | wc -l
echo "MQTT issues found"
```

## Recovery Procedures

### Network Reset

**When to Use:**

- Network becomes unstable
- Many devices become unresponsive
- After major configuration changes

**Steps:**

1. **Backup Current Network:**

    ```bash
    # Backup coordinator backup
    cp /opt/zigbee2mqtt/data/coordinator_backup.json /opt/zigbee2mqtt/data/coordinator_backup_$(date +%Y%m%d).json

    # Backup devices database
    cp /opt/zigbee2mqtt/data/database.db /opt/zigbee2mqtt/data/database_backup_$(date +%Y%m%d).db
    ```

2. **Soft Reset (Recommended):**

    ```yaml
    # configuration.yaml
    advanced:
    network_key: GENERATE  # Keep existing or generate new
    channel: 11           # Can change if needed
    pan_id: 0x1a62       # Generate new if needed
    ```

3. **Hard Reset (Last Resort):**

    ```bash
    # Stop Zigbee2MQTT
    sudo systemctl stop zigbee2mqtt

    # Remove network data
    rm /opt/zigbee2mqtt/data/coordinator_backup.json
    rm /opt/zigbee2mqtt/data/database.db

    # Start fresh
    sudo systemctl start zigbee2mqtt
    ```

### Device Recovery

**Force Re-interview:**

```bash
# Re-interview specific device
mosquitto_pub -t "zigbee2mqtt/bridge/request/device/interview" -m '{"id": "DEVICE_NAME"}'

# Check interview status
mosquitto_sub -t "zigbee2mqtt/bridge/response/device/interview"
```

**Reconfigure Reporting:**

```bash
# Reset device reporting
mosquitto_pub -t "zigbee2mqtt/bridge/request/device/configure_reporting" -m '{"id": "DEVICE_NAME"}'
```

**Force Device Removal:**

```bash
# Remove unresponsive device
mosquitto_pub -t "zigbee2mqtt/bridge/request/device/remove" -m '{"id": "DEVICE_NAME", "force": true}'
```

### Coordinator Recovery

**Backup Restoration:**

```bash
# Stop service
sudo systemctl stop zigbee2mqtt

# Restore backup
cp /opt/zigbee2mqtt/data/coordinator_backup_20231201.json /opt/zigbee2mqtt/data/coordinator_backup.json

# Start service
sudo systemctl start zigbee2mqtt
```

**Firmware Recovery:**

```bash
# Check firmware version
mosquitto_sub -t "zigbee2mqtt/bridge/info" | jq .coordinator

# Flash firmware (example for CC2652)
python3 cc2538-bsl.py -p /dev/ttyUSB0 -evw CC2652R_coordinator_20230507.hex
```

## Diagnostic Tools

### Network Visualization

```bash
#!/bin/bash
# network_health.sh - Check network health

echo "=== Zigbee Network Health Check ==="

# Get network info
echo "Network Information:"
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/info" -C 1 | jq .

# Get device count
echo -e "\nDevice Count:"
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1 | jq 'length'

# Check for offline devices
echo -e "\nOffline Devices:"
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1 | \
  jq '.[] | select(.network_address == null) | .friendly_name'

# Network map
echo -e "\nGenerating network map..."
mosquitto_pub -t "zigbee2mqtt/bridge/request/networkmap" -m '{"type": "raw", "routes": false}'
sleep 2
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/response/networkmap" -C 1 | jq .
```

### Signal Quality Check

```bash
#!/bin/bash
# signal_check.sh - Check device signal quality

echo "=== Signal Quality Report ==="

# Get all devices with LQI info
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1 | \
  jq '.[] | select(.network_address != null) | {
    name: .friendly_name,
    lqi: .lqi,
    address: .network_address,
    type: .type
  }' | \
  jq -s 'sort_by(.lqi) | reverse'
```

### Performance Monitor

```bash
#!/bin/bash
# performance_monitor.sh - Monitor system performance

echo "=== Performance Monitor ==="

# System resources
echo "System Resources:"
free -h
df -h /opt/zigbee2mqtt/

# Process info
echo -e "\nZigbee2MQTT Process:"
ps aux | grep zigbee2mqtt | grep -v grep

# Network statistics
echo -e "\nNetwork Statistics:"
netstat -i

# MQTT broker status
echo -e "\nMQTT Broker:"
sudo systemctl status mosquitto --no-pager -l
```

## Prevention Best Practices

### Regular Maintenance

1. **Weekly Checks:**
   - Review logs for errors
   - Check device battery levels
   - Verify network topology

2. **Monthly Tasks:**
   - Update firmware if available
   - Clean log files
   - Backup configuration and network

3. **Quarterly Actions:**
   - Review device performance
   - Optimize network configuration
   - Plan for network expansion

### Monitoring Setup

```yaml
# configuration.yaml
advanced:
  log_level: info
  log_rotation: true
  log_max_files: 10
  
availability:
  active:
    timeout: 10
  passive:
    timeout: 1500

homeassistant:
  discovery_topic: homeassistant
  status_topic: homeassistant/status
  legacy_entity_attributes: false
  legacy_triggers: false
```

### Alerting Configuration

Set up alerts for critical issues:

1. **Service Down Alerts**
2. **High Error Rate Notifications**
3. **Device Offline Warnings**
4. **Network Capacity Alerts**

## Emergency Contacts

### Community Resources

- **GitHub Issues**: Report bugs and feature requests
- **Community Forum**: Get help from experienced users
- **Discord/Telegram**: Real-time community support
- **Documentation**: Official troubleshooting guides

### Professional Support

For enterprise deployments:

- Consider professional Zigbee consultants
- Hardware vendor support for coordinators
- Home automation integrator assistance

---

> **Remember**: Most issues can be resolved with patience and systematic troubleshooting. Always backup your configuration before making major changes, and don't hesitate to ask the community for help with specific issues.
