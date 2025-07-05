---
title: "Nginx Reverse Proxy and Load Balancing"
description: "Complete guide to using Nginx as a reverse proxy and load balancer with Docker"
tags: ["nginx", "reverse-proxy", "load-balancing", "docker", "containers"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2025-01-20"
---

# Nginx

Nginx is a high-performance web server that can also function as a reverse proxy, load balancer, and HTTP cache. This guide demonstrates how to configure Nginx for reverse proxying and load balancing using Docker containers.

## What is a Reverse Proxy?

A reverse proxy sits between clients and backend servers, forwarding client requests to the appropriate backend server and then returning the server's response back to the client. Benefits include:

- **Load distribution** - Spread requests across multiple servers
- **SSL termination** - Handle SSL/TLS encryption/decryption
- **Caching** - Store frequently requested content
- **Security** - Hide backend server details from clients
- **Compression** - Reduce bandwidth usage

## Reverse Proxy

### Initial Setup

Docker containers will be used to demonstrate using Nginx as a reverse proxy. Create a directory structure to hold all required files.

```bash
# Create main project directory
mkdir nginx-demo && cd nginx-demo

# Create subdirectories for each component
mkdir webserver1 webserver2 nginx

# Verify directory structure
tree .
```

Expected directory structure:

nginx-demo/
├── webserver1/
├── webserver2/
├── nginx/
└── docker-compose.yml


### Create Web Content

In each "webserver*" folder, create an `index.html` file with content specific to that webserver:

**webserver1/index.html:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Web Server 1</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #2c3e50; }
        .server-info { background-color: #ecf0f1; padding: 20px; margin: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Web Server 1</h1>
    <div class="server-info">
        <p>This is server 1 responding to your request</p>
        <p>Server ID: webserver1</p>
    </div>
</body>
</html>
```

**webserver2/index.html:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Web Server 2</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #27ae60; }
        .server-info { background-color: #ecf0f1; padding: 20px; margin: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Web Server 2</h1>
    <div class="server-info">
        <p>This is server 2 responding to your request</p>
        <p>Server ID: webserver2</p>
    </div>
</body>
</html>
```

### Basic Nginx Configuration

Create a file named `nginx.conf` in the "nginx" directory:

```nginx
# nginx/nginx.conf
worker_processes 1;

events { 
    worker_connections 1024; 
}

http {
    # Include MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    # Basic proxy settings
    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Host $server_name;

    # Timeouts
    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```

### Docker Compose Configuration

Create a `docker-compose.yml` file in the root directory:

```yaml
# docker-compose.yml
version: "3.9"

services:
  apache1:
    image: httpd:latest
    container_name: my-apache-app1
    volumes:
      - ./webserver1:/usr/local/apache2/htdocs
    networks:
      - nginx-network

  apache2:
    image: httpd:latest
    container_name: my-apache-app2
    volumes:
      - ./webserver2:/usr/local/apache2/htdocs
    networks:
      - nginx-network

  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
      - "8081:8081"
      - "8082:8082"
    depends_on:
      - apache1
      - apache2
    networks:
      - nginx-network

networks:
  nginx-network:
    driver: bridge
```

### Start the Environment

Create the environment by running the following Docker Compose command:

```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# Check logs if needed
docker-compose logs nginx
```

## Reverse Proxy - Sites on Separate Ports

Update the `nginx.conf` file to include upstream sections and virtual server sections:

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

    # Define upstream servers
    upstream webserver1 {
        server my-apache-app1:80;
        # Health check (nginx plus feature)
        # health_check;
    }

    upstream webserver2 {
        server my-apache-app2:80;
        # health_check;
    }

    # Global proxy settings
    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Host $server_name;

    # Server block for webserver1 on port 8081
    server {
        listen 8081;
        server_name localhost;
        access_log /var/log/nginx/webserver1_access.log compression;
        error_log /var/log/nginx/webserver1_error.log;
        
        location / {
            proxy_pass http://webserver1;
            proxy_set_header Host $host:$server_port;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # Server block for webserver2 on port 8082
    server {
        listen 8082;
        server_name localhost;
        access_log /var/log/nginx/webserver2_access.log compression;
        error_log /var/log/nginx/webserver2_error.log;

        location / {
            proxy_pass http://webserver2;
            proxy_set_header Host $host:$server_port;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### Update and Test Configuration

```bash
# Restart nginx with new configuration
docker-compose down && docker-compose up -d

# Test both endpoints
curl http://localhost:8081
curl http://localhost:8082

# Test health endpoints
curl http://localhost:8081/health
curl http://localhost:8082/health
```

## Reverse Proxy - Sites on Single Port

### Configure Host Entries

Create two entries in the `/etc/hosts` file for each webserver:

```bash
# Add entries to /etc/hosts
echo "127.0.0.1 site1.joseph-streeter.com" | sudo tee -a /etc/hosts
echo "127.0.0.1 site2.joseph-streeter.com" | sudo tee -a /etc/hosts

# Verify entries
grep joseph-streeter /etc/hosts
```

### Update Nginx Configuration

Update the `nginx.conf` file to include `server_name` directives:

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

    upstream webserver1 {
        server my-apache-app1:80;
    }

    upstream webserver2 {
        server my-apache-app2:80;
    }

    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    # Virtual host for site1
    server {
        listen 80;
        server_name site1.joseph-streeter.com;
        access_log /var/log/nginx/site1_access.log compression;
        error_log /var/log/nginx/site1_error.log;
        
        location / {
            proxy_pass http://webserver1;
        }

        location /health {
            access_log off;
            return 200 "site1 healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # Virtual host for site2
    server {
        listen 80;
        server_name site2.joseph-streeter.com;
        access_log /var/log/nginx/site2_access.log compression;
        error_log /var/log/nginx/site2_error.log;

        location / {
            proxy_pass http://webserver2;
        }

        location /health {
            access_log off;
            return 200 "site2 healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # Default server (catch-all)
    server {
        listen 80 default_server;
        server_name _;
        return 444; # Close connection without response
    }
}
```

### Test Name-Based Virtual Hosts

```bash
# Update configuration
docker-compose down && docker-compose up -d

# Test both sites
curl http://site1.joseph-streeter.com
curl http://site2.joseph-streeter.com

# Test with headers to verify proxy settings
curl -H "Host: site1.joseph-streeter.com" http://localhost
curl -H "Host: site2.joseph-streeter.com" http://localhost
```

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

## SSL/TLS Configuration

### Basic SSL Setup

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL certificate files
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # SSL session cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header X-Forwarded-Proto https;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

## Monitoring and Troubleshooting

### Enable Status Module

```nginx
server {
    listen 8080;
    server_name localhost;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
    
    location /upstream_status {
        # nginx plus feature
        # status;
        access_log off;
    }
}
```

### Useful Commands

```bash
# Test nginx configuration
docker exec nginx-proxy nginx -t

# Reload nginx configuration
docker exec nginx-proxy nginx -s reload

# View nginx status
curl http://localhost:8080/nginx_status

# Monitor access logs
docker exec nginx-proxy tail -f /var/log/nginx/access.log

# Check upstream server status
docker exec nginx-proxy cat /var/log/nginx/error.log | grep upstream

# Test configuration syntax
docker run --rm -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf nginx nginx -t
```

### Common Issues and Solutions

1. **502 Bad Gateway**

   ```bash
   # Check if backend servers are running
   docker-compose ps
   
   # Check network connectivity
   docker exec nginx-proxy ping my-apache-app1
   ```

2. **504 Gateway Timeout**

   ```nginx
   # Increase timeout values
   proxy_connect_timeout 60s;
   proxy_send_timeout 60s;
   proxy_read_timeout 60s;
   ```

3. **Connection refused**

   ```bash
   # Verify backend server ports
   docker exec my-apache-app1 netstat -tlnp
   ```

## Best Practices

### Security Headers

```nginx
server {
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

### Rate Limiting

```nginx
http {
    # Define rate limiting zone
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
        }
    }
}
```

### Caching

```nginx
http {
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g 
                     inactive=60m use_temp_path=off;
    
    server {
        location / {
            proxy_cache my_cache;
            proxy_cache_revalidate on;
            proxy_cache_min_uses 3;
            proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
            proxy_cache_background_update on;
            proxy_cache_lock on;
            
            proxy_pass http://backend;
        }
    }
}
```

## Resources

- [Nginx Documentation](http://nginx.org/en/docs/)
- [Nginx Load Balancing](http://nginx.org/en/docs/http/load_balancing.html)
- [Nginx Reverse Proxy](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Nginx SSL Configuration](http://nginx.org/en/docs/http/configuring_https_servers.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

This comprehensive guide provides everything needed to implement Nginx as a reverse proxy and load balancer in containerized environments.
