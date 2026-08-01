---
title: "Troubleshooting Guide"
description: "Diagnosing failed units, dependency problems, boot issues, and common systemd errors"
author: "josephstreeter"
tags: ["systemd", "linux", "troubleshooting", "debugging", "failed units"]
category: "infrastructure"
last_updated: "2026-08-01"
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

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
