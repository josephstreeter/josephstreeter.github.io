---
title: "Unit Files and Service Configuration"
description: "Writing systemd unit files, directive reference, dependencies, and service configuration"
author: "josephstreeter"
tags: ["systemd", "linux", "unit files", "service configuration", "systemctl"]
category: "infrastructure"
last_updated: "2026-08-01"
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

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
