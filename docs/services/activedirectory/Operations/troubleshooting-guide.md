---
title: "Active Directory Troubleshooting"
description: "Comprehensive troubleshooting guide for Active Directory issues, common problems, and resolution strategies"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

Active Directory troubleshooting requires a systematic approach to identify and resolve issues affecting authentication, replication, DNS, and service functionality. This guide provides diagnostic procedures and solutions for common AD problems.

## Diagnostic Tools

### Built-in Windows Tools

Essential tools for AD troubleshooting:

```powershell
# Domain Controller Diagnostics
dcdiag /c /v /f:dcdiag-results.txt

# Replication Diagnostics
repadmin /showrepl
repadmin /replsummary
repadmin /syncall /AdeP

# DNS Diagnostics
nslookup -type=SRV _ldap._tcp.dc._msdcs.domain.com
dcdiag /test:dns /v

# Network and Authentication
nltest /dsgetdc:domain.com
nltest /sc_query:domain.com
w32tm /query /status

# Event Log Analysis
Get-WinEvent -LogName "Directory Service" -MaxEvents 100 | Where-Object {$_.LevelDisplayName -eq "Error"}
Get-WinEvent -LogName "DNS Server" -MaxEvents 50 | Where-Object {$_.LevelDisplayName -eq "Warning"}
```

### PowerShell Diagnostic Scripts

```powershell
# AD Health Check Script
function Test-ADReplication
{
    param(
        [string]$DomainName = $env:USERDOMAIN
    )
    
    if ($DomainControllers.Count -eq 0)
    {
        Write-Error "No domain controllers found"
        return
    }

# Usage
$healthCheck = Test-ADHealth
$healthCheck | ConvertTo-Json -Depth 3
```

## Authentication Issues

### User Login Problems

Common authentication troubleshooting steps:

```powershell
# Check user account status
function Test-UserAuthentication
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [string]$Domain = $env:USERDOMAIN
    )
    
    try
    {
        # Get user information
        $user = Get-ADUser -Identity $Username -Properties PasswordLastSet, PasswordExpired, LockedOut, Enabled, LastLogonDate
        
        $userStatus = @{
            Username = $user.SamAccountName
            Enabled = $user.Enabled
            LockedOut = $user.LockedOut
            PasswordExpired = $user.PasswordExpired
            PasswordLastSet = $user.PasswordLastSet
            LastLogon = $user.LastLogonDate
            Issues = @()
        }
        
        # Check for common issues
        if (-not $user.Enabled)
        {
            $userStatus.Issues += "Account is disabled"
        }
        
        if ($user.LockedOut)
        {
            $userStatus.Issues += "Account is locked out"
        }
        
        if ($user.PasswordExpired)
        {
            $userStatus.Issues += "Password has expired"
        }
        
        # Check password age
        if ($user.PasswordLastSet)
        {
            $passwordAge = (Get-Date) - $user.PasswordLastSet
            if ($passwordAge.Days -gt 90)
            {
                $userStatus.Issues += "Password is $($passwordAge.Days) days old"
            }
        }
        
        # Check recent login
        if ($user.LastLogonDate)
        {
            $lastLoginAge = (Get-Date) - $user.LastLogonDate
            if ($lastLoginAge.Days -gt 30)
            {
                $userStatus.Issues += "Last login was $($lastLoginAge.Days) days ago"
            }
        }
        
        return $userStatus
    }
    catch
    {
        Write-Error "Failed to retrieve user information: $($_.Exception.Message)"
        return $null
    }
}

# Check authentication events
function Get-AuthenticationEvents
{
    param(
        [string]$Username,
        [int]$Hours = 24
    )
    
    $startTime = (Get-Date).AddHours(-$Hours)
    
    # Common authentication event IDs
    $eventIDs = @(
        4624,  # Successful logon
        4625,  # Failed logon
        4634,  # Successful logoff
        4647,  # User initiated logoff
        4740,  # Account locked out
        4767,  # Account unlocked
        4771,  # Kerberos pre-authentication failed
        4776   # Domain controller attempted to validate credentials
    )
    
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = $eventIDs
        StartTime = $startTime
    } | Where-Object {
        $_.Message -like "*$Username*"
    } | Select-Object TimeCreated, Id, LevelDisplayName, Message
    
    return $events
}
```

