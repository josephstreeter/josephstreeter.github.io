---
title: Active Directory Maintenance and Troubleshooting
description: Comprehensive guide for Active Directory maintenance procedures, troubleshooting methodologies, and issue resolution
author: Joseph Streeter
date: 2024-01-15
tags: [active-directory, maintenance, troubleshooting, operations, administration]
---

Maintaining a healthy Active Directory environment requires proactive monitoring, regular maintenance tasks, and systematic troubleshooting approaches. This guide provides comprehensive procedures for keeping AD running optimally and resolving common issues.

## 🔧 Regular Maintenance Tasks

### Daily Maintenance

```powershell
# Daily AD Health Check Script
function Invoke-ADDailyHealthCheck
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DomainControllers = (Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name),
        
        [Parameter()]
        [string]$LogPath = "C:\ADLogs\DailyHealthCheck_$(Get-Date -Format 'yyyy-MM-dd').log",
        
        [Parameter()]
        [switch]$SendEmail
    )
    
    try
    {
        $Results = [System.Collections.Generic.List[object]]@()
        $StartTime = Get-Date
        
        Write-Host "Starting Active Directory Daily Health Check..." -ForegroundColor Green
        
        # Create log directory if it doesn't exist
        $LogDirectory = Split-Path $LogPath
        if (-not (Test-Path $LogDirectory))
        {
            New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Initialize log file
        "Active Directory Daily Health Check - $(Get-Date)" | Out-File -FilePath $LogPath -Encoding UTF8
        "=" * 80 | Out-File -FilePath $LogPath -Append
        
        foreach ($DC in $DomainControllers)
        {
            Write-Host "Checking Domain Controller: $DC" -ForegroundColor Cyan
            $DCResult = [PSCustomObject]@{
                DomainController = $DC
                Timestamp = Get-Date
                ServiceStatus = @{}
                ReplicationStatus = ""
                EventLogErrors = @()
                DiskSpace = @{}
                OverallHealth = "Unknown"
                Issues = @()
            }
            
            try
            {
                # Test DC connectivity
                if (-not (Test-Connection -ComputerName $DC -Count 2 -Quiet))
                {
                    $DCResult.Issues += "Domain Controller not responding to ping"
                    $DCResult.OverallHealth = "Critical"
                    $Results.Add($DCResult)
                    continue
                }
                
                # Check critical AD services
                $CriticalServices = @('NTDS', 'DNS', 'DFSR', 'W32Time', 'Netlogon', 'KDC')
                
                foreach ($Service in $CriticalServices)
                {
                    try
                    {
                        $ServiceStatus = Get-Service -ComputerName $DC -Name $Service -ErrorAction Stop
                        $DCResult.ServiceStatus[$Service] = $ServiceStatus.Status
                        
                        if ($ServiceStatus.Status -ne 'Running')
                        {
                            $DCResult.Issues += "$Service service is $($ServiceStatus.Status)"
                        }
                    }
                    catch
                    {
                        $DCResult.ServiceStatus[$Service] = "Not Found"
                        $DCResult.Issues += "$Service service not found"
                    }
                }
                
                # Check AD replication
                try
                {
                    $ReplStatus = Invoke-Command -ComputerName $DC -ScriptBlock {
                        repadmin /showrepl /csv | ConvertFrom-Csv | Where-Object {$_.'Number of Failures' -gt 0}
                    } -ErrorAction Stop
                    
                    if ($ReplStatus)
                    {
                        $DCResult.ReplicationStatus = "Replication Failures Detected"
                        $DCResult.Issues += "Active Directory replication failures"
                    }
                    else
                    {
                        $DCResult.ReplicationStatus = "Healthy"
                    }
                }
                catch
                {
                    $DCResult.ReplicationStatus = "Unable to check"
                    $DCResult.Issues += "Could not verify replication status"
                }
                
                # Check disk space
                try
                {
                    $DiskInfo = Get-WmiObject -ComputerName $DC -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
                    
                    foreach ($Disk in $DiskInfo)
                    {
                        $PercentFree = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)
                        $DCResult.DiskSpace[$Disk.DeviceID] = "$PercentFree% free"
                        
                        if ($PercentFree -lt 10)
                        {
                            $DCResult.Issues += "Drive $($Disk.DeviceID) has only $PercentFree% free space"
                        }
                    }
                }
                catch
                {
                    $DCResult.Issues += "Could not retrieve disk space information"
                }
                
                # Check recent errors in System and Directory Services logs
                try
                {
                    $RecentErrors = Get-WinEvent -ComputerName $DC -FilterHashtable @{
                        LogName = 'System', 'Directory Service'
                        Level = 1, 2
                        StartTime = (Get-Date).AddHours(-24)
                    } -MaxEvents 10 -ErrorAction SilentlyContinue
                    
                    if ($RecentErrors)
                    {
                        $DCResult.EventLogErrors = $RecentErrors | ForEach-Object {
                            "$($_.TimeCreated) - $($_.LevelDisplayName) - $($_.Id) - $($_.Message.Substring(0, [math]::Min(100, $_.Message.Length)))"
                        }
                        $DCResult.Issues += "$($RecentErrors.Count) error(s) in System/Directory Service logs"
                    }
                }
                catch
                {
                    $DCResult.Issues += "Could not retrieve event log information"
                }
                
                # Determine overall health
                if ($DCResult.Issues.Count -eq 0)
                {
                    $DCResult.OverallHealth = "Healthy"
                }
                elseif ($DCResult.Issues | Where-Object {$_ -match "Critical|Not responding|service is Stopped"})
                {
                    $DCResult.OverallHealth = "Critical"
                }
                else
                {
                    $DCResult.OverallHealth = "Warning"
                }
            }
            catch
            {
                $DCResult.Issues += "General error during health check: $($_.Exception.Message)"
                $DCResult.OverallHealth = "Critical"
            }
            
            $Results.Add($DCResult)
            
            # Log results for this DC
            "" | Out-File -FilePath $LogPath -Append
            "Domain Controller: $DC" | Out-File -FilePath $LogPath -Append
            "Overall Health: $($DCResult.OverallHealth)" | Out-File -FilePath $LogPath -Append
            "Services:" | Out-File -FilePath $LogPath -Append
            $DCResult.ServiceStatus.GetEnumerator() | ForEach-Object {
                "  $($_.Key): $($_.Value)" | Out-File -FilePath $LogPath -Append
            }
            "Replication: $($DCResult.ReplicationStatus)" | Out-File -FilePath $LogPath -Append
            "Disk Space:" | Out-File -FilePath $LogPath -Append
            $DCResult.DiskSpace.GetEnumerator() | ForEach-Object {
                "  $($_.Key): $($_.Value)" | Out-File -FilePath $LogPath -Append
            }
            if ($DCResult.Issues.Count -gt 0)
            {
                "Issues:" | Out-File -FilePath $LogPath -Append
                $DCResult.Issues | ForEach-Object {
                    "  - $_" | Out-File -FilePath $LogPath -Append
                }
            }
        }
        
        # Generate summary
        $HealthySystems = ($Results | Where-Object OverallHealth -eq "Healthy").Count
        $WarningSystems = ($Results | Where-Object OverallHealth -eq "Warning").Count
        $CriticalSystems = ($Results | Where-Object OverallHealth -eq "Critical").Count
        
        $Summary = [PSCustomObject]@{
            CheckTime = $StartTime
            TotalDCs = $Results.Count
            HealthyDCs = $HealthySystems
            WarningDCs = $WarningSystems
            CriticalDCs = $CriticalSystems
            OverallStatus = if ($CriticalSystems -gt 0) { "Critical" } elseif ($WarningSystems -gt 0) { "Warning" } else { "Healthy" }
        }
        
        # Log summary
        "" | Out-File -FilePath $LogPath -Append
        "SUMMARY" | Out-File -FilePath $LogPath -Append
        "=" * 40 | Out-File -FilePath $LogPath -Append
        "Total Domain Controllers: $($Summary.TotalDCs)" | Out-File -FilePath $LogPath -Append
        "Healthy: $($Summary.HealthyDCs)" | Out-File -FilePath $LogPath -Append
        "Warning: $($Summary.WarningDCs)" | Out-File -FilePath $LogPath -Append
        "Critical: $($Summary.CriticalDCs)" | Out-File -FilePath $LogPath -Append
        "Overall Status: $($Summary.OverallStatus)" | Out-File -FilePath $LogPath -Append
        
        Write-Host "`nDaily Health Check Summary:" -ForegroundColor Cyan
        Write-Host "Healthy DCs: $($Summary.HealthyDCs)" -ForegroundColor Green
        Write-Host "Warning DCs: $($Summary.WarningDCs)" -ForegroundColor Yellow
        Write-Host "Critical DCs: $($Summary.CriticalDCs)" -ForegroundColor Red
        Write-Host "Log saved to: $LogPath" -ForegroundColor White
        
        return [PSCustomObject]@{
            Summary = $Summary
            DetailedResults = $Results
            LogPath = $LogPath
        }
    }
    catch
    {
        Write-Error "Daily health check failed: $($_.Exception.Message)"
        throw
    }
}
```

### Weekly Maintenance

```powershell
# Weekly AD Maintenance Script
function Invoke-ADWeeklyMaintenance
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath = "C:\ADLogs\WeeklyMaintenance_$(Get-Date -Format 'yyyy-MM-dd').log"
    )
    
    try
    {
        Write-Host "Starting Active Directory Weekly Maintenance..." -ForegroundColor Green
        
        # Initialize log
        "Active Directory Weekly Maintenance - $(Get-Date)" | Out-File -FilePath $LogPath -Encoding UTF8
        
        # 1. Check and clean up AD database
        Write-Host "1. Checking Active Directory database..." -ForegroundColor Cyan
        $DatabaseCheck = @"
        - Check NTDS.dit size and growth
        - Verify database integrity
        - Check for tombstone cleanup
        - Review deleted objects container
"@
        $DatabaseCheck | Out-File -FilePath $LogPath -Append
        
        # 2. Review FSMO role holders
        Write-Host "2. Reviewing FSMO role holders..." -ForegroundColor Cyan
        try
        {
            $FSMORoles = @{
                "Schema Master" = (Get-ADForest).SchemaMaster
                "Domain Naming Master" = (Get-ADForest).DomainNamingMaster
                "RID Master" = (Get-ADDomain).RIDMaster
                "PDC Emulator" = (Get-ADDomain).PDCEmulator
                "Infrastructure Master" = (Get-ADDomain).InfrastructureMaster
            }
            
            "FSMO Role Holders:" | Out-File -FilePath $LogPath -Append
            $FSMORoles.GetEnumerator() | ForEach-Object {
                "$($_.Key): $($_.Value)" | Out-File -FilePath $LogPath -Append
            }
        }
        catch
        {
            "Error retrieving FSMO roles: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        }
        
        # 3. Check DNS health
        Write-Host "3. Checking DNS health..." -ForegroundColor Cyan
        try
        {
            $DNSZones = Get-DnsServerZone -ComputerName (Get-ADDomainController).Name
            "DNS Zones Count: $($DNSZones.Count)" | Out-File -FilePath $LogPath -Append
            
            # Check for scavenging settings
            $ScavengingSettings = Get-DnsServerScavenging -ComputerName (Get-ADDomainController).Name
            "DNS Scavenging Enabled: $($ScavengingSettings.ScavengingState)" | Out-File -FilePath $LogPath -Append
        }
        catch
        {
            "Error checking DNS: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        }
        
        # 4. Review Group Policy
        Write-Host "4. Reviewing Group Policy..." -ForegroundColor Cyan
        try
        {
            $GPOs = Get-GPO -All
            "Total GPOs: $($GPOs.Count)" | Out-File -FilePath $LogPath -Append
            
            # Check for unlinked GPOs
            $UnlinkedGPOs = $GPOs | Where-Object { (Get-GPOReport -Guid $_.Id -ReportType Xml | Select-String "LinksTo").Count -eq 0 }
            "Unlinked GPOs: $($UnlinkedGPOs.Count)" | Out-File -FilePath $LogPath -Append
        }
        catch
        {
            "Error reviewing GPOs: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        }
        
        # 5. Backup status check
        Write-Host "5. Checking backup status..." -ForegroundColor Cyan
        try
        {
            # Check Windows Server Backup
            $BackupSummary = Get-WBSummary -ErrorAction SilentlyContinue
            if ($BackupSummary)
            {
                "Last Backup: $($BackupSummary.LastBackupTime)" | Out-File -FilePath $LogPath -Append
                "Backup Result: $($BackupSummary.LastBackupResultHR)" | Out-File -FilePath $LogPath -Append
            }
            else
            {
                "Windows Server Backup not configured or accessible" | Out-File -FilePath $LogPath -Append
            }
        }
        catch
        {
            "Error checking backup status: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        }
        
        Write-Host "Weekly maintenance completed. Log saved to: $LogPath" -ForegroundColor Green
    }
    catch
    {
        Write-Error "Weekly maintenance failed: $($_.Exception.Message)"
        throw
    }
}
```

## 🚨 Troubleshooting Methodologies

### Common AD Issues and Solutions

#### Authentication Failures

```powershell
# Comprehensive authentication troubleshooting
function Test-ADAuthentication
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter()]
        [string]$DomainController,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    try
    {
        Write-Host "Troubleshooting authentication for user: $UserName" -ForegroundColor Yellow
        
        # 1. Check if user exists
        try
        {
            $User = Get-ADUser -Identity $UserName -Properties LockedOut, Enabled, PasswordExpired, LastLogonDate, BadLogonCount
            Write-Host "✓ User account found" -ForegroundColor Green
            
            # Check account status
            if (-not $User.Enabled)
            {
                Write-Host "✗ User account is disabled" -ForegroundColor Red
                return "Account Disabled"
            }
            
            if ($User.LockedOut)
            {
                Write-Host "✗ User account is locked out" -ForegroundColor Red
                Write-Host "Bad logon count: $($User.BadLogonCount)" -ForegroundColor Yellow
                return "Account Locked"
            }
            
            if ($User.PasswordExpired)
            {
                Write-Host "✗ User password has expired" -ForegroundColor Red
                return "Password Expired"
            }
            
            Write-Host "✓ Account status checks passed" -ForegroundColor Green
        }
        catch
        {
            Write-Host "✗ User account not found: $($_.Exception.Message)" -ForegroundColor Red
            return "User Not Found"
        }
        
        # 2. Check Kerberos tickets
        try
        {
            $KlistOutput = & klist
            if ($KlistOutput -match $UserName)
            {
                Write-Host "✓ Kerberos ticket found for user" -ForegroundColor Green
            }
            else
            {
                Write-Host "⚠ No Kerberos ticket found for user" -ForegroundColor Yellow
            }
        }
        catch
        {
            Write-Host "⚠ Could not check Kerberos tickets" -ForegroundColor Yellow
        }
        
        # 3. Test LDAP connectivity
        try
        {
            $LDAPTest = Test-NetConnection -ComputerName $DomainController -Port 389
            if ($LDAPTest.TcpTestSucceeded)
            {
                Write-Host "✓ LDAP connectivity successful" -ForegroundColor Green
            }
            else
            {
                Write-Host "✗ LDAP connectivity failed" -ForegroundColor Red
                return "LDAP Connection Failed"
            }
        }
        catch
        {
            Write-Host "⚠ Could not test LDAP connectivity" -ForegroundColor Yellow
        }
        
        # 4. Check domain controller health
        try
        {
            $DCDiag = & dcdiag /test:connectivity /s:$DomainController
            if ($DCDiag -match "passed test Connectivity")
            {
                Write-Host "✓ Domain controller connectivity test passed" -ForegroundColor Green
            }
            else
            {
                Write-Host "✗ Domain controller connectivity issues detected" -ForegroundColor Red
            }
        }
        catch
        {
            Write-Host "⚠ Could not run dcdiag connectivity test" -ForegroundColor Yellow
        }
        
        if ($Detailed)
        {
            # Additional detailed checks
            Write-Host "`nDetailed Information:" -ForegroundColor Cyan
            Write-Host "Last Logon: $($User.LastLogonDate)" -ForegroundColor White
            Write-Host "Bad Logon Count: $($User.BadLogonCount)" -ForegroundColor White
            
            # Check group memberships
            $Groups = Get-ADPrincipalGroupMembership -Identity $UserName
            Write-Host "Group Memberships: $($Groups.Count)" -ForegroundColor White
            
            # Check password policy
            $PasswordPolicy = Get-ADDefaultDomainPasswordPolicy
            Write-Host "Password Policy - Max Age: $($PasswordPolicy.MaxPasswordAge)" -ForegroundColor White
        }
        
        return "Authentication checks completed"
    }
    catch
    {
        Write-Error "Authentication troubleshooting failed: $($_.Exception.Message)"
        throw
    }
}
```

#### Replication Issues

```powershell
# Replication troubleshooting and repair
function Repair-ADReplication
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DomainControllers = (Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name),
        
        [Parameter()]
        [switch]$ForceReplication
    )
    
    try
    {
        Write-Host "Starting Active Directory replication diagnostics..." -ForegroundColor Green
        
        $ReplicationResults = [System.Collections.Generic.List[object]]@()
        
        foreach ($DC in $DomainControllers)
        {
            Write-Host "Checking replication on: $DC" -ForegroundColor Cyan
            
            $DCResult = [PSCustomObject]@{
                DomainController = $DC
                ReplicationPartners = @()
                ReplicationFailures = @()
                KnowledgeConsistencyChecker = ""
                OverallStatus = "Unknown"
            }
            
            try
            {
                # Check replication partners
                $ReplPartners = & repadmin /showrepl $DC /csv | ConvertFrom-Csv
                $DCResult.ReplicationPartners = $ReplPartners | Where-Object { $_.'Number of Failures' -eq 0 }
                $DCResult.ReplicationFailures = $ReplPartners | Where-Object { $_.'Number of Failures' -gt 0 }
                
                # Check KCC
                $KCCResult = & repadmin /kcc $DC
                $DCResult.KnowledgeConsistencyChecker = if ($KCCResult -match "completed successfully") { "Healthy" } else { "Issues detected" }
                
                # Determine overall status
                if ($DCResult.ReplicationFailures.Count -eq 0)
                {
                    $DCResult.OverallStatus = "Healthy"
                    Write-Host "  ✓ Replication healthy" -ForegroundColor Green
                }
                else
                {
                    $DCResult.OverallStatus = "Failed"
                    Write-Host "  ✗ $($DCResult.ReplicationFailures.Count) replication failure(s)" -ForegroundColor Red
                    
                    # Show failures
                    foreach ($Failure in $DCResult.ReplicationFailures)
                    {
                        Write-Host "    - Source: $($Failure.'Source DSA') | Failures: $($Failure.'Number of Failures')" -ForegroundColor Yellow
                    }
                    
                    # Force replication if requested
                    if ($ForceReplication)
                    {
                        Write-Host "  ⚡ Forcing replication..." -ForegroundColor Yellow
                        
                        foreach ($Failure in $DCResult.ReplicationFailures)
                        {
                            try
                            {
                                & repadmin /replicate $DC $Failure.'Source DSA' $Failure.'Naming Context'
                                Write-Host "    ✓ Forced replication from $($Failure.'Source DSA')" -ForegroundColor Green
                            }
                            catch
                            {
                                Write-Host "    ✗ Failed to force replication from $($Failure.'Source DSA')" -ForegroundColor Red
                            }
                        }
                    }
                }
            }
            catch
            {
                $DCResult.OverallStatus = "Error"
                Write-Host "  ✗ Error checking replication: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            $ReplicationResults.Add($DCResult)
        }
        
        # Generate summary report
        $HealthyDCs = ($ReplicationResults | Where-Object OverallStatus -eq "Healthy").Count
        $FailedDCs = ($ReplicationResults | Where-Object OverallStatus -eq "Failed").Count
        $ErrorDCs = ($ReplicationResults | Where-Object OverallStatus -eq "Error").Count
        
        Write-Host "`nReplication Summary:" -ForegroundColor Cyan
        Write-Host "Healthy DCs: $HealthyDCs" -ForegroundColor Green
        Write-Host "Failed DCs: $FailedDCs" -ForegroundColor Red
        Write-Host "Error DCs: $ErrorDCs" -ForegroundColor Red
        
        if ($FailedDCs -gt 0 -or $ErrorDCs -gt 0)
        {
            Write-Host "`nRecommended Actions:" -ForegroundColor Yellow
            Write-Host "1. Check network connectivity between domain controllers" -ForegroundColor White
            Write-Host "2. Verify DNS configuration and resolution" -ForegroundColor White
            Write-Host "3. Check Windows Time Service synchronization" -ForegroundColor White
            Write-Host "4. Review event logs for detailed error information" -ForegroundColor White
            Write-Host "5. Consider running: dcdiag /test:replications" -ForegroundColor White
        }
        
        return $ReplicationResults
    }
    catch
    {
        Write-Error "Replication repair failed: $($_.Exception.Message)"
        throw
    }
}
```

## 📊 Performance Monitoring

### LDAP Query Performance

```powershell
# Monitor and optimize LDAP query performance
function Test-LDAPPerformance
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DomainController = (Get-ADDomainController).Name,
        
        [Parameter()]
        [int]$SampleQueries = 10,
        
        [Parameter()]
        [switch]$EnableDetailedLogging
    )
    
    try
    {
        Write-Host "Testing LDAP query performance on: $DomainController" -ForegroundColor Green
        
        $PerformanceResults = [System.Collections.Generic.List[object]]@()
        
        # Test queries of varying complexity
        $TestQueries = @(
            @{ Name = "Simple User Query"; Filter = "(&(objectClass=user)(sAMAccountName=*))" },
            @{ Name = "Complex User Query"; Filter = "(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(lastLogonTimestamp>=*))" },
            @{ Name = "Group Query"; Filter = "(&(objectClass=group)(groupType:1.2.840.113556.1.4.803:=2147483648))" },
            @{ Name = "Computer Query"; Filter = "(&(objectClass=computer)(operatingSystem=*))" },
            @{ Name = "Large Result Set"; Filter = "(&(objectClass=user))" }
        )
        
        foreach ($Query in $TestQueries)
        {
            Write-Host "Testing: $($Query.Name)" -ForegroundColor Cyan
            
            $QueryTimes = @()
            
            for ($i = 1; $i -le $SampleQueries; $i++)
            {
                try
                {
                    $StartTime = Get-Date
                    $Results = Get-ADObject -Filter $Query.Filter -Server $DomainController -ResultSetSize 1000
                    $EndTime = Get-Date
                    $Duration = ($EndTime - $StartTime).TotalMilliseconds
                    
                    $QueryTimes += $Duration
                    
                    if ($EnableDetailedLogging)
                    {
                        Write-Host "  Sample $i`: $Duration ms ($($Results.Count) results)" -ForegroundColor Gray
                    }
                }
                catch
                {
                    Write-Host "  Sample $i`: Failed - $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            if ($QueryTimes.Count -gt 0)
            {
                $PerformanceResult = [PSCustomObject]@{
                    QueryName = $Query.Name
                    QueryFilter = $Query.Filter
                    SampleCount = $QueryTimes.Count
                    AverageMs = [math]::Round(($QueryTimes | Measure-Object -Average).Average, 2)
                    MinimumMs = [math]::Round(($QueryTimes | Measure-Object -Minimum).Minimum, 2)
                    MaximumMs = [math]::Round(($QueryTimes | Measure-Object -Maximum).Maximum, 2)
                    StandardDeviation = if ($QueryTimes.Count -gt 1) { 
                        [math]::Round([math]::Sqrt((($QueryTimes | ForEach-Object { [math]::Pow($_ - ($QueryTimes | Measure-Object -Average).Average, 2) } | Measure-Object -Sum).Sum / ($QueryTimes.Count - 1))), 2)
                    } else { 0 }
                    PerformanceRating = ""
                }
                
                # Assign performance rating
                if ($PerformanceResult.AverageMs -lt 100) { $PerformanceResult.PerformanceRating = "Excellent" }
                elseif ($PerformanceResult.AverageMs -lt 500) { $PerformanceResult.PerformanceRating = "Good" }
                elseif ($PerformanceResult.AverageMs -lt 1000) { $PerformanceResult.PerformanceRating = "Fair" }
                else { $PerformanceResult.PerformanceRating = "Poor" }
                
                $PerformanceResults.Add($PerformanceResult)
                
                Write-Host "  Average: $($PerformanceResult.AverageMs) ms | Rating: $($PerformanceResult.PerformanceRating)" -ForegroundColor $(
                    switch ($PerformanceResult.PerformanceRating) {
                        "Excellent" { "Green" }
                        "Good" { "Green" }
                        "Fair" { "Yellow" }
                        "Poor" { "Red" }
                    }
                )
            }
        }
        
        # Generate recommendations
        Write-Host "`nPerformance Recommendations:" -ForegroundColor Cyan
        
        $PoorPerformance = $PerformanceResults | Where-Object PerformanceRating -eq "Poor"
        if ($PoorPerformance.Count -gt 0)
        {
            Write-Host "⚠ Poor performing queries detected:" -ForegroundColor Red
            $PoorPerformance | ForEach-Object {
                Write-Host "  - $($_.QueryName): $($_.AverageMs) ms average" -ForegroundColor Yellow
            }
            Write-Host "Recommendations:" -ForegroundColor Yellow
            Write-Host "  1. Review and optimize LDAP filters" -ForegroundColor White
            Write-Host "  2. Consider adding indexes for frequently queried attributes" -ForegroundColor White
            Write-Host "  3. Reduce result set sizes where possible" -ForegroundColor White
            Write-Host "  4. Check domain controller hardware resources" -ForegroundColor White
        }
        else
        {
            Write-Host "✓ All queries performing within acceptable ranges" -ForegroundColor Green
        }
        
        return $PerformanceResults
    }
    catch
    {
        Write-Error "LDAP performance test failed: $($_.Exception.Message)"
        throw
    }
}

# Example usage and documentation
Write-Host @"

ACTIVE DIRECTORY MAINTENANCE AND TROUBLESHOOTING GUIDE

Daily Maintenance:
• Run Invoke-ADDailyHealthCheck to monitor DC health
• Check service status, replication, disk space, and event logs
• Review and address any warnings or critical issues

Weekly Maintenance:
• Execute Invoke-ADWeeklyMaintenance for comprehensive checks
• Review FSMO role placement and health
• Analyze DNS configuration and scavenging
• Audit Group Policy objects and links
• Verify backup completion and status

Troubleshooting:
• Use Test-ADAuthentication for user login issues
• Run Repair-ADReplication for replication problems
• Execute Test-LDAPPerformance to identify query bottlenecks

Emergency Procedures:
• Domain Controller failure: Check FSMO roles and transfer if needed
• Replication failures: Force replication and check network connectivity
• Authentication issues: Verify account status, unlock accounts, check time sync
• DNS problems: Restart DNS service, check zone transfers, validate records

Performance Optimization:
• Monitor LDAP query performance regularly
• Optimize frequently used LDAP filters
• Ensure adequate hardware resources
• Implement proper site topology for WAN environments

Preventive Measures:
• Regular system backups including system state
• Monitor disk space on domain controllers
• Keep domain controllers patched and current
• Implement proper change management processes
• Document all configuration changes

"@ -ForegroundColor Green
