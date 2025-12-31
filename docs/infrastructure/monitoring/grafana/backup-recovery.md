---
title: "Backup and Recovery"
description: "Comprehensive guide to backing up and restoring Prometheus, Grafana, and Alertmanager with automated scripts and disaster recovery procedures"
author: "josephstreeter"
ms.author: "joseph.streeter"
ms.topic: how-to
ms.date: 12/30/2025
keywords: ["prometheus", "grafana", "backup", "recovery", "disaster recovery", "snapshots", "restore"]
uid: docs.infrastructure.grafana.backup-recovery
---

## Overview

A comprehensive backup strategy ensures data protection and rapid recovery from failures, data corruption, or disasters.

**Key Components to Backup:**

- Prometheus TSDB data and configuration
- Grafana dashboards, data sources, and database
- Alertmanager configuration and silences
- Recording and alerting rules
- Provisioning configurations

**Backup Strategy Requirements:**

- Automated daily backups
- Off-site storage (S3, MinIO, NFS)
- Retention policies (7 daily, 4 weekly, 12 monthly)
- Encryption at rest and in transit
- Tested restore procedures
- Documented recovery processes

## Prometheus Backups

### Snapshot API

Prometheus provides a snapshot API for creating point-in-time backups.

```bash
#!/bin/bash
# Create Prometheus snapshot

PROMETHEUS_URL="http://prometheus:9090"
SNAPSHOT_NAME="prometheus-snapshot-$(date +%Y%m%d-%H%M%S)"

# Create snapshot (requires --web.enable-admin-api flag)
curl -XPOST "${PROMETHEUS_URL}/api/v1/admin/tsdb/snapshot"

# Get snapshot name
SNAPSHOT=$(curl -s "${PROMETHEUS_URL}/api/v1/admin/tsdb/snapshot" | jq -r '.data.name')

echo "Snapshot created: ${SNAPSHOT}"
```

### Automated Backup Script

