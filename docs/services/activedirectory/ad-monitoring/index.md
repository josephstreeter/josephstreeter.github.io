---
title: Active Directory Monitoring
description: Comprehensive guide to monitoring Active Directory infrastructure, performance metrics, security events, and automated alerting systems
author: Joseph Streeter
date: 2024-01-15
tags: [active-directory, monitoring, security, performance, alerts, powershell, scom]
---

Active Directory monitoring is essential for maintaining a healthy, secure, and performant enterprise infrastructure. This guide covers comprehensive monitoring strategies, tools, and automated alerting systems for Active Directory environments.

## AD Monitoring Fundamentals

### Critical Components to Monitor

#### Domain Controllers

- **System Resources**: CPU, memory, disk I/O, network utilization
- **AD Services**: NTDS, DNS, Kerberos, LDAP, Global Catalog
- **Replication Health**: Replication topology, latency, failures
- **Authentication Performance**: Logon response times, Kerberos ticket processing

#### Active Directory Database

- **Database Size**: NTDS.dit growth trends and space utilization
- **Database Performance**: Read/write operations, search performance
- **Transaction Log**: Log file growth, checkpoint operations
- **Defragmentation**: Online and offline defragmentation status

#### Network and Connectivity

- **Site Topology**: Inter-site replication links and schedules
- **DNS Health**: DNS server responsiveness, zone transfers
- **Time Synchronization**: NTP accuracy across domain controllers
- **Network Latency**: Response times between sites and DCs

```text
┌─────────────────────────────────────────────────────────────────┐
│                AD Monitoring Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│  Monitoring Layer    │ Components                               │
│  ├─ Infrastructure   │ CPU, Memory, Disk, Network              │
│  ├─ Services         │ NTDS, DNS, KDC, Global Catalog          │
│  ├─ Applications     │ Authentication, Replication, LDAP       │
│  ├─ Security         │ Event Logs, Audit Policies, Threats     │
│  └─ Business         │ User Experience, Service Availability   │
└─────────────────────────────────────────────────────────────────┘
```

## PowerShell-Based Monitoring

### Domain Controller Health Check Script