### Kerberos Issues

Diagnose Kerberos authentication problems:

```powershell
# Kerberos ticket diagnostics
function Test-KerberosTickets
{
    param(
        [string]$Username = $env:USERNAME
    )
    
    # List current tickets
    $tickets = klist
    
    # Parse ticket information
    $ticketInfo = @{
        CurrentUser = $Username
        Tickets = @()
        Issues = @()
    }
    
    if ($tickets -match "No tickets")
    {
        $ticketInfo.Issues += "No Kerberos tickets found"
    }
    
    # Check for expired tickets
    if ($tickets -match "expired|invalid")
    {
        $ticketInfo.Issues += "Expired or invalid tickets detected"
    }
    
    # Purge and renew tickets if issues found
    if ($ticketInfo.Issues.Count -gt 0)
    {
        Write-Output "Attempting to resolve Kerberos issues..."
        klist purge
        
        # Force ticket renewal
        try
        {
            $null = nltest /dsgetdc:$env:USERDOMAIN
            $ticketInfo.Resolution = "Tickets purged and renewed"
        }
        catch
        {
            $ticketInfo.Resolution = "Failed to renew tickets: $($_.Exception.Message)"
        }
    }
    
    return $ticketInfo
}

# SPN (Service Principal Name) diagnostics
function Test-ServicePrincipalNames
{
    param(
        [string]$DomainName = $env:USERDOMAIN
    )
    
    try
    {
        $serviceAccounts = Get-ADUser -Filter "ServicePrincipalName -like '*'" -Properties ServicePrincipalNames
        
        $duplicateSpns = @()
        $allSpns = @()
        
        # Collect all SPNs
        foreach ($account in $serviceAccounts)
        {
            $allSpns += $account.ServicePrincipalNames
        }
        
        foreach ($spn in $spns.ServicePrincipalNames)
        {
            $duplicates = $allSpns | Where-Object { $_ -eq $spn }
            if ($duplicates.Count -gt 1)
            {
                $duplicateSpns += [PSCustomObject]@{
                    SPN = $spn
                    Count = $duplicates.Count
                }
            }
        }
    }
    catch
    {
        Write-Error "Failed to check SPNs: $($_.Exception.Message)"
    }
}
```

## Replication Issues

### Replication Monitoring

Monitor and troubleshoot AD replication:

