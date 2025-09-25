---
title: "Complete SystemD Service Management Guide"
description: "Comprehensive guide to systemd service management, unit files, timers, and enterprise best practices for Linux system administration"
ms.date: 09/13/2025
author: josephstreeter
ms.author: joseph.streeter
ms.topic: how-to
ms.service: linux
keywords: systemd, linux, service management, unit files, timers, systemctl, journalctl
---

## Complete SystemD Service Management Guide

## Table of Contents

- [Overview and Architecture](#overview-and-architecture)
- [Essential Commands](#essential-commands)
- [Unit File Management](#unit-file-management)
- [Service Configuration](#service-configuration)
- [Timer Units and Scheduling](#timer-units-and-scheduling)
- [Logging and Monitoring](#logging-and-monitoring)
- [Security and Hardening](#security-and-hardening)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Enterprise Best Practices](#enterprise-best-practices)
- [Automation and Scripting](#automation-and-scripting)

---

## Overview and Architecture

**SystemD** is the modern init system and service manager that has become the standard for most Linux distributions. It provides a unified framework for managing system services, processes, and system state with advanced features like parallel startup, dependency management, and comprehensive logging.

### Key Components

| Component | Purpose | Description |
|-----------|---------|-------------|
| **systemctl** | Service Control | Primary command-line interface for managing services |
| **journalctl** | Log Management | Query and manage systemd logs and journal |
| **systemd-analyze** | Performance Analysis | Analyze boot performance and service dependencies |
| **systemd-run** | Ad-hoc Execution | Run commands as transient services |
| **systemd-escape** | Name Escaping | Escape strings for use in unit names |

### System Architecture

```mermaid
graph TB
    A[systemd PID 1] --> B[System Services]
    A --> C[User Services]
    A --> D[Targets/Runlevels]
    B --> E[Network Services]
    B --> F[Storage Services]
    B --> G[Application Services]
    C --> H[User Session]
    C --> I[Desktop Environment]
    D --> J[Boot Process]
    D --> K[System States]
```

### Advantages Over Traditional Init

- ✅ **Parallel Service Startup** - Faster boot times
- ✅ **Dependency Management** - Intelligent service ordering
- ✅ **Socket-based Activation** - On-demand service startup
- ✅ **Process Supervision** - Automatic restart and monitoring
- ✅ **Unified Logging** - Centralized log management with journald
- ✅ **Resource Management** - Built-in cgroups integration
- ✅ **Security Features** - Advanced sandboxing and isolation
- ✅ **Timer Integration** - Modern replacement for cron

---

## ⚡ **Essential Commands**

---

## Essential Commands

### Service Lifecycle Management

#### Basic Service Operations

```bash
# Start a service immediately
sudo systemctl start <service-name>

# Stop a running service
sudo systemctl stop <service-name>

# Restart a service (stop then start)
sudo systemctl restart <service-name>

# Reload service configuration without restarting
sudo systemctl reload <service-name>

# Restart only if service is already running
sudo systemctl try-restart <service-name>

# Reload configuration, restart if reload not supported
sudo systemctl reload-or-restart <service-name>
```

#### Boot Configuration

```bash
# Enable service to start automatically at boot
sudo systemctl enable <service-name>

# Disable service from starting at boot
sudo systemctl disable <service-name>

# Enable and start service in one command
sudo systemctl enable --now <service-name>

# Disable and stop service in one command
sudo systemctl disable --now <service-name>

# Mask service (prevent it from being started)
sudo systemctl mask <service-name>

# Unmask a previously masked service
sudo systemctl unmask <service-name>
```

### Service Status and Information

#### Service Status Commands

```bash
# Check detailed service status
systemctl status <service-name>

# Check if service is currently active
systemctl is-active <service-name>

# Check if service is enabled for boot
systemctl is-enabled <service-name>

# Check if service has failed
systemctl is-failed <service-name>

# Show service properties
systemctl show <service-name>

# Show specific property
systemctl show <service-name> -p ActiveState
```

#### System-wide Service Listing

```bash
# List all loaded services
systemctl list-units --type=service

# List all services (including inactive)
systemctl list-units --type=service --all

# List only active services
systemctl list-units --type=service --state=active

# List only failed services
systemctl list-units --type=service --state=failed

# List enabled services
systemctl list-unit-files --type=service --state=enabled

# List disabled services
systemctl list-unit-files --type=service --state=disabled
```

### Advanced Service Operations

#### Service Dependencies

```bash
# List service dependencies
systemctl list-dependencies <service-name>

# Show what services depend on this service
systemctl list-dependencies <service-name> --reverse

# Show dependency tree
systemctl list-dependencies <service-name> --all

# Check what services are required by a target
systemctl list-dependencies graphical.target
```

#### Process Information

```bash
# Show main process ID
systemctl show <service-name> -p MainPID

# Show all processes in service cgroup
systemd-cgls <service-name>

# Show resource usage
systemd-cgtop

# Kill all processes in service
sudo systemctl kill <service-name>

# Send specific signal to service
sudo systemctl kill -s HUP <service-name>
```

---

## Unit File Management

### Unit File Hierarchy and Precedence

SystemD follows a specific hierarchy for unit files with different precedence levels:

| Priority | Location | Purpose | Use Case |
|----------|----------|---------|----------|
| **1** | `/etc/systemd/system/` | Local/custom unit files | Custom services, overrides |
| **2** | `/run/systemd/system/` | Runtime unit files | Temporary/transient services |
| **3** | `/usr/lib/systemd/system/` | Distribution packages | Package-provided services |

#### Unit File Operations

```bash
# List all unit files and their states
systemctl list-unit-files

# Show unit file content
systemctl cat <service-name>

# Edit unit file (creates override)
sudo systemctl edit <service-name>

# Edit full unit file
sudo systemctl edit --full <service-name>

# Reload systemd configuration after changes
sudo systemctl daemon-reload

# Verify unit file syntax
systemd-analyze verify /path/to/unit-file

# Show unit file locations
systemctl show <service-name> -p FragmentPath
```

### Unit File Structure and Sections

#### Complete Unit File Template

```ini
# /etc/systemd/system/example.service
[Unit]
# Service metadata and dependencies
Description=Example Service Description
Documentation=https://example.com/docs
After=network.target syslog.target
Before=nginx.service
Requires=postgresql.service
Wants=redis.service
Conflicts=example-old.service
OnFailure=failure-notification.service

# Conditions for starting
ConditionPathExists=/opt/example/bin/example
ConditionUser=!root
AssertPathExists=/opt/example/config/

[Service]
# Service execution configuration
Type=notify
User=example-user
Group=example-group
WorkingDirectory=/opt/example
Environment="ENVIRONMENT=production"
Environment="LOG_LEVEL=info"
EnvironmentFile=/etc/example/environment

# Execution commands
ExecStartPre=/opt/example/bin/pre-start.sh
ExecStart=/opt/example/bin/example-daemon
ExecStartPost=/opt/example/bin/post-start.sh
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/opt/example/bin/graceful-stop.sh
ExecStopPost=/opt/example/bin/cleanup.sh

# Process management
PIDFile=/var/run/example/example.pid
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=30
KillMode=mixed
KillSignal=SIGTERM

# Resource limits
MemoryLimit=512M
CPUQuota=50%
TasksMax=100
LimitNOFILE=65536

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/example /var/log/example

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=example-service

[Install]
# Installation configuration
WantedBy=multi-user.target
RequiredBy=critical-service.target
Also=example-monitoring.service
Alias=example.service
```

### Service Types Detailed

#### Service Type Comparison

| Type | Description | Use Case | Process Behavior |
|------|-------------|----------|------------------|
| **simple** | Default type, starts immediately | Long-running daemons | systemd assumes service started when ExecStart process starts |
| **exec** | Similar to simple, waits for execve() | Services needing initialization time | systemd waits until execve() call succeeds |
| **forking** | Service forks and parent exits | Traditional daemons | systemd waits for parent process to exit |
| **oneshot** | Runs once and exits | Scripts, initialization | Service considered active until process exits |
| **notify** | Service sends readiness notification | Modern daemons with sd_notify | Service must call sd_notify() to signal readiness |
| **idle** | Delays execution | Services sensitive to console output | Waits until other jobs finish before starting |

#### Service Type Examples

```ini
# Simple service (default)
[Service]
Type=simple
ExecStart=/usr/bin/my-daemon

# Forking service
[Service]
Type=forking
PIDFile=/var/run/mydaemon.pid
ExecStart=/usr/bin/mydaemon --daemon

# Notify service
[Service]
Type=notify
ExecStart=/usr/bin/modern-daemon
NotifyAccess=main

# Oneshot service
[Service]
Type=oneshot
ExecStart=/usr/bin/setup-script.sh
RemainAfterExit=yes

# Idle service
[Service]
Type=idle
ExecStart=/usr/bin/console-sensitive-service
```

### Unit File Best Practices

#### Dependency Management

```ini
# Use After= for ordering without hard dependency
After=network.target

# Use Wants= for soft dependencies
Wants=database.service

# Use Requires= for hard dependencies
Requires=network.target

# Prevent conflicts with other services
Conflicts=old-version.service

# Set up failure handling
OnFailure=alert-service.service
```

#### Environment and Security

```ini
# Environment configuration
Environment="VAR1=value1"
Environment="VAR2=value2"
EnvironmentFile=/etc/myservice/config

# Security hardening
User=myservice
Group=myservice
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

---

## Service Configuration

### Real-World Service Examples

#### Node.js Web Application

```ini
# /etc/systemd/system/webapp.service
[Unit]
Description=Node.js Web Application
Documentation=https://github.com/company/webapp
After=network.target
Wants=network.target

[Service]
Type=simple
User=webapp
Group=webapp
WorkingDirectory=/opt/webapp
Environment=NODE_ENV=production
Environment=PORT=3000
EnvironmentFile=/etc/webapp/environment
ExecStartPre=/usr/bin/npm install --production
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webapp

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/lib/webapp /var/log/webapp

# Resource limits
MemoryLimit=1G
CPUQuota=80%
TasksMax=100

[Install]
WantedBy=multi-user.target
```

#### Python Flask Application with Gunicorn

```ini
# /etc/systemd/system/flask-app.service
[Unit]
Description=Flask Application (Gunicorn)
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=notify
User=flask-app
Group=flask-app
WorkingDirectory=/opt/flask-app
Environment=FLASK_ENV=production
Environment=DATABASE_URL=postgresql://user:pass@localhost/db
ExecStart=/opt/flask-app/venv/bin/gunicorn --bind 127.0.0.1:5000 --workers 4 --timeout 30 --keep-alive 2 --max-requests 1000 --max-requests-jitter 100 app:application
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
TimeoutStopSec=15
Restart=on-failure
RestartSec=3

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/flask-app
CapabilityBoundingSet=

[Install]
WantedBy=multi-user.target
```

#### Database Service (PostgreSQL-style)

```ini
# /etc/systemd/system/custom-db.service
[Unit]
Description=Custom Database Service
Documentation=https://docs.example.com/database
After=network.target
Before=application.service

[Service]
Type=notify
User=database
Group=database
WorkingDirectory=/var/lib/database

# Pre-flight checks
ExecStartPre=/usr/local/bin/db-preflight-check.sh
ExecStartPre=/bin/mkdir -p /var/run/database
ExecStartPre=/bin/chown database:database /var/run/database

# Main service
ExecStart=/usr/local/bin/database-server --config=/etc/database/database.conf
ExecReload=/bin/kill -HUP $MAINPID

# Graceful shutdown
ExecStop=/usr/local/bin/database-shutdown.sh
TimeoutStopSec=300

# Post-stop cleanup
ExecStopPost=/bin/rm -rf /var/run/database

# Process management
PIDFile=/var/run/database/database.pid
Restart=on-failure
RestartSec=10

# Resource limits
MemoryLimit=8G
CPUWeight=200
IOWeight=200

# Security
PrivateNetwork=false
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/lib/database /var/log/database
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
```

#### Monitoring and Backup Service

```ini
# /etc/systemd/system/backup-service.service
[Unit]
Description=Automated Backup Service
Documentation=file:///etc/backup/README.md
After=network.target

[Service]
Type=oneshot
User=backup
Group=backup
WorkingDirectory=/opt/backup

# Environment
Environment=BACKUP_TYPE=incremental
EnvironmentFile=/etc/backup/config

# Execution
ExecStartPre=/opt/backup/scripts/pre-backup-check.sh
ExecStart=/opt/backup/scripts/perform-backup.sh
ExecStartPost=/opt/backup/scripts/post-backup-notify.sh

# Error handling
ExecStopPost=/opt/backup/scripts/cleanup-on-failure.sh

# Security
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/backup /var/log/backup
ReadOnlyPaths=/etc/backup

# Don't restart oneshot services
Restart=no

[Install]
WantedBy=multi-user.target
```

### Service Templates and Instantiation

#### Template Service

```ini
# /etc/systemd/system/worker@.service
[Unit]
Description=Worker Service Instance %i
Documentation=https://docs.example.com/worker
After=network.target

[Service]
Type=simple
User=worker
Group=worker
WorkingDirectory=/opt/worker
Environment=WORKER_ID=%i
Environment=WORKER_CONFIG=/etc/worker/worker-%i.conf
ExecStart=/opt/worker/bin/worker --instance=%i
Restart=on-failure
RestartSec=5

# Instance-specific resource limits
MemoryLimit=256M
CPUQuota=25%

[Install]
WantedBy=multi-user.target
```

#### Using Template Services

```bash
# Start specific instances
sudo systemctl start worker@1.service
sudo systemctl start worker@2.service
sudo systemctl start worker@web.service

# Enable instances for boot
sudo systemctl enable worker@1.service worker@2.service

# Check status of all instances
systemctl status 'worker@*'

# Start multiple instances at once
sudo systemctl start worker@{1..4}.service
```

### Service Overrides and Drop-ins

#### Creating Service Overrides

```bash
# Create override directory and file
sudo systemctl edit nginx.service
```

This creates `/etc/systemd/system/nginx.service.d/override.conf`:

```ini
[Service]
# Override specific settings
MemoryLimit=1G
CPUQuota=80%

# Add additional environment variables
Environment=CUSTOM_VAR=value

# Change restart behavior
Restart=always
RestartSec=3
```

#### Multiple Drop-in Files

```bash
# Create specific override files
sudo mkdir -p /etc/systemd/system/myservice.service.d/
sudo tee /etc/systemd/system/myservice.service.d/10-resources.conf << 'EOF'
[Service]
MemoryLimit=2G
CPUQuota=50%
EOF

sudo tee /etc/systemd/system/myservice.service.d/20-security.conf << 'EOF'
[Service]
NoNewPrivileges=true
PrivateTmp=true
EOF

# Reload configuration
sudo systemctl daemon-reload
```

### PowerShell Service Management Scripts

#### Service Status Monitor

```powershell
function Get-SystemdServiceStatus
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,
        [switch]$IncludeResources,
        [switch]$ExportToJson
    )
    
    $serviceStats = @()
    
    foreach ($serviceName in $ServiceNames)
    {
        try
        {
            # Get basic service information
            $statusOutput = & systemctl status $serviceName --no-pager --lines=0 2>&1
            $isActive = (& systemctl is-active $serviceName) -eq "active"
            $isEnabled = (& systemctl is-enabled $serviceName) -eq "enabled"
            
            # Get service properties
            $properties = @{}
            $showOutput = & systemctl show $serviceName
            foreach ($line in $showOutput)
            {
                if ($line -match "^([^=]+)=(.*)$")
                {
                    $properties[$matches[1]] = $matches[2]
                }
            }
            
            $serviceInfo = [PSCustomObject]@{
                ServiceName = $serviceName
                IsActive = $isActive
                IsEnabled = $isEnabled
                MainPID = $properties.MainPID
                LoadState = $properties.LoadState
                ActiveState = $properties.ActiveState
                SubState = $properties.SubState
                UnitFileState = $properties.UnitFileState
                StartTime = $properties.ActiveEnterTimestamp
                Memory = if ($IncludeResources) { $properties.MemoryCurrent } else { $null }
                CPUUsage = if ($IncludeResources) { $properties.CPUUsageNSec } else { $null }
                RestartCount = $properties.NRestarts
                LastExit = $properties.ExecMainStatus
            }
            
            $serviceStats += $serviceInfo
            Write-Host "✓ $serviceName - Active: $isActive, Enabled: $isEnabled" -ForegroundColor $(if ($isActive) { "Green" } else { "Red" })
        }
        catch
        {
            Write-Error "Failed to get status for service: $serviceName - $($_.Exception.Message)"
        }
    }
    
    if ($ExportToJson)
    {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = "systemd_services_$timestamp.json"
        $serviceStats | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile
        Write-Host "Service status exported to: $outputFile" -ForegroundColor Cyan
    }
    
    return $serviceStats
}
```

#### Bulk Service Management

```powershell
function Manage-SystemdServices
{
    param(
        [Parameter(Mandatory)]
        [ValidateSet("start", "stop", "restart", "enable", "disable", "status")]
        [string]$Action,
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,
        [switch]$Force,
        [string]$LogPath = "./service_management.log"
    )
    
    $results = @()
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "Starting bulk $Action operation for $($ServiceNames.Count) services..." -ForegroundColor Cyan
    
    foreach ($serviceName in $ServiceNames)
    {
        try
        {
            $actionCmd = "systemctl $Action $serviceName"
            if ($Force -and $Action -in @("stop", "restart"))
            {
                $actionCmd += " --force"
            }
            
            Write-Host "Processing: $serviceName" -ForegroundColor Yellow
            
            # Execute the systemctl command
            $output = Invoke-Expression "sudo $actionCmd" 2>&1
            $exitCode = $LASTEXITCODE
            
            $result = [PSCustomObject]@{
                Timestamp = $timestamp
                ServiceName = $serviceName
                Action = $Action
                Success = $exitCode -eq 0
                Output = $output -join "`n"
                ExitCode = $exitCode
            }
            
            $results += $result
            
            if ($exitCode -eq 0)
            {
                Write-Host "✓ $serviceName - $Action completed successfully" -ForegroundColor Green
                "$timestamp - SUCCESS: $serviceName - $Action" | Add-Content -Path $LogPath
            }
            else
            {
                Write-Host "✗ $serviceName - $Action failed (Exit Code: $exitCode)" -ForegroundColor Red
                "$timestamp - FAILED: $serviceName - $Action - $output" | Add-Content -Path $LogPath
            }
        }
        catch
        {
            Write-Error "Exception during $Action for $serviceName : $($_.Exception.Message)"
            "$timestamp - ERROR: $serviceName - $Action - Exception: $($_.Exception.Message)" | Add-Content -Path $LogPath
        }
    }
    
    # Summary
    $successCount = ($results | Where-Object Success).Count
    $failureCount = $results.Count - $successCount
    
    Write-Host "`nOperation Summary:" -ForegroundColor Cyan
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failureCount" -ForegroundColor Red
    Write-Host "  Log file: $LogPath" -ForegroundColor Yellow
    
    return $results
}
```

---

## Timer Units and Scheduling

SystemD timers provide a modern, powerful alternative to traditional cron jobs with better integration into the systemd ecosystem, improved logging, and more sophisticated scheduling options.

### Timer Types and Scheduling

#### Timer Types Overview

| Timer Type | Description | Use Case | Example |
|------------|-------------|----------|---------|
| **Monotonic** | Relative to system boot/start | System maintenance | `OnBootSec=15min` |
| **Realtime** | Calendar-based scheduling | Regular tasks | `OnCalendar=daily` |
| **Transient** | One-time execution | Ad-hoc tasks | `systemd-run --on-active=5min` |

#### Calendar Event Formats

```bash
# Common calendar formats
OnCalendar=minutely          # Every minute
OnCalendar=hourly            # Every hour
OnCalendar=daily             # Every day at midnight
OnCalendar=weekly            # Every Monday at midnight
OnCalendar=monthly           # First day of month at midnight
OnCalendar=yearly            # January 1st at midnight

# Specific times
OnCalendar=*-*-* 02:00:00    # Daily at 2 AM
OnCalendar=Mon,Fri 09:00     # Monday and Friday at 9 AM
OnCalendar=*-*-01 03:00      # First day of every month at 3 AM
OnCalendar=2025-12-25 10:00  # Specific date and time

# Complex scheduling
OnCalendar=Mon..Fri 09:00    # Weekdays at 9 AM
OnCalendar=*-*-* 09,17:00    # Daily at 9 AM and 5 PM
OnCalendar=*-01,07-01 12:00  # January 1st and July 1st at noon
```

### Comprehensive Timer Examples

#### Daily Backup Timer

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily System Backup
Documentation=file:///etc/backup/README.md
Requires=backup.service

[Timer]
# Run daily at 2 AM
OnCalendar=*-*-* 02:00:00
# Ensure it runs even if system was off
Persistent=true
# Add random delay up to 15 minutes
RandomizedDelaySec=15min
# Prevent multiple instances
AccuracySec=1min

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=System Backup Service
Documentation=file:///etc/backup/README.md
After=network.target

[Service]
Type=oneshot
User=backup
Group=backup
WorkingDirectory=/opt/backup
Environment=BACKUP_TYPE=daily
EnvironmentFile=/etc/backup/config

# Pre-backup checks
ExecStartPre=/opt/backup/scripts/check-disk-space.sh
ExecStartPre=/opt/backup/scripts/verify-mount-points.sh

# Main backup execution
ExecStart=/opt/backup/scripts/perform-backup.sh

# Post-backup tasks
ExecStartPost=/opt/backup/scripts/verify-backup.sh
ExecStartPost=/opt/backup/scripts/send-notification.sh

# Cleanup on failure
ExecStopPost=/opt/backup/scripts/cleanup-failed-backup.sh

# Security
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/backup /mnt/backup
ReadOnlyPaths=/etc/backup

# Resource limits
MemoryLimit=1G
CPUQuota=50%
IOWeight=10

# Timeout configuration
TimeoutStartSec=3600
```

#### Log Rotation Timer

```ini
# /etc/systemd/system/log-rotation.timer
[Unit]
Description=Custom Log Rotation
Requires=log-rotation.service

[Timer]
# Run every 6 hours
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true
RandomizedDelaySec=30min

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/log-rotation.service
[Unit]
Description=Custom Log Rotation Service

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/custom-logrotate.sh
StandardOutput=journal
StandardError=journal
```

#### System Monitoring Timer

```ini
# /etc/systemd/system/system-monitor.timer
[Unit]
Description=System Health Monitoring
Requires=system-monitor.service

[Timer]
# Run every 5 minutes
OnCalendar=*:0/5
Persistent=false
AccuracySec=30sec

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/system-monitor.service
[Unit]
Description=System Health Monitor

[Service]
Type=oneshot
User=monitor
Group=monitor
ExecStart=/opt/monitoring/scripts/health-check.sh
Environment=ALERT_THRESHOLD=90
EnvironmentFile=/etc/monitoring/config
StandardOutput=journal
StandardError=journal
```

### Advanced Timer Configuration

#### Timer with Multiple Schedules

```ini
# /etc/systemd/system/multi-schedule.timer
[Unit]
Description=Multi-Schedule Timer Example

[Timer]
# Multiple OnCalendar entries
OnCalendar=Mon,Wed,Fri 09:00
OnCalendar=Tue,Thu 14:00
OnCalendar=Sat 08:00
OnCalendar=Sun 20:00

# Persistent across reboots
Persistent=true

# Random delay to avoid system load spikes
RandomizedDelaySec=10min

# High precision timing
AccuracySec=1sec

[Install]
WantedBy=timers.target
```

#### Conditional Timer Execution

```ini
# /etc/systemd/system/conditional-task.service
[Unit]
Description=Conditional Task Execution
ConditionPathExists=/var/run/enable-task
ConditionUser=!root
AssertPathIsDirectory=/opt/tasks

[Service]
Type=oneshot
ExecStartPre=/opt/tasks/scripts/check-conditions.sh
ExecStart=/opt/tasks/scripts/run-task.sh
ExecStartPost=/opt/tasks/scripts/cleanup.sh
```

### Timer Management Commands

#### Basic Timer Operations

```bash
# List all timers
systemctl list-timers

# List all timers including inactive
systemctl list-timers --all

# Show detailed timer information
systemctl status backup.timer

# Start timer immediately (runs associated service now)
sudo systemctl start backup.timer

# Enable timer for automatic startup
sudo systemctl enable backup.timer

# Check when timer will run next
systemctl list-timers backup.timer

# Show timer properties
systemctl show backup.timer
```

#### Testing Timer Schedules

```bash
# Test calendar expressions
systemd-analyze calendar "Mon,Wed,Fri 09:00"
systemd-analyze calendar "*-*-* 02:00:00"
systemd-analyze calendar "weekly"

# Show next execution times
systemd-analyze calendar "*:0/5" --iterations=10

# Verify timer unit syntax
systemd-analyze verify /etc/systemd/system/backup.timer
```

### PowerShell Timer Management Scripts

#### Timer Status Monitor

```powershell
function Get-SystemdTimerStatus
{
    param(
        [string[]]$TimerNames = @(),
        [switch]$ShowNext10,
        [switch]$IncludeInactive
    )
    
    # Get all timers or specific ones
    $listTimersCmd = "systemctl list-timers"
    if ($IncludeInactive) { $listTimersCmd += " --all" }
    if ($TimerNames.Count -gt 0) { $listTimersCmd += " " + ($TimerNames -join " ") }
    
    $timersOutput = Invoke-Expression $listTimersCmd
    $timers = @()
    
    # Parse timer output (skip header lines)
    for ($i = 1; $i -lt $timersOutput.Count - 2; $i++)
    {
        $line = $timersOutput[$i]
        if ($line -match "^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$")
        {
            $timer = [PSCustomObject]@{
                NextRun = $matches[1] + " " + $matches[2]
                LastRun = $matches[3] + " " + $matches[4]
                UnitName = $matches[5]
                Status = "Active"
            }
            $timers += $timer
        }
    }
    
    # Get additional details for each timer
    foreach ($timer in $timers)
    {
        try
        {
            $statusOutput = & systemctl show $timer.UnitName --property=ActiveState,UnitFileState,NextElapseUSecRealtime
            foreach ($line in $statusOutput)
            {
                if ($line -match "^([^=]+)=(.*)$")
                {
                    $timer | Add-Member -NotePropertyName $matches[1] -NotePropertyValue $matches[2] -Force
                }
            }
            
            # Test calendar schedule if it exists
            $timerFile = "/etc/systemd/system/$($timer.UnitName)"
            if (Test-Path $timerFile)
            {
                $content = Get-Content $timerFile
                $onCalendarLine = $content | Where-Object { $_ -match "OnCalendar=(.+)" }
                if ($onCalendarLine)
                {
                    $calendar = $matches[1]
                    $timer | Add-Member -NotePropertyName "Schedule" -NotePropertyValue $calendar -Force
                    
                    if ($ShowNext10)
                    {
                        $nextRuns = & systemd-analyze calendar $calendar --iterations=10 2>/dev/null
                        $timer | Add-Member -NotePropertyName "Next10Runs" -NotePropertyValue $nextRuns -Force
                    }
                }
            }
        }
        catch
        {
            Write-Warning "Could not get detailed info for timer: $($timer.UnitName)"
        }
    }
    
    return $timers
}
```

#### Timer Schedule Analyzer

```powershell
function Test-SystemdTimerSchedule
{
    param(
        [Parameter(Mandatory)]
        [string]$CalendarExpression,
        [int]$Iterations = 5,
        [switch]$ValidateOnly
    )
    
    Write-Host "Testing calendar expression: $CalendarExpression" -ForegroundColor Cyan
    
    try
    {
        # Test the calendar expression
        $output = & systemd-analyze calendar $CalendarExpression --iterations=$Iterations 2>&1
        
        if ($LASTEXITCODE -eq 0)
        {
            Write-Host "✓ Calendar expression is valid" -ForegroundColor Green
            
            if (-not $ValidateOnly)
            {
                Write-Host "`nNext $Iterations execution times:" -ForegroundColor Yellow
                $output | ForEach-Object { Write-Host "  $_" }
                
                # Parse and analyze the schedule
                $times = $output | Where-Object { $_ -match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}" }
                if ($times.Count -gt 1)
                {
                    $intervals = @()
                    for ($i = 1; $i -lt $times.Count; $i++)
                    {
                        $prev = [DateTime]::Parse(($times[$i-1] -split " ")[0..1] -join " ")
                        $curr = [DateTime]::Parse(($times[$i] -split " ")[0..1] -join " ")
                        $interval = $curr - $prev
                        $intervals += $interval.TotalMinutes
                    }
                    
                    $avgInterval = ($intervals | Measure-Object -Average).Average
                    Write-Host "`nSchedule Analysis:" -ForegroundColor Cyan
                    Write-Host "  Average interval: $([math]::Round($avgInterval, 2)) minutes" -ForegroundColor White
                    Write-Host "  Shortest interval: $($intervals | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) minutes" -ForegroundColor White
                    Write-Host "  Longest interval: $($intervals | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) minutes" -ForegroundColor White
                }
            }
            
            return $true
        }
        else
        {
            Write-Host "✗ Calendar expression is invalid" -ForegroundColor Red
            Write-Host "Error: $output" -ForegroundColor Red
            return $false
        }
    }
    catch
    {
        Write-Error "Failed to test calendar expression: $($_.Exception.Message)"
        return $false
    }
}
```

---

## Logging and Monitoring

SystemD's journal system (journald) provides centralized, structured logging that integrates seamlessly with the init system, offering powerful querying capabilities and efficient log management.

### Journal Architecture and Configuration

#### Journal Storage Configuration

```bash
# Main journal configuration file
sudo nano /etc/systemd/journald.conf
```

```ini
# /etc/systemd/journald.conf
[Journal]
# Storage location
Storage=persistent          # auto, volatile, persistent, none
Compress=yes               # Compress log entries
Seal=yes                  # Add authentication data to log entries

# Size management
SystemMaxUse=4G           # Maximum disk space for journal
SystemKeepFree=1G         # Keep this much disk space free
SystemMaxFileSize=128M    # Maximum size of individual journal files
SystemMaxFiles=100        # Maximum number of journal files

# Time-based retention
MaxRetentionSec=1month    # Keep logs for 1 month
MaxFileSec=1week         # Rotate files weekly

# Rate limiting
RateLimitIntervalSec=30s  # Time window for rate limiting
RateLimitBurst=10000     # Max messages per time window

# Forward to syslog (optional)
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=yes
```

### Advanced journalctl Usage

#### Time-based Queries

```bash
# View logs from specific time ranges
journalctl --since "2025-01-01 00:00:00"
journalctl --since yesterday
journalctl --since "2 hours ago"
journalctl --until "1 hour ago"
journalctl --since "2025-01-01" --until "2025-01-31"

# Relative time queries
journalctl --since "-1d"          # Last 24 hours
journalctl --since "-2h"          # Last 2 hours
journalctl --since "-30m"         # Last 30 minutes
```

#### Service-specific Logging

```bash
# Service logs with context
journalctl -u nginx.service
journalctl -u nginx.service --follow
journalctl -u nginx.service --since today
journalctl -u nginx.service -n 100      # Last 100 lines

# Multiple services
journalctl -u nginx.service -u postgresql.service

# Service logs with process info
journalctl -u nginx.service _PID=1234
journalctl _COMM=nginx                   # All processes named nginx
```

#### Priority and Filtering

```bash
# Filter by priority levels
journalctl -p emerg     # Emergency messages only
journalctl -p alert     # Alert and above
journalctl -p crit      # Critical and above
journalctl -p err       # Error and above
journalctl -p warning   # Warning and above
journalctl -p notice    # Notice and above
journalctl -p info      # Info and above
journalctl -p debug     # All messages

# Priority ranges
journalctl -p warning..emerg    # Warning to emergency
journalctl -p 4..0              # Numeric priority range
```

#### Field-based Filtering

```bash
# Filter by specific fields
journalctl _UID=1000                    # Messages from specific user
journalctl _GID=1000                    # Messages from specific group
journalctl _HOSTNAME=server01           # Messages from specific host
journalctl _TRANSPORT=kernel            # Kernel messages
journalctl _TRANSPORT=syslog            # Syslog messages
journalctl _TRANSPORT=stdout            # Service stdout

# Process information
journalctl _PID=1234                    # Specific process ID
journalctl _COMM=sshd                   # Specific command
journalctl _EXE=/usr/sbin/sshd         # Specific executable

# System information
journalctl _KERNEL_DEVICE=sda1          # Disk-related messages
journalctl _UDEV_DEVNODE=/dev/sda1      # Device node messages
```

#### Advanced Output Formatting

```bash
# JSON output for parsing
journalctl -u nginx.service -o json
journalctl -u nginx.service -o json-pretty

# Export formats
journalctl -u nginx.service -o export      # Binary export format
journalctl -u nginx.service -o cat         # Just the message text
journalctl -u nginx.service -o short       # Traditional syslog format
journalctl -u nginx.service -o verbose     # All available fields

# Custom field output
journalctl -u nginx.service -o short-monotonic    # With monotonic timestamps
journalctl -u nginx.service -o short-iso          # ISO timestamp format
```

### Log Analysis and Monitoring Scripts

#### Comprehensive Log Analyzer

```powershell
function Analyze-SystemdLogs
{
    param(
        [string]$ServiceName,
        [string]$Since = "1 hour ago",
        [string]$Until = "now",
        [ValidateSet("emerg", "alert", "crit", "err", "warning", "notice", "info", "debug")]
        [string]$Priority = "info",
        [int]$MaxLines = 1000,
        [switch]$IncludeStatistics,
        [switch]$ExportToFile,
        [string]$OutputPath = "./log_analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )
    
    Write-Host "Analyzing systemd logs..." -ForegroundColor Cyan
    
    # Build journalctl command
    $journalctlCmd = "journalctl --no-pager -o json"
    if ($ServiceName) { $journalctlCmd += " -u $ServiceName" }
    $journalctlCmd += " --since '$Since' --until '$Until' -p $Priority -n $MaxLines"
    
    Write-Host "Executing: $journalctlCmd" -ForegroundColor Yellow
    
    try
    {
        # Get raw log data
        $rawLogs = Invoke-Expression $journalctlCmd | ConvertFrom-Json
        
        if (-not $rawLogs)
        {
            Write-Warning "No logs found matching the criteria"
            return $null
        }
        
        # Process logs
        $processedLogs = @()
        $errorCount = 0
        $warningCount = 0
        $priorityStats = @{}
        $unitStats = @{}
        
        foreach ($entry in $rawLogs)
        {
            $logEntry = [PSCustomObject]@{
                Timestamp = [DateTime]::FromBinary([Convert]::ToInt64($entry.__REALTIME_TIMESTAMP) * 10 + 621355968000000000)
                Message = $entry.MESSAGE
                Priority = $entry.PRIORITY
                PriorityText = switch ($entry.PRIORITY) {
                    "0" { "Emergency" }
                    "1" { "Alert" }
                    "2" { "Critical" }
                    "3" { "Error" }
                    "4" { "Warning" }
                    "5" { "Notice" }
                    "6" { "Info" }
                    "7" { "Debug" }
                    default { "Unknown" }
                }
                Unit = $entry._SYSTEMD_UNIT
                PID = $entry._PID
                UID = $entry._UID
                GID = $entry._GID
                Hostname = $entry._HOSTNAME
                Transport = $entry._TRANSPORT
            }
            
            $processedLogs += $logEntry
            
            # Statistics
            if ($IncludeStatistics)
            {
                if ($entry.PRIORITY -le 3) { $errorCount++ }
                if ($entry.PRIORITY -eq 4) { $warningCount++ }
                
                if ($priorityStats.ContainsKey($logEntry.PriorityText))
                {
                    $priorityStats[$logEntry.PriorityText]++
                }
                else
                {
                    $priorityStats[$logEntry.PriorityText] = 1
                }
                
                if ($entry._SYSTEMD_UNIT)
                {
                    if ($unitStats.ContainsKey($entry._SYSTEMD_UNIT))
                    {
                        $unitStats[$entry._SYSTEMD_UNIT]++
                    }
                    else
                    {
                        $unitStats[$entry._SYSTEMD_UNIT] = 1
                    }
                }
            }
        }
        
        # Create analysis result
        $analysis = [PSCustomObject]@{
            Query = @{
                ServiceName = $ServiceName
                TimeRange = "$Since to $Until"
                Priority = $Priority
                MaxLines = $MaxLines
                ExecutedAt = Get-Date
            }
            Summary = @{
                TotalEntries = $processedLogs.Count
                ErrorCount = $errorCount
                WarningCount = $warningCount
                TimeSpan = if ($processedLogs.Count -gt 0) {
                    ($processedLogs[-1].Timestamp - $processedLogs[0].Timestamp).ToString()
                } else { "N/A" }
            }
            Logs = $processedLogs
        }
        
        if ($IncludeStatistics)
        {
            $analysis | Add-Member -NotePropertyName "Statistics" -NotePropertyValue @{
                PriorityDistribution = $priorityStats
                TopUnits = $unitStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
            }
        }
        
        # Display summary
        Write-Host "`nLog Analysis Summary:" -ForegroundColor Green
        Write-Host "  Total entries: $($analysis.Summary.TotalEntries)" -ForegroundColor White
        Write-Host "  Errors: $($analysis.Summary.ErrorCount)" -ForegroundColor Red
        Write-Host "  Warnings: $($analysis.Summary.WarningCount)" -ForegroundColor Yellow
        Write-Host "  Time span: $($analysis.Summary.TimeSpan)" -ForegroundColor White
        
        # Export if requested
        if ($ExportToFile)
        {
            $analysis | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "  Analysis exported to: $OutputPath" -ForegroundColor Cyan
        }
        
        return $analysis
    }
    catch
    {
        Write-Error "Failed to analyze logs: $($_.Exception.Message)"
        return $null
    }
}
```

#### Real-time Log Monitor

```powershell
function Start-SystemdLogMonitor
{
    param(
        [string[]]$ServiceNames = @(),
        [ValidateSet("emerg", "alert", "crit", "err", "warning", "notice", "info", "debug")]
        [string]$MinPriority = "warning",
        [string[]]$AlertKeywords = @("error", "fail", "critical", "emergency"),
        [string]$AlertEmail,
        [int]$BufferSize = 100,
        [switch]$ShowTimestamp
    )
    
    Write-Host "Starting real-time systemd log monitor..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    
    # Build journalctl command
    $journalctlCmd = "journalctl -f -o json --no-pager -p $MinPriority"
    if ($ServiceNames.Count -gt 0)
    {
        $serviceArgs = $ServiceNames | ForEach-Object { "-u $_" }
        $journalctlCmd += " " + ($serviceArgs -join " ")
    }
    
    Write-Host "Monitor command: $journalctlCmd" -ForegroundColor Gray
    Write-Host "Monitoring for priority: $MinPriority and above" -ForegroundColor Gray
    Write-Host "Alert keywords: $($AlertKeywords -join ', ')" -ForegroundColor Gray
    Write-Host "---" -ForegroundColor Gray
    
    $alertBuffer = @()
    
    try
    {
        # Start the journalctl process
        $process = Start-Process -FilePath "bash" -ArgumentList "-c", $journalctlCmd -NoNewWindow -PassThru -RedirectStandardOutput
        
        # Read output line by line
        while (-not $process.HasExited)
        {
            $line = $process.StandardOutput.ReadLine()
            if ($line)
            {
                try
                {
                    $logEntry = $line | ConvertFrom-Json
                    
                    # Format timestamp
                    $timestamp = if ($ShowTimestamp)
                    {
                        $realTime = [DateTime]::FromBinary([Convert]::ToInt64($logEntry.__REALTIME_TIMESTAMP) * 10 + 621355968000000000)
                        "[$($realTime.ToString('yyyy-MM-dd HH:mm:ss'))] "
                    }
                    else { "" }
                    
                    # Determine color based on priority
                    $color = switch ($logEntry.PRIORITY)
                    {
                        { $_ -le 2 } { "Red" }      # Emergency, Alert, Critical
                        "3" { "DarkRed" }           # Error
                        "4" { "Yellow" }            # Warning
                        "5" { "DarkYellow" }        # Notice
                        default { "White" }         # Info, Debug
                    }
                    
                    # Format output
                    $output = "$timestamp$($logEntry._SYSTEMD_UNIT): $($logEntry.MESSAGE)"
                    Write-Host $output -ForegroundColor $color
                    
                    # Check for alert keywords
                    $messageText = $logEntry.MESSAGE.ToLower()
                    $foundAlert = $AlertKeywords | Where-Object { $messageText -contains $_.ToLower() }
                    
                    if ($foundAlert -and $logEntry.PRIORITY -le 4)
                    {
                        $alert = [PSCustomObject]@{
                            Timestamp = Get-Date
                            Service = $logEntry._SYSTEMD_UNIT
                            Priority = $logEntry.PRIORITY
                            Message = $logEntry.MESSAGE
                            Keyword = $foundAlert[0]
                        }
                        
                        $alertBuffer += $alert
                        Write-Host "🚨 ALERT: $($foundAlert[0]) detected in $($logEntry._SYSTEMD_UNIT)" -ForegroundColor Red -BackgroundColor Yellow
                        
                        # Send email alert if configured
                        if ($AlertEmail)
                        {
                            Send-LogAlert -Alert $alert -EmailAddress $AlertEmail
                        }
                        
                        # Trim buffer
                        if ($alertBuffer.Count -gt $BufferSize)
                        {
                            $alertBuffer = $alertBuffer[-$BufferSize..-1]
                        }
                    }
                }
                catch
                {
                    Write-Warning "Failed to parse log entry: $line"
                }
            }
            
            Start-Sleep -Milliseconds 100
        }
    }
    catch
    {
        Write-Error "Log monitoring failed: $($_.Exception.Message)"
    }
    finally
    {
        if ($process -and -not $process.HasExited)
        {
            $process.Kill()
        }
        
        Write-Host "`nLog monitoring stopped." -ForegroundColor Cyan
        Write-Host "Captured $($alertBuffer.Count) alerts during session." -ForegroundColor Yellow
    }
}

function Send-LogAlert
{
    param(
        [PSCustomObject]$Alert,
        [string]$EmailAddress
    )
    
    $subject = "SystemD Alert: $($Alert.Keyword) in $($Alert.Service)"
    $body = @"
SystemD Alert Detected

Service: $($Alert.Service)
Priority: $($Alert.Priority)
Keyword: $($Alert.Keyword)
Time: $($Alert.Timestamp)
Message: $($Alert.Message)

Please investigate immediately.
"@
    
    try
    {
        # Send email using system mail command or implement SMTP
        $body | mail -s $subject $EmailAddress
        Write-Host "Alert email sent to $EmailAddress" -ForegroundColor Green
    }
    catch
    {
        Write-Warning "Failed to send alert email: $($_.Exception.Message)"
    }
}
```

### Log Management and Maintenance

#### Journal Maintenance Commands

```bash
# Check journal disk usage
journalctl --disk-usage

# Verify journal files integrity
sudo journalctl --verify

# Show journal file information
journalctl --header

# Vacuum logs by time
sudo journalctl --vacuum-time=2weeks
sudo journalctl --vacuum-time=30d

# Vacuum logs by size
sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-size=1G

# Vacuum logs by number of files
sudo journalctl --vacuum-files=10

# Rotate journal files manually
sudo systemctl kill --kill-who=main --signal=SIGUSR2 systemd-journald
```

#### Journal Performance Tuning

```bash
# Monitor journal performance
systemd-analyze --user verify
systemd-analyze critical-chain
systemd-analyze plot > boot_analysis.svg

# Journal sync modes
# /etc/systemd/journald.conf
[Journal]
# Sync modes: none, sync, immediate
SyncIntervalSec=5m        # Sync every 5 minutes
Storage=persistent        # Store on disk
Compress=yes             # Enable compression
MaxLevelStore=info       # Store info and above
MaxLevelSyslog=debug     # Forward debug and above to syslog
```

### Advanced Monitoring Integration

#### Prometheus Integration

```bash
# Install systemd exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service for node_exporter
sudo tee /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.systemd.unit-whitelist="(sshd|nginx|postgresql|redis)\.service"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

---

## Security and Hardening

SystemD provides extensive security features that can significantly improve service isolation and system security through sandboxing, capability controls, and resource restrictions.

### Security Directives Overview

#### Process Isolation

| Directive | Effect | Security Benefit | Example |
|-----------|--------|------------------|---------|
| `User=` | Run as specific user | Privilege separation | `User=nginx` |
| `Group=` | Run as specific group | Group-based access control | `Group=www-data` |
| `NoNewPrivileges=true` | Disable privilege escalation | Prevents setuid/setgid | Security baseline |
| `PrivateTmp=true` | Private /tmp directory | Isolate temporary files | File system isolation |
| `ProtectSystem=strict` | Read-only system directories | Prevent system modification | System integrity |
| `ProtectHome=true` | Hide home directories | Protect user data | Data privacy |

#### Capability Management

```ini
# Capability control examples
[Service]
# Drop all capabilities except network binding
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Drop all capabilities
CapabilityBoundingSet=
NoNewPrivileges=true

# Specific capability sets
CapabilityBoundingSet=CAP_DAC_OVERRIDE CAP_SETUID CAP_SETGID
```

### Comprehensive Security Configuration Examples

#### Web Server Security (Nginx-style)

```ini
# /etc/systemd/system/secure-webserver.service
[Unit]
Description=Secure Web Server
Documentation=https://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
User=nginx
Group=nginx
PIDFile=/var/run/nginx.pid

# Basic execution
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true

# File system protection
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/nginx /var/cache/nginx /var/run

# Network and system calls
PrivateNetwork=false
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Capabilities
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETGID CAP_SETUID
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

#### Database Service Security (PostgreSQL-style)

```ini
# /etc/systemd/system/secure-database.service
[Unit]
Description=Secure Database Service
Documentation=https://www.postgresql.org/docs/
After=network.target

[Service]
Type=notify
User=postgres
Group=postgres

# Environment
Environment=PGDATA=/var/lib/postgresql/data
Environment=POSTGRES_USER=postgres
EnvironmentFile=/etc/postgresql/environment

# Execution
ExecStartPre=/usr/local/bin/postgres-pre-start.sh
ExecStart=/usr/local/bin/postgres -D $PGDATA
ExecReload=/bin/kill -HUP $MAINPID

# Advanced security
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
ProtectKernelLogs=true
ProtectClock=true

# File system isolation
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/postgresql /var/log/postgresql /var/run/postgresql
ReadOnlyPaths=/etc/postgresql

# Memory and process protection
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true

# Network restrictions
PrivateNetwork=false
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
IPAddressDeny=any
IPAddressAllow=127.0.0.0/8 10.0.0.0/8 192.168.0.0/16

# System call filtering
SystemCallFilter=@system-service @signal @ipc @network-io
SystemCallFilter=~@privileged @resources @obsolete
SystemCallErrorNumber=EPERM

# Capabilities (none needed for database)
CapabilityBoundingSet=
AmbientCapabilities=

# Resource limits
MemoryLimit=8G
CPUQuota=400%
TasksMax=4096
LimitNOFILE=65536
LimitLOCKS=4096

[Install]
WantedBy=multi-user.target
```

#### Application Service with Maximum Security

```ini
# /etc/systemd/system/ultra-secure-app.service
[Unit]
Description=Ultra-Secure Application Service
After=network.target

[Service]
Type=simple
User=secureapp
Group=secureapp
WorkingDirectory=/opt/secureapp

# Execution
ExecStart=/opt/secureapp/bin/app
Restart=on-failure
RestartSec=5

# Maximum security hardening
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
PrivateNetwork=true
PrivateUsers=true
PrivateMounts=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectClock=true
ProtectControlGroups=true
ProtectHome=true
ProtectHostname=true
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
PrivateIPC=true

# File system restrictions
ProtectSystem=strict
ReadOnlyPaths=/
ReadWritePaths=/opt/secureapp/data /var/log/secureapp
InaccessiblePaths=/proc /sys /dev

# System call restrictions
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources @obsolete @debug @mount @swap @reboot @module @raw-io
SystemCallErrorNumber=EPERM
SystemCallArchitectures=native

# No capabilities
CapabilityBoundingSet=
AmbientCapabilities=

# Resource limits
MemoryLimit=512M
CPUQuota=50%
TasksMax=100
LimitNOFILE=1024
LimitNPROC=10

# Additional restrictions
UMask=0077
KeyringMode=private

[Install]
WantedBy=multi-user.target
```

### Security Analysis and Validation

#### Security Audit Script

```powershell
function Test-SystemdServiceSecurity
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,
        [switch]$DetailedReport,
        [switch]$ExportResults,
        [string]$OutputPath = "./security_audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )
    
    $securityChecks = @{
        "User" = @{ Required = $true; Description = "Service runs as non-root user" }
        "Group" = @{ Required = $true; Description = "Service runs as specific group" }
        "NoNewPrivileges" = @{ Required = $true; Description = "Prevents privilege escalation" }
        "PrivateTmp" = @{ Required = $true; Description = "Isolates temporary directories" }
        "ProtectSystem" = @{ Required = $true; Description = "Protects system directories" }
        "ProtectHome" = @{ Required = $false; Description = "Protects user home directories" }
        "CapabilityBoundingSet" = @{ Required = $false; Description = "Limits process capabilities" }
        "RestrictNamespaces" = @{ Required = $false; Description = "Restricts namespace usage" }
        "SystemCallFilter" = @{ Required = $false; Description = "Filters allowed system calls" }
        "MemoryDenyWriteExecute" = @{ Required = $false; Description = "Prevents code injection" }
    }
    
    $auditResults = @()
    
    foreach ($serviceName in $ServiceNames)
    {
        Write-Host "Auditing security for service: $serviceName" -ForegroundColor Cyan
        
        try
        {
            # Get service properties
            $properties = @{}
            $showOutput = & systemctl show $serviceName
            foreach ($line in $showOutput)
            {
                if ($line -match "^([^=]+)=(.*)$")
                {
                    $properties[$matches[1]] = $matches[2]
                }
            }
            
            $securityScore = 0
            $maxScore = 0
            $findings = @()
            
            foreach ($check in $securityChecks.Keys)
            {
                $checkInfo = $securityChecks[$check]
                $maxScore += if ($checkInfo.Required) { 2 } else { 1 }
                
                $value = $properties[$check]
                $configured = -not [string]::IsNullOrEmpty($value) -and $value -ne "(unset)"
                
                $finding = [PSCustomObject]@{
                    Check = $check
                    Description = $checkInfo.Description
                    Required = $checkInfo.Required
                    Configured = $configured
                    Value = $value
                    Score = 0
                }
                
                if ($configured)
                {
                    if ($checkInfo.Required)
                    {
                        $finding.Score = 2
                        $securityScore += 2
                    }
                    else
                    {
                        $finding.Score = 1
                        $securityScore += 1
                    }
                }
                elseif ($checkInfo.Required)
                {
                    $finding.Score = 0
                }
                else
                {
                    $finding.Score = 0
                }
                
                $findings += $finding
            }
            
            $securityPercentage = [math]::Round(($securityScore / $maxScore) * 100, 2)
            
            $serviceAudit = [PSCustomObject]@{
                ServiceName = $serviceName
                SecurityScore = $securityScore
                MaxScore = $maxScore
                SecurityPercentage = $securityPercentage
                LoadState = $properties.LoadState
                ActiveState = $properties.ActiveState
                User = $properties.User
                Group = $properties.Group
                AuditTimestamp = Get-Date
                Findings = $findings
            }
            
            if ($DetailedReport)
            {
                $serviceAudit | Add-Member -NotePropertyName "AllProperties" -NotePropertyValue $properties
            }
            
            $auditResults += $serviceAudit
            
            # Display summary
            $color = switch ($securityPercentage)
            {
                { $_ -ge 80 } { "Green" }
                { $_ -ge 60 } { "Yellow" }
                default { "Red" }
            }
            
            Write-Host "  Security Score: $securityScore/$maxScore ($securityPercentage%)" -ForegroundColor $color
            
            # Show critical missing configurations
            $missingRequired = $findings | Where-Object { $_.Required -and -not $_.Configured }
            if ($missingRequired)
            {
                Write-Host "  Missing required configurations:" -ForegroundColor Red
                $missingRequired | ForEach-Object { Write-Host "    - $($_.Check): $($_.Description)" -ForegroundColor Red }
            }
        }
        catch
        {
            Write-Error "Failed to audit service $serviceName : $($_.Exception.Message)"
        }
    }
    
    # Overall summary
    if ($auditResults.Count -gt 0)
    {
        $avgScore = ($auditResults | Measure-Object SecurityPercentage -Average).Average
        $highSecurity = ($auditResults | Where-Object { $_.SecurityPercentage -ge 80 }).Count
        $mediumSecurity = ($auditResults | Where-Object { $_.SecurityPercentage -ge 60 -and $_.SecurityPercentage -lt 80 }).Count
        $lowSecurity = ($auditResults | Where-Object { $_.SecurityPercentage -lt 60 }).Count
        
        Write-Host "`nSecurity Audit Summary:" -ForegroundColor Cyan
        Write-Host "  Services audited: $($auditResults.Count)" -ForegroundColor White
        Write-Host "  Average security score: $([math]::Round($avgScore, 2))%" -ForegroundColor White
        Write-Host "  High security (80%+): $highSecurity" -ForegroundColor Green
        Write-Host "  Medium security (60-79%): $mediumSecurity" -ForegroundColor Yellow
        Write-Host "  Low security (<60%): $lowSecurity" -ForegroundColor Red
        
        if ($ExportResults)
        {
            $auditResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "  Audit results exported to: $OutputPath" -ForegroundColor Cyan
        }
    }
    
    return $auditResults
}
```

### Security Best Practices Implementation

#### Automated Security Hardening

```powershell
function Set-SystemdServiceSecurity
{
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        [ValidateSet("Basic", "Standard", "Strict", "Maximum")]
        [string]$SecurityLevel = "Standard",
        [string]$ServiceUser,
        [string]$ServiceGroup,
        [string[]]$ReadWritePaths = @(),
        [string[]]$ReadOnlyPaths = @(),
        [switch]$ApplyImmediately
    )
    
    $securityConfigs = @{
        "Basic" = @{
            "User" = $ServiceUser
            "Group" = $ServiceGroup
            "NoNewPrivileges" = "true"
            "PrivateTmp" = "true"
        }
        "Standard" = @{
            "User" = $ServiceUser
            "Group" = $ServiceGroup
            "NoNewPrivileges" = "true"
            "PrivateTmp" = "true"
            "ProtectSystem" = "true"
            "ProtectHome" = "true"
            "RestrictNamespaces" = "true"
        }
        "Strict" = @{
            "User" = $ServiceUser
            "Group" = $ServiceGroup
            "NoNewPrivileges" = "true"
            "PrivateTmp" = "true"
            "PrivateDevices" = "true"
            "ProtectSystem" = "strict"
            "ProtectHome" = "true"
            "ProtectKernelTunables" = "true"
            "ProtectControlGroups" = "true"
            "RestrictNamespaces" = "true"
            "RestrictRealtime" = "true"
            "SystemCallFilter" = "@system-service"
            "CapabilityBoundingSet" = ""
        }
        "Maximum" = @{
            "User" = $ServiceUser
            "Group" = $ServiceGroup
            "NoNewPrivileges" = "true"
            "PrivateTmp" = "true"
            "PrivateDevices" = "true"
            "PrivateNetwork" = "false"
            "ProtectSystem" = "strict"
            "ProtectHome" = "true"
            "ProtectKernelTunables" = "true"
            "ProtectKernelModules" = "true"
            "ProtectKernelLogs" = "true"
            "ProtectClock" = "true"
            "ProtectControlGroups" = "true"
            "ProtectHostname" = "true"
            "RestrictNamespaces" = "true"
            "RestrictRealtime" = "true"
            "RestrictSUIDSGID" = "true"
            "LockPersonality" = "true"
            "MemoryDenyWriteExecute" = "true"
            "RemoveIPC" = "true"
            "SystemCallFilter" = "@system-service"
            "SystemCallFilter" = "~@privileged @resources @obsolete"
            "SystemCallErrorNumber" = "EPERM"
            "CapabilityBoundingSet" = ""
            "UMask" = "0077"
        }
    }
    
    Write-Host "Applying $SecurityLevel security configuration to $ServiceName" -ForegroundColor Cyan
    
    try
    {
        # Create override directory
        $overrideDir = "/etc/systemd/system/$ServiceName.d"
        $overrideFile = "$overrideDir/security-hardening.conf"
        
        Invoke-Expression "sudo mkdir -p $overrideDir"
        
        # Generate security configuration
        $config = $securityConfigs[$SecurityLevel]
        $configContent = "[Service]`n"
        
        foreach ($key in $config.Keys)
        {
            $configContent += "$key=$($config[$key])`n"
        }
        
        # Add path configurations
        if ($ReadWritePaths.Count -gt 0)
        {
            $configContent += "ReadWritePaths=$($ReadWritePaths -join ' ')`n"
        }
        
        if ($ReadOnlyPaths.Count -gt 0)
        {
            $configContent += "ReadOnlyPaths=$($ReadOnlyPaths -join ' ')`n"
        }
        
        # Write configuration
        $configContent | sudo tee $overrideFile > /dev/null
        
        Write-Host "Security configuration written to: $overrideFile" -ForegroundColor Green
        
        # Reload systemd
        Invoke-Expression "sudo systemctl daemon-reload"
        
        if ($ApplyImmediately)
        {
            Write-Host "Restarting service to apply security settings..." -ForegroundColor Yellow
            Invoke-Expression "sudo systemctl restart $ServiceName"
            
            # Verify service started successfully
            Start-Sleep -Seconds 2
            $status = Invoke-Expression "systemctl is-active $ServiceName"
            if ($status -eq "active")
            {
                Write-Host "Service restarted successfully with new security settings" -ForegroundColor Green
            }
            else
            {
                Write-Warning "Service failed to start with new security settings. Check logs: journalctl -u $ServiceName"
            }
        }
        else
        {
            Write-Host "Security configuration applied. Restart service to activate: sudo systemctl restart $ServiceName" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch
    {
        Write-Error "Failed to apply security configuration: $($_.Exception.Message)"
        return $false
    }
}
```

---

## Performance Optimization

SystemD provides numerous features for optimizing service performance, resource management, and system efficiency.

### Resource Management and Limits

#### CPU Control

```ini
[Service]
# CPU scheduling
CPUWeight=100              # Default: 100, Range: 1-10000
CPUQuota=50%              # Limit to 50% of one CPU core
CPUAffinity=0 1 2         # Bind to specific CPU cores

# Nice and priority
Nice=10                   # Process priority (-20 to 19)
IOSchedulingClass=2       # I/O scheduling class (0-3)
IOSchedulingPriority=4    # I/O priority (0-7)
```

#### Memory Management

```ini
[Service]
# Memory limits
MemoryLimit=2G            # Hard memory limit
MemoryMax=2G             # Maximum memory (cgroups v2)
MemoryHigh=1.5G          # Soft memory limit
MemorySwapMax=1G         # Maximum swap usage

# Memory accounting
MemoryAccounting=true     # Enable memory accounting
```

#### I/O Control

```ini
[Service]
# I/O bandwidth limits
IOReadBandwidthMax=/dev/sda 50M    # Read bandwidth limit
IOWriteBandwidthMax=/dev/sda 20M   # Write bandwidth limit

# I/O operations limits
IOReadIOPSMax=/dev/sda 1000        # Read IOPS limit
IOWriteIOPSMax=/dev/sda 500        # Write IOPS limit

# I/O weight
IOWeight=100              # I/O scheduling weight (1-10000)
```

### Advanced Performance Configuration

#### High-Performance Web Server

```ini
# /etc/systemd/system/high-perf-web.service
[Unit]
Description=High-Performance Web Server
After=network.target

[Service]
Type=forking
User=nginx
Group=nginx
PIDFile=/var/run/nginx.pid
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID

# Performance optimization
Nice=-5                   # Higher priority
IOSchedulingClass=1       # Real-time I/O scheduling
IOSchedulingPriority=2    # High I/O priority

# CPU optimization
CPUWeight=500            # Higher CPU weight
CPUAffinity=0-3         # Use first 4 CPU cores

# Memory optimization
MemoryMax=4G            # Maximum memory
MemoryHigh=3G           # Soft limit
MemoryAccounting=true

# I/O optimization
IOWeight=500            # Higher I/O weight
IOReadBandwidthMax=/dev/sda 200M
IOWriteBandwidthMax=/dev/sda 100M

# File descriptor limits
LimitNOFILE=65536       # Increase file descriptor limit
LimitNPROC=8192         # Process limit

# Security (basic)
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

#### Database Performance Tuning

```ini
# /etc/systemd/system/high-perf-db.service
[Unit]
Description=High-Performance Database
After=network.target

[Service]
Type=notify
User=postgres
Group=postgres
Environment=PGDATA=/var/lib/postgresql/data

# Execution
ExecStart=/usr/local/bin/postgres -D $PGDATA
ExecReload=/bin/kill -HUP $MAINPID

# Performance tuning
Nice=-10                # Highest priority for database
IOSchedulingClass=1     # Real-time I/O
IOSchedulingPriority=1  # Highest I/O priority
OOMScoreAdjust=-800     # Protect from OOM killer

# CPU allocation
CPUWeight=1000          # Maximum CPU weight
CPUAffinity=4-7         # Dedicated CPU cores

# Memory configuration
MemoryMax=16G           # Large memory allocation
MemoryHigh=14G          # Soft limit
MemoryAccounting=true
MemorySwapMax=0         # Disable swap for database

# I/O optimization
IOWeight=1000           # Maximum I/O weight
IOReadBandwidthMax=/dev/nvme0n1 1G    # High-speed NVMe
IOWriteBandwidthMax=/dev/nvme0n1 500M
IOReadIOPSMax=/dev/nvme0n1 10000
IOWriteIOPSMax=/dev/nvme0n1 5000

# File system limits
LimitNOFILE=131072      # Large file descriptor limit
LimitLOCKS=65536        # File locking limit
LimitMEMLOCK=infinity   # Memory locking

# Process limits
LimitNPROC=16384        # Process limit
TasksMax=32768          # Task limit

[Install]
WantedBy=multi-user.target
```

### Performance Monitoring Scripts

#### Resource Usage Monitor

```powershell
function Monitor-SystemdServicePerformance
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,
        [int]$IntervalSeconds = 5,
        [int]$DurationMinutes = 10,
        [switch]$ExportData,
        [string]$OutputPath = "./performance_data_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    )
    
    Write-Host "Starting performance monitoring for $($ServiceNames.Count) services" -ForegroundColor Cyan
    Write-Host "Monitoring interval: $IntervalSeconds seconds" -ForegroundColor Yellow
    Write-Host "Total duration: $DurationMinutes minutes" -ForegroundColor Yellow
    Write-Host "Services: $($ServiceNames -join ', ')" -ForegroundColor White
    
    $performanceData = @()
    $totalIterations = ($DurationMinutes * 60) / $IntervalSeconds
    $iteration = 0
    
    try
    {
        while ($iteration -lt $totalIterations)
        {
            $timestamp = Get-Date
            Write-Host "[$($timestamp.ToString('HH:mm:ss'))] Collecting performance data..." -ForegroundColor Gray
            
            foreach ($serviceName in $ServiceNames)
            {
                try
                {
                    # Get service properties
                    $properties = @{}
                    $showOutput = & systemctl show $serviceName --property=MainPID,ActiveState,CPUUsageNSec,MemoryCurrent,TasksCurrent,IPIngressBytes,IPEgressBytes
                    
                    foreach ($line in $showOutput)
                    {
                        if ($line -match "^([^=]+)=(.*)$")
                        {
                            $properties[$matches[1]] = $matches[2]
                        }
                    }
                    
                    # Get process-level metrics if service is running
                    $processMetrics = $null
                    if ($properties.MainPID -and $properties.MainPID -ne "0")
                    {
                        try
                        {
                            $processInfo = Get-Process -Id $properties.MainPID -ErrorAction Stop
                            $processMetrics = @{
                                CPU = $processInfo.CPU
                                WorkingSet = $processInfo.WorkingSet64
                                VirtualMemory = $processInfo.VirtualMemorySize64
                                Threads = $processInfo.Threads.Count
                                HandleCount = $processInfo.HandleCount
                            }
                        }
                        catch
                        {
                            # Process might have exited
                        }
                    }
                    
                    $performanceEntry = [PSCustomObject]@{
                        Timestamp = $timestamp
                        ServiceName = $serviceName
                        ActiveState = $properties.ActiveState
                        MainPID = $properties.MainPID
                        CPUUsageNSec = $properties.CPUUsageNSec
                        MemoryCurrent = $properties.MemoryCurrent
                        TasksCurrent = $properties.TasksCurrent
                        IPIngressBytes = $properties.IPIngressBytes
                        IPEgressBytes = $properties.IPEgressBytes
                        ProcessCPU = if ($processMetrics) { $processMetrics.CPU } else { $null }
                        ProcessMemory = if ($processMetrics) { $processMetrics.WorkingSet } else { $null }
                        ProcessThreads = if ($processMetrics) { $processMetrics.Threads } else { $null }
                    }
                    
                    $performanceData += $performanceEntry
                    
                    # Display current metrics
                    $memoryMB = if ($properties.MemoryCurrent -and $properties.MemoryCurrent -ne "[not set]") 
                    { 
                        [math]::Round([int64]$properties.MemoryCurrent / 1MB, 2) 
                    } else { "N/A" }
                    
                    Write-Host "  $serviceName - Memory: ${memoryMB}MB, Tasks: $($properties.TasksCurrent), State: $($properties.ActiveState)" -ForegroundColor White
                }
                catch
                {
                    Write-Warning "Failed to collect metrics for $serviceName : $($_.Exception.Message)"
                }
            }
            
            $iteration++
            $progress = [math]::Round(($iteration / $totalIterations) * 100, 1)
            Write-Host "Progress: $progress% ($iteration/$totalIterations)" -ForegroundColor Cyan
            
            if ($iteration -lt $totalIterations)
            {
                Start-Sleep -Seconds $IntervalSeconds
            }
        }
        
        # Calculate summary statistics
        Write-Host "`nPerformance Monitoring Summary:" -ForegroundColor Green
        
        foreach ($serviceName in $ServiceNames)
        {
            $serviceData = $performanceData | Where-Object { $_.ServiceName -eq $serviceName }
            if ($serviceData)
            {
                $memoryData = $serviceData | Where-Object { $_.MemoryCurrent -and $_.MemoryCurrent -ne "[not set]" } | ForEach-Object { [int64]$_.MemoryCurrent }
                $taskData = $serviceData | Where-Object { $_.TasksCurrent -and $_.TasksCurrent -ne "[not set]" } | ForEach-Object { [int]$_.TasksCurrent }
                
                Write-Host "`n  $serviceName Statistics:" -ForegroundColor Yellow
                
                if ($memoryData)
                {
                    $avgMemory = ($memoryData | Measure-Object -Average).Average / 1MB
                    $maxMemory = ($memoryData | Measure-Object -Maximum).Maximum / 1MB
                    $minMemory = ($memoryData | Measure-Object -Minimum).Minimum / 1MB
                    Write-Host "    Memory - Avg: $([math]::Round($avgMemory, 2))MB, Max: $([math]::Round($maxMemory, 2))MB, Min: $([math]::Round($minMemory, 2))MB" -ForegroundColor White
                }
                
                if ($taskData)
                {
                    $avgTasks = ($taskData | Measure-Object -Average).Average
                    $maxTasks = ($taskData | Measure-Object -Maximum).Maximum
                    Write-Host "    Tasks - Avg: $([math]::Round($avgTasks, 1)), Max: $maxTasks" -ForegroundColor White
                }
            }
        }
        
        if ($ExportData)
        {
            $performanceData | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "`nPerformance data exported to: $OutputPath" -ForegroundColor Cyan
        }
        
        return $performanceData
    }
    catch
    {
        Write-Error "Performance monitoring failed: $($_.Exception.Message)"
        return $performanceData
    }
}
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Service Fails to Start

```bash
# Check service status and logs
systemctl status service-name
journalctl -u service-name --since "10 minutes ago"

# Check service dependencies
systemctl list-dependencies service-name
systemctl list-dependencies service-name --reverse

# Verify unit file syntax
systemd-analyze verify /etc/systemd/system/service-name.service

# Check if service is masked
systemctl is-enabled service-name
systemctl unmask service-name  # If masked
```

#### Performance Issues

```bash
# Analyze boot performance
systemd-analyze time
systemd-analyze blame
systemd-analyze critical-chain

# Check resource usage
systemctl status service-name
systemd-cgtop

# Monitor service resource consumption
systemctl show service-name --property=MemoryCurrent,CPUUsageNSec,TasksCurrent

# Check for resource limits
systemctl show service-name | grep -E "(Memory|CPU|Tasks|Limit)"
```

#### Dependency Problems

```bash
# Check circular dependencies
systemd-analyze verify /etc/systemd/system/*.service

# View dependency tree
systemctl list-dependencies --all
systemctl list-dependencies graphical.target

# Check for failed dependencies
systemctl list-units --failed
systemctl list-dependencies service-name --failed
```

### Diagnostic Scripts

#### Comprehensive System Health Check

```powershell
function Test-SystemdHealth
{
    param(
        [switch]$IncludeUserServices,
        [switch]$CheckSecurity,
        [switch]$ExportReport,
        [string]$OutputPath = "./systemd_health_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    Write-Host "Running comprehensive systemd health check..." -ForegroundColor Cyan
    
    $healthReport = @{
        SystemOverview = @{}
        FailedServices = @()
        SecurityIssues = @()
        PerformanceIssues = @()
        Recommendations = @()
        CheckTimestamp = Get-Date
    }
    
    try
    {
        # System overview
        Write-Host "Checking system overview..." -ForegroundColor Yellow
        
        $bootTime = (& systemd-analyze time 2>/dev/null) -join " "
        $systemState = & systemctl is-system-running
        $failedCount = (& systemctl list-units --state=failed --no-legend | Measure-Object).Count
        
        $healthReport.SystemOverview = @{
            BootTime = $bootTime
            SystemState = $systemState
            FailedServices = $failedCount
            SystemUptime = (Get-Uptime).ToString()
        }
        
        # Check for failed services
        Write-Host "Checking for failed services..." -ForegroundColor Yellow
        
        $failedServices = & systemctl list-units --state=failed --no-legend
        foreach ($line in $failedServices)
        {
            if ($line -match "^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$")
            {
                $serviceName = $matches[1]
                $loadState = $matches[2]
                $activeState = $matches[3]
                $subState = $matches[4]
                $description = $matches[5]
                
                # Get recent logs for the failed service
                $recentLogs = & journalctl -u $serviceName --since "1 hour ago" --no-pager -n 10
                
                $failedService = @{
                    Name = $serviceName
                    LoadState = $loadState
                    ActiveState = $activeState
                    SubState = $subState
                    Description = $description
                    RecentLogs = $recentLogs -join "`n"
                }
                
                $healthReport.FailedServices += $failedService
            }
        }
        
        # Security check
        if ($CheckSecurity)
        {
            Write-Host "Performing security checks..." -ForegroundColor Yellow
            
            # Check for services running as root
            $rootServices = & systemctl list-units --type=service --state=active --no-legend | ForEach-Object {
                if ($_ -match "^\s*(\S+)")
                {
                    $serviceName = $matches[1]
                    $user = (& systemctl show $serviceName --property=User).Split('=')[1]
                    if ([string]::IsNullOrEmpty($user) -or $user -eq "root")
                    {
                        return $serviceName
                    }
                }
            } | Where-Object { $_ }
            
            foreach ($service in $rootServices)
            {
                $healthReport.SecurityIssues += @{
                    Type = "Root Service"
                    Service = $service
                    Description = "Service running as root user"
                    Severity = "Medium"
                }
            }
            
            # Check for services without security hardening
            $unsecuredServices = & systemctl list-units --type=service --state=active --no-legend | ForEach-Object {
                if ($_ -match "^\s*(\S+)")
                {
                    $serviceName = $matches[1]
                    $noNewPrivileges = (& systemctl show $serviceName --property=NoNewPrivileges).Split('=')[1]
                    $privateTmp = (& systemctl show $serviceName --property=PrivateTmp).Split('=')[1]
                    
                    if ($noNewPrivileges -ne "yes" -or $privateTmp -ne "yes")
                    {
                        return @{
                            Service = $serviceName
                            NoNewPrivileges = $noNewPrivileges
                            PrivateTmp = $privateTmp
                        }
                    }
                }
            } | Where-Object { $_ }
            
            foreach ($service in $unsecuredServices)
            {
                $healthReport.SecurityIssues += @{
                    Type = "Insufficient Hardening"
                    Service = $service.Service
                    Description = "Service lacks basic security hardening (NoNewPrivileges: $($service.NoNewPrivileges), PrivateTmp: $($service.PrivateTmp))"
                    Severity = "Low"
                }
            }
        }
        
        # Performance issues
        Write-Host "Checking for performance issues..." -ForegroundColor Yellow
        
        # Check for long boot times
        if ($bootTime -match "(\d+\.?\d*)\s*s")
        {
            $bootTimeSeconds = [double]$matches[1]
            if ($bootTimeSeconds -gt 30)
            {
                $healthReport.PerformanceIssues += @{
                    Type = "Slow Boot"
                    Description = "Boot time is $bootTimeSeconds seconds (>30s)"
                    Severity = "Medium"
                }
            }
        }
        
        # Check for services with high memory usage
        $highMemoryServices = & systemctl list-units --type=service --state=active --no-legend | ForEach-Object {
            if ($_ -match "^\s*(\S+)")
            {
                $serviceName = $matches[1]
                $memoryCurrent = (& systemctl show $serviceName --property=MemoryCurrent).Split('=')[1]
                
                if ($memoryCurrent -and $memoryCurrent -ne "[not set]" -and [int64]$memoryCurrent -gt 1GB)
                {
                    return @{
                        Service = $serviceName
                        Memory = [math]::Round([int64]$memoryCurrent / 1GB, 2)
                    }
                }
            }
        } | Where-Object { $_ } | Sort-Object Memory -Descending
        
        foreach ($service in $highMemoryServices)
        {
            $healthReport.PerformanceIssues += @{
                Type = "High Memory Usage"
                Service = $service.Service
                Description = "Service using $($service.Memory)GB of memory"
                Severity = "Low"
            }
        }
        
        # Generate recommendations
        Write-Host "Generating recommendations..." -ForegroundColor Yellow
        
        if ($healthReport.FailedServices.Count -gt 0)
        {
            $healthReport.Recommendations += "Investigate and fix $($healthReport.FailedServices.Count) failed services"
        }
        
        if ($healthReport.SecurityIssues.Count -gt 0)
        {
            $healthReport.Recommendations += "Address $($healthReport.SecurityIssues.Count) security issues"
        }
        
        if ($healthReport.PerformanceIssues.Count -gt 0)
        {
            $healthReport.Recommendations += "Optimize $($healthReport.PerformanceIssues.Count) performance issues"
        }
        
        if ($healthReport.FailedServices.Count -eq 0 -and $healthReport.SecurityIssues.Count -eq 0)
        {
            $healthReport.Recommendations += "System appears healthy - continue regular monitoring"
        }
        
        # Display summary
        Write-Host "`nSystemd Health Check Summary:" -ForegroundColor Green
        Write-Host "  System State: $($healthReport.SystemOverview.SystemState)" -ForegroundColor White
        Write-Host "  Failed Services: $($healthReport.FailedServices.Count)" -ForegroundColor $(if ($healthReport.FailedServices.Count -eq 0) { "Green" } else { "Red" })
        Write-Host "  Security Issues: $($healthReport.SecurityIssues.Count)" -ForegroundColor $(if ($healthReport.SecurityIssues.Count -eq 0) { "Green" } else { "Yellow" })
        Write-Host "  Performance Issues: $($healthReport.PerformanceIssues.Count)" -ForegroundColor $(if ($healthReport.PerformanceIssues.Count -eq 0) { "Green" } else { "Yellow" })
        
        # Export report
        if ($ExportReport)
        {
            $htmlReport = Generate-SystemdHealthReport -HealthData $healthReport
            $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "  Health report exported to: $OutputPath" -ForegroundColor Cyan
        }
        
        return $healthReport
    }
    catch
    {
        Write-Error "Health check failed: $($_.Exception.Message)"
        return $null
    }
}

