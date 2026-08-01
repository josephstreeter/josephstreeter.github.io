---
title: "Timer Units and Scheduling"
description: "systemd timers as a cron replacement: monotonic and calendar timers, accuracy, and persistence"
author: "josephstreeter"
tags: ["systemd", "linux", "timers", "scheduling", "cron"]
category: "infrastructure"
last_updated: "2026-08-01"
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

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
