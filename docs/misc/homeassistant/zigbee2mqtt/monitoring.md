# Zigbee2MQTT Monitoring and Maintenance

Comprehensive guide for monitoring system health, maintaining network performance, and implementing backup strategies.

## System Monitoring

### Log Management

#### Log Configuration

```yaml
# configuration.yaml
advanced:
  log_level: info  # error, warn, info, debug
  log_output: ['console', 'file']
  log_directory: data/log/%TIMESTAMP%
  log_file: log.txt
  log_rotation: true
  log_symlink_current: true
  log_max_files: 10
```

#### Real-time Log Monitoring

```bash
# Native installation
tail -f /opt/zigbee2mqtt/data/log/log.txt

# Docker installation
docker logs -f zigbee2mqtt

# Systemd service logs
journalctl -u zigbee2mqtt -f

# Filter logs by level
journalctl -u zigbee2mqtt --since "1 hour ago" | grep ERROR
```

#### Log Analysis

```bash
# Count error messages
grep -c "ERROR" /opt/zigbee2mqtt/data/log/log.txt

# Find device-specific issues
grep "device_name" /opt/zigbee2mqtt/data/log/log.txt

# Monitor pairing activity
grep -i "pair\|join" /opt/zigbee2mqtt/data/log/log.txt

# Check network health
grep -i "link\|quality\|route" /opt/zigbee2mqtt/data/log/log.txt
```

### Network Health Monitoring

#### Network Map Generation

```bash
# Generate network topology map
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "raw"}'

# Generate Graphviz format for visualization
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "graphviz"}'

# Include route information
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" \
  -m '{"type": "raw", "routes": true}'
```

#### Link Quality Monitoring

```bash
# Monitor all device link quality
mosquitto_sub -h localhost -t "zigbee2mqtt/+/linkquality"

# Check specific device link quality
mosquitto_sub -h localhost -t "zigbee2mqtt/sensor_name/linkquality" -C 1

# Monitor link quality changes
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/logging" | grep -i "link"
```

#### Device Availability Tracking

```bash
# Monitor device availability
mosquitto_sub -h localhost -t "zigbee2mqtt/+/availability"

# Check offline devices
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/logging" | grep -i "offline"

# Get device list with status
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1
```

### Performance Metrics

#### System Resource Monitoring

```bash
# Monitor CPU and memory usage
htop

# Check disk space
df -h /opt/zigbee2mqtt

# Monitor process resources
ps aux | grep zigbee2mqtt

# Check USB device status
lsusb -v | grep -A 10 -B 10 "Zigbee\|CC2652\|ConBee"
```

#### MQTT Message Monitoring

```bash
# Monitor all MQTT traffic
mosquitto_sub -h localhost -t "#" -v

# Count messages per minute
mosquitto_sub -h localhost -t "zigbee2mqtt/#" | pv -l -r > /dev/null

# Monitor bridge messages
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/#"

# Check message sizes
mosquitto_sub -h localhost -t "zigbee2mqtt/+/get" -F '@Y-@m-@d @H:@M:@S %t %p'
```

#### Database Growth Monitoring

```bash
# Check database size
ls -lh /opt/zigbee2mqtt/data/database.db

# Monitor database growth over time
du -h /opt/zigbee2mqtt/data/ | tee -a db_size_log.txt

# Database integrity check (SQLite)
sqlite3 /opt/zigbee2mqtt/data/database.db "PRAGMA integrity_check;"
```

## Backup and Recovery

### Configuration Backup

#### Automated Backup Script

```bash
#!/bin/bash
# backup-zigbee2mqtt.sh

BACKUP_DIR="/home/pi/backups/zigbee2mqtt"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Stop Zigbee2MQTT (optional for consistency)
sudo systemctl stop zigbee2mqtt

# Copy essential files
cp /opt/zigbee2mqtt/data/configuration.yaml "$BACKUP_PATH/"
cp /opt/zigbee2mqtt/data/database.db "$BACKUP_PATH/"
cp /opt/zigbee2mqtt/data/coordinator_backup.json "$BACKUP_PATH/" 2>/dev/null || true

# Copy log files (recent)
cp -r /opt/zigbee2mqtt/data/log "$BACKUP_PATH/" 2>/dev/null || true

# Start Zigbee2MQTT
sudo systemctl start zigbee2mqtt

# Compress backup
tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_PATH"

# Keep only last 30 backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_PATH.tar.gz"
```

