---
title: Certbot Guide
description: Installing and using Certbot to automate Let's Encrypt certificates on Linux with Nginx, Apache, and standalone servers
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Certbot Guide

### Overview

[**Certbot**](https://certbot.eff.org/) is a free, open-source ACME client maintained by the [Electronic Frontier Foundation (EFF)](https://www.eff.org/). It is the most widely used tool for obtaining and automatically renewing [Let's Encrypt](https://letsencrypt.org/) certificates on Linux, BSD, and macOS. Certbot can configure popular web servers directly (Nginx and Apache) or simply obtain certificates for you to deploy however you like.

Certbot is written in Python and distributed through OS package managers and, preferably, as a self-contained **snap**. On installation it sets up an automatic renewal mechanism (a systemd timer or cron job) so certificates renew without intervention.

> [!NOTE]
> The EFF recommends installing Certbot via **snap** on most systems, because the snap package is always the latest version and bundles its dependencies. Distribution packages (`apt`, `dnf`) are convenient but are often older. This guide covers both.

### Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Certbot Plugins](#certbot-plugins)
- [Quick Start: Nginx](#quick-start-nginx)
- [Quick Start: Apache](#quick-start-apache)
- [Standalone and Webroot Modes](#standalone-and-webroot-modes)
- [DNS Validation and Wildcards](#dns-validation-and-wildcards)
- [Automatic Renewal](#automatic-renewal)
- [Deploy Hooks](#deploy-hooks)
- [Managing Certificates](#managing-certificates)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Prerequisites

- A Linux (or BSD/macOS) host with `sudo`/root access.
- A publicly resolvable DNS name pointing at the server (for HTTP validation), **or** API access to your DNS provider (for DNS validation).
- For **HTTP-01 validation**: inbound TCP port 80 reachable from the internet.
- For the Nginx/Apache plugins: the corresponding web server installed and running.
- Outbound HTTPS access to the ACME CA (Let's Encrypt endpoints).

> [!IMPORTANT]
> Certbot needs privileges to write certificates under `/etc/letsencrypt`, bind low ports during standalone validation, and reload the web server. Run it with `sudo` (or as root).

## Installation

### Recommended: snap (most distributions)

```bash
# 1. Ensure snapd is installed and up to date
sudo snap install core
sudo snap refresh core

# 2. Remove any distro-packaged certbot to avoid conflicts
sudo apt remove certbot     # Debian/Ubuntu
# sudo dnf remove certbot   # Fedora/RHEL

# 3. Install certbot from snap
sudo snap install --classic certbot

# 4. Symlink so 'certbot' is on PATH
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# 5. Verify
certbot --version
```

### Distribution packages

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install certbot python3-certbot-nginx python3-certbot-apache

# Fedora
sudo dnf install certbot python3-certbot-nginx python3-certbot-apache

# RHEL / CentOS / Rocky / Alma (enable EPEL first)
sudo dnf install epel-release
sudo dnf install certbot python3-certbot-nginx python3-certbot-apache

# Arch Linux
sudo pacman -S certbot certbot-nginx certbot-apache
```

> [!TIP]
> With the snap installation, web-server and DNS plugins are bundled or installed as snap "connections" rather than separate `python3-certbot-*` packages. To use a DNS plugin with the snap, install it and connect its plugin interface — see [DNS Validation and Wildcards](#dns-validation-and-wildcards).

## Certbot Plugins

Certbot's behavior is driven by two kinds of plugins: **authenticators** (prove domain control) and **installers** (configure the web server). Many plugins do both.

| Plugin | Authenticator | Installer | Use case |
| ------ | ------------- | --------- | -------- |
| `--nginx` | Yes | Yes | Nginx: obtain and auto-configure |
| `--apache` | Yes | Yes | Apache: obtain and auto-configure |
| `--standalone` | Yes | No | Certbot runs its own temporary web server on port 80/443 |
| `--webroot` | Yes | No | Serve challenge files from an existing web root; server keeps running |
| `--manual` | Yes | No | Manual or scripted HTTP/DNS challenge |
| `dns-<provider>` | Yes | No | DNS-01 validation via a provider API (wildcards) |

## Quick Start: Nginx

The Nginx plugin obtains a certificate and edits your Nginx configuration to use it, including an optional HTTP→HTTPS redirect.

```bash
# Obtain and install a certificate for one or more names
sudo certbot --nginx -d example.com -d www.example.com

# Obtain only (edit Nginx config yourself)
sudo certbot certonly --nginx -d example.com
```

Certbot prompts (first run) for an email address and to accept the terms of service, detects the matching `server` blocks, performs HTTP-01 validation, installs the certificate, and reloads Nginx.

> [!TIP]
> To skip the interactive prompts for automation, add `--non-interactive --agree-tos -m admin@example.com`. To automatically add the HTTP→HTTPS redirect, add `--redirect` (or `--no-redirect` to leave HTTP as-is).

## Quick Start: Apache

```bash
# Obtain and install for Apache, with redirect
sudo certbot --apache -d example.com -d www.example.com --redirect

# Obtain only, without touching Apache config
sudo certbot certonly --apache -d example.com
```

The Apache plugin edits your virtual host configuration to reference the new certificate and reloads Apache.

## Standalone and Webroot Modes

When you are not using the Nginx/Apache plugins — for example, securing a mail server, a load balancer, or an application that terminates TLS itself — use `certonly` with `standalone` or `webroot`.

**Standalone** — Certbot runs its own temporary listener. The port it needs (80 for HTTP-01) must be free, so stop any service using it first, or use a deploy/pre hook:

```bash
sudo certbot certonly --standalone \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
```

**Webroot** — Certbot writes the challenge file into an existing, already-running web server's document root under `/.well-known/acme-challenge/`. The server keeps serving traffic normally:

```bash
sudo certbot certonly --webroot \
    -w /var/www/example.com \
    -d example.com -d www.example.com \
    --non-interactive --agree-tos -m admin@example.com
```

Issued certificates and keys are written under `/etc/letsencrypt/live/<primary-domain>/`:

| File | Contents |
| ---- | -------- |
| `privkey.pem` | Private key |
| `cert.pem` | Server certificate only |
| `chain.pem` | Intermediate CA chain |
| `fullchain.pem` | Server certificate + chain (use this for most servers) |

> [!IMPORTANT]
> Point your service configuration at the files under `/etc/letsencrypt/live/<domain>/`, which are **symlinks** that always reference the current certificate. Do not copy the certificate elsewhere and reference the copy — the copy will not update on renewal. If a service needs the files in another location or format, use a [deploy hook](#deploy-hooks) to copy/convert them after each renewal.

## DNS Validation and Wildcards

Wildcard certificates (`*.example.com`) **require DNS-01 validation**. Certbot provides DNS plugins for many providers.

```bash
# Example: Cloudflare DNS plugin (distro package install)
sudo apt install python3-certbot-dns-cloudflare

# Store scoped API credentials, readable only by root
sudo install -m 600 /dev/null /root/.secrets/cloudflare.ini
sudo tee /root/.secrets/cloudflare.ini >/dev/null <<'EOF'
dns_cloudflare_api_token = YOUR_SCOPED_API_TOKEN
EOF

# Issue a wildcard certificate
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
    -d 'example.com' -d '*.example.com' \
    --non-interactive --agree-tos -m admin@example.com
```

For the **snap** installation, install and connect the DNS plugin instead:

```bash
sudo snap install certbot-dns-cloudflare
sudo snap connect certbot:plugin certbot-dns-cloudflare
```

### Amazon Route 53

The `dns-route53` plugin manages the `_acme-challenge` TXT record in an AWS Route 53 hosted zone, making it a common choice for workloads running on AWS.

```bash
# Install the Route 53 plugin
sudo apt install python3-certbot-dns-route53        # Debian/Ubuntu
# --- or, for the snap installation ---
sudo snap install certbot-dns-route53
sudo snap set certbot trust-plugin-with-root=ok
sudo snap connect certbot:plugin certbot-dns-route53

# Issue a wildcard certificate via Route 53
sudo certbot certonly \
    --dns-route53 \
    -d 'example.com' -d '*.example.com' \
    --non-interactive --agree-tos -m admin@example.com

# Optionally wait longer for DNS propagation before validation
sudo certbot certonly \
    --dns-route53 --dns-route53-propagation-seconds 30 \
    -d '*.example.com' \
    --non-interactive --agree-tos -m admin@example.com
```

The Route 53 plugin authenticates with the standard [AWS SDK credential chain](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html), so you do not pass a credentials file on the command line. Provide credentials by any of:

- An **IAM role** attached to the EC2 instance / ECS task / Lambda (preferred — no long-lived keys).
- A credentials file at `/root/.aws/config` (or `~/.aws/config` for the user running Certbot).
- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`).

```ini
# /root/.aws/config  (chmod 600, owned by root)
[default]
aws_access_key_id = AKIAEXAMPLE
aws_secret_access_key = EXAMPLESECRETKEY
```

The IAM principal needs permission to read hosted zones and change the challenge record. Scope it as tightly as possible:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListHostedZones",
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ChangeChallengeRecords",
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
    }
  ]
}
```

> [!TIP]
> Prefer an **IAM role** over static access keys wherever the machine supports it (EC2 instance profile, ECS task role, IRSA on EKS). Roles supply short-lived, automatically rotated credentials, eliminating the long-lived secret that a `~/.aws/config` file would otherwise hold.

The same credential-handling discipline applies to every DNS provider, not just Route 53.

> [!WARNING]
> DNS plugin credentials grant API access to your DNS zone. For providers using a credentials file (such as Cloudflare), create a **scoped** API token limited to editing records for the target zone (never a global API key), store the file with `chmod 600` owned by root, and keep it out of source control — Certbot warns if the credentials file has overly permissive permissions. For Route 53, restrict the IAM policy to the specific hosted zone as shown above.

Providers without a plugin can use `--manual --preferred-challenges dns` with a `--manual-auth-hook` / `--manual-cleanup-hook` script that calls your DNS API. Purely interactive manual DNS mode cannot renew automatically.

## Automatic Renewal

Let's Encrypt certificates are valid for 90 days; Certbot renews them when they are within 30 days of expiry.

Both the snap and modern distribution packages install an automatic renewal task — a **systemd timer** (`certbot.timer`) or a cron entry (`/etc/cron.d/certbot`) — so you usually do not need to configure anything.

```bash
# Check the systemd timer (snap / systemd distros)
systemctl list-timers | grep certbot
systemctl status certbot.timer

# Test that renewal works without actually renewing (highly recommended)
sudo certbot renew --dry-run

# Force a real renewal now (testing only — mind rate limits)
sudo certbot renew --force-renewal
```

The renewal command reads each certificate's saved configuration from `/etc/letsencrypt/renewal/<domain>.conf` and repeats the exact process (same domains, plugin, and hooks) used at issuance.

> [!IMPORTANT]
> Always run `sudo certbot renew --dry-run` after setup and after any change to your web server or hooks. It exercises the full renewal path against the **staging** environment without consuming production rate limits, catching problems before a real renewal is due.

## Deploy Hooks

Hooks let Certbot run commands around renewal — essential for reloading services or distributing certificates to software that does not read `/etc/letsencrypt` directly.

| Hook | When it runs |
| ---- | ------------ |
| `--pre-hook` | Before validation (e.g. stop a service to free port 80 for standalone) |
| `--deploy-hook` | Only after a certificate is successfully renewed |
| `--post-hook` | After the attempt, whether or not renewal happened |

```bash
# Attach a deploy hook at issuance time (saved into the renewal config)
sudo certbot certonly --standalone -d example.com \
    --deploy-hook 'systemctl reload nginx'

# Global hooks for all certificates: drop scripts here (must be executable)
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh >/dev/null <<'EOF'
#!/bin/bash
systemctl reload nginx
systemctl reload postfix
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh
```

Scripts in `/etc/letsencrypt/renewal-hooks/{pre,deploy,post}/` run automatically for every certificate. A deploy hook can read `$RENEWED_LINEAGE` (the `/etc/letsencrypt/live/<domain>` path) and `$RENEWED_DOMAINS` to know what changed.

> [!TIP]
> Use a **deploy hook** (not post-hook) to reload services or convert formats, so the work only happens when a certificate actually changed. For example, build a PKCS#12 for a Java application or copy `fullchain.pem`/`privkey.pem` to a chroot after each renewal.

## Managing Certificates

```bash
# List all certificates Certbot manages, with expiry dates
sudo certbot certificates

# Revoke a certificate (e.g. key compromise), then delete its config
sudo certbot revoke --cert-name example.com --reason keycompromise
sudo certbot delete --cert-name example.com

# Expand or change the domains on an existing certificate
sudo certbot --nginx -d example.com -d www.example.com -d api.example.com

# Switch a certificate to a different key type (RSA <-> ECDSA)
sudo certbot certonly --key-type ecdsa -d example.com
```

## Troubleshooting

| Symptom | Likely cause | Resolution |
| ------- | ------------ | ---------- |
| "Timeout during connect" on HTTP-01 | Port 80 blocked or DNS wrong | Open port 80 to the internet; confirm the domain's public DNS points at this host |
| "Too many certificates already issued" | Production rate limit hit | Use `--dry-run` / staging while testing; wait for the limit window to reset |
| Renewal succeeds but site serves old cert | Service not reloaded | Add a `--deploy-hook` that reloads the web server |
| `nginx`/`apache` plugin can't find the vhost | Server block not matched | Use `certonly` and reference the files manually, or fix the server_name/ServerName |
| Wildcard request rejected on HTTP | Wildcards need DNS-01 | Use a `--dns-<provider>` plugin |
| Credentials file permission warning | File world-readable | `chmod 600` the credentials file, owned by root |

```bash
# Certbot logs (most recent first)
sudo tail -n 100 /var/log/letsencrypt/letsencrypt.log

# Confirm a challenge TXT record is published (DNS-01)
dig +short TXT _acme-challenge.example.com

# Inspect an installed certificate's dates and SANs
sudo openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -dates -text | grep -A1 "Subject Alternative Name"
```

> [!TIP]
> Add `--test-cert` (equivalent to using the staging server) to any issuance command to iterate without touching production rate limits. Delete the resulting test certificate with `certbot delete` before requesting the real one.

## Best Practices

- **Install via snap** for the newest version and automatic updates, unless a policy requires distro packages.
- **Run `--dry-run` after every change** to confirm renewal still works before a real one is due.
- **Reference `/etc/letsencrypt/live/<domain>/` symlinks**, never copies, so services always see the current certificate.
- **Use deploy hooks** to reload services and convert formats, so work happens only on actual renewal.
- **Provide a contact email** (`-m`) so Let's Encrypt can warn you if renewal stops.
- **Scope DNS credentials** to a single zone and `chmod 600` the credentials file.
- **Test against staging** (`--test-cert`) before production to avoid burning rate limits.
- **Monitor expiry independently** of Certbot so a broken timer does not silently become an outage.
- **Back up `/etc/letsencrypt`** — it holds account keys, certificates, private keys, and renewal configuration.

## Related Topics

- [ACME Protocol Overview](index.md)
- [win-acme Guide](win-acme.md)
- [Certificate Management and PKI](../index.md)
- [OpenSSL Guide](../openssl/index.md)

## Additional Resources

- [Certbot Official Site and Instructions](https://certbot.eff.org/)
- [Certbot User Guide](https://eff-certbot.readthedocs.io/en/stable/)
- [Certbot DNS Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
