---
title: "Security and Hardening"
description: "Sandboxing directives, capability restriction, filesystem and namespace isolation for systemd services"
author: "josephstreeter"
tags: ["systemd", "linux", "security", "hardening", "sandboxing"]
category: "infrastructure"
last_updated: "2026-08-01"
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

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
