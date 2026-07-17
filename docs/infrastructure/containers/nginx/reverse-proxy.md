---
title: Nginx Reverse Proxy
description: Configuring Nginx as a reverse proxy with Docker — basic setup, separate ports, and name-based virtual hosts
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

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

#### Request (Proxy) Header Reference

The [`proxy_set_header`](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_set_header) directive sets or overrides the headers Nginx sends to the backend. Behind a reverse proxy the backend would otherwise only see Nginx's own address and connection, so these headers preserve the original client's details:

| Header | Value | Purpose |
| ------ | ----- | ------- |
| `Host` | `$host` | Forwards the original `Host` the client requested, so the backend can select the correct virtual host. Without it the backend sees the upstream name and may generate wrong redirects/links. |
| `X-Real-IP` | `$remote_addr` | The client's IP as seen by Nginx, so the backend can log and authorize the real client rather than the proxy. |
| `X-Forwarded-For` | `$proxy_add_x_forwarded_for` | Appends the client IP to any existing `X-Forwarded-For` value, preserving the ordered list of proxies the request passed through. |
| `X-Forwarded-Proto` | `$scheme` | Tells the backend whether the client used `http` or `https` — essential for apps that build absolute URLs, set `Secure` cookies, or enforce HTTPS. |
| `X-Forwarded-Host` | `$server_name` | The original host requested by the client (the forwarding companion to `Host`). |

The values above are built from standard Nginx variables:

| Variable | Meaning |
| -------- | ------- |
| `$host` | Host from the request line, or the `Host` header, or the matched `server_name` |
| `$remote_addr` | Client IP address of the current connection |
| `$proxy_add_x_forwarded_for` | Incoming `X-Forwarded-For` header plus `$remote_addr` |
| `$scheme` | Request scheme — `http` or `https` |
| `$server_name` | Name of the `server` block that handled the request |

> [!NOTE]
> `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, and `X-Forwarded-Host` are de-facto conventions, not part of the HTTP specification. The backend must be explicitly configured to **trust and read** them (for example, a trusted-proxy or forwarded-headers setting), and you should only accept them from proxies you control — a client can forge these headers when it connects directly. The standardized replacement is the single [`Forwarded`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded) header (RFC 7239).

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

## Navigation

[◄ Overview](index.md) · [Nginx Overview](index.md) · [Load Balancing ►](load-balancing.md)
