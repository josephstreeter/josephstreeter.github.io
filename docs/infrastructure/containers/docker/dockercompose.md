---
title: "Docker Compose"
description: "Complete guide to Docker Compose for multi-container applications"
tags: ["docker", "containers", "orchestration", "devops"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2025-01-20"
---

# Docker Compose

Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services, networks, and volumes. Then, with a single command, you create and start all the services from your configuration.

## What is Docker Compose?

Docker Compose allows you to:

- **Define multi-container applications** in a single YAML file
- **Manage application lifecycle** with simple commands
- **Create isolated environments** for development, testing, and production
- **Scale services** up or down as needed
- **Share configurations** across teams and environments

## Key Concepts

- **Services**: Define how containers should run
- **Networks**: Control how containers communicate
- **Volumes**: Manage persistent data storage
- **Environment Variables**: Configure application settings
- **Dependencies**: Define startup order and relationships

## Basic Docker Compose File Structure

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - frontend

  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - backend

volumes:
  db_data:

networks:
  frontend:
  backend:
```

## Common Commands

### Basic Operations

```bash
# Start services in background
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Development Commands

```bash
# Build services
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Run one-time commands
docker-compose exec web bash

# Scale services
docker-compose up -d --scale web=3
```

## Container Management

> [!TIP]
> Pin images to specific tags in your docker-compose file. This prevents surprise failures due to automatic updates and ensures consistent deployments across environments.

### Update All Containers

The following process safely updates all containers while minimizing downtime:

```bash
# Step 1: Pull latest images
docker-compose pull

# Step 2: Create backup of current state (optional)
docker-compose ps > containers_backup.txt

# Step 3: Update containers with zero-downtime strategy
docker-compose up --force-recreate --build -d

# Step 4: Verify services are running
docker-compose ps

# Step 5: Clean up unused images
docker image prune -f
```

### Safe Update Process with Rollback

```bash
# Create a backup script for safe updates
#!/bin/bash

# Backup current compose file
cp docker-compose.yml docker-compose.yml.backup

# Pull new images
docker-compose pull

# Test configuration
docker-compose config

# Update with health checks
docker-compose up -d --remove-orphans

# Wait for services to be healthy
sleep 30

# Check if all services are running
if docker-compose ps | grep -q "Exit"; then
    echo "Some services failed, rolling back..."
    docker-compose down
    cp docker-compose.yml.backup docker-compose.yml
    docker-compose up -d
    exit 1
fi

echo "Update successful!"
docker image prune -f
```

### Update Single Service

```bash
# Update specific service
docker-compose pull service_name
docker-compose up -d --no-deps service_name

# Force recreate single service
docker-compose up -d --force-recreate service_name
```

## Best Practices

### Security

```yaml
# Use non-root users
services:
  web:
    image: nginx:alpine
    user: "1000:1000"
    
  app:
    build: .
    user: "appuser"
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
```

### Environment Variables

```yaml
# Use .env file for sensitive data
services:
  database:
    image: postgres:13
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Health Checks

```yaml
services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Resource Limits

```yaml
services:
  web:
    image: nginx:alpine
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Example Configurations

### Web Application Stack

```yaml
# Full web application with database and cache
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - web
    networks:
      - frontend

  web:
    build: .
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    networks:
      - frontend
      - backend

  db:
    image: postgres:13-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    secrets:
      - db_password
    networks:
      - backend

  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend

volumes:
  postgres_data:
  redis_data:

networks:
  frontend:
  backend:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Development Environment

```yaml
# Development setup with hot reload
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - CHOKIDAR_USEPOLLING=true
    command: npm run dev

  db:
    image: postgres:13-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    volumes:
      - dev_db_data:/var/lib/postgresql/data

volumes:
  dev_db_data:
```

## Troubleshooting

### Common Issues

```bash
# Check service logs
docker-compose logs service_name

# Inspect service configuration
docker-compose config

# Check resource usage
docker stats $(docker-compose ps -q)

# Debug networking
docker network ls
docker network inspect project_network_name

# Clean up everything
docker-compose down -v --remove-orphans
docker system prune -af
```

### Performance Monitoring

```bash
# Monitor resource usage
docker-compose top

# View real-time logs
docker-compose logs -f

# Check disk usage
docker system df
```

## Migration and Backup

### Backup Strategy

```bash
#!/bin/bash
# backup-compose.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/$DATE"

# Create backup directory
mkdir -p $BACKUP_DIR

# Export volumes
docker-compose exec -T db pg_dump -U user myapp > $BACKUP_DIR/database.sql

# Backup compose files
cp docker-compose.yml $BACKUP_DIR/
cp .env $BACKUP_DIR/ 2>/dev/null || true

# Archive volumes
docker run --rm -v project_db_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/volumes.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"
```

### Restore Process

```bash
#!/bin/bash
# restore-compose.sh

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

# Stop services
docker-compose down

# Restore configuration
cp $BACKUP_DIR/docker-compose.yml .
cp $BACKUP_DIR/.env . 2>/dev/null || true

# Start database
docker-compose up -d db

# Wait for database
sleep 10

# Restore database
docker-compose exec -T db psql -U user myapp < $BACKUP_DIR/database.sql

# Start all services
docker-compose up -d

echo "Restore completed from: $BACKUP_DIR"
```
