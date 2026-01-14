---
title: Windows Infrastructure Security (Advanced)
description: Comprehensive security hardening guide for Windows Server infrastructure including domain controllers, member servers, and workstations
author: Joseph Streeter
ms.author: jstreeter
ms.date: 2024-12-30
ms.topic: article
ms.service: windows-server
keywords: Windows Server security, hardening, domain security, infrastructure security, compliance, CIS, STIG
uid: docs.infrastructure.windows.security.advanced
---

Windows Infrastructure Security provides comprehensive guidance for securing Windows-based infrastructure components including domain controllers, member servers, and workstations against modern threats.

## Security Architecture Overview

### Defense in Depth Model

```text
┌─────────────────────────────────────────────────────────────────┐
│                Windows Security Layers                          │
├─────────────────────────────────────────────────────────────────┤
│  Layer              │ Components                                │
│  ├─ Physical        │ Hardware Security, TPM, Secure Boot       │
│  ├─ Network         │ Firewall, IPSec, Network Segmentation     │
│  ├─ Host            │ OS Hardening, AV, HIPS                    │
│  ├─ Application     │ Code Signing, AppLocker, WDAC             │
│  ├─ Data            │ Encryption, DLP, Rights Management        │
│  └─ Identity        │ MFA, Privileged Access, Account Policy    │
└─────────────────────────────────────────────────────────────────┘
```

### Security Framework Components

- **Endpoint Protection**: Anti-malware, behavior analysis, threat detection
- **Access Control**: RBAC, privilege management, authentication
- **Data Protection**: Encryption at rest and in transit, DLP
- **Network Security**: Segmentation, monitoring, traffic analysis
- **Compliance**: Policy enforcement, auditing, reporting

## Domain Controller Security Hardening

### Advanced Security Configuration

