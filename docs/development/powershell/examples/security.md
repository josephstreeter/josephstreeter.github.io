---
title: PowerShell Security Examples
description: Practical PowerShell examples for security administration, compliance checking, and vulnerability assessment
author: Joseph Streeter
date: 2024-01-15
tags: [powershell, security, compliance, auditing, vulnerability-assessment]
---

This collection demonstrates PowerShell's capabilities for security administration, compliance checking, and vulnerability assessment. These examples follow enterprise security best practices and include proper error handling.

## Security Auditing

### User Account Security Audit

```powershell
<#
.SYNOPSIS
    Performs comprehensive user account security audit
.DESCRIPTION
    Audits Active Directory user accounts for security compliance,
    identifying potential security risks and policy violations
.EXAMPLE
    Invoke-UserSecurityAudit -Domain "contoso.com" -ReportPath "C:\Reports"
#>
function Invoke-UserSecurityAudit
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$ReportPath
    )
    
    try
    {
        Write-Verbose "Starting user security audit for domain: $Domain"
        
        # Import Active Directory module
        Import-Module ActiveDirectory -ErrorAction Stop
        
        $AuditResults = [System.Collections.Generic.List[object]]@()
        $ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        
        # Get all enabled user accounts
        $Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties *
        
        foreach ($User in $Users)
        {
            $SecurityIssues = [System.Collections.Generic.List[string]]@()
            
            # Check password policy compliance
            if ($User.PasswordNeverExpires)
            {
                $SecurityIssues.Add("Password never expires")
            }
            
            if ($User.PasswordNotRequired)
            {
                $SecurityIssues.Add("Password not required")
            }
            
            # Check account settings
            if ($User.AccountNotDelegated -eq $false -and $User.AdminCount -gt 0)
            {
                $SecurityIssues.Add("Privileged account allows delegation")
            }
            
            if ($User.TrustedForDelegation)
            {
                $SecurityIssues.Add("Account trusted for delegation")
            }
            
            # Check login times
            $LastLogon = [DateTime]::FromFileTime($User.LastLogonTimestamp)
            $DaysSinceLogon = (Get-Date) - $LastLogon
            
            if ($DaysSinceLogon.Days -gt 90)
            {
                $SecurityIssues.Add("No logon in 90+ days")
            }
            
            # Check group memberships
            $Groups = Get-ADPrincipalGroupMembership $User.SamAccountName
            $PrivilegedGroups = $Groups | Where-Object {
                $_.Name -match "Admin|Domain|Enterprise|Schema"
            }
            
            if ($PrivilegedGroups.Count -gt 0)
            {
                $SecurityIssues.Add("Member of privileged groups: $($PrivilegedGroups.Name -join ', ')")
            }
            
            # Create audit result object
            $AuditResult = [PSCustomObject]@{
                UserName = $User.SamAccountName
                DisplayName = $User.DisplayName
                Enabled = $User.Enabled
                LastLogon = $LastLogon
                PasswordLastSet = $User.PasswordLastSet
                PasswordExpired = $User.PasswordExpired
                LockedOut = $User.LockedOut
                SecurityIssues = $SecurityIssues -join '; '
                IssueCount = $SecurityIssues.Count
                Department = $User.Department
                Manager = $User.Manager
            }
            
            $AuditResults.Add($AuditResult)
        }
        
        # Generate reports
        $CriticalIssues = $AuditResults | Where-Object { $_.IssueCount -gt 0 }
        
        # Export detailed report
        $DetailedReportPath = Join-Path $ReportPath "UserSecurityAudit_$ReportDate.csv"
        $AuditResults | Export-Csv -Path $DetailedReportPath -NoTypeInformation
        
        # Generate summary report
        $SummaryReport = @{
            TotalUsers = $AuditResults.Count
            UsersWithIssues = $CriticalIssues.Count
            PasswordNeverExpires = ($AuditResults | Where-Object { $_.SecurityIssues -like "*never expires*" }).Count
            InactiveUsers = ($AuditResults | Where-Object { $_.SecurityIssues -like "*No logon*" }).Count
            PrivilegedUsers = ($AuditResults | Where-Object { $_.SecurityIssues -like "*privileged groups*" }).Count
        }
        
        $SummaryReportPath = Join-Path $ReportPath "UserSecuritySummary_$ReportDate.json"
        $SummaryReport | ConvertTo-Json | Out-File -FilePath $SummaryReportPath
        
        Write-Host "Audit completed successfully!" -ForegroundColor Green
        Write-Host "Detailed report: $DetailedReportPath" -ForegroundColor Cyan
        Write-Host "Summary report: $SummaryReportPath" -ForegroundColor Cyan
        Write-Host "Users with security issues: $($CriticalIssues.Count) of $($AuditResults.Count)" -ForegroundColor Yellow
        
        return $AuditResults
    }
    catch
    {
        Write-Error "User security audit failed: $($_.Exception.Message)"
        throw
    }
}
```

