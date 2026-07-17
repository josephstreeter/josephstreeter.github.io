---
title: "Grafana Backup and Recovery"
description: "Guide to backing up and restoring Grafana, including database backups, dashboard exports via API, provisioning as code, and restore procedures"
author: "josephstreeter"
ms.author: josephstreeter
ms.topic: how-to
ms.date: 12/30/2025
keywords: ["grafana", "backup", "recovery", "dashboards", "provisioning", "restore", "database"]
uid: docs.infrastructure.grafana.backup-recovery
---

## Overview

This page covers backing up and restoring Grafana: the underlying database, dashboards and data sources exported via the API, the `grafana.ini` configuration, installed plugins, and provisioning definitions kept as code. For the shared backup infrastructure the whole monitoring stack relies on — off-site storage (S3, MinIO), encryption, disaster recovery testing, and the combined automation scripts — see the [Prometheus Backup and Recovery](../prometheus/backup-recovery.md) page.

## Grafana Backups

### Database Backups

#### SQLite Backup

```bash
#!/bin/bash
# grafana-sqlite-backup.sh

set -euo pipefail

GRAFANA_DB="/var/lib/grafana/grafana.db"
BACKUP_DIR="/backups/grafana"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/grafana-db-${TIMESTAMP}.db"

mkdir -p "${BACKUP_DIR}"

# Create SQLite backup
sqlite3 "${GRAFANA_DB}" ".backup '${BACKUP_FILE}'"

# Compress backup
gzip "${BACKUP_FILE}"

echo "Grafana SQLite backup completed: ${BACKUP_FILE}.gz"
```

#### PostgreSQL Backup

```bash
#!/bin/bash
# grafana-postgres-backup.sh

set -euo pipefail

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grafana}"
DB_USER="${DB_USER:-grafana}"
DB_PASSWORD="${DB_PASSWORD}"
BACKUP_DIR="/backups/grafana"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/grafana-db-${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

# Create PostgreSQL dump
export PGPASSWORD="${DB_PASSWORD}"
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
    --format=custom \
    --compress=9 \
    --file="${BACKUP_FILE}.dump"

# Create plain SQL backup for readability
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
    --format=plain \
    --file="${BACKUP_FILE}"

gzip "${BACKUP_FILE}"

echo "Grafana PostgreSQL backup completed: ${BACKUP_FILE}.dump and ${BACKUP_FILE}.gz"
```

#### MySQL Backup

```bash
#!/bin/bash
# grafana-mysql-backup.sh

set -euo pipefail

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-grafana}"
DB_USER="${DB_USER:-grafana}"
DB_PASSWORD="${DB_PASSWORD}"
BACKUP_DIR="/backups/grafana"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/grafana-db-${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

# Create MySQL dump
mysqldump -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    "${DB_NAME}" > "${BACKUP_FILE}"

gzip "${BACKUP_FILE}"

echo "Grafana MySQL backup completed: ${BACKUP_FILE}.gz"
```

### Dashboard Exports via API

> [!NOTE]
> The scripts below authenticate with `Authorization: Bearer ${GRAFANA_API_KEY}`. Grafana **API keys are deprecated in favor of service-account tokens** (Grafana 9+). Create a service account with the required role and issue a token for it, then set `GRAFANA_API_KEY` to that token — the `Authorization: Bearer` header is identical.

<!-- -->

