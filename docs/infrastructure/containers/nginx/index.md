---
title: Nginx Reverse Proxy and Load Balancing
description: Guide to using Nginx as a reverse proxy, load balancer, and TLS terminator with Docker
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: overview
ms.service: infrastructure
---

## Nginx

Nginx is a high-performance web server that can also function as a reverse proxy, load balancer, and HTTP cache. This guide demonstrates how to configure Nginx for reverse proxying and load balancing using Docker containers.

## What is a Reverse Proxy?

A reverse proxy sits between clients and backend servers, forwarding client requests to the appropriate backend server and then returning the server's response back to the client. Benefits include:

- **Load distribution** - Spread requests across multiple servers
- **SSL termination** - Handle SSL/TLS encryption/decryption
- **Caching** - Store frequently requested content
- **Security** - Hide backend server details from clients
- **Compression** - Reduce bandwidth usage

## In This Section

- [Reverse Proxy](reverse-proxy.md) — Configuring Nginx as a reverse proxy with Docker — basic setup, separate ports, and name-based virtual hosts
- [Load Balancing](load-balancing.md) — Load balancing with Nginx — upstream groups, balancing methods, health checks, and advanced configuration
- [TLS / Let's Encrypt](tls.md) — Configuring TLS/SSL in Nginx, including automated certificates with Let's Encrypt (Certbot) on host and in Docker
- [Monitoring & Troubleshooting](monitoring.md) — Monitoring Nginx with the status module, useful operational commands, and solutions to common issues
- [Best Practices](best-practices.md) — Nginx security headers, rate limiting, and caching best practices

## Resources

- [Nginx Documentation](http://nginx.org/en/docs/index.md)
- [Nginx Load Balancing](http://nginx.org/en/docs/http/load_balancing.html)
- [Nginx Reverse Proxy](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Nginx SSL Configuration](http://nginx.org/en/docs/http/configuring_https_servers.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/index.md)

Header reference:

- [`proxy_set_header` — ngx_http_proxy_module](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_set_header) — set/override request headers to the backend
- [`add_header` — ngx_http_headers_module](http://nginx.org/en/docs/http/ngx_http_headers_module.html#add_header) — add response headers (and the inheritance caveat)
- [Nginx embedded variables](http://nginx.org/en/docs/http/ngx_http_core_module.html#variables) — `$host`, `$remote_addr`, `$scheme`, and the rest used in header values
- [MDN HTTP Headers reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers) — authoritative definition of every request/response header
- [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/) — recommended security response headers and values
- [MDN: `Forwarded` header (RFC 7239)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded) — the standardized alternative to the `X-Forwarded-*` conventions

## Related Topics

- [ACME / Let's Encrypt (certificates section)](../../../security/certificates/acme/index.md)
- [SSL vs TLS](../../../security/certificates/sslvstls.md)
- [Docker](../docker/index.md)
