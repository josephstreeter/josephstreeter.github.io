---
title: "PostgreSQL Security"
description: "Securing containerized PostgreSQL — authentication, pg_hba.conf, TLS/SSL, roles and least privilege, secrets, and network isolation"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Security

### Network Exposure

The first and most effective control is **not exposing the database**. In a container deployment:

- Keep PostgreSQL on an internal Docker/Kubernetes network and let application containers reach it by service name — do not publish port 5432 at all if nothing outside needs it.
- If you must publish it, bind to localhost or a private interface (`127.0.0.1:5432:5432`) and firewall it; never `0.0.0.0` on a public host without TLS.
- Set `listen_addresses` deliberately — `*` listens on all interfaces (needed inside the container network), but the real boundary is what you publish and your `pg_hba.conf`.

### Authentication and pg_hba.conf

`pg_hba.conf` is PostgreSQL's host-based access control — evaluated top to bottom, first match wins. Each rule is `TYPE  DATABASE  USER  ADDRESS  METHOD`:

```ini
# TYPE   DATABASE     USER         ADDRESS          METHOD
local    all          all                           scram-sha-256
# App connections over the Docker network, encrypted
hostssl  appdb        appuser      10.0.0.0/8       scram-sha-256
# Replication for the replica only
host     replication  replicator   10.0.0.0/8       scram-sha-256
# Reject everything else explicitly
host     all          all          0.0.0.0/0        reject
```

| Method | Use |
| ------ | --- |
| `scram-sha-256` | **Preferred** password auth (salted challenge-response). Set `password_encryption = scram-sha-256`. |
| `md5` | Legacy password hashing — weaker; migrate off it. |
| `cert` | Client-certificate authentication (mutual TLS). |
| `trust` | **No authentication** — never use except in a throwaway local sandbox. |
| `reject` | Explicitly deny matching connections. |

> [!WARNING]
> The official image's default `POSTGRES_HOST_AUTH_METHOD` should be `scram-sha-256`, **never `trust`** in any shared or production environment — `trust` lets anyone who can reach the port connect as any user with no password. Confirm your generated `pg_hba.conf` does not contain broad `trust` rules.

### TLS/SSL

Encrypt client connections so credentials and data aren't sent in the clear. Provide a certificate and key and enable SSL:

```ini
# postgresql.conf
ssl = on
ssl_cert_file = '/etc/postgresql/certs/server.crt'
ssl_key_file  = '/etc/postgresql/certs/server.key'
ssl_min_protocol_version = 'TLSv1.2'
```

```yaml
# mount the certs (key must be readable only by the postgres user, mode 0600)
volumes:
  - ./certs/server.crt:/etc/postgresql/certs/server.crt:ro
  - ./certs/server.key:/etc/postgresql/certs/server.key:ro
```

Require TLS for remote connections with `hostssl` rules in `pg_hba.conf` (as above), and have clients verify the server:

```bash
psql "host=db.example.com dbname=appdb user=appuser sslmode=verify-full sslrootcert=ca.crt"
```

`sslmode=verify-full` validates both the certificate chain and the hostname — the only mode that prevents man-in-the-middle attacks. See the [certificates section](../../../security/certificates/index.md) for obtaining/managing certificates.

### Roles and Least Privilege

Never run applications as the superuser. Create purpose-specific roles with only the privileges they need:

```sql
-- Application role: connect and use the schema, no ownership/DDL
CREATE ROLE appuser LOGIN PASSWORD 'from-a-secret';
GRANT CONNECT ON DATABASE appdb TO appuser;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

-- Read-only role for reporting/BI
CREATE ROLE readonly LOGIN PASSWORD 'from-a-secret';
GRANT CONNECT ON DATABASE appdb TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
```

- Own objects with a dedicated **owner** role (not the app role), so a compromised app account cannot drop or alter schema.
- Use `ALTER DEFAULT PRIVILEGES` so future tables inherit the right grants automatically.
- Consider **Row-Level Security** (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) for multi-tenant data.

### Secrets Management

Do not hard-code passwords in Compose files or images:

- Use **Docker secrets** (`POSTGRES_PASSWORD_FILE=/run/secrets/db_password`) or Kubernetes Secrets, not plain environment variables where avoidable.
- Keep credential files out of source control; mount them read-only.
- Rotate the superuser and application passwords periodically (`ALTER USER … PASSWORD …`), and store them in a secrets manager (Vault, cloud secret stores) for larger deployments.

```yaml
# Docker secret example (see Deployment)
environment:
  POSTGRES_PASSWORD_FILE: /run/secrets/db_password
secrets:
  - db_password
```

### Hardening Checklist

- [ ] Port 5432 not publicly exposed; DB reachable only on the internal network
- [ ] `pg_hba.conf` uses `scram-sha-256` (or `cert`); no broad `trust`; explicit `reject` catch-all
- [ ] `password_encryption = scram-sha-256`
- [ ] TLS enabled; remote clients use `hostssl` + `sslmode=verify-full`
- [ ] Applications use least-privilege roles; objects owned by a separate role
- [ ] Passwords sourced from secrets, not committed; rotated periodically
- [ ] Running a supported PostgreSQL major version, patched to the latest minor
- [ ] Backups (see [Backup and Recovery](backup-recovery.md)) stored securely and encrypted

## Navigation

[◄ Replication and High Availability](replication-ha.md) · [PostgreSQL Overview](index.md) · [Monitoring and Troubleshooting ►](monitoring.md)
