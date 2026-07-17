---
title: "PostgreSQL in Containers"
description: "Comprehensive guide to running PostgreSQL in containers — deployment, configuration and tuning, backups, replication and HA, security, and monitoring with Docker"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: overview
ms.service: infrastructure
---

## PostgreSQL in Containers

[PostgreSQL](https://www.postgresql.org/) ("Postgres") is a powerful, open-source object-relational database with 35+ years of development, full ACID compliance, MVCC, and a rich extension ecosystem. This section focuses on **running PostgreSQL in containers** with Docker — deployment, configuration and tuning, data persistence, backup and recovery, replication and high availability, security, and monitoring.

> [!NOTE]
> This section covers the **operational, containerized** side of PostgreSQL. For the SQL language, data types, indexing, query tuning, and general database concepts, see the [PostgreSQL developer guide](../../../development/databases/postgresql.md). For administration UIs, see [pgAdmin](../pgadmin/index.md).

### The Official Image

Examples use the official [`postgres`](https://hub.docker.com/_/postgres) image. Key facts:

| Aspect | Detail |
| ------ | ------ |
| Data directory | `/var/lib/postgresql/data` (override with the `PGDATA` env var) |
| Runs as | the `postgres` user (UID 999) inside the container |
| First-run init | scripts in `/docker-entrypoint-initdb.d/` (`*.sql`, `*.sql.gz`, `*.sh`) run **only** when the data directory is empty |
| Default port | 5432 |
| Required env | `POSTGRES_PASSWORD` (the image refuses to start without it, unless `POSTGRES_HOST_AUTH_METHOD=trust`) |

> [!IMPORTANT]
> **Pin the major version** (e.g. `postgres:17`, not `postgres:latest`). PostgreSQL data files are **not** compatible across major versions — starting a newer major on an older cluster's data directory will fail, and major upgrades require `pg_upgrade` or a dump/restore (see [Best Practices](best-practices.md)). Minor versions (17.x) are drop-in.

### Container-Specific Concerns

Running PostgreSQL in a container adds a few considerations beyond a bare-metal install, each covered in this section:

- **Persistence** — the data directory must live on a volume, or you lose the database when the container is removed ([Deployment](deployment.md)).
- **Shared memory** — the default 64 MB `/dev/shm` can be too small for parallel queries; raise `shm_size` ([Best Practices](best-practices.md)).
- **Configuration** — how to pass `postgresql.conf`/`pg_hba.conf` into an image you don't control ([Configuration](configuration.md)).
- **Resource limits** — tune `shared_buffers`/`work_mem` to the container's memory limit, not the host's ([Best Practices](best-practices.md)).
- **Backups and upgrades** — logical vs physical backups and major-version upgrades in a container world ([Backup and Recovery](backup-recovery.md)).

### In This Section

- [Deployment](deployment.md) — the official image, Docker Compose, environment variables, init scripts, and persistent volumes
- [Configuration and Tuning](configuration.md) — passing `postgresql.conf`/`pg_hba.conf`, key tuning parameters, and building a custom image
- [Backup and Recovery](backup-recovery.md) — `pg_dump`/`pg_restore`, `pg_basebackup`, and point-in-time recovery (PITR)
- [Replication and High Availability](replication-ha.md) — streaming replication, connection pooling with PgBouncer, and Kubernetes operators
- [Security](security.md) — authentication, `pg_hba.conf`, TLS, roles/privileges, and secrets
- [Monitoring and Troubleshooting](monitoring.md) — logging, `pg_stat` views, the Prometheus exporter, health checks, and common issues
- [Best Practices](best-practices.md) — tuning, shared memory, `PGDATA` ownership, resource limits, and major-version upgrades

### Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [`postgres` Docker image](https://hub.docker.com/_/postgres)
- [PGTune](https://pgtune.leopard.in.ua/) — generates a tuned `postgresql.conf` for your resources
- [CloudNativePG](https://cloudnative-pg.io/) — Kubernetes operator for PostgreSQL

### Related Topics

- [PostgreSQL developer guide](../../../development/databases/postgresql.md) — SQL, indexing, and query tuning
- [pgAdmin](../pgadmin/index.md) — web administration UI
- [Docker](../docker/index.md)
- [Kubernetes](../kubernetes/index.md)