```powershell
# Comprehensive replication check
function Test-ADReplication
{
    param(
        [string[]]$DomainControllers = @()
    )
    
    if ($DomainControllers.Count -eq 0)
    {
        $DomainControllers = (Get-ADDomainController -Filter *).Name
    }
    
    $replicationReport = @{
        Timestamp = Get-Date
        DomainControllers = @{}
        OverallStatus = "Unknown"
        Issues = @()
    }
    
    foreach ($dc in $DomainControllers)
    {
        Write-Output "Checking replication on $($dc.HostName)"
        
        $dcIssues = 0
        
        # Check inbound replication
        try
        {
            $inboundRepl = Get-ADReplicationPartnerMetadata -Target $dc.HostName -PartnerType Inbound
            
            foreach ($repl in $inboundRepl)
            {
                if ($repl.'Last Success Time' -eq "0" -or $repl.'Consecutive Failures' -gt 0)
                {
                    Write-Warning "Inbound replication issue on $($dc.HostName) from $($repl.Partner): Last Success: $($repl.'Last Success Time'), Failures: $($repl.'Consecutive Failures')"
                    $dcIssues++
                }
            }
            
            foreach ($repl in $outboundRepl)
            {
                if ($repl.'Last Success Time' -eq "0" -or $repl.'Consecutive Failures' -gt 0)
                {
                    Write-Warning "Outbound replication issue on $($dc.HostName) to $($repl.Partner): Last Success: $($repl.'Last Success Time'), Failures: $($repl.'Consecutive Failures')"
                    $dcIssues++
                }
            }
        }
        catch
        {
            Write-Error "Failed to check replication on $($dc.HostName): $($_.Exception.Message)"
            $dcIssues++
        }    # Determine overall status
    $totalIssues = ($replicationReport.DomainControllers.Values | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
    
    if ($totalIssues -eq 0)
    {
        $replicationReport.OverallStatus = "Healthy"
    }
    elseif ($totalIssues -lt 5)
    {
        $replicationReport.OverallStatus = "Warning"
    }
    else
    {
        $replicationReport.OverallStatus = "Critical"
    }
    
    return $replicationReport
}

# Force replication between DCs
function Invoke-ADReplicationSync
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDC,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationDC,
        
        [string]$NamingContext = (Get-ADDomain).DistinguishedName
    )
    
    try
    {
        Write-Output "Forcing replication from $SourceDC to $DestinationDC..."
        
        # Force immediate replication
        $result = repadmin /syncall $DestinationDC $NamingContext /AdeP
        
        if ($result -match "error|fail")
        {
            throw "Replication sync failed: $result"
        }
        
        Write-Output "Replication sync completed successfully"
        return $true
    }
    catch
    {
        Write-Error "Failed to sync replication: $($_.Exception.Message)"
        return $false
    }
}
```

### SYSVOL and FRS Issues

Troubleshoot SYSVOL replication problems:

```powershell
# SYSVOL health check
function Test-SysvolReplication
{
    param(
        [string[]]$DomainControllers = @()
    )
    
    if ($DomainControllers.Count -eq 0)
    {
        $DomainControllers = (Get-ADDomainController -Filter *).Name
    }
    
    $sysvolReport = @{
        Timestamp = Get-Date
        ReplicationMethod = "Unknown"
        DomainControllers = @{}
        Issues = @()
    }
    
    # Determine replication method (FRS or DFSR)
    try
    {
        $dfsrCheck = Get-WmiObject -Namespace "root\MicrosoftDfs" -Class "DfsrReplicatedFolderInfo" -ErrorAction Stop
        $sysvolReport.ReplicationMethod = "DFSR"
    }
    catch
    {
        $sysvolReport.ReplicationMethod = "FRS"
    }
    
    foreach ($dc in $DomainControllers)
    {
        $dcSysvolStatus = @{
            Name = $dc
            SysvolShare = $false
            NetlogonShare = $false
            ReplicationStatus = "Unknown"
            Issues = @()
        }
        
        try
        {
            # Test SYSVOL share
            $sysvolPath = "\\$dc\SYSVOL"
            if (Test-Path $sysvolPath)
            {
                $dcSysvolStatus.SysvolShare = $true
            }
            else
            {
                $dcSysvolStatus.Issues += "SYSVOL share not accessible"
            }
            
            # Test NETLOGON share
            $netlogonPath = "\\$dc\NETLOGON"
            if (Test-Path $netlogonPath)
            {
                $dcSysvolStatus.NetlogonShare = $true
            }
            else
            {
                $dcSysvolStatus.Issues += "NETLOGON share not accessible"
            }
            
            # Check replication status based on method
            if ($sysvolReport.ReplicationMethod -eq "DFSR")
            {
                $dfsrStatus = dfsrdiag replicationstate /member:$dc
                if ($dfsrStatus -match "error|fail")
                {
                    $dcSysvolStatus.Issues += "DFSR replication issues detected"
                }
            }
            else
            {
                $frsStatus = ntfrsutl ds $dc
                if ($frsStatus -match "error|fail")
                {
                    $dcSysvolStatus.Issues += "FRS replication issues detected"
                }
            }
            
            $sysvolReport.DomainControllers[$dc] = $dcSysvolStatus
        }
        catch
        {
            $dcSysvolStatus.Issues += "Failed to check SYSVOL status: $($_.Exception.Message)"
            $sysvolReport.DomainControllers[$dc] = $dcSysvolStatus
        }
    }
    
    return $sysvolReport
}
```

