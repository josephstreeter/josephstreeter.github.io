---
title: "High Availability"
description: "Comprehensive guide to deploying highly available Prometheus and Grafana monitoring infrastructure with Thanos, federation, and clustering"
author: "josephstreeter"
ms.author: "joseph.streeter"
ms.topic: architecture
ms.date: 12/30/2025
keywords: ["prometheus", "grafana", "high availability", "thanos", "federation", "clustering", "ha"]
uid: docs.infrastructure.grafana.high-availability
---

## Overview

High Availability (HA) ensures your monitoring infrastructure remains operational during failures, providing continuous monitoring and alerting capabilities.

**Key Components:**

- **Multiple Prometheus Instances**: Eliminate single points of failure
- **Thanos**: Long-term storage and global query view
- **Grafana Clustering**: Shared database and session storage
- **Load Balancing**: Distribute traffic across instances
- **Federation**: Hierarchical or cross-datacenter aggregation

**HA Architecture Goals:**

- No single point of failure
- Automatic failover
- Data consistency across replicas
- Minimal recovery time (RTO < 5 minutes)
- Minimal data loss (RPO < 1 minute)

## Prometheus HA

### Multiple Prometheus Instances

Deploy identical Prometheus instances scraping the same targets with external labels for deduplication.

```yaml
# prometheus-1.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'main'
    replica: 'prometheus-1'
    region: 'us-east-1'

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets:
        - 'node1:9100'
        - 'node2:9100'
        - 'node3:9100'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - 'alertmanager-1:9093'
          - 'alertmanager-2:9093'
          - 'alertmanager-3:9093'

remote_write:
  - url: 'http://thanos-receive:19291/api/v1/receive'
    queue_config:
      capacity: 10000
      max_shards: 30
      min_shards: 1
      max_samples_per_send: 5000
      batch_send_deadline: 5s
      min_backoff: 30ms
      max_backoff: 5s
```

```yaml
# prometheus-2.yml (identical except replica label)
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'main'
    replica: 'prometheus-2'
    region: 'us-east-1'

# Same scrape_configs and alerting as prometheus-1
```

### Docker Compose HA Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  prometheus-1:
    image: prom/prometheus:v2.49.0
    container_name: prometheus-1
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    volumes:
      - ./prometheus-1.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - prometheus-1-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring

  prometheus-2:
    image: prom/prometheus:v2.49.0
    container_name: prometheus-2
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    volumes:
      - ./prometheus-2.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - prometheus-2-data:/prometheus
    ports:
      - "9091:9090"
    networks:
      - monitoring

  alertmanager-1:
    image: prom/alertmanager:v0.26.0
    container_name: alertmanager-1
    restart: unless-stopped
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-2:9094'
      - '--cluster.peer=alertmanager-3:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-1-data:/alertmanager
    ports:
      - "9093:9093"
    networks:
      - monitoring

  alertmanager-2:
    image: prom/alertmanager:v0.26.0
    container_name: alertmanager-2
    restart: unless-stopped
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-3:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-2-data:/alertmanager
    ports:
      - "9094:9093"
    networks:
      - monitoring

  alertmanager-3:
    image: prom/alertmanager:v0.26.0
    container_name: alertmanager-3
    restart: unless-stopped
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-2:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-3-data:/alertmanager
    ports:
      - "9095:9093"
    networks:
      - monitoring

volumes:
  prometheus-1-data:
  prometheus-2-data:
  alertmanager-1-data:
  alertmanager-2-data:
  alertmanager-3-data:

networks:
  monitoring:
    driver: bridge
```

### Deduplication with Thanos Query

Thanos Query deduplicates metrics from multiple Prometheus replicas.

```bash
# Thanos Query configuration
thanos query \
  --http-address=0.0.0.0:9090 \
  --grpc-address=0.0.0.0:10901 \
  --store=prometheus-1:10901 \
  --store=prometheus-2:10901 \
  --store=thanos-store:10901 \
  --query.replica-label=replica \
  --query.auto-downsampling
