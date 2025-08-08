# Zigbee2MQTT Installation Guide

Complete installation guide for Zigbee2MQTT across different platforms and deployment methods.

## Installation Methods Overview

Choose the installation method that best fits your environment:

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **Docker** | Most users | Easy updates, isolation | Requires Docker knowledge |
| **Native** | Raspberry Pi | Direct hardware access | Manual dependency management |
| **HA Add-on** | Home Assistant users | Integrated management | Limited customization |

## Method 1: Docker Installation (Recommended)

### Prerequisites

- Docker and Docker Compose installed
- USB Zigbee adapter properly connected
- MQTT broker available (see [Mosquitto Setup Guide](../mosquitto/index.md))

### Docker Compose Setup

Create directory structure:

```bash
mkdir -p ~/zigbee2mqtt/data
cd ~/zigbee2mqtt
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:latest
    restart: unless-stopped
    volumes:
      - ./data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      - "8080:8080"  # Web interface
    environment:
      - TZ=America/New_York  # Set your timezone
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # Adjust to your adapter
    networks:
      - zigbee2mqtt

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:latest
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/logs:/mosquitto/log
    networks:
      - zigbee2mqtt

networks:
  zigbee2mqtt:
    driver: bridge
```

### Device Detection

Find your Zigbee adapter:

```bash
# List USB devices
lsusb

# Check serial devices
ls -la /dev/ttyUSB* /dev/ttyACM*

# Check device permissions
ls -la /dev/ttyUSB0
```

### Start Services

```bash
# Start containers
docker-compose up -d

# Check logs
docker-compose logs -f zigbee2mqtt

# Verify container status
docker-compose ps
```

## Method 2: Native Installation on Raspberry Pi

### Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git and build tools
sudo apt-get install -y git build-essential

# Verify installation
node --version
npm --version
```

### Install Zigbee2MQTT

```bash
# Create user and directory
sudo useradd -r -s /bin/false zigbee2mqtt
sudo mkdir -p /opt/zigbee2mqtt
sudo chown -R zigbee2mqtt:zigbee2mqtt /opt/zigbee2mqtt

# Clone repository
sudo -u zigbee2mqtt git clone https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt

# Install dependencies
cd /opt/zigbee2mqtt
sudo -u zigbee2mqtt npm ci
```

### Create System Service

Create systemd service file:

```bash
sudo nano /etc/systemd/system/zigbee2mqtt.service
```

Service configuration:

```ini
[Unit]
Description=zigbee2mqtt
After=network.target

[Service]
ExecStart=/usr/bin/node index.js
WorkingDirectory=/opt/zigbee2mqtt
StandardOutput=inherit
StandardError=inherit
Restart=always
RestartSec=10s
User=zigbee2mqtt
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable zigbee2mqtt

# Start service
sudo systemctl start zigbee2mqtt

# Check status
sudo systemctl status zigbee2mqtt

# View logs
journalctl -u zigbee2mqtt -f
```

### Fix Permissions (if needed)

```bash
# Add user to dialout group
sudo usermod -a -G dialout zigbee2mqtt

# Set device permissions
sudo chmod 666 /dev/ttyUSB0

# Create udev rule for persistent permissions
sudo nano /etc/udev/rules.d/99-zigbee.rules
```

Udev rule content:

```text
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="zigbee", GROUP="dialout", MODE="0666"
```

Apply udev rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Method 3: Home Assistant Add-on

### Installation Steps

1. **Navigate to Add-on Store**
   - Go to **Supervisor → Add-on Store**
   - Search for "Zigbee2MQTT"
   - Click **Install**

2. **Basic Configuration**

   ```yaml
   data_path: /config/zigbee2mqtt
   socat:
     enabled: false
     master: pty,raw,echo=0,link=/tmp/ttyZ2M,mode=777
     slave: tcp-listen:8485,keepalive,nodelay,reuseaddr,keepidle=1,keepintvl=1,keepcnt=5
   mqtt:
     base_topic: zigbee2mqtt
     server: mqtt://core-mosquitto:1883
     user: homeassistant
     password: !secret mqtt_password
   serial:
     port: /dev/ttyUSB0
   ```

3. **Start Add-on**
   - Click **Start**
   - Enable **Start on boot**
   - Enable **Watchdog**

### Add-on Configuration Options

```yaml
# Advanced configuration
advanced:
  log_level: info
  pan_id: GENERATE
  channel: 11
  network_key: GENERATE
  