```powershell
<#
.SYNOPSIS
    Advanced Domain Controller security hardening automation.
.DESCRIPTION
    Implements comprehensive security controls for domain controllers
    including advanced threat protection, compliance settings, and monitoring.
#>

function Set-DomainControllerSecurityBaseline {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DomainControllers = @(),
        
        [Parameter()]
        [switch]$ApplyAdvancedProtection,
        
        [Parameter()]
        [string]$ComplianceProfile = "STIG",
        
        [Parameter()]
        [string]$LogPath = "C:\Security\Logs\DC-Hardening.log"
    )
    
    if ($DomainControllers.Count -eq 0) {
        $DomainControllers = (Get-ADDomainController -Filter *).Name
    }
    
    $SecurityBaseline = @{
        # Account Policies
        PasswordPolicy = @{
            MinimumPasswordLength = 14
            PasswordComplexity = $true
            MaximumPasswordAge = 60
            MinimumPasswordAge = 1
            PasswordHistoryCount = 24
            LockoutThreshold = 5
            LockoutDuration = 30
            ResetLockoutCounterAfter = 30
        }
        
        # Audit Policies
        AuditPolicy = @{
            AccountLogon = "Success,Failure"
            AccountManagement = "Success,Failure"
            DirectoryServiceAccess = "Success,Failure"
            LogonEvents = "Success,Failure"
            ObjectAccess = "Success,Failure"
            PolicyChange = "Success,Failure"
            PrivilegeUse = "Success,Failure"
            ProcessTracking = "Success"
            SystemEvents = "Success,Failure"
        }
        
        # Security Options
        SecurityOptions = @{
            "Network access: Do not allow anonymous enumeration of SAM accounts" = "Enabled"
            "Network access: Do not allow anonymous enumeration of SAM accounts and shares" = "Enabled"
            "Network access: Restrict anonymous access to Named Pipes and Shares" = "Enabled"
            "Network security: Do not store LAN Manager hash value on next password change" = "Enabled"
            "Network security: LAN Manager authentication level" = "Send NTLMv2 response only. Refuse LM & NTLM"
            "Network security: Minimum session security for NTLM SSP based clients" = "Require NTLMv2 session security, Require 128-bit encryption"
            "Network security: Minimum session security for NTLM SSP based servers" = "Require NTLMv2 session security, Require 128-bit encryption"
            "Interactive logon: Do not display last user name" = "Enabled"
            "Interactive logon: Do not require CTRL+ALT+DEL" = "Disabled"
            "Interactive logon: Prompt user to change password before expiration" = "14 days"
            "Microsoft network client: Digitally sign communications (always)" = "Enabled"
            "Microsoft network server: Digitally sign communications (always)" = "Enabled"
            "Domain controller: Allow server operators to schedule tasks" = "Disabled"
            "Domain controller: LDAP server signing requirements" = "Require signing"
            "Domain controller: Refuse machine account password changes" = "Disabled"
        }
        
        # Services Configuration
        Services = @{
            "Disabled" = @(
                "Fax", "WebClient", "Telephony", "RemoteRegistry",
                "TermService", "TapiSrv", "WinRM"
            )
            "Manual" = @(
                "BITS", "Browser", "CertPropSvc", "ClipSrv",
                "CryptSvc", "Dhcp", "dmserver", "Dnscache"
            )
        }
        
        # Registry Security
        RegistrySettings = @{
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\RestrictAnonymous" = 2
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\RestrictAnonymousSAM" = 1
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\NoLMHash" = 1
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\LmCompatibilityLevel" = 5
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\MSV1_0\NTLMMinClientSec" = 0x20080000
            "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\MSV1_0\NTLMMinServerSec" = 0x20080000
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\DisablePasswordChange" = 0
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\MaximumPasswordAge" = 30
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\RequireSignOrSeal" = 1
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\RequireStrongKey" = 1
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\SealSecureChannel" = 1
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\SignSecureChannel" = 1
        }
    }
    
    foreach ($DC in $DomainControllers) {
        Write-Log "Starting security hardening for DC: $DC" -LogPath $LogPath
        
        try {
            # Apply security baseline
            Invoke-Command -ComputerName $DC -ScriptBlock {
                param($Baseline, $ApplyAdvanced)
                
                # Configure password policy
                secedit /export /cfg C:\temp\current.cfg /quiet
                $SecurityTemplate = Get-Content C:\temp\current.cfg
                
                # Modify security template with baseline settings
                $ModifiedTemplate = $SecurityTemplate | ForEach-Object {
                    $line = $_
                    
                    # Password policy settings
                    if ($line -match "MinimumPasswordLength") {
                        "MinimumPasswordLength = $($Baseline.PasswordPolicy.MinimumPasswordLength)"
                    }
                    elseif ($line -match "PasswordComplexity") {
                        "PasswordComplexity = $($Baseline.PasswordPolicy.PasswordComplexity ? 1 : 0)"
                    }
                    elseif ($line -match "MaximumPasswordAge") {
                        "MaximumPasswordAge = $($Baseline.PasswordPolicy.MaximumPasswordAge)"
                    }
                    elseif ($line -match "MinimumPasswordAge") {
                        "MinimumPasswordAge = $($Baseline.PasswordPolicy.MinimumPasswordAge)"
                    }
                    elseif ($line -match "PasswordHistorySize") {
                        "PasswordHistorySize = $($Baseline.PasswordPolicy.PasswordHistoryCount)"
                    }
                    elseif ($line -match "LockoutBadCount") {
                        "LockoutBadCount = $($Baseline.PasswordPolicy.LockoutThreshold)"
                    }
                    elseif ($line -match "LockoutDuration") {
                        "LockoutDuration = $($Baseline.PasswordPolicy.LockoutDuration * 60)"
                    }
                    elseif ($line -match "ResetLockoutCount") {
                        "ResetLockoutCount = $($Baseline.PasswordPolicy.ResetLockoutCounterAfter * 60)"
                    }
                    else {
                        $line
                    }
                }
                
                # Apply modified template
                $ModifiedTemplate | Out-File -FilePath C:\temp\security.cfg -Encoding ASCII
                secedit /configure /db C:\temp\security.sdb /cfg C:\temp\security.cfg /quiet
                
                # Configure audit policies
                foreach ($Policy in $Baseline.AuditPolicy.GetEnumerator()) {
                    auditpol /set /category:"$($Policy.Key)" /success:enable /failure:enable
                }
                
                # Configure registry settings
                foreach ($Setting in $Baseline.RegistrySettings.GetEnumerator()) {
                    $Path = Split-Path $Setting.Key
                    $Name = Split-Path $Setting.Key -Leaf
                    
                    if (!(Test-Path $Path)) {
                        New-Item -Path $Path -Force | Out-Null
                    }
                    
                    Set-ItemProperty -Path $Path -Name $Name -Value $Setting.Value -Force
                }
                
                # Configure services
                foreach ($Service in $Baseline.Services.Disabled) {
                    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
                        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
                    }
                }
                
                foreach ($Service in $Baseline.Services.Manual) {
                    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
                        Set-Service -Name $Service -StartupType Manual -ErrorAction SilentlyContinue
                    }
                }
                
                # Clean up temporary files
                Remove-Item C:\temp\current.cfg -ErrorAction SilentlyContinue
                Remove-Item C:\temp\security.cfg -ErrorAction SilentlyContinue
                Remove-Item C:\temp\security.sdb -ErrorAction SilentlyContinue
                
            } -ArgumentList $SecurityBaseline, $ApplyAdvancedProtection
            
            # Configure Windows Defender Advanced Threat Protection
            if ($ApplyAdvancedProtection) {
                Enable-AdvancedThreatProtection -ComputerName $DC
            }
            
            # Configure Windows Event Forwarding
            Configure-WindowsEventForwarding -ComputerName $DC
            
            Write-Log "Security hardening completed for DC: $DC" -LogPath $LogPath -Level "Success"
        }
        catch {
            Write-Log "Failed to harden DC $DC : $($_.Exception.Message)" -LogPath $LogPath -Level "Error"
        }
    }
}

function Enable-AdvancedThreatProtection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        # Enable Windows Defender Advanced Threat Protection
        try {
            # Configure real-time protection
            Set-MpPreference -DisableRealtimeMonitoring $false
            Set-MpPreference -DisableBehaviorMonitoring $false
            Set-MpPreference -DisableBlockAtFirstSeen $false
            Set-MpPreference -DisableIOAVProtection $false
            Set-MpPreference -DisableScriptScanning $false
            
            # Configure cloud protection
            Set-MpPreference -MAPSReporting Advanced
            Set-MpPreference -SubmitSamplesConsent SendAllSamples
            
            # Configure attack surface reduction rules
            $ASRRules = @{
                "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550" = "Enabled"  # Block executable content from email client and webmail
                "D4F940AB-401B-4EFC-AADC-AD5F3C50688A" = "Enabled"  # Block all Office applications from creating child processes
                "3B576869-A4EC-4529-8536-B80A7769E899" = "Enabled"  # Block Office applications from creating executable content
                "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84" = "Enabled"  # Block Office applications from injecting code into other processes
                "D3E037E1-3EB8-44C8-A917-57927947596D" = "Enabled"  # Block JavaScript or VBScript from launching downloaded executable content
                "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC" = "Enabled"  # Block execution of potentially obfuscated scripts
                "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B" = "Enabled"  # Block Win32 API calls from Office macros
            }
            
            foreach ($Rule in $ASRRules.GetEnumerator()) {
                Add-MpPreference -AttackSurfaceReductionRules_Ids $Rule.Key -AttackSurfaceReductionRules_Actions Enabled
            }
            
            # Configure controlled folder access
            Set-MpPreference -EnableControlledFolderAccess Enabled
            
            # Add critical system folders to protected list
            $ProtectedFolders = @(
                "C:\Windows\System32",
                "C:\Windows\SysWOW64",
                "C:\Program Files",
                "C:\Program Files (x86)",
                "$env:WINDIR\NTDS"
            )
            
            foreach ($Folder in $ProtectedFolders) {
                Add-MpPreference -ControlledFolderAccessProtectedFolders $Folder
            }
            
            Write-EventLog -LogName Application -Source "SecurityHardening" -EventId 5001 -EntryType Information -Message "Advanced Threat Protection enabled on $env:COMPUTERNAME"
        }
        catch {
            Write-EventLog -LogName Application -Source "SecurityHardening" -EventId 5002 -EntryType Error -Message "Failed to enable ATP on $env:COMPUTERNAME : $($_.Exception.Message)"
            throw
        }
    }
}

function Configure-WindowsEventForwarding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter()]
        [string]$CollectorServer = "SIEM01.company.com"
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param($Collector)
        
        # Configure WinRM for event forwarding
        winrm quickconfig -q
        winrm set winrm/config/service '@{AllowUnencrypted="false"}'
        winrm set winrm/config/service/auth '@{Basic="false"}'
        winrm set winrm/config/service/auth '@{Kerberos="true"}'
        
        # Configure Windows Event Collector
        wecutil cs "C:\Windows\System32\subscription.xml"
        
        # Create subscription configuration
        $SubscriptionXML = @"
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
    <SubscriptionId>DomainControllerSecurity</SubscriptionId>
    <SubscriptionType>SourceInitiated</SubscriptionType>
    <Description>Domain Controller Security Events</Description>
    <Enabled>true</Enabled>
    <Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
    <ConfigurationMode>Normal</ConfigurationMode>
    <Delivery Mode="Push">
        <Batching>
            <MaxItems>5</MaxItems>
            <MaxLatencyTime>900000</MaxLatencyTime>
        </Batching>
        <PushSettings>
            <Heartbeat Interval="900000"/>
        </PushSettings>
    </Delivery>
    <Query>
        <![CDATA[
        <QueryList>
            <Query Id="0">
                <Select Path="Security">*[System[(EventID=4624 or EventID=4625 or EventID=4634 or EventID=4672 or EventID=4720 or EventID=4722 or EventID=4724 or EventID=4725 or EventID=4726 or EventID=4727 or EventID=4728 or EventID=4729 or EventID=4730 or EventID=4731 or EventID=4732 or EventID=4733 or EventID=4734 or EventID=4735 or EventID=4737 or EventID=4738 or EventID=4739 or EventID=4740 or EventID=4741 or EventID=4742 or EventID=4743 or EventID=4754 or EventID=4755 or EventID=4756 or EventID=4757 or EventID=4764 or EventID=4767 or EventID=4768 or EventID=4769 or EventID=4771 or EventID=4776 or EventID=4778 or EventID=4779 or EventID=4781)]]></Select>
            </Query>
            <Query Id="1">
                <Select Path="System">*[System[(EventID=7030 or EventID=7045 or EventID=6005 or EventID=6006 or EventID=6008 or EventID=6013)]]></Select>
            </Query>
            <Query Id="2">
                <Select Path="Directory Service">*</Select>
            </Query>
        </QueryList>
        ]]>
    </Query>
    <ReadExistingEvents>false</ReadExistingEvents>
    <TransportName>HTTP</TransportName>
    <ContentFormat>Events</ContentFormat>
    <Locale Language="en-US"/>
    <LogFile>ForwardedEvents</LogFile>
    <AllowedSourceNonDomainComputers></AllowedSourceNonDomainComputers>
    <AllowedSourceDomainComputers>O:NSG:BAD:P(A;;GA;;;DC)S:</AllowedSourceDomainComputers>
</Subscription>
"@
        
        $SubscriptionXML | Out-File -FilePath "C:\Windows\System32\subscription.xml" -Encoding UTF8
        
        # Configure the subscription
        wecutil cs "C:\Windows\System32\subscription.xml"
        
        Write-EventLog -LogName Application -Source "SecurityHardening" -EventId 5003 -EntryType Information -Message "Windows Event Forwarding configured on $env:COMPUTERNAME"
        
    } -ArgumentList $CollectorServer
}
```

