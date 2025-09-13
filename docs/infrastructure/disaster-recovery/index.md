---
title: Disaster Recovery
description: Comprehensive disaster recovery planning, implementation, and testing strategies for infrastructure and applications
author: Joseph Streeter
date: 2024-01-15
tags: [disaster-recovery, backup, business-continuity, incident-response, infrastructure]
---

Disaster recovery (DR) encompasses the strategies, policies, and procedures that enable an organization to recover or continue its technology infrastructure critical to supporting business functions after a natural or human-induced disaster. This guide provides a comprehensive framework for implementing effective disaster recovery solutions.

## Disaster Recovery Fundamentals

### Key Concepts

#### Recovery Time Objective (RTO)

The maximum acceptable length of time that a computer system can be down after a failure or disaster occurs.

#### Recovery Point Objective (RPO)

The maximum amount of data loss that is acceptable during a disaster recovery scenario.

#### Business Impact Analysis (BIA)

Process that identifies and evaluates the potential effects of interruptions to critical business operations.

### DR Planning Framework

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Disaster Recovery Framework                  │
├─────────────────────────────────────────────────────────────────┤
│  1. Risk Assessment     │ Identify threats and vulnerabilities  │
│  2. Business Impact     │ Analyze critical business functions   │
│  3. Recovery Strategy   │ Define recovery approaches            │
│  4. Plan Development    │ Create detailed recovery procedures   │
│  5. Testing & Training  │ Validate and rehearse recovery plans  │
│  6. Maintenance         │ Keep plans current and effective      │
└─────────────────────────────────────────────────────────────────┘
```

## Risk Assessment and Business Impact Analysis

### Threat Identification

#### Natural Disasters

- **Earthquakes**: Structural damage, power outages
- **Floods**: Equipment damage, facility access issues
- **Fires**: Complete facility destruction, smoke damage
- **Severe Weather**: Power outages, communication disruption

#### Human-Caused Threats

- **Cyber Attacks**: Ransomware, data breaches, system compromise
- **Sabotage**: Internal threats, malicious actions
- **Terrorism**: Physical and cyber terrorism
- **Human Error**: Accidental deletion, configuration mistakes

#### Technology Failures

- **Hardware Failures**: Server crashes, storage failures
- **Software Failures**: Application bugs, OS corruption
- **Network Failures**: ISP outages, equipment failures
- **Power Failures**: Grid failures, UPS failures

### Business Impact Assessment

#### Critical Business Functions

```bash
# Business function criticality assessment template
cat > business-functions-assessment.txt << EOF
Function: Customer Order Processing
- Criticality: High
- RTO: 2 hours
- RPO: 15 minutes
- Dependencies: Database, Payment Gateway, Inventory System
- Impact of Downtime: $10,000/hour revenue loss

Function: Email Communications
- Criticality: Medium
- RTO: 4 hours
- RPO: 1 hour
- Dependencies: Exchange Server, Active Directory
- Impact of Downtime: Communication delays, customer service impact

Function: Internal File Sharing
- Criticality: Low
- RTO: 24 hours
- RPO: 8 hours
- Dependencies: File Server, Active Directory
- Impact of Downtime: Reduced productivity
EOF
```

## Backup Strategies

### Backup Types

#### Full Backup

Complete copy of all data at a specific point in time.

```bash
# Example: Full backup with tar
tar -czf /backup/full-backup-$(date +%Y%m%d).tar.gz /data/

# Example: Full backup with rsync
rsync -av --delete /data/ /backup/full-backup/
```

#### Incremental Backup

Backs up only data that has changed since the last backup.

```bash
# Example: Incremental backup script
#!/bin/bash
BACKUP_DIR="/backup/incremental"
SOURCE_DIR="/data"
DATE=$(date +%Y%m%d-%H%M%S)

# Create incremental backup
rsync -av --link-dest="$BACKUP_DIR/latest" "$SOURCE_DIR/" "$BACKUP_DIR/$DATE/"

# Update latest symlink
rm -f "$BACKUP_DIR/latest"
ln -s "$DATE" "$BACKUP_DIR/latest"
```

#### Differential Backup

Backs up all data changed since the last full backup.

```bash
# Example: Differential backup using find and tar
find /data -newer /backup/last-full-backup.timestamp -type f | \
    tar -czf /backup/differential-$(date +%Y%m%d).tar.gz -T -
