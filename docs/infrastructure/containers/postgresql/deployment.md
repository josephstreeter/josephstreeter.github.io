---
title: "PostgreSQL Deployment"
description: "Deploying PostgreSQL with Docker and Docker Compose — environment variables, init scripts, persistent volumes, and health checks"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Deployment

### Quick Start

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=changeme_strong \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:17
```

Connect with `psql` from inside the container (no need to expose the port for local admin):

```bash
docker exec -it postgres psql -U appuser -d appdb
```

> [!WARNING]
> Only publish port 5432 (`-p`) when a client outside the Docker network truly needs direct access, and never bind it to a public interface without TLS and firewalling. Prefer keeping the database on an internal Docker network and connecting from application containers by service name.

### Environment Variables

The official image is configured through environment variables (honored **only on first initialization**, when the data directory is empty):

| Variable | Purpose |
| -------- | ------- |
| `POSTGRES_PASSWORD` | Superuser password. **Required** unless `POSTGRES_HOST_AUTH_METHOD=trust`. |
| `POSTGRES_USER` | Superuser name (default `postgres`). |
| `POSTGRES_DB` | Database created on first init (default = `POSTGRES_USER`). |
| `PGDATA` | Data directory path (default `/var/lib/postgresql/data`). Use a subdirectory when mounting, e.g. `.../data/pgdata`. |
| `POSTGRES_INITDB_ARGS` | Extra `initdb` flags, e.g. `--data-checksums` (recommended) or `--locale=…`. |
| `POSTGRES_HOST_AUTH_METHOD` | Default auth method in generated `pg_hba.conf` (e.g. `scram-sha-256`). Avoid `trust`. |

> [!IMPORTANT]
> Because these apply **only when the data directory is empty**, changing `POSTGRES_PASSWORD` later has no effect — the password lives in the database, not the environment. Change it with SQL instead: `ALTER USER appuser PASSWORD '…';`.

### Docker Compose

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:17
    container_name: postgres
    environment:
      POSTGRES_USER: appuser
      POSTGRES_DB: appdb
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password   # prefer a secret over env
      POSTGRES_INITDB_ARGS: "--data-checksums"
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./initdb:/docker-entrypoint-initdb.d:ro          # first-run SQL/shell scripts
    ports:
      - "127.0.0.1:5432:5432"                            # localhost only
    shm_size: "256mb"                                    # room for parallel queries
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    secrets:
      - db_password

  app:
    image: myapp:latest
    environment:
      DATABASE_URL: "postgres://appuser@db:5432/appdb"   # connect by service name
    depends_on:
      db:
        condition: service_healthy                       # wait for the DB to be ready
    networks:
      - default

volumes:
  pgdata:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Persistence

The database lives in `/var/lib/postgresql/data`. Without a volume there, **all data is lost** when the container is removed. Options:

| Type | Definition | Notes |
| ---- | ---------- | ----- |
| **Named volume** | `pgdata:/var/lib/postgresql/data` | Recommended — Docker manages it; survives `docker compose down` (removed only with `down -v`) |
| **Bind mount** | `./data:/var/lib/postgresql/data` | Host-path visibility; watch host filesystem/permission and performance quirks |

> [!TIP]
> When bind-mounting, set `PGDATA` to a **subdirectory** of the mount (e.g. `/var/lib/postgresql/data/pgdata`). PostgreSQL's `initdb` requires an empty data directory, and mount points sometimes contain hidden files (like `lost+found`) that break initialization.

### Initialization Scripts

Files placed in `/docker-entrypoint-initdb.d/` run once, in alphabetical order, when the cluster is first created. Use them to create schemas, roles, and seed data:

```bash
initdb/
├── 01-schema.sql        # CREATE TABLE ...
├── 02-roles.sql         # CREATE ROLE readonly ...; GRANT ...
└── 03-seed.sh           # shell script (e.g. bulk COPY from a mounted file)
```

```sql
-- initdb/02-roles.sql
CREATE ROLE readonly NOLOGIN;
GRANT CONNECT ON DATABASE appdb TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
```

> [!NOTE]
> Init scripts do **not** run if the data directory is already populated. To re-run them you must start from an empty volume. They are for bootstrapping, not migrations — manage ongoing schema changes with a migration tool (Flyway, Liquibase, Alembic, etc.).

### Verifying the Deployment

```bash
# Is the server accepting connections?
docker exec postgres pg_isready -U appuser -d appdb

# Server version and settings
docker exec -it postgres psql -U appuser -d appdb -c "SELECT version();"

# List databases and roles
docker exec -it postgres psql -U appuser -d appdb -c "\l"
docker exec -it postgres psql -U appuser -d appdb -c "\du"
```

## Navigation

[◄ Overview](index.md) · [PostgreSQL Overview](index.md) · [Configuration and Tuning ►](configuration.md)