#### Docker Backup Script

```bash
#!/bin/bash
# docker-backup-zigbee2mqtt.sh

BACKUP_DIR="/home/user/backups/zigbee2mqtt"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_NAME="zigbee2mqtt"

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

# Copy files from container
docker cp "$CONTAINER_NAME:/app/data/configuration.yaml" "$BACKUP_DIR/$DATE/"
docker cp "$CONTAINER_NAME:/app/data/database.db" "$BACKUP_DIR/$DATE/"
docker cp "$CONTAINER_NAME:/app/data/coordinator_backup.json" "$BACKUP_DIR/$DATE/" 2>/dev/null || true

# Compress backup
tar -czf "$BACKUP_DIR/$DATE.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_DIR/$DATE"

# Retention policy
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Docker backup completed: $BACKUP_DIR/$DATE.tar.gz"
```

#### Schedule Backups with Cron

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /home/pi/scripts/backup-zigbee2mqtt.sh >> /var/log/zigbee2mqtt-backup.log 2>&1

# Add weekly full backup
0 3 * * 0 /home/pi/scripts/full-backup-zigbee2mqtt.sh

# Add pre-update backup
@reboot sleep 60 && /home/pi/scripts/backup-zigbee2mqtt.sh
```

### Database Management

#### Database Backup

```bash
# Create database backup with timestamp
cp /opt/zigbee2mqtt/data/database.db \
   "/home/pi/backups/database_$(date +%Y%m%d_%H%M%S).db"

# Verify database integrity
sqlite3 /opt/zigbee2mqtt/data/database.db ".backup backup.db"
```

#### Database Recovery

```bash
# Stop Zigbee2MQTT
sudo systemctl stop zigbee2mqtt

# Restore database from backup
cp /home/pi/backups/database_20240807_120000.db \
   /opt/zigbee2mqtt/data/database.db

# Fix permissions
chown zigbee2mqtt:zigbee2mqtt /opt/zigbee2mqtt/data/database.db

# Start Zigbee2MQTT
sudo systemctl start zigbee2mqtt

# Verify recovery
journalctl -u zigbee2mqtt --since "5 minutes ago"
```

### Coordinator Backup

#### Create Coordinator Backup

```bash
# Trigger coordinator backup via MQTT
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/backup" -m '{}'

# Manual backup location
ls -la /opt/zigbee2mqtt/data/coordinator_backup.json

# Verify backup content
cat /opt/zigbee2mqtt/data/coordinator_backup.json | jq .
```

#### Coordinator Recovery

```bash
# Stop Zigbee2MQTT
sudo systemctl stop zigbee2mqtt

# Restore coordinator backup
cp /home/pi/backups/coordinator_backup_20240807.json \
   /opt/zigbee2mqtt/data/coordinator_backup.json

# Start Zigbee2MQTT (will restore automatically)
sudo systemctl start zigbee2mqtt

# Monitor restoration process
tail -f /opt/zigbee2mqtt/data/log/log.txt
```

## Maintenance Tasks

### Regular Maintenance Schedule

#### Daily Tasks

```bash
#!/bin/bash
# daily-maintenance.sh

# Check service status
systemctl is-active zigbee2mqtt

# Monitor error logs
grep ERROR /opt/zigbee2mqtt/data/log/log.txt | tail -10

# Check disk space
df -h /opt/zigbee2mqtt | awk 'NR==2 {print $5}' | sed 's/%//'

# Verify MQTT connectivity
timeout 5 mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/state" -C 1
```

#### Weekly Tasks

```bash
#!/bin/bash
# weekly-maintenance.sh

# Health check
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/health_check" -m '{}'

# Check for firmware updates
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/device/ota_update/check" -m '{"id": "all"}'

# Network map generation
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" -m '{"type": "raw"}' > /tmp/network_map.json

# Analyze device performance
grep -c "linkquality" /opt/zigbee2mqtt/data/log/log.txt
```

#### Monthly Tasks

```bash
#!/bin/bash
# monthly-maintenance.sh

