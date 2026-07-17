---
title: Nginx Load Balancing
description: Load balancing with Nginx — upstream groups, balancing methods, health checks, and advanced configuration
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Load Balancer

Nginx can distribute requests across multiple instances of an application, providing fault tolerance and optimizing resource utilization.

### Configure Load Balancing

Update the `nginx.conf` file to combine both servers under one upstream:

```nginx
# nginx/nginx.conf
worker_processes 1;

events { 
    worker_connections 1024; 
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    # Load balanced upstream
    upstream webservers {
        server my-apache-app1:80;
        server my-apache-app2:80;
        # Optional: Add backup server
        # server my-apache-app3:80 backup;
    }

    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    server {
        listen 80;
        server_name site1.joseph-streeter.com;
        access_log /var/log/nginx/loadbalancer_access.log compression;
        error_log /var/log/nginx/loadbalancer_error.log;
        
        location / {
            proxy_pass http://webservers;
            
            # Load balancer health check
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
            proxy_next_upstream_tries 3;
            proxy_next_upstream_timeout 30s;
        }

        location /health {
            access_log off;
            return 200 "load balancer healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### Test Load Balancing

```bash
# Update configuration
docker-compose down && docker-compose up -d

# Test load balancing with multiple requests
for i in {1..10}; do 
    echo "Request $i:"
    curl -s http://site1.joseph-streeter.com | grep -o "Web Server [12]"
    sleep 1
done
```

Expected output (should alternate):

```console
Request 1:
Web Server 1
Request 2:
Web Server 2
Request 3:
Web Server 1
Request 4:
Web Server 2
...
```

## Load Balancing Methods

### Round Robin (Default)

The simplest method where requests are distributed evenly across servers:

```nginx
upstream app {
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### Least Connected

Distributes requests to servers with fewer active connections:

```nginx
upstream app {
    least_conn;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### IP Hash

Uses client IP address to determine which server handles requests (session persistence):

```nginx
upstream app {
    ip_hash;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

> [!NOTE]
> **Session Persistence**: Neither round-robin nor least-connected load balancing persist sessions. If session persistence is required, use ip-hash method.

### Weighted Load Balancing

Distribute requests based on server capacity using weights:

```nginx
upstream app {
    server srv1.example.com weight=3;  # Receives 3x more requests
    server srv2.example.com weight=2;  # Receives 2x more requests
    server srv3.example.com weight=1;  # Receives 1x requests (default)
}
```

Example with different server capabilities:

```nginx
upstream webservers {
    # High-performance server gets more traffic
    server my-apache-app1:80 weight=3;
    # Standard server gets normal traffic
    server my-apache-app2:80 weight=1;
    # Backup server (only used if all primary servers are down)
    server my-apache-app3:80 backup;
}
```

### Health Checks and Server States

```nginx
upstream app {
    # Active server
    server srv1.example.com;
    
    # Server with custom weight and max failures
    server srv2.example.com weight=2 max_fails=3 fail_timeout=30s;
    
    # Backup server (only used when all primary servers are down)
    server srv3.example.com backup;
    
    # Temporarily remove server from rotation
    server srv4.example.com down;
    
    # Slow start server (nginx plus feature)
    # server srv5.example.com slow_start=30s;
}
```

### Advanced Configuration Example

```nginx
upstream backend {
    # Load balancing method
    least_conn;
    
    # Primary servers
    server app1.example.com:8080 weight=3 max_fails=2 fail_timeout=30s;
    server app2.example.com:8080 weight=2 max_fails=2 fail_timeout=30s;
    
    # Backup server
    server app3.example.com:8080 backup;
    
    # Keep alive connections to backend
    keepalive 32;
}

server {
    listen 80;
    server_name myapp.example.com;
    
    location / {
        proxy_pass http://backend;
        
        # Connection settings
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # Error handling
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Navigation

[◄ Reverse Proxy](reverse-proxy.md) · [Nginx Overview](index.md) · [TLS / Let's Encrypt ►](tls.md)
