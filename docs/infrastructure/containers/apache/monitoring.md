---
title: "Apache Monitoring and Troubleshooting"
description: "Monitoring Apache with mod_status, configuring logging, and resolving common Apache issues in containers"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Monitoring and Troubleshooting

### Server Status (mod_status)

`mod_status` exposes a live page of worker activity, request throughput, and per-connection state. Enable the module and a restricted `/server-status` handler:

```apache
LoadModule status_module modules/mod_status.so

# Include per-request detail (CPU, request being served)
ExtendedStatus On

<Location "/server-status">
    SetHandler server-status
    Require ip 127.0.0.1 10.0.0.0/8
</Location>
```

```bash
# Human-readable page
curl http://localhost/server-status

# Machine-readable summary (for scripts/exporters)
curl http://localhost/server-status?auto
```

> [!WARNING]
> Never expose `/server-status` publicly — it reveals client IPs, requested URLs, and vhost names. Restrict it with `Require ip` and/or authentication, and consider a dedicated internal port.

The `?auto` output feeds monitoring systems. The [Prometheus apache_exporter](https://github.com/Lusitaniae/apache_exporter) scrapes it and exports metrics such as busy/idle workers, total accesses, and bytes served.

### Logging

Apache writes an error log and an access log. In containers, log to the container's stdout/stderr so `docker logs` and log drivers capture them:

```apache
# Send logs to the container's stdout/stderr
ErrorLog  /proc/self/fd/2
LogLevel  warn

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
CustomLog /proc/self/fd/1 combined
```

Common `LogFormat` tokens:

| Token | Meaning |
| ----- | ------- |
| `%h` | Client IP (or `%{X-Forwarded-For}i` behind another proxy) |
| `%t` | Request time |
| `%r` | Request line (method, path, protocol) |
| `%>s` | Final HTTP status code |
| `%b` | Response size in bytes |
| `%D` | Time to serve the request, in microseconds |
| `%{Referer}i` / `%{User-Agent}i` | Named request headers |

> [!TIP]
> Behind an upstream proxy or load balancer, `%h` logs the proxy's IP. Log the real client with `%{X-Forwarded-For}i`, and raise `LogLevel` to `debug` (or per-module, e.g. `LogLevel proxy:debug`) only while diagnosing.

### Useful Commands

```bash
# Validate configuration syntax (do this before every reload)
docker exec apache httpd -t

# Show the parsed virtual host layout
docker exec apache httpd -S

# List compiled-in and loaded modules
docker exec apache httpd -M

# Graceful reload — finish in-flight requests, then apply new config
docker exec apache apachectl graceful

# Follow logs
docker logs -f apache
```

### Common Issues and Solutions

| Symptom | Likely cause | Resolution |
| ------- | ------------ | ---------- |
| **503 Service Unavailable** | Backend down, or all balancer members failed | Check backends (`docker compose ps`); review `retry`/health-check settings; look for `proxy:error` in the log |
| **502 Bad Gateway** | Backend returned an invalid response or closed the connection | Verify the backend speaks HTTP on the proxied port; check `ProxyPass` target host/port |
| **AH00558: could not reliably determine the server's fully qualified domain name** | `ServerName` not set | Add a global `ServerName` directive |
| **Redirect loops on HTTPS** | Backend sees `http` and redirects to HTTPS repeatedly | Set `RequestHeader set X-Forwarded-Proto "https"` and configure the app to trust it |
| **403 Forbidden** | Missing `Require all granted`, or restrictive `<Directory>`/`<Proxy>` rules | Grant access to the served directory/proxy; check filesystem permissions |
| **Config change not applied** | Container not reloaded | `docker exec apache apachectl graceful` (or restart the container) |
| **Module not found on start** | `LoadModule` for a module not present/enabled | Confirm the `.so` exists under `modules/` and the `LoadModule` line is uncommented |

```bash
# Reproduce a proxied request and inspect status/headers
curl -I -H "Host: app1.example.com" http://localhost/

# Check whether Apache can reach a backend from inside the container
docker exec apache curl -sv http://app1:80/ 2>&1 | head

# Watch the error log for proxy failures
docker logs apache 2>&1 | grep -i proxy
```

## Navigation

[◄ Security and Hardening](security.md) · [Apache Overview](index.md) · [Performance and Best Practices ►](best-practices.md)