> [!TIP]
> Instead of hand-rolling these API scripts, consider the community [`grafana-backup-tool`](https://github.com/ysde/grafana-backup-tool) (`grafana-backup`), which exports and restores dashboards, folders, data sources, alert rules, and more via the Grafana API in one command.

```bash
#!/bin/bash
# grafana-dashboard-backup.sh
# Export all Grafana dashboards via API

set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://grafana:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY}"
BACKUP_DIR="/backups/grafana/dashboards"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"

mkdir -p "${BACKUP_PATH}"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Log "Starting Grafana dashboard backup..."

# Get all dashboard UIDs
Log "Fetching dashboard list..."
DASHBOARDS=$(curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[] | .uid')

if [ -z "${DASHBOARDS}" ]; then
    Log "No dashboards found"
    exit 0
fi

DASHBOARD_COUNT=$(echo "${DASHBOARDS}" | wc -l)
Log "Found ${DASHBOARD_COUNT} dashboards"

# Export each dashboard
COUNT=0
for uid in ${DASHBOARDS}; do
    COUNT=$((COUNT + 1))
    Log "Exporting dashboard ${COUNT}/${DASHBOARD_COUNT}: ${uid}"
    
    # Get dashboard JSON
    dashboard_json=$(curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        "${GRAFANA_URL}/api/dashboards/uid/${uid}")
    
    # Extract dashboard title for filename
    title=$(echo "${dashboard_json}" | jq -r '.meta.slug')
    
    # Save dashboard JSON
    echo "${dashboard_json}" | jq '.dashboard' > "${BACKUP_PATH}/${title}-${uid}.json"
done

# Export data sources
Log "Exporting data sources..."
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/datasources" | jq '.' > "${BACKUP_PATH}/datasources.json"

# Export alert notification channels
# NOTE: /api/alert-notifications is a LEGACY-ALERTING endpoint. Under Grafana
# unified alerting (the default since Grafana 9) it returns nothing useful and
# does NOT capture contact points or notification policies. Unified-alerting
# config lives in the database and is provisioned via provisioning/alerting/;
# backing up the DB + the provisioning directory captures it (see below).
Log "Exporting notification channels (legacy alerting only)..."
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/alert-notifications" | jq '.' > "${BACKUP_PATH}/notification-channels.json"

# Export folders
Log "Exporting folders..."
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/folders" | jq '.' > "${BACKUP_PATH}/folders.json"

# Create archive
Log "Creating archive..."
cd "${BACKUP_DIR}"
tar -czf "grafana-dashboards-${TIMESTAMP}.tar.gz" "${TIMESTAMP}"
rm -rf "${TIMESTAMP}"

Log "Dashboard backup completed: grafana-dashboards-${TIMESTAMP}.tar.gz"
```

### Automated Grafana Backup

```bash
#!/bin/bash
# grafana-full-backup.sh
# Complete Grafana backup including database and dashboards

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups/grafana}"
GRAFANA_URL="${GRAFANA_URL:-http://grafana:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY}"
DB_TYPE="${DB_TYPE:-postgres}"
S3_BUCKET="${S3_BUCKET:-s3://grafana-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Error()
{
    Log "ERROR: $*" >&2
    exit 1
}

mkdir -p "${BACKUP_DIR}"

Log "Starting full Grafana backup..."

# Backup database
Log "Backing up database..."
case "${DB_TYPE}" in
    postgres)
        pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" \
            --format=custom --compress=9 \
            --file="${BACKUP_DIR}/grafana-db-${TIMESTAMP}.dump"
        ;;
    mysql)
        mysqldump -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" \
            --single-transaction "${DB_NAME}" | gzip > "${BACKUP_DIR}/grafana-db-${TIMESTAMP}.sql.gz"
        ;;
    sqlite)
        sqlite3 "${GRAFANA_DB}" ".backup '${BACKUP_DIR}/grafana-db-${TIMESTAMP}.db'"
        gzip "${BACKUP_DIR}/grafana-db-${TIMESTAMP}.db"
        ;;
    *)
        Error "Unknown database type: ${DB_TYPE}"
        ;;
esac

# Backup dashboards via API
Log "Backing up dashboards..."
DASHBOARD_DIR="${BACKUP_DIR}/dashboards-${TIMESTAMP}"
mkdir -p "${DASHBOARD_DIR}"

# Export all dashboards
DASHBOARDS=$(curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[] | .uid')

for uid in ${DASHBOARDS}; do
    curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        "${GRAFANA_URL}/api/dashboards/uid/${uid}" | \
        jq '.dashboard' > "${DASHBOARD_DIR}/${uid}.json"
done

# Export configuration
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/datasources" > "${DASHBOARD_DIR}/datasources.json"
# LEGACY-ALERTING endpoint only — see note above. With unified alerting, contact
# points and notification policies are captured by the DB dump plus the
# provisioning/alerting/ directory, not by this call.
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/alert-notifications" > "${DASHBOARD_DIR}/notifications.json"
curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "${GRAFANA_URL}/api/folders" > "${DASHBOARD_DIR}/folders.json"

# Create archive
tar -czf "${BACKUP_DIR}/grafana-dashboards-${TIMESTAMP}.tar.gz" -C "${BACKUP_DIR}" "dashboards-${TIMESTAMP}"
rm -rf "${DASHBOARD_DIR}"

# Backup provisioning files
Log "Backing up provisioning files..."
if [ -d "/etc/grafana/provisioning" ]; then
    tar -czf "${BACKUP_DIR}/grafana-provisioning-${TIMESTAMP}.tar.gz" -C /etc/grafana provisioning
fi

# Backup the main configuration file (grafana.ini). The dashboard/provisioning
# exports above do NOT include it, yet it holds server, database, auth, SMTP
# and feature settings that must be restored for a faithful rebuild.
Log "Backing up grafana.ini..."
GRAFANA_INI="${GRAFANA_INI:-/etc/grafana/grafana.ini}"
if [ -f "${GRAFANA_INI}" ]; then
    cp "${GRAFANA_INI}" "${BACKUP_DIR}/grafana-ini-${TIMESTAMP}.ini"
fi

# Backup the installed plugins directory. Plugins are not stored in the DB, so
# a DB-only restore would silently drop panels/data sources they provide.
Log "Backing up plugins..."
GRAFANA_PLUGINS_DIR="${GRAFANA_PLUGINS_DIR:-/var/lib/grafana/plugins}"
if [ -d "${GRAFANA_PLUGINS_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/grafana-plugins-${TIMESTAMP}.tar.gz" \
        -C "$(dirname "${GRAFANA_PLUGINS_DIR}")" "$(basename "${GRAFANA_PLUGINS_DIR}")"
fi

# Create manifest
Log "Creating backup manifest..."
cat > "${BACKUP_DIR}/manifest-${TIMESTAMP}.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "grafana_version": "$(curl -s ${GRAFANA_URL}/api/health | jq -r '.version')",
    "database_type": "${DB_TYPE}",
    "files": {
        "database": "grafana-db-${TIMESTAMP}.dump",
        "dashboards": "grafana-dashboards-${TIMESTAMP}.tar.gz",
        "provisioning": "grafana-provisioning-${TIMESTAMP}.tar.gz",
        "config": "grafana-ini-${TIMESTAMP}.ini",
        "plugins": "grafana-plugins-${TIMESTAMP}.tar.gz"
    }
}
EOF

# Upload to S3
if [ -n "${S3_BUCKET}" ]; then
    Log "Uploading to S3..."
    aws s3 sync "${BACKUP_DIR}" "${S3_BUCKET}/$(date +%Y/%m/%d)/" \
        --exclude "*" \
        --include "*-${TIMESTAMP}.*"
fi

Log "Full Grafana backup completed"
```

### Provisioning as Code

```yaml
# provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
```

```yaml
# provisioning/datasources/datasource.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Thanos
    type: prometheus
    access: proxy
    url: http://thanos-query:9090
    editable: false
```

## Restore Procedures

### Grafana Database Restore

#### PostgreSQL Restore

```bash
#!/bin/bash
# grafana-postgres-restore.sh

set -euo pipefail

BACKUP_FILE="$1"
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grafana}"
DB_USER="${DB_USER:-grafana}"
DB_PASSWORD="${DB_PASSWORD}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <backup-file.dump>"
    exit 1
fi

echo "Stopping Grafana..."
docker stop grafana-1 grafana-2 grafana-3 || true

echo "Dropping existing database..."
export PGPASSWORD="${DB_PASSWORD}"
psql -h "${DB_HOST}" -U "${DB_USER}" -c "DROP DATABASE IF EXISTS ${DB_NAME};"
psql -h "${DB_HOST}" -U "${DB_USER}" -c "CREATE DATABASE ${DB_NAME};"

echo "Restoring database..."
pg_restore -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" \
    --no-owner --no-privileges "${BACKUP_FILE}"

echo "Starting Grafana..."
docker start grafana-1 grafana-2 grafana-3

echo "Restore completed"
```

#### MySQL Restore

```bash
#!/bin/bash
# grafana-mysql-restore.sh

set -euo pipefail

BACKUP_FILE="$1"
DB_HOST="${DB_HOST:-mysql}"
DB_NAME="${DB_NAME:-grafana}"
DB_USER="${DB_USER:-grafana}"
DB_PASSWORD="${DB_PASSWORD}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <backup-file.sql.gz>"
    exit 1
fi

echo "Stopping Grafana..."
docker stop grafana || true

echo "Restoring database..."
zcat "${BACKUP_FILE}" | mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}"

echo "Starting Grafana..."
docker start grafana

echo "Restore completed"
```

### Dashboard Restore

```bash
#!/bin/bash
# grafana-dashboard-restore.sh

set -euo pipefail

BACKUP_ARCHIVE="$1"
GRAFANA_URL="${GRAFANA_URL:-http://grafana:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY}"

if [ -z "${BACKUP_ARCHIVE}" ]; then
    echo "Usage: $0 <backup-archive.tar.gz>"
    exit 1
fi

echo "Extracting backup..."
TEMP_DIR=$(mktemp -d)
tar -xzf "${BACKUP_ARCHIVE}" -C "${TEMP_DIR}"

DASHBOARD_DIR=$(find "${TEMP_DIR}" -type d -name "dashboards-*" | head -1)

if [ -z "${DASHBOARD_DIR}" ]; then
    echo "No dashboard directory found in backup"
    exit 1
fi

# Restore data sources first
echo "Restoring data sources..."
if [ -f "${DASHBOARD_DIR}/datasources.json" ]; then
    jq -c '.[]' "${DASHBOARD_DIR}/datasources.json" | while read -r datasource; do
        curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "${datasource}" \
            "${GRAFANA_URL}/api/datasources"
    done
fi

# Restore folders
echo "Restoring folders..."
if [ -f "${DASHBOARD_DIR}/folders.json" ]; then
    jq -c '.[]' "${DASHBOARD_DIR}/folders.json" | while read -r folder; do
        curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "${folder}" \
            "${GRAFANA_URL}/api/folders"
    done
fi

# Restore dashboards
echo "Restoring dashboards..."
find "${DASHBOARD_DIR}" -name "*.json" ! -name "datasources.json" ! -name "notifications.json" ! -name "folders.json" | while read -r dashboard_file; do
    dashboard_json=$(cat "${dashboard_file}")
    payload=$(jq -n --argjson dashboard "${dashboard_json}" '{dashboard: $dashboard, overwrite: true}')
    
    curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "${payload}" \
        "${GRAFANA_URL}/api/dashboards/db"
done

# Restore notification channels
# NOTE: /api/alert-notifications is LEGACY ALERTING only. If you use unified
# alerting (default since Grafana 9), restore contact points and notification
# policies from the database dump and/or the provisioning/alerting/ directory
# instead — this call will not recreate them.
echo "Restoring notification channels (legacy alerting only)..."
if [ -f "${DASHBOARD_DIR}/notifications.json" ]; then
    jq -c '.[]' "${DASHBOARD_DIR}/notifications.json" | while read -r notification; do
        curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "${notification}" \
            "${GRAFANA_URL}/api/alert-notifications"
    done
fi

# Clean up
rm -rf "${TEMP_DIR}"

echo "Dashboard restore completed"
```

## Shared Backup Infrastructure

Grafana backups rely on the same stack-wide backup infrastructure documented on the [Prometheus Backup and Recovery](../prometheus/backup-recovery.md) page. Refer there for:

- [Backup Storage](../prometheus/backup-recovery.md#backup-storage) — off-site S3 and MinIO uploads plus GPG encryption for all backups.
- [Disaster Recovery Testing](../prometheus/backup-recovery.md#disaster-recovery-testing) — DR drill and RTO/RPO scripts that cover both Grafana and Prometheus.
- [Automation Scripts](../prometheus/backup-recovery.md#automation-scripts) — the combined `backup-all.sh` orchestration and cron schedule that invoke `grafana-full-backup.sh` alongside the Prometheus and Alertmanager backups.

## See Also

- [Prometheus Backup and Recovery](../prometheus/backup-recovery.md)
- [Grafana Overview](index.md)
- [Monitoring Stack Overview](../index.md)
- [High Availability](high-availability.md)
- [Alerting Configuration](../prometheus/alerting.md)
- [Exporters Configuration](../prometheus/exporters.md)