## DNS Issues

### DNS Troubleshooting

Diagnose DNS problems affecting AD:

```powershell
# Comprehensive DNS check for AD
function Test-ADDnsConfiguration
{
    param(
        [string]$Domain = $env:USERDOMAIN,
        [string[]]$DomainControllers = @()
    )
    
    if ($DomainControllers.Count -eq 0)
    {
        $DomainControllers = (Get-ADDomainController -Filter *).Name
    }
    
    $dnsReport = @{
        Domain = $Domain
        Timestamp = Get-Date
        SRVRecords = @{}
        ARecords = @{}
        Issues = @()
    }
    
    # Critical SRV records to check
    $srvRecords = @(
        "_ldap._tcp.$Domain",
        "_ldap._tcp.dc._msdcs.$Domain",
        "_kerberos._tcp.$Domain",
        "_kpasswd._tcp.$Domain",
        "_gc._tcp.$Domain"
    )
    
    foreach ($srv in $srvRecords)
    {
        try
        {
            $srvResult = Resolve-DnsName -Name $srv -Type SRV -ErrorAction Stop
            $dnsReport.SRVRecords[$srv] = @{
                Status = "Success"
                Records = $srvResult.Count
                Details = $srvResult
            }
        }
        catch
        {
            $dnsReport.SRVRecords[$srv] = @{
                Status = "Failed"
                Error = $_.Exception.Message
            }
            $dnsReport.Issues += "Failed to resolve SRV record: $srv"
        }
    }
    
    # Check A records for domain controllers
    foreach ($dc in $DomainControllers)
    {
        try
        {
            $aResult = Resolve-DnsName -Name $dc -Type A -ErrorAction Stop
            $dnsReport.ARecords[$dc] = @{
                Status = "Success"
                IPAddress = $aResult.IPAddress
            }
        }
        catch
        {
            $dnsReport.ARecords[$dc] = @{
                Status = "Failed"
                Error = $_.Exception.Message
            }
            $dnsReport.Issues += "Failed to resolve A record for DC: $dc"
        }
    }
    
    return $dnsReport
}

# DNS scavenging check
function Test-DnsScavenging
{
    param(
        [string[]]$DnsServers = @()
    )
    
    if ($DnsServers.Count -eq 0)
    {
        $DnsServers = (Get-ADDomainController -Filter *).Name
    }
    
    $scavengingReport = @{
        Timestamp = Get-Date
        Servers = @{}
    }
    
    foreach ($server in $DnsServers)
    {
        try
        {
            $scavengingSettings = Get-DnsServerScavenging -ComputerName $server
            
            $scavengingReport.Servers[$server] = @{
                ScavengingState = $scavengingSettings.ScavengingState
                ScavengingInterval = $scavengingSettings.ScavengingInterval
                LastScavengeTime = $scavengingSettings.LastScavengeTime
                Recommendations = @()
            }
            
            if (-not $scavengingSettings.ScavengingState)
            {
                $scavengingReport.Servers[$server].Recommendations += "Enable DNS scavenging"
            }
            
            if ($scavengingSettings.ScavengingInterval.TotalDays -gt 7)
            {
                $scavengingReport.Servers[$server].Recommendations += "Consider reducing scavenging interval"
            }
        }
        catch
        {
            $scavengingReport.Servers[$server] = @{
                Error = $_.Exception.Message
            }
        }
    }
    
    return $scavengingReport
}
```

## Performance Issues

### Performance Monitoring

