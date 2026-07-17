---
title: "PostgreSQL Configuration and Tuning"
description: "Configuring containerized PostgreSQL — passing postgresql.conf and pg_hba.conf, key tuning parameters, and building a custom image"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Configuration and Tuning

PostgreSQL reads two main files from its data directory: `postgresql.conf` (server settings) and `pg_hba.conf` (client authentication — see [Security](security.md)). In a container you don't edit these by hand on a running server; instead you provide them at deploy time. There are three approaches.

### Method 1 — Command-Line Overrides (simplest)

Pass settings as `-c` flags via the container `command`. Good for a handful of tunables:

```yaml
services:
  db:
    image: postgres:17
    command:
      - "postgres"
      - "-c"
      - "shared_buffers=512MB"
      - "-c"
      - "max_connections=100"
      - "-c"
      - "log_min_duration_statement=500ms"
    environment:
      POSTGRES_PASSWORD: changeme
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

### Method 2 — Mount a Custom postgresql.conf

Generate a tuned config (e.g. with [PGTune](https://pgtune.leopard.in.ua/)), mount it, and tell PostgreSQL to use it:

```yaml
services:
  db:
    image: postgres:17
    command: ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
    environment:
      POSTGRES_PASSWORD: changeme
    volumes:
      - ./config/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      - ./config/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

Point `pg_hba.conf` at the mounted file inside `postgresql.conf`:

```ini
# config/postgresql.conf (excerpt)
hba_file = '/etc/postgresql/pg_hba.conf'
listen_addresses = '*'
```

> [!TIP]
> Keep the whole config file, not a fragment — `config_file` replaces the default entirely. Alternatively, keep the defaults and drop overrides into a `conf.d` directory referenced with `include_dir 'conf.d'`, which layers cleanly on top of the image defaults.

### Method 3 — Custom Image

Bake configuration and extensions into a derived image for reproducible builds:

```dockerfile
FROM postgres:17
# Install an extension package (example: pgvector)
RUN apt-get update && apt-get install -y --no-install-recommends \
        postgresql-17-pgvector && rm -rf /var/lib/apt/lists/*
# Ship a tuned config
COPY postgresql.conf /etc/postgresql/postgresql.conf
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
```

### Key Tuning Parameters

Defaults are conservative. Size the memory parameters to the **container's** memory limit, not the host's. A rough starting point for a dedicated database container:

| Parameter | Rule of thumb | What it controls |
| --------- | ------------- | ---------------- |
| `shared_buffers` | ~25% of container RAM | PostgreSQL's own page cache |
| `effective_cache_size` | ~50–75% of RAM | Planner hint for total cache (PG + OS); doesn't allocate memory |
| `work_mem` | (RAM × 0.25) / max_connections, per sort | Memory per sort/hash **operation** — multiplied by concurrent operations, so be conservative |
| `maintenance_work_mem` | 256 MB–1 GB | Memory for `VACUUM`, `CREATE INDEX`, etc. |
| `max_connections` | 100–200; use a pooler beyond that | Concurrent connections (each costs memory) |
| `wal_buffers` | 16 MB (or -1 = auto) | Write-ahead log buffer |
| `checkpoint_completion_target` | 0.9 | Spreads checkpoint I/O to smooth latency |
| `random_page_cost` | 1.1 on SSD/NVMe (4 default = spinning disk) | Planner's cost of random I/O |
| `effective_io_concurrency` | 200 on SSD | Concurrent I/O the storage can handle |

> [!WARNING]
> `work_mem` is allocated **per operation, per connection** — a single query can use several multiples of it, and many connections multiply that further. Setting it too high invites out-of-memory kills (the container OOM-killer will terminate PostgreSQL). Raise it cautiously, or set it per-session for known heavy queries.

### Applying and Inspecting Changes

Many parameters reload without a restart; some (like `shared_buffers`, `max_connections`) require a full restart.

```bash
# Reload config (SIGHUP) — applies parameters that don't need a restart
docker exec postgres psql -U postgres -c "SELECT pg_reload_conf();"

# Restart for parameters that require it
docker restart postgres

# Check a setting's current value and whether it needs a restart
docker exec -it postgres psql -U postgres -c "SHOW shared_buffers;"
docker exec -it postgres psql -U postgres -c \
  "SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('shared_buffers','work_mem','max_connections');"
```

The `context` column tells you how a change takes effect: `postmaster` = restart required, `sighup` = reload, `user`/`superuser` = per-session.

### Extensions

Enable extensions per database with `CREATE EXTENSION` (the extension's files must be present in the image):

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;   -- query performance stats
CREATE EXTENSION IF NOT EXISTS pgcrypto;             -- cryptographic functions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";          -- UUID generation
```

`pg_stat_statements` also needs to be preloaded via `shared_preload_libraries` (a restart-level setting) — see [Monitoring](monitoring.md).

## Navigation

[◄ Deployment](deployment.md) · [PostgreSQL Overview](index.md) · [Backup and Recovery ►](backup-recovery.md)