```

## Thanos

Thanos provides seamless integration with Prometheus for long-term storage and global query view.

### Thanos Architecture

```mermaid
graph TB
    P1[Prometheus 1] -->|Sidecar| S1[Thanos Sidecar 1]
    P2[Prometheus 2] -->|Sidecar| S2[Thanos Sidecar 2]
    S1 -->|Upload| OBJ[Object Storage]
    S2 -->|Upload| OBJ
    S1 -->|gRPC| Q[Thanos Query]
    S2 -->|gRPC| Q
    STORE[Thanos Store] -->|Read| OBJ
    STORE -->|gRPC| Q
    Q -->|Query| G[Grafana]
    COMP[Thanos Compactor] -->|Compact| OBJ
    RULER[Thanos Ruler] -->|Rules| Q
```

### Thanos Components

#### Thanos Sidecar

Runs alongside Prometheus, uploads blocks to object storage, and serves queries.

```yaml
# docker-compose.yml
services:
  prometheus-1:
    image: prom/prometheus:v2.49.0
    container_name: prometheus-1
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=2d'
      - '--storage.tsdb.min-block-duration=2h'
      - '--storage.tsdb.max-block-duration=2h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-1-data:/prometheus
    networks:
      - monitoring

  thanos-sidecar-1:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-sidecar-1
    command:
      - 'sidecar'
      - '--tsdb.path=/prometheus'
      - '--prometheus.url=http://prometheus-1:9090'
      - '--grpc-address=0.0.0.0:10901'
      - '--http-address=0.0.0.0:10902'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
    volumes:
      - prometheus-1-data:/prometheus:ro
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
    ports:
      - "10902:10902"
    networks:
      - monitoring
    depends_on:
      - prometheus-1
```

#### Thanos Store Gateway

Implements Prometheus' Store API on historical data in object storage.

```yaml
# docker-compose.yml
services:
  thanos-store:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-store
    restart: unless-stopped
    command:
      - 'store'
      - '--data-dir=/var/thanos/store'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--grpc-address=0.0.0.0:10901'
      - '--http-address=0.0.0.0:10902'
      - '--index-cache-size=2GB'
      - '--chunk-pool-size=2GB'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - thanos-store-data:/var/thanos/store
    ports:
      - "10903:10902"
    networks:
      - monitoring

volumes:
  thanos-store-data:
```

#### Thanos Query

Provides a global query view across all Prometheus instances and object storage.

```yaml
# docker-compose.yml
services:
  thanos-query:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-query
    restart: unless-stopped
    command:
      - 'query'
      - '--http-address=0.0.0.0:9090'
      - '--grpc-address=0.0.0.0:10901'
      - '--store=thanos-sidecar-1:10901'
      - '--store=thanos-sidecar-2:10901'
      - '--store=thanos-store:10901'
      - '--query.replica-label=replica'
      - '--query.replica-label=prometheus_replica'
      - '--query.auto-downsampling'
      - '--query.partial-response'
    ports:
      - "9090:9090"
    networks:
      - monitoring
    depends_on:
      - thanos-sidecar-1
      - thanos-store
```

#### Thanos Compactor

Compacts and downsamples data in object storage.

```yaml
# docker-compose.yml
services:
  thanos-compactor:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-compactor
    restart: unless-stopped
    command:
      - 'compact'
      - '--data-dir=/var/thanos/compact'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--http-address=0.0.0.0:10902'
      - '--consistency-delay=30m'
      - '--retention.resolution-raw=30d'
      - '--retention.resolution-5m=90d'
      - '--retention.resolution-1h=365d'
      - '--compact.concurrency=1'
      - '--downsample.concurrency=1'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - thanos-compactor-data:/var/thanos/compact
    ports:
      - "10904:10902"
    networks:
      - monitoring

volumes:
  thanos-compactor-data:
