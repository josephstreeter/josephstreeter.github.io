---
title: Working with Docker Containers
description: Advanced Docker container management, lifecycle operations, networking, and production deployment strategies
author: Joseph Streeter
date: 2024-01-15
tags: [docker, containers, deployment, networking, volumes, production]
---

This comprehensive guide covers advanced Docker container operations, from lifecycle management to production deployment strategies. It builds upon the [Docker Quickstart](quickstart.md) guide.

## Container Lifecycle Management

### Container States

Containers transition through several states during their lifecycle:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Container Lifecycle                          │
├─────────────────────────────────────────────────────────────────┤
│  Created → Running → Paused → Stopped → Removed                │
│      ↑         ↓         ↑         ↑         ↑                 │
│      └─────────┴─────────┴─────────┴─────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

### Advanced Container Operations

#### Creating Containers

```bash
# Create container without starting
docker create --name webserver nginx:latest

# Create with resource limits
docker create --name limited-app \
  --memory="512m" \
  --cpus="1.0" \
  --storage-opt size=10G \
  nginx:latest

# Create with environment variables
docker create --name app \
  -e NODE_ENV=production \
  -e DATABASE_URL=postgres://localhost/mydb \
  node:16-alpine
```

#### Container Inspection

```bash
# Detailed container information
docker inspect webserver

# Get specific information using format
docker inspect --format='{{.State.Status}}' webserver
docker inspect --format='{{.NetworkSettings.IPAddress}}' webserver
docker inspect --format='{{range .Mounts}}{{.Source}}:{{.Destination}}{{end}}' webserver

# Container resource usage
docker stats webserver

# Real-time container events
docker events --filter container=webserver
```

#### Container Process Management

```bash
# List processes in container
docker top webserver

# Execute commands in running container
docker exec webserver ls -la /etc

# Interactive shell in container
docker exec -it webserver /bin/bash

# Execute as specific user
docker exec -u root -it webserver /bin/bash

# Execute with environment variables
docker exec -e VAR=value webserver env
```

## Advanced Networking

### Network Types

#### Bridge Networks (Default)

```bash
# Create custom bridge network
docker network create --driver bridge mybridge

# Run container on custom bridge
docker run -d --name web1 --network mybridge nginx
docker run -d --name web2 --network mybridge nginx

# Containers can communicate by name
docker exec web1 ping web2
```

#### Host Networks

```bash
# Use host networking (container shares host network stack)
docker run -d --network host nginx

# No port mapping needed - container uses host ports directly
```

#### None Networks

```bash
# Container with no network access
docker run -d --network none alpine sleep 3600
```

#### Overlay Networks (Multi-host)

```bash
# Create overlay network (requires Docker Swarm)
docker network create --driver overlay --attachable myoverlay

# Run containers on different hosts using same network
docker run -d --name service1 --network myoverlay alpine
```

### Advanced Network Configuration

#### Custom Network with Subnet

```bash
# Create network with custom subnet
docker network create --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  --gateway=172.20.0.1 \
  custom-net

# Run container with static IP
docker run -d --name web \
  --network custom-net \
  --ip 172.20.0.10 \
  nginx
```

#### Network Aliases

```bash
# Create container with network alias
docker run -d --name db \
  --network mynetwork \
  --network-alias database \
  --network-alias mysql-server \
  mysql:8.0

# Other containers can connect using alias
docker run -d --name app \
  --network mynetwork \
  -e DB_HOST=database \
  myapp:latest
```

#### Port Publishing Strategies

```bash
# Publish specific port
docker run -p 8080:80 nginx

# Publish all exposed ports to random host ports
docker run -P nginx

# Publish to specific interface
docker run -p 127.0.0.1:8080:80 nginx

# Publish UDP port
docker run -p 8080:80/udp nginx

# Multiple port mappings
docker run -p 80:80 -p 443:443 -p 8080:8080 nginx
```

## Volume Management and Data Persistence

### Volume Types Comparison

