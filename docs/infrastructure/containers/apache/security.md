---
title: "Apache Security and Hardening"
description: "Hardening the Apache HTTP Server — security response headers, information-disclosure controls, request limits, and access control"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Security and Hardening

This page covers hardening an Apache reverse proxy or web server: response security headers, reducing information disclosure, limiting request abuse, and controlling access.

### Security Response Headers

Set response headers with `mod_headers`. Use `always` so they are sent on error responses too:

```apache
LoadModule headers_module modules/mod_headers.so

<VirtualHost *:443>
    # ... TLS config ...

    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</VirtualHost>
```

| Header | Example value | What it does |
| ------ | ------------- | ------------ |
| [`X-Frame-Options`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options) | `SAMEORIGIN` | Prevents the page from being framed by other origins (clickjacking). Superseded by CSP `frame-ancestors`. |
| [`X-Content-Type-Options`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options) | `nosniff` | Stops MIME-sniffing away from the declared `Content-Type`. |
| [`Referrer-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy) | `strict-origin-when-cross-origin` | Limits how much of the referring URL is sent. The modern default. |
| [`Content-Security-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) | `default-src 'self'` | Allowlists the sources a page may load — the strongest XSS/injection defense. Tailor to your app. |
| [`Strict-Transport-Security`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) | `max-age=31536000; includeSubDomains` | Forces HTTPS for the domain. Only send over HTTPS, and confirm all subdomains support HTTPS before `includeSubDomains`/`preload`. |

> [!NOTE]
> Legacy guides often include `X-XSS-Protection` — it is [deprecated](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection) and best omitted (rely on CSP). Unlike Nginx's `add_header`, Apache's `Header` directives from an outer scope **are merged** into inner scopes, but an inner `Header set` for the same name overrides it — keep header definitions in one place to avoid surprises.

### Reduce Information Disclosure

By default Apache advertises its version and OS. Trim this in the main config:

```apache
# Send only "Server: Apache" — not version/OS/module details
ServerTokens Prod

# Remove the version footer on error pages and listings
ServerSignature Off

# Disable the TRACE method (cross-site tracing)
TraceEnable Off
```

| Directive | Effect |
| --------- | ------ |
| `ServerTokens Prod` | `Server` header becomes just `Apache` (no version, OS, or modules). |
| `ServerSignature Off` | Removes the server-generated signature line from error/index pages. |
| `TraceEnable Off` | Disables the HTTP `TRACE` method, mitigating Cross-Site Tracing. |

### Disable Directory Listings and Restrict the Filesystem

Deny access to the whole filesystem by default, then grant only what you serve. Disable automatic directory indexes and `.htaccess` overrides unless you need them:

```apache
# Deny everything by default
<Directory />
    AllowOverride None
    Require all denied
    Options None
</Directory>

# Grant the document root; no directory listings, no symlink surprises
<Directory "/usr/local/apache2/htdocs">
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

# Block access to hidden files (e.g. .git, .env, .htpasswd)
<FilesMatch "^\.">
    Require all denied
</FilesMatch>
```

> [!TIP]
> Setting `AllowOverride None` disables `.htaccess` processing, which is both a security and a **performance** win — Apache no longer walks the directory tree looking for `.htaccess` files on every request. Only enable overrides for directories that genuinely need them.

### Request Limits (DoS Mitigation)

Cap request sizes and slow-client exposure to blunt basic abuse:

```apache
# Timeout for receiving a request / sending a response (seconds)
Timeout 60

# Limit sizes to reduce memory abuse
LimitRequestBody 10485760        # 10 MB max request body
LimitRequestFields 100           # max number of request headers
LimitRequestFieldSize 8190       # max size of a single header
LimitRequestLine 8190            # max size of the request line
```

For slow-loris-style attacks, enable `mod_reqtimeout` (loaded by default in the official image) to drop clients that dribble their request:

```apache
LoadModule reqtimeout_module modules/mod_reqtimeout.so

# header: allow 20s (extendable to 40s at 500 bytes/s); body: 20s (500 bytes/s)
RequestReadTimeout header=20-40,MinRate=500 body=20,MinRate=500
```

### Web Application Firewall (ModSecurity)

For deeper protection, `mod_security2` with the OWASP Core Rule Set (CRS) inspects requests for injection, XSS, and other attack patterns. It is not in the base `httpd` image; use an image that bundles it (for example [owasp/modsecurity-crs](https://hub.docker.com/r/owasp/modsecurity-crs)) or install it in a derived image.

```apache
# Conceptual — provided by a ModSecurity-enabled image
LoadModule security2_module modules/mod_security2.so
SecRuleEngine On
IncludeOptional /etc/modsecurity.d/owasp-crs/*.conf
```

> [!NOTE]
> Run ModSecurity in **detection-only** mode (`SecRuleEngine DetectionOnly`) first and review the logs before enforcing, to tune out false positives against your application.

### Access Control

Restrict sensitive locations by IP, and require authentication where appropriate:

```apache
# Admin area: internal networks only
<Location "/admin">
    Require ip 10.0.0.0/8 192.168.0.0/16
</Location>

# Basic auth example (use TLS so credentials aren't sent in the clear)
<Location "/private">
    AuthType Basic
    AuthName "Restricted"
    AuthUserFile "/usr/local/apache2/conf/.htpasswd"
    Require valid-user
</Location>
```

## Navigation

[◄ TLS / Let's Encrypt](tls.md) · [Apache Overview](index.md) · [Monitoring and Troubleshooting ►](monitoring.md)