## Endpoint Detection and Response (EDR)

### Advanced Threat Detection

```powershell
function Install-EDRSolution {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerNames = @(),
        
        [Parameter()]
        [string]$EDRSolution = "WindowsDefenderATP",
        
        [Parameter()]
        [string]$OnboardingScript = "C:\Security\Scripts\WindowsDefenderATPOnboardingScript.cmd"
    )
    
    if ($ComputerNames.Count -eq 0) {
        # Get all domain computers
        $ComputerNames = (Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object {$_.OperatingSystem -like "*Windows*"}).Name
    }
    
    foreach ($Computer in $ComputerNames) {
        Write-Host "Installing EDR on $Computer..." -ForegroundColor Yellow
        
        try {
            # Copy onboarding script to target computer
            $DestPath = "\\$Computer\C$\Temp\OnboardEDR.cmd"
            Copy-Item -Path $OnboardingScript -Destination $DestPath -Force
            
            # Execute onboarding script remotely
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param($ScriptPath)
                
                # Run onboarding script
                $Result = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$ScriptPath`"" -Wait -PassThru -WindowStyle Hidden
                
                if ($Result.ExitCode -eq 0) {
                    # Configure advanced features
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection" -Name "Enable" -Value 1 -Force
                    
                    # Enable tamper protection
                    Set-MpPreference -DisableTamperProtection $false
                    
                    # Configure telemetry level
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 3 -Force
                    
                    Write-EventLog -LogName Application -Source "EDRDeployment" -EventId 6001 -EntryType Information -Message "EDR successfully deployed on $env:COMPUTERNAME"
                    return $true
                }
                else {
                    Write-EventLog -LogName Application -Source "EDRDeployment" -EventId 6002 -EntryType Error -Message "EDR deployment failed on $env:COMPUTERNAME with exit code $($Result.ExitCode)"
                    return $false
                }
            } -ArgumentList "C:\Temp\OnboardEDR.cmd"
            
            Write-Host "EDR installation completed on $Computer" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install EDR on $Computer : $($_.Exception.Message)"
        }
    }
}