```powershell
<#
.SYNOPSIS
    Comprehensive Active Directory domain controller health check.
.DESCRIPTION
    Performs detailed health assessment of domain controllers including
    services, replication, performance counters, and security events.
.EXAMPLE
    .\AD-HealthCheck.ps1 -DomainController "DC01" -GenerateReport
.NOTES
    Requires Active Directory PowerShell module and appropriate permissions.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$DomainController = @(),
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [string]$ReportPath = "C:\Reports\AD-Health"
)

# Import required modules
Import-Module ActiveDirectory -ErrorAction Stop

function Test-DomainControllerServices
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    $CriticalServices = @(
        'NTDS',          # Active Directory Domain Services
        'DNS',           # DNS Server
        'Kdc',           # Kerberos Key Distribution Center
        'ADWS',          # Active Directory Web Services
        'Netlogon',      # Net Logon
        'W32Time'        # Windows Time
    )
    
    $ServiceStatus = @{}
    
    foreach ($Service in $CriticalServices)
    {
        try
        {
            $ServiceInfo = Get-Service -Name $Service -ComputerName $ComputerName -ErrorAction Stop
            $ServiceStatus[$Service] = @{
                Status = $ServiceInfo.Status
                StartType = $ServiceInfo.StartType
                Healthy = ($ServiceInfo.Status -eq 'Running')
            }
        }
        catch
        {
            $ServiceStatus[$Service] = @{
                Status = 'Unknown'
                StartType = 'Unknown'
                Healthy = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return $ServiceStatus
}

function Test-ADReplication
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainController
    )
    
    try
    {
        # Get replication summary
        $ReplSummary = Get-ADReplicationUpToDatenessVectorTable -Target $DomainController
        
        # Get replication failures
        $ReplFailures = Get-ADReplicationFailure -Target $DomainController
        
        # Get replication partner metadata
        $ReplPartners = Get-ADReplicationPartnerMetadata -Target $DomainController
        
        $ReplicationHealth = @{
            Summary = $ReplSummary
            Failures = $ReplFailures
            Partners = $ReplPartners
            FailureCount = $ReplFailures.Count
            Healthy = ($ReplFailures.Count -eq 0)
            LastSuccessfulSync = ($ReplPartners | Measure-Object -Property LastReplicationSuccess -Maximum).Maximum
        }
        
        return $ReplicationHealth
    }
    catch
    {
        return @{
            Healthy = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ADPerformanceCounters
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    $PerformanceCounters = @(
        '\NTDS\LDAP Searches/sec',
        '\NTDS\LDAP Successful Binds/sec',
        '\NTDS\DRA Pending Replication Synchronizations',
        '\NTDS\DS Directory Reads/sec',
        '\NTDS\DS Directory Writes/sec',
        '\NTDS\Database >> instances(lsass/NTDSA)\I/O Database Reads Average Latency',
        '\NTDS\Database >> instances(lsass/NTDSA)\I/O Database Writes Average Latency',
        '\Memory\Available MBytes',
        '\Processor(_Total)\% Processor Time',
        '\LogicalDisk(C:)\% Free Space'
    )
    
    $CounterData = @{}
    
    foreach ($Counter in $PerformanceCounters)
    {
        try
        {
            $CounterValue = (Get-Counter -Counter $Counter -ComputerName $ComputerName -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average
            $CounterData[$Counter] = [math]::Round($CounterValue.Average, 2)
        }
        catch
        {
            $CounterData[$Counter] = "Error: $($_.Exception.Message)"
        }
    }
    
    return $CounterData
}

function Get-ADSecurityEvents
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter()]
        [int]$Hours = 24
    )
    
    $StartTime = (Get-Date).AddHours(-$Hours)
    $SecurityEvents = @{}
    
    # Critical security event IDs to monitor
    $CriticalEventIDs = @{
        4625 = 'Failed Logon Attempts'
        4740 = 'Account Lockouts'
        4771 = 'Kerberos Pre-authentication Failed'
        4648 = 'Logon with Explicit Credentials'
        4720 = 'User Account Created'
        4726 = 'User Account Deleted'
        4728 = 'User Added to Security Group'
        4732 = 'User Added to Local Group'
        4756 = 'User Added to Universal Group'
    }
    
    foreach ($EventID in $CriticalEventIDs.Keys)
    {
        try
        {
            $Events = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = $EventID
                StartTime = $StartTime
            } -ComputerName $ComputerName -ErrorAction SilentlyContinue
            
            $SecurityEvents[$EventID] = @{
                Description = $CriticalEventIDs[$EventID]
                Count = $Events.Count
                RecentEvents = $Events | Select-Object -First 10 | Select-Object TimeCreated, Id, LevelDisplayName, Message
            }
        }
        catch
        {
            $SecurityEvents[$EventID] = @{
                Description = $CriticalEventIDs[$EventID]
                Count = 0
                Error = $_.Exception.Message
            }
        }
    }
    
    return $SecurityEvents
}

function Get-ADDatabaseInfo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    try
    {
        # Get NTDS database file information
        $NTDSPath = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $NTDSInfo = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "DSA Database file"
            return $NTDSInfo."DSA Database file"
        }
        
        $DatabaseFile = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($Path)
            if (Test-Path $Path)
            {
                $FileInfo = Get-Item $Path
                return @{
                    Size = $FileInfo.Length
                    SizeGB = [math]::Round($FileInfo.Length / 1GB, 2)
                    LastWriteTime = $FileInfo.LastWriteTime
                    CreationTime = $FileInfo.CreationTime
                }
            }
            else
            {
                return $null
            }
        } -ArgumentList $NTDSPath
        
        # Get log file information
        $LogPath = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $LogInfo = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Database log files path"
            return $LogInfo."Database log files path"
        }
        
        $LogFiles = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($Path)
            if (Test-Path $Path)
            {
                $Logs = Get-ChildItem -Path $Path -Filter "*.log"
                $TotalSize = ($Logs | Measure-Object -Property Length -Sum).Sum
                return @{
                    Count = $Logs.Count
                    TotalSize = $TotalSize
                    TotalSizeGB = [math]::Round($TotalSize / 1GB, 2)
                }
            }
            else
            {
                return $null
            }
        } -ArgumentList $LogPath
        
        return @{
            DatabasePath = $NTDSPath
            DatabaseInfo = $DatabaseFile
            LogPath = $LogPath
            LogInfo = $LogFiles
        }
    }
    catch
    {
        return @{
            Error = $_.Exception.Message
        }
    }
}

# Main execution
function Start-ADHealthCheck
{
    $Results = @{}
    
    # Get all domain controllers if none specified
    if ($DomainController.Count -eq 0)
    {
        try
        {
            $DomainController = (Get-ADDomainController -Filter *).Name
        }
        catch
        {
            Write-Error "Failed to retrieve domain controllers: $($_.Exception.Message)"
            return
        }
    }
    
    foreach ($DC in $DomainController)
    {
        Write-Host "Checking domain controller: $DC" -ForegroundColor Green
        
        $DCHealth = @{
            DomainController = $DC
            Timestamp = Get-Date
            Services = Test-DomainControllerServices -ComputerName $DC
            Replication = Test-ADReplication -DomainController $DC
            Performance = Get-ADPerformanceCounters -ComputerName $DC
            SecurityEvents = Get-ADSecurityEvents -ComputerName $DC
            Database = Get-ADDatabaseInfo -ComputerName $DC
        }
        
        # Calculate overall health score
        $HealthScore = 0
        $TotalChecks = 0
        
        # Service health (40% weight)
        $ServiceHealthy = ($DCHealth.Services.Values | Where-Object {$_.Healthy}).Count
        $ServiceTotal = $DCHealth.Services.Count
        $ServiceScore = ($ServiceHealthy / $ServiceTotal) * 40
        $HealthScore += $ServiceScore
        
        # Replication health (30% weight)
        if ($DCHealth.Replication.Healthy)
        {
            $HealthScore += 30
        }
        
        # Performance thresholds (30% weight)
        $PerfScore = 30
        if ($DCHealth.Performance['\Processor(_Total)\% Processor Time'] -gt 80) { $PerfScore -= 10 }
        if ($DCHealth.Performance['\Memory\Available MBytes'] -lt 512) { $PerfScore -= 10 }
        if ($DCHealth.Performance['\LogicalDisk(C:)\% Free Space'] -lt 20) { $PerfScore -= 10 }
        $HealthScore += $PerfScore
        
        $DCHealth.OverallHealthScore = [math]::Round($HealthScore, 1)
        $DCHealth.HealthStatus = switch ($HealthScore)
        {
            {$_ -ge 90} { "Excellent" }
            {$_ -ge 75} { "Good" }
            {$_ -ge 60} { "Warning" }
            default { "Critical" }
        }
        
        $Results[$DC] = $DCHealth
        
        Write-Host "Health Score: $($DCHealth.OverallHealthScore)% - $($DCHealth.HealthStatus)" -ForegroundColor $(
            switch ($DCHealth.HealthStatus)
            {
                "Excellent" { "Green" }
                "Good" { "Yellow" }
                "Warning" { "Yellow" }
                "Critical" { "Red" }
            }
        )
    }
    
    if ($GenerateReport)
    {
        New-Item -ItemType Directory -Path $ReportPath -Force -ErrorAction SilentlyContinue
        $ReportFile = Join-Path $ReportPath "AD-HealthCheck-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8
        Write-Host "Report saved to: $ReportFile" -ForegroundColor Green
    }
    
    return $Results
}

# Execute health check
$HealthCheckResults = Start-ADHealthCheck

# Display summary
Write-Host "`n=== Active Directory Health Check Summary ===" -ForegroundColor Cyan
foreach ($DC in $HealthCheckResults.Keys)
{
    $Result = $HealthCheckResults[$DC]
    Write-Host "$DC : $($Result.HealthStatus) ($($Result.OverallHealthScore)%)" -ForegroundColor $(
        switch ($Result.HealthStatus)
        {
            "Excellent" { "Green" }
            "Good" { "Yellow" }
            "Warning" { "Yellow" }
            "Critical" { "Red" }
        }
    )
}
```

### Automated Replication Monitoring

```powershell
<#
.SYNOPSIS
    Monitor Active Directory replication across all domain controllers.
