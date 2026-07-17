---
title: Nginx TLS / SSL and Let's Encrypt
description: Configuring TLS/SSL in Nginx, including automated certificates with Let's Encrypt (Certbot) on host and in Docker
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

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

## Automated TLS with Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) is a free, automated certificate authority that issues publicly trusted TLS certificates using the ACME protocol. Instead of self-signed certificates (which browsers reject) or paid commercial certificates, you can obtain and automatically renew certificates for any public domain at no cost. Certificates are valid for 90 days and are meant to be renewed automatically.

> [!NOTE]
> This page covers Let's Encrypt specifically for Nginx. For the ACME protocol itself, other clients (including win-acme for Windows), DNS-01 wildcard validation, and rate-limit details, see the [ACME section](../../../security/certificates/acme/index.md) and the [Certbot guide](../../../security/certificates/acme/certbot.md).

### Prerequisites

- A registered domain whose DNS **A/AAAA record points at the server** running Nginx.
- Inbound TCP **port 80** reachable from the internet (used for HTTP-01 domain validation).
- Nginx serving the domain — the certificate is bound to the hostname in `server_name`.

### Method 1 — Certbot with the Nginx plugin

For Nginx installed directly on the host, the Certbot Nginx plugin is the simplest option: it obtains the certificate and edits your Nginx configuration to use it.

```bash
# Install Certbot and the Nginx plugin (Debian/Ubuntu; see the Certbot guide for snap/other distros)
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obtain a certificate and let Certbot configure Nginx automatically
sudo certbot --nginx -d example.com -d www.example.com

# Certbot edits the matching server block and can add an HTTP->HTTPS redirect
sudo nginx -t && sudo systemctl reload nginx
```

Certbot points the `server` block at the issued files under `/etc/letsencrypt/live/example.com/`:

```nginx
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

### Method 2 — Webroot (keep Nginx serving traffic)

The webroot method writes the ACME challenge file into a directory Nginx already serves, so Nginx never stops. This suits configurations you manage yourself (as in this guide) and reverse-proxy setups.

Serve the ACME challenge path from your HTTP `server` block:

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    # Let's Encrypt HTTP-01 challenge files
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect everything else to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}
```

Request the certificate with the webroot plugin, then point the HTTPS server block at the result:

```bash
sudo certbot certonly --webroot -w /var/www/certbot \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
```

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Modern TLS settings (see the SSL/TLS Configuration section above)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### Method 3 — Dockerized Nginx + Certbot

When Nginx runs in a container (as in this guide), run Certbot as a companion container that shares the certificate and webroot volumes with Nginx. This keeps the Docker Compose workflow from the reverse-proxy section intact.

```yaml
# docker-compose.yml (excerpt)
services:
  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - certbot-webroot:/var/www/certbot:ro       # serve challenge files
      - certbot-certs:/etc/letsencrypt:ro          # read issued certs
    networks:
      - nginx-network

  certbot:
    image: certbot/certbot:latest
    container_name: certbot
    volumes:
      - certbot-webroot:/var/www/certbot           # write challenge files
      - certbot-certs:/etc/letsencrypt             # store issued certs
    # Attempt renewal every 12 hours; certbot only renews when due
    entrypoint: >
      sh -c 'trap exit TERM;
      while :; do certbot renew --webroot -w /var/www/certbot; sleep 12h & wait $${!}; done'

volumes:
  certbot-webroot:
  certbot-certs:

networks:
  nginx-network:
    driver: bridge
```

Issue the initial certificate once, before the renewal loop takes over:

```bash
docker compose run --rm certbot certonly --webroot -w /var/www/certbot \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
```

> [!TIP]
> For a fully hands-off setup, consider a purpose-built image such as [nginx-proxy + acme-companion](https://github.com/nginx-proxy/acme-companion), or a reverse proxy with built-in ACME like **Caddy** or **Traefik**, which obtain and renew certificates automatically with no Certbot container to manage.

### Automatic Renewal

Let's Encrypt certificates last 90 days; Certbot renews them when they are within 30 days of expiry. A host install adds a systemd timer or cron job automatically:

```bash
# Confirm the renewal timer is active
systemctl list-timers | grep certbot

# Test renewal end-to-end without issuing a real certificate
sudo certbot renew --dry-run
```

Nginx keeps serving the old certificate until it is reloaded, so reload it after each successful renewal with a **deploy hook**:

```bash
# Runs only when a certificate is actually renewed
sudo certbot renew --deploy-hook "nginx -s reload"
```

For the containerized setup in Method 3, the renew loop handles renewal; reload Nginx afterward by signalling the container (for example `docker exec nginx-proxy nginx -s reload`) on a schedule or from a deploy hook.

> [!IMPORTANT]
> Test automation against Let's Encrypt's **staging** environment first (`--dry-run`, or `--test-cert`) to avoid hitting production [rate limits](https://letsencrypt.org/docs/rate-limits/). Always reference the `/etc/letsencrypt/live/<domain>/` symlinks in your config — never copy the files elsewhere, or renewals will not take effect.

### Wildcards (DNS-01)

A wildcard certificate (`*.example.com`) requires DNS-01 validation instead of the HTTP methods above, which means providing a DNS-provider API credential. See the [Certbot guide](../../../security/certificates/acme/certbot.md#dns-validation-and-wildcards) for provider plugins (Cloudflare, Route 53, and others).

## Navigation

[◄ Load Balancing](load-balancing.md) · [Nginx Overview](index.md) · [Monitoring & Troubleshooting ►](monitoring.md)
