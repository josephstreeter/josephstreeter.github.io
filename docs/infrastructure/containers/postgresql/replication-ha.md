---
title: "PostgreSQL Replication and High Availability"
description: "Streaming replication, connection pooling with PgBouncer, and high-availability options (Patroni, Kubernetes operators) for containerized PostgreSQL"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Replication and High Availability

PostgreSQL replicates by shipping its write-ahead log (WAL) from a **primary** to one or more **replicas**. Replicas can serve read-only queries (read scaling) and stand ready for promotion if the primary fails (high availability).

| Mode | Behavior |
| ---- | -------- |
| **Asynchronous streaming** (default) | Primary doesn't wait for replicas; tiny risk of losing the last transactions on failover. Lowest latency. |
| **Synchronous streaming** | Primary waits for at least one replica to confirm before committing; no data loss on failover, higher commit latency. |
| **Logical replication** | Replicates selected tables via publish/subscribe; enables cross-version and partial replication. |

### Streaming Replication with Docker Compose

**1. Prepare the primary.** Set replication parameters and create a replication role:

```ini
# primary postgresql.conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 512MB          # retain WAL so a lagging replica can catch up
hot_standby = on
```

```sql
-- on the primary
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_secret';
```

```ini
# primary pg_hba.conf — allow the replica to connect for replication
host    replication    replicator    10.0.0.0/8    scram-sha-256
```

**2. Seed and start the replica.** A replica is initialized from a base backup of the primary:

```bash
# In the replica container, clone the primary's data directory
pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data \
  -Fp -Xs -P -R
# -R writes standby.signal + primary_conninfo automatically
```

The `-R` flag creates `standby.signal` and sets `primary_conninfo`, so the replica starts following the primary on boot. A minimal Compose sketch:

```yaml
services:
  primary:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: changeme
    volumes:
      - primary-data:/var/lib/postgresql/data
      - ./primary/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      - ./primary/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
    command: ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

  replica:
    image: postgres:17
    depends_on: [ primary ]
    environment:
      PGPASSWORD: repl_secret
    volumes:
      - replica-data:/var/lib/postgresql/data
    # Entrypoint should pg_basebackup from "primary" on first start, then run postgres
    # (use an init script or a small wrapper image)

volumes:
  primary-data:
  replica-data:
```

Verify replication health:

```sql
-- on the primary: see connected replicas and their lag
SELECT client_addr, state, sent_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;

-- on the replica: confirm it is in recovery
SELECT pg_is_in_recovery();          -- true
```

For zero-data-loss commits, make one replica synchronous on the primary:

```ini
synchronous_standby_names = 'FIRST 1 (replica1)'
synchronous_commit = on
```

### Connection Pooling (PgBouncer)

PostgreSQL uses one process per connection, so thousands of app connections are expensive. Put **PgBouncer** in front to multiplex many client connections onto a small pool of server connections:

```yaml
services:
  pgbouncer:
    image: edoburu/pgbouncer:latest
    environment:
      DATABASE_URL: "postgres://appuser:changeme@db:5432/appdb"
      POOL_MODE: transaction        # return the server conn after each transaction
      MAX_CLIENT_CONN: 1000
      DEFAULT_POOL_SIZE: 25         # server connections per user/db
    ports:
      - "6432:6432"
    depends_on: [ db ]
```

| Pool mode | Reuses a server connection after… | Use with |
| --------- | --------------------------------- | -------- |
| `session` | the client disconnects | Anything (safest; least pooling benefit) |
| `transaction` | each transaction | Most web apps — big win; avoid session-level features (some prepared statements, `SET`, advisory locks held across transactions) |
| `statement` | each statement | Autocommit-only workloads |

> [!TIP]
> Point applications at PgBouncer (port 6432), not directly at PostgreSQL. Keep PostgreSQL's `max_connections` modest (e.g. 100–200) and let PgBouncer absorb client concurrency. This is often the single biggest scalability improvement for a busy database.

### High Availability (Automatic Failover)

Plain streaming replication does **not** promote a replica automatically — you need an HA layer that detects failure, promotes a replica, and redirects clients:

| Tool | Model | Notes |
| ---- | ----- | ----- |
| [**Patroni**](https://patroni.readthedocs.io/) | Template + DCS (etcd/Consul/ZooKeeper) | The de-facto standard for self-managed HA; handles leader election, promotion, and reconfiguration |
| [**repmgr**](https://www.repmgr.org/) | Replication manager + daemon | Simpler than Patroni; manual or automated failover |
| [**CloudNativePG**](https://cloudnative-pg.io/) | Kubernetes operator | Declarative clusters, failover, backups, and rolling upgrades as Kubernetes resources |
| [**Zalando postgres-operator**](https://github.com/zalando/postgres-operator) / [**Crunchy PGO**](https://access.crunchydata.com/documentation/postgres-operator/) | Kubernetes operators (Patroni-based) | Mature operators with backups, connection pooling, and monitoring built in |

> [!IMPORTANT]
> On **Kubernetes**, prefer a **PostgreSQL operator** (CloudNativePG, Crunchy PGO, Zalando) over hand-built StatefulSets. Operators encode the hard parts — failover, fencing to avoid split-brain, base-backup seeding of new replicas, WAL archiving, and safe rolling upgrades — that are easy to get dangerously wrong by hand.

### Choosing an Approach

- **Single container** — fine for development and many small production workloads with good backups.
- **Primary + async replica(s)** — read scaling and a warm standby for manual failover.
- **Synchronous replication** — when you cannot lose committed transactions.
- **Patroni or an operator** — when you need automatic failover with minimal downtime.

## Navigation

[◄ Backup and Recovery](backup-recovery.md) · [PostgreSQL Overview](index.md) · [Security ►](security.md)