Monitor AD performance metrics:

```powershell
# AD performance counters
function Get-ADPerformanceMetrics
{
    param(
        [string]$DomainController = $env:COMPUTERNAME,
        [int]$SampleInterval = 5,
        [int]$SampleCount = 12
    )
    
    $performanceCounters = @(
        "\NTDS\DRA Inbound Bytes Total/sec",
        "\NTDS\DRA Outbound Bytes Total/sec",
        "\NTDS\DS Directory Reads/sec",
        "\NTDS\DS Directory Writes/sec",
        "\NTDS\LDAP Client Sessions",
        "\NTDS\LDAP Searches/sec",
        "\NTDS\LDAP Successful Binds/sec",
        "\NTDS\Kerberos Authentications/sec",
        "\NTDS\NTLM Authentications/sec"
    )
    
    try
    {
        $samples = Get-Counter -ComputerName $DomainController -Counter $performanceCounters -SampleInterval $SampleInterval -MaxSamples $SampleCount
        
        $performanceReport = @{
            DomainController = $DomainController
            SamplePeriod = "$($SampleInterval * $SampleCount) seconds"
            Metrics = @{}
            Alerts = @()
        }
        
        # Calculate averages and identify issues
        foreach ($counter in $performanceCounters)
        {
            $counterSamples = $samples.CounterSamples | Where-Object {$_.Path -like "*$($counter.Split('\')[-1])*"}
            $average = ($counterSamples | Measure-Object -Property CookedValue -Average).Average
            
            $performanceReport.Metrics[$counter] = @{
                Average = [Math]::Round($average, 2)
                Minimum = ($counterSamples | Measure-Object -Property CookedValue -Minimum).Minimum
                Maximum = ($counterSamples | Measure-Object -Property CookedValue -Maximum).Maximum
            }
            
            # Performance thresholds
            switch -Wildcard ($counter) {
                "*LDAP Searches/sec*" {
                    if ($average -gt 1000)
                    {
                        $performanceReport.Alerts += "High LDAP search rate: $([Math]::Round($average, 2))/sec"
                    }
                }
                "*DS Directory Reads/sec*" {
                    if ($average -gt 500)
                    {
                        $performanceReport.Alerts += "High directory read rate: $([Math]::Round($average, 2))/sec"
                    }
                }
                "*LDAP Client Sessions*" {
                    if ($average -gt 1000)
                    {
                        $performanceReport.Alerts += "High LDAP client sessions: $([Math]::Round($average, 2))"
                    }
                }
            }
        }
        
        return $performanceReport
    }
    catch
    {
        Write-Error "Failed to collect performance metrics: $($_.Exception.Message)"
        return $null
    }
}

# Database performance check
function Test-ADDatabasePerformance
{
    param(
        [string]$DomainController = $env:COMPUTERNAME
    )
    
    $databaseReport = @{
        DomainController = $DomainController
        Timestamp = Get-Date
        DatabaseInfo = @{}
        Issues = @()
    }
    
    try
    {
        # Get database file information
        $ntdsutil = "ntdsutil `"activate instance ntds`" files info quit quit"
        $dbInfo = Invoke-Expression $ntdsutil
        
        # Parse database information
        if ($dbInfo -match "Database file: (.+)")
        {
            $dbPath = $matches[1].Trim()
            $dbFile = Get-Item $dbPath -ErrorAction Stop
            
            $databaseReport.DatabaseInfo = @{
                Path = $dbPath
                SizeMB = [Math]::Round($dbFile.Length / 1MB, 2)
                LastModified = $dbFile.LastWriteTime
            }
            
            # Check database size
            if ($dbFile.Length -gt 10GB)
            {
                $databaseReport.Issues += "Large database size: $([Math]::Round($dbFile.Length / 1GB, 2)) GB"
            }
            
            # Check available disk space
            $drive = $dbPath.Substring(0, 2)
            $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $drive}
            $freeSpaceGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
            
            if ($freeSpaceGB -lt 2)
            {
                $databaseReport.Issues += "Low disk space: $freeSpaceGB GB available"
            }
        }
        
        return $databaseReport
    }
    catch
    {
        $databaseReport.Issues += "Failed to check database: $($_.Exception.Message)"
        return $databaseReport
    }
}
```

## Group Policy Issues

### Group Policy Troubleshooting

Diagnose GP application problems:

```powershell
# Group Policy diagnostics
function Test-GroupPolicyApplication
{
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Username = $env:USERNAME
    )
    
    $gpReport = @{
        ComputerName = $ComputerName
        Username = $Username
        Timestamp = Get-Date
        ComputerPolicies = @{}
        UserPolicies = @{}
        Issues = @()
    }
    
    try
    {
        # Run gpresult for detailed information
        $gpResult = gpresult /r /scope:both
        
        # Check last GP refresh times
        $computerRefresh = Get-WinEvent -FilterHashtable @{LogName='System'; ID=1502} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($computerRefresh)
        {
            $gpReport.ComputerPolicies.LastRefresh = $computerRefresh.TimeCreated
        }
        
        $userRefresh = Get-WinEvent -FilterHashtable @{LogName='Application'; ID=1502} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($userRefresh)
        {
            $gpReport.UserPolicies.LastRefresh = $userRefresh.TimeCreated
        }
        
        # Check for GP errors
        $gpErrors = Get-WinEvent -FilterHashtable @{LogName='System'; ID=1085,1097} -MaxEvents 10 -ErrorAction SilentlyContinue
        if ($gpErrors)
        {
            $gpReport.Issues += "Group Policy errors found in event log"
        }
        
        # Test network connectivity to domain controller
        $dc = nltest /dsgetdc:$env:USERDOMAIN
        if ($dc -match "error|fail")
        {
            $gpReport.Issues += "Cannot contact domain controller for GP processing"
        }
        
        return $gpReport
    }
    catch
    {
        $gpReport.Issues += "Failed to analyze Group Policy: $($_.Exception.Message)"
        return $gpReport
    }
}

