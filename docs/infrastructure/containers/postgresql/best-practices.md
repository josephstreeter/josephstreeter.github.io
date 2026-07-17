---
title: "PostgreSQL Container Best Practices"
description: "Production best practices for containerized PostgreSQL — shared memory, PGDATA ownership, resource limits, autovacuum, and major-version upgrades"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: conceptual
ms.service: infrastructure
---

## Best Practices

### Container-Specific Gotchas

These trip up almost everyone running PostgreSQL in containers:

- **Shared memory (`/dev/shm`).** Docker gives a container 64 MB of `/dev/shm` by default, but PostgreSQL uses it for parallel query workers. Raise it or you'll see `could not resize shared memory segment` errors:

  ```yaml
  services:
    db:
      image: postgres:17
      shm_size: "256mb"        # or docker run --shm-size=256m
  ```

- **`PGDATA` on a bind mount.** Point `PGDATA` at a **subdirectory** of the mount (`/var/lib/postgresql/data/pgdata`) so `initdb` sees an empty directory even if the mount root has hidden files like `lost+found`.

- **Volume ownership.** The image runs as UID 999 (`postgres`). Bind-mounted host directories must be writable by that UID, or startup fails with permission errors. Named volumes avoid this.

- **Never run two servers on one data directory.** Pointing two containers at the same volume corrupts the database. For availability, use [replication](replication-ha.md), not a shared volume.

- **Env vars apply once.** `POSTGRES_PASSWORD`/`POSTGRES_DB` only take effect on first init. Later changes need SQL (`ALTER USER …`, `CREATE DATABASE …`).

### Resource Limits and Tuning

Set explicit limits and tune PostgreSQL to the **container's** memory, not the host's:

```yaml
services:
  db:
    image: postgres:17
    shm_size: "256mb"
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: 8G
    command:
      - "postgres"
      - "-c"
      - "shared_buffers=2GB"          # ~25% of the 8G limit
      - "-c"
      - "effective_cache_size=6GB"    # ~75%
      - "-c"
      - "maintenance_work_mem=512MB"
      - "-c"
      - "work_mem=16MB"               # conservative; per-operation
```

> [!WARNING]
> If PostgreSQL's memory settings exceed the container limit, the kernel **OOM-killer** terminates the `postgres` process — an abrupt, hard-to-diagnose crash. Leave headroom below the limit; `shared_buffers` + peak `work_mem × concurrent operations` + connection overhead must fit comfortably. See [Configuration and Tuning](configuration.md).

### Autovacuum and Maintenance

Autovacuum reclaims dead rows and updates planner statistics — do not disable it. For write-heavy tables, make it more aggressive rather than turning it off:

```ini
autovacuum = on
autovacuum_vacuum_scale_factor = 0.1      # vacuum after 10% of rows change
autovacuum_analyze_scale_factor = 0.05
# For a specific hot table:
-- ALTER TABLE events SET (autovacuum_vacuum_scale_factor = 0.02);
```

Watch `n_dead_tup` and `last_autovacuum` in `pg_stat_user_tables` ([Monitoring](monitoring.md)). Rising dead tuples with old vacuum times mean autovacuum can't keep up — tune it or the table will bloat.

### Data Integrity

- Initialize with **data checksums** (`POSTGRES_INITDB_ARGS: "--data-checksums"`) to detect silent storage corruption. This can only be set at cluster creation.
- Use durable storage; keep `fsync = on` and `full_page_writes = on` (the defaults). Disabling them risks corruption on crash — never do it on data you care about.

### Major-Version Upgrades

Data files are **not** compatible across major versions (16 → 17), so you cannot just change the image tag. Two paths:

**Dump and restore** (simplest, works everywhere; requires downtime proportional to data size):

```bash
# 1. Dump from the old version
docker exec pg16 pg_dumpall -U postgres > all.sql
# 2. Start a fresh new-version container on an empty volume
# 3. Restore
cat all.sql | docker exec -i pg17 psql -U postgres
```

**`pg_upgrade`** (fast, in-place; needs both binaries — use an image built for the transition or [`tianon/postgres-upgrade`](https://github.com/tianon/docker-postgres-upgrade)):

```bash
docker run --rm \
  -v pg16-data:/var/lib/postgresql/16/data \
  -v pg17-data:/var/lib/postgresql/17/data \
  tianon/postgres-upgrade:16-to-17
```

> [!IMPORTANT]
> Always **back up before upgrading** and test the upgrade in a copy first. Pin the major version in your image tag so an unrelated `latest` change never silently attempts to start a newer server on an older data directory (which fails to start).

### Operational Checklist

- [ ] Major version pinned in the image tag; minor updates applied
- [ ] Data on a named volume (or correctly-owned bind mount); `PGDATA` on a subdirectory
- [ ] `shm_size` raised for parallel queries
- [ ] Memory settings sized to the container limit with headroom (no OOM risk)
- [ ] `--data-checksums` enabled at init; `fsync`/`full_page_writes` on
- [ ] Autovacuum on and tuned for write-heavy tables
- [ ] Backups automated and **restore-tested** (see [Backup and Recovery](backup-recovery.md))
- [ ] Security hardening applied (see [Security](security.md))
- [ ] Monitoring and slow-query logging in place (see [Monitoring](monitoring.md))
- [ ] Upgrade procedure documented and rehearsed

## Navigation

[◄ Monitoring and Troubleshooting](monitoring.md) · [PostgreSQL Overview](index.md)
