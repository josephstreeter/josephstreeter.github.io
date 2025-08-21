---
title: "ELK Stack"
description: "Comprehensive guide to Elasticsearch, Logstash, and Kibana (ELK Stack) for centralized logging, search, and analytics in containerized environments"
category: "infrastructure"
tags: ["containers", "logging", "elasticsearch", "logstash", "kibana", "elk-stack", "observability", "search"]
---

The ELK Stack is a powerful collection of three open-source tools: Elasticsearch, Logstash, and Kibana. Together, they provide a complete solution for centralized logging, real-time search, and data visualization. The ELK Stack has become the de facto standard for log aggregation and analysis in distributed systems and containerized environments.

## Table of Contents

- [Overview](#overview)
- [Key Components](#key-components)
- [Architecture](#architecture)
- [Installation and Deployment](#installation-and-deployment)
- [Elasticsearch Configuration](#elasticsearch-configuration)
- [Logstash Configuration](#logstash-configuration)
- [Kibana Configuration](#kibana-configuration)
- [Beats Integration](#beats-integration)
- [Data Pipeline](#data-pipeline)
- [Security](#security)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Performance Optimization](#performance-optimization)
- [Container Log Collection](#container-log-collection)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

The ELK Stack provides a comprehensive logging and analytics platform that can handle massive volumes of data from various sources. It's particularly well-suited for containerized environments where applications generate logs that need to be aggregated, searched, and analyzed in real-time.

### Core Capabilities

- **Centralized Logging**: Collect logs from multiple sources into a single location
- **Real-time Search**: Lightning-fast search across massive datasets
- **Data Visualization**: Rich dashboards and visualizations for log analysis
- **Scalability**: Horizontal scaling to handle growing data volumes
- **Flexibility**: Support for structured and unstructured data
- **Integration**: Extensive ecosystem of plugins and integrations

### Evolution to Elastic Stack

The ELK Stack has evolved into the **Elastic Stack**, which includes additional components:

- **Beats**: Lightweight data shippers
- **Elastic APM**: Application Performance Monitoring
- **Machine Learning**: Anomaly detection and forecasting
- **Security**: SIEM and security analytics

### When to Use ELK Stack

ELK Stack is ideal for:

- **Enterprise Logging**: Large-scale log aggregation and analysis
- **Security Analytics**: SIEM and threat detection
- **Business Intelligence**: Metrics and KPI dashboards
- **Application Monitoring**: Performance and error tracking
- **Compliance**: Audit logging and regulatory compliance
- **Full-text Search**: Content search and discovery

## Key Components

### Elasticsearch

**Elasticsearch** is a distributed, RESTful search and analytics engine built on Apache Lucene.

#### Elasticsearch Features

- **Distributed Architecture**: Scales horizontally across multiple nodes
- **RESTful API**: Simple HTTP-based API for all operations
- **Real-time Search**: Near real-time indexing and search capabilities
- **Document-oriented**: Stores data as JSON documents
- **Schema-free**: Dynamic mapping and flexible data structures
- **Aggregations**: Powerful analytics and aggregation capabilities

#### Elasticsearch Use Cases

- Primary data store for logs and metrics
- Full-text search engine
- Analytics and business intelligence
- Geospatial data analysis

### Logstash

**Logstash** is a server-side data processing pipeline that ingests data from multiple sources, transforms it, and sends it to Elasticsearch.

#### Logstash Features

- **Input Plugins**: Support for various data sources (files, databases, message queues)
- **Filter Plugins**: Transform and enrich data during processing
- **Output Plugins**: Send processed data to multiple destinations
- **Codec Support**: Handle different data formats (JSON, CSV, XML, etc.)
- **Pipeline Processing**: Multi-stage data transformation
- **Monitoring**: Built-in monitoring and health checks

#### Logstash Use Cases

- Log parsing and transformation
- Data enrichment and normalization
- ETL (Extract, Transform, Load) operations
- Real-time data processing

### Kibana

**Kibana** is a data visualization and exploration platform designed to work with Elasticsearch.

#### Kibana Features

- **Interactive Dashboards**: Rich, interactive visualizations
- **Data Discovery**: Explore data with intuitive search interfaces
- **Visualization Types**: Charts, graphs, maps, tables, and more
- **Canvas**: Pixel-perfect presentations and infographics
- **Machine Learning UI**: Anomaly detection and forecasting
- **Dev Tools**: Console for Elasticsearch queries and API testing

#### Kibana Use Cases

- Log analysis and visualization
- Real-time operational dashboards
- Business intelligence reporting
- Data exploration and discovery

## Architecture

### Basic ELK Stack Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ELK Stack Architecture                         │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│    Data         │    Logstash     │  Elasticsearch  │       Kibana            │
│   Sources       │                 │                 │                         │
│                 │ • Ingestion     │ • Indexing      │ • Visualization         │
│ • Application   │ • Parsing       │ • Search        │ • Dashboards            │
│   Logs          │ • Filtering     │ • Storage       │ • Analysis              │
│ • System Logs   │ • Enhancement   │ • Analytics     │ • User Interface        │
│ • Web Servers   │ • Routing       │ • Clustering    │                         │
│ • Databases     │                 │                 │                         │
│ • Containers    │                 │                 │                         │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────┘
         │                 │                 │                       │
         └─────────────────►│                 │                       │
                           └─────────────────►│                       │
                                             └───────────────────────►│
```

### Distributed Architecture with Beats

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Elastic Stack with Beats                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Beats     │    │  Logstash   │    │Elasticsearch│    │   Kibana    │  │
│  │             │    │             │    │   Cluster   │    │             │  │
│  │ • Filebeat  │───►│ • Input     │───►│             │───►│ • Discover  │  │
│  │ • Metricbeat│    │ • Filter    │    │ • Master    │    │ • Visualize │  │
│  │ • Packetbeat│    │ • Output    │    │ • Data      │    │ • Dashboard │  │
│  │ • Heartbeat │    │             │    │ • Ingest    │    │ • Alerting  │  │
│  │ • Auditbeat │    │             │    │             │    │             │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### High Availability Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Production ELK Stack Architecture                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐  │
│  │Load Balancer│    │  Logstash       │    │   Elasticsearch Cluster     │  │
│  │             │    │   Cluster       │    │                             │  │
│  │   HAProxy   │───►│                 │───►│  ┌───────┐ ┌───────┐ ┌────┐ │  │
│  │   Nginx     │    │ • Logstash-1    │    │  │Master │ │Master │ │Data│ │  │
│  │             │    │ • Logstash-2    │    │  │Node-1 │ │Node-2 │ │Node│ │  │
│  └─────────────┘    │ • Logstash-3    │    │  └───────┘ └───────┘ └────┘ │  │
│                     │                 │    │                             │  │
│                     └─────────────────┘    │  ┌───────┐ ┌───────┐ ┌────┐ │  │
│                                            │  │Master │ │Data   │ │Data│ │  │
│  ┌─────────────┐                          │  │Node-3 │ │Node-1 │ │Node│ │  │
│  │   Kibana    │◄─────────────────────────│  └───────┘ └───────┘ └────┘ │  │
│  │   Cluster   │                          │                             │  │
│  │             │                          └─────────────────────────────┘  │
│  │ • Kibana-1  │                                                            │
│  │ • Kibana-2  │                                                            │
│  └─────────────┘                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Data Collection**: Beats or applications send logs to Logstash
2. **Processing**: Logstash parses, filters, and transforms the data
3. **Indexing**: Processed data is indexed in Elasticsearch
4. **Storage**: Data is stored across Elasticsearch cluster nodes
5. **Querying**: Kibana queries Elasticsearch for data visualization
6. **Visualization**: Users interact with data through Kibana dashboards

## Installation and Deployment

### Docker Compose Deployment

Complete ELK Stack with Docker Compose:

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - node.name=elasticsearch
      - cluster.name=elk-cluster
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
      - xpack.security.enrollment.enabled=false
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - elk
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: logstash
    volumes:
      - ./logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
    ports:
      - "5044:5044"
      - "9600:9600"
    environment:
      - "LS_JAVA_OPTS=-Xms1g -Xmx1g"
    networks:
      - elk
    depends_on:
      - elasticsearch
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9600 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - SERVER_NAME=kibana
      - SERVER_HOST=0.0.0.0
    volumes:
      - ./kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
    networks:
      - elk
    depends_on:
      - elasticsearch
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    container_name: filebeat
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log:/var/log:ro
      - filebeat-data:/usr/share/filebeat/data
    environment:
      - output.elasticsearch.hosts=["elasticsearch:9200"]
    networks:
      - elk
    depends_on:
      - elasticsearch
      - logstash
    restart: unless-stopped

  metricbeat:
    image: docker.elastic.co/beats/metricbeat:8.11.0
    container_name: metricbeat
    user: root
    volumes:
      - ./metricbeat/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro
      - /proc:/hostfs/proc:ro
      - /:/hostfs:ro
      - metricbeat-data:/usr/share/metricbeat/data
    environment:
      - output.elasticsearch.hosts=["elasticsearch:9200"]
    networks:
      - elk
    depends_on:
      - elasticsearch
    restart: unless-stopped

volumes:
  elasticsearch-data:
  filebeat-data:
  metricbeat-data:

networks:
  elk:
    driver: bridge
```

### Kubernetes Deployment

#### Elasticsearch StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: elk
spec:
  serviceName: "elasticsearch"
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: transport
        env:
        - name: node.name
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: cluster.name
          value: "elk-cluster"
        - name: cluster.initial_master_nodes
          value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
        - name: discovery.seed_hosts
          value: "elasticsearch-0.elasticsearch,elasticsearch-1.elasticsearch,elasticsearch-2.elasticsearch"
        - name: ES_JAVA_OPTS
          value: "-Xms2g -Xmx2g"
        - name: xpack.security.enabled
          value: "false"
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /_cluster/health
            port: 9200
          initialDelaySeconds: 30
          timeoutSeconds: 5
        livenessProbe:
          httpGet:
            path: /_cluster/health
            port: 9200
          initialDelaySeconds: 60
          timeoutSeconds: 5
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "fast-ssd"
      resources:
        requests:
          storage: 100Gi
```

#### Logstash Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: elk
spec:
  replicas: 2
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
      - name: logstash
        image: docker.elastic.co/logstash/logstash:8.11.0
        ports:
        - containerPort: 5044
          name: beats
        - containerPort: 9600
          name: http
        env:
        - name: LS_JAVA_OPTS
          value: "-Xms1g -Xmx1g"
        volumeMounts:
        - name: logstash-config
          mountPath: /usr/share/logstash/config
        - name: logstash-pipeline
          mountPath: /usr/share/logstash/pipeline
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /
            port: 9600
          initialDelaySeconds: 30
          timeoutSeconds: 5
      volumes:
      - name: logstash-config
        configMap:
          name: logstash-config
      - name: logstash-pipeline
        configMap:
          name: logstash-pipeline
```

#### Kibana Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: elk
spec:
  replicas: 2
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.11.0
        ports:
        - containerPort: 5601
          name: http
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        - name: SERVER_HOST
          value: "0.0.0.0"
        volumeMounts:
        - name: kibana-config
          mountPath: /usr/share/kibana/config
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /api/status
            port: 5601
          initialDelaySeconds: 30
          timeoutSeconds: 5
      volumes:
      - name: kibana-config
        configMap:
          name: kibana-config
```

### Helm Installation

```bash
# Add Elastic Helm repository
helm repo add elastic https://helm.elastic.co
helm repo update

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace elk \
  --create-namespace \
  --set replicas=3 \
  --set volumeClaimTemplate.resources.requests.storage=100Gi \
  --set esJavaOpts="-Xms2g -Xmx2g"

# Install Logstash
helm install logstash elastic/logstash \
  --namespace elk \
  --set replicas=2 \
  --set logstashJavaOpts="-Xms1g -Xmx1g"

# Install Kibana
helm install kibana elastic/kibana \
  --namespace elk \
  --set replicas=2 \
  --set service.type=LoadBalancer

# Install Filebeat
helm install filebeat elastic/filebeat \
  --namespace elk
```

## Elasticsearch Configuration

### Elasticsearch Basic Configuration

Create `elasticsearch.yml`:

```yaml
# Cluster
cluster.name: elk-cluster
node.name: ${HOSTNAME}

# Network
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery
discovery.type: single-node  # For single node
# discovery.seed_hosts: ["elasticsearch-1", "elasticsearch-2", "elasticsearch-3"]
# cluster.initial_master_nodes: ["elasticsearch-1", "elasticsearch-2", "elasticsearch-3"]

# Path settings
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs

# Memory
bootstrap.memory_lock: true

# Security (disable for basic setup)
xpack.security.enabled: false
xpack.security.enrollment.enabled: false

# Monitoring
xpack.monitoring.collection.enabled: true
```

### Elasticsearch Production Configuration

```yaml
# Cluster configuration
cluster.name: production-elk-cluster
node.name: ${HOSTNAME}
node.roles: ["master", "data", "ingest"]

# Network
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery for multi-node cluster
discovery.seed_hosts: 
  - elasticsearch-1.example.com
  - elasticsearch-2.example.com  
  - elasticsearch-3.example.com
cluster.initial_master_nodes:
  - elasticsearch-1
  - elasticsearch-2
  - elasticsearch-3

# Memory and JVM
bootstrap.memory_lock: true
indices.memory.index_buffer_size: 20%

# Thread pools
thread_pool:
  write:
    size: 8
    queue_size: 1000
  search:
    size: 13
    queue_size: 1000

# Index settings
action.auto_create_index: true
action.destructive_requires_name: true

# Cluster settings
cluster.routing.allocation.disk.threshold.enabled: true
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%
cluster.routing.allocation.disk.watermark.flood_stage: 95%

# Security
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/certs/elastic-certificates.p12

# Monitoring
xpack.monitoring.collection.enabled: true
xpack.monitoring.elasticsearch.collection.enabled: false
```

### Index Templates

```json
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "refresh_interval": "10s",
      "index.lifecycle.name": "logs-policy",
      "index.lifecycle.rollover_alias": "logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "level": {
          "type": "keyword"
        },
        "service": {
          "type": "keyword"
        },
        "message": {
          "type": "text",
          "analyzer": "standard"
        },
        "host": {
          "properties": {
            "name": {"type": "keyword"},
            "ip": {"type": "ip"}
          }
        }
      }
    }
  },
  "version": 1,
  "_meta": {
    "description": "Template for application logs"
  }
}
```

## Logstash Configuration

### Basic Pipeline Configuration

Create `logstash.yml`:

```yaml
# Node
node.name: logstash

# Path settings  
path.data: /usr/share/logstash/data
path.logs: /usr/share/logstash/logs
path.settings: /usr/share/logstash/config
path.config: /usr/share/logstash/pipeline

# Pipeline settings
pipeline.workers: 4
pipeline.batch.size: 1000
pipeline.batch.delay: 50

# Queue settings
queue.type: persisted
queue.max_bytes: 1gb
queue.checkpoint.writes: 1024

# HTTP API
http.host: "0.0.0.0"
http.port: 9600

# Log level
log.level: info

# Monitoring
xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch.hosts: ["http://elasticsearch:9200"]
```

### Input, Filter, Output Pipeline

Create pipeline configuration (`/usr/share/logstash/pipeline/logstash.conf`):

```ruby
input {
  # Beats input
  beats {
    port => 5044
    host => "0.0.0.0"
  }
  
  # Syslog input
  syslog {
    port => 514
    type => "syslog"
  }
  
  # File input
  file {
    path => "/var/log/*.log"
    start_position => "beginning"
    type => "system"
  }
  
  # HTTP input for webhook data
  http {
    port => 8080
    type => "webhook"
  }
  
  # TCP input for application logs
  tcp {
    port => 5000
    type => "tcp"
  }
}

filter {
  # Parse different log types
  if [fields][logtype] == "nginx" {
    grok {
      match => { 
        "message" => "%{COMBINEDAPACHELOG}" 
      }
      tag_on_failure => ["_grokparsefailure_nginx"]
    }
    
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
    
    mutate {
      convert => { "response" => "integer" }
      convert => { "bytes" => "integer" }
      remove_field => [ "timestamp" ]
    }
  }
  
  # Parse JSON logs
  if [fields][logtype] == "json" {
    json {
      source => "message"
      tag_on_failure => ["_jsonparsefailure"]
    }
  }
  
  # Parse application logs
  if [fields][service] == "webapp" {
    grok {
      match => { 
        "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} \[%{DATA:thread}\] %{DATA:logger} - %{GREEDYDATA:log_message}" 
      }
      tag_on_failure => ["_grokparsefailure_webapp"]
    }
    
    date {
      match => [ "timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
    }
    
    mutate {
      remove_field => [ "timestamp" ]
    }
  }
  
  # Add common fields
  mutate {
    add_field => { 
      "processed_at" => "%{@timestamp}"
      "logstash_host" => "%{host}"
    }
  }
  
  # GeoIP enrichment
  if [clientip] {
    geoip {
      source => "clientip"
      target => "geoip"
    }
  }
  
  # User agent parsing
  if [agent] {
    useragent {
      source => "agent"
      target => "user_agent"
    }
  }
  
  # DNS lookup
  if [clientip] {
    dns {
      reverse => [ "clientip" ]
      action => "replace"
      hit_cache_size => 4096
      hit_cache_ttl => 900
      failed_cache_size => 512  
      failed_cache_ttl => 60
    }
  }
}

output {
  # Output to Elasticsearch
  if [fields][logtype] == "nginx" {
    elasticsearch {
      hosts => ["http://elasticsearch:9200"]
      index => "nginx-logs-%{+YYYY.MM.dd}"
      template_name => "nginx"
      template_overwrite => true
    }
  } else if [fields][service] == "webapp" {
    elasticsearch {
      hosts => ["http://elasticsearch:9200"]
      index => "webapp-logs-%{+YYYY.MM.dd}"
    }
  } else {
    elasticsearch {
      hosts => ["http://elasticsearch:9200"]
      index => "logstash-%{+YYYY.MM.dd}"
    }
  }
  
  # Debug output to stdout
  if [tags] and "_grokparsefailure" in [tags] {
    stdout { 
      codec => rubydebug 
    }
  }
}
```

### Advanced Pipeline Configuration

```ruby
input {
  beats {
    port => 5044
    host => "0.0.0.0"
    ssl => true
    ssl_certificate_authorities => ["/usr/share/logstash/config/certs/ca.crt"]
    ssl_certificate => "/usr/share/logstash/config/certs/logstash.crt"
    ssl_key => "/usr/share/logstash/config/certs/logstash.key"
  }
  
  kafka {
    bootstrap_servers => "kafka1:9092,kafka2:9092,kafka3:9092"
    topics => ["logs", "metrics", "traces"]
    codec => json
    group_id => "logstash_consumers"
  }
}

filter {
  # Pipeline branching
  if [service] == "payment" {
    # Sensitive data masking
    mutate {
      gsub => [
        "message", "\d{4}-\d{4}-\d{4}-\d{4}", "****-****-****-****",
        "message", "\b\d{3}-\d{2}-\d{4}\b", "***-**-****"
      ]
    }
  }
  
  # Error detection and alerting
  if [level] == "ERROR" or [level] == "FATAL" {
    mutate {
      add_tag => ["error", "alert"]
      add_field => { 
        "alert_severity" => "high" 
      }
    }
  }
  
  # Performance monitoring
  if [response_time] {
    if [response_time] > 5000 {
      mutate {
        add_tag => ["slow_response"]
        add_field => { 
          "performance_issue" => "slow_response" 
        }
      }
    }
  }
  
  # Data enrichment from external sources
  jdbc_lookup {
    id => "user_lookup"
    statement => "SELECT name, department FROM users WHERE id = ?"
    parameters => ["%{user_id}"]
    target => "user_details"
    default_hash => {}
  }
}

output {
  # Multiple outputs with conditions
  if "error" in [tags] {
    # Send errors to dedicated index
    elasticsearch {
      hosts => ["http://elasticsearch:9200"]
      index => "errors-%{+YYYY.MM.dd}"
    }
    
    # Send alerts to external system
    http {
      url => "https://alertmanager.example.com/api/v1/alerts"
      http_method => "post"
      format => "json"
      mapping => {
        "labels" => {
          "service" => "%{service}"
          "severity" => "critical"
        }
        "annotations" => {
          "summary" => "%{message}"
        }
      }
    }
  }
  
  # Dead letter queue for failed documents
  if "_elasticsearch_output_failure" in [tags] {
    file {
      path => "/var/log/logstash/failed_documents.log"
      codec => json_lines
    }
  }
}
```

## Kibana Configuration

### Kibana Basic Configuration

Create `kibana.yml`:

```yaml
# Server
server.host: "0.0.0.0"
server.port: 5601
server.name: "kibana"

# Elasticsearch
elasticsearch.hosts: ["http://elasticsearch:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "changeme"

# Logging
logging.appenders.file.type: file
logging.appenders.file.fileName: /usr/share/kibana/logs/kibana.log
logging.appenders.file.layout.type: json

logging.root.level: info
logging.root.appenders: [default, file]

# Monitoring
monitoring.ui.container.elasticsearch.enabled: true
xpack.monitoring.enabled: true

# Security
xpack.security.enabled: false
xpack.encryptedSavedObjects.encryptionKey: "something_at_least_32_characters"
```

### Kibana Production Configuration

```yaml
# Server configuration
server.host: "0.0.0.0"
server.port: 5601
server.name: "kibana-prod"
server.basePath: "/kibana"
server.rewriteBasePath: true

# Elasticsearch configuration
elasticsearch.hosts: 
  - "https://elasticsearch-1:9200"
  - "https://elasticsearch-2:9200"
  - "https://elasticsearch-3:9200"
elasticsearch.username: "kibana_system"
elasticsearch.password: "${ELASTICSEARCH_PASSWORD}"
elasticsearch.ssl.certificateAuthorities: ["/usr/share/kibana/config/certs/ca.crt"]
elasticsearch.ssl.verificationMode: certificate

# Security
xpack.security.enabled: true
xpack.security.encryptionKey: "${ENCRYPTION_KEY}"
xpack.security.session.idleTimeout: "1h"
xpack.security.session.lifespan: "30d"

# Authentication
xpack.security.authc.providers:
  basic.basic1:
    order: 0
    enabled: true
  saml.saml1:
    order: 1
    realm: "saml_realm"

# Alerting
xpack.alerting.enabled: true
xpack.actions.enabled: true

# Monitoring
monitoring.ui.container.elasticsearch.enabled: true
monitoring.ui.container.logstash.enabled: true
monitoring.kibana.collection.enabled: true

# Performance
elasticsearch.requestTimeout: 30000
elasticsearch.shardTimeout: 30000

# Logging
logging.appenders.file.type: file
logging.appenders.file.fileName: /usr/share/kibana/logs/kibana.log
logging.appenders.file.layout.type: json

logging.root.level: info
logging.root.appenders: [default, file]

# Advanced settings
map.includeElasticMapsService: true
telemetry.enabled: true
newsfeed.enabled: true
```

### Index Patterns and Visualizations

Create index patterns via API:

```bash
# Create index pattern
curl -X POST "kibana:5601/api/saved_objects/index-pattern" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "logs-*",
      "timeFieldName": "@timestamp"
    }
  }'

# Import dashboard
curl -X POST "kibana:5601/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -F "file=@dashboard.ndjson"
```

## Beats Integration

### Filebeat Configuration

```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/app/*.log
  fields:
    logtype: system
    service: webapp
  fields_under_root: true
  multiline.pattern: '^\d{4}-\d{2}-\d{2}'
  multiline.negate: true
  multiline.match: after

- type: container
  enabled: true
  paths:
    - /var/lib/docker/containers/*/*.log
  processors:
  - add_docker_metadata:
      host: "unix:///var/run/docker.sock"

- type: syslog
  enabled: true
  protocol.tcp:
    host: "0.0.0.0:514"

processors:
- add_host_metadata:
    when.not.contains.tags: forwarded

- drop_fields:
    fields: ["agent", "ecs", "host.architecture", "host.os"]

output.logstash:
  hosts: ["logstash:5044"]
  ssl.certificate_authorities: ["/usr/share/filebeat/certs/ca.crt"]

# Alternative: Output directly to Elasticsearch
# output.elasticsearch:
#   hosts: ["elasticsearch:9200"]
#   index: "filebeat-%{+yyyy.MM.dd}"

monitoring.enabled: true
monitoring.elasticsearch:
  hosts: ["elasticsearch:9200"]

logging.level: info
logging.to_files: true
logging.files:
  path: /usr/share/filebeat/logs
  name: filebeat
  keepfiles: 7
  permissions: 0600
```

### Metricbeat Configuration

```yaml
# metricbeat.yml
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

metricbeat.modules:
- module: system
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    - socket_summary
    - filesystem
    - fsstat
    - diskio
  enabled: true
  period: 10s

- module: docker
  metricsets:
    - container
    - cpu
    - diskio
    - healthcheck
    - info
    - memory
    - network
  hosts: ["unix:///var/run/docker.sock"]
  period: 10s
  enabled: true

- module: elasticsearch
  metricsets:
    - node
    - node_stats
    - cluster_stats
  period: 10s
  hosts: ["http://elasticsearch:9200"]
  enabled: true

- module: logstash
  metricsets:
    - node
    - node_stats
  period: 10s
  hosts: ["http://logstash:9600"]
  enabled: true

- module: kibana
  metricsets:
    - status
  period: 10s
  hosts: ["http://kibana:5601"]
  enabled: true

processors:
- add_host_metadata: ~
- add_docker_metadata: ~

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "metricbeat-%{+yyyy.MM.dd}"

monitoring.enabled: true

setup.template.enabled: true
setup.template.name: "metricbeat"
setup.template.pattern: "metricbeat-*"

logging.level: info
```

## Data Pipeline

### Index Lifecycle Management (ILM)

```json
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0,
            "include": {
              "box_type": "warm"
            }
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0,
            "include": {
              "box_type": "cold"
            }
          },
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Ingest Pipelines

```json
{
  "description": "Parse nginx access logs",
  "processors": [
    {
      "grok": {
        "field": "message",
        "patterns": [
          "%{COMBINEDAPACHELOG}"
        ]
      }
    },
    {
      "date": {
        "field": "timestamp",
        "formats": [
          "dd/MMM/yyyy:HH:mm:ss Z"
        ]
      }
    },
    {
      "convert": {
        "field": "response",
        "type": "integer"
      }
    },
    {
      "convert": {
        "field": "bytes",
        "type": "integer"
      }
    },
    {
      "geoip": {
        "field": "clientip",
        "target_field": "geoip"
      }
    },
    {
      "user_agent": {
        "field": "agent",
        "target_field": "user_agent"
      }
    },
    {
      "remove": {
        "field": ["timestamp", "agent", "message"]
      }
    }
  ]
}
```

## Security

### Authentication and Authorization

```yaml
# Enable X-Pack security
xpack.security.enabled: true

# Built-in users
elasticsearch.username: "elastic"
elasticsearch.password: "changeme"

# File-based realm
xpack.security.authc.realms.file.file1:
  order: 0

# LDAP realm
xpack.security.authc.realms.ldap.ldap1:
  order: 1
  url: "ldaps://ldap.example.com:636"
  bind_dn: "cn=ldapuser, ou=users, o=services, dc=example, dc=com"
  bind_password: "changeme"
  user_search:
    base_dn: "dc=example,dc=com"
    filter: "(cn={0})"
  group_search:
    base_dn: "dc=example,dc=com"
    filter: "(memberOf={0})"
```

### TLS/SSL Configuration

```yaml
# Elasticsearch TLS
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12

xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.http.ssl.truststore.path: certs/elastic-certificates.p12

# Kibana TLS
server.ssl.enabled: true
server.ssl.certificate: /usr/share/kibana/config/certs/kibana.crt
server.ssl.key: /usr/share/kibana/config/certs/kibana.key

elasticsearch.ssl.certificateAuthorities: ["/usr/share/kibana/config/certs/ca.crt"]
elasticsearch.ssl.verificationMode: certificate
```

### Role-Based Access Control

```json
{
  "admin_role": {
    "cluster": ["all"],
    "indices": [
      {
        "names": ["*"],
        "privileges": ["all"]
      }
    ]
  },
  "read_only_role": {
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["logs-*"],
        "privileges": ["read", "view_index_metadata"]
      }
    ]
  },
  "developer_role": {
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["app-*", "debug-*"],
        "privileges": ["read", "write", "create_index", "delete_index"]
      }
    ]
  }
}
```

## Monitoring and Alerting

### Cluster Monitoring

```yaml
# Enable monitoring
xpack.monitoring.enabled: true
xpack.monitoring.collection.enabled: true

# Monitoring settings
xpack.monitoring.collection.interval: 10s
xpack.monitoring.elasticsearch.collection.enabled: false
```

### Watcher Alerts

```json
{
  "trigger": {
    "schedule": {
      "interval": "1m"
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {"range": {"@timestamp": {"gte": "now-5m"}}},
                {"term": {"level": "ERROR"}}
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {
        "gt": 10
      }
    }
  },
  "actions": {
    "send_email": {
      "email": {
        "to": ["admin@example.com"],
        "subject": "High Error Rate Alert",
        "body": "More than 10 errors in the last 5 minutes"
      }
    },
    "webhook": {
      "webhook": {
        "scheme": "https",
        "host": "hooks.slack.com",
        "port": 443,
        "method": "post",
        "path": "/services/YOUR/SLACK/WEBHOOK",
        "body": "{\"text\": \"High error rate detected: {{ctx.payload.hits.total}} errors\"}"
      }
    }
  }
}
```

## Performance Optimization

### Elasticsearch Tuning

```yaml
# JVM heap size (50% of available RAM, max 32GB)
ES_JAVA_OPTS: "-Xms16g -Xmx16g"

# Index settings for performance
index:
  refresh_interval: "30s"
  number_of_shards: 2
  number_of_replicas: 1
  translog:
    flush_threshold_size: "512mb"
    sync_interval: "30s"

# Query settings
indices.queries.cache.size: "20%"
indices.requests.cache.size: "2%"
indices.fielddata.cache.size: "20%"

# Thread pools
thread_pool:
  write:
    size: 8
    queue_size: 1000
  search:
    size: 13
    queue_size: 1000
  get:
    size: 8
    queue_size: 1000
```

### Logstash Optimization

```yaml
# Pipeline workers (number of CPU cores)
pipeline.workers: 8

# Batch settings
pipeline.batch.size: 5000
pipeline.batch.delay: 50

# Memory settings
LS_JAVA_OPTS: "-Xms8g -Xmx8g"

# Queue settings
queue.type: persisted
queue.max_bytes: 8gb
queue.checkpoint.writes: 1024
```

### Index Optimization

```bash
# Force merge indices
curl -X POST "elasticsearch:9200/old-index/_forcemerge?max_num_segments=1"

# Update index settings
curl -X PUT "elasticsearch:9200/logs-*/_settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "refresh_interval": "60s",
    "number_of_replicas": 0
  }'

# Shrink index
curl -X POST "elasticsearch:9200/large-index/_shrink/small-index" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "index.number_of_shards": 1
    }
  }'
```

## Container Log Collection

### Docker Logging Driver

Configure Docker daemon for ELK integration:

```json
{
  "log-driver": "gelf",
  "log-opts": {
    "gelf-address": "udp://logstash:12201",
    "tag": "{{.Name}}/{{.FullID}}"
  }
}
```

### Kubernetes Logging Architecture

Deploy Filebeat as DaemonSet for Kubernetes log collection:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccount: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:8.11.0
        args: [
          "-c", "/etc/filebeat.yml",
          "-e"
        ]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0600
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: varlog
        hostPath:
          path: /var/log
      - name: data
        hostPath:
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
```

## Best Practices

### Index Management

1. **Index Naming**: Use time-based indices (logs-YYYY.MM.dd)
2. **Shard Sizing**: Keep shards between 20-40GB for optimal performance
3. **Replica Strategy**: Use 0 replicas for non-critical data, 1-2 for critical
4. **Template Usage**: Define index templates for consistent settings
5. **ILM Policies**: Implement lifecycle management for cost optimization

### Data Modeling

1. **Field Types**: Use appropriate field types (keyword vs text)
2. **Mapping Explosion**: Avoid high-cardinality fields
3. **Nested Objects**: Use nested objects sparingly
4. **Field Naming**: Use consistent naming conventions
5. **Field Limits**: Monitor field count per index

### Query Optimization

```json
// Good: Use specific time ranges
{
  "query": {
    "bool": {
      "must": [
        {"range": {"@timestamp": {"gte": "now-1h"}}},
        {"term": {"level": "ERROR"}}
      ]
    }
  }
}

// Avoid: Open-ended time ranges
{
  "query": {
    "match_all": {}
  }
}

// Good: Use filters for exact matches
{
  "query": {
    "bool": {
      "filter": [
        {"term": {"service": "webapp"}},
        {"range": {"@timestamp": {"gte": "now-1d"}}}
      ]
    }
  }
}
```

### Operational Excellence

1. **Monitoring**: Monitor cluster health, performance metrics
2. **Backup**: Regular snapshots of critical indices
3. **Capacity Planning**: Monitor disk usage and growth trends
4. **Security**: Enable authentication and encryption
5. **Documentation**: Document index patterns and field mappings

### Resource Planning

```yaml
# Memory allocation guidelines
elasticsearch:
  heap: "50% of available RAM, max 32GB"
  total_memory: "64GB recommended for production"

logstash:
  heap: "4-8GB typically sufficient"
  workers: "Number of CPU cores"

kibana:
  memory: "2-4GB for normal usage"
```

## Troubleshooting

### Common Issues

#### Elasticsearch Issues

```bash
# Check cluster health
curl "elasticsearch:9200/_cluster/health?pretty"

# Check node status
curl "elasticsearch:9200/_cat/nodes?v"

# Check index status
curl "elasticsearch:9200/_cat/indices?v"

# Check shard allocation
curl "elasticsearch:9200/_cat/shards?v"

# Check pending tasks
curl "elasticsearch:9200/_cluster/pending_tasks?pretty"
```

#### Logstash Issues

```bash
# Check Logstash status
curl "logstash:9600/_node/stats?pretty"

# Check pipeline stats
curl "logstash:9600/_node/stats/pipelines?pretty"

# Monitor Logstash logs
tail -f /usr/share/logstash/logs/logstash-plain.log

# Test configuration
/usr/share/logstash/bin/logstash --config.test_and_exit --path.config=/usr/share/logstash/pipeline/
```

#### Kibana Issues

```bash
# Check Kibana status
curl "kibana:5601/api/status"

# Check Kibana logs
tail -f /usr/share/kibana/logs/kibana.log

# Clear browser cache and cookies
# Reset Kibana index pattern cache
```

### Performance Debugging

```bash
# Monitor query performance
curl "elasticsearch:9200/_cat/thread_pool/search?v&h=node_name,name,active,rejected,completed"

# Check slow queries
curl "elasticsearch:9200/_cluster/settings?include_defaults=true" | grep slow

# Monitor JVM heap usage
curl "elasticsearch:9200/_nodes/stats/jvm?pretty"

# Check cache usage
curl "elasticsearch:9200/_nodes/stats/indices/query_cache,request_cache,fielddata?pretty"
```

### Log Analysis

```bash
# Common log patterns to monitor
tail -f elasticsearch.log | grep -E "(ERROR|Exception|OutOfMemory)"
tail -f logstash.log | grep -E "(ERROR|pipeline.*stopped)"
tail -f kibana.log | grep -E "(ERROR|FATAL)"

# Monitor disk space
df -h /usr/share/elasticsearch/data
df -h /var/log

# Check file descriptors
lsof -p $(pgrep -f elasticsearch) | wc -l
```

## Resources

### Official Documentation

- [Elastic Stack Documentation](https://www.elastic.co/guide/index.html)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Reference](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/index.html)

### Container Resources

- [Elastic Docker Images](https://www.docker.elastic.co/)
- [Elastic Helm Charts](https://github.com/elastic/helm-charts)
- [Elastic Cloud on Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)
- [Docker Compose Examples](https://github.com/elastic/elasticsearch/tree/main/docs/reference/setup/install/docker)

### Beats Documentation

- [Filebeat Reference](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Metricbeat Reference](https://www.elastic.co/guide/en/beats/metricbeat/current/index.html)
- [Packetbeat Reference](https://www.elastic.co/guide/en/beats/packetbeat/current/index.html)
- [Heartbeat Reference](https://www.elastic.co/guide/en/beats/heartbeat/current/index.html)

### Community Resources

- [Elastic Community](https://discuss.elastic.co/)
- [Awesome Elasticsearch](https://github.com/dzharii/awesome-elasticsearch)
- [Elastic Blog](https://www.elastic.co/blog/)
- [Elastic Webinars](https://www.elastic.co/webinars/)

### Learning Resources

- [Elastic Training](https://www.elastic.co/training/)
- [Elasticsearch Certifications](https://www.elastic.co/training/certification)
- [Getting Started Guides](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html)
- [Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/how-to.html)

### Integration Examples

- [ELK + Docker](https://elk-docker.readthedocs.io/)
- [ELK + Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html)
- [ELK + Prometheus](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-module-prometheus.html)
- [ELK + Jaeger](https://www.elastic.co/guide/en/apm/guide/current/jaeger-integration.html)