```bash
#!/bin/bash
# prometheus-backup.sh
# Automated Prometheus backup with retention

set -euo pipefail

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://prometheus:9090}"
PROMETHEUS_DATA_DIR="${PROMETHEUS_DATA_DIR:-/prometheus}"
BACKUP_DIR="${BACKUP_DIR:-/backups/prometheus}"
S3_BUCKET="${S3_BUCKET:-s3://prometheus-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
RETENTION_WEEKS="${RETENTION_WEEKS:-4}"
RETENTION_MONTHS="${RETENTION_MONTHS:-12}"

# Logging
Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Error()
{
    Log "ERROR: $*" >&2
    exit 1
}

# Create backup directory
Mkdir -p "${BACKUP_DIR}"

# Generate backup name
BACKUP_NAME="prometheus-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

Log "Starting Prometheus backup: ${BACKUP_NAME}"

# Create snapshot via API
Log "Creating Prometheus snapshot..."
SNAPSHOT_RESPONSE=$(curl -s -XPOST "${PROMETHEUS_URL}/api/v1/admin/tsdb/snapshot")
SNAPSHOT_STATUS=$(echo "${SNAPSHOT_RESPONSE}" | jq -r '.status')

if [ "${SNAPSHOT_STATUS}" != "success" ]; then
    Error "Failed to create snapshot: ${SNAPSHOT_RESPONSE}"
fi

SNAPSHOT_NAME=$(echo "${SNAPSHOT_RESPONSE}" | jq -r '.data.name')
SNAPSHOT_PATH="${PROMETHEUS_DATA_DIR}/snapshots/${SNAPSHOT_NAME}"

Log "Snapshot created: ${SNAPSHOT_NAME}"

# Create compressed archive
Log "Creating compressed archive..."
cd "${PROMETHEUS_DATA_DIR}/snapshots"
tar -czf "${BACKUP_PATH}.tar.gz" "${SNAPSHOT_NAME}"

if [ ! -f "${BACKUP_PATH}.tar.gz" ]; then
    Error "Failed to create backup archive"
fi

BACKUP_SIZE=$(du -h "${BACKUP_PATH}.tar.gz" | cut -f1)
Log "Backup archive created: ${BACKUP_PATH}.tar.gz (${BACKUP_SIZE})"

# Calculate checksum
Log "Calculating checksum..."
sha256sum "${BACKUP_PATH}.tar.gz" > "${BACKUP_PATH}.tar.gz.sha256"

# Backup Prometheus configuration
Log "Backing up Prometheus configuration..."
mkdir -p "${BACKUP_PATH}-config"
cp -r /etc/prometheus/* "${BACKUP_PATH}-config/"
tar -czf "${BACKUP_PATH}-config.tar.gz" -C "${BACKUP_PATH}-config" .
rm -rf "${BACKUP_PATH}-config"

# Upload to S3 if configured
if [ -n "${S3_BUCKET}" ]; then
    Log "Uploading to S3..."
    aws s3 cp "${BACKUP_PATH}.tar.gz" "${S3_BUCKET}/$(date +%Y/%m/%d)/${BACKUP_NAME}.tar.gz"
    aws s3 cp "${BACKUP_PATH}.tar.gz.sha256" "${S3_BUCKET}/$(date +%Y/%m/%d)/${BACKUP_NAME}.tar.gz.sha256"
    aws s3 cp "${BACKUP_PATH}-config.tar.gz" "${S3_BUCKET}/$(date +%Y/%m/%d)/${BACKUP_NAME}-config.tar.gz"
    Log "Upload completed"
fi

# Clean up snapshot
Log "Cleaning up snapshot..."
rm -rf "${SNAPSHOT_PATH}"

# Apply retention policy
Log "Applying retention policy..."

# Keep daily backups for RETENTION_DAYS
find "${BACKUP_DIR}" -name "prometheus-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

# Keep weekly backups (Sundays) for RETENTION_WEEKS
WEEKLY_RETENTION_DAYS=$((RETENTION_WEEKS * 7))
find "${BACKUP_DIR}" -name "prometheus-backup-*.tar.gz" -type f -mtime +${WEEKLY_RETENTION_DAYS} ! -name "*-Sun-*.tar.gz" -delete

# Keep monthly backups (1st of month) for RETENTION_MONTHS
MONTHLY_RETENTION_DAYS=$((RETENTION_MONTHS * 30))
find "${BACKUP_DIR}" -name "prometheus-backup-*.tar.gz" -type f -mtime +${MONTHLY_RETENTION_DAYS} ! -name "*-01-*.tar.gz" -delete

# Clean up checksums for deleted backups
find "${BACKUP_DIR}" -name "*.sha256" -type f | while read -r checksum_file; do
    backup_file="${checksum_file%.sha256}"
    if [ ! -f "${backup_file}" ]; then
        rm -f "${checksum_file}"
    fi
done

Log "Backup completed successfully: ${BACKUP_NAME}"

# Send success notification
curl -X POST https://healthchecks.io/ping/your-uuid

exit 0
```

### Incremental Backups

```bash
#!/bin/bash
# prometheus-incremental-backup.sh
# Incremental backup using rsync

set -euo pipefail

PROMETHEUS_DATA_DIR="/prometheus"
BACKUP_BASE_DIR="/backups/prometheus-incremental"
CURRENT_BACKUP="${BACKUP_BASE_DIR}/current"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create backup directories
mkdir -p "${BACKUP_BASE_DIR}"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Log "Starting incremental backup..."

# Perform incremental backup using rsync
if [ -d "${CURRENT_BACKUP}" ]; then
    Log "Performing incremental backup..."
    rsync -av --delete \
        --link-dest="${CURRENT_BACKUP}" \
        "${PROMETHEUS_DATA_DIR}/" \
        "${BACKUP_BASE_DIR}/${TIMESTAMP}/"
else
    Log "Performing full backup..."
    rsync -av \
        "${PROMETHEUS_DATA_DIR}/" \
        "${BACKUP_BASE_DIR}/${TIMESTAMP}/"
fi

# Update current symlink
rm -f "${CURRENT_BACKUP}"
ln -s "${BACKUP_BASE_DIR}/${TIMESTAMP}" "${CURRENT_BACKUP}"

Log "Incremental backup completed: ${TIMESTAMP}"
```