```

#### Thanos Ruler

Evaluates Prometheus recording and alerting rules against Thanos Query.

```yaml
# docker-compose.yml
services:
  thanos-ruler:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-ruler
    restart: unless-stopped
    command:
      - 'rule'
      - '--data-dir=/var/thanos/ruler'
      - '--rule-file=/etc/thanos/rules/*.yml'
      - '--alert.query-url=http://thanos-query:9090'
      - '--alertmanagers.url=http://alertmanager-1:9093'
      - '--alertmanagers.url=http://alertmanager-2:9093'
      - '--query=thanos-query:9090'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--label=ruler_cluster="main"'
      - '--label=ruler_replica="thanos-ruler-1"'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - ./rules:/etc/thanos/rules:ro
      - thanos-ruler-data:/var/thanos/ruler
    ports:
      - "10905:10902"
    networks:
      - monitoring
    depends_on:
      - thanos-query

volumes:
  thanos-ruler-data:
```

### Object Storage Configuration

#### S3 Configuration

```yaml
# thanos-bucket.yml
type: S3
config:
  bucket: "thanos-metrics"
  endpoint: "s3.amazonaws.com"
  region: "us-east-1"
  access_key: "${AWS_ACCESS_KEY_ID}"
  secret_key: "${AWS_SECRET_ACCESS_KEY}"
  insecure: false
  signature_version2: false
  encrypt_sse: true
  put_user_metadata:
    "X-Amz-Storage-Class": "INTELLIGENT_TIERING"
  http_config:
    idle_conn_timeout: 90s
    response_header_timeout: 2m
    insecure_skip_verify: false
  trace:
    enable: true
  part_size: 134217728  # 128MB
```

#### MinIO Configuration

```yaml
# thanos-bucket.yml
type: S3
config:
  bucket: "thanos-metrics"
  endpoint: "minio:9000"
  access_key: "${MINIO_ACCESS_KEY}"
  secret_key: "${MINIO_SECRET_KEY}"
  insecure: true
  signature_version2: false
```

#### GCS Configuration

```yaml
# thanos-bucket.yml
type: GCS
config:
  bucket: "thanos-metrics"
  service_account: |-
    {
      "type": "service_account",
      "project_id": "my-project",
      "private_key_id": "key-id",
      "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
      "client_email": "thanos@my-project.iam.gserviceaccount.com",
      "client_id": "123456789",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token"
    }
```

#### Azure Configuration

```yaml
# thanos-bucket.yml
type: AZURE
config:
  storage_account: "thanosmetrics"
  storage_account_key: "${AZURE_STORAGE_KEY}"
  container: "thanos-metrics"
  endpoint: ""
  max_retries: 3
```

### Complete Thanos Deployment

```yaml
# docker-compose-thanos.yml
version: '3.8'