# Frontend
frontend:
  port: 8099
  
# Experimental features
experimental:
  new_api: true
```

## Post-Installation Verification

### Check Service Status

**Docker:**

```bash
# Container status
docker ps | grep zigbee2mqtt

# Container logs
docker logs zigbee2mqtt

# Test web interface
curl http://localhost:8080
```

**Native Installation:**

```bash
# Service status
sudo systemctl status zigbee2mqtt

# Service logs
journalctl -u zigbee2mqtt --since "5 minutes ago"

# Process check
ps aux | grep zigbee2mqtt
```

**Home Assistant Add-on:**

1. Check add-on logs in Supervisor
2. Verify web interface at http://[ha-ip]:8099
3. Check MQTT connectivity

### Test MQTT Connectivity

```bash
# Subscribe to bridge info
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/info"

# Check bridge state
mosquitto_sub -h localhost -t "zigbee2mqtt/bridge/state"

# Test coordinator
mosquitto_pub -h localhost -t "zigbee2mqtt/bridge/request/permit_join" -m '{"value": false}'
```

## Hardware Setup Verification

### USB Adapter Check

```bash
# Verify adapter detection
dmesg | grep -i usb
dmesg | grep -i cp210

# Check adapter capabilities
sudo cat /sys/bus/usb-serial/devices/ttyUSB0/../../manufacturer
sudo cat /sys/bus/usb-serial/devices/ttyUSB0/../../product
```

### Adapter Configuration

| Adapter Type | Device Path | Baud Rate | Notes |
|--------------|-------------|-----------|-------|
| CC2531 | `/dev/ttyACM0` | 115200 | Requires firmware flash |
| CC2652P | `/dev/ttyUSB0` | 115200 | Recommended |
| ConBee II | `/dev/ttyACM0` | 38400 | Use deconz adapter |
| Sonoff Plus | `/dev/ttyUSB0` | 115200 | Pre-flashed |

## Updating Zigbee2MQTT

### Docker Update

```bash
# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d

# Cleanup old images
docker image prune
```

### Native Installation Update

```bash
# Stop service
sudo systemctl stop zigbee2mqtt

# Update code
cd /opt/zigbee2mqtt
sudo -u zigbee2mqtt git fetch
sudo -u zigbee2mqtt git pull

# Update dependencies
sudo -u zigbee2mqtt npm ci

# Start service
sudo systemctl start zigbee2mqtt
```

### Home Assistant Add-on Update

1. Go to **Supervisor → Dashboard**
2. Click **Update** button if available
3. Monitor update progress in logs

## Backup Before Configuration

```bash
# Create backup directory
mkdir -p ~/zigbee2mqtt-backup/initial

# Docker backup
docker cp zigbee2mqtt:/app/data/configuration.yaml ~/zigbee2mqtt-backup/initial/

# Native backup
cp /opt/zigbee2mqtt/data/configuration.yaml ~/zigbee2mqtt-backup/initial/

# Add-on backup
cp /config/zigbee2mqtt/configuration.yaml ~/zigbee2mqtt-backup/initial/
```

## Common Installation Issues

### Permission Denied Errors

```bash
# Fix USB permissions
sudo usermod -a -G dialout $USER
sudo chmod 666 /dev/ttyUSB0

# For Docker users
sudo usermod -a -G dialout $USER
```

### Port Already in Use

```bash
# Check what's using port 8080
sudo netstat -tulpn | grep :8080
sudo lsof -i :8080

# Change port in configuration
# Edit docker-compose.yml or configuration.yaml
```

### Adapter Not Detected

```bash
# Check USB devices
lsusb -v

# Check kernel modules
lsmod | grep usb

# Try different USB port
# Use powered USB hub if needed
```

### Node.js Version Issues

```bash
# Check Node.js version (need 16+)
node --version

# Update Node.js if needed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Next Steps

After successful installation:

1. **[Configure Zigbee2MQTT](configuration.md)** - Set up basic configuration
2. **[Pair Your First Device](device-management.md)** - Start adding Zigbee devices
3. **[Set Up Monitoring](monitoring.md)** - Configure logging and backup
4. **[Integrate with Home Assistant](integration.md)** - Connect to your automation platform

## Related Topics

- [Zigbee2MQTT Overview](index.md) - Architecture and prerequisites
- [Mosquitto MQTT Setup](../mosquitto/index.md) - MQTT broker configuration
- [Configuration Guide](configuration.md) - Detailed configuration options
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
