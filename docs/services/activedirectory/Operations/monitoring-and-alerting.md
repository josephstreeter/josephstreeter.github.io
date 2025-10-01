---
uid: ad-monitoring-logging
title: "Active Directory Monitoring and Logging Guide"
description: "Comprehensive guide for monitoring, logging, and auditing Active Directory environments with modern security practices, automation, and enterprise monitoring solutions."
author: "Active Directory Team"
ms.author: "adteam"
ms.date: "07/05/2025"
ms.topic: "conceptual"
ms.service: "active-directory"
ms.subservice: "monitoring"
keywords: ["Active Directory", "Monitoring", "Logging", "SIEM", "Performance", "Security", "Auditing", "PowerShell", "Automation"]
---

## Overview

Effective monitoring and logging are critical for maintaining Active Directory health, security, and performance. This guide covers comprehensive monitoring strategies that include performance metrics, security events, service health, and compliance auditing with automated alerting and response capabilities.

This comprehensive guide provides enterprise-level monitoring, logging, and auditing strategies for Active Directory environments with modern security practices, automation techniques, and integration with enterprise monitoring solutions.

## Prerequisites

### Technical Requirements

- Windows Server 2019 or later (Windows Server 2022 recommended)
- PowerShell 5.1 or later with ActiveDirectory module
- Enterprise monitoring solution (SCOM, Nagios, SolarWinds, or similar)
- SIEM solution for security event correlation
- Sufficient storage for log retention (minimum 90 days recommended)

### Planning Requirements

- Monitoring requirements and baseline performance metrics defined
- Security event monitoring and alerting thresholds established
- Compliance requirements identified (SOX, HIPAA, PCI-DSS, etc.)
- Log retention and archival policies defined
- Incident response procedures documented

### Security Requirements

- Least privilege access for monitoring accounts
- Secure log transmission and storage
- Event correlation and threat detection capabilities
- Compliance audit trail requirements
- Data protection and privacy considerations

## Monitoring Architecture

### Core Components

1. **Performance Monitoring**: System metrics, service health, and resource utilization
2. **Security Event Monitoring**: Authentication events, security policy changes, and threat detection
3. **Service Health Monitoring**: Critical AD services availability and functionality
4. **Replication Monitoring**: Inter-site and intra-site replication health
5. **Capacity Planning**: Growth trends and resource forecasting

### Integration Points

- **SIEM Integration**: Security event correlation and threat detection
- **Enterprise Monitoring**: Performance metrics and service availability
- **Cloud Services**: Azure AD Connect, hybrid scenarios
- **Backup Systems**: Backup success/failure monitoring
- **Change Management**: Configuration change tracking

## Performance Monitoring

### Critical Performance Counters

```powershell
# Comprehensive AD performance monitoring script
function Start-ADPerformanceMonitoring {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [int]$SampleInterval = 60,
        [int]$MonitoringDuration = 3600,
        [string]$LogPath = "C:\Monitoring\ADPerformance",
        [hashtable]$Thresholds = @{
            'CPU' = 80
            'Memory' = 85
            'DiskQueue' = 2
            'LDAPBinds' = 1000
            'KerberosAuth' = 500
        }
    )
    
    # Ensure log directory exists
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force
    }
    
    $PerformanceCounters = @(
        # System Performance
        '\Processor(_Total)\% Processor Time',
        '\Memory\% Committed Bytes In Use',
        '\PhysicalDisk(_Total)\Avg. Disk Queue Length',
        '\System\Processor Queue Length',
        
        # Active Directory Specific
        '\NTDS\LDAP Successful Binds/sec',
        '\NTDS\LDAP Searches/sec',
        '\NTDS\DS Directory Reads/sec',
        '\NTDS\DS Directory Writes/sec',
        '\NTDS\DRA Pending Replication Synchronizations',
        '\NTDS\DS Threads in Use',
        
        # Kerberos Authentication
        '\Security System-Wide Statistics\Kerberos Authentications',
        '\Security System-Wide Statistics\KDC AS Requests',
        '\Security System-Wide Statistics\KDC TGS Requests',
        
        # Database Performance
        '\Database ==> Instances(lsass/NTDSA)\Database Cache % Hit',
        '\Database ==> Instances(lsass/NTDSA)\Database Cache Size (MB)',
        '\Database ==> Instances(lsass/NTDSA)\Database Page Fault Stalls/sec',
        
        # Network Performance
        '\Network Interface(*)\Bytes Total/sec',
        '\Network Interface(*)\Packets/sec'
    )
    
    foreach ($DC in $DomainControllers) {
        Start-Job -Name "Monitor-$DC" -ScriptBlock {
            param($DC, $Counters, $Interval, $Duration, $LogPath, $Thresholds)
            
            $EndTime = (Get-Date).AddSeconds($Duration)
            $LogFile = Join-Path $LogPath "ADPerf_$DC_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            
            while ((Get-Date) -lt $EndTime) {
                try {
                    $PerfData = Get-Counter -ComputerName $DC -Counter $Counters -SampleInterval $Interval -MaxSamples 1
                    
                    foreach ($Sample in $PerfData.CounterSamples) {
                        $Result = [PSCustomObject]@{
                            Timestamp = $Sample.Timestamp
                            Computer = $DC
                            Counter = $Sample.Path
                            Value = $Sample.CookedValue
                            Instance = $Sample.InstanceName
                        }
                        
                        # Check thresholds and generate alerts
                        $CounterName = ($Sample.Path -split '\\')[-1]
                        switch -Wildcard ($CounterName) {
                            '*Processor Time*' {
                                if ($Sample.CookedValue -gt $Thresholds.CPU) {
                                    Write-Warning "HIGH CPU on $DC`: $($Sample.CookedValue)%"
                                }
                            }
                            '*Committed Bytes*' {
                                if ($Sample.CookedValue -gt $Thresholds.Memory) {
                                    Write-Warning "HIGH MEMORY on $DC`: $($Sample.CookedValue)%"
                                }
                            }
                            '*Queue Length*' {
                                if ($Sample.CookedValue -gt $Thresholds.DiskQueue) {
                                    Write-Warning "HIGH DISK QUEUE on $DC`: $($Sample.CookedValue)"
                                }
                            }
                        }
                        
                        $Result | Export-Csv -Path $LogFile -Append -NoTypeInformation
                    }
                }
                catch {
                    Write-Error "Failed to collect performance data from $DC`: $($_.Exception.Message)"
                }
                
                Start-Sleep -Seconds $Interval
            }
        } -ArgumentList $DC, $PerformanceCounters, $SampleInterval, $MonitoringDuration, $LogPath, $Thresholds
    }
    
    Write-Host "Performance monitoring started for $($DomainControllers.Count) domain controllers" -ForegroundColor Green
    Write-Host "Monitoring duration: $($MonitoringDuration/60) minutes" -ForegroundColor Green
    Write-Host "Log path: $LogPath" -ForegroundColor Green
}

