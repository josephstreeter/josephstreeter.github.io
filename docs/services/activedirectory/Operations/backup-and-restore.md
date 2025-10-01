---
title: Active Directory Backup and Restore
description: Comprehensive guide to backing up and restoring Active Directory Domain Services
author: Joseph Streeter
date: 2024-01-15
tags: [active-directory, backup, restore, disaster-recovery, operations]
---
## Overview

Comprehensive guide to backing up and restoring Active Directory Domain Services components and data.

Active Directory backup and restore operations are critical for disaster recovery and business continuity. This guide covers:

- System State backups for domain controllers
- SYSVOL backup and replication
- Database backup procedures
- Forest and domain recovery scenarios
- Best practices for backup scheduling

## Backup Procedures

### System State Backup

System State backups include all critical AD components:

- Active Directory database (NTDS.DIT)
- Registry settings
- System files
- SYSVOL folder contents

### Backup Commands

Using Windows Server Backup:

```powershell
# Create system state backup
wbadmin start systemstatebackup -backuptarget:D:\Backups
```

### Automated Backup Scheduling

Configure regular automated backups using Task Scheduler or Group Policy.

## Restore Procedures

### Non-Authoritative Restore

Standard restore when AD database corruption occurs:

1. Boot into Directory Services Restore Mode (DSRM)
2. Restore system state from backup
3. Restart in normal mode

### Authoritative Restore

When specific objects need to be restored and replicated:

1. Perform non-authoritative restore
2. Use ntdsutil for authoritative restore
3. Restart replication services

## Recovery Scenarios

### Single Domain Controller Recovery

- Restore from system state backup
- Verify replication health

### Multiple Domain Controller Loss

- Forest recovery procedures
- SYSVOL restoration
- Global catalog rebuilding

## Related Topics

- **[Forest Recovery](active-directory-forest-recovery.md)** - Complete forest disaster recovery
- **[Disaster Recovery Planning](../configuration/disaster-recovery.md)** - DR strategy and planning
- **[Monitoring and Alerting](monitoring-and-alerting.md)** - Health monitoring