services:
  prometheus-1:
    image: prom/prometheus:v2.49.0
    container_name: prometheus-1
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=2d'
      - '--storage.tsdb.min-block-duration=2h'
      - '--storage.tsdb.max-block-duration=2h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus-1.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - prometheus-1-data:/prometheus
    networks:
      - monitoring

  thanos-sidecar-1:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-sidecar-1
    restart: unless-stopped
    command:
      - 'sidecar'
      - '--tsdb.path=/prometheus'
      - '--prometheus.url=http://prometheus-1:9090'
      - '--grpc-address=0.0.0.0:10901'
      - '--http-address=0.0.0.0:10902'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
    volumes:
      - prometheus-1-data:/prometheus:ro
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
    depends_on:
      - prometheus-1
    networks:
      - monitoring

  prometheus-2:
    image: prom/prometheus:v2.49.0
    container_name: prometheus-2
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=2d'
      - '--storage.tsdb.min-block-duration=2h'
      - '--storage.tsdb.max-block-duration=2h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus-2.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - prometheus-2-data:/prometheus
    networks:
      - monitoring

  thanos-sidecar-2:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-sidecar-2
    restart: unless-stopped
    command:
      - 'sidecar'
      - '--tsdb.path=/prometheus'
      - '--prometheus.url=http://prometheus-2:9090'
      - '--grpc-address=0.0.0.0:10901'
      - '--http-address=0.0.0.0:10902'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
    volumes:
      - prometheus-2-data:/prometheus:ro
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
    depends_on:
      - prometheus-2
    networks:
      - monitoring

  thanos-query:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-query
    restart: unless-stopped
    command:
      - 'query'
      - '--http-address=0.0.0.0:9090'
      - '--grpc-address=0.0.0.0:10901'
      - '--store=thanos-sidecar-1:10901'
      - '--store=thanos-sidecar-2:10901'
      - '--store=thanos-store:10901'
      - '--query.replica-label=replica'
      - '--query.auto-downsampling'
    ports:
      - "9090:9090"
    depends_on:
      - thanos-sidecar-1
      - thanos-sidecar-2
      - thanos-store
    networks:
      - monitoring

  thanos-store:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-store
    restart: unless-stopped
    command:
      - 'store'
      - '--data-dir=/var/thanos/store'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--grpc-address=0.0.0.0:10901'
      - '--http-address=0.0.0.0:10902'
      - '--index-cache-size=2GB'
      - '--chunk-pool-size=2GB'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - thanos-store-data:/var/thanos/store
    networks:
      - monitoring

  thanos-compactor:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-compactor
    restart: unless-stopped
    command:
      - 'compact'
      - '--data-dir=/var/thanos/compact'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--http-address=0.0.0.0:10902'
      - '--consistency-delay=30m'
      - '--retention.resolution-raw=30d'
      - '--retention.resolution-5m=90d'
      - '--retention.resolution-1h=365d'
      - '--compact.concurrency=1'
      - '--downsample.concurrency=1'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - thanos-compactor-data:/var/thanos/compact
    networks:
      - monitoring

  thanos-ruler:
    image: thanosio/thanos:v0.33.0
    container_name: thanos-ruler
    restart: unless-stopped
    command:
      - 'rule'
      - '--data-dir=/var/thanos/ruler'
      - '--rule-file=/etc/thanos/rules/*.yml'
      - '--alert.query-url=http://thanos-query:9090'
      - '--alertmanagers.url=http://alertmanager:9093'
      - '--query=thanos-query:9090'
      - '--objstore.config-file=/etc/thanos/bucket.yml'
      - '--label=ruler_cluster="main"'
    volumes:
      - ./thanos-bucket.yml:/etc/thanos/bucket.yml:ro
      - ./rules:/etc/thanos/rules:ro
      - thanos-ruler-data:/var/thanos/ruler
    depends_on:
      - thanos-query
    networks:
      - monitoring

  minio:
    image: minio/minio:RELEASE.2024-01-16T16-07-38Z
    container_name: minio
    restart: unless-stopped
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    command: server /data --console-address ":9001"
    volumes:
      - minio-data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      - monitoring

volumes:
  prometheus-1-data:
  prometheus-2-data:
  thanos-store-data:
  thanos-compactor-data:
  thanos-ruler-data:
  minio-data:

networks:
  monitoring:
    driver: bridge
```

## Grafana Clustering

### Database Backend

Grafana requires shared database for clustering.

#### PostgreSQL Setup

```yaml
# docker-compose.yml
version: '3.8'

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
    image: grafana/grafana:10.3.0
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
    image: grafana/grafana:10.3.0
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
    image: grafana/grafana:10.3.0
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

## Federation

### Hierarchical Federation

```yaml
# global-prometheus.yml (aggregation layer)
global:
  scrape_interval: 30s
  evaluation_interval: 30s
  external_labels:
    datacenter: 'global'

scrape_configs:
  # Federate from regional Prometheus instances
  - job_name: 'federate-us-east'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="node_exporter"}'
        - '{job="cadvisor"}'
        - '{__name__=~"job:.*"}'  # Recording rules
        - 'up'
    static_configs:
      - targets:
        - 'prometheus-us-east:9090'

  - job_name: 'federate-us-west'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="node_exporter"}'
        - '{job="cadvisor"}'
        - '{__name__=~"job:.*"}'
        - 'up'
    static_configs:
      - targets:
        - 'prometheus-us-west:9090'

  - job_name: 'federate-eu-central'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="node_exporter"}'
        - '{job="cadvisor"}'
        - '{__name__=~"job:.*"}'
        - 'up'
    static_configs:
      - targets:
        - 'prometheus-eu-central:9090'
```

### Recording Rules for Federation

