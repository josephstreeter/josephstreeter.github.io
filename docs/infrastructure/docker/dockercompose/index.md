---
title: "Docker Compose"
description: "Multi-container application orchestration: service definitions, networks, volumes, environments, and production deployment"
tags: ["containers", "docker", "compose", "orchestration", "multi-container", "yaml"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
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
- [Development Workflow](#development-workflow)
- [Multi-Environment Setup](#multi-environment-setup)
- [Production Considerations](#production-considerations)
- [Backup and Restore](#backup-and-restore)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security Best Practices](#security-best-practices)
- [Templates](#templates)
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

Compose v2 is a CLI plugin, invoked as `docker compose`. It is not a separate `docker-compose`
binary and does not need to be installed independently in most cases.

### Docker Desktop (Windows/Mac)

Included — nothing to install:

```bash
docker compose version
```

### Linux

Install the plugin package from Docker's repository, which is also what
[Installing Docker](../install.md) does:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y docker-compose-plugin

# RHEL/CentOS/Fedora
sudo dnf install -y docker-compose-plugin

# Verify
docker compose version
```

### Manual Install

Only needed when you cannot use Docker's repository:

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p "$DOCKER_CONFIG/cli-plugins"
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"

docker compose version
```

Install to `/usr/local/lib/docker/cli-plugins` instead of `$HOME` to make it available to all
users.

> [!WARNING]
> Do not install Compose v1 — the standalone `docker-compose` binary, or `pip install
> docker-compose`, or the distribution's own `docker-compose` package. v1 reached end of life,
> receives no updates, and does not support the current Compose Specification. Guides
> recommending those methods predate Compose v2.

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
# compose.yaml
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

### File Name

Compose looks for `compose.yaml` first, then falls back to `docker-compose.yml`. Both work;
`compose.yaml` is the name in the current specification and is preferred for new projects.
Override with `-f`:

```bash
docker compose -f custom-name.yaml up -d
```

### The `version` Key Is Obsolete

Older Compose files begin with `version: '3.8'`. That field belonged to the legacy v1 file
formats and is **ignored** by Compose v2, which warns about it:

```text
the attribute `version` is obsolete, it will be ignored,
please remove it to avoid potential confusion
```

Remove it. There is no compatibility benefit to keeping it — Compose v2 implements the
[Compose Specification](https://compose-spec.io/), which is unversioned and feature-detects
instead. Guides presenting a "3.4 / 3.6 / 3.8 feature matrix" describe a format that no longer
governs behavior.

> [!TIP]
> `docker compose config` renders the fully resolved file — the fastest way to see what
> Compose actually parsed, including variable substitution and merged override files.

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

## Development Workflow

Compose v2 added features aimed squarely at the edit-reload loop. They are absent from most
older material, which still reaches for bind mounts and manual `restart` for everything.

### File Watching

`docker compose watch` monitors the project and reacts per-path, rather than mounting the
source tree and hoping the process notices:

```yaml
services:
  web:
    build: .
    develop:
      watch:
        # Copy changed files straight into the running container
        - action: sync
          path: ./src
          target: /app/src
          ignore:
            - node_modules/

        # Dependency manifest changed — rebuild the image
        - action: rebuild
          path: ./package.json

        # Copy, then restart the container
        - action: sync+restart
          path: ./config/nginx.conf
          target: /etc/nginx/nginx.conf
```

```bash
docker compose watch

# Or run the stack and watch together
docker compose up --watch
```

| Action | Behavior |
|--------|----------|
| `sync` | Copy changed files into the container. Fastest; needs an app that hot-reloads. |
| `rebuild` | Rebuild the image and recreate the container. |
| `sync+restart` | Copy, then restart the container — for config a process reads at startup. |
| `sync+exec` | Copy, then run a command in the container (e.g. a migration). |

`sync` avoids the bind-mount performance penalty on Docker Desktop entirely, which is its
main advantage over the traditional approach — see
[I/O Performance](../storage.md#io-performance).

### Composing Files with `include`

`include` pulls in another Compose file as a unit, which beats a sprawl of `-f` flags when
several teams or subsystems each own a file:

```yaml
include:
  - path: ./infra/compose.yaml
  - path: ./services/api/compose.yaml
  - path: ./services/worker/compose.yaml

services:
  gateway:
    image: nginx:alpine
    ports:
      - "80:80"
```

With env-file scoping and project directory control:

```yaml
include:
  - path: ./services/api/compose.yaml
    project_directory: ./services/api
    env_file: ./services/api/.env
```

`include` differs from `-f` overrides in an important way: each included file is resolved
**independently**, with its own relative paths and variables, then merged. Multiple `-f`
files are merged first and resolved once, so relative paths in them are interpreted against
the first file's directory. `include` is what you want for genuinely separate components;
`-f` for layering environment overrides on one application.

### Lifecycle Hooks

`post_start` and `pre_stop` run commands at container transitions — useful for fixing
permissions on a mount, or draining connections before shutdown:

```yaml
services:
  app:
    image: myapp:latest
    volumes:
      - appdata:/var/lib/app
    post_start:
      - command: chown -R app:app /var/lib/app
        user: root
    pre_stop:
      - command: /app/bin/drain --timeout 20s
```

`post_start` hooks run without blocking startup, so do not treat them as an initialization
barrier — use a [health check](#health-monitoring) plus `depends_on: condition:
service_healthy` when ordering actually matters.

## Multi-Environment Setup

### Environment-Specific Files

```yaml
# docker-compose.yml (base configuration)
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

### Updating Running Services

> [!TIP]
> Pin images to specific tags in your Compose file. This prevents surprise failures from automatic updates and keeps deployments consistent across environments.

Update every service in the stack:

```bash
# Pull the latest images
docker compose pull

# Record current state for reference
docker compose ps > containers_backup.txt

# Recreate containers with the new images
docker compose up --force-recreate --build -d

# Verify services are running
docker compose ps

# Reclaim space from superseded images
docker image prune -f
```

Update a single service without disturbing its dependencies:

```bash
docker compose pull service_name
docker compose up -d --no-deps service_name

# Force recreate a single service
docker compose up -d --force-recreate service_name
```

### Safe Update with Automatic Rollback

This wrapper validates the configuration, waits for health, and restores the previous
Compose file if any service exits during the update window.

```bash
#!/bin/bash
set -euo pipefail

# Back up the current compose file
cp docker-compose.yml docker-compose.yml.backup

# Pull new images and validate configuration before touching anything
docker compose pull
docker compose config >/dev/null

# Update, then wait for health checks to settle
docker compose up -d --remove-orphans --wait --wait-timeout 60

# Roll back if any service exited
if docker compose ps --status exited --quiet | grep -q .; then
    echo "Some services failed, rolling back..."
    docker compose down
    mv docker-compose.yml.backup docker-compose.yml
    docker compose up -d
    exit 1
fi

echo "Update successful!"
rm -f docker-compose.yml.backup
docker image prune -f
```

## Backup and Restore

A complete backup captures three things: the database contents, the Compose configuration
that defines the stack, and the named volumes holding persistent data.

### Backup Strategy

```bash
#!/bin/bash
# backup-compose.sh
set -euo pipefail

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/$DATE"
mkdir -p "$BACKUP_DIR"

# Dump the database
docker compose exec -T db pg_dump -U user myapp > "$BACKUP_DIR/database.sql"

# Preserve the configuration that defines the stack
cp docker-compose.yml "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/" 2>/dev/null || true

# Archive named volumes
docker run --rm \
    -v project_db_data:/data:ro \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine tar czf /backup/volumes.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"
```

> [!IMPORTANT]
> Volume names are prefixed with the project name (the directory name by default). Confirm
> the real name with `docker volume ls` before relying on the archive step.

### Restore Process

```bash
#!/bin/bash
# restore-compose.sh
set -euo pipefail

BACKUP_DIR=${1:-}

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

# Stop the stack before replacing configuration
docker compose down

# Restore configuration
cp "$BACKUP_DIR/docker-compose.yml" .
cp "$BACKUP_DIR/.env" . 2>/dev/null || true

# Bring the database up first and wait for it to accept connections
docker compose up -d --wait db

# Restore the dump
docker compose exec -T db psql -U user myapp < "$BACKUP_DIR/database.sql"

# Start the remaining services
docker compose up -d

echo "Restore completed from: $BACKUP_DIR"
```

> [!WARNING]
> Restoring overwrites the live database. Take a fresh backup before running this against
> a production stack.

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

## Templates

Docker Compose templates for common application architectures and development scenarios:

### Full-Stack Application

```yaml
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
