---
uid: misc.homeassistant.homeassistant.deployment
title: Home Assistant Deployment Guide (Moved)
description: This deployment guide has been moved to the dedicated deployment section
keywords: [home assistant, deployment, docker, docker-compose, installation, container]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Deployment Guide Moved

The Home Assistant deployment documentation has been reorganized and moved to a dedicated deployment section for better organization.

### New Deployment Documentation Location

Please refer to the comprehensive deployment guides:

- **[Complete Stack Deployment](../deployment/index.md)** - Full Home Assistant, Mosquitto, and Zigbee2MQTT stack
- **[Home Assistant Only](../deployment/homeassistant.md)** - Dedicated Home Assistant deployment
- **[Mosquitto MQTT](../deployment/mosquitto.md)** - MQTT broker deployment
- **[Zigbee2MQTT](../deployment/zigbee2mqtt.md)** - Zigbee device integration

### What's Available

The new deployment section includes:

1. **Complete Stack Deployment**: Ready-to-deploy Docker Compose configurations for the entire Home Assistant ecosystem
2. **Individual Service Deployment**: Focused deployment guides for each component
3. **Production Configurations**: Security, monitoring, and backup strategies
4. **Troubleshooting**: Common issues and solutions
5. **Cross-Platform Support**: Docker, native installation, and Raspberry Pi optimizations

### Quick Start

For a complete Home Assistant stack with MQTT and Zigbee support:

```bash
# Navigate to the complete deployment guide
# Follow: ../deployment/index.md

# Quick stack deployment
mkdir homeassistant-stack
cd homeassistant-stack
# Download docker-compose.yml from deployment guide
docker-compose up -d
```

This reorganization provides better separation of concerns and more focused documentation for each deployment scenario.
