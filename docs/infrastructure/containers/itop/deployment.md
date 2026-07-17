---
title: "iTop Deployment"
description: "Deploying iTop with Docker Compose and MariaDB — images, volumes, the first-run setup wizard, and the cron scheduler"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Deployment

iTop deploys as two services — the PHP application and a MySQL/MariaDB database — plus a scheduler that runs `cron.php`. A first-run **setup wizard** creates the configuration file and database schema.

### Images

Combodo does not publish a single canonical Docker image, so options are:

1. **Build your own** from a `php:8.1-apache` base with the iTop release extracted into the web root (most control; recommended for production).
2. **A maintained community image** (for example [`vbkunin/itop`](https://hub.docker.com/r/vbkunin/itop)) to get started quickly — audit what it bundles and its update cadence.

A minimal build-your-own image:

```dockerfile
# Dockerfile
FROM php:8.1-apache

# iTop's required PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev libpng-dev libldap2-dev libxml2-dev graphviz unzip && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install mysqli gd zip ldap soap opcache && \
    a2enmod rewrite && rm -rf /var/lib/apt/lists/*

# Extract the iTop release into the web root
ADD https://sourceforge.net/projects/itop/files/itop/3.2.0/iTop-3.2.0.zip /tmp/itop.zip
RUN unzip -q /tmp/itop.zip -d /var/www/html && \
    mv /var/www/html/web/* /var/www/html/ 2>/dev/null || true && \
    chown -R www-data:www-data /var/www/html

# Recommended PHP settings for iTop
RUN { \
      echo 'memory_limit=256M'; \
      echo 'max_execution_time=300'; \
      echo 'upload_max_filesize=32M'; \
      echo 'post_max_size=32M'; \
    } > /usr/local/etc/php/conf.d/itop.ini
```

> [!NOTE]
> `graphviz` is needed for iTop's impact-analysis diagrams, and the `mysqli`, `ldap`, `soap`, `gd`, and `zip` PHP extensions are required or strongly recommended. Match the iTop version in the `ADD` URL to a release that supports your PHP version (iTop 3.2 needs PHP 8.1+).

### Docker Compose

```yaml
# docker-compose.yml
services:
  db:
    image: mariadb:11
    container_name: itop-db
    environment:
      MARIADB_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MARIADB_DATABASE: itop
      MARIADB_USER: itop
      MARIADB_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - itop-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    secrets: [ db_root_password, db_password ]

  itop:
    build: .
    container_name: itop-app
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - itop-conf:/var/www/html/conf          # config-itop.php (created by the wizard)
      - itop-data:/var/www/html/data          # attachments, backups, dumps
      - itop-env:/var/www/html/env-production # compiled data model
      - itop-log:/var/www/html/log
    ports:
      - "127.0.0.1:8080:80"                    # front with a reverse proxy for TLS
    restart: unless-stopped

  cron:
    build: .
    container_name: itop-cron
    depends_on: [ itop ]
    volumes:
      - itop-conf:/var/www/html/conf
      - itop-data:/var/www/html/data
      - itop-env:/var/www/html/env-production
      - itop-log:/var/www/html/log
    # Run iTop's background task scheduler every minute
    entrypoint: >
      sh -c 'while :; do
        php /var/www/html/webservices/cron.php --auth_user=admin --auth_pwd=$$(cat /run/secrets/itop_admin_pwd) >> /var/www/html/log/cron.log 2>&1;
        sleep 60; done'
    restart: unless-stopped
    secrets: [ itop_admin_pwd ]

volumes:
  itop-db:
  itop-conf:
  itop-data:
  itop-env:
  itop-log:

secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt
  itop_admin_pwd:
    file: ./secrets/itop_admin_pwd.txt
```

> [!IMPORTANT]
> Persist the three writable iTop directories on volumes: **`conf/`** (holds `config-itop.php`), **`data/`** (attachments and backups), and **`env-production/`** (the compiled data model). Losing `conf/` or `env-production/` means re-running setup; losing `data/` loses attachments. The database volume holds everything else.

### The Setup Wizard

On first launch, iTop serves an interactive installer:

1. Browse to `http://<host>:8080/setup/` (via the reverse proxy in production).
2. Accept the license and let it run the **prerequisites check** — it flags any missing PHP extension or setting (fix these in the image, not by hand in a running container).
3. Choose **Install a new iTop** (or upgrade an existing one).
4. Enter the **database connection**: host `db`, the `itop` user and password, and database name `itop`.
5. Create the **iTop administrator** account (username/password).
6. Pick the **language, ITIL modules, and sample data** (skip sample data for production).
7. Setup writes `conf/production/config-itop.php` and builds the schema.

```bash
# Watch the app come up and confirm the DB is reachable
docker compose up -d
docker logs -f itop-app
docker exec itop-app php -r "echo phpversion();"
```

> [!WARNING]
> After installation, iTop **locks the setup wizard** so it cannot be re-run by an anonymous visitor. Keep it that way — never leave `/setup/` reachable from untrusted networks. Re-running setup (for upgrades) requires deliberately re-enabling it (see [Backup and Recovery](backup-recovery.md)).

### Verifying the Deployment

```bash
# Application reachable
curl -I http://localhost:8080/

# Database schema present
docker exec itop-db mariadb -uitop -p"$(cat secrets/db_password.txt)" \
  -e "SHOW TABLES;" itop | head

# Cron is running background tasks
docker logs itop-cron --tail 20
```

## Navigation

[◄ Overview](index.md) · [iTop Overview](index.md) · [Configuration ►](configuration.md)
