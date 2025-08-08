---
uid: misc.homeassistant.deployment.homeassistant
title: Home Assistant Deployment
description: Dedicated Home Assistant deployment guide
keywords: [home assistant, deployment, docker, container, production]
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 08/07/2025
ms.topic: conceptual
---

## Home Assistant Deployment

This guide focuses specifically on deploying Home Assistant Core in various environments with production-ready configurations.

### Deployment Options

1. **Home Assistant OS**: Dedicated appliance approach
2. **Home Assistant Container**: Docker-based deployment
3. **Home Assistant Supervised**: Full features with custom OS
4. **Home Assistant Core**: Python virtual environment

## Container Deployment (Recommended)

### Basic Docker Compose Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    privileged: true
    restart: unless-stopped
    environment:
      - TZ=America/Chicago
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    ports:
      - "8123:8123"
    networks:
      - homeassistant
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # Z-Wave/Zigbee USB stick
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

networks:
  homeassistant:
    driver: bridge
```

### Production Docker Compose

```yaml
# production-docker-compose.yml
version: '3.8'

services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    privileged: true
    environment:
      - TZ=America/Chicago
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
    volumes:
      - homeassistant_config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
      - /dev:/dev
      - ./secrets:/run/secrets
    ports:
      - "8123:8123"
    networks:
      - homeassistant
      - database
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'

  postgres:
    image: postgres:15-alpine
    container_name: homeassistant_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=homeassistant
      - POSTGRES_USER=homeassistant
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./secrets:/run/secrets
    networks:
      - database
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U homeassistant"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  nginx:
    image: nginx:alpine
    container_name: homeassistant_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - nginx_logs:/var/log/nginx
    networks:
      - homeassistant
    depends_on:
      - homeassistant
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  homeassistant_config:
    driver: local
  postgres_data:
    driver: local
  nginx_logs:
    driver: local

networks:
  homeassistant:
    driver: bridge
  database:
    driver: bridge
    internal: true

secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
```

## Initial Setup

### Directory Structure

```bash
# Create directory structure
mkdir -p homeassistant/{config,secrets,nginx,backups}
cd homeassistant

# Set proper permissions
chmod 700 secrets/
chmod 755 config/
chmod 755 nginx/

# Create secrets
echo "your_secure_postgres_password" > secrets/postgres_password.txt
chmod 600 secrets/postgres_password.txt
```

### Configuration Files

#### Basic Configuration

Create `config/configuration.yaml`:

```yaml
# Loads default set of integrations
default_config:

# Text to speech
tts:
  - platform: google_translate

# Example automation
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

# Database configuration (if using PostgreSQL)
recorder:
  db_url: postgresql://homeassistant:password@postgres:5432/homeassistant
  purge_keep_days: 30
  auto_purge: true

# HTTP configuration
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12
  ip_ban_enabled: true
  login_attempts_threshold: 5
```

### Deployment Commands

```bash
# Start services
docker-compose up -d

# Monitor logs
docker-compose logs -f homeassistant

# Check service health
docker-compose ps

# Update containers
docker-compose pull
docker-compose down
docker-compose up -d --force-recreate

# Clean up unused images
docker image prune -f
```

## Security Configuration

### Nginx Reverse Proxy

Create `nginx/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream homeassistant {
        server homeassistant:8123;
    }
    
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }
    
    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name your-domain.com;
        
        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        
        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
        
        # Proxy settings
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        
        location / {
            proxy_pass http://homeassistant;
            proxy_read_timeout 90;
        }
        
        # API endpoint with increased timeout
        location /api/ {
            proxy_pass http://homeassistant;
            proxy_read_timeout 300;
        }
    }
}
```

## Troubleshooting

### Common Issues

```bash
# Check container logs
docker-compose logs homeassistant

# Check container health
docker-compose ps
docker inspect homeassistant | grep Health

# Check resource usage
docker stats homeassistant

# Check file permissions
docker-compose exec homeassistant ls -la /config

# Restart service
docker-compose restart homeassistant
```

### Configuration Validation

```bash
# Check Home Assistant configuration
docker-compose exec homeassistant python -m homeassistant --script check_config --config /config
```

For complete stack deployment with MQTT and Zigbee integration, see the [main deployment guide](index.md).