```yaml
# recording-rules.yml
groups:
  - name: federation_rules
    interval: 30s
    rules:
      # CPU aggregation
      - record: job:node_cpu_utilization:avg
        expr: 100 - (avg by (job, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

      # Memory aggregation
      - record: job:node_memory_utilization:avg
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

      # Disk aggregation
      - record: job:node_disk_utilization:avg
        expr: (1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} / node_filesystem_size_bytes)) * 100

      # Request rate
      - record: job:http_requests:rate5m
        expr: sum by (job, instance) (rate(http_requests_total[5m]))

      # Error rate
      - record: job:http_errors:rate5m
        expr: sum by (job, instance) (rate(http_requests_total{status=~"5.."}[5m]))
```

## Remote Storage

### Cortex Deployment

```yaml
# docker-compose-cortex.yml
version: '3.8'

services:
  cortex:
    image: cortexproject/cortex:v1.16.0
    container_name: cortex
    restart: unless-stopped
    command:
      - '-config.file=/etc/cortex/config.yaml'
      - '-target=all'
    volumes:
      - ./cortex-config.yaml:/etc/cortex/config.yaml:ro
      - cortex-data:/data
    ports:
      - "9009:9009"
    networks:
      - monitoring

volumes:
  cortex-data:

networks:
  monitoring:
    driver: bridge
```

```yaml
# cortex-config.yaml
auth_enabled: false

server:
  http_listen_port: 9009
  grpc_listen_port: 9095

distributor:
  pool:
    health_check_ingesters: true

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1

storage:
  engine: blocks

blocks_storage:
  backend: filesystem
  bucket_store:
    sync_dir: /data/tsdb-sync
  filesystem:
    dir: /data/blocks
  tsdb:
    dir: /data/tsdb

querier:
  query_ingesters_within: 3h

query_range:
  split_queries_by_interval: 24h
  cache_results: true

limits:
  ingestion_rate: 50000
  ingestion_burst_size: 100000
```

### VictoriaMetrics Cluster

```yaml
# docker-compose-vm.yml
version: '3.8'

services:
  vmstorage:
    image: victoriametrics/vmstorage:v1.96.0-cluster
    container_name: vmstorage
    restart: unless-stopped
    command:
      - '--storageDataPath=/storage'
      - '--httpListenAddr=:8482'
      - '--vminsertAddr=:8400'
      - '--vmselectAddr=:8401'
    volumes:
      - vmstorage-data:/storage
    ports:
      - "8482:8482"
      - "8400:8400"
      - "8401:8401"
    networks:
      - monitoring

  vminsert:
    image: victoriametrics/vminsert:v1.96.0-cluster
    container_name: vminsert
    restart: unless-stopped
    command:
      - '--storageNode=vmstorage:8400'
      - '--httpListenAddr=:8480'
    ports:
      - "8480:8480"
    networks:
      - monitoring
    depends_on:
      - vmstorage

  vmselect:
    image: victoriametrics/vmselect:v1.96.0-cluster
    container_name: vmselect
    restart: unless-stopped
    command:
      - '--storageNode=vmstorage:8401'
      - '--httpListenAddr=:8481'
    ports:
      - "8481:8481"
    networks:
      - monitoring
    depends_on:
      - vmstorage

volumes:
  vmstorage-data:

networks:
  monitoring:
    driver: bridge
```

Prometheus remote write configuration:

```yaml
# prometheus.yml
remote_write:
  - url: http://vminsert:8480/insert/0/prometheus/

remote_read:
  - url: http://vmselect:8481/select/0/prometheus/
```

## Disaster Recovery

### Multi-Region Setup

```yaml
# Architecture for multi-region deployment
# Region 1: us-east-1
services:
  prometheus-us-east-1:
    external_labels:
      region: us-east-1
      cluster: main
    remote_write:
      - url: https://thanos-receive-global.example.com/api/v1/receive

# Region 2: us-west-2
services:
  prometheus-us-west-2:
    external_labels:
      region: us-west-2
      cluster: main
    remote_write:
      - url: https://thanos-receive-global.example.com/api/v1/receive

# Region 3: eu-central-1
services:
  prometheus-eu-central-1:
    external_labels:
      region: eu-central-1
      cluster: main
    remote_write:
      - url: https://thanos-receive-global.example.com/api/v1/receive
```