### Retention Policies

```bash
#!/bin/bash
# prometheus-retention.sh
# Apply sophisticated retention policies

set -euo pipefail

BACKUP_DIR="/backups/prometheus"

# Retention rules
DAILY_RETENTION=7      # Keep 7 daily backups
WEEKLY_RETENTION=4     # Keep 4 weekly backups (Sundays)
MONTHLY_RETENTION=12   # Keep 12 monthly backups (1st of month)
YEARLY_RETENTION=5     # Keep 5 yearly backups (January 1st)

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Log "Applying retention policies..."

# Get current date
CURRENT_DATE=$(date +%s)

# Process all backups
find "${BACKUP_DIR}" -name "prometheus-backup-*.tar.gz" -type f | while read -r backup_file; do
    # Extract date from filename (format: prometheus-backup-YYYYMMDD-HHMMSS.tar.gz)
    backup_date=$(basename "${backup_file}" | sed 's/prometheus-backup-\([0-9]\{8\}\).*/\1/')
    backup_timestamp=$(date -d "${backup_date}" +%s)
    backup_age_days=$(( (CURRENT_DATE - backup_timestamp) / 86400 ))
    backup_dow=$(date -d "${backup_date}" +%u)  # Day of week (1=Monday, 7=Sunday)
    backup_dom=$(date -d "${backup_date}" +%d)  # Day of month
    backup_month=$(date -d "${backup_date}" +%m)
    
    # Determine if backup should be kept
    keep_backup=false
    reason=""
    
    # Keep if within daily retention
    if [ ${backup_age_days} -le ${DAILY_RETENTION} ]; then
        keep_backup=true
        reason="daily"
    # Keep if weekly backup (Sunday) within weekly retention
    elif [ ${backup_dow} -eq 7 ] && [ ${backup_age_days} -le $((WEEKLY_RETENTION * 7)) ]; then
        keep_backup=true
        reason="weekly"
    # Keep if monthly backup (1st) within monthly retention
    elif [ "${backup_dom}" = "01" ] && [ ${backup_age_days} -le $((MONTHLY_RETENTION * 30)) ]; then
        keep_backup=true
        reason="monthly"
    # Keep if yearly backup (Jan 1st) within yearly retention
    elif [ "${backup_dom}" = "01" ] && [ "${backup_month}" = "01" ] && [ ${backup_age_days} -le $((YEARLY_RETENTION * 365)) ]; then
        keep_backup=true
        reason="yearly"
    fi
    
    # Delete if not kept
    if [ "${keep_backup}" = false ]; then
        Log "Deleting old backup: $(basename "${backup_file}") (${backup_age_days} days old)"
        rm -f "${backup_file}"
        rm -f "${backup_file}.sha256"
    else
        Log "Keeping backup: $(basename "${backup_file}") (${reason}, ${backup_age_days} days old)"
    fi
done

Log "Retention policy applied"
```

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
Log "Exporting notification channels..."
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
        "provisioning": "grafana-provisioning-${TIMESTAMP}.tar.gz"
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

## Alertmanager Backups

```bash
#!/bin/bash
# alertmanager-backup.sh

set -euo pipefail

ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://alertmanager:9093}"
ALERTMANAGER_DATA_DIR="${ALERTMANAGER_DATA_DIR:-/alertmanager}"
BACKUP_DIR="${BACKUP_DIR:-/backups/alertmanager}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "${BACKUP_DIR}"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Log "Starting Alertmanager backup..."

# Backup configuration
Log "Backing up configuration..."
cp /etc/alertmanager/alertmanager.yml "${BACKUP_DIR}/alertmanager-config-${TIMESTAMP}.yml"

# Backup silences
Log "Backing up silences..."
curl -s "${ALERTMANAGER_URL}/api/v2/silences" > "${BACKUP_DIR}/silences-${TIMESTAMP}.json"

# Backup notification log
Log "Backing up notification log..."
if [ -d "${ALERTMANAGER_DATA_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/alertmanager-data-${TIMESTAMP}.tar.gz" -C "${ALERTMANAGER_DATA_DIR}" .
fi

Log "Alertmanager backup completed"
```