function Generate-SystemdHealthReport
{
    param([hashtable]$HealthData)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>SystemD Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .healthy { color: #27ae60; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .error { color: #e74c3c; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f8f9fa; }
        .metric { display: inline-block; margin: 10px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; text-align: center; min-width: 120px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>SystemD Health Report</h1>
        <p>Generated: $($HealthData.CheckTimestamp.ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>
    
    <div class="section">
        <h2>System Overview</h2>
        <div class="metric">
            <h4>System State</h4>
            <div class="$(if ($HealthData.SystemOverview.SystemState -eq 'running') { 'healthy' } else { 'error' })">$($HealthData.SystemOverview.SystemState)</div>
        </div>
        <div class="metric">
            <h4>Boot Time</h4>
            <div>$($HealthData.SystemOverview.BootTime)</div>
        </div>
        <div class="metric">
            <h4>Failed Services</h4>
            <div class="$(if ($HealthData.SystemOverview.FailedServices -eq 0) { 'healthy' } else { 'error' })">$($HealthData.SystemOverview.FailedServices)</div>
        </div>
        <div class="metric">
            <h4>Uptime</h4>
            <div>$($HealthData.SystemOverview.SystemUptime)</div>
        </div>
    </div>
"@
    
    if ($HealthData.FailedServices.Count -gt 0)
    {
        $html += @"
    <div class="section">
        <h2>Failed Services</h2>
        <table>
            <tr><th>Service</th><th>State</th><th>Description</th></tr>
"@
        foreach ($service in $HealthData.FailedServices)
        {
            $html += "<tr><td>$($service.Name)</td><td class='error'>$($service.ActiveState)</td><td>$($service.Description)</td></tr>"
        }
        $html += "</table></div>"
    }
    
    if ($HealthData.SecurityIssues.Count -gt 0)
    {
        $html += @"
    <div class="section">
        <h2>Security Issues</h2>
        <table>
            <tr><th>Type</th><th>Service</th><th>Description</th><th>Severity</th></tr>
"@
        foreach ($issue in $HealthData.SecurityIssues)
        {
            $severityClass = switch ($issue.Severity) { "High" { "error" } "Medium" { "warning" } default { "warning" } }
            $html += "<tr><td>$($issue.Type)</td><td>$($issue.Service)</td><td>$($issue.Description)</td><td class='$severityClass'>$($issue.Severity)</td></tr>"
        }
        $html += "</table></div>"
    }
    
    if ($HealthData.Recommendations.Count -gt 0)
    {
        $html += @"
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
"@
        foreach ($recommendation in $HealthData.Recommendations)
        {
            $html += "<li>$recommendation</li>"
        }
        $html += "</ul></div>"
    }
    
    $html += "</body></html>"
    return $html
}
```

---

## Enterprise Best Practices

### Production Service Standards

#### Service Development Lifecycle

1. **Development Phase**
   - Use template services for consistency
   - Implement comprehensive logging
   - Add health check endpoints
   - Plan resource requirements

2. **Testing Phase**
   - Test service in isolated environment
   - Validate security configuration
   - Performance benchmarking
   - Dependency testing

3. **Deployment Phase**
   - Gradual rollout strategy
   - Monitoring and alerting setup
   - Backup and rollback procedures
   - Documentation updates

4. **Maintenance Phase**
   - Regular security audits
   - Performance monitoring
   - Log rotation and cleanup
   - Dependency updates

### Automation and Scripting

#### Service Deployment Automation

```powershell
function Deploy-SystemdService
{
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        [Parameter(Mandatory)]
        [string]$ServiceTemplate,
        [hashtable]$Variables = @{},
        [string]$Environment = "production",
        [switch]$EnableImmediately,
        [switch]$ValidateOnly
    )
    
    Write-Host "Deploying systemd service: $ServiceName" -ForegroundColor Cyan
    Write-Host "Template: $ServiceTemplate" -ForegroundColor Yellow
    Write-Host "Environment: $Environment" -ForegroundColor Yellow
    
    try
    {
        # Load service template
        if (-not (Test-Path $ServiceTemplate))
        {
            throw "Service template not found: $ServiceTemplate"
        }
        
        $templateContent = Get-Content $ServiceTemplate -Raw
        
        # Replace variables in template
        foreach ($key in $Variables.Keys)
        {
            $templateContent = $templateContent -replace "{{$key}}", $Variables[$key]
        }
        
        # Add environment-specific configurations
        $environmentConfig = Get-EnvironmentConfig -Environment $Environment
        foreach ($key in $environmentConfig.Keys)
        {
            $templateContent = $templateContent -replace "{{$key}}", $environmentConfig[$key]
        }
        
        # Validate template syntax
        $tempFile = "/tmp/$ServiceName.service.tmp"
        $templateContent | Out-File -FilePath $tempFile -Encoding UTF8
        
        $validationResult = & systemd-analyze verify $tempFile 2>&1
        if ($LASTEXITCODE -ne 0)
        {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            throw "Service template validation failed: $validationResult"
        }
        
        if ($ValidateOnly)
        {
            Write-Host "✓ Service template validation passed" -ForegroundColor Green
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            return $true
        }
        
        # Deploy service file
        $serviceFile = "/etc/systemd/system/$ServiceName.service"
        Write-Host "Deploying service file to: $serviceFile" -ForegroundColor Yellow
        
        # Create backup of existing service if it exists
        if (Test-Path $serviceFile)
        {
            $backupFile = "$serviceFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $serviceFile $backupFile
            Write-Host "Existing service backed up to: $backupFile" -ForegroundColor Yellow
        }
        
        # Copy service file
        Copy-Item $tempFile $serviceFile
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        
        # Set proper permissions
        & sudo chmod 644 $serviceFile
        & sudo chown root:root $serviceFile
        
        # Reload systemd
        Write-Host "Reloading systemd daemon..." -ForegroundColor Yellow
        & sudo systemctl daemon-reload
        
        # Validate deployed service
        $postValidation = & systemd-analyze verify $serviceFile 2>&1
        if ($LASTEXITCODE -ne 0)
        {
            Write-Error "Deployed service validation failed: $postValidation"
            return $false
        }
        
        Write-Host "✓ Service deployed successfully" -ForegroundColor Green
        
        # Enable and start if requested
        if ($EnableImmediately)
        {
            Write-Host "Enabling and starting service..." -ForegroundColor Yellow
            & sudo systemctl enable $ServiceName
            & sudo systemctl start $ServiceName
            
            # Verify service started
            Start-Sleep -Seconds 2
            $status = & systemctl is-active $ServiceName
            if ($status -eq "active")
            {
                Write-Host "✓ Service started successfully" -ForegroundColor Green
            }
            else
            {
                Write-Warning "Service failed to start. Check logs: journalctl -u $ServiceName"
                return $false
            }
        }
        
        # Display deployment summary
        Write-Host "`nDeployment Summary:" -ForegroundColor Green
        Write-Host "  Service: $ServiceName" -ForegroundColor White
        Write-Host "  File: $serviceFile" -ForegroundColor White
        Write-Host "  Template: $ServiceTemplate" -ForegroundColor White
        Write-Host "  Environment: $Environment" -ForegroundColor White
        Write-Host "  Status: $(if ($EnableImmediately) { 'Enabled and Active' } else { 'Deployed (not started)' })" -ForegroundColor White
        
        return $true
    }
    catch
    {
        Write-Error "Service deployment failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-EnvironmentConfig
{
    param([string]$Environment)
    
    $configs = @{
        "development" = @{
            "LOG_LEVEL" = "debug"
            "RESTART_POLICY" = "on-failure"
            "MEMORY_LIMIT" = "512M"
            "CPU_QUOTA" = "50%"
        }
        "staging" = @{
            "LOG_LEVEL" = "info"
            "RESTART_POLICY" = "always"
            "MEMORY_LIMIT" = "1G"
            "CPU_QUOTA" = "75%"
        }
        "production" = @{
            "LOG_LEVEL" = "warning"
            "RESTART_POLICY" = "always"
            "MEMORY_LIMIT" = "2G"
            "CPU_QUOTA" = "100%"
        }
    }
    
    return $configs[$Environment] ?? $configs["production"]
}
```

### Best Practices Summary

1. **Service Design**
   - Use descriptive service names and documentation
   - Implement proper dependency management
   - Design for failure and recovery
   - Plan resource requirements

2. **Security**
   - Always run services as non-root users
   - Implement security hardening directives
   - Use capability restrictions
   - Enable sandboxing features

3. **Performance**
   - Set appropriate resource limits
   - Use CPU and I/O scheduling
   - Monitor resource usage
   - Optimize for your workload

4. **Monitoring**
   - Implement comprehensive logging
   - Set up alerting for failures
   - Monitor resource consumption
   - Regular health checks

5. **Maintenance**
   - Regular security audits
   - Keep services updated
   - Monitor log sizes
   - Document changes

---

## References and Additional Resources

- [systemd Documentation](https://systemd.io/)
- [systemd.service Manual](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [systemd.unit Manual](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
- [systemd.timer Manual](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Red Hat systemd Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-managing_services_with_systemd)
- [Arch Linux systemd Wiki](https://wiki.archlinux.org/title/systemd)
- [SystemD Security Features](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing)
