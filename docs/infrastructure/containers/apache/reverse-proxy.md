---
title: "Apache Reverse Proxy"
description: "Configuring Apache HTTP Server as a reverse proxy with mod_proxy and name-based virtual hosts, using Docker"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Reverse Proxy

A reverse proxy sits in front of one or more backend servers, forwarding client requests to them and returning their responses. Apache implements this with the `mod_proxy` family of modules. Benefits include SSL/TLS termination, hiding backend topology, centralized logging, caching, and routing multiple applications behind one entry point.

### Enabling the Proxy Modules

Reverse proxying needs `mod_proxy` and a protocol handler (`mod_proxy_http` for HTTP backends). Enable them in `httpd.conf`:

```apache
LoadModule proxy_module      modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module    modules/mod_headers.so
```

> [!WARNING]
> Never leave Apache configured as an **open (forward) proxy**. Ensure `ProxyRequests Off` is set (it is the default). `ProxyRequests On` combined with a permissive `<Proxy>` block would let anyone relay arbitrary traffic through your server.

### Initial Setup

Create a project directory with a place for the Apache config and two backend web roots:

```bash
# Create the project structure
mkdir apache-demo && cd apache-demo
mkdir app1 app2 apache

# Simple backend content
echo '<h1>App 1</h1>' > app1/index.html
echo '<h1>App 2</h1>' > app2/index.html
```

### Basic Reverse Proxy Configuration

Create `apache/httpd.conf`. This forwards all requests to a single backend:

```apache
# apache/httpd.conf
ServerRoot "/usr/local/apache2"
Listen 80
ServerName proxy.example.com

# Required modules
LoadModule mpm_event_module  modules/mod_mpm_event.so
LoadModule proxy_module      modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module    modules/mod_headers.so
LoadModule unixd_module      modules/mod_unixd.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule mime_module       modules/mod_mime.so

User daemon
Group daemon

# Do not act as a forward proxy
ProxyRequests Off
<Proxy *>
    Require all granted
</Proxy>

# Pass the original Host and client details to the backend
ProxyPreserveHost On
RequestHeader set X-Forwarded-Proto "http"

# Forward everything to app1
ProxyPass        "/" "http://app1:80/"
ProxyPassReverse "/" "http://app1:80/"

# Logging
ErrorLog /proc/self/fd/2
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog /proc/self/fd/1 combined
```

#### Reverse-Proxy Directive Reference

| Directive | Purpose |
| --------- | ------- |
| `ProxyRequests Off` | Disables the forward proxy. Required for a secure reverse proxy. |
| `ProxyPass "/" "http://app1:80/"` | Maps a URL path to a backend. Requests for `/` are forwarded to `app1`. |
| `ProxyPassReverse` | Rewrites `Location`, `Content-Location`, and `URI` headers in backend responses so redirects point at the proxy, not the backend. |
| `ProxyPreserveHost On` | Sends the client's original `Host` header to the backend instead of the backend's hostname — the backend can then select the right virtual host. |
| `<Proxy *> Require all granted` | Access control for proxied requests. Restrict this in production (e.g. `Require ip 10.0.0.0/8`). |

#### Headers passed to the backend

`mod_proxy` automatically adds these request headers when forwarding:

| Header | Set by | Meaning |
| ------ | ------ | ------- |
| `X-Forwarded-For` | `mod_proxy` (automatic) | The client IP, appended to any existing chain of proxies. |
| `X-Forwarded-Host` | `mod_proxy` (automatic) | The original `Host` requested by the client. |
| `X-Forwarded-Server` | `mod_proxy` (automatic) | The hostname of the proxy server itself. |
| `X-Forwarded-Proto` | **you** (via `RequestHeader`) | Whether the client used `http` or `https`. Not automatic — set it explicitly, especially on the HTTPS vhost (`RequestHeader set X-Forwarded-Proto "https"`). |

> [!NOTE]
> `ProxyPreserveHost On` forwards the client `Host`, but the `X-Forwarded-*` headers are conventions the backend must be configured to trust. Only accept them from proxies you control — a client connecting directly can forge them.

### Docker Compose Configuration

Run Apache in front of two containerized backends:

```yaml
# docker-compose.yml
services:
  app1:
    image: httpd:2.4
    container_name: app1
    volumes:
      - ./app1:/usr/local/apache2/htdocs:ro
    networks:
      - web

  app2:
    image: httpd:2.4
    container_name: app2
    volumes:
      - ./app2:/usr/local/apache2/htdocs:ro
    networks:
      - web

  proxy:
    image: httpd:2.4
    container_name: apache-proxy
    ports:
      - "80:80"
    volumes:
      - ./apache/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro
    depends_on:
      - app1
      - app2
    networks:
      - web

networks:
  web:
    driver: bridge
```

Start it and verify:

```bash
docker compose up -d
docker compose ps

# The proxy forwards to app1
curl http://localhost/

# Validate the Apache config without restarting
docker exec apache-proxy httpd -t
```

### Name-Based Virtual Hosts

To serve multiple sites/apps from one Apache instance, use name-based virtual hosts that route by `Host` header. Replace the single `ProxyPass` with per-host `<VirtualHost>` blocks:

```apache
# apache/httpd.conf (virtual host section)
ProxyRequests Off
ProxyPreserveHost On

<VirtualHost *:80>
    ServerName app1.example.com
    ProxyPass        "/" "http://app1:80/"
    ProxyPassReverse "/" "http://app1:80/"
    RequestHeader set X-Forwarded-Proto "http"
</VirtualHost>

<VirtualHost *:80>
    ServerName app2.example.com
    ProxyPass        "/" "http://app2:80/"
    ProxyPassReverse "/" "http://app2:80/"
    RequestHeader set X-Forwarded-Proto "http"
</VirtualHost>
```

Test with explicit `Host` headers (or add entries to `/etc/hosts`):

```bash
curl -H "Host: app1.example.com" http://localhost/
curl -H "Host: app2.example.com" http://localhost/
```

### Path-Based Routing

To route by URL path instead of hostname, map multiple `ProxyPass` directives within one virtual host. **Order matters** — most specific paths first:

```apache
<VirtualHost *:80>
    ServerName example.com

    ProxyPreserveHost On

    # More specific paths must come before "/"
    ProxyPass        "/api/"  "http://api-backend:8080/"
    ProxyPassReverse "/api/"  "http://api-backend:8080/"

    ProxyPass        "/app/"  "http://app-backend:3000/"
    ProxyPassReverse "/app/"  "http://app-backend:3000/"

    # Catch-all last
    ProxyPass        "/" "http://web-backend:80/"
    ProxyPassReverse "/" "http://web-backend:80/"
</VirtualHost>
```

> [!TIP]
> Exclude a path from proxying with `ProxyPass "/static/" "!"` — useful when Apache should serve some paths locally (for example static assets) while proxying the rest.

### WebSocket Proxying

WebSocket backends need `mod_proxy_wstunnel` and a rewrite that upgrades matching requests:

```apache
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
LoadModule rewrite_module        modules/mod_rewrite.so

<VirtualHost *:80>
    ServerName ws.example.com

    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule ^/?(.*) "ws://backend:8080/$1" [P,L]

    ProxyPass        "/" "http://backend:8080/"
    ProxyPassReverse "/" "http://backend:8080/"
</VirtualHost>
```

## Navigation

[◄ Overview](index.md) · [Apache Overview](index.md) · [Load Balancing ►](load-balancing.md)