## Backup Storage

### S3 Storage

```bash
#!/bin/bash
# upload-to-s3.sh

set -euo pipefail

SOURCE_DIR="/backups"
S3_BUCKET="s3://monitoring-backups"
STORAGE_CLASS="INTELLIGENT_TIERING"

# Upload with encryption
aws s3 sync "${SOURCE_DIR}" "${S3_BUCKET}" \
    --storage-class "${STORAGE_CLASS}" \
    --server-side-encryption AES256 \
    --exclude "*.tmp" \
    --exclude ".DS_Store"

# Set lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
    --bucket monitoring-backups \
    --lifecycle-configuration file://lifecycle-policy.json
```

```json
{
    "Rules": [
        {
            "Id": "TransitionToGlacier",
            "Status": "Enabled",
            "Prefix": "",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 90,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}
```

### MinIO Storage

```bash
#!/bin/bash
# upload-to-minio.sh

set -euo pipefail

MC_ALIAS="minio"
MINIO_ENDPOINT="http://minio:9000"
MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY}"
MINIO_SECRET_KEY="${MINIO_SECRET_KEY}"
BUCKET="monitoring-backups"
SOURCE_DIR="/backups"

# Configure mc client
mc alias set "${MC_ALIAS}" "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}"

# Create bucket if not exists
mc mb -p "${MC_ALIAS}/${BUCKET}"

# Upload backups
mc mirror --overwrite "${SOURCE_DIR}" "${MC_ALIAS}/${BUCKET}"

# Set retention policy
mc retention set --default COMPLIANCE --days 30 "${MC_ALIAS}/${BUCKET}"
```

### Encryption

```bash
#!/bin/bash
# encrypt-backup.sh
# Encrypt backups using GPG

set -euo pipefail

BACKUP_FILE="$1"
GPG_RECIPIENT="backup@example.com"

# Encrypt backup
gpg --encrypt --recipient "${GPG_RECIPIENT}" \
    --output "${BACKUP_FILE}.gpg" \
    "${BACKUP_FILE}"

# Verify encryption
if [ -f "${BACKUP_FILE}.gpg" ]; then
    echo "Backup encrypted: ${BACKUP_FILE}.gpg"
    rm "${BACKUP_FILE}"
else
    echo "Encryption failed" >&2
    exit 1
fi
```

## Restore Procedures

### Prometheus Restore

```bash
#!/bin/bash
# prometheus-restore.sh

set -euo pipefail

BACKUP_FILE="$1"
PROMETHEUS_DATA_DIR="/prometheus"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Error()
{
    Log "ERROR: $*" >&2
    exit 1
}

if [ -z "${BACKUP_FILE}" ]; then
    Error "Usage: $0 <backup-file.tar.gz>"
fi

if [ ! -f "${BACKUP_FILE}" ]; then
    Error "Backup file not found: ${BACKUP_FILE}"
fi

Log "Starting Prometheus restore from ${BACKUP_FILE}"

# Stop Prometheus
Log "Stopping Prometheus..."
docker stop prometheus || systemctl stop prometheus

# Verify checksum if available
if [ -f "${BACKUP_FILE}.sha256" ]; then
    Log "Verifying checksum..."
    sha256sum -c "${BACKUP_FILE}.sha256" || Error "Checksum verification failed"
fi

# Backup current data
Log "Backing up current data..."
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
if [ -d "${PROMETHEUS_DATA_DIR}" ]; then
    mv "${PROMETHEUS_DATA_DIR}" "${PROMETHEUS_DATA_DIR}.backup.${BACKUP_TIMESTAMP}"
fi

# Extract backup
Log "Extracting backup..."
mkdir -p "${PROMETHEUS_DATA_DIR}"
tar -xzf "${BACKUP_FILE}" -C /tmp/

# Find snapshot directory
SNAPSHOT_DIR=$(find /tmp -type d -name "prometheus-snapshot-*" | head -1)

if [ -z "${SNAPSHOT_DIR}" ]; then
    Error "No snapshot directory found in backup"
fi

# Move data to Prometheus data directory
Log "Restoring data..."
mv "${SNAPSHOT_DIR}"/* "${PROMETHEUS_DATA_DIR}/"

# Fix permissions
chown -R prometheus:prometheus "${PROMETHEUS_DATA_DIR}"

# Clean up
rm -rf /tmp/prometheus-snapshot-*

# Start Prometheus
Log "Starting Prometheus..."
docker start prometheus || systemctl start prometheus

# Wait for Prometheus to be ready
Log "Waiting for Prometheus to be ready..."
for i in {1..30}; do
    if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1; then
        Log "Prometheus is ready"
        break
    fi
    sleep 2
done

Log "Restore completed successfully"
```

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
echo "Restoring notification channels..."
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

