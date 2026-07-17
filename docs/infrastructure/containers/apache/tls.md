---
title: "Apache TLS / SSL and Let's Encrypt"
description: "Configuring HTTPS in Apache with mod_ssl, including automated certificates with Let's Encrypt (Certbot) on the host and in Docker"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## TLS / SSL Configuration

Apache terminates TLS with `mod_ssl`. This page covers a modern HTTPS virtual host and then automated, free certificates with Let's Encrypt.

### Enabling mod_ssl

```apache
LoadModule ssl_module    modules/mod_ssl.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so  # TLS session cache
Listen 443
```

### Basic HTTPS Virtual Host

```apache
<VirtualHost *:443>
    ServerName example.com

    SSLEngine on
    SSLCertificateFile      "/usr/local/apache2/conf/ssl/example.com.crt"
    SSLCertificateKeyFile   "/usr/local/apache2/conf/ssl/example.com.key"

    # Modern protocol and cipher policy (disable SSLv3/TLS 1.0/1.1)
    SSLProtocol             -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
    SSLHonorCipherOrder     off
    SSLSessionTickets       off

    # Reverse proxy to a backend (mark the connection as HTTPS)
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"
    ProxyPass        "/" "http://backend:80/"
    ProxyPassReverse "/" "http://backend:80/"
</VirtualHost>
```

| Directive | Purpose |
| --------- | ------- |
| `SSLEngine on` | Enables TLS for this virtual host. |
| `SSLCertificateFile` | The server certificate (with `mod_ssl` in Apache 2.4.8+, may contain the full chain). |
| `SSLCertificateKeyFile` | The matching private key (keep readable only by root). |
| `SSLProtocol -all +TLSv1.2 +TLSv1.3` | Enables only TLS 1.2 and 1.3; disables SSLv3, TLS 1.0/1.1. |
| `SSLCipherSuite` | Allowed ciphers. Use the [Mozilla generator](https://ssl-config.mozilla.org/) for a current list. |
| `SSLHonorCipherOrder off` | With TLS 1.3 / modern suites, let the client choose; set `on` only for legacy ordering needs. |

> [!TIP]
> Generate a vetted, up-to-date `mod_ssl` config with the [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) (choose "Apache"). See [SSL vs TLS](../../../security/certificates/sslvstls.md) for protocol background.

### Redirect HTTP to HTTPS

```apache
<VirtualHost *:80>
    ServerName example.com
    Redirect permanent "/" "https://example.com/"
</VirtualHost>
```

## Automated TLS with Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) issues free, publicly trusted certificates via the ACME protocol, valid for 90 days and designed to renew automatically. Prefer it over self-signed certificates for anything public-facing.

> [!NOTE]
> This page covers Let's Encrypt for Apache. For the ACME protocol itself, other clients, DNS-01 wildcard validation, and rate limits, see the [ACME section](../../../security/certificates/acme/index.md) and the [Certbot guide](../../../security/certificates/acme/certbot.md).

### Prerequisites

- A registered domain whose DNS **A/AAAA record points at the server** running Apache.
- Inbound TCP **port 80** reachable from the internet (for HTTP-01 validation).
- Apache serving the domain named in `ServerName`.

### Method 1 — Certbot with the Apache plugin

For Apache installed on the host, the Certbot Apache plugin obtains the certificate and edits your virtual host to use it:

```bash
# Debian/Ubuntu (see the Certbot guide for snap/other distros)
sudo apt update
sudo apt install certbot python3-certbot-apache

# Obtain and install the certificate, adding an HTTP->HTTPS redirect
sudo certbot --apache -d example.com -d www.example.com --redirect

# Verify and reload
sudo apachectl configtest && sudo systemctl reload apache2
```

Certbot writes the issued files under `/etc/letsencrypt/live/example.com/` and points `mod_ssl` at them:

```apache
SSLCertificateFile    /etc/letsencrypt/live/example.com/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
```

### Method 2 — Webroot (keep Apache serving)

The webroot method drops the ACME challenge file into a directory Apache already serves, so Apache never stops. Serve the challenge path from your HTTP virtual host:

```apache
<VirtualHost *:80>
    ServerName example.com

    # Serve Let's Encrypt HTTP-01 challenges from the webroot
    Alias "/.well-known/acme-challenge/" "/var/www/certbot/.well-known/acme-challenge/"
    <Directory "/var/www/certbot">
        Require all granted
    </Directory>

    # Redirect everything else to HTTPS
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [L,R=301]
</VirtualHost>
```

Request the certificate, then reference it from the HTTPS virtual host:

```bash
sudo certbot certonly --webroot -w /var/www/certbot \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
```

### Method 3 — Dockerized Apache + Certbot

When Apache runs in a container, run Certbot as a companion container sharing the certificate and webroot volumes:

```yaml
# docker-compose.yml (excerpt)
services:
  apache:
    image: httpd:2.4
    container_name: apache
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./apache/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro
      - certbot-webroot:/var/www/certbot:ro       # serve challenge files
      - certbot-certs:/etc/letsencrypt:ro          # read issued certs
    networks: [ web ]

  certbot:
    image: certbot/certbot:latest
    container_name: certbot
    volumes:
      - certbot-webroot:/var/www/certbot           # write challenge files
      - certbot-certs:/etc/letsencrypt             # store issued certs
    # Attempt renewal every 12 hours; certbot renews only when due
    entrypoint: >
      sh -c 'trap exit TERM;
      while :; do certbot renew --webroot -w /var/www/certbot; sleep 12h & wait $${!}; done'

volumes:
  certbot-webroot:
  certbot-certs:

networks:
  web:
    driver: bridge
```

Point `mod_ssl` at the shared certs (`/etc/letsencrypt/live/example.com/fullchain.pem` and `privkey.pem`), then issue the initial certificate once:

```bash
docker compose run --rm certbot certonly --webroot -w /var/www/certbot \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
docker compose up -d
```

> [!TIP]
> For a fully hands-off container setup, consider [nginx-proxy + acme-companion](https://github.com/nginx-proxy/acme-companion) or a reverse proxy with built-in ACME (Caddy, Traefik) in front of Apache.

### Automatic Renewal

Certificates last 90 days; Certbot renews within 30 days of expiry. A host install adds a systemd timer/cron job automatically. Apache keeps serving the old certificate until reloaded, so reload it after renewal with a **deploy hook**:

```bash
# Confirm the renewal timer
systemctl list-timers | grep certbot

# Test the whole renewal path without issuing a real certificate
sudo certbot renew --dry-run

# Reload Apache only when a certificate actually renews
sudo certbot renew --deploy-hook "apachectl graceful"
```

For the containerized setup, the renew loop handles renewal; reload Apache afterward by signalling the container (`docker exec apache apachectl graceful`).

> [!IMPORTANT]
> Test against Let's Encrypt's **staging** environment first (`--dry-run` or `--test-cert`) to avoid production [rate limits](https://letsencrypt.org/docs/rate-limits/). Always reference the `/etc/letsencrypt/live/<domain>/` symlinks — never copy the files elsewhere, or renewals will not take effect.

### Wildcards (DNS-01)

A wildcard certificate (`*.example.com`) requires DNS-01 validation and a DNS-provider API credential. See the [Certbot guide](../../../security/certificates/acme/certbot.md#dns-validation-and-wildcards) for provider plugins (Cloudflare, Route 53, and others).

## Navigation

[◄ Load Balancing](load-balancing.md) · [Apache Overview](index.md) · [Security and Hardening ►](security.md)