# Advanced AD health monitoring with automated alerting
function Test-ADHealthMetrics {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [string]$AlertEmail = $null,
        [string]$SMTPServer = $null
    )
    
    $HealthResults = @()
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Checking health metrics for $DC..." -ForegroundColor Blue
        
        try {
            # Service Status Check
            $Services = @(
                'NTDS', 'DNS', 'Netlogon', 'W32Time', 'DFSR',
                'KDC', 'EventLog', 'RpcSs', 'RPCSS'
            )
            
            $ServiceStatus = foreach ($Service in $Services) {
                $Svc = Get-Service -ComputerName $DC -Name $Service -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Service = $Service
                    Status = if ($Svc) { $Svc.Status } else { 'NotFound' }
                    StartType = if ($Svc) { $Svc.StartType } else { 'Unknown' }
                }
            }
            
            # Replication Status
            $ReplStatus = Get-ADReplicationPartnerMetadata -Target $DC -Scope Domain
            $ReplIssues = $ReplStatus | Where-Object { 
                $_.LastReplicationSuccess -lt (Get-Date).AddHours(-2) -or
                $_.ConsecutiveReplicationFailures -gt 0
            }
            
            # Event Log Errors (last 24 hours)
            $EventErrors = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Directory Service', 'System', 'Application'
                Level = 1, 2  # Critical and Error
                StartTime = (Get-Date).AddDays(-1)
            } -MaxEvents 100 -ErrorAction SilentlyContinue
            
            # Disk Space Check
            $DiskSpace = Get-WmiObject -ComputerName $DC -Class Win32_LogicalDisk | Where-Object {
                $_.DriveType -eq 3  # Fixed disk
            } | Select-Object DeviceID, 
                @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}},
                @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace/1GB,2)}},
                @{Name='PercentFree';Expression={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}}
            
            $LowDiskSpace = $DiskSpace | Where-Object { $_.PercentFree -lt 20 }
            
            # Compile health summary
            $HealthSummary = [PSCustomObject]@{
                DomainController = $DC
                Timestamp = Get-Date
                ServicesDown = ($ServiceStatus | Where-Object { $_.Status -ne 'Running' }).Count
                ReplicationIssues = $ReplIssues.Count
                CriticalEvents = $EventErrors.Count
                LowDiskSpaceCount = $LowDiskSpace.Count
                OverallHealth = 'Healthy'
                Issues = @()
            }
            
            # Determine overall health
            if ($HealthSummary.ServicesDown -gt 0) {
                $HealthSummary.OverallHealth = 'Critical'
                $HealthSummary.Issues += "Services down: $($HealthSummary.ServicesDown)"
            }
            
            if ($HealthSummary.ReplicationIssues -gt 0) {
                $HealthSummary.OverallHealth = 'Warning'
                $HealthSummary.Issues += "Replication issues: $($HealthSummary.ReplicationIssues)"
            }
            
            if ($HealthSummary.CriticalEvents -gt 10) {
                $HealthSummary.OverallHealth = 'Warning'
                $HealthSummary.Issues += "High error count: $($HealthSummary.CriticalEvents)"
            }
            
            if ($HealthSummary.LowDiskSpaceCount -gt 0) {
                $HealthSummary.OverallHealth = 'Warning'
                $HealthSummary.Issues += "Low disk space on $($HealthSummary.LowDiskSpaceCount) drives"
            }
            
            $HealthResults += $HealthSummary
            
            # Send alert if issues found
            if ($HealthSummary.OverallHealth -ne 'Healthy' -and $AlertEmail -and $SMTPServer) {
                $Subject = "AD Health Alert - $DC - $($HealthSummary.OverallHealth)"
                $Body = "Domain Controller: $DC`n"
                $Body += "Status: $($HealthSummary.OverallHealth)`n"
                $Body += "Issues: $($HealthSummary.Issues -join ', ')`n"
                $Body += "Timestamp: $(Get-Date)`n"
                
                Send-MailMessage -To $AlertEmail -Subject $Subject -Body $Body -SmtpServer $SMTPServer
            }
        }
        catch {
            Write-Error "Failed to check health for $DC`: $($_.Exception.Message)"
        }
    }
    
    return $HealthResults
}
```

### Performance Baseline Establishment

```powershell
# Establish performance baselines for capacity planning
function New-ADPerformanceBaseline {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [int]$BaselineDays = 30,
        [string]$ReportPath = "C:\Reports\AD_Baseline_$(Get-Date -Format 'yyyyMMdd').html"
    )
    
    $BaselineData = @()
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Collecting baseline data for $DC..." -ForegroundColor Blue
        
        # Collect key performance metrics
        $Metrics = @{
            'CPUAverage' = (Get-Counter -ComputerName $DC -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 300 -MaxSamples 288 | 
                           ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
            'MemoryAverage' = (Get-Counter -ComputerName $DC -Counter '\Memory\% Committed Bytes In Use' -SampleInterval 300 -MaxSamples 288 | 
                              ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
            'LDAPBindsPerSec' = (Get-Counter -ComputerName $DC -Counter '\NTDS\LDAP Successful Binds/sec' -SampleInterval 300 -MaxSamples 288 | 
                                ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
            'KerberosAuthPerSec' = (Get-Counter -ComputerName $DC -Counter '\Security System-Wide Statistics\Kerberos Authentications' -SampleInterval 300 -MaxSamples 288 | 
                                   ForEach-Object { $_.CounterSamples.CookedValue } | Measure-Object -Average).Average
        }
        
        $BaselineData += [PSCustomObject]@{
            DomainController = $DC
            BaselineDate = Get-Date
            CPUBaseline = [math]::Round($Metrics.CPUAverage, 2)
            MemoryBaseline = [math]::Round($Metrics.MemoryAverage, 2)
            LDAPBindsBaseline = [math]::Round($Metrics.LDAPBindsPerSec, 2)
            KerberosAuthBaseline = [math]::Round($Metrics.KerberosAuthPerSec, 2)
            RecommendedCPUThreshold = [math]::Round($Metrics.CPUAverage * 1.5, 2)
            RecommendedMemoryThreshold = [math]::Round($Metrics.MemoryAverage * 1.2, 2)
        }
    }
    
    # Generate baseline report
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Performance Baseline Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .header { background-color: #4CAF50; color: white; padding: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Performance Baseline Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Baseline Period: $BaselineDays days</p>
    </div>
    
    <h2>Performance Baselines</h2>
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>CPU Baseline (%)</th>
            <th>Memory Baseline (%)</th>
            <th>LDAP Binds/sec</th>
            <th>Kerberos Auth/sec</th>
            <th>Recommended CPU Threshold</th>
            <th>Recommended Memory Threshold</th>
        </tr>
"@
    
    foreach ($Data in $BaselineData) {
        $Html += @"
        <tr>
            <td>$($Data.DomainController)</td>
            <td>$($Data.CPUBaseline)</td>
            <td>$($Data.MemoryBaseline)</td>
            <td>$($Data.LDAPBindsBaseline)</td>
            <td>$($Data.KerberosAuthBaseline)</td>
            <td>$($Data.RecommendedCPUThreshold)</td>
            <td>$($Data.RecommendedMemoryThreshold)</td>
        </tr>
"@
    }
    
    $Html += @"
    </table>
    
    <h2>Monitoring Recommendations</h2>
    <ul>
        <li>Set CPU alerts at recommended threshold levels</li>
        <li>Monitor memory usage trends for capacity planning</li>
        <li>Track authentication patterns for performance optimization</li>
        <li>Review baselines monthly and adjust thresholds accordingly</li>
    </ul>
</body>
</html>
"@
    
    $Html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Baseline report generated: $ReportPath" -ForegroundColor Green
    
    return $BaselineData
}
```

## Security Event Monitoring

### Critical Security Events

```powershell
# Comprehensive security event monitoring for Active Directory
function Start-ADSecurityMonitoring {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [string]$SIEMServer = $null,
        [int]$MonitoringInterval = 300,  # 5 minutes
        [string]$AlertEmail = $null,
        [string]$SMTPServer = $null
    )
    
    # Critical security events to monitor
    $SecurityEvents = @{
        # Authentication Events
        4625 = 'Failed Logon'
        4648 = 'Logon with Explicit Credentials'
        4768 = 'Kerberos TGT Request'
        4769 = 'Kerberos Service Ticket Request'
        4771 = 'Kerberos Pre-authentication Failed'
        4776 = 'Domain Controller Authentication'
        
        # Account Management
        4720 = 'User Account Created'
        4722 = 'User Account Enabled'
        4724 = 'Password Reset'
        4725 = 'User Account Disabled'
        4726 = 'User Account Deleted'
        4738 = 'User Account Changed'
        4740 = 'User Account Locked Out'
        4767 = 'User Account Unlocked'
        
        # Group Management
        4727 = 'Security-enabled Global Group Created'
        4728 = 'Member Added to Security-enabled Global Group'
        4729 = 'Member Removed from Security-enabled Global Group'
        4731 = 'Security-enabled Local Group Created'
        4732 = 'Member Added to Security-enabled Local Group'
        4733 = 'Member Removed from Security-enabled Local Group'
        4756 = 'Member Added to Security-enabled Universal Group'
        4757 = 'Member Removed from Security-enabled Universal Group'
        
        # Privilege Escalation
        4672 = 'Special Privileges Assigned'
        4673 = 'Privileged Service Called'
        4674 = 'Operation Attempted on Privileged Object'
        
        # Policy Changes
        4713 = 'Kerberos Policy Changed'
        4719 = 'System Audit Policy Changed'
        4739 = 'Domain Policy Changed'
        4864 = 'Namespace Collision'
        
        # System Events
        1102 = 'Audit Log Cleared'
        4608 = 'Windows Starting'
        4609 = 'Windows Shutting Down'
        4616 = 'System Time Changed'
        
        # Directory Service Changes
        5136 = 'Directory Service Object Modified'
        5137 = 'Directory Service Object Created'
        5138 = 'Directory Service Object Undeleted'
        5139 = 'Directory Service Object Moved'
        5141 = 'Directory Service Object Deleted'
    }
    
    foreach ($DC in $DomainControllers) {
        Start-Job -Name "SecurityMonitor-$DC" -ScriptBlock {
            param($DC, $Events, $Interval, $SIEMServer, $AlertEmail, $SMTPServer)
            
            $LastCheck = (Get-Date).AddMinutes(-5)
            
            while ($true) {
                try {
                    $CurrentCheck = Get-Date
                    
                    # Query security events
                    $SecurityLogs = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                        LogName = 'Security'
                        ID = $Events.Keys
                        StartTime = $LastCheck
                        EndTime = $CurrentCheck
                    } -ErrorAction SilentlyContinue
                    
                    foreach ($Event in $SecurityLogs) {
                        $EventData = [PSCustomObject]@{
                            Timestamp = $Event.TimeCreated
                            Computer = $DC
                            EventID = $Event.Id
                            EventName = $Events[$Event.Id]
                            Level = $Event.LevelDisplayName
                            User = $Event.Properties[5].Value
                            Source = $Event.Properties[18].Value
                            Message = $Event.Message
                            ProcessName = $Event.Properties[9].Value
                        }
                        
                        # Send to SIEM if configured
                        if ($SIEMServer) {
                            # Send via syslog or API (implementation depends on SIEM)
                            Send-SyslogMessage -Server $SIEMServer -Message ($EventData | ConvertTo-Json)
                        }
                        
                        # Generate alerts for critical events
                        $CriticalEvents = @(4625, 4740, 1102, 4713, 4719)
                        if ($Event.Id -in $CriticalEvents) {
                            $AlertSubject = "CRITICAL AD Security Event - $($Events[$Event.Id]) on $DC"
                            $AlertBody = "Event ID: $($Event.Id)`n"
                            $AlertBody += "Event: $($Events[$Event.Id])`n"
                            $AlertBody += "Time: $($Event.TimeCreated)`n"
                            $AlertBody += "Computer: $DC`n"
                            $AlertBody += "Details: $($Event.Message)`n"
                            
                            if ($AlertEmail -and $SMTPServer) {
                                Send-MailMessage -To $AlertEmail -Subject $AlertSubject -Body $AlertBody -SmtpServer $SMTPServer
                            }
                        }
                        
                        # Log to file
                        $LogFile = "C:\Logs\ADSecurity_$DC_$(Get-Date -Format 'yyyyMMdd').log"
                        "$($EventData.Timestamp) - $($EventData.EventName) - $($EventData.User)" | Add-Content -Path $LogFile
                    }
                    
                    $LastCheck = $CurrentCheck
                    Start-Sleep -Seconds $Interval
                }
                catch {
                    Write-Error "Security monitoring error on $DC`: $($_.Exception.Message)"
                    Start-Sleep -Seconds 60
                }
            }
        } -ArgumentList $DC, $SecurityEvents, $MonitoringInterval, $SIEMServer, $AlertEmail, $SMTPServer
    }
    
    Write-Host "Security monitoring started for $($DomainControllers.Count) domain controllers" -ForegroundColor Green
}