.DESCRIPTION
    Comprehensive replication monitoring with automated alerting and reporting.
#>

function Monitor-ADReplication
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$EmailRecipient = "admin@company.com",
        
        [Parameter()]
        [string]$SMTPServer = "smtp.company.com",
        
        [Parameter()]
        [int]$AlertThresholdMinutes = 60
    )
    
    # Get all domain controllers
    $DomainControllers = Get-ADDomainController -Filter *
    $ReplicationIssues = @()
    
    foreach ($DC in $DomainControllers)
    {
        Write-Host "Checking replication for: $($DC.Name)" -ForegroundColor Green
        
        try
        {
            # Check replication failures
            $ReplFailures = Get-ADReplicationFailure -Target $DC.Name
            
            if ($ReplFailures.Count -gt 0)
            {
                $ReplicationIssues += [PSCustomObject]@{
                    DomainController = $DC.Name
                    IssueType = "Replication Failure"
                    Details = $ReplFailures
                    Severity = "High"
                }
            }
            
            # Check replication partner metadata
            $ReplPartners = Get-ADReplicationPartnerMetadata -Target $DC.Name
            
            foreach ($Partner in $ReplPartners)
            {
                $TimeSinceLastRepl = (Get-Date) - $Partner.LastReplicationSuccess
                
                if ($TimeSinceLastRepl.TotalMinutes -gt $AlertThresholdMinutes)
                {
                    $ReplicationIssues += [PSCustomObject]@{
                        DomainController = $DC.Name
                        PartnerDC = $Partner.Partner
                        IssueType = "Replication Delay"
                        TimeSinceLastSuccess = $TimeSinceLastRepl
                        Severity = if ($TimeSinceLastRepl.TotalHours -gt 4) { "High" } else { "Medium" }
                    }
                }
            }
            
            # Check for lingering objects
            $LingeringObjects = Get-ADReplicationUpToDatenessVectorTable -Target $DC.Name | 
                Where-Object { $_.UsnFilter -lt $_.HighestCommittedUsn }
            
            if ($LingeringObjects)
            {
                $ReplicationIssues += [PSCustomObject]@{
                    DomainController = $DC.Name
                    IssueType = "Potential Lingering Objects"
                    Details = $LingeringObjects
                    Severity = "Medium"
                }
            }
        }
        catch
        {
            $ReplicationIssues += [PSCustomObject]@{
                DomainController = $DC.Name
                IssueType = "Monitoring Error"
                Details = $_.Exception.Message
                Severity = "High"
            }
        }
    }
    
    # Generate report
    if ($ReplicationIssues.Count -gt 0)
    {
        $ReportHTML = @"
<html>
<head>
    <title>Active Directory Replication Issues Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { background-color: #ffcccc; }
        .medium { background-color: #ffffcc; }
        .low { background-color: #ccffcc; }
    </style>
</head>
<body>
    <h1>Active Directory Replication Issues</h1>
    <p>Report generated: $(Get-Date)</p>
    <p>Total issues found: $($ReplicationIssues.Count)</p>
    
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>Issue Type</th>
            <th>Severity</th>
            <th>Details</th>
        </tr>
"@
        
        foreach ($Issue in $ReplicationIssues)
        {
            $RowClass = switch ($Issue.Severity)
            {
                "High" { "high" }
                "Medium" { "medium" }
                "Low" { "low" }
            }
            
            $ReportHTML += @"
        <tr class="$RowClass">
            <td>$($Issue.DomainController)</td>
            <td>$($Issue.IssueType)</td>
            <td>$($Issue.Severity)</td>
            <td>$($Issue.Details -join '; ')</td>
        </tr>
"@
        }
        
        $ReportHTML += @"
    </table>
</body>
</html>
"@
        
        # Send email alert
        $EmailParams = @{
            From = "ad-monitoring@company.com"
            To = $EmailRecipient
            Subject = "AD Replication Issues Detected - $($ReplicationIssues.Count) Issues"
            Body = $ReportHTML
            BodyAsHtml = $true
            SmtpServer = $SMTPServer
        }
        
        Send-MailMessage @EmailParams
        Write-Host "Alert email sent to: $EmailRecipient" -ForegroundColor Yellow
    }
    else
    {
        Write-Host "No replication issues detected!" -ForegroundColor Green
    }
    
    return $ReplicationIssues
}
```

## SCOM Integration

### Active Directory Management Pack Configuration

```powershell
# SCOM PowerShell script for AD monitoring configuration
Import-Module OperationsManager

# Configure AD Domain Controller monitoring
$ADDCClass = Get-SCOMClass -Name "Microsoft.Windows.Computer" | Where-Object {$_.DisplayName -eq "Windows Computer"}

# Create monitoring rules for critical AD services
$MonitoringRules = @(
    @{
        Name = "NTDS Service Monitor"
        Service = "NTDS"
        AlertOnStop = $true
        Description = "Monitors the Active Directory Domain Services service"
    },
    @{
        Name = "DNS Service Monitor" 
        Service = "DNS"
        AlertOnStop = $true
        Description = "Monitors the DNS Server service on domain controllers"
    },
    @{
        Name = "KDC Service Monitor"
        Service = "Kdc"
        AlertOnStop = $true
        Description = "Monitors the Kerberos Key Distribution Center service"
    }
)

foreach ($Rule in $MonitoringRules)
{
    # Create service monitor
    $Monitor = New-SCOMMonitor -Name $Rule.Name -Description $Rule.Description -Class $ADDCClass
    # Additional configuration would be added here for service-specific monitoring
}

# Configure performance counter monitoring
$PerformanceCounters = @(
    @{
        Counter = "NTDS\LDAP Searches/sec"
        Threshold = 1000
        AlertOnExceed = $true
    },
    @{
        Counter = "NTDS\DRA Pending Replication Synchronizations"
        Threshold = 10
        AlertOnExceed = $true
    }
)

foreach ($Counter in $PerformanceCounters)
{
    # Configure performance counter rules
    Write-Host "Configuring monitoring for: $($Counter.Counter)"
}
```

## Event Log Monitoring

### Critical AD Events to Monitor

```powershell
# Event monitoring configuration
$CriticalADEvents = @{
    # Authentication Events
    4625 = @{
        LogName = "Security"
        Description = "Failed Logon Attempts"
        Threshold = 50  # Alert if more than 50 in 1 hour
        Action = "Alert"
    }
    
    4740 = @{
        LogName = "Security"
        Description = "Account Lockouts"
        Threshold = 5   # Alert if more than 5 in 1 hour
        Action = "Alert"
    }
    
    4771 = @{
        LogName = "Security"
        Description = "Kerberos Pre-authentication Failed"
        Threshold = 25  # Alert if more than 25 in 1 hour
        Action = "Alert"
    }
    
    # Directory Service Events
    1655 = @{
        LogName = "Directory Service"
        Description = "Communication with Global Catalog Failed"
        Threshold = 1
        Action = "Immediate Alert"
    }
    
    2887 = @{
        LogName = "Directory Service"
        Description = "Replication Latency Warning"
        Threshold = 5
        Action = "Alert"
    }
    
    # DNS Events
    4013 = @{
        LogName = "DNS Server"
        Description = "DNS Server Failed to Load Zone"
        Threshold = 1
        Action = "Immediate Alert"
    }
    
    # System Events
    6005 = @{
        LogName = "System"
        Description = "Event Log Service Started"
        Threshold = 3   # Alert if system restarts more than 3 times per day
        Action = "Monitor"
    }
    
    6006 = @{
        LogName = "System"
        Description = "Event Log Service Stopped"
        Threshold = 3
        Action = "Monitor"
    }
}

function New-ADEventSubscription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$EventConfig,
        
        [Parameter(Mandatory)]
        [string[]]$DomainControllers
    )
    
    foreach ($DC in $DomainControllers)
    {
        foreach ($EventID in $EventConfig.Keys)
        {
            $Event = $EventConfig[$EventID]
            
            # Create scheduled task for event monitoring
            $TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument @"
-Command "& {
    `$Events = Get-WinEvent -FilterHashtable @{LogName='$($Event.LogName)'; ID=$EventID; StartTime=(Get-Date).AddHours(-1)} -ComputerName $DC -ErrorAction SilentlyContinue
    if (`$Events.Count -gt $($Event.Threshold)) {
        Send-MailMessage -From 'ad-monitoring@company.com' -To 'admin@company.com' -Subject 'AD Alert: $($Event.Description) on $DC' -Body 'Threshold exceeded: `$(`$Events.Count) events in last hour' -SmtpServer 'smtp.company.com'
    }
}"
"@
            
            $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 15)
            
            $TaskName = "AD-Monitor-$EventID-$DC"
            Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Description "Monitor Event ID $EventID on $DC"
        }
    }
}
```

## Performance Baseline and Trending

### Performance Data Collection

```powershell
function Start-ADPerformanceCollection
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DomainControllers,
        
        [Parameter()]
        [int]$CollectionIntervalMinutes = 15,
        
        [Parameter()]
        [string]$DatabaseConnectionString = "Server=SQLSERVER;Database=ADMonitoring;Integrated Security=true"
    )
    
    $PerformanceCounters = @(
        '\NTDS\LDAP Client Sessions',
        '\NTDS\LDAP Active Threads',
        '\NTDS\LDAP Searches/sec',
        '\NTDS\LDAP Successful Binds/sec',
        '\NTDS\LDAP Writes/sec',
        '\NTDS\DRA Inbound Values (DNs only)/sec',
        '\NTDS\DRA Outbound Values (DNs only)/sec',
        '\NTDS\DRA Pending Replication Synchronizations',
        '\NTDS\DS Directory Reads/sec',
        '\NTDS\DS Directory Writes/sec',
        '\NTDS\DS Search sub-operations/sec',
        '\NTDS\Database >> Cache % Hit',
        '\NTDS\Database >> Cache Size (MB)',
        '\Memory\Available MBytes',
        '\Memory\Page Faults/sec',
        '\Processor(_Total)\% Processor Time',
        '\LogicalDisk(C:)\% Free Space',
        '\LogicalDisk(C:)\Avg. Disk Queue Length',
        '\Network Interface(*)\Bytes Total/sec'
    )
    
    while ($true)
    {
        foreach ($DC in $DomainControllers)
        {
            $Timestamp = Get-Date
            $CounterData = @{}
            
            foreach ($Counter in $PerformanceCounters)
            {
                try
                {
                    $CounterValue = (Get-Counter -Counter $Counter -ComputerName $DC -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average
                    $CounterData[$Counter] = [math]::Round($CounterValue.Average, 2)
                }
                catch
                {
                    Write-Warning "Failed to collect counter $Counter from $DC : $($_.Exception.Message)"
                    $CounterData[$Counter] = $null
                }
            }
            
            # Store data in database
            try
            {
                $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($DatabaseConnectionString)
                $SqlConnection.Open()
                
                foreach ($Counter in $CounterData.Keys)
                {
                    if ($CounterData[$Counter] -ne $null)
                    {
                        $SqlCommand = $SqlConnection.CreateCommand()
                        $SqlCommand.CommandText = @"
INSERT INTO PerformanceData (Timestamp, DomainController, CounterName, CounterValue)
VALUES (@Timestamp, @DomainController, @CounterName, @CounterValue)
"@
                        $SqlCommand.Parameters.AddWithValue("@Timestamp", $Timestamp) | Out-Null
                        $SqlCommand.Parameters.AddWithValue("@DomainController", $DC) | Out-Null
                        $SqlCommand.Parameters.AddWithValue("@CounterName", $Counter) | Out-Null
                        $SqlCommand.Parameters.AddWithValue("@CounterValue", $CounterData[$Counter]) | Out-Null
                        
                        $SqlCommand.ExecuteNonQuery() | Out-Null
                    }
                }
                
                $SqlConnection.Close()
            }
            catch
            {
                Write-Error "Failed to store performance data: $($_.Exception.Message)"
            }
        }
        
        Write-Host "Performance data collected at $(Get-Date)" -ForegroundColor Green
        Start-Sleep -Seconds ($CollectionIntervalMinutes * 60)
    }
}
```

## Automated Alerting and Reporting

### Daily Health Report

```powershell
function New-ADDailyHealthReport
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Recipients = @("admin@company.com"),
        
        [Parameter()]
        [string]$SMTPServer = "smtp.company.com"
    )
    
    $ReportDate = Get-Date
    $Yesterday = $ReportDate.AddDays(-1)
    
    # Collect health data
    $DomainControllers = Get-ADDomainController -Filter *
    $HealthSummary = @()
    
    foreach ($DC in $DomainControllers)
    {
        $DCHealth = @{
            Name = $DC.Name
            Site = $DC.Site
            OperatingSystem = $DC.OperatingSystem
            Services = Test-DomainControllerServices -ComputerName $DC.Name
            Replication = Test-ADReplication -DomainController $DC.Name
            SecurityEvents = Get-ADSecurityEvents -ComputerName $DC.Name -Hours 24
        }
        
        $HealthSummary += $DCHealth
    }
    
    # Generate HTML report
    $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Daily Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 10px; text-align: center; }
        .summary { background-color: #f9f9f9; padding: 15px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { color: green; }
        .warning { color: orange; }
        .critical { color: red; }
        .chart { margin: 20px 0; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Health Report</h1>
        <p>Report Date: $($ReportDate.ToString('yyyy-MM-dd HH:mm'))</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <ul>
            <li>Total Domain Controllers: $($DomainControllers.Count)</li>
            <li>Healthy DCs: $($HealthSummary | Where-Object {$_.Replication.Healthy}).Count</li>
            <li>DCs with Issues: $($HealthSummary | Where-Object {!$_.Replication.Healthy}).Count</li>
        </ul>
    </div>
    
    <h2>Domain Controller Status</h2>
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>Site</th>
            <th>OS</th>
            <th>Services</th>
            <th>Replication</th>
            <th>Security Events</th>
        </tr>
"@
    
    foreach ($DC in $HealthSummary)
    {
        $ServiceStatus = if (($DC.Services.Values | Where-Object {$_.Healthy}).Count -eq $DC.Services.Count) { "healthy" } else { "critical" }
        $ReplStatus = if ($DC.Replication.Healthy) { "healthy" } else { "critical" }
        $SecurityStatus = if (($DC.SecurityEvents.Values | Where-Object {$_.Count -gt 10}).Count -eq 0) { "healthy" } else { "warning" }
        
        $ReportHTML += @"
        <tr>
            <td>$($DC.Name)</td>
            <td>$($DC.Site)</td>
            <td>$($DC.OperatingSystem)</td>
            <td class="$ServiceStatus">$ServiceStatus</td>
            <td class="$ReplStatus">$ReplStatus</td>
            <td class="$SecurityStatus">$SecurityStatus</td>
        </tr>
"@
    }
    
    $ReportHTML += @"
    </table>
    
    <p><em>Report generated by AD Monitoring System</em></p>
</body>
</html>
"@
    
    # Send email report
    foreach ($Recipient in $Recipients)
    {
        Send-MailMessage -From "ad-monitoring@company.com" -To $Recipient -Subject "AD Daily Health Report - $($ReportDate.ToString('yyyy-MM-dd'))" -Body $ReportHTML -BodyAsHtml -SmtpServer $SMTPServer
    }
    
    Write-Host "Daily health report sent to: $($Recipients -join ', ')" -ForegroundColor Green
}
```

## Related Topics

- [Active Directory Security](~/docs/services/activedirectory/Security/index.md)
- [Group Policy Management](~/docs/services/activedirectory/GroupPolicy/index.md)
- [Domain Controllers](~/docs/services/activedirectory/DomainControllers/index.md)
- [Infrastructure Monitoring](~/docs/infrastructure/monitoring/index.md)

## Topics

Add topics here.
