---
title: "PostgreSQL Backup and Recovery"
description: "Backing up containerized PostgreSQL — logical dumps with pg_dump/pg_restore, physical base backups, and point-in-time recovery (PITR)"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Backup and Recovery

There are two families of PostgreSQL backup, and a robust setup often uses both:

| Type | Tool | Captures | Restore granularity |
| ---- | ---- | -------- | ------------------- |
| **Logical** | `pg_dump` / `pg_dumpall` | SQL statements to recreate data | Whole database or specific tables; portable across versions/architectures |
| **Physical** | `pg_basebackup` + WAL | Byte-level copy of the data directory | Whole cluster; enables point-in-time recovery |

> [!IMPORTANT]
> A backup you have never restored is not a backup. **Test restores regularly** into a throwaway container. Also back up **globals** (roles, tablespaces) with `pg_dumpall --globals-only` — a plain `pg_dump` of one database does not include cluster-wide roles.

### Logical Backups (pg_dump / pg_restore)

`pg_dump` exports a single database. Use the **custom** format (`-Fc`) — it is compressed and works with `pg_restore` for selective, parallel restores.

```bash
# Dump one database to a compressed custom-format file
docker exec postgres pg_dump -U appuser -d appdb -Fc -f /tmp/appdb.dump
docker cp postgres:/tmp/appdb.dump ./appdb-$(date +%F).dump

# Or stream directly to a file on the host (no temp file in the container)
docker exec postgres pg_dump -U appuser -d appdb -Fc | cat > appdb-$(date +%F).dump

# Cluster-wide roles/tablespaces (run alongside per-database dumps)
docker exec postgres pg_dumpall -U postgres --globals-only > globals-$(date +%F).sql
```

Restore into a fresh database:

```bash
# Recreate roles first (if restoring to a clean cluster)
cat globals.sql | docker exec -i postgres psql -U postgres

# Create the target DB, then restore (4 parallel jobs)
docker exec postgres createdb -U postgres appdb
cat appdb.dump | docker exec -i postgres pg_restore -U postgres -d appdb -j4

# Restore only specific tables
pg_restore -U postgres -d appdb -t customers -t orders appdb.dump
```

> [!TIP]
> Use `-Fc` (custom) or `-Fd` (directory, supports parallel **dump** with `-j`) rather than a plain `.sql` file. Plain SQL is human-readable but restores single-threaded and can't do selective restore. The directory format is best for very large databases.

### Automated Logical Backups

A simple scheduled backup sidecar/cron on the host:

```bash
#!/usr/bin/env bash
# pg-backup.sh — run from cron on the host
set -euo pipefail
STAMP=$(date +%F_%H%M)
DEST=/backups
docker exec postgres pg_dump -U appuser -d appdb -Fc > "$DEST/appdb-$STAMP.dump"
docker exec postgres pg_dumpall -U postgres --globals-only > "$DEST/globals-$STAMP.sql"
# Retention: delete dumps older than 14 days
find "$DEST" -name 'appdb-*.dump' -mtime +14 -delete
```

For a container-native option, images like [`prodrigestivill/postgres-backup-local`](https://github.com/prodrigestivill/docker-postgres-backup-local) run scheduled `pg_dump` with rotation as a companion service.

### Physical Backups (pg_basebackup)

A base backup copies the entire data directory — the basis for replicas and PITR. The server must allow replication connections (`wal_level=replica` or higher, and a replication-capable role):

```bash
# Take a base backup into a host directory (tar + gzip)
docker exec postgres pg_basebackup \
  -U replicator -h localhost -D /tmp/basebackup -Ft -z -P -Xs
docker cp postgres:/tmp/basebackup ./basebackup-$(date +%F)
```

| Flag | Meaning |
| ---- | ------- |
| `-Ft` | tar format output |
| `-z` | gzip-compress |
| `-P` | show progress |
| `-Xs` | stream WAL during the backup so it is self-consistent |

### Point-in-Time Recovery (PITR)

PITR = a base backup **plus** a continuous archive of WAL segments, letting you restore to any moment (e.g. just before an accidental `DROP TABLE`). Enable WAL archiving in `postgresql.conf`:

```ini
wal_level = replica
archive_mode = on
# Copy each completed WAL segment to an archive volume
archive_command = 'test ! -f /wal_archive/%f && cp %p /wal_archive/%f'
```

Mount `/wal_archive` on a durable volume (ideally off-host / object storage). To recover:

1. Restore the base backup into a fresh data directory.
2. Provide a `restore_command` and a recovery target, then create a `recovery.signal` file:

```ini
# postgresql.conf (or postgresql.auto.conf) for the recovery instance
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '2026-07-17 14:30:00'
```

```bash
# Signal recovery mode (PostgreSQL 12+; replaces the old recovery.conf)
touch /var/lib/postgresql/data/recovery.signal
```

PostgreSQL replays WAL up to the target and then opens the database.

> [!NOTE]
> For production PITR, use a dedicated tool rather than hand-rolled `archive_command` scripts. [pgBackRest](https://pgbackrest.org/) and [Barman](https://pgbarman.org/) handle compression, encryption, retention, parallel restore, and object-storage (S3) targets — and both run well alongside containers.

### Volume Snapshots

Storage-level snapshots (LVM, ZFS, cloud block-storage) can back up the whole data volume, but only produce a **consistent** backup if taken atomically while PostgreSQL is quiescent or via `pg_start_backup()`/`pg_stop_backup()` (low-level API) or `pg_basebackup`. A crash-consistent snapshot of a running cluster usually recovers, but treat `pg_dump`/`pg_basebackup` as the authoritative methods.

## Navigation

[◄ Configuration and Tuning](configuration.md) · [PostgreSQL Overview](index.md) · [Replication and High Availability ►](replication-ha.md)