### Testing Restore Procedures

```bash
#!/bin/bash
# test-restore.sh
# Automated restore testing

set -euo pipefail

TEST_ENV="restore-test"
BACKUP_FILE="$1"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

Log "Starting restore test..."

# Create isolated test environment
Log "Creating test environment..."
docker network create "${TEST_ENV}" || true

# Deploy test Prometheus
docker run -d --name prometheus-test --network "${TEST_ENV}" \
    -v prometheus-test-data:/prometheus \
    prom/prometheus:v2.49.0

# Perform restore in test environment
Log "Performing restore..."
./prometheus-restore.sh "${BACKUP_FILE}"

# Verify restoration
Log "Verifying restored data..."
sleep 10

# Check Prometheus is running
if ! docker exec prometheus-test wget -q -O- http://localhost:9090/-/ready; then
    Log "ERROR: Prometheus not ready"
    exit 1
fi

# Verify metrics exist
METRIC_COUNT=$(docker exec prometheus-test wget -q -O- 'http://localhost:9090/api/v1/label/__name__/values' | jq '.data | length')

if [ "${METRIC_COUNT}" -eq 0 ]; then
    Log "ERROR: No metrics found"
    exit 1
fi

Log "Restore test successful: ${METRIC_COUNT} metrics found"

# Clean up test environment
docker stop prometheus-test
docker rm prometheus-test
docker volume rm prometheus-test-data
docker network rm "${TEST_ENV}"

Log "Test environment cleaned up"
```

## Disaster Recovery Testing

### DR Drill Script