| Type | Use Case | Performance | Portability | Management |
|------|----------|-------------|-------------|------------|
| Named Volumes | Database data, shared data | High | High | Docker managed |
| Bind Mounts | Development, config files | Medium | Low | Host managed |
| tmpfs | Temporary data, secrets | Highest | N/A | Memory only |

### Named Volumes

```bash
# Create volume with driver options
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.1,rw \
  --opt device=:/path/to/dir \
  nfs-volume

# Use volume with specific mount options
docker run -d --name app \
  --mount source=myvolume,target=/data,readonly \
  alpine

# Backup volume data
docker run --rm \
  -v myvolume:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz /data

# Restore volume data
docker run --rm \
  -v myvolume:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /
```

### Bind Mounts Best Practices

```bash
# Read-only bind mount
docker run -d --name web \
  --mount type=bind,source=/host/config,target=/app/config,readonly \
  nginx

# Bind mount with propagation
docker run -d --name app \
  --mount type=bind,source=/host/data,target=/data,bind-propagation=shared \
  alpine

# Bind mount with SELinux labels (Linux)
docker run -d --name app \
  -v /host/data:/data:Z \
  alpine
```

### tmpfs Mounts for Security

```bash
# Mount secrets in memory
docker run -d --name app \
  --tmpfs /app/secrets:noexec,nosuid,size=100m \
  myapp:latest

# Multiple tmpfs mounts
docker run -d --name app \
  --tmpfs /tmp:noexec,nosuid,size=1g \
  --tmpfs /var/cache:noexec,nosuid,size=500m \
  myapp:latest
```

## Container Security

### Running as Non-Root User

```dockerfile
# Dockerfile example
FROM alpine:latest

# Create user and group
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

# Switch to non-root user
USER appuser

# Application files owned by appuser
COPY --chown=appuser:appgroup . /app
WORKDIR /app
```

```bash
# Override user at runtime
docker run -u 1001:1001 myapp:latest

# Run as specific user with home directory
docker run -u $(id -u):$(id -g) -v $HOME:/home/user myapp:latest
```

### Security Options

```bash
# Run with security profiles
docker run --security-opt apparmor=docker-default myapp
docker run --security-opt seccomp=chrome.json myapp

# Disable privileged escalation
docker run --security-opt no-new-privileges myapp

# Drop capabilities
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# Run with read-only root filesystem
docker run --read-only --tmpfs /tmp myapp
```

### Resource Limits and Constraints

```bash
# Memory limits
docker run -m 512m myapp                    # 512 MB limit
docker run --memory=1g myapp                # 1 GB limit
docker run --memory=1g --memory-swap=2g myapp  # 1GB memory + 1GB swap

# CPU limits
docker run --cpus="1.5" myapp               # 1.5 CPU cores
docker run --cpu-shares=512 myapp           # Relative CPU weight
docker run --cpuset-cpus="0,1" myapp        # Specific CPU cores

# I/O limits
docker run --device-read-bps /dev/sda:1mb myapp
docker run --device-write-bps /dev/sda:1mb myapp

# Process limits
docker run --pids-limit=100 myapp           # Max 100 processes

# Ulimits
docker run --ulimit nofile=1024:1024 myapp  # File descriptor limit
```

## Production Deployment Strategies

### Health Checks

```dockerfile
# Dockerfile health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

```bash
# Runtime health check
docker run -d --name web \
  --health-cmd="curl -f http://localhost || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  nginx

# Check health status
docker inspect --format='{{.State.Health.Status}}' web
```

### Restart Policies

```bash
# Always restart unless manually stopped
docker run -d --restart=unless-stopped nginx

# Restart on failure only
docker run -d --restart=on-failure:3 nginx

# Always restart
docker run -d --restart=always nginx

# Update restart policy of running container
docker update --restart=unless-stopped mycontainer
```

### Logging Configuration

```bash
# JSON file logging with rotation
docker run -d --name app \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp

# Syslog logging
docker run -d --name app \
  --log-driver syslog \
  --log-opt syslog-address=tcp://192.168.1.100:514 \
  myapp

# Disable logging
docker run -d --name app --log-driver none myapp