# Force Group Policy refresh
function Invoke-GroupPolicyRefresh
{
    param(
        [switch]$Computer,
        [switch]$User,
        [switch]$Force
    )
    
    try
    {
        $refreshParams = @()
        
        if ($Computer)
        {
            $refreshParams += "/target:computer"
        }
        
        if ($User)
        {
            $refreshParams += "/target:user"
        }
        
        if ($Force)
        {
            $refreshParams += "/force"
        }
        
        $refreshCommand = "gpupdate " + ($refreshParams -join " ")
        
        Write-Output "Executing: $refreshCommand"
        $result = Invoke-Expression $refreshCommand
        
        Write-Output "Group Policy refresh completed"
        return $result
    }
    catch
    {
        Write-Error "Failed to refresh Group Policy: $($_.Exception.Message)"
        return $false
    }
}
```

## Common Troubleshooting Scenarios

### Domain Join Issues

Troubleshoot computer domain join problems:

```powershell
# Domain join diagnostics
function Test-DomainJoinRequirements
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DomainName,
        
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    $joinReport = @{
        DomainName = $DomainName
        ComputerName = $ComputerName
        Timestamp = Get-Date
        Prerequisites = @{}
        Issues = @()
    }
    
    # Check DNS resolution
    try
    {
        $domainDC = Resolve-DnsName -Name $DomainName -Type A -ErrorAction Stop
        $joinReport.Prerequisites.DNSResolution = "Pass"
    }
    catch
    {
        $joinReport.Prerequisites.DNSResolution = "Fail"
        $joinReport.Issues += "Cannot resolve domain name: $DomainName"
    }
    
    # Check domain controller connectivity
    try
    {
        $dcInfo = nltest /dsgetdc:$DomainName
        if ($dcInfo -match "error|fail")
        {
            throw "Domain controller lookup failed"
        }
        $joinReport.Prerequisites.DCConnectivity = "Pass"
    }
    catch
    {
        $joinReport.Prerequisites.DCConnectivity = "Fail"
        $joinReport.Issues += "Cannot contact domain controller for $DomainName"
    }
    
    # Check time synchronization
    try
    {
        $timeDiff = w32tm /stripchart /computer:$DomainName /samples:1 /dataonly
        if ($timeDiff -match "error")
        {
            throw "Time sync check failed"
        }
        $joinReport.Prerequisites.TimeSync = "Pass"
    }
    catch
    {
        $joinReport.Prerequisites.TimeSync = "Warning"
        $joinReport.Issues += "Time synchronization may be an issue"
    }
    
    # Check network connectivity
    try
    {
        $pingResult = Test-Connection -ComputerName $DomainName -Count 2 -ErrorAction Stop
        $joinReport.Prerequisites.NetworkConnectivity = "Pass"
    }
    catch
    {
        $joinReport.Prerequisites.NetworkConnectivity = "Fail"
        $joinReport.Issues += "Network connectivity issues to domain"
    }
    
    return $joinReport
}
```

### Trust Relationship Issues

Diagnose trust relationship problems:

```powershell
# Trust relationship diagnostics
function Test-ComputerTrustRelationship
{
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Domain = $env:USERDOMAIN
    )
    
    $trustReport = @{
        ComputerName = $ComputerName
        Domain = $Domain
        Timestamp = Get-Date
        TrustStatus = "Unknown"
        Issues = @()
        Resolution = @()
    }
    
    try
    {
        # Test secure channel
        $trustTest = nltest /sc_query:$Domain
        
        if ($trustTest -match "success")
        {
            $trustReport.TrustStatus = "Healthy"
        }
        elseif ($trustTest -match "error|fail")
        {
            $trustReport.TrustStatus = "Broken"
            $trustReport.Issues += "Secure channel test failed"
            $trustReport.Resolution += "Reset computer account password"
        }
        
        # Additional checks if trust is broken
        if ($trustReport.TrustStatus -eq "Broken")
        {
            # Try to reset secure channel
            Write-Output "Attempting to reset secure channel..."
            $resetResult = nltest /sc_reset:$Domain
            
            if ($resetResult -match "success")
            {
                $trustReport.Resolution += "Secure channel reset successful"
                $trustReport.TrustStatus = "Repaired"
            }
            else
            {
                $trustReport.Resolution += "Secure channel reset failed - manual intervention required"
            }
        }
        
        return $trustReport
    }
    catch
    {
        $trustReport.Issues += "Failed to test trust relationship: $($_.Exception.Message)"
        return $trustReport
    }
}
```

## Event Log Analysis

### Critical Event Monitoring

Monitor and analyze AD-related events:

```powershell
# AD event analysis
function Get-ADCriticalEvents
{
    param(
        [int]$Hours = 24,
        [string[]]$ComputerName = @($env:COMPUTERNAME)
    )
    
    $startTime = (Get-Date).AddHours(-$Hours)
    
    # Critical AD event IDs
    $criticalEvents = @{
        # Authentication events
        4771 = "Kerberos pre-authentication failed"
        4776 = "Domain controller attempted to validate credentials"
        4740 = "Account locked out"
        
        # Replication events
        1311 = "Knowledge Consistency Checker error"
        1388 = "Replication error"
        
        # DNS events
        4013 = "DNS server unable to load zone"
        4015 = "DNS server unable to start"
        
        # Directory Service events
        1202 = "Directory service could not be initialized"
        1173 = "Internal error in Active Directory"
    }
    
    $eventReport = @{
        TimeRange = "$Hours hours"
        StartTime = $startTime
        Computers = @{}
        Summary = @{
            TotalEvents = 0
            CriticalCount = 0
            WarningCount = 0
        }
    }
    
    foreach ($computer in $ComputerName)
    {
        $computerEvents = @{
            ComputerName = $computer
            Events = @()
            Summary = @{
                Critical = 0
                Warning = 0
                Information = 0
            }
        }
        
        try
        {
            foreach ($eventId in $criticalEvents.Keys)
            {
                $events = Get-WinEvent -ComputerName $computer -FilterHashtable @{
                    LogName = 'Security', 'System', 'Directory Service', 'DNS Server'
                    ID = $eventId
                    StartTime = $startTime
                } -ErrorAction SilentlyContinue
                
                foreach ($event in $events)
                {
                    $eventInfo = @{
                        EventId = $event.Id
                        Level = $event.LevelDisplayName
                        TimeCreated = $event.TimeCreated
                        Description = $criticalEvents[$event.Id]
                        Message = $event.Message.Substring(0, [Math]::Min(200, $event.Message.Length))
                    }
                    
                    $computerEvents.Events += $eventInfo
                    $computerEvents.Summary[$event.LevelDisplayName]++
                    $eventReport.Summary.TotalEvents++
                    
                    if ($event.LevelDisplayName -eq "Critical")
                    {
                        $eventReport.Summary.CriticalCount++
                    }
                    elseif ($event.LevelDisplayName -eq "Warning")
                    {
                        $eventReport.Summary.WarningCount++
                    }
                }
            }
            
            $eventReport.Computers[$computer] = $computerEvents
        }
        catch
        {
            Write-Warning "Failed to retrieve events from $computer`: $($_.Exception.Message)"
        }
    }
    
    return $eventReport
}
```

## Recovery Procedures

### Authoritative Restore

Perform authoritative restore of AD objects:

```powershell
# Authoritative restore guidance
function New-AuthoritativeRestorePlan
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$ObjectDN,
        
        [string]$BackupDate,
        [switch]$DryRun
    )
    
    $restorePlan = @{
        ObjectDN = $ObjectDN
        BackupDate = $BackupDate
        DryRun = $DryRun
        Steps = @()
        Warnings = @()
        Prerequisites = @()
    }
    
    # Add prerequisites
    $restorePlan.Prerequisites += "Boot domain controller into Directory Services Restore Mode"
    $restorePlan.Prerequisites += "Restore system state from backup dated $BackupDate"
    $restorePlan.Prerequisites += "Ensure network connectivity to other domain controllers"
    
    # Add restoration steps
    $restorePlan.Steps += "Start in Directory Services Restore Mode"
    $restorePlan.Steps += "Restore system state: wbadmin start systemstaterecovery -version:$BackupDate"
    $restorePlan.Steps += "Mark object as authoritative: ntdsutil `"authoritative restore`" `"restore object $ObjectDN`""
    $restorePlan.Steps += "Restart in normal mode"
    $restorePlan.Steps += "Force replication to other DCs"
    
    # Add warnings
    $restorePlan.Warnings += "Authoritative restore will overwrite newer changes"
    $restorePlan.Warnings += "Test in lab environment first"
    $restorePlan.Warnings += "Backup current state before proceeding"
    
    if ($DryRun)
    {
        Write-Output "DRY RUN - Authoritative Restore Plan:"
        $restorePlan | ConvertTo-Json -Depth 3
    }
    
    return $restorePlan
}
```

## Related Documentation

- **[Getting Started](../fundamentals/getting-started.md)** - AD fundamentals and basic setup
- **[Domain Controllers](../fundamentals/domain-controllers.md)** - DC deployment and management
- **[Delegation](delegation.md)** - Permission delegation and security
- **[Operations](index.md)** - Day-to-day AD administration
- **[Security Best Practices](../security-best-practices.md)** - AD security hardening

---

*This troubleshooting guide provides systematic approaches to diagnosing and resolving Active Directory issues. Regular monitoring and proactive maintenance help prevent many common problems.*