### System Vulnerability Assessment

```powershell
<#
.SYNOPSIS
    Performs system vulnerability assessment
.DESCRIPTION
    Checks Windows systems for common security vulnerabilities,
    missing patches, and security configuration issues
.EXAMPLE
    Invoke-VulnerabilityAssessment -ComputerName "Server01" -OutputPath "C:\Security"
#>
function Invoke-VulnerabilityAssessment
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$OutputPath = "C:\Temp"
    )
    
    begin
    {
        $VulnerabilityResults = [System.Collections.Generic.List[object]]@()
        $ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    }
    
    process
    {
        foreach ($Computer in $ComputerName)
        {
            try
            {
                Write-Verbose "Assessing vulnerabilities on: $Computer"
                
                $Session = if ($Computer -eq $env:COMPUTERNAME)
                {
                    $null
                }
                else
                {
                    New-PSSession -ComputerName $Computer -ErrorAction Stop
                }
                
                $ScriptBlock = {
                    $Results = @{}
                    
                    # Check Windows version and support status
                    $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
                    $Results.OperatingSystem = $OSInfo.Caption
                    $Results.Version = $OSInfo.Version
                    $Results.BuildNumber = $OSInfo.BuildNumber
                    
                    # Check for missing security updates
                    try
                    {
                        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                        $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software' and CategoryIDs contains '0fa1201d-4330-4fa8-8ae9-b877473b6441'")
                        $Results.MissingSecurityUpdates = $SearchResult.Updates.Count
                        $Results.SecurityUpdateTitles = @($SearchResult.Updates | ForEach-Object { $_.Title })
                    }
                    catch
                    {
                        $Results.MissingSecurityUpdates = "Unable to check"
                        $Results.SecurityUpdateTitles = @()
                    }
                    
                    # Check UAC configuration
                    $UACSettings = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue
                    $Results.UACEnabled = $UACSettings.EnableLUA -eq 1
                    $Results.UACPromptLevel = $UACSettings.ConsentPromptBehaviorAdmin
                    
                    # Check Windows Defender status
                    try
                    {
                        $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
                        $Results.DefenderEnabled = $DefenderStatus.AntivirusEnabled
                        $Results.DefenderUpToDate = $DefenderStatus.AntivirusSignatureLastUpdated -gt (Get-Date).AddDays(-7)
                        $Results.RealTimeProtection = $DefenderStatus.RealTimeProtectionEnabled
                    }
                    catch
                    {
                        $Results.DefenderEnabled = "Unable to check"
                        $Results.DefenderUpToDate = "Unable to check"
                        $Results.RealTimeProtection = "Unable to check"
                    }
                    
                    # Check firewall status
                    try
                    {
                        $FirewallProfiles = Get-NetFirewallProfile
                        $Results.FirewallDomain = ($FirewallProfiles | Where-Object Name -eq "Domain").Enabled
                        $Results.FirewallPrivate = ($FirewallProfiles | Where-Object Name -eq "Private").Enabled
                        $Results.FirewallPublic = ($FirewallProfiles | Where-Object Name -eq "Public").Enabled
                    }
                    catch
                    {
                        $Results.FirewallDomain = "Unable to check"
                        $Results.FirewallPrivate = "Unable to check"
                        $Results.FirewallPublic = "Unable to check"
                    }
                    
                    # Check for unnecessary services
                    $UnnecessaryServices = @(
                        "Telnet", "FTP", "SNMP", "RemoteRegistry", "Browser"
                    )
                    
                    $RunningUnnecessaryServices = @()
                    foreach ($ServiceName in $UnnecessaryServices)
                    {
                        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
                        if ($Service -and $Service.Status -eq "Running")
                        {
                            $RunningUnnecessaryServices += $ServiceName
                        }
                    }
                    $Results.UnnecessaryServices = $RunningUnnecessaryServices
                    
                    # Check for weak passwords (requires additional tools in real scenarios)
                    $Results.PasswordPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
                    
                    # Check BitLocker status
                    try
                    {
                        $BitLockerVolumes = Get-BitLockerVolume
                        $SystemVolume = $BitLockerVolumes | Where-Object MountPoint -eq "C:"
                        $Results.BitLockerEnabled = $SystemVolume.ProtectionStatus -eq "On"
                        $Results.BitLockerEncryption = $SystemVolume.EncryptionPercentage
                    }
                    catch
                    {
                        $Results.BitLockerEnabled = "Unable to check"
                        $Results.BitLockerEncryption = "Unable to check"
                    }
                    
                    return $Results
                }
                
                if ($Session)
                {
                    $AssessmentData = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
                    Remove-PSSession $Session
                }
                else
                {
                    $AssessmentData = & $ScriptBlock
                }
                
                # Calculate vulnerability score
                $VulnerabilityScore = 0
                $Issues = [System.Collections.Generic.List[string]]@()
                
                if ($AssessmentData.MissingSecurityUpdates -gt 0)
                {
                    $VulnerabilityScore += 30
                    $Issues.Add("Missing $($AssessmentData.MissingSecurityUpdates) security updates")
                }
                
                if (-not $AssessmentData.UACEnabled)
                {
                    $VulnerabilityScore += 20
                    $Issues.Add("UAC disabled")
                }
                
                if (-not $AssessmentData.DefenderEnabled)
                {
                    $VulnerabilityScore += 25
                    $Issues.Add("Windows Defender disabled")
                }
                
                if (-not $AssessmentData.DefenderUpToDate)
                {
                    $VulnerabilityScore += 15
                    $Issues.Add("Outdated antivirus signatures")
                }
                
                if (-not $AssessmentData.FirewallPublic)
                {
                    $VulnerabilityScore += 20
                    $Issues.Add("Public firewall disabled")
                }
                
                if ($AssessmentData.UnnecessaryServices.Count -gt 0)
                {
                    $VulnerabilityScore += 10
                    $Issues.Add("Unnecessary services running: $($AssessmentData.UnnecessaryServices -join ', ')")
                }
                
                if (-not $AssessmentData.BitLockerEnabled)
                {
                    $VulnerabilityScore += 15
                    $Issues.Add("BitLocker not enabled")
                }
                
                # Create vulnerability report object
                $VulnerabilityReport = [PSCustomObject]@{
                    ComputerName = $Computer
                    AssessmentDate = Get-Date
                    VulnerabilityScore = $VulnerabilityScore
                    RiskLevel = switch ($VulnerabilityScore)
                    {
                        { $_ -lt 25 } { "Low" }
                        { $_ -lt 50 } { "Medium" }
                        { $_ -lt 75 } { "High" }
                        default { "Critical" }
                    }
                    OperatingSystem = $AssessmentData.OperatingSystem
                    Version = $AssessmentData.Version
                    BuildNumber = $AssessmentData.BuildNumber
                    MissingSecurityUpdates = $AssessmentData.MissingSecurityUpdates
                    UACEnabled = $AssessmentData.UACEnabled
                    DefenderEnabled = $AssessmentData.DefenderEnabled
                    DefenderUpToDate = $AssessmentData.DefenderUpToDate
                    FirewallStatus = "$($AssessmentData.FirewallDomain)/$($AssessmentData.FirewallPrivate)/$($AssessmentData.FirewallPublic)"
                    BitLockerEnabled = $AssessmentData.BitLockerEnabled
                    SecurityIssues = $Issues -join '; '
                    IssueCount = $Issues.Count
                }
                
                $VulnerabilityResults.Add($VulnerabilityReport)
                
                Write-Host "Assessment completed for $Computer - Risk Level: $($VulnerabilityReport.RiskLevel)" -ForegroundColor $(
                    switch ($VulnerabilityReport.RiskLevel)
                    {
                        "Low" { "Green" }
                        "Medium" { "Yellow" }
                        "High" { "Red" }
                        "Critical" { "Magenta" }
                    }
                )
            }
            catch
            {
                Write-Error "Vulnerability assessment failed for $Computer`: $($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        if ($VulnerabilityResults.Count -gt 0)
        {
            # Export detailed report
            $ReportPath = Join-Path $OutputPath "VulnerabilityAssessment_$ReportDate.csv"
            $VulnerabilityResults | Export-Csv -Path $ReportPath -NoTypeInformation
            
            # Generate summary
            $Summary = @{
                TotalSystems = $VulnerabilityResults.Count
                LowRisk = ($VulnerabilityResults | Where-Object RiskLevel -eq "Low").Count
                MediumRisk = ($VulnerabilityResults | Where-Object RiskLevel -eq "Medium").Count
                HighRisk = ($VulnerabilityResults | Where-Object RiskLevel -eq "High").Count
                CriticalRisk = ($VulnerabilityResults | Where-Object RiskLevel -eq "Critical").Count
                AverageScore = [math]::Round(($VulnerabilityResults | Measure-Object VulnerabilityScore -Average).Average, 2)
            }
            
            Write-Host "`nVulnerability Assessment Summary:" -ForegroundColor Cyan
            Write-Host "Total Systems: $($Summary.TotalSystems)" -ForegroundColor White
            Write-Host "Low Risk: $($Summary.LowRisk)" -ForegroundColor Green
            Write-Host "Medium Risk: $($Summary.MediumRisk)" -ForegroundColor Yellow
            Write-Host "High Risk: $($Summary.HighRisk)" -ForegroundColor Red
            Write-Host "Critical Risk: $($Summary.CriticalRisk)" -ForegroundColor Magenta
            Write-Host "Average Score: $($Summary.AverageScore)" -ForegroundColor White
            Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
        }
        
        return $VulnerabilityResults
    }
}
```

## Compliance Automation

### STIG Compliance Checker

```powershell
<#
.SYNOPSIS
    Checks system compliance against STIG (Security Technical Implementation Guide) requirements
