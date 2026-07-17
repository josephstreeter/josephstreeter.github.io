---
title: "Apache HTTP Server"
description: "Comprehensive guide to running the Apache HTTP Server (httpd) in containers — reverse proxy, load balancing, TLS with Let's Encrypt, security hardening, monitoring, and performance tuning"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: overview
ms.service: infrastructure
---

## Apache HTTP Server

The **Apache HTTP Server** (commonly "httpd" or simply "Apache") is one of the most widely deployed web servers in the world. It is a mature, modular server that can act as a static web server, a reverse proxy, a load balancer, and a TLS terminator. This guide focuses on running Apache in **containers** with Docker, covering reverse proxying, load balancing, HTTPS with Let's Encrypt, security hardening, monitoring, and performance tuning.

The examples use the official [`httpd`](https://hub.docker.com/_/httpd) image (Apache 2.4). Its configuration lives at `/usr/local/apache2/conf/httpd.conf`, extra config snippets go in `/usr/local/apache2/conf/extra/`, and the default document root is `/usr/local/apache2/htdocs/`.

### Apache vs Nginx

Both Apache and [Nginx](../nginx/index.md) are production-grade web servers; the right choice depends on the workload. They are also frequently combined — Nginx as an edge cache/reverse proxy in front of Apache application servers.

| | Apache HTTP Server | Nginx |
| - | ------------------ | ----- |
| Architecture | Process/thread-based (MPMs: prefork, worker, event) | Event-driven, asynchronous |
| Configuration | Central config plus per-directory `.htaccess` overrides | Central config, no per-directory files |
| Dynamic content | In-process modules (`mod_php`, `mod_wsgi`) | Proxies to external processes (PHP-FPM, etc.) |
| Module loading | Dynamic — modules load at runtime via `LoadModule` | Mostly compile-time (dynamic modules since 1.9.11) |
| Strengths | `.htaccess` flexibility, huge module ecosystem | High concurrency, low memory footprint |

### Modules

Apache's capabilities come from modules that must be enabled with `LoadModule`. The official image ships them, but many are commented out by default. This guide uses:

| Module | Purpose |
| ------ | ------- |
| `mod_proxy`, `mod_proxy_http` | Reverse proxying to backend servers |
| `mod_proxy_balancer`, `mod_lbmethod_*` | Load balancing across backends |
| `mod_ssl` | TLS/HTTPS termination |
| `mod_headers` | Add or modify request/response headers |
| `mod_rewrite` | URL rewriting and redirects |
| `mod_deflate`, `mod_cache`, `mod_cache_disk` | Compression and caching |
| `mod_status` | Runtime server status page |

Enable a module by uncommenting (or adding) its `LoadModule` line in `httpd.conf`:

```apache
LoadModule proxy_module        modules/mod_proxy.so
LoadModule proxy_http_module   modules/mod_proxy_http.so
LoadModule ssl_module          modules/mod_ssl.so
LoadModule headers_module      modules/mod_headers.so
LoadModule rewrite_module      modules/mod_rewrite.so
```

### In This Section

- [Reverse Proxy](reverse-proxy.md) — Apache as a reverse proxy with `mod_proxy` and name-based virtual hosts, using Docker
- [Load Balancing](load-balancing.md) — `mod_proxy_balancer`, balancing methods, sticky sessions, health checks, and the balancer manager
- [TLS / Let's Encrypt](tls.md) — HTTPS with `mod_ssl` and automated certificates via Let's Encrypt (Certbot) on the host and in Docker
- [Security and Hardening](security.md) — security response headers, information-disclosure hardening, and access control
- [Monitoring and Troubleshooting](monitoring.md) — `mod_status`, logging, and solutions to common issues
- [Performance and Best Practices](best-practices.md) — MPM tuning, compression, caching, and operational best practices

### Resources

- [Apache HTTP Server 2.4 Documentation](https://httpd.apache.org/docs/2.4/)
- [Apache Module Index](https://httpd.apache.org/docs/2.4/mod/)
- [`httpd` Docker image](https://hub.docker.com/_/httpd)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) — generates Apache TLS config
- [Apache Performance Tuning](https://httpd.apache.org/docs/2.4/misc/perf-tuning.html)

### Related Topics

- [Nginx](../nginx/index.md) — the event-driven alternative
- [ACME / Let's Encrypt (certificates section)](../../../security/certificates/acme/index.md)
- [SSL vs TLS](../../../security/certificates/sslvstls.md)
- [Docker](../docker/index.md)