# View logs with timestamps
docker logs -t app

# Follow logs in real-time
docker logs -f app

# View last N lines
docker logs --tail 50 app
```

## Multi-Container Applications

### Docker Compose Production Setup

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - web_data:/var/www/html
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - frontend
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  app:
    image: myapp:latest
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    volumes:
      - app_data:/app/data
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - frontend
      - backend
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'

  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    restart: unless-stopped
    secrets:
      - db_password
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend
    restart: unless-stopped

volumes:
  web_data:
  app_data:
  postgres_data:
  redis_data:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Service Discovery and Load Balancing

```yaml
# docker-compose.yml with load balancer
version: '3.8'

services:
  traefik:
    image: traefik:v2.9
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - traefik

  app:
    image: myapp:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
    deploy:
      replicas: 3
    networks:
      - traefik

networks:
  traefik:
    external: true
```

## Container Monitoring and Debugging

### Resource Monitoring

```bash
# Real-time container stats
docker stats

# Container stats in JSON format
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Export container filesystem as tar
docker export mycontainer > container-backup.tar

# Import container from tar
docker import container-backup.tar myimage:latest
```

### Debugging Techniques

```bash
# Debug network connectivity
docker run --rm --network container:myapp nicolaka/netshoot

# Debug with nsenter (access container namespaces)
docker inspect myapp | grep Pid
sudo nsenter -t PID -n -p

# Copy files from/to container
docker cp myapp:/etc/nginx/nginx.conf ./
docker cp ./new-config.conf myapp:/etc/nginx/

# Create debug container with same environment
docker run -it --rm \
  --network container:myapp \
  --pid container:myapp \
  --volumes-from myapp \
  busybox sh
```

### Log Analysis

```bash
# Search logs for patterns
docker logs myapp 2>&1 | grep ERROR

# Export logs to file
docker logs myapp > app.log 2>&1

# Real-time log filtering
docker logs -f myapp | grep -E "(ERROR|WARN)"

# Log analysis with timestamps
docker logs --since="2024-01-01T00:00:00" --until="2024-01-02T00:00:00" myapp
```

## Performance Optimization

### Image Optimization

```dockerfile
# Multi-stage build for smaller images
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine AS production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```

### Container Performance Tuning

```bash
# Optimize container startup
docker run -d --name app \
  --memory="1g" \
  --cpus="2.0" \
  --oom-kill-disable=false \
  --memory-swappiness=0 \
  myapp:latest

# Use init process for proper signal handling
docker run -d --init myapp:latest

# Optimize I/O performance
docker run -d --name app \
  --storage-opt size=20G \
  --device-read-iops /dev/sda:1000 \
  --device-write-iops /dev/sda:1000 \
  myapp:latest
```

## Backup and Migration

### Container State Backup

```bash
# Create container snapshot
docker commit myapp myapp:backup-$(date +%Y%m%d)

# Export container as tar
docker save myapp:latest > myapp-image.tar

# Import image from tar
docker load < myapp-image.tar

# Backup all volumes
for volume in $(docker volume ls -q); do
  docker run --rm \
    -v $volume:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/$volume.tar.gz /data
done
```

### Container Migration

```bash
# Migration script
#!/bin/bash
CONTAINER_NAME="myapp"
BACKUP_DIR="/backup"

# Create backup
docker commit $CONTAINER_NAME $CONTAINER_NAME:migration
docker save $CONTAINER_NAME:migration > $BACKUP_DIR/$CONTAINER_NAME.tar

# Copy volumes
docker run --rm \
  -v myapp_data:/source \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/myapp_data.tar.gz /source

# On target host
docker load < myapp.tar
docker volume create myapp_data
docker run --rm \
  -v myapp_data:/target \
  -v /backup:/backup \
  alpine tar xzf /backup/myapp_data.tar.gz -C /target --strip 1
```

## Related Topics

- [Container Security](../security/index.md)
- [Container Orchestration](../orchestration/index.md)
- [Infrastructure Monitoring](../../monitoring/index.md)

## Topics

Add topics here.
