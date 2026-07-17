---
title: "Apache Performance and Best Practices"
description: "Apache HTTP Server performance tuning — MPM selection and sizing, compression, caching, keep-alive, and container best practices"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: conceptual
ms.service: infrastructure
---

## Performance and Best Practices

### Multi-Processing Modules (MPMs)

An MPM determines how Apache handles concurrency. Exactly one is active. The official image defaults to **event**, which is the right choice for a reverse proxy or static/keep-alive-heavy workload.

| MPM | Model | Use when |
| --- | ----- | -------- |
| `event` | Threaded; a dedicated thread manages keep-alive connections | Default. Best for reverse proxies and high-concurrency HTTP(S) with keep-alive. |
| `worker` | Threaded (processes × threads) | Similar to event; use if a module is not event-compatible. |
| `prefork` | One process per connection, no threads | Only when you must load a non-thread-safe module in-process (e.g. classic `mod_php`). Highest memory use. |

Select and size the MPM (event example):

```apache
LoadModule mpm_event_module modules/mod_mpm_event.so

<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads          25
    MaxSpareThreads          75
    ThreadsPerChild          25
    MaxRequestWorkers        400      # max simultaneous requests
    MaxConnectionsPerChild   10000    # recycle children to bound memory leaks
</IfModule>
```

| Directive | Meaning |
| --------- | ------- |
| `ThreadsPerChild` | Threads per child process. |
| `MaxRequestWorkers` | Ceiling on concurrent requests (`≈ ThreadsPerChild × number of children`). The key sizing knob. |
| `MinSpareThreads` / `MaxSpareThreads` | Idle-thread band Apache maintains to absorb bursts. |
| `MaxConnectionsPerChild` | Requests a child serves before being recycled (bounds memory growth). `0` = never recycle. |

> [!TIP]
> Size `MaxRequestWorkers` to available memory: divide the container's memory budget by the average per-thread/process footprint. Setting it too high invites swapping under load; too low causes requests to queue. Load-test with `ab`, `wrk`, or `h2load` and watch `mod_status` busy workers.

### Keep-Alive

Reusing connections avoids repeated TCP/TLS handshakes:

```apache
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
```

Keep `KeepAliveTimeout` short (a few seconds) so idle connections free up quickly — the event MPM handles idle keep-alive connections efficiently without tying up a worker thread.

### Compression (mod_deflate)

Compress text responses to cut bandwidth. Do **not** compress already-compressed types (images, video, archives):

```apache
LoadModule deflate_module modules/mod_deflate.so

<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/css text/xml \
        application/javascript application/json application/xml image/svg+xml

    # Don't waste CPU on already-compressed content
    SetEnvIfNoCase Request_URI "\.(?:gif|jpe?g|png|webp|zip|gz|mp4)$" no-gzip
</IfModule>
```

> [!NOTE]
> Prefer Brotli (`mod_brotli`, `AddOutputFilterByType BROTLI_COMPRESS ...`) where available — it compresses text better than gzip. It ships with the official image but must be enabled with `LoadModule brotli_module modules/mod_brotli.so`.

### Caching (mod_cache)

`mod_cache` with a disk backend caches proxied/backend responses, reducing load on backends:

```apache
LoadModule cache_module      modules/mod_cache.so
LoadModule cache_disk_module modules/mod_cache_disk.so

<IfModule mod_cache_disk.c>
    CacheRoot "/var/cache/apache2"
    CacheEnable disk "/"
    CacheDirLevels 2
    CacheDirLength 1
    CacheIgnoreCacheControl Off      # honor backend Cache-Control
    CacheMaxFileSize 10485760        # 10 MB per object
</IfModule>
```

Set long-lived caching headers for static assets so clients and intermediaries cache them:

```apache
LoadModule expires_module modules/mod_expires.so

<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/png "access plus 30 days"
    ExpiresByType text/css  "access plus 7 days"
    ExpiresByType application/javascript "access plus 7 days"
</IfModule>
```

> [!IMPORTANT]
> Only cache what is safe to cache. Never disk-cache authenticated or per-user responses unless the backend sets appropriate `Cache-Control: private`/`no-store`. When in doubt, cache static assets only and leave dynamic responses to the backend.

### HTTP/2

Enable HTTP/2 (over TLS) for multiplexing and header compression:

```apache
LoadModule http2_module modules/mod_http2.so

Protocols h2 http/1.1
```

Add this in the global scope (and it applies to TLS vhosts). HTTP/2 pairs well with the event MPM.

### Container Best Practices

- **Pin an explicit image tag** (`httpd:2.4.62`) rather than `latest`, and rebuild to pick up security updates deliberately.
- **Mount config read-only** (`:ro`) and keep certificates/keys in a separate, tightly-permissioned volume or secret — never bake private keys into the image.
- **Run `httpd -t` in CI** (or a pre-deploy step) to catch config errors before they reach production.
- **Log to stdout/stderr** (see [Monitoring](monitoring.md)) so the container platform collects logs; avoid writing logs inside the container's writable layer.
- **Set resource limits** (`deploy.resources` / `--memory`, `--cpus`) and size `MaxRequestWorkers` to match.
- **Reload gracefully** with `apachectl graceful` (or a rolling container update) to apply config without dropping in-flight requests.
- **Run behind an orchestrator health check** hitting a lightweight endpoint; pair with `mod_proxy_hcheck` for backend health (see [Load Balancing](load-balancing.md)).

## Navigation

[◄ Monitoring and Troubleshooting](monitoring.md) · [Apache Overview](index.md)