# Threat detection and analysis
function Search-ADSecurityThreats {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [datetime]$StartTime = (Get-Date).AddHours(-24),
        [datetime]$EndTime = (Get-Date),
        [string]$ReportPath = "C:\Reports\AD_ThreatAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    $ThreatIndicators = @()
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Analyzing security events on $DC..." -ForegroundColor Blue
        
        try {
            # Brute Force Detection (multiple failed logons)
            $FailedLogons = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4625
                StartTime = $StartTime
                EndTime = $EndTime
            } -ErrorAction SilentlyContinue
            
            $BruteForceAttempts = $FailedLogons | Group-Object {$_.Properties[5].Value} | 
                Where-Object {$_.Count -gt 10} | ForEach-Object {
                    [PSCustomObject]@{
                        ThreatType = 'Brute Force Attack'
                        Severity = 'High'
                        TargetUser = $_.Name
                        AttemptCount = $_.Count
                        DomainController = $DC
                        FirstAttempt = ($_.Group | Sort-Object TimeCreated)[0].TimeCreated
                        LastAttempt = ($_.Group | Sort-Object TimeCreated)[-1].TimeCreated
                    }
                }
            
            # Privilege Escalation Detection
            $PrivilegeEvents = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4672, 4673, 4674
                StartTime = $StartTime
                EndTime = $EndTime
            } -ErrorAction SilentlyContinue
            
            $SuspiciousPrivileges = $PrivilegeEvents | Group-Object {$_.Properties[1].Value} | 
                Where-Object {$_.Count -gt 50} | ForEach-Object {
                    [PSCustomObject]@{
                        ThreatType = 'Suspicious Privilege Usage'
                        Severity = 'Medium'
                        User = $_.Name
                        EventCount = $_.Count
                        DomainController = $DC
                        FirstEvent = ($_.Group | Sort-Object TimeCreated)[0].TimeCreated
                        LastEvent = ($_.Group | Sort-Object TimeCreated)[-1].TimeCreated
                    }
                }
            
            # Account Manipulation Detection
            $AccountChanges = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4720, 4722, 4724, 4738
                StartTime = $StartTime
                EndTime = $EndTime
            } -ErrorAction SilentlyContinue
            
            $RapidAccountChanges = $AccountChanges | Group-Object {$_.Properties[0].Value} | 
                Where-Object {$_.Count -gt 5} | ForEach-Object {
                    [PSCustomObject]@{
                        ThreatType = 'Rapid Account Manipulation'
                        Severity = 'Medium'
                        TargetAccount = $_.Name
                        ChangeCount = $_.Count
                        DomainController = $DC
                        FirstChange = ($_.Group | Sort-Object TimeCreated)[0].TimeCreated
                        LastChange = ($_.Group | Sort-Object TimeCreated)[-1].TimeCreated
                    }
                }
            
            $ThreatIndicators += $BruteForceAttempts
            $ThreatIndicators += $SuspiciousPrivileges
            $ThreatIndicators += $RapidAccountChanges
        }
        catch {
            Write-Error "Failed to analyze threats on $DC`: $($_.Exception.Message)"
        }
    }
    
    # Generate threat analysis report
    if ($ThreatIndicators.Count -gt 0) {
        $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Threat Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { background-color: #ffcccc; }
        .medium { background-color: #fff3cd; }
        .low { background-color: #d4edda; }
        .header { background-color: #dc3545; color: white; padding: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Threat Analysis Report</h1>
        <p>Analysis Period: $StartTime to $EndTime</p>
        <p>Threats Detected: $($ThreatIndicators.Count)</p>
    </div>
    
    <h2>Detected Threats</h2>
    <table>
        <tr>
            <th>Threat Type</th>
            <th>Severity</th>
            <th>Target/User</th>
            <th>Count</th>
            <th>Domain Controller</th>
            <th>First Occurrence</th>
            <th>Last Occurrence</th>
        </tr>
"@
        
        foreach ($Threat in $ThreatIndicators | Sort-Object Severity, ThreatType) {
            $SeverityClass = $Threat.Severity.ToLower()
            $Html += @"
        <tr class="$SeverityClass">
            <td>$($Threat.ThreatType)</td>
            <td>$($Threat.Severity)</td>
            <td>$($Threat.TargetUser ?? $Threat.User ?? $Threat.TargetAccount)</td>
            <td>$($Threat.AttemptCount ?? $Threat.EventCount ?? $Threat.ChangeCount)</td>
            <td>$($Threat.DomainController)</td>
            <td>$($Threat.FirstAttempt ?? $Threat.FirstEvent ?? $Threat.FirstChange)</td>
            <td>$($Threat.LastAttempt ?? $Threat.LastEvent ?? $Threat.LastChange)</td>
        </tr>
"@
        }
        
        $Html += @"
    </table>
    
    <h2>Recommended Actions</h2>
    <ul>
        <li><strong>High Severity Threats:</strong> Immediate investigation and response required</li>
        <li><strong>Medium Severity Threats:</strong> Review and validate activity within 24 hours</li>
        <li><strong>Brute Force Attacks:</strong> Consider account lockout policies and MFA implementation</li>
        <li><strong>Privilege Escalation:</strong> Review privileged account activities and access controls</li>
        <li><strong>Account Manipulation:</strong> Validate all account changes through change management</li>
    </ul>
</body>
</html>
"@
        
        $Html | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-Host "Threat analysis report generated: $ReportPath" -ForegroundColor Yellow
        Write-Host "Threats detected: $($ThreatIndicators.Count)" -ForegroundColor $(if ($ThreatIndicators.Count -gt 0) { 'Red' } else { 'Green' })
    }
    else {
        Write-Host "No threats detected in the specified time period" -ForegroundColor Green
    }
    
    return $ThreatIndicators
}
```

## Service Health Monitoring

### Critical Active Directory Services

```powershell
# Comprehensive service monitoring with automated remediation
function Monitor-ADServices {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [switch]$AutoRestart,
        [string]$AlertEmail = $null,
        [string]$SMTPServer = $null,
        [int]$CheckInterval = 300  # 5 minutes
    )
    
    # Critical AD services with dependencies
    $CriticalServices = @{
        'NTDS' = @{
            DisplayName = 'Active Directory Domain Services'
            Dependencies = @('RpcSs', 'EventLog')
            RestartAllowed = $true
            Priority = 'Critical'
        }
        'DNS' = @{
            DisplayName = 'DNS Server'
            Dependencies = @('RpcSs', 'EventLog')
            RestartAllowed = $true
            Priority = 'Critical'
        }
        'Netlogon' = @{
            DisplayName = 'Netlogon'
            Dependencies = @('RpcSs', 'NTDS')
            RestartAllowed = $true
            Priority = 'Critical'
        }
        'W32Time' = @{
            DisplayName = 'Windows Time'
            Dependencies = @()
            RestartAllowed = $true
            Priority = 'High'
        }
        'DFSR' = @{
            DisplayName = 'DFS Replication'
            Dependencies = @('RpcSs')
            RestartAllowed = $true
            Priority = 'High'
        }
        'KDC' = @{
            DisplayName = 'Kerberos Key Distribution Center'
            Dependencies = @('NTDS')
            RestartAllowed = $false  # Requires careful handling
            Priority = 'Critical'
        }
        'EventLog' = @{
            DisplayName = 'Windows Event Log'
            Dependencies = @()
            RestartAllowed = $true
            Priority = 'Critical'
        }
        'RpcSs' = @{
            DisplayName = 'Remote Procedure Call (RPC)'
            Dependencies = @()
            RestartAllowed = $false  # System critical
            Priority = 'Critical'
        }
    }
    
    foreach ($DC in $DomainControllers) {
        Start-Job -Name "ServiceMonitor-$DC" -ScriptBlock {
            param($DC, $Services, $AutoRestart, $AlertEmail, $SMTPServer, $CheckInterval)
            
            while ($true) {
                try {
                    $ServiceIssues = @()
                    
                    foreach ($ServiceName in $Services.Keys) {
                        $ServiceInfo = $Services[$ServiceName]
                        $Service = Get-Service -ComputerName $DC -Name $ServiceName -ErrorAction SilentlyContinue
                        
                        if (-not $Service) {
                            $Issue = [PSCustomObject]@{
                                Service = $ServiceName
                                DisplayName = $ServiceInfo.DisplayName
                                Status = 'NotInstalled'
                                Action = 'Manual intervention required'
                                Priority = $ServiceInfo.Priority
                                Timestamp = Get-Date
                            }
                            $ServiceIssues += $Issue
                            continue
                        }
                        
                        if ($Service.Status -ne 'Running') {
                            $Issue = [PSCustomObject]@{
                                Service = $ServiceName
                                DisplayName = $ServiceInfo.DisplayName
                                Status = $Service.Status
                                Action = 'None'
                                Priority = $ServiceInfo.Priority
                                Timestamp = Get-Date
                            }
                            
                            # Attempt automatic restart if enabled and allowed
                            if ($AutoRestart -and $ServiceInfo.RestartAllowed) {
                                try {
                                    Write-Host "Attempting to restart $ServiceName on $DC..." -ForegroundColor Yellow
                                    Start-Service -InputObject $Service
                                    Start-Sleep -Seconds 30
                                    $Service.Refresh()
                                    
                                    if ($Service.Status -eq 'Running') {
                                        $Issue.Action = 'Successfully restarted'
                                        Write-Host "$ServiceName restarted successfully on $DC" -ForegroundColor Green
                                    } else {
                                        $Issue.Action = 'Restart failed'
                                        Write-Host "Failed to restart $ServiceName on $DC" -ForegroundColor Red
                                    }
                                }
                                catch {
                                    $Issue.Action = "Restart error: $($_.Exception.Message)"
                                    Write-Error "Error restarting $ServiceName on $DC`: $($_.Exception.Message)"
                                }
                            } else {
                                $Issue.Action = 'Manual restart required'
                            }
                            
                            $ServiceIssues += $Issue
                        }
                    }
                    
                    # Send alerts for service issues
                    if ($ServiceIssues.Count -gt 0 -and $AlertEmail -and $SMTPServer) {
                        $CriticalIssues = $ServiceIssues | Where-Object { $_.Priority -eq 'Critical' }
                        
                        if ($CriticalIssues.Count -gt 0) {
                            $Subject = "CRITICAL: AD Service Issues on $DC"
                            $Body = "Critical Active Directory service issues detected on $DC`:`n`n"
                            
                            foreach ($Issue in $CriticalIssues) {
                                $Body += "Service: $($Issue.DisplayName) ($($Issue.Service))`n"
                                $Body += "Status: $($Issue.Status)`n"
                                $Body += "Action: $($Issue.Action)`n"
                                $Body += "Time: $($Issue.Timestamp)`n`n"
                            }
                            
                            $Body += "Please investigate immediately to prevent service degradation."
                            
                            Send-MailMessage -To $AlertEmail -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Priority High
                        }
                    }
                    
                    # Log service status
                    $LogFile = "C:\Logs\ADServices_$DC_$(Get-Date -Format 'yyyyMMdd').log"
                    if ($ServiceIssues.Count -gt 0) {
                        foreach ($Issue in $ServiceIssues) {
                            "$(Get-Date) - $($Issue.Service) - $($Issue.Status) - $($Issue.Action)" | Add-Content -Path $LogFile
                        }
                    }
                    
                    Start-Sleep -Seconds $CheckInterval
                }
                catch {
                    Write-Error "Service monitoring error on $DC`: $($_.Exception.Message)"
                    Start-Sleep -Seconds 60
                }
            }
        } -ArgumentList $DC, $CriticalServices, $AutoRestart, $AlertEmail, $SMTPServer, $CheckInterval
    }
    
    Write-Host "Service monitoring started for $($DomainControllers.Count) domain controllers" -ForegroundColor Green
    if ($AutoRestart) {
        Write-Host "Automatic service restart enabled (where permitted)" -ForegroundColor Yellow
    }
}

# Service dependency analysis and health report
function Get-ADServiceHealth {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [string]$ReportPath = "C:\Reports\AD_ServiceHealth_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    $ServiceHealth = @()
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Checking service health on $DC..." -ForegroundColor Blue
        
        try {
            $Services = Get-Service -ComputerName $DC | Where-Object {
                $_.Name -in @('NTDS', 'DNS', 'Netlogon', 'W32Time', 'DFSR', 'KDC', 'EventLog', 'RpcSs', 'LanmanServer', 'LanmanWorkstation', 'COMSysApp')
            }
            
            foreach ($Service in $Services) {
                $StartupType = (Get-WmiObject -ComputerName $DC -Class Win32_Service -Filter "Name='$($Service.Name)'").StartMode
                $ProcessId = (Get-WmiObject -ComputerName $DC -Class Win32_Service -Filter "Name='$($Service.Name)'").ProcessId
                
                $ServiceHealth += [PSCustomObject]@{
                    DomainController = $DC
                    ServiceName = $Service.Name
                    DisplayName = $Service.DisplayName
                    Status = $Service.Status
                    StartupType = $StartupType
                    ProcessId = $ProcessId
                    CanPauseAndContinue = $Service.CanPauseAndContinue
                    CanShutdown = $Service.CanShutdown
                    CanStop = $Service.CanStop
                    CheckTime = Get-Date
                }
            }
        }
        catch {
            Write-Error "Failed to check service health on $DC`: $($_.Exception.Message)"
        }
    }
    
    # Generate service health report
    $HealthySugar = $ServiceHealth | Where-Object { $_.Status -eq 'Running' }
    $UnhealthyServices = $ServiceHealth | Where-Object { $_.Status -ne 'Running' }
    
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Service Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .running { background-color: #d4edda; }
        .stopped { background-color: #f8d7da; }
        .starting { background-color: #fff3cd; }
        .header { background-color: #007bff; color: white; padding: 10px; }
        .summary { background-color: #f8f9fa; padding: 15px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Service Health Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Domain Controllers Checked: $($DomainControllers.Count)</p>
    </div>
    
    <div class="summary">
        <h2>Health Summary</h2>
        <p><strong>Total Services Checked:</strong> $($ServiceHealth.Count)</p>
        <p><strong>Healthy Services:</strong> $($HealthySugar.Count)</p>
        <p><strong>Unhealthy Services:</strong> $($UnhealthyServices.Count)</p>
        <p><strong>Overall Health:</strong> $(if ($UnhealthyServices.Count -eq 0) { "HEALTHY" } else { "ISSUES DETECTED" })</p>
    </div>
"@
    
    if ($UnhealthyServices.Count -gt 0) {
        $Html += @"
    <h2>Service Issues</h2>
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>Service</th>
            <th>Display Name</th>
            <th>Status</th>
            <th>Startup Type</th>
            <th>Check Time</th>
        </tr>
"@
        
        foreach ($Service in $UnhealthyServices) {
            $StatusClass = $Service.Status.ToLower()
            $Html += @"
        <tr class="$StatusClass">
            <td>$($Service.DomainController)</td>
            <td>$($Service.ServiceName)</td>
            <td>$($Service.DisplayName)</td>
            <td>$($Service.Status)</td>
            <td>$($Service.StartupType)</td>
            <td>$($Service.CheckTime)</td>
        </tr>
"@
        }
        
        $Html += "</table>"
    }
    
    $Html += @"
    <h2>All Services Status</h2>
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>Service</th>
            <th>Display Name</th>
            <th>Status</th>
            <th>Startup Type</th>
            <th>Process ID</th>
        </tr>
"@
    
    foreach ($Service in $ServiceHealth | Sort-Object DomainController, ServiceName) {
        $StatusClass = $Service.Status.ToLower()
        $Html += @"
        <tr class="$StatusClass">
            <td>$($Service.DomainController)</td>
            <td>$($Service.ServiceName)</td>
            <td>$($Service.DisplayName)</td>
            <td>$($Service.Status)</td>
            <td>$($Service.StartupType)</td>
            <td>$($Service.ProcessId)</td>
        </tr>
"@
    }
    
    $Html += @"
    </table>
</body>
</html>
"@
    
    $Html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Service health report generated: $ReportPath" -ForegroundColor Green
    
    return $ServiceHealth
}
```

## Replication Monitoring

### Active Directory Replication Health

```powershell
# Comprehensive AD replication monitoring
function Monitor-ADReplication {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [int]$MaxReplicationLag = 60,  # minutes
        [string]$AlertEmail = $null,
        [string]$SMTPServer = $null,
        [string]$ReportPath = "C:\Reports\AD_ReplicationHealth_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    $ReplicationStatus = @()
    $ReplicationIssues = @()
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Checking replication status for $DC..." -ForegroundColor Blue
        
        try {
            # Get replication partner metadata
            $Partners = Get-ADReplicationPartnerMetadata -Target $DC -Scope Domain
            
            foreach ($Partner in $Partners) {
                $ReplicationLag = (Get-Date) - $Partner.LastReplicationSuccess
                $IsHealthy = $ReplicationLag.TotalMinutes -le $MaxReplicationLag -and $Partner.ConsecutiveReplicationFailures -eq 0
                
                $Status = [PSCustomObject]@{
                    SourceDC = $DC
                    PartnerDC = $Partner.Partner
                    Partition = $Partner.Partition
                    LastReplicationSuccess = $Partner.LastReplicationSuccess
                    LastReplicationAttempt = $Partner.LastReplicationAttempt
                    ReplicationLagMinutes = [math]::Round($ReplicationLag.TotalMinutes, 2)
                    ConsecutiveFailures = $Partner.ConsecutiveReplicationFailures
                    LastReplicationResult = $Partner.LastReplicationResult
                    IsHealthy = $IsHealthy
                    CheckTime = Get-Date
                }
                
                $ReplicationStatus += $Status
                
                if (-not $IsHealthy) {
                    $ReplicationIssues += $Status
                }
            }
            
            # Check replication queue
            $ReplQueue = Get-ADReplicationQueueOperation -Server $DC
            if ($ReplQueue.Count -gt 0) {
                Write-Warning "$DC has $($ReplQueue.Count) pending replication operations"
            }
        }
        catch {
            Write-Error "Failed to check replication on $DC`: $($_.Exception.Message)"
            $ReplicationIssues += [PSCustomObject]@{
                SourceDC = $DC
                PartnerDC = 'Unknown'
                Partition = 'Unknown'
                LastReplicationSuccess = 'Error'
                LastReplicationAttempt = 'Error'
                ReplicationLagMinutes = 9999
                ConsecutiveFailures = 9999
                LastReplicationResult = "Error: $($_.Exception.Message)"
                IsHealthy = $false
                CheckTime = Get-Date
            }
        }
    }
    
    # Generate alerts for replication issues
    if ($ReplicationIssues.Count -gt 0 -and $AlertEmail -and $SMTPServer) {
        $Subject = "Active Directory Replication Issues Detected"
        $Body = "Replication issues detected in Active Directory:`n`n"
        
        foreach ($Issue in $ReplicationIssues) {
            $Body += "Source DC: $($Issue.SourceDC)`n"
            $Body += "Partner DC: $($Issue.PartnerDC)`n"
            $Body += "Partition: $($Issue.Partition)`n"
            $Body += "Last Success: $($Issue.LastReplicationSuccess)`n"
            $Body += "Lag (minutes): $($Issue.ReplicationLagMinutes)`n"
            $Body += "Consecutive Failures: $($Issue.ConsecutiveFailures)`n"
            $Body += "Last Result: $($Issue.LastReplicationResult)`n`n"
        }
        
        Send-MailMessage -To $AlertEmail -Subject $Subject -Body $Body -SmtpServer $SMTPServer
    }
    
    # Generate replication health report
    $HealthyReplications = $ReplicationStatus | Where-Object { $_.IsHealthy }
    $UnhealthyReplications = $ReplicationStatus | Where-Object { -not $_.IsHealthy }
    
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Replication Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { background-color: #d4edda; }
        .unhealthy { background-color: #f8d7da; }
        .warning { background-color: #fff3cd; }
        .header { background-color: #28a745; color: white; padding: 10px; }
        .summary { background-color: #f8f9fa; padding: 15px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Replication Health Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Maximum Acceptable Lag: $MaxReplicationLag minutes</p>
    </div>
    
    <div class="summary">
        <h2>Replication Summary</h2>
        <p><strong>Total Replication Links:</strong> $($ReplicationStatus.Count)</p>
        <p><strong>Healthy Replications:</strong> $($HealthyReplications.Count)</p>
        <p><strong>Unhealthy Replications:</strong> $($UnhealthyReplications.Count)</p>
        <p><strong>Overall Health:</strong> $(if ($UnhealthyReplications.Count -eq 0) { "HEALTHY" } else { "ISSUES DETECTED" })</p>
    </div>
"@
    
    if ($UnhealthyReplications.Count -gt 0) {
        $Html += @"
    <h2>Replication Issues</h2>
    <table>
        <tr>
            <th>Source DC</th>
            <th>Partner DC</th>
            <th>Partition</th>
            <th>Last Success</th>
            <th>Lag (min)</th>
            <th>Failures</th>
            <th>Last Result</th>
        </tr>
"@
        
        foreach ($Issue in $UnhealthyReplications) {
            $Html += @"
        <tr class="unhealthy">
            <td>$($Issue.SourceDC)</td>
            <td>$($Issue.PartnerDC)</td>
            <td>$($Issue.Partition)</td>
            <td>$($Issue.LastReplicationSuccess)</td>
            <td>$($Issue.ReplicationLagMinutes)</td>
            <td>$($Issue.ConsecutiveFailures)</td>
            <td>$($Issue.LastReplicationResult)</td>
        </tr>
"@
        }
        
        $Html += "</table>"
    }
    
    $Html += @"
    <h2>All Replication Status</h2>
    <table>
        <tr>
            <th>Source DC</th>
            <th>Partner DC</th>
            <th>Partition</th>
            <th>Last Success</th>
            <th>Lag (min)</th>
            <th>Failures</th>
            <th>Status</th>
        </tr>
"@
    
    foreach ($Status in $ReplicationStatus | Sort-Object SourceDC, PartnerDC) {
        $HealthClass = if ($Status.IsHealthy) { "healthy" } else { "unhealthy" }
        $Html += @"
        <tr class="$HealthClass">
            <td>$($Status.SourceDC)</td>
            <td>$($Status.PartnerDC)</td>
            <td>$($Status.Partition)</td>
            <td>$($Status.LastReplicationSuccess)</td>
            <td>$($Status.ReplicationLagMinutes)</td>
            <td>$($Status.ConsecutiveFailures)</td>
            <td>$(if ($Status.IsHealthy) { "Healthy" } else { "Issue" })</td>
        </tr>
"@
    }
    
    $Html += @"
    </table>
</body>
</html>
"@
    
    $Html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Replication health report generated: $ReportPath" -ForegroundColor Green
    
    return $ReplicationStatus
}

# Force replication and monitor convergence
function Invoke-ADReplicationSync {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [switch]$AllPartitions,
        [int]$TimeoutMinutes = 30
    )
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Initiating replication sync on $DC..." -ForegroundColor Blue
        
        try {
            if ($AllPartitions) {
                # Sync all partitions
                $Partitions = Get-ADReplicationPartnerMetadata -Target $DC | 
                             Select-Object -ExpandProperty Partition -Unique
                
                foreach ($Partition in $Partitions) {
                    Write-Host "  Syncing partition: $Partition" -ForegroundColor Gray
                    Sync-ADObject -Object $Partition -Source $DC -Destination "*"
                }
            } else {
                # Sync domain partition only
                $DomainDN = (Get-ADDomain).DistinguishedName
                Sync-ADObject -Object $DomainDN -Source $DC -Destination "*"
            }
            
            Write-Host "Replication sync initiated on $DC" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to initiate replication sync on $DC`: $($_.Exception.Message)"
        }
    }
    
    # Monitor convergence
    Write-Host "Monitoring replication convergence..." -ForegroundColor Yellow
    $StartTime = Get-Date
    $ConvergenceAchieved = $false
    
    while (-not $ConvergenceAchieved -and ((Get-Date) - $StartTime).TotalMinutes -lt $TimeoutMinutes) {
        Start-Sleep -Seconds 30
        
        $PendingOperations = 0
        foreach ($DC in $DomainControllers) {
            try {
                $Queue = Get-ADReplicationQueueOperation -Server $DC
                $PendingOperations += $Queue.Count
            }
            catch {
                Write-Warning "Could not check replication queue on $DC"
            }
        }
        
        if ($PendingOperations -eq 0) {
            $ConvergenceAchieved = $true
            Write-Host "Replication convergence achieved!" -ForegroundColor Green
        } else {
            Write-Host "Pending operations: $PendingOperations" -ForegroundColor Yellow
        }
    }
    
    if (-not $ConvergenceAchieved) {
        Write-Warning "Replication convergence not achieved within $TimeoutMinutes minutes"
    }
    
    return $ConvergenceAchieved
}
```

## Logging and Auditing

### Enterprise Logging Strategy

```powershell
# Configure comprehensive AD logging and forwarding
function Set-ADLoggingConfiguration {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [string]$SIEMServer = $null,
        [int]$SyslogPort = 514,
        [hashtable]$LogLevels = @{
            'Knowledge Consistency Checker' = 3
            'Security Events' = 4
            'Replication Events' = 3
            'Global Catalog' = 2
            'Inter-site Messaging' = 2
        }
    )
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Configuring logging on $DC..." -ForegroundColor Blue
        
        try {
            # Configure diagnostic logging levels
            foreach ($Component in $LogLevels.Keys) {
                $Level = $LogLevels[$Component]
                $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
                
                Invoke-Command -ComputerName $DC -ScriptBlock {
                    param($Component, $Level)
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name $Component -Value $Level
                } -ArgumentList $Component, $Level
                
                Write-Host "  Set $Component logging to level $Level" -ForegroundColor Gray
            }
            
            # Configure security auditing
            $AuditPolicies = @(
                'Audit Account Logon Events',
                'Audit Account Management',
                'Audit Directory Service Access',
                'Audit Logon Events',
                'Audit Policy Change',
                'Audit Privilege Use',
                'Audit System Events'
            )
            
            foreach ($Policy in $AuditPolicies) {
                Invoke-Command -ComputerName $DC -ScriptBlock {
                    param($Policy)
                    auditpol /set /subcategory:$Policy /success:enable /failure:enable
                } -ArgumentList $Policy
            }
            
            # Configure event log sizes
            $EventLogs = @{
                'Security' = 1048576000  # 1GB
                'System' = 104857600     # 100MB
                'Application' = 104857600 # 100MB
                'Directory Service' = 524288000  # 500MB
            }
            
            foreach ($LogName in $EventLogs.Keys) {
                $MaxSize = $EventLogs[$LogName]
                Invoke-Command -ComputerName $DC -ScriptBlock {
                    param($LogName, $MaxSize)
                    $Log = Get-WinEvent -ListLog $LogName
                    $Log.MaximumSizeInBytes = $MaxSize
                    $Log.SaveChanges()
                } -ArgumentList $LogName, $MaxSize
            }
            
            # Configure log forwarding to SIEM if specified
            if ($SIEMServer) {
                $WinRMConfig = @"
winrm quickconfig -q
winrm set winrm/config/client '@{TrustedHosts="$SIEMServer"}'
wecutil qc /q
"@
                Invoke-Command -ComputerName $DC -ScriptBlock {
                    param($Config)
                    Invoke-Expression $Config
                } -ArgumentList $WinRMConfig
            }
            
            Write-Host "Logging configuration completed on $DC" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to configure logging on $DC`: $($_.Exception.Message)"
        }
    }
}

# Real-time log monitoring and alerting
function Start-ADLogMonitoring {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [string]$SIEMServer = $null,
        [hashtable]$CriticalEventIDs = @{
            1102 = 'Audit log cleared'
            4740 = 'Account locked out'
            4625 = 'Failed logon'
            4648 = 'Explicit credential logon'
            4719 = 'Audit policy changed'
            4713 = 'Kerberos policy changed'
        },
        [string]$AlertEmail = $null,
        [string]$SMTPServer = $null
    )
    
    foreach ($DC in $DomainControllers) {
        Start-Job -Name "LogMonitor-$DC" -ScriptBlock {
            param($DC, $CriticalEvents, $SIEMServer, $AlertEmail, $SMTPServer)
            
            # Register for real-time event monitoring
            $EventArgs = @{
                FilterHashtable = @{
                    LogName = 'Security', 'System', 'Directory Service'
                    ID = $CriticalEvents.Keys
                }
            }
            
            Register-WinEvent -FilterHashtable $EventArgs -Action {
                $Event = $Event.SourceEventArgs.NewEvent
                $EventData = [PSCustomObject]@{
                    Computer = $env:COMPUTERNAME
                    TimeCreated = $Event.TimeCreated
                    Id = $Event.Id
                    LevelDisplayName = $Event.LevelDisplayName
                    Message = $Event.Message
                    UserId = $Event.UserId
                    ProcessId = $Event.ProcessId
                }
                
                # Send to SIEM
                if ($SIEMServer) {
                    $SyslogMessage = "<14>$(Get-Date -Format 'MMM dd HH:mm:ss') $($EventData.Computer) AD-Monitor: $($EventData | ConvertTo-Json -Compress)"
                    $UdpClient = New-Object System.Net.Sockets.UdpClient
                    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($SyslogMessage)
                    $UdpClient.Send($Bytes, $Bytes.Length, $SIEMServer, 514)
                    $UdpClient.Close()
                }
                
                # Send email alert for critical events
                if ($AlertEmail -and $SMTPServer -and $Event.Id -in @(1102, 4740, 4719, 4713)) {
                    $Subject = "CRITICAL AD Event - $($CriticalEvents[$Event.Id]) on $($EventData.Computer)"
                    $Body = "Critical Active Directory event detected:`n`n"
                    $Body += "Event ID: $($Event.Id)`n"
                    $Body += "Event: $($CriticalEvents[$Event.Id])`n"
                    $Body += "Time: $($Event.TimeCreated)`n"
                    $Body += "Computer: $($EventData.Computer)`n"
                    $Body += "Details: $($Event.Message)`n"
                    
                    Send-MailMessage -To $AlertEmail -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Priority High
                }
                
                # Log to file
                $LogFile = "C:\Logs\ADCriticalEvents_$($EventData.Computer)_$(Get-Date -Format 'yyyyMMdd').log"
                "$($EventData.TimeCreated) - ID:$($EventData.Id) - $($CriticalEvents[$EventData.Id]) - $($EventData.UserId)" | Add-Content -Path $LogFile
            }
            
            # Keep the job running
            while ($true) {
                Start-Sleep -Seconds 60
            }
        } -ArgumentList $DC, $CriticalEventIDs, $SIEMServer, $AlertEmail, $SMTPServer
    }
    
    Write-Host "Real-time log monitoring started for $($DomainControllers.Count) domain controllers" -ForegroundColor Green
}
```

## Compliance and Reporting

### Compliance Auditing Framework

```powershell
# Generate comprehensive compliance audit report
function New-ADComplianceReport {
    param(
        [string[]]$DomainControllers = (Get-ADDomainController -Filter *).Name,
        [ValidateSet('SOX', 'HIPAA', 'PCI-DSS', 'NIST', 'Custom')]
        [string[]]$ComplianceFrameworks = @('SOX', 'NIST'),
        [datetime]$StartDate = (Get-Date).AddDays(-30),
        [datetime]$EndDate = (Get-Date),
        [string]$ReportPath = "C:\Reports\AD_ComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    $ComplianceData = @{
        'UserAccountManagement' = @()
        'PrivilegedAccess' = @()
        'AuthenticationEvents' = @()
        'PolicyChanges' = @()
        'SystemAccess' = @()
    }
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Collecting compliance data from $DC..." -ForegroundColor Blue
        
        try {
            # User Account Management Events
            $UserMgmtEvents = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4720, 4722, 4723, 4724, 4725, 4726, 4738, 4740, 4767
                StartTime = $StartDate
                EndTime = $EndDate
            } -ErrorAction SilentlyContinue
            
            foreach ($Event in $UserMgmtEvents) {
                $ComplianceData.UserAccountManagement += [PSCustomObject]@{
                    Timestamp = $Event.TimeCreated
                    Computer = $DC
                    EventID = $Event.Id
                    User = $Event.Properties[0].Value
                    Actor = $Event.Properties[4].Value
                    Action = switch ($Event.Id) {
                        4720 { 'Account Created' }
                        4722 { 'Account Enabled' }
                        4723 { 'Password Change Attempted' }
                        4724 { 'Password Reset' }
                        4725 { 'Account Disabled' }
                        4726 { 'Account Deleted' }
                        4738 { 'Account Changed' }
                        4740 { 'Account Locked' }
                        4767 { 'Account Unlocked' }
                    }
                }
            }
            
            # Privileged Access Events
            $PrivEvents = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4672, 4673, 4674, 4648
                StartTime = $StartDate
                EndTime = $EndDate
            } -ErrorAction SilentlyContinue
            
            foreach ($Event in $PrivEvents) {
                $ComplianceData.PrivilegedAccess += [PSCustomObject]@{
                    Timestamp = $Event.TimeCreated
                    Computer = $DC
                    EventID = $Event.Id
                    User = $Event.Properties[1].Value
                    Privileges = $Event.Properties[2].Value
                    Process = $Event.Properties[9].Value
                }
            }
            
            # Authentication Events
            $AuthEvents = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4624, 4625, 4634, 4647, 4768, 4769, 4771, 4776
                StartTime = $StartDate
                EndTime = $EndDate
            } -ErrorAction SilentlyContinue | Select-Object -First 1000
            
            foreach ($Event in $AuthEvents) {
                $ComplianceData.AuthenticationEvents += [PSCustomObject]@{
                    Timestamp = $Event.TimeCreated
                    Computer = $DC
                    EventID = $Event.Id
                    User = $Event.Properties[5].Value
                    LogonType = if ($Event.Properties.Count -gt 8) { $Event.Properties[8].Value } else { 'Unknown' }
                    SourceIP = if ($Event.Properties.Count -gt 18) { $Event.Properties[18].Value } else { 'Unknown' }
                    Result = if ($Event.Id -in @(4624, 4634, 4647, 4768, 4769, 4776)) { 'Success' } else { 'Failure' }
                }
            }
            
            # Policy Change Events
            $PolicyEvents = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                LogName = 'Security'
                ID = 4713, 4719, 4739, 4817
                StartTime = $StartDate
                EndTime = $EndDate
            } -ErrorAction SilentlyContinue
            
            foreach ($Event in $PolicyEvents) {
                $ComplianceData.PolicyChanges += [PSCustomObject]@{
                    Timestamp = $Event.TimeCreated
                    Computer = $DC
                    EventID = $Event.Id
                    Actor = $Event.Properties[1].Value
                    PolicyType = switch ($Event.Id) {
                        4713 { 'Kerberos Policy' }
                        4719 { 'Audit Policy' }
                        4739 { 'Domain Policy' }
                        4817 { 'Audit Settings' }
                    }
                    Changes = $Event.Message
                }
            }
        }
        catch {
            Write-Error "Failed to collect compliance data from $DC`: $($_.Exception.Message)"
        }
    }
    
    # Generate compliance report
    $TotalUserActions = $ComplianceData.UserAccountManagement.Count
    $TotalPrivilegedActions = $ComplianceData.PrivilegedAccess.Count
    $TotalAuthAttempts = $ComplianceData.AuthenticationEvents.Count
    $FailedAuthAttempts = ($ComplianceData.AuthenticationEvents | Where-Object { $_.Result -eq 'Failure' }).Count
    $PolicyChanges = $ComplianceData.PolicyChanges.Count
    
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Compliance Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { background-color: #d4edda; }
        .failure { background-color: #f8d7da; }
        .warning { background-color: #fff3cd; }
        .header { background-color: #6f42c1; color: white; padding: 10px; }
        .summary { background-color: #f8f9fa; padding: 15px; margin-bottom: 20px; }
        .framework { background-color: #e3f2fd; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Compliance Audit Report</h1>
        <p>Audit Period: $StartDate to $EndDate</p>
        <p>Compliance Frameworks: $($ComplianceFrameworks -join ', ')</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <p><strong>User Account Management Actions:</strong> $TotalUserActions</p>
        <p><strong>Privileged Access Events:</strong> $TotalPrivilegedActions</p>
        <p><strong>Authentication Attempts:</strong> $TotalAuthAttempts</p>
        <p><strong>Failed Authentication Attempts:</strong> $FailedAuthAttempts</p>
        <p><strong>Policy Changes:</strong> $PolicyChanges</p>
        <p><strong>Domain Controllers Audited:</strong> $($DomainControllers.Count)</p>
    </div>
"@
    
    # Add framework-specific sections
    foreach ($Framework in $ComplianceFrameworks) {
        $Html += @"
    <div class="framework">
        <h3>$Framework Compliance Requirements</h3>
        <ul>
"@
        
        switch ($Framework) {
            'SOX' {
                $Html += @"
            <li>User access management and review (Covered: User Account Management)</li>
            <li>Privileged access controls (Covered: Privileged Access Events)</li>
            <li>Authentication and authorization logging (Covered: Authentication Events)</li>
            <li>System changes and configuration management (Covered: Policy Changes)</li>
"@
            }
            'HIPAA' {
                $Html += @"
            <li>Access control and user authentication (Covered: Authentication Events)</li>
            <li>Audit controls and logging (Covered: All Event Categories)</li>
            <li>Information access management (Covered: Privileged Access Events)</li>
            <li>Transmission security (Covered: System Access Events)</li>
"@
            }
            'NIST' {
                $Html += @"
            <li>Access Control (AC) - User management and privileged access</li>
            <li>Audit and Accountability (AU) - Comprehensive event logging</li>
            <li>Identification and Authentication (IA) - Authentication events</li>
            <li>Configuration Management (CM) - Policy change tracking</li>
"@
            }
        }
        
        $Html += @"
        </ul>
    </div>
"@
    }
    
    # Add detailed event tables
    if ($ComplianceData.UserAccountManagement.Count -gt 0) {
        $Html += @"
    <h2>User Account Management Events</h2>
    <table>
        <tr>
            <th>Timestamp</th>
            <th>Domain Controller</th>
            <th>Action</th>
            <th>Target User</th>
            <th>Actor</th>
        </tr>
"@
        
        foreach ($Event in ($ComplianceData.UserAccountManagement | Sort-Object Timestamp -Descending | Select-Object -First 100)) {
            $Html += @"
        <tr>
            <td>$($Event.Timestamp)</td>
            <td>$($Event.Computer)</td>
            <td>$($Event.Action)</td>
            <td>$($Event.User)</td>
            <td>$($Event.Actor)</td>
        </tr>
"@
        }
        
        $Html += "</table>"
    }
    
    if ($ComplianceData.PolicyChanges.Count -gt 0) {
        $Html += @"
    <h2>Policy Changes</h2>
    <table>
        <tr>
            <th>Timestamp</th>
            <th>Domain Controller</th>
            <th>Policy Type</th>
            <th>Actor</th>
        </tr>
"@
        
        foreach ($Event in $ComplianceData.PolicyChanges) {
            $Html += @"
        <tr class="warning">
            <td>$($Event.Timestamp)</td>
            <td>$($Event.Computer)</td>
            <td>$($Event.PolicyType)</td>
            <td>$($Event.Actor)</td>
        </tr>
"@
        }
        
        $Html += "</table>"
    }
    
    $Html += @"
</body>
</html>
"@
    
    $Html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Compliance audit report generated: $ReportPath" -ForegroundColor Green
    
    return $ComplianceData
}
```

## Cloud and Hybrid Monitoring

### Azure AD Connect Health Monitoring

```powershell
# Monitor hybrid environment health
function Monitor-HybridADHealth {
    param(
        [string]$AADConnectServer,
        [string]$TenantId,
        [string]$SubscriptionId,
        [string]$ReportPath = "C:\Reports\Hybrid_AD_Health_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    $HybridHealth = @()
    
    # Check Azure AD Connect status
    if ($AADConnectServer) {
        try {
            $ConnectStatus = Invoke-Command -ComputerName $AADConnectServer -ScriptBlock {
                Import-Module ADSync
                
                $SyncCycles = Get-ADSyncScheduler
                $LastSync = Get-ADSyncRunHistoryCount | Select-Object -First 1
                $ConnectorSpaces = Get-ADSyncConnectorStatistics
                
                [PSCustomObject]@{
                    SchedulerEnabled = $SyncCycles.SyncCycleEnabled
                    NextSyncCycle = $SyncCycles.NextSyncCyclePolicyType
                    LastSyncTime = $LastSync.StartDate
                    LastSyncResult = $LastSync.Result
                    ConnectorCount = $ConnectorSpaces.Count
                }
            }
            
            $HybridHealth += [PSCustomObject]@{
                Component = 'Azure AD Connect'
                Status = if ($ConnectStatus.SchedulerEnabled) { 'Healthy' } else { 'Issue' }
                LastSync = $ConnectStatus.LastSyncTime
                Details = "Scheduler: $($ConnectStatus.SchedulerEnabled), Result: $($ConnectStatus.LastSyncResult)"
            }
        }
        catch {
            $HybridHealth += [PSCustomObject]@{
                Component = 'Azure AD Connect'
                Status = 'Error'
                LastSync = 'Unknown'
                Details = "Error: $($_.Exception.Message)"
            }
        }
    }
    
    # Check password writeback (if configured)
    try {
        $PWWriteback = Get-ADSyncAADPasswordResetConfiguration -ErrorAction SilentlyContinue
        if ($PWWriteback) {
            $HybridHealth += [PSCustomObject]@{
                Component = 'Password Writeback'
                Status = if ($PWWriteback.PasswordWritebackEnabled) { 'Enabled' } else { 'Disabled' }
                LastSync = 'N/A'
                Details = "Enabled: $($PWWriteback.PasswordWritebackEnabled)"
            }
        }
    }
    catch {
        Write-Warning "Could not check password writeback status"
    }
    
    # Generate hybrid health report
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Hybrid Active Directory Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { background-color: #d4edda; }
        .issue { background-color: #f8d7da; }
        .enabled { background-color: #d4edda; }
        .disabled { background-color: #fff3cd; }
        .header { background-color: #17a2b8; color: white; padding: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Hybrid Active Directory Health Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Tenant ID: $TenantId</p>
    </div>
    
    <h2>Hybrid Components Status</h2>
    <table>
        <tr>
            <th>Component</th>
            <th>Status</th>
            <th>Last Sync</th>
            <th>Details</th>
        </tr>
"@
    
    foreach ($Component in $HybridHealth) {
        $StatusClass = $Component.Status.ToLower()
        $Html += @"
        <tr class="$StatusClass">
            <td>$($Component.Component)</td>
            <td>$($Component.Status)</td>
            <td>$($Component.LastSync)</td>
            <td>$($Component.Details)</td>
        </tr>
"@
    }
    
    $Html += @"
    </table>
</body>
</html>
"@
    
    $Html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Hybrid health report generated: $ReportPath" -ForegroundColor Green
    
    return $HybridHealth
}
```

## Best Practices and Recommendations

### Monitoring Best Practices

1. **Baseline Establishment**: Establish performance baselines during normal operations
2. **Threshold Setting**: Set appropriate alerting thresholds based on baseline data
3. **Alert Tuning**: Regularly review and tune alerts to minimize false positives
4. **Escalation Procedures**: Implement clear escalation paths for different severity levels
5. **Documentation**: Maintain up-to-date monitoring documentation and procedures

### Security Monitoring

1. **Real-time Alerting**: Implement real-time alerting for critical security events
2. **Threat Correlation**: Use SIEM solutions for advanced threat detection and correlation
3. **Behavioral Analysis**: Monitor for unusual patterns and behaviors
4. **Compliance Auditing**: Regular compliance audits and reporting
5. **Incident Response**: Integrate monitoring with incident response procedures

### Performance Optimization

1. **Minimize Monitoring Overhead**: Balance monitoring completeness with performance impact
2. **Efficient Data Collection**: Use sampling and aggregation to reduce data volume
3. **Storage Management**: Implement appropriate log retention and archival policies
4. **Network Impact**: Consider bandwidth usage for centralized monitoring
5. **Regular Review**: Periodically review monitoring strategy and adjust as needed

## Additional Resources

### Microsoft Documentation

- [Monitor and troubleshoot AD DS](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/monitor-ad-ds)
- [Active Directory Replication and Topology Management](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/replication)
- [Security Monitoring for Active Directory](https://docs.microsoft.com/en-us/windows-server/identity/securing-privileged-access/reference-tools-logon-types)

### Security Frameworks

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/index.md)
- [SANS Active Directory Security](https://www.sans.org/white-papers/1966/index.md)

### Monitoring Tools

- [System Center Operations Manager (SCOM)](https://docs.microsoft.com/en-us/system-center/scom/index.md)
- [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/index.md)
- [Splunk for Active Directory](https://splunkbase.splunk.com/app/1151/index.md)

---

*This guide provides comprehensive monitoring and logging strategies for Active Directory environments. Regular review and updates ensure continued effectiveness and security.*
