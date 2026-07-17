---
title: "Grafana High Availability"
description: "Guide to deploying a highly available Grafana visualization layer with a shared database backend, clustering, and load balancing"
author: "josephstreeter"
ms.author: josephstreeter
ms.topic: architecture
ms.date: 12/30/2025
keywords: ["grafana", "high availability", "clustering", "load balancing", "postgresql", "ha"]
uid: docs.infrastructure.grafana.high-availability
---

## Overview

High Availability (HA) for Grafana keeps the visualization and alerting UI online during failures by running multiple Grafana instances behind a load balancer, all sharing a single SQL database for application state (users, sessions/auth tokens, dashboards). This page covers the Grafana-specific clustering and load balancing configuration.

**Key Components:**

- **Grafana Clustering**: Shared SQL database for application state (users, sessions/auth tokens, dashboards), with an optional `remote_cache` (e.g. Redis) for caching
- **Load Balancing**: Distribute traffic across instances

> [!NOTE]
> The metrics pipeline side of HA — redundant Prometheus instances, Thanos long-term storage, federation, remote storage, and disaster recovery — is documented separately in [Prometheus High Availability](../prometheus/high-availability.md).

## Grafana Clustering

### Database Backend

Grafana requires a shared database for clustering.

> [!IMPORTANT]
> The default SQLite backend **cannot be used for HA** — it is a single-node, file-based database. A multi-instance (clustered) Grafana deployment requires a shared **MySQL** or **PostgreSQL** database so that every instance reads and writes the same application state.

#### PostgreSQL Setup

```yaml
# docker-compose.yml

services:
  postgres:
    image: postgres:16-alpine
    container_name: grafana-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: grafana
      POSTGRES_USER: grafana
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - monitoring
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U grafana"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: grafana-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    networks:
      - monitoring
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  grafana-1:
    image: grafana/grafana:11.2.0
    container_name: grafana-1
    restart: unless-stopped
    environment:
      GF_DATABASE_TYPE: postgres
      GF_DATABASE_HOST: postgres:5432
      GF_DATABASE_NAME: grafana
      GF_DATABASE_USER: grafana
      GF_DATABASE_PASSWORD: ${DB_PASSWORD}
      GF_REMOTE_CACHE_TYPE: redis
      GF_REMOTE_CACHE_CONNSTR: addr=redis:6379,password=${REDIS_PASSWORD},db=0
      GF_SERVER_ROOT_URL: https://grafana.example.com
      GF_SECURITY_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-1-logs:/var/log/grafana
    ports:
      - "3000:3000"
    networks:
      - monitoring
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  grafana-2:
    image: grafana/grafana:11.2.0
    container_name: grafana-2
    restart: unless-stopped
    environment:
      GF_DATABASE_TYPE: postgres
      GF_DATABASE_HOST: postgres:5432
      GF_DATABASE_NAME: grafana
      GF_DATABASE_USER: grafana
      GF_DATABASE_PASSWORD: ${DB_PASSWORD}
      GF_REMOTE_CACHE_TYPE: redis
      GF_REMOTE_CACHE_CONNSTR: addr=redis:6379,password=${REDIS_PASSWORD},db=0
      GF_SERVER_ROOT_URL: https://grafana.example.com
      GF_SECURITY_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-2-logs:/var/log/grafana
    ports:
      - "3001:3000"
    networks:
      - monitoring
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  grafana-3:
    image: grafana/grafana:11.2.0
    container_name: grafana-3
    restart: unless-stopped
    environment:
      GF_DATABASE_TYPE: postgres
      GF_DATABASE_HOST: postgres:5432
      GF_DATABASE_NAME: grafana
      GF_DATABASE_USER: grafana
      GF_DATABASE_PASSWORD: ${DB_PASSWORD}
      GF_REMOTE_CACHE_TYPE: redis
      GF_REMOTE_CACHE_CONNSTR: addr=redis:6379,password=${REDIS_PASSWORD},db=0
      GF_SERVER_ROOT_URL: https://grafana.example.com
      GF_SECURITY_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-3-logs:/var/log/grafana
    ports:
      - "3002:3000"
    networks:
      - monitoring
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

volumes:
  postgres-data:
  redis-data:
  grafana-1-logs:
  grafana-2-logs:
  grafana-3-logs:

networks:
  monitoring:
    driver: bridge
```

### Load Balancing

#### Nginx Configuration

```nginx
# nginx.conf
upstream grafana_backend {
    least_conn;
    server grafana-1:3000 max_fails=3 fail_timeout=30s;
    server grafana-2:3000 max_fails=3 fail_timeout=30s;
    server grafana-3:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name grafana.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name grafana.example.com;

    ssl_certificate /etc/nginx/ssl/grafana.crt;
    ssl_certificate_key /etc/nginx/ssl/grafana.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Health check
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    }

    location /api/live/ {
        proxy_pass http://grafana_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

#### HAProxy Configuration

```conf
# haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 4096
    tune.ssl.default-dh-param 2048

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend grafana_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/grafana.pem
    redirect scheme https if !{ ssl_fc }
    default_backend grafana_backend

backend grafana_backend
    balance leastconn
    option httpchk GET /api/health
    http-check expect status 200
    server grafana-1 grafana-1:3000 check inter 5s fall 3 rise 2
    server grafana-2 grafana-2:3000 check inter 5s fall 3 rise 2
    server grafana-3 grafana-3:3000 check inter 5s fall 3 rise 2

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if LOCALHOST
```

## Metrics Pipeline HA

Grafana is the visualization layer of the monitoring stack. Making the underlying metrics pipeline highly available — running multiple Prometheus replicas, deduplicating with Thanos Query, long-term storage in object storage, hierarchical federation, remote storage backends (Cortex, VictoriaMetrics), and multi-region disaster recovery — is covered in a dedicated page:

- [Prometheus High Availability](../prometheus/high-availability.md)

## Troubleshooting

### Grafana Clustering Issues

```bash
# Check database connectivity
docker logs grafana-1 | grep database

# Verify Redis connection (Redis is used as the optional remote_cache, not for sessions)
redis-cli -h redis -a $REDIS_PASSWORD ping

# Inspect the remote_cache contents (cache entries only).
# NOTE: Grafana >= 9 does NOT store login/auth sessions as Redis "session:*" keys.
# Session/auth tokens live in the shared SQL database (auth_token table); Redis
# here is only the remote_cache for caching, not session storage.
redis-cli -h redis -a $REDIS_PASSWORD keys "*"

# Verify all instances use same database
docker exec grafana-1 grep GF_DATABASE /etc/grafana/grafana.ini
```

## See Also

- [Monitoring Stack Overview](../index.md)
- [Grafana Installation](installation.md)
- [Grafana Configuration](configuration.md)
- [Backup and Recovery](backup-recovery.md)
- [Prometheus High Availability](../prometheus/high-availability.md)