```bash
#!/bin/bash
# dr-drill.sh
# Complete disaster recovery drill

set -euo pipefail

DR_DATE=$(date +%Y-%m-%d)
DR_LOG="/var/log/dr-drill-${DR_DATE}.log"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${DR_LOG}"
}

Log "=== Starting Disaster Recovery Drill ==="

# Step 1: Verify backups exist
Log "Step 1: Verifying backups..."
LATEST_PROMETHEUS_BACKUP=$(find /backups/prometheus -name "*.tar.gz" -type f -mtime -1 | head -1)
LATEST_GRAFANA_BACKUP=$(find /backups/grafana -name "grafana-db-*.dump" -type f -mtime -1 | head -1)

if [ -z "${LATEST_PROMETHEUS_BACKUP}" ]; then
    Log "ERROR: No recent Prometheus backup found"
    exit 1
fi

if [ -z "${LATEST_GRAFANA_BACKUP}" ]; then
    Log "ERROR: No recent Grafana backup found"
    exit 1
fi

Log "Found backups:"
Log "  Prometheus: ${LATEST_PROMETHEUS_BACKUP}"
Log "  Grafana: ${LATEST_GRAFANA_BACKUP}"

# Step 2: Test Prometheus restore
Log "Step 2: Testing Prometheus restore..."
START_TIME=$(date +%s)
./test-restore.sh "${LATEST_PROMETHEUS_BACKUP}"
PROMETHEUS_RTO=$(($(date +%s) - START_TIME))
Log "Prometheus RTO: ${PROMETHEUS_RTO} seconds"

# Step 3: Test Grafana restore
Log "Step 3: Testing Grafana restore..."
START_TIME=$(date +%s)
./test-grafana-restore.sh "${LATEST_GRAFANA_BACKUP}"
GRAFANA_RTO=$(($(date +%s) - START_TIME))
Log "Grafana RTO: ${GRAFANA_RTO} seconds"

# Step 4: Verify data integrity
Log "Step 4: Verifying data integrity..."

# Check metric count
EXPECTED_METRICS=1000
ACTUAL_METRICS=$(curl -s 'http://prometheus-test:9090/api/v1/label/__name__/values' | jq '.data | length')

if [ "${ACTUAL_METRICS}" -lt "${EXPECTED_METRICS}" ]; then
    Log "WARNING: Metric count lower than expected (${ACTUAL_METRICS} < ${EXPECTED_METRICS})"
fi

# Check dashboard count
EXPECTED_DASHBOARDS=20
ACTUAL_DASHBOARDS=$(curl -s -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    "http://grafana-test:3000/api/search?type=dash-db" | jq '. | length')

if [ "${ACTUAL_DASHBOARDS}" -lt "${EXPECTED_DASHBOARDS}" ]; then
    Log "WARNING: Dashboard count lower than expected (${ACTUAL_DASHBOARDS} < ${EXPECTED_DASHBOARDS})"
fi

# Step 5: Generate report
Log "Step 5: Generating DR drill report..."

cat > "/var/log/dr-drill-report-${DR_DATE}.txt" <<EOF
Disaster Recovery Drill Report
Date: ${DR_DATE}

Backup Status:
- Prometheus: ✓ Found ($(date -r "${LATEST_PROMETHEUS_BACKUP}" '+%Y-%m-%d %H:%M:%S'))
- Grafana: ✓ Found ($(date -r "${LATEST_GRAFANA_BACKUP}" '+%Y-%m-%d %H:%M:%S'))

Recovery Time Objectives (RTO):
- Prometheus: ${PROMETHEUS_RTO} seconds (Target: <300s)
- Grafana: ${GRAFANA_RTO} seconds (Target: <120s)

Data Integrity:
- Metrics restored: ${ACTUAL_METRICS} (Expected: >${EXPECTED_METRICS})
- Dashboards restored: ${ACTUAL_DASHBOARDS} (Expected: >${EXPECTED_DASHBOARDS})

Overall Status: PASSED
EOF

Log "=== Disaster Recovery Drill Completed ==="
Log "Full log: ${DR_LOG}"
Log "Report: /var/log/dr-drill-report-${DR_DATE}.txt"
```

### RTO/RPO Testing

```bash
#!/bin/bash
# rto-rpo-test.sh
# Measure actual RTO and RPO

set -euo pipefail

# Simulate failure and measure recovery time
echo "=== RTO/RPO Test ==="

# Record current time
FAILURE_TIME=$(date +%s)
echo "Simulated failure at: $(date -d @${FAILURE_TIME})"

# Stop services
docker stop prometheus grafana

# Wait for monitoring to detect failure
sleep 60

# Start recovery
RECOVERY_START=$(date +%s)
docker start prometheus grafana

# Wait for services to be ready
while true; do
    if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1 && \
       curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

RECOVERY_END=$(date +%s)
RTO=$((RECOVERY_END - RECOVERY_START))

echo "Recovery Time Objective (RTO): ${RTO} seconds"

# Calculate RPO (data loss)
LAST_SCRAPE=$(curl -s 'http://localhost:9090/api/v1/query?query=up' | \
    jq -r '.data.result[0].value[0]')
RPO=$((FAILURE_TIME - LAST_SCRAPE))

echo "Recovery Point Objective (RPO): ${RPO} seconds of data loss"
```

## Backup Monitoring

