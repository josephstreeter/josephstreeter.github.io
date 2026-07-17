---
title: "iTop Backup, Recovery, and Upgrades"
description: "Backing up and restoring iTop — the database, configuration, and attachments — plus safely upgrading iTop in containers"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Backup, Recovery, and Upgrades

### What to Back Up

A complete iTop backup has three parts — all are needed for a full restore:

| Component | Where | Contents |
| --------- | ----- | -------- |
| **Database** | MySQL/MariaDB (`itop-db` volume) | All CIs, tickets, users, history — the bulk of your data |
| **Configuration** | `conf/` (`itop-conf` volume) | `config-itop.php` — DB connection, settings, LDAP |
| **Attachments & data** | `data/` (`itop-data` volume) | Uploaded files and iTop-generated backups |
| **Compiled model** | `env-production/` (`itop-env` volume) | Reproducible by re-running setup, but backing it up speeds recovery |

> [!IMPORTANT]
> The database alone is not a complete backup — without `config-itop.php` (DB credentials, URL, LDAP) and the attachments in `data/`, a restore is incomplete. Back up the database **and** the config/data volumes together, as a set.

### iTop's Built-in Backup

iTop can back up its own database and configuration from **Admin tools → Backup** (or on a schedule via the cron scheduler if the Combodo backup module is enabled). Backups land in `data/backups/` (the `itop-data` volume). This is convenient but still lives on the same host — copy it off-box.

### Database Backup (mysqldump)

The authoritative database backup is a `mysqldump` of the iTop schema:

```bash
# Dump the iTop database to a compressed file on the host
docker exec itop-db sh -c \
  'exec mariadb-dump -uitop -p"$MARIADB_PASSWORD" --single-transaction --quick itop' \
  | gzip > itop-db-$(date +%F).sql.gz

# Also copy the config and attachments volumes
docker run --rm -v itop-conf:/conf -v itop-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/itop-files-$(date +%F).tgz -C / conf data
```

`--single-transaction` gives a consistent dump of InnoDB tables without locking the application.

### Automated Backup

```bash
#!/usr/bin/env bash
# itop-backup.sh — run from host cron
set -euo pipefail
DEST=/backups; STAMP=$(date +%F_%H%M)
docker exec itop-db sh -c 'exec mariadb-dump -uitop -p"$MARIADB_PASSWORD" --single-transaction --quick itop' \
  | gzip > "$DEST/itop-db-$STAMP.sql.gz"
docker run --rm -v itop-conf:/conf -v itop-data:/data -v "$DEST":/backup alpine \
  tar czf "/backup/itop-files-$STAMP.tgz" -C / conf data
find "$DEST" -name 'itop-*' -mtime +14 -delete       # 14-day retention
```

### Restore

```bash
# 1. Restore the database into a running (empty) DB container
zcat itop-db-2026-07-17.sql.gz | \
  docker exec -i itop-db sh -c 'exec mariadb -uitop -p"$MARIADB_PASSWORD" itop'

# 2. Restore the config and attachments volumes
docker run --rm -v itop-conf:/conf -v itop-data:/data -v "$PWD":/backup alpine \
  tar xzf /backup/itop-files-2026-07-17.tgz -C /

# 3. Restart the app so it reloads config
docker compose restart itop cron
```

If `config-itop.php` came from a different hostname, update `app_root_url` and `db_host` for the new environment before starting. Always **test restores** into a throwaway stack.

## Upgrading iTop

iTop upgrades run the **setup wizard in upgrade mode**, which migrates the database schema and recompiles the data model. In a container world the code lives in the image, so the flow is:

1. **Back up first** — database + `conf`/`data` volumes (see above). Non-negotiable.
2. **Build a new image** with the target iTop version (bump the release in your `Dockerfile`), keeping the same `conf`, `data`, and `env-production` volumes.
3. **Re-enable setup** if it was locked, from a trusted network only.
4. **Run the upgrade wizard** at `/setup/` — choose *Upgrade an existing instance*; it detects the existing DB, applies schema migrations, and rebuilds `env-production/`.
5. **Verify** the version and that background tasks resume, then **disable setup** again.

```bash
# After editing the Dockerfile to the new iTop version:
docker compose build itop cron
docker compose up -d
# Complete the upgrade via the /setup/ wizard, then re-lock it
```

> [!WARNING]
> Match the **PHP and MySQL/MariaDB versions** to the iTop release you're upgrading to — a new iTop major may require a newer PHP (e.g. iTop 3.2 needs PHP 8.1+). Upgrade the base image accordingly, and rehearse the whole upgrade on a **copy of production** first, since schema migrations are hard to reverse on a live ticketing system.

### Migration / Moving Environments

To clone production to staging (or move hosts): restore the database dump and the `conf`/`data` volumes into the new stack, then edit `config-itop.php` (`app_root_url`, `db_host`, LDAP) for the new environment before first start.

## Navigation

[◄ Security](security.md) · [iTop Overview](index.md) · [Monitoring and Troubleshooting ►](monitoring.md)
