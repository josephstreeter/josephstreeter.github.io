---
title: "Docker Compose"
description: "Comprehensive guide to Docker Compose for multi-container application orchestration, development environments, and production deployments"
category: "infrastructure"
tags: ["containers", "docker", "orchestration", "multi-container", "development", "deployment", "yaml"]
---

Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services, networks, and volumes. Then, with a single command, you create and start all the services from your configuration.

> [!NOTE]
> Docker Compose is ideal for development, testing, and staging environments, as well as CI/CD workflows and single-host deployments.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
- [Compose File Structure](#compose-file-structure)
- [Services Configuration](#services-configuration)
- [Networks](#networks)
- [Volumes](#volumes)
- [Environment Variables](#environment-variables)
- [Multi-Environment Setup](#multi-environment-setup)
- [Production Considerations](#production-considerations)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security Best Practices](#security-best-practices)
- [Common Patterns](#templates)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Resources](#resources)

## Overview

### Key Features

- **Multi-Container Orchestration**: Define and manage multiple containers as a single application
- **Service Dependencies**: Control startup order and dependencies between services
- **Environment Management**: Easy switching between development, testing, and production configurations
- **Volume Management**: Persistent data storage and sharing between containers
- **Network Isolation**: Create custom networks for service communication
- **Scaling**: Scale services up or down as needed
- **Health Checks**: Monitor container health and restart failed services

### Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Docker Compose Architecture                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │
│  │   Compose File  │───►│   Docker API    │───►│   Containers    │          │
│  │                 │    │                 │    │                 │          │
│  │ • Services      │    │ • Create        │    │ • App Server    │          │
│  │ • Networks      │    │ • Start         │    │ • Database      │          │
│  │ • Volumes       │    │ • Stop          │    │ • Cache         │          │
│  │ • Environment   │    │ • Remove        │    │ • Load Balancer │          │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘          │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        Docker Network                               │    │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐           │    │
│  │  │   Web   │◄──►│   API   │◄──►│Database │    │  Cache  │           │    │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────┘           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Use Cases

- **Development Environments**: Consistent development setup across teams
- **Testing**: Integration testing with all dependencies
- **Microservices**: Orchestrate multiple services together
- **CI/CD Pipelines**: Automated testing and deployment workflows
- **Single-Host Production**: Simple production deployments
- **Local Development**: Replace complex local setups

## Installation

### Docker Desktop (Windows/Mac)

Docker Compose is included with Docker Desktop:

```bash
# Verify installation
docker compose version
```

### Linux Installation

```bash
# Download the latest stable release
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symbolic link (optional)
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

### Using pip (Alternative)

```bash
# Install using pip
pip install docker-compose

# Verify installation
docker-compose --version
```

### Using package managers

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker-compose

# CentOS/RHEL/Fedora
sudo dnf install docker-compose

# Arch Linux
sudo pacman -S docker-compose

# macOS (Homebrew)
brew install docker-compose
```

## Core Concepts

### Services

Services define the containers that make up your application. Each service runs one image and can be scaled to run multiple containers.

### Networks

Networks enable communication between containers. By default, Compose creates a single network for your app.

### Volumes

Volumes provide persistent data storage that survives container restarts and updates.

### Profiles

Profiles allow you to adjust your Compose application for different environments or use cases.

## Compose File Structure

### Basic Structure

```yaml
# docker-compose.yml
version: '3.8'  # Compose file format version

services:
  # Define your services here
  web:
    # Service configuration
    
networks:
  # Define custom networks (optional)
  
volumes:
  # Define named volumes (optional)

secrets:
  # Define secrets (optional)

configs:
  # Define configs (optional)
```

### Version Compatibility

| Compose Version | Docker Engine | Features |
|-----------------|---------------|----------|
| 3.8 | 19.03.0+ | Latest features, init, device_cgroup_rules |
| 3.7 | 18.06.0+ | External networks, secrets |
| 3.6 | 18.02.0+ | tmpfs, init |
| 3.5 | 17.12.0+ | Isolation, scale |
| 3.4 | 17.09.0+ | pid, platform |

> [!TIP]
> Use the latest version (3.8+) for new projects to access all features.

## Services Configuration

### Basic Service Definition

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    restart: unless-stopped
```

### Build Configuration

```yaml
services:
  app:
    build: .  # Build from current directory
    # OR with advanced build options
    build:
      context: ./app
      dockerfile: Dockerfile.dev
      args:
        - NODE_ENV=development
        - API_URL=http://localhost:3000
      target: development
      cache_from:
        - myapp:latest
    image: myapp:dev
```

### Advanced Service Configuration

```yaml
services:
  api:
    image: node:16-alpine
    container_name: my-api
    hostname: api-server
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    # Dependencies
    depends_on:
      - database
      - redis
    
    # Environment variables
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgres://user:pass@database:5432/myapp
    
    # Environment file
    env_file:
      - .env
      - .env.production
    
    # Ports
    ports:
      - "3000:3000"
      - "3001:3001"
    
    # Volumes
    volumes:
      - ./app:/usr/src/app
      - node_modules:/usr/src/app/node_modules
      - logs:/var/log
    
    # Networks
    networks:
      - frontend
      - backend
    
    # Labels
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.localhost`)"
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    
    # Security
    security_opt:
      - no-new-privileges:true
    user: "1001:1001"
    read_only: true
    
    # Restart policy
    restart: unless-stopped
    
    # Command override
    command: npm start
    
    # Working directory
    working_dir: /usr/src/app
    
    # TTY and interactive
    tty: true
    stdin_open: true
```

### Service Dependencies

```yaml
services:
  web:
    image: nginx
    depends_on:
      - api
      - database
  
  api:
    image: node:16
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_started
  
  database:
    image: postgres:13
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
  
  redis:
    image: redis:alpine
```

## Network Configuration

### Default Network

```yaml
# Automatic network creation
services:
  web:
    image: nginx
  api:
    image: node:16
# Both services can communicate using service names
```

### Custom Networks

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

services:
  web:
    image: nginx
    networks:
      - frontend
  
  api:
    image: node:16
    networks:
      - frontend
      - backend
  
  database:
    image: postgres:13
    networks:
      - backend
```

### Advanced Network Configuration

```yaml
networks:
  frontend:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: br-frontend
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
          ip_range: 172.28.240.0/20
          gateway: 172.28.0.1
    labels:
      - "environment=production"
  
  backend:
    driver: bridge
    internal: true  # No external access
  
  external-network:
    external: true
    name: existing-network

services:
  proxy:
    image: nginx
    networks:
      frontend:
        ipv4_address: 172.28.0.10
      external-network:
```

### Network Aliases

```yaml
services:
  api:
    image: node:16
    networks:
      backend:
        aliases:
          - api-server
          - backend-api
  
  worker:
    image: node:16
    networks:
      - backend
    # Can connect to api using 'api', 'api-server', or 'backend-api'
```

## Volume Management

### Named Volumes

```yaml
volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
  
  nfs_data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/path/to/dir"

services:
  database:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  cache:
    image: redis:alpine
    volumes:
      - redis_data:/data
```

### Bind Mounts

```yaml
services:
  web:
    image: nginx
    volumes:
      # Bind mount
      - ./html:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      
      # Short syntax
      - ./logs:/var/log/nginx
      
      # Long syntax
      - type: bind
        source: ./config
        target: /etc/nginx/conf.d
        read_only: true
      
      # Anonymous volume
      - /var/lib/mysql
```

### Volume Configuration Options

```yaml
volumes:
  data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /host/path
    labels:
      - "project=myapp"
      - "environment=production"
  
  external_volume:
    external: true
    name: shared-data

services:
  app:
    image: myapp
    volumes:
      - type: volume
        source: data
        target: /data
        volume:
          nocopy: true
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100M
```

## Environment Variables

### Environment Variable Sources

```yaml
services:
  app:
    image: node:16
    
    # Direct environment variables
    environment:
      NODE_ENV: production
      PORT: 3000
      DEBUG: "app:*"
    
    # Array format
    environment:
      - NODE_ENV=production
      - PORT=3000
    
    # Environment files
    env_file:
      - .env
      - .env.production
      - ./config/app.env
    
    # Interpolate host environment
    environment:
      HOST_USER: ${USER}
      HOST_UID: ${UID:-1000}
      DATABASE_URL: postgres://${DB_USER}:${DB_PASS}@database:5432/${DB_NAME}
```

### Environment File Examples

```bash
# .env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://user:password@localhost:5432/myapp
REDIS_URL=redis://localhost:6379
API_KEY=your-secret-api-key
DEBUG=app:*

# .env.production
NODE_ENV=production
PORT=8080
DATABASE_URL=postgres://produser:prodpass@prod-db:5432/prodapp
REDIS_URL=redis://prod-redis:6379
# API_KEY should be set via secrets in production
```

### Variable Substitution

```yaml
# docker-compose.yml
services:
  app:
    image: ${APP_IMAGE:-node:16}
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      DATABASE_URL: postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}
    volumes:
      - ${HOST_DATA_PATH}:/data
```

```bash
# Set variables in shell or .env file
export APP_IMAGE=myapp:latest
export APP_PORT=8080
export DB_USER=postgres
export DB_PASS=secretpassword
export DB_HOST=database
export DB_PORT=5432
export DB_NAME=myapp
export HOST_DATA_PATH=/opt/myapp/data
```

## Multi-Environment Setup

### Environment-Specific Files

```yaml
# docker-compose.yml (base configuration)
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      NODE_ENV: production
    volumes:
      - ./app:/usr/src/app
    networks:
      - app-network

networks:
  app-network:
```

```yaml
# docker-compose.override.yml (development overrides)
version: '3.8'

services:
  app:
    build: .
    environment:
      NODE_ENV: development
      DEBUG: "app:*"
    volumes:
      - ./app:/usr/src/app
      - node_modules:/usr/src/app/node_modules
    ports:
      - "3000:3000"
    command: npm run dev
  
  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev:/var/lib/postgresql/data

volumes:
  postgres_dev:
  node_modules:
```

```yaml
# docker-compose.prod.yml (production overrides)
version: '3.8'

services:
  app:
    restart: unless-stopped
    environment:
      NODE_ENV: production
    deploy:
      resources:
        limits:
          memory: 1G
    labels:
      - "traefik.enable=true"
  
  database:
    image: postgres:13
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_prod:/var/lib/postgresql/data
    secrets:
      - db_password

secrets:
  db_password:
    external: true

volumes:
  postgres_prod:
    external: true
```

### Running Different Environments

```bash
# Development (uses docker-compose.yml + docker-compose.override.yml)
docker compose up

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing
docker compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit

# Staging
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

### Profiles for Selective Services

```yaml
services:
  app:
    image: myapp
    profiles: ["core"]
  
  database:
    image: postgres:13
    profiles: ["core", "db"]
  
  admin:
    image: myapp-admin
    profiles: ["admin"]
  
  monitoring:
    image: prometheus
    profiles: ["monitoring"]
  
  debug:
    image: myapp-debug
    profiles: ["debug"]
```

```bash
# Run core services only
docker compose --profile core up

# Run with admin interface
docker compose --profile core --profile admin up

# Run everything except monitoring
docker compose --profile core --profile admin --profile debug up

# Run all profiles
docker compose --profile core --profile admin --profile monitoring --profile debug up
```

## Production Considerations

### Production-Ready Configuration

```yaml
version: '3.8'

services:
  app:
    image: myapp:${APP_VERSION}
    restart: unless-stopped
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    
    # Health checks
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    # Security
    security_opt:
      - no-new-privileges:true
    user: "app:app"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=1G
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,version"
    
    # Environment
    environment:
      NODE_ENV: production
    env_file:
      - .env.production
    
    # Secrets
    secrets:
      - db_password
      - api_key
    
    # Networks
    networks:
      - frontend
      - backend
    
    # Labels for service discovery
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"

  database:
    image: postgres:13-alpine
    restart: unless-stopped
    
    # Security
    user: postgres
    
    # Health check
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    
    # Environment
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    
    # Volumes
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    
    # Secrets
    secrets:
      - db_password
    
    # Network
    networks:
      - backend
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    
    volumes:
      - redis_data:/data
    
    networks:
      - backend
    
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    
    ports:
      - "80:80"
      - "443:443"
    
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/ssl:ro
      - nginx_logs:/var/log/nginx
    
    networks:
      - frontend
    
    depends_on:
      - app
    
    labels:
      - "traefik.enable=true"

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  nginx_logs:
    driver: local

secrets:
  db_password:
    external: true
  api_key:
    external: true
```

### Scaling Services

```bash
# Scale specific service
docker compose up -d --scale app=3 --scale worker=5

# Using deploy configuration
```

```yaml
services:
  app:
    image: myapp
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

### Rolling Updates

```bash
# Update single service
docker compose up -d --no-deps app

# Rolling update with health checks
docker compose up -d --wait --wait-timeout 60

# Blue-green deployment pattern
docker compose -f docker-compose.yml -f docker-compose.blue.yml up -d
# Verify blue environment
docker compose -f docker-compose.yml -f docker-compose.green.yml up -d
# Switch traffic to green
```

## Monitoring and Logging

### Centralized Logging

```yaml
services:
  app:
    image: myapp
    logging:
      driver: "fluentd"
      options:
        fluentd-address: "fluentd:24224"
        tag: "docker.myapp"
  
  fluentd:
    image: fluent/fluentd:v1.14-1
    volumes:
      - ./fluentd/fluent.conf:/fluentd/etc/fluent.conf
    ports:
      - "24224:24224"
    networks:
      - logging

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - logging

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    networks:
      - logging

networks:
  logging:

volumes:
  elasticsearch_data:
```

### Monitoring Stack

```yaml
# monitoring-stack.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - ./grafana/provisioning:/etc/grafana/provisioning
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
```

### Health Monitoring

```yaml
services:
  app:
    image: myapp
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
  database:
    image: postgres:13
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    
  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # Health check aggregator
  healthcheck:
    image: alpine
    command: |
      sh -c '
        while true; do
          docker compose ps --services --filter "status=running" | wc -l
          sleep 30
        done
      '
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

## Security Best Practices

### Security Configuration

```yaml
services:
  app:
    image: myapp:latest
    
    # Run as non-root user
    user: "1000:1000"
    
    # Security options
    security_opt:
      - no-new-privileges:true
      - seccomp:unconfined
    
    # Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/cache:noexec,nosuid,size=50m
    
    # Capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    
    # Resource limits
    ulimits:
      nofile:
        soft: 1024
        hard: 2048
      nproc: 512
    
    # Environment
    environment:
      # Don't expose sensitive info in environment
      - LOG_LEVEL=info
    
    # Use secrets for sensitive data
    secrets:
      - db_password
      - api_key
    
    # Labels
    labels:
      - "security.scan=enabled"
      - "compliance.level=high"

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true
    name: production_api_key
```

### Network Security

```yaml
networks:
  # Public-facing network
  public:
    driver: bridge
    
  # Internal application network
  internal:
    driver: bridge
    internal: true
    
  # Database network (most restricted)
  database:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.0.0/24

services:
  nginx:
    image: nginx
    networks:
      - public
      - internal
    ports:
      - "80:80"
      - "443:443"
  
  app:
    image: myapp
    networks:
      - internal
      - database
    # No external ports exposed
  
  database:
    image: postgres:13
    networks:
      - database
    # Only accessible from database network
```

### Secrets Management

```yaml
# Using Docker secrets
services:
  app:
    image: myapp
    secrets:
      - source: db_password
        target: /run/secrets/db_password
        mode: 0400
      - source: api_key
        target: /run/secrets/api_key
        mode: 0400

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true
    name: myapp_api_key
```

```bash
# Create external secret
echo "secret-api-key" | docker secret create myapp_api_key -

# Use with Docker Compose
docker stack deploy -c docker-compose.yml myapp
```

## Common Patterns {#templates}

Docker Compose templates for common application architectures and development scenarios:

### Full-Stack Application

```yaml
version: '3.8'

services:
  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8080
    volumes:
      - ./frontend:/app
      - node_modules_frontend:/app/node_modules
    networks:
      - frontend

  # Backend API
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://user:pass@database:5432/myapp
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./backend:/app
      - node_modules_backend:/app/node_modules
    networks:
      - frontend
      - backend
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_started

  # Database
  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cache
  redis:
    image: redis:alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend

  # Background worker
  worker:
    build: ./backend
    command: npm run worker
    environment:
      - DATABASE_URL=postgres://user:pass@database:5432/myapp
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./backend:/app
      - node_modules_backend:/app/node_modules
    networks:
      - backend
    depends_on:
      - database
      - redis

networks:
  frontend:
  backend:
    internal: true

volumes:
  postgres_data:
  redis_data:
  node_modules_frontend:
  node_modules_backend:
```

### Microservices Architecture

```yaml
version: '3.8'

services:
  # API Gateway
  gateway:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    networks:
      - public
      - services
    depends_on:
      - user-service
      - order-service
      - product-service

  # User Service
  user-service:
    build: ./services/user
    environment:
      - SERVICE_NAME=user-service
      - DATABASE_URL=postgres://user:pass@user-db:5432/users
    networks:
      - services
      - user-db-network
    depends_on:
      - user-db

  user-db:
    image: postgres:13
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - user_db_data:/var/lib/postgresql/data
    networks:
      - user-db-network

  # Order Service
  order-service:
    build: ./services/order
    environment:
      - SERVICE_NAME=order-service
      - DATABASE_URL=postgres://user:pass@order-db:5432/orders
      - USER_SERVICE_URL=http://user-service:3000
    networks:
      - services
      - order-db-network
    depends_on:
      - order-db

  order-db:
    image: postgres:13
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - order_db_data:/var/lib/postgresql/data
    networks:
      - order-db-network

  # Product Service
  product-service:
    build: ./services/product
    environment:
      - SERVICE_NAME=product-service
      - DATABASE_URL=mongo://product-db:27017/products
    networks:
      - services
      - product-db-network
    depends_on:
      - product-db

  product-db:
    image: mongo:5
    volumes:
      - product_db_data:/data/db
    networks:
      - product-db-network

  # Message Queue
  rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin
    ports:
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - services

networks:
  public:
  services:
    internal: true
  user-db-network:
    internal: true
  order-db-network:
    internal: true
  product-db-network:
    internal: true

volumes:
  user_db_data:
  order_db_data:
  product_db_data:
  rabbitmq_data:
```

### Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
      - "9229:9229"  # Node.js debugging port
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    command: npm run dev
    stdin_open: true
    tty: true

  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ./database/seeds:/docker-entrypoint-initdb.d

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  postgres_dev_data:
  node_modules:
```

## Troubleshooting

### Common Issues and Solutions

#### Service Won't Start

```bash
# Check service logs
docker compose logs service-name

# Check all logs
docker compose logs

# Follow logs in real-time
docker compose logs -f service-name

# Check service status
docker compose ps

# Inspect service configuration
docker compose config
```

#### Port Already in Use

```bash
# Find process using port
lsof -i :3000
netstat -tulpn | grep :3000

# Kill process
kill -9 PID

# Use different port in compose file
ports:
  - "3001:3000"
```

#### Volume Permission Issues

```bash
# Check volume permissions
docker compose exec service-name ls -la /path/to/volume

# Fix permissions
docker compose exec service-name chown -R user:group /path/to/volume
```

```yaml
# Set user in compose file
services:
  app:
    image: myapp
    user: "${UID}:${GID}"
    volumes:
      - ./data:/app/data
```

#### Network Connectivity Issues

```bash
# Test network connectivity
docker compose exec service1 ping service2
docker compose exec service1 nslookup service2
docker compose exec service1 nc -zv service2 port

# Inspect networks
docker network ls
docker network inspect network-name

# Check service endpoints
docker compose exec service1 cat /etc/hosts
```

#### Memory/Resource Issues

```bash
# Check resource usage
docker stats

# Monitor specific services
docker compose top

# Set resource limits
```

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

### Debugging Techniques

#### Debug Mode

```bash
# Enable debug mode
export COMPOSE_DEBUG=1
docker compose up

# Verbose output
docker compose --verbose up

# Dry run (validate without executing)
docker compose --dry-run up
```

#### Service Inspection

```bash
# Inspect service
docker compose exec service-name bash

# Check environment variables
docker compose exec service-name env

# Check running processes
docker compose exec service-name ps aux

# Check network configuration
docker compose exec service-name ip addr
docker compose exec service-name netstat -tulpn
```

#### Configuration Validation

```bash
# Validate compose file syntax
docker compose config

# Show resolved configuration
docker compose config --resolve-env-vars

# Validate specific service
docker compose config service-name

# Show services
docker compose config --services

# Show volumes
docker compose config --volumes
```

## Best Practices

### File Organization

```text
project/
├── docker-compose.yml              # Base configuration
├── docker-compose.override.yml     # Development overrides
├── docker-compose.prod.yml         # Production overrides  
├── docker-compose.test.yml         # Testing configuration
├── .env                            # Environment variables
├── .env.example                    # Environment template
├── services/
│   ├── app/
│   │   ├── Dockerfile
│   │   ├── Dockerfile.dev
│   │   └── src/
│   ├── database/
│   │   ├── init.sql
│   │   └── migrations/
│   └── nginx/
│       ├── nginx.conf
│       └── ssl/
├── config/
│   ├── prometheus/
│   ├── grafana/
│   └── fluentd/
├── scripts/
│   ├── deploy.sh
│   ├── backup.sh
│   └── monitor.sh
└── docs/
    ├── README.md
    └── DEPLOYMENT.md
```

### Naming Conventions

```yaml
# Use descriptive service names
services:
  web-frontend:          # Not: web
  api-backend:           # Not: app
  postgres-database:     # Not: db
  redis-cache:          # Not: cache
  nginx-proxy:          # Not: proxy

# Use consistent volume naming
volumes:
  postgres_data:         # service_purpose
  redis_cache_data:
  nginx_logs:

# Use meaningful network names
networks:
  frontend_network:
  backend_network:
  database_network:
```

### Configuration Management

```yaml
# Use environment variables for configuration
services:
  app:
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - PORT=${APP_PORT:-3000}
      - DATABASE_URL=${DATABASE_URL}
    
    # Use labels for metadata
    labels:
      - "com.example.service=api"
      - "com.example.version=${VERSION}"
      - "com.example.environment=${NODE_ENV}"
```

### Performance Optimization

```yaml
services:
  app:
    # Set appropriate restart policy
    restart: unless-stopped
    
    # Configure resource limits
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
    
    # Use health checks
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    # Configure logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### Security Guidelines

1. **Use specific image tags**

   ```yaml
   image: node:16.14.2-alpine  # Not: node:latest
   ```

2. **Run as non-root user**

   ```yaml
   user: "1000:1000"
   ```

3. **Use secrets for sensitive data**

   ```yaml
   secrets:
     - db_password
     - api_key
   ```

4. **Limit network exposure**

   ```yaml
   # Only expose necessary ports
   ports:
     - "80:80"
   # Use internal networks for service communication
   ```

5. **Set security options**

   ```yaml
   security_opt:
     - no-new-privileges:true
   read_only: true
   ```

### Development Workflow

```bash
# Start development environment
docker compose up -d

# View logs
docker compose logs -f app

# Run tests
docker compose exec app npm test

# Access database
docker compose exec database psql -U user -d myapp

# Restart service after code changes
docker compose restart app

# Stop everything
docker compose down

# Clean up (remove volumes)
docker compose down -v
```

### Production Deployment

```bash
# Deploy to production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Update service
docker compose pull app
docker compose up -d --no-deps app

# Monitor health
docker compose ps
docker compose logs --tail=100 app

# Scale services
docker compose up -d --scale app=3 --scale worker=2

# Backup volumes
docker compose exec database pg_dump -U user myapp > backup.sql
```

## Resources

### Official Documentation

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/compose/)

### Learning Resources

- [Docker Compose Tutorial](https://docker-curriculum.com/#docker-compose)
- [Compose Best Practices](https://docs.docker.com/compose/production/)
- [Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/)

### Tools and Extensions

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [VS Code Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
- [Portainer](https://www.portainer.io/)
- [Lazy Docker](https://github.com/jesseduffield/lazydocker)

### Community Resources

- [Awesome Docker Compose](https://github.com/docker/awesome-compose)
- [Docker Hub](https://hub.docker.com/)
- [Docker Community Forums](https://forums.docker.com/)
- [Stack Overflow - Docker Compose](https://stackoverflow.com/questions/tagged/docker-compose)