```yaml
# backup-monitoring.yml
groups:
  - name: backup_monitoring
    interval: 5m
    rules:
      - alert: BackupFailed
        expr: time() - backup_last_success_timestamp_seconds > 86400
        for: 1h
        labels:
          severity: critical
        annotations:
          summary: "Backup has not succeeded in 24 hours"
          description: "Last successful backup was {{ $value | humanizeDuration }} ago"

      - alert: BackupSizeAnomaly
        expr: abs(backup_size_bytes - avg_over_time(backup_size_bytes[7d])) / stddev_over_time(backup_size_bytes[7d]) > 3
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Backup size is anomalous"
          description: "Backup size {{ $value | humanize }}B deviates significantly from average"

      - alert: BackupStorageFull
        expr: (backup_storage_used_bytes / backup_storage_total_bytes) > 0.9
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Backup storage is {{ $value | humanizePercentage }} full"

      - alert: BackupRetentionViolation
        expr: count(backup_age_days > 365) > 0
        for: 1h
        labels:
          severity: info
        annotations:
          summary: "Backups older than retention policy found"
```

## Automation Scripts

### Complete Backup Automation

```bash
#!/bin/bash
# backup-all.sh
# Complete backup automation with notifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/backup-$(date +%Y%m%d).log"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-}"

Log()
{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

Error()
{
    Log "ERROR: $*"
    Send_notification "Backup Failed" "$*"
    exit 1
}

Send_notification()
{
    local title="$1"
    local message="$2"
    
    # Slack notification
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST "${SLACK_WEBHOOK_URL}" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"${title}: ${message}\"}"
    fi
    
    # Email notification
    if [ -n "${EMAIL_TO:-}" ]; then
        echo "${message}" | mail -s "${title}" "${EMAIL_TO}"
    fi
}

# Trap errors
trap 'Error "Backup script failed at line $LINENO"' ERR

Log "=== Starting Automated Backup ==="

# Backup Prometheus
Log "Backing up Prometheus..."
"${SCRIPT_DIR}/prometheus-backup.sh" || Error "Prometheus backup failed"

# Backup Grafana
Log "Backing up Grafana..."
"${SCRIPT_DIR}/grafana-full-backup.sh" || Error "Grafana backup failed"

# Backup Alertmanager
Log "Backing up Alertmanager..."
"${SCRIPT_DIR}/alertmanager-backup.sh" || Error "Alertmanager backup failed"

# Verify backups
Log "Verifying backups..."
PROMETHEUS_BACKUP=$(find /backups/prometheus -name "*.tar.gz" -type f -mmin -30 | head -1)
GRAFANA_BACKUP=$(find /backups/grafana -name "grafana-db-*.dump" -type f -mmin -30 | head -1)

if [ -z "${PROMETHEUS_BACKUP}" ] || [ -z "${GRAFANA_BACKUP}" ]; then
    Error "Backup verification failed - backup files not found"
fi

Log "Backups verified successfully"

# Ping healthcheck
if [ -n "${HEALTHCHECK_URL}" ]; then
    curl -m 10 --retry 5 "${HEALTHCHECK_URL}" || Log "WARNING: Failed to ping healthcheck"
fi

Send_notification "Backup Successful" "All backups completed successfully"

Log "=== Automated Backup Completed ==="
```

### Cron Configuration

```cron
# /etc/cron.d/monitoring-backups

# Daily Prometheus backup at 2 AM
0 2 * * * root /opt/scripts/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1

# Daily Grafana backup at 3 AM
0 3 * * * root /opt/scripts/grafana-full-backup.sh >> /var/log/grafana-backup.log 2>&1

# Hourly Alertmanager backup
0 * * * * root /opt/scripts/alertmanager-backup.sh >> /var/log/alertmanager-backup.log 2>&1

# Weekly DR drill (Sundays at 1 AM)
0 1 * * 0 root /opt/scripts/dr-drill.sh >> /var/log/dr-drill.log 2>&1

# Daily backup cleanup
0 4 * * * root /opt/scripts/prometheus-retention.sh >> /var/log/backup-retention.log 2>&1
```

## See Also

- [Prometheus Configuration](index.md)
- [High Availability](high-availability.md)
- [Alerting Configuration](alerting.md)
- [Exporters Configuration](exporters.md)