# Update Zigbee2MQTT
cd /opt/zigbee2mqtt
sudo -u zigbee2mqtt git pull
sudo -u zigbee2mqtt npm ci

# Clean old log files
find /opt/zigbee2mqtt/data/log -name "*.txt" -mtime +90 -delete

# Database maintenance
sqlite3 /opt/zigbee2mqtt/data/database.db "VACUUM;"

# Review device battery levels
mosquitto_sub -h localhost -t "zigbee2mqtt/+/battery" -W 30 | sort -n
```

### Performance Optimization

#### Network Optimization

```bash
# Check and optimize Zigbee channel
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/health_check" -m '{}'

# Analyze WiFi interference
sudo iwlist scan | grep -E "Channel:|ESSID:" | head -20

# Optimal channel selection script
#!/bin/bash
for channel in 11 15 20 25 26; do
    echo "Testing channel $channel"
    # Test logic here
done
```

#### Database Optimization

```bash
# Analyze database size
sqlite3 /opt/zigbee2mqtt/data/database.db ".schema" | head -20

# Optimize database
sqlite3 /opt/zigbee2mqtt/data/database.db "ANALYZE; VACUUM;"

# Check database statistics
sqlite3 /opt/zigbee2mqtt/data/database.db "SELECT COUNT(*) FROM devices;"
```

#### Advanced Log Management

```bash
# Configure log rotation
cat > /etc/logrotate.d/zigbee2mqtt << EOF
/opt/zigbee2mqtt/data/log/*.txt {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 zigbee2mqtt zigbee2mqtt
    postrotate
        systemctl reload zigbee2mqtt
    endscript
}
EOF
```

## Alerting and Notifications

### System Health Alerts

#### Basic Monitoring Script

```bash
#!/bin/bash
# monitor-zigbee2mqtt.sh

ALERT_EMAIL="admin@example.com"
LOG_FILE="/opt/zigbee2mqtt/data/log/log.txt"

# Check if service is running
if ! systemctl is-active --quiet zigbee2mqtt; then
    echo "Zigbee2MQTT service is down!" | mail -s "Zigbee2MQTT Alert" $ALERT_EMAIL
fi

# Check for recent errors
ERROR_COUNT=$(grep -c "ERROR" $LOG_FILE | tail -100)
if [ $ERROR_COUNT -gt 10 ]; then
    echo "High error count detected: $ERROR_COUNT errors" | mail -s "Zigbee2MQTT Errors" $ALERT_EMAIL
fi

# Check coordinator connectivity
if ! timeout 10 mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/state" -C 1 | grep -q "online"; then
    echo "Coordinator appears offline" | mail -s "Zigbee2MQTT Coordinator Alert" $ALERT_EMAIL
fi
```

#### Device Health Monitoring

```bash
#!/bin/bash
# device-health-monitor.sh

# Check for offline devices
OFFLINE_DEVICES=$(mosquitto_sub -h localhost -t "zigbee2mqtt/+/availability" -W 10 | grep "offline" | wc -l)

if [ $OFFLINE_DEVICES -gt 0 ]; then
    echo "$OFFLINE_DEVICES devices are offline" | mail -s "Device Offline Alert" admin@example.com
fi

# Monitor battery levels
LOW_BATTERY=$(mosquitto_sub -h localhost -t "zigbee2mqtt/+/battery" -W 30 | awk '$1 < 20 {count++} END {print count+0}')

if [ $LOW_BATTERY -gt 0 ]; then
    echo "$LOW_BATTERY devices have low battery" | mail -s "Low Battery Alert" admin@example.com
fi
```

### Integration with Monitoring Systems

#### Prometheus Metrics

```yaml
# configuration.yaml
advanced:
  metrics: true

experimental:
  new_api: true

frontend:
  metrics_port: 9090
```

#### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Zigbee2MQTT Monitoring",
    "panels": [
      {
        "title": "Device Count",
        "type": "stat",
        "targets": [
          {
            "expr": "zigbee2mqtt_devices_total"
          }
        ]
      },
      {
        "title": "Message Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(zigbee2mqtt_messages_total[5m])"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting Monitoring Issues

### Log Analysis Tools

#### Error Pattern Detection

```bash
# Find common error patterns
grep -E "ERROR|WARN|CRITICAL" /opt/zigbee2mqtt/data/log/log.txt | \
    awk '{print $4}' | sort | uniq -c | sort -nr

# Timeline analysis
grep ERROR /opt/zigbee2mqtt/data/log/log.txt | \
    awk '{print $1" "$2}' | sort | uniq -c

# Device-specific issues
grep "device_name" /opt/zigbee2mqtt/data/log/log.txt | \
    grep -E "ERROR|timeout|failed"
```

#### Performance Analysis

```bash
# Message frequency analysis
grep "received MQTT message" /opt/zigbee2mqtt/data/log/log.txt | \
    awk '{print $1" "$2}' | cut -c1-13 | uniq -c

# Response time monitoring
grep -E "publishing|received" /opt/zigbee2mqtt/data/log/log.txt | \
    awk '{print $1" "$2" "$3}'
```

### Common Monitoring Issues

#### Log File Issues

```bash
# Check log file permissions
ls -la /opt/zigbee2mqtt/data/log/

# Fix log permissions
sudo chown -R zigbee2mqtt:zigbee2mqtt /opt/zigbee2mqtt/data/log/

# Check disk space for logs
du -sh /opt/zigbee2mqtt/data/log/
```

#### MQTT Monitoring Problems

```bash
# Test MQTT connectivity
mosquitto_pub -h localhost -t "test/topic" -m "test message"
mosquitto_sub -h localhost -t "test/topic" -C 1

# Check MQTT broker status
systemctl status mosquitto

# Verify MQTT credentials
mosquitto_pub -h localhost -u username -P password -t "test" -m "auth test"
```

## Reporting and Documentation

### Generate System Reports

#### Health Report Script

```bash
#!/bin/bash
# generate-health-report.sh

REPORT_FILE="/tmp/zigbee2mqtt-health-$(date +%Y%m%d).txt"

echo "Zigbee2MQTT Health Report - $(date)" > $REPORT_FILE
echo "=================================" >> $REPORT_FILE

# Service status
echo -e "\nService Status:" >> $REPORT_FILE
systemctl status zigbee2mqtt --no-pager >> $REPORT_FILE

# Device count
echo -e "\nDevice Statistics:" >> $REPORT_FILE
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/devices" -C 1 | \
    jq length >> $REPORT_FILE

# Recent errors
echo -e "\nRecent Errors (last 24h):" >> $REPORT_FILE
grep ERROR /opt/zigbee2mqtt/data/log/log.txt | tail -10 >> $REPORT_FILE

# Resource usage
echo -e "\nResource Usage:" >> $REPORT_FILE
ps aux | grep zigbee2mqtt | grep -v grep >> $REPORT_FILE
df -h /opt/zigbee2mqtt >> $REPORT_FILE

echo "Report generated: $REPORT_FILE"
```

#### Network Topology Report

```bash
#!/bin/bash
# network-topology-report.sh

# Generate network map
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/networkmap" -m '{"type": "raw"}' 

# Wait for response and save
sleep 5
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/response/networkmap" -C 1 > network_topology.json

# Analyze topology
echo "Network Analysis - $(date)"
echo "Total devices: $(jq '.nodes | length' network_topology.json)"
echo "Router devices: $(jq '.nodes | map(select(.type == "Router")) | length' network_topology.json)"
echo "End devices: $(jq '.nodes | map(select(.type == "EndDevice")) | length' network_topology.json)"
```

## Next Steps

After setting up monitoring:

1. **[Configure Advanced Features](advanced.md)** - Security and performance optimization
2. **[Set Up Home Assistant Integration](integration.md)** - Connect to automation platform
3. **[Review Troubleshooting Guide](troubleshooting.md)** - Handle common issues

## Related Topics

- [Configuration Guide](configuration.md) - System configuration options
- [Device Management](device-management.md) - Managing Zigbee devices
- [Troubleshooting](troubleshooting.md) - Diagnosing and fixing issues
- [Advanced Topics](advanced.md) - Security and performance optimization