function Get-ThreatDetectionReport {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerNames = @(),
        
        [Parameter()]
        [int]$DaysBack = 7,
        
        [Parameter()]
        [string]$ReportPath = "C:\Security\Reports\ThreatDetection.html"
    )
    
    $StartDate = (Get-Date).AddDays(-$DaysBack)
    $ThreatData = @()
    
    if ($ComputerNames.Count -eq 0) {
        $ComputerNames = (Get-ADComputer -Filter *).Name
    }
    
    foreach ($Computer in $ComputerNames) {
        try {
            # Get security events from remote computer
            $SecurityEvents = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                LogName = 'Security'
                StartTime = $StartDate
                ID = 4625, 4624, 4648, 4672, 4720, 4728, 4732, 4756
            } -ErrorAction SilentlyContinue
            
            # Get Windows Defender events
            $DefenderEvents = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                LogName = 'Microsoft-Windows-Windows Defender/Operational'
                StartTime = $StartDate
                ID = 1006, 1007, 1008, 1009, 1010, 1116, 1117
            } -ErrorAction SilentlyContinue
            
            # Get system events
            $SystemEvents = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                LogName = 'System'
                StartTime = $StartDate
                ID = 7045, 7030, 6005, 6008
            } -ErrorAction SilentlyContinue
            
            # Process events for threat indicators
            foreach ($Event in ($SecurityEvents + $DefenderEvents + $SystemEvents)) {
                $ThreatLevel = "Low"
                $ThreatType = "Unknown"
                
                switch ($Event.Id) {
                    4625 { 
                        $ThreatLevel = "Medium"
                        $ThreatType = "Failed Logon"
                    }
                    4648 { 
                        $ThreatLevel = "Medium"
                        $ThreatType = "Explicit Credential Use"
                    }
                    4672 { 
                        $ThreatLevel = "High"
                        $ThreatType = "Special Privileges Assigned"
                    }
                    1006 { 
                        $ThreatLevel = "Critical"
                        $ThreatType = "Malware Detected"
                    }
                    1007 { 
                        $ThreatLevel = "Critical"
                        $ThreatType = "Malware Blocked"
                    }
                    7045 { 
                        $ThreatLevel = "Medium"
                        $ThreatType = "Service Installation"
                    }
                }
                
                $ThreatData += [PSCustomObject]@{
                    ComputerName = $Computer
                    EventTime = $Event.TimeCreated
                    EventID = $Event.Id
                    ThreatType = $ThreatType
                    ThreatLevel = $ThreatLevel
                    Message = $Event.Message
                    UserName = if ($Event.Properties.Count -gt 5) { $Event.Properties[5].Value } else { "N/A" }
                    SourceIP = if ($Event.Properties.Count -gt 19) { $Event.Properties[19].Value } else { "N/A" }
                }
            }
        }
        catch {
            Write-Warning "Failed to collect threat data from $Computer : $($_.Exception.Message)"
        }
    }
    
    # Generate threat report
    $CriticalThreats = ($ThreatData | Where-Object ThreatLevel -eq "Critical").Count
    $HighThreats = ($ThreatData | Where-Object ThreatLevel -eq "High").Count
    $MediumThreats = ($ThreatData | Where-Object ThreatLevel -eq "Medium").Count
    $TotalThreats = $ThreatData.Count
    
    $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Threat Detection Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #d32f2f; color: white; padding: 15px; text-align: center; }
        .summary { background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-left: 4px solid #d32f2f; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .critical { background-color: #ffebee; color: #d32f2f; font-weight: bold; }
        .high { background-color: #fff3e0; color: #f57c00; }
        .medium { background-color: #e3f2fd; color: #1976d2; }
        .low { background-color: #e8f5e8; color: #388e3c; }
        .chart { background-color: #f8f9fa; padding: 20px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Threat Detection Report</h1>
        <p>Report Period: $StartDate to $(Get-Date)</p>
    </div>
    
    <div class="summary">
        <h2>Threat Summary</h2>
        <div class="chart">
            <h3>Threat Distribution</h3>
            <p>Critical: $CriticalThreats | High: $HighThreats | Medium: $MediumThreats | Total: $TotalThreats</p>
        </div>
    </div>
    
    <h2>Detailed Threat Analysis</h2>
    <table>
        <tr>
            <th>Computer</th>
            <th>Time</th>
            <th>Threat Type</th>
            <th>Level</th>
            <th>Event ID</th>
            <th>User</th>
            <th>Source IP</th>
        </tr>
"@
    
    foreach ($Threat in ($ThreatData | Sort-Object EventTime -Descending | Select-Object -First 100)) {
        $RowClass = $Threat.ThreatLevel.ToLower()
        
        $ReportHTML += @"
        <tr class="$RowClass">
            <td>$($Threat.ComputerName)</td>
            <td>$($Threat.EventTime)</td>
            <td>$($Threat.ThreatType)</td>
            <td>$($Threat.ThreatLevel)</td>
            <td>$($Threat.EventID)</td>
            <td>$($Threat.UserName)</td>
            <td>$($Threat.SourceIP)</td>
        </tr>
"@
    }
    
    $ReportHTML += @"
    </table>
    
    <h2>Security Recommendations</h2>
    <ul>
        <li>Investigate all critical and high-severity threats immediately</li>
        <li>Review failed logon patterns for potential brute force attacks</li>
        <li>Monitor service installations for potential persistence mechanisms</li>
        <li>Implement network segmentation to limit threat propagation</li>
        <li>Ensure all endpoints have updated EDR solutions</li>
        <li>Conduct regular threat hunting activities</li>
    </ul>
    
    <p><em>Generated by Windows Infrastructure Security Monitoring</em></p>
</body>
</html>
"@
    
    # Save report
    $ReportDir = Split-Path $ReportPath -Parent
    if (!(Test-Path $ReportDir)) {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    }
    
    $ReportHTML | Out-File -FilePath $ReportPath -Encoding UTF8
    
    Write-Host "Threat detection report generated: $ReportPath" -ForegroundColor Green
    Write-Host "Critical Threats: $CriticalThreats" -ForegroundColor Red
    Write-Host "High Threats: $HighThreats" -ForegroundColor Yellow
    
    return $ThreatData
}
```

## Network Security Controls

### Micro-segmentation and Traffic Analysis

```powershell
function Enable-NetworkSegmentation {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerNames = @(),
        
        [Parameter()]
        [hashtable]$SegmentationRules = @{},
        
        [Parameter()]
        [switch]$EnableTrafficAnalysis
    )
    
    # Default segmentation rules
    if ($SegmentationRules.Count -eq 0) {
        $SegmentationRules = @{
            "DomainControllers" = @{
                AllowedPorts = @(53, 88, 135, 389, 445, 464, 636, 3268, 3269, 9389)
                AllowedSources = @("DomainControllers", "MemberServers", "Workstations")
                DenyByDefault = $true
            }
            "MemberServers" = @{
                AllowedPorts = @(80, 443, 3389, 5985, 5986)
                AllowedSources = @("Workstations", "AdminWorkstations")
                DenyByDefault = $true
            }
            "Workstations" = @{
                AllowedPorts = @(80, 443, 445)
                AllowedSources = @("DomainControllers", "FileServers", "PrintServers")
                DenyByDefault = $false
            }
        }
    }
    
    foreach ($Computer in $ComputerNames) {
        Write-Host "Configuring network segmentation for $Computer..." -ForegroundColor Yellow
        
        try {
            # Determine computer role
            $ComputerRole = Get-ComputerRole -ComputerName $Computer
            
            if ($SegmentationRules.ContainsKey($ComputerRole)) {
                $Rules = $SegmentationRules[$ComputerRole]
                
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    param($Role, $Rules)
                    
                    # Enable Windows Firewall on all profiles
                    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow
                    
                    # Clear existing rules (be careful!)
                    # Remove-NetFirewallRule -DisplayGroup "Custom Segmentation Rules" -ErrorAction SilentlyContinue
                    
                    # Create inbound rules based on role
                    foreach ($Port in $Rules.AllowedPorts) {
                        New-NetFirewallRule -DisplayName "Allow Inbound Port $Port ($Role)" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Group "Custom Segmentation Rules"
                    }
                    
                    # Create outbound monitoring rules
                    if ($Rules.DenyByDefault) {
                        New-NetFirewallRule -DisplayName "Log Outbound Connections ($Role)" -Direction Outbound -Action Allow -Group "Custom Segmentation Rules" -Enabled True
                    }
                    
                    # Enable logging
                    Set-NetFirewallProfile -Profile Domain -LogAllowed True -LogBlocked True -LogMaxSizeKilobytes 32767 -LogFileName "C:\Windows\System32\LogFiles\Firewall\pfirewall.log"
                    
                    Write-EventLog -LogName Application -Source "NetworkSecurity" -EventId 7001 -EntryType Information -Message "Network segmentation configured for $Role on $env:COMPUTERNAME"
                    
                } -ArgumentList $ComputerRole, $Rules
                
                Write-Host "Network segmentation configured for $Computer ($ComputerRole)" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Failed to configure network segmentation for $Computer : $($_.Exception.Message)"
        }
    }
}

function Get-ComputerRole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    try {
        $Computer = Get-ADComputer -Identity $ComputerName -Properties OperatingSystem
        
        # Check if it's a domain controller
        $DCs = Get-ADDomainController -Filter *
        if ($DCs.Name -contains $ComputerName) {
            return "DomainControllers"
        }
        
        # Check operating system for server vs workstation
        if ($Computer.OperatingSystem -like "*Server*") {
            return "MemberServers"
        }
        else {
            return "Workstations"
        }
    }
    catch {
        Write-Warning "Could not determine role for $ComputerName : $($_.Exception.Message)"
        return "Unknown"
    }
}
```

## Compliance and Audit Framework

### STIG and CIS Benchmark Implementation

```powershell
function Test-ComplianceBaseline {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerNames = @(),
        
        [Parameter()]
        [ValidateSet("STIG", "CIS", "NIST", "Custom")]
        [string]$Framework = "STIG",
        
        [Parameter()]
        [string]$ReportPath = "C:\Security\Reports\Compliance.html"
    )
    
    $ComplianceResults = @()
    $Framework = "STIG"  # Default to STIG baseline
    
    # Load compliance checks based on framework
    $ComplianceChecks = Get-ComplianceChecks -Framework $Framework
    
    foreach ($Computer in $ComputerNames) {
        Write-Host "Running compliance assessment on $Computer..." -ForegroundColor Yellow
        
        foreach ($Check in $ComplianceChecks) {
            try {
                $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $Check.ScriptBlock
                
                $ComplianceResults += [PSCustomObject]@{
                    ComputerName = $Computer
                    Framework = $Framework
                    CheckID = $Check.ID
                    Title = $Check.Title
                    Category = $Check.Category
                    Severity = $Check.Severity
                    Status = $Result.Status
                    Finding = $Result.Finding
                    Expected = $Check.Expected
                    Remediation = $Check.Remediation
                    Timestamp = Get-Date
                }
            }
            catch {
                $ComplianceResults += [PSCustomObject]@{
                    ComputerName = $Computer
                    Framework = $Framework
                    CheckID = $Check.ID
                    Title = $Check.Title
                    Category = $Check.Category
                    Severity = $Check.Severity
                    Status = "Error"
                    Finding = $_.Exception.Message
                    Expected = $Check.Expected
                    Remediation = $Check.Remediation
                    Timestamp = Get-Date
                }
            }
        }
    }
    
    # Generate compliance report
    Generate-ComplianceReport -Results $ComplianceResults -ReportPath $ReportPath
    
    return $ComplianceResults
}

function Get-ComplianceChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Framework
    )
    
    switch ($Framework) {
        "STIG" {
            return @(
                @{
                    ID = "V-73519"
                    Title = "Password history must be configured"
                    Category = "Account Management"
                    Severity = "Medium"
                    Expected = "24 passwords remembered"
                    Remediation = "Set password history to 24"
                    ScriptBlock = {
                        $Policy = secedit /export /cfg C:\temp\secpol.cfg /quiet
                        $Content = Get-Content C:\temp\secpol.cfg
                        $PasswordHistory = ($Content | Where-Object { $_ -match "PasswordHistorySize" }) -replace "PasswordHistorySize = ", ""
                        Remove-Item C:\temp\secpol.cfg -Force
                        
                        if ($PasswordHistory -ge 24) {
                            return @{ Status = "Pass"; Finding = "Password history is $PasswordHistory" }
                        } else {
                            return @{ Status = "Fail"; Finding = "Password history is $PasswordHistory (should be 24)" }
                        }
                    }
                },
                @{
                    ID = "V-73521"
                    Title = "Minimum password length must be 14 characters"
                    Category = "Account Management"
                    Severity = "High"
                    Expected = "14 characters minimum"
                    Remediation = "Set minimum password length to 14"
                    ScriptBlock = {
                        $Policy = secedit /export /cfg C:\temp\secpol.cfg /quiet
                        $Content = Get-Content C:\temp\secpol.cfg
                        $MinLength = ($Content | Where-Object { $_ -match "MinimumPasswordLength" }) -replace "MinimumPasswordLength = ", ""
                        Remove-Item C:\temp\secpol.cfg -Force
                        
                        if ($MinLength -ge 14) {
                            return @{ Status = "Pass"; Finding = "Minimum password length is $MinLength" }
                        } else {
                            return @{ Status = "Fail"; Finding = "Minimum password length is $MinLength (should be 14)" }
                        }
                    }
                },
                @{
                    ID = "V-73805"
                    Title = "Anonymous access to Named Pipes and Shares must be restricted"
                    Category = "Network Security"
                    Severity = "High"
                    Expected = "Restricted"
                    Remediation = "Enable 'Network access: Restrict anonymous access to Named Pipes and Shares'"
                    ScriptBlock = {
                        $RegValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "restrictanonymous" -ErrorAction SilentlyContinue
                        
                        if ($RegValue.restrictanonymous -eq 1) {
                            return @{ Status = "Pass"; Finding = "Anonymous access is restricted" }
                        } else {
                            return @{ Status = "Fail"; Finding = "Anonymous access is not restricted" }
                        }
                    }
                }
            )
        }
        
        "CIS" {
            return @(
                @{
                    ID = "2.3.1.1"
                    Title = "Accounts: Administrator account status"
                    Category = "Account Policies"
                    Severity = "High"
                    Expected = "Disabled"
                    Remediation = "Disable the Administrator account"
                    ScriptBlock = {
                        $Admin = Get-LocalUser -Name "Administrator"
                        
                        if ($Admin.Enabled -eq $false) {
                            return @{ Status = "Pass"; Finding = "Administrator account is disabled" }
                        } else {
                            return @{ Status = "Fail"; Finding = "Administrator account is enabled" }
                        }
                    }
                },
                @{
                    ID = "9.1.1"
                    Title = "Windows Firewall: Domain: Firewall state"
                    Category = "Windows Firewall"
                    Severity = "High"
                    Expected = "On"
                    Remediation = "Enable Domain profile firewall"
                    ScriptBlock = {
                        $Firewall = Get-NetFirewallProfile -Profile Domain
                        
                        if ($Firewall.Enabled -eq $true) {
                            return @{ Status = "Pass"; Finding = "Domain firewall is enabled" }
                        } else {
                            return @{ Status = "Fail"; Finding = "Domain firewall is disabled" }
                        }
                    }
                }
            )
        }
    }
}
```

## Related Topics

- [Windows Server Configuration](../index.md)
- [Active Directory Security](../../../services/directoryservices/activedirectory/security/index.md)
- [Network Infrastructure Security](../../networking/security/index.md)
- [Identity and Access Management](../../security/iam/index.md)
- [Compliance and Auditing](../../security/compliance/index.md)