### Failover Procedures

```bash
#!/bin/bash
# Automated failover script

PRIMARY_PROMETHEUS="http://prometheus-1:9090"
SECONDARY_PROMETHEUS="http://prometheus-2:9090"
HEALTH_CHECK_INTERVAL=10

Check_health()
{
    local url=$1
    if curl -sf "${url}/-/healthy" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Monitor primary
while true; do
    if ! Check_health "$PRIMARY_PROMETHEUS"; then
        echo "Primary Prometheus unhealthy, checking secondary..."
        if Check_health "$SECONDARY_PROMETHEUS"; then
            echo "Failing over to secondary..."
            # Update DNS or load balancer
            # Send alert
            curl -X POST https://alertmanager:9093/api/v1/alerts \
                -d '[{"labels":{"alertname":"PrometheusFailover","severity":"critical"},"annotations":{"description":"Failed over to secondary Prometheus"}}]'
        else
            echo "Both instances unhealthy!"
        fi
    fi
    sleep $HEALTH_CHECK_INTERVAL
done
```

### RTO/RPO Targets

| Component | RTO Target | RPO Target | Strategy |
| --- | --- | --- | --- |
| Prometheus | < 5 minutes | < 1 minute | Multiple replicas with external labels |
| Grafana | < 2 minutes | 0 (shared DB) | Clustered with load balancer |
| Alertmanager | < 1 minute | 0 (clustered) | 3-node cluster with gossip |
| Long-term Storage | < 30 minutes | < 15 minutes | Object storage replication |

## Monitoring the HA Stack

```yaml
# ha-monitoring.yml
groups:
  - name: ha_health
    interval: 30s
    rules:
      - alert: PrometheusReplicaDown
        expr: up{job="prometheus"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Prometheus replica {{ $labels.instance }} is down"

      - alert: PrometheusReplicaLagHigh
        expr: (time() - prometheus_tsdb_lowest_timestamp) > 300
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Prometheus replica {{ $labels.instance }} is lagging"

      - alert: ThanosQueryDown
        expr: up{job="thanos-query"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Thanos Query is down"

      - alert: ThanosStoreDown
        expr: up{job="thanos-store"} == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Thanos Store is down"

      - alert: GrafanaDown
        expr: up{job="grafana"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Grafana instance {{ $labels.instance }} is down"

      - alert: AlertmanagerClusterNotHealthy
        expr: sum(up{job="alertmanager"}) < 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alertmanager cluster unhealthy"

      - alert: DatabaseConnectionFailed
        expr: grafana_database_connected == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Grafana cannot connect to database"
```

## Troubleshooting

### Thanos Issues

```bash
# Check Thanos sidecar can access Prometheus
curl http://thanos-sidecar:10902/metrics | grep thanos_sidecar_prometheus

# Verify object storage connectivity
curl http://thanos-sidecar:10902/metrics | grep thanos_objstore

# Check Thanos Query stores
curl http://thanos-query:9090/api/v1/stores | jq

# Verify deduplication
curl 'http://thanos-query:9090/api/v1/query?query=up&dedup=true'
```

### Grafana Clustering Issues

```bash
# Check database connectivity
docker logs grafana-1 | grep database

# Verify Redis connection
redis-cli -h redis -a $REDIS_PASSWORD ping

# Check session storage
redis-cli -h redis -a $REDIS_PASSWORD keys "session:*"

# Verify all instances use same database
docker exec grafana-1 grep GF_DATABASE /etc/grafana/grafana.ini
```

### Federation Issues

```bash
# Test federation endpoint
curl 'http://prometheus:9090/federate?match[]={job="node_exporter"}'

# Check if honor_labels is working
# Should preserve original labels
curl 'http://global-prometheus:9090/api/v1/query?query=up{job="node_exporter"}'
```

## See Also

- [Prometheus Configuration](index.md)
- [Exporters Configuration](exporters.md)
- [Alerting Configuration](alerting.md)
- [Backup and Recovery](backup-recovery.md)