```

### 3-2-1 Backup Rule

- **3 copies** of important data
- **2 different** storage media types
- **1 copy** stored offsite

```bash
# Implementation example
#!/bin/bash
# Primary backup to local storage
rsync -av /data/ /backup/local/

# Secondary backup to network storage
rsync -av /data/ /backup/network/

# Offsite backup to cloud storage
aws s3 sync /data/ s3://company-backup-bucket/data/
```

### Backup Automation

#### Linux Backup Script

```bash
#!/bin/bash
# Comprehensive backup script

# Configuration
SOURCE_DIRS=("/etc" "/home" "/var/log" "/opt")
BACKUP_BASE="/backup"
RETENTION_DAYS=30
LOG_FILE="/var/log/backup.log"
EMAIL_RECIPIENT="admin@company.com"

# Functions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

cleanup_old_backups() {
    find "$BACKUP_BASE" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    log_message "Cleaned up backups older than $RETENTION_DAYS days"
}

perform_backup() {
    local backup_date=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_BASE/backup-$backup_date.tar.gz"
    
    log_message "Starting backup to $backup_file"
    
    if tar -czf "$backup_file" "${SOURCE_DIRS[@]}" 2>/dev/null; then
        log_message "Backup completed successfully"
        
        # Verify backup integrity
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            log_message "Backup verification passed"
        else
            log_message "ERROR: Backup verification failed"
            return 1
        fi
    else
        log_message "ERROR: Backup failed"
        return 1
    fi
}

send_notification() {
    local status=$1
    if [ "$status" -eq 0 ]; then
        echo "Backup completed successfully on $(hostname)" | \
            mail -s "Backup Success - $(hostname)" "$EMAIL_RECIPIENT"
    else
        echo "Backup failed on $(hostname). Check $LOG_FILE for details." | \
            mail -s "Backup FAILED - $(hostname)" "$EMAIL_RECIPIENT"
    fi
}

# Main execution
main() {
    log_message "Starting backup process"
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_BASE"
    
    # Perform backup
    if perform_backup; then
        cleanup_old_backups
        send_notification 0
        log_message "Backup process completed successfully"
        exit 0
    else
        send_notification 1
        log_message "Backup process failed"
        exit 1
    fi
}

main "$@"
```

## High Availability and Redundancy

### Database High Availability

#### MySQL Master-Slave Replication

```sql
-- Master configuration
-- /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-do-db = production_db

-- Create replication user
CREATE USER 'replication'@'%' IDENTIFIED BY 'secure_password';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
FLUSH PRIVILEGES;

-- Get master status
SHOW MASTER STATUS;
```

```sql
-- Slave configuration
-- /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
server-id = 2
relay-log = mysql-relay-bin
read-only = 1

-- Configure replication
CHANGE MASTER TO
    MASTER_HOST='master-server-ip',
    MASTER_USER='replication',
    MASTER_PASSWORD='secure_password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=154;

START SLAVE;
SHOW SLAVE STATUS\G
```

#### PostgreSQL Streaming Replication

```bash
# Primary server configuration
# postgresql.conf
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 32
archive_mode = on
archive_command = 'cp %p /archive/%f'

# pg_hba.conf
host replication replicator standby-server-ip/32 md5
```

```bash
# Standby server setup
pg_basebackup -h primary-server-ip -D /var/lib/postgresql/12/main \
    -U replicator -v -P -W -R
```

### Application Load Balancing

#### HAProxy Configuration

```bash
# /etc/haproxy/haproxy.cfg
global
    daemon
    maxconn 4096
    log stdout local0

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog

frontend web_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/website.pem
    redirect scheme https if !{ ssl_fc }
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 10.0.1.10:80 check
    server web2 10.0.1.11:80 check
    server web3 10.0.1.12:80 check

listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats auth admin:secure_password
```

## Related Topics

- [Infrastructure Monitoring](../monitoring/index.md)
- [Container Security](../containers/security/index.md)
- [Windows Security](../windows/security/index.md)
- [Network Security](../networking/security/index.md)

## Topics

Add topics here.
