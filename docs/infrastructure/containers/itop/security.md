---
title: "iTop Security"
description: "Securing iTop — TLS via a reverse proxy, authentication and profiles, database and file-permission hardening, and locking down the setup wizard"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Security

iTop holds sensitive operational data — asset inventory, contacts, and workflow that can trigger changes — and authenticates staff. Harden it before exposing it beyond a trusted network.

### TLS via a Reverse Proxy

Do not expose the iTop HTTP port directly. Put a reverse proxy in front for TLS termination and access control ([Nginx](../nginx/index.md) or [Apache](../apache/index.md)), and obtain a certificate with [Let's Encrypt](../../../security/certificates/acme/certbot.md).

```nginx
# Nginx reverse proxy for iTop
server {
    listen 443 ssl http2;
    server_name itop.example.com;

    ssl_certificate     /etc/letsencrypt/live/itop.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/itop.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 32m;          # allow attachment uploads

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;   # iTop needs this for correct links
    }
}

server {
    listen 80;
    server_name itop.example.com;
    return 301 https://$host$request_uri;
}
```

Then, in `config-itop.php` (see [Configuration](configuration.md)):

```php
'app_root_url' => 'https://itop.example.com/',
'secure_connection_required' => true,      // reject plain HTTP
```

> [!IMPORTANT]
> Forward `X-Forwarded-Proto https` from the proxy **and** set `app_root_url` to the HTTPS URL. If iTop thinks it's on HTTP it generates insecure links, breaks the portal, and may loop on redirects. `client_max_body_size`/`upload_max_filesize` must be large enough for attachments.

### Lock Down the Setup Wizard

The installer at `/setup/` can rebuild the database and configuration — it must never be reachable by untrusted users:

- iTop disables setup after installation; keep it disabled. Re-enable it only briefly for upgrades, from a trusted network, then disable again.
- Optionally block `/setup/` and `/toolkit/` at the reverse proxy except from admin source IPs:

  ```nginx
  location ~ ^/(setup|toolkit)/ {
      allow 10.0.0.0/8;
      deny all;
      proxy_pass http://127.0.0.1:8080;
  }
  ```

### Authentication and Profiles

- Enforce **strong passwords** and prefer **LDAP/SSO** over local accounts where possible (see [Integration](integration.md)).
- iTop authorization is **profile-based** — assign users the minimum profiles for their role (e.g. *Portal user*, *Service Desk Agent*, *Configuration Manager*) rather than *Administrator*.
- Create dedicated, least-privilege service accounts for the **REST API** and the **cron** scheduler — never reuse the admin account for automation.
- Review the **Administrator** profile membership periodically; it can change the data model and configuration.

### Database Hardening

- Give iTop a **dedicated database user** limited to its own schema — not the MySQL root account. The [Deployment](deployment.md) Compose file does this with `MARIADB_USER`.
- Keep the database on the **internal Docker network**; do not publish port 3306.
- Source DB credentials from **secrets/`_FILE` variables**, not inline environment values. See [PostgreSQL Security](../postgresql/security.md) for the same principles applied to a database backend, and [MySQL](../mysql/index.md).

### File Permissions

iTop needs write access only to specific directories; everything else should be read-only to the web-server user:

| Path | Access |
| ---- | ------ |
| `conf/` | Writable during setup; read-only afterwards is safest (the app reads `config-itop.php`) |
| `data/` | Writable — attachments, backups, temp |
| `env-production/` | Writable during setup/compile |
| `log/` | Writable |
| everything else | Read-only to `www-data` |

```bash
# Own the tree by the web user, then restrict
docker exec itop-app chown -R www-data:www-data /var/www/html
docker exec itop-app find /var/www/html -type f -exec chmod 640 {} \;
docker exec itop-app find /var/www/html -type d -exec chmod 750 {} \;
```

> [!TIP]
> Running the writable directories on separate volumes (as in [Deployment](deployment.md)) both persists data and makes it easy to keep the rest of the web root immutable — rebuild the image to update code, and the mounted `conf`/`data`/`env-production` carry state forward.

### Security Checklist

- [ ] iTop reached only through an HTTPS reverse proxy; app port not public
- [ ] `X-Forwarded-Proto https` forwarded; `app_root_url` set to the HTTPS URL; `secure_connection_required = true`
- [ ] `/setup/` and `/toolkit/` disabled or IP-restricted
- [ ] Strong auth (LDAP/SSO where possible); least-privilege profiles; dedicated API/cron accounts
- [ ] Dedicated DB user (not root); port 3306 internal-only; credentials from secrets
- [ ] Web root read-only except `conf`/`data`/`env-production`/`log`
- [ ] iTop, PHP, and the database kept patched to supported versions

## Navigation

[◄ Integration](integration.md) · [iTop Overview](index.md) · [Backup and Recovery ►](backup-recovery.md)
