---
title: "Logging and Monitoring"
description: "journalctl, journal configuration, log retention, and monitoring systemd services"
author: "josephstreeter"
tags: ["systemd", "linux", "journalctl", "logging", "monitoring"]
category: "infrastructure"
last_updated: "2026-08-01"
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

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
