---
title: "PostgreSQL Monitoring and Troubleshooting"
description: "Monitoring containerized PostgreSQL — logging, pg_stat views, pg_stat_statements, the Prometheus exporter, health checks, and common issues"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Monitoring and Troubleshooting

### Logging

The official image logs to stdout by default, so `docker logs` captures server output. Tune what gets logged in `postgresql.conf`:

```ini
# Log slow queries (a top diagnostic) — statements over 500 ms
log_min_duration_statement = 500          # ms; 0 = log all, -1 = off

log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on                        # log when a session waits on a lock
log_temp_files = 0                         # log temp files (spills over work_mem)
log_line_prefix = '%m [%p] %q%u@%d '       # time, pid, user@db
log_autovacuum_min_duration = 0            # log autovacuum activity
```

```bash
docker logs -f postgres
# Filter for slow queries
docker logs postgres 2>&1 | grep "duration:"
```

> [!TIP]
> `log_min_duration_statement` is the single most useful setting for finding performance problems — it surfaces the exact slow statements without the overhead of logging everything. Start at a few hundred milliseconds and lower it as you tune.

### Live Views (pg_stat_*)

PostgreSQL exposes rich runtime statistics as system views:

```sql
-- Current activity: who is connected and what they're running
SELECT pid, usename, state, wait_event_type, wait_event,
       now() - query_start AS runtime, query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY runtime DESC;

-- Database-wide counters: commits, rollbacks, cache hit ratio, deadlocks
SELECT datname, xact_commit, xact_rollback, blks_hit, blks_read,
       round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS cache_hit_pct
FROM pg_stat_database
WHERE datname = 'appdb';

-- Table access patterns: seq scans vs index scans, dead tuples (bloat/vacuum)
SELECT relname, seq_scan, idx_scan, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Replication lag (on the primary)
SELECT client_addr, state, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;
```

### Query Performance (pg_stat_statements)

The `pg_stat_statements` extension aggregates execution stats per normalized query — the best way to find your most expensive queries. It must be preloaded (a restart-level setting):

```ini
# postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 queries by total time
SELECT round(total_exec_time::numeric, 1) AS total_ms,
       calls,
       round(mean_exec_time::numeric, 2) AS mean_ms,
       query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Metrics (Prometheus)

Export metrics for Prometheus/Grafana with [`postgres_exporter`](https://github.com/prometheus-community/postgres_exporter) as a sidecar:

```yaml
services:
  postgres-exporter:
    image: quay.io/prometheuscommunity/postgres-exporter:latest
    environment:
      DATA_SOURCE_NAME: "postgresql://exporter:secret@db:5432/appdb?sslmode=disable"
    ports:
      - "9187:9187"
    depends_on: [ db ]
```

Grant the exporter a limited monitoring role:

```sql
CREATE ROLE exporter LOGIN PASSWORD 'secret';
GRANT pg_monitor TO exporter;      -- built-in role for read-only stats access
```

It exposes connection counts, transaction rates, cache hit ratio, replication lag, and more — pair with a PostgreSQL Grafana dashboard.

### Health Checks

Use `pg_isready` for container/orchestrator health checks — it tests that the server accepts connections without running a query:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s        # grace period during initial startup/recovery
```

### Troubleshooting Guide

| Symptom | Likely cause | What to check |
| ------- | ------------ | ------------- |
| **Container exits immediately** | `POSTGRES_PASSWORD` unset, or non-empty/incompatible data dir | `docker logs`; ensure the password env is set and the volume matches the image's major version |
| **`FATAL: password authentication failed`** | Wrong credentials or `pg_hba.conf` method | Verify user/password; check `pg_hba.conf` order (first match wins) |
| **`FATAL: sorry, too many clients already`** | `max_connections` exhausted | Add a pooler ([PgBouncer](replication-ha.md)); find leaks in `pg_stat_activity` |
| **`could not resize shared memory segment` / parallel query errors** | `/dev/shm` too small | Set `shm_size` (e.g. `256mb`) on the container ([Best Practices](best-practices.md)) |
| **Container OOM-killed** | `work_mem`/`shared_buffers` too high for the memory limit | Lower memory settings; raise the limit; check for a runaway query |
| **Slow queries / high CPU** | Missing indexes, plan regressions, bloat | `pg_stat_statements`; `EXPLAIN (ANALYZE, BUFFERS)`; check `n_dead_tup` and autovacuum |
| **Disk filling up** | WAL not archived/recycled, table bloat, or stalled replica | Check `pg_wal` size, `archive_command` success, replication slots holding WAL |

```bash
# Interactive session for diagnostics
docker exec -it postgres psql -U postgres -d appdb

# Inspect a specific query's plan
docker exec -it postgres psql -U appuser -d appdb \
  -c "EXPLAIN (ANALYZE, BUFFERS) SELECT ...;"

# Data directory / WAL size
docker exec postgres du -sh /var/lib/postgresql/data /var/lib/postgresql/data/pg_wal
```

> [!IMPORTANT]
> Unbounded WAL growth filling the disk is often a **stale replication slot** — a replica (or forgotten slot) that stopped consuming WAL, so PostgreSQL retains it forever. Check `SELECT * FROM pg_replication_slots WHERE active = false;` and drop orphaned slots.

## Navigation

[◄ Security](security.md) · [PostgreSQL Overview](index.md) · [Best Practices ►](best-practices.md)