.DESCRIPTION
    Automates STIG compliance checking for Windows systems,
    providing detailed reports and remediation recommendations
.EXAMPLE
    Test-STIGCompliance -ComputerName "Server01" -STIGProfile "Windows2019"
#>
function Test-STIGCompliance
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [ValidateSet("Windows2019", "Windows2016", "Windows10", "IIS")]
        [string]$STIGProfile = "Windows2019",
        
        [Parameter()]
        [string]$ReportPath = "C:\STIGReports"
    )
    
    begin
    {
        # Create report directory if it doesn't exist
        if (-not (Test-Path $ReportPath))
        {
            New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        }
        
        # Define STIG check configurations
        $STIGChecks = @{
            "V-93149" = @{
                Title = "Account lockout threshold must be configured"
                Check = { 
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.LockoutThreshold -le 3 -and $Policy.LockoutThreshold -gt 0
                }
                Severity = "Medium"
                Category = "Account Management"
            }
            "V-93151" = @{
                Title = "Account lockout duration must be configured"
                Check = {
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.LockoutDuration.TotalMinutes -ge 15
                }
                Severity = "Medium"
                Category = "Account Management"
            }
            "V-93153" = @{
                Title = "Password history must be configured"
                Check = {
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.PasswordHistoryCount -ge 24
                }
                Severity = "Medium"
                Category = "Account Management"
            }
            "V-93155" = @{
                Title = "Minimum password age must be configured"
                Check = {
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.MinPasswordAge.TotalDays -ge 1
                }
                Severity = "Low"
                Category = "Account Management"
            }
            "V-93157" = @{
                Title = "Maximum password age must be configured"
                Check = {
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.MaxPasswordAge.TotalDays -le 60 -and $Policy.MaxPasswordAge.TotalDays -gt 0
                }
                Severity = "Medium"
                Category = "Account Management"
            }
            "V-93159" = @{
                Title = "Minimum password length must be configured"
                Check = {
                    $Policy = Get-ADDefaultDomainPasswordPolicy
                    return $Policy.MinPasswordLength -ge 14
                }
                Severity = "High"
                Category = "Account Management"
            }
        }
        
        $ComplianceResults = [System.Collections.Generic.List[object]]@()
    }
    
    process
    {
        foreach ($Computer in $ComputerName)
        {
            try
            {
                Write-Verbose "Checking STIG compliance for: $Computer"
                
                $Session = if ($Computer -eq $env:COMPUTERNAME)
                {
                    $null
                }
                else
                {
                    New-PSSession -ComputerName $Computer -ErrorAction Stop
                }
                
                foreach ($CheckID in $STIGChecks.Keys)
                {
                    $Check = $STIGChecks[$CheckID]
                    
                    try
                    {
                        $ScriptBlock = $Check.Check
                        
                        if ($Session)
                        {
                            $Result = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
                        }
                        else
                        {
                            $Result = & $ScriptBlock
                        }
                        
                        $ComplianceResult = [PSCustomObject]@{
                            ComputerName = $Computer
                            CheckDate = Get-Date
                            STIGProfile = $STIGProfile
                            CheckID = $CheckID
                            Title = $Check.Title
                            Category = $Check.Category
                            Severity = $Check.Severity
                            Compliant = $Result
                            Status = if ($Result) { "Pass" } else { "Fail" }
                            Details = if (-not $Result) { "Non-compliant with STIG requirement" } else { "Compliant" }
                        }
                        
                        $ComplianceResults.Add($ComplianceResult)
                    }
                    catch
                    {
                        $ComplianceResult = [PSCustomObject]@{
                            ComputerName = $Computer
                            CheckDate = Get-Date
                            STIGProfile = $STIGProfile
                            CheckID = $CheckID
                            Title = $Check.Title
                            Category = $Check.Category
                            Severity = $Check.Severity
                            Compliant = $false
                            Status = "Error"
                            Details = "Check failed: $($_.Exception.Message)"
                        }
                        
                        $ComplianceResults.Add($ComplianceResult)
                    }
                }
                
                if ($Session)
                {
                    Remove-PSSession $Session
                }
            }
            catch
            {
                Write-Error "STIG compliance check failed for $Computer`: $($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        if ($ComplianceResults.Count -gt 0)
        {
            $ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $ReportFile = Join-Path $ReportPath "STIGCompliance_$($STIGProfile)_$ReportDate.csv"
            
            # Export detailed report
            $ComplianceResults | Export-Csv -Path $ReportFile -NoTypeInformation
            
            # Generate compliance summary
            $Summary = @{
                TotalChecks = $ComplianceResults.Count
                PassedChecks = ($ComplianceResults | Where-Object Status -eq "Pass").Count
                FailedChecks = ($ComplianceResults | Where-Object Status -eq "Fail").Count
                ErrorChecks = ($ComplianceResults | Where-Object Status -eq "Error").Count
                CompliancePercentage = [math]::Round((($ComplianceResults | Where-Object Status -eq "Pass").Count / $ComplianceResults.Count) * 100, 2)
                HighSeverityFailures = ($ComplianceResults | Where-Object { $_.Status -eq "Fail" -and $_.Severity -eq "High" }).Count
                MediumSeverityFailures = ($ComplianceResults | Where-Object { $_.Status -eq "Fail" -and $_.Severity -eq "Medium" }).Count
                LowSeverityFailures = ($ComplianceResults | Where-Object { $_.Status -eq "Fail" -and $_.Severity -eq "Low" }).Count
            }
            
            Write-Host "`nSTIG Compliance Summary ($STIGProfile):" -ForegroundColor Cyan
            Write-Host "Overall Compliance: $($Summary.CompliancePercentage)%" -ForegroundColor $(
                if ($Summary.CompliancePercentage -ge 90) { "Green" }
                elseif ($Summary.CompliancePercentage -ge 75) { "Yellow" }
                else { "Red" }
            )
            Write-Host "Total Checks: $($Summary.TotalChecks)" -ForegroundColor White
            Write-Host "Passed: $($Summary.PassedChecks)" -ForegroundColor Green
            Write-Host "Failed: $($Summary.FailedChecks)" -ForegroundColor Red
            Write-Host "Errors: $($Summary.ErrorChecks)" -ForegroundColor Yellow
            Write-Host "High Severity Failures: $($Summary.HighSeverityFailures)" -ForegroundColor Red
            Write-Host "Medium Severity Failures: $($Summary.MediumSeverityFailures)" -ForegroundColor Yellow
            Write-Host "Low Severity Failures: $($Summary.LowSeverityFailures)" -ForegroundColor Green
            Write-Host "Report saved to: $ReportFile" -ForegroundColor Cyan
        }
        
        return $ComplianceResults
    }
}
```

## Security Monitoring

### Event Log Security Monitor

```powershell
<#
.SYNOPSIS
    Monitors Windows Event Logs for security-related events
.DESCRIPTION
    Continuously monitors security events and generates alerts
    for suspicious activities and security violations
.EXAMPLE
    Start-SecurityEventMonitor -AlertEmail "admin@company.com" -MonitorDuration 3600
#>
function Start-SecurityEventMonitor
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [string]$AlertEmail,
        
        [Parameter()]
        [int]$MonitorDuration = 3600, # 1 hour default
        
        [Parameter()]
        [string]$LogPath = "C:\SecurityLogs"
    )
    
    # Security event IDs to monitor
    $CriticalEvents = @{
        4625 = "Failed logon attempt"
        4648 = "Logon with explicit credentials"
        4656 = "Handle to object requested"
        4728 = "Member added to security-enabled global group"
        4732 = "Member added to security-enabled local group"
        4756 = "Member added to security-enabled universal group"
        5140 = "Network share accessed"
        5142 = "Network share added"
        5144 = "Network share deleted"
    }
    
    try
    {
        Write-Host "Starting security event monitoring..." -ForegroundColor Green
        Write-Host "Duration: $MonitorDuration seconds" -ForegroundColor Cyan
        Write-Host "Log path: $LogPath" -ForegroundColor Cyan
        
        if (-not (Test-Path $LogPath))
        {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        $StartTime = Get-Date
        $EndTime = $StartTime.AddSeconds($MonitorDuration)
        $EventCount = 0
        $AlertCount = 0
        
        do
        {
            foreach ($Computer in $ComputerName)
            {
                try
                {
                    # Get recent security events
                    $Events = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                        LogName = 'Security'
                        StartTime = (Get-Date).AddMinutes(-5)
                        ID = $CriticalEvents.Keys
                    } -ErrorAction SilentlyContinue
                    
                    foreach ($Event in $Events)
                    {
                        $EventCount++
                        
                        # Parse event details
                        $EventData = @{
                            Computer = $Computer
                            TimeCreated = $Event.TimeCreated
                            EventID = $Event.Id
                            Description = $CriticalEvents[$Event.Id]
                            Level = $Event.LevelDisplayName
                            Message = $Event.Message
                            UserId = $Event.UserId
                            UserName = try { (New-Object System.Security.Principal.SecurityIdentifier($Event.UserId)).Translate([System.Security.Principal.NTAccount]).Value } catch { "Unknown" }
                        }
                        
                        # Log event
                        $LogEntry = [PSCustomObject]$EventData
                        $LogFile = Join-Path $LogPath "SecurityEvents_$(Get-Date -Format 'yyyy-MM-dd').csv"
                        $LogEntry | Export-Csv -Path $LogFile -Append -NoTypeInformation
                        
                        # Check for alert conditions
                        $ShouldAlert = $false
                        $AlertReason = ""
                        
                        switch ($Event.Id)
                        {
                            4625 
                            {
                                # Multiple failed logons
                                $RecentFailures = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                                    LogName = 'Security'
                                    StartTime = (Get-Date).AddMinutes(-10)
                                    ID = 4625
                                } -ErrorAction SilentlyContinue
                                
                                if ($RecentFailures.Count -gt 5)
                                {
                                    $ShouldAlert = $true
                                    $AlertReason = "Multiple failed logon attempts detected"
                                }
                            }
                            4728 
                            {
                                $ShouldAlert = $true
                                $AlertReason = "User added to security group"
                            }
                            4732 
                            {
                                $ShouldAlert = $true
                                $AlertReason = "User added to local administrators group"
                            }
                        }
                        
                        if ($ShouldAlert)
                        {
                            $AlertCount++
                            $AlertMessage = @"
SECURITY ALERT

Time: $($Event.TimeCreated)
Computer: $Computer
Event: $($CriticalEvents[$Event.Id])
User: $($EventData.UserName)
Reason: $AlertReason

Event Details:
$($Event.Message)
"@
                            
                            Write-Warning $AlertMessage
                            
                            if ($AlertEmail)
                            {
                                try
                                {
                                    Send-MailMessage -To $AlertEmail -Subject "Security Alert - $Computer" -Body $AlertMessage -SmtpServer "smtp.company.com" -ErrorAction Stop
                                }
                                catch
                                {
                                    Write-Warning "Failed to send email alert: $($_.Exception.Message)"
                                }
                            }
                        }
                        else
                        {
                            Write-Host "[$($Event.TimeCreated)] $Computer - $($CriticalEvents[$Event.Id])" -ForegroundColor Yellow
                        }
                    }
                }
                catch
                {
                    Write-Warning "Failed to monitor $Computer`: $($_.Exception.Message)"
                }
            }
            
            Start-Sleep -Seconds 30
            
        } while ((Get-Date) -lt $EndTime)
        
        Write-Host "`nMonitoring completed!" -ForegroundColor Green
        Write-Host "Total events processed: $EventCount" -ForegroundColor Cyan
        Write-Host "Alerts generated: $AlertCount" -ForegroundColor Yellow
        Write-Host "Logs saved to: $LogPath" -ForegroundColor Cyan
    }
    catch
    {
        Write-Error "Security monitoring failed: $($_.Exception.Message)"
        throw
    }
}

# Usage Examples
Write-Host @"

SECURITY POWERSHELL EXAMPLES

1. User Security Audit:
   Invoke-UserSecurityAudit -Domain "contoso.com" -ReportPath "C:\Reports"

2. Vulnerability Assessment:
   Invoke-VulnerabilityAssessment -ComputerName "Server01","Server02" -OutputPath "C:\Security"

3. STIG Compliance Check:
   Test-STIGCompliance -ComputerName "Server01" -STIGProfile "Windows2019"

4. Security Event Monitoring:
   Start-SecurityEventMonitor -AlertEmail "admin@company.com" -MonitorDuration 7200

These examples demonstrate PowerShell's capabilities for:
- Automated security auditing
- Vulnerability assessment
- Compliance checking
- Real-time security monitoring

All functions include proper error handling, parameter validation,
and comprehensive reporting capabilities.

"@ -ForegroundColor Green
```
