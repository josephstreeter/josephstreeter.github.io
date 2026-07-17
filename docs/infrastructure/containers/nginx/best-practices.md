---
title: Nginx Best Practices
description: Nginx security headers, rate limiting, and caching best practices
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: conceptual
ms.service: infrastructure
---

## Best Practices

### Security Headers

```nginx
server {
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

Response headers are set with the [`add_header`](http://nginx.org/en/docs/http/ngx_http_headers_module.html#add_header) directive. The `always` parameter makes Nginx send the header on **all** responses, including error responses (4xx/5xx) — without it, the header is omitted on many error codes.

| Header | Example value | What it does |
| ------ | ------------- | ------------ |
| [`X-Frame-Options`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options) | `SAMEORIGIN` | Controls whether the page may be loaded in a `<frame>`/`<iframe>`, mitigating clickjacking. `SAMEORIGIN` permits framing only by pages of the same origin. Largely superseded by CSP `frame-ancestors`. |
| [`X-Content-Type-Options`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options) | `nosniff` | Stops the browser from MIME-sniffing a response away from its declared `Content-Type`, closing some XSS/drive-by vectors. |
| [`Referrer-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy) | `strict-origin-when-cross-origin` | Controls how much of the referring URL is sent in the `Referer` header. The value shown is the modern browser default: full URL same-origin, origin-only cross-origin, nothing on HTTPS→HTTP downgrades. |
| [`Content-Security-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) | `default-src 'self'` | Allowlists where the page may load scripts, styles, images, frames, etc. The single strongest defense against XSS and content injection. Tailor the directives to the sources your app actually needs. |
| [`Strict-Transport-Security`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) (HSTS) | `max-age=31536000; includeSubDomains` | Instructs browsers to use HTTPS only for the domain for `max-age` seconds, defeating SSL-stripping/downgrade. Only send this over HTTPS, and be sure every subdomain supports HTTPS before adding `includeSubDomains` (and `preload`). |

> [!IMPORTANT]
> **`add_header` inheritance is not additive.** Directives from an outer block (e.g. `http` or `server`) are inherited by an inner block (e.g. `location`) **only if that inner block defines no `add_header` of its own**. As soon as a `location` adds any header, it loses *all* inherited ones and must re-declare every header it needs. Define security headers once at the `server` level and audit any per-`location` `add_header` for this gotcha.

A note on what changed from older example configurations:

> [!NOTE]
> Two headers from older guides were intentionally dropped from the example above:
>
> - **`X-XSS-Protection`** — a legacy header for the browsers' built-in XSS auditor. It is [deprecated](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection); modern browsers ignore or have removed it, and the once-common `1; mode=block` value could itself introduce vulnerabilities. Omit it (or send `0`) and rely on `Content-Security-Policy`.
> - The permissive CSP `default-src 'self' http: https: data: blob: 'unsafe-inline'` allows inline scripts and almost any source, which negates most of CSP's protection. Prefer a strict policy (`default-src 'self'`) and widen it only as specific needs require.

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

## Navigation

[◄ Monitoring & Troubleshooting](monitoring.md) · [Nginx Overview](index.md)
