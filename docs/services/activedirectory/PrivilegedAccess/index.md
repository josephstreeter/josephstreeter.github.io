---
title: Privileged Access Management (PAM)
description: Comprehensive guide to implementing Privileged Access Management for Active Directory including Just-in-Time access, privileged account monitoring, and access governance
author: Joseph Streeter
date: 2024-01-15
tags: [privileged-access, pam, active-directory, security, just-in-time, governance]
---

Privileged Access Management (PAM) is a critical security control for protecting Active Directory environments against insider threats and external attacks targeting privileged accounts. This guide covers comprehensive PAM implementation strategies.

## PAM Architecture Overview

### Core Components

- **Just-in-Time (JIT) Access**: Temporary privilege elevation
- **Privileged Account Monitoring**: Real-time activity tracking
- **Access Governance**: Approval workflows and reviews
- **Session Management**: Recorded and monitored privileged sessions
- **Credential Vaulting**: Secure storage of privileged credentials

```text
┌─────────────────────────────────────────────────────────────────┐
│                PAM Architecture                                 │
├─────────────────────────────────────────────────────────────────┤
│  Layer           │ Components                                   │
│  ├─ Governance   │ Approval Workflows, Policy Management       │
│  ├─ Access       │ JIT Elevation, Session Broker              │
│  ├─ Monitoring   │ Activity Logging, Behavioral Analytics     │
│  ├─ Vaulting     │ Credential Storage, Password Rotation      │
│  └─ Integration  │ AD, SIEM, HR Systems, ITSM                │
└─────────────────────────────────────────────────────────────────┘
```

## Just-in-Time Access Implementation

### PowerShell JIT Framework

```powershell
<#
.SYNOPSIS
    Just-in-Time privileged access management for Active Directory.
.DESCRIPTION
    Provides temporary elevation with automated approval workflows,
    time-based access controls, and comprehensive audit logging.
#>

class JITAccessRequest {
    [string]$RequestID
    [string]$UserName
    [string]$TargetGroup
    [string]$Justification
    [datetime]$RequestTime
    [datetime]$ExpirationTime
    [string]$Status
    [string]$ApproverName
    [datetime]$ApprovalTime
    [string]$DenialReason
    [hashtable]$Metadata
    
    JITAccessRequest([string]$User, [string]$Group, [string]$Reason, [int]$DurationMinutes) {
        $this.RequestID = [Guid]::NewGuid().ToString()
        $this.UserName = $User
        $this.TargetGroup = $Group
        $this.Justification = $Reason
        $this.RequestTime = Get-Date
        $this.ExpirationTime = (Get-Date).AddMinutes($DurationMinutes)
        $this.Status = "Pending"
        $this.Metadata = @{}
    }
}

class JITAccessManager {
    [string]$RequestStorePath
    [hashtable]$GroupApprovers
    [hashtable]$AutoApprovalRules
    [string]$SMTPServer
    [string]$LogPath
    
    JITAccessManager([string]$StorePath) {
        $this.RequestStorePath = $StorePath
        $this.GroupApprovers = @{}
        $this.AutoApprovalRules = @{}
        $this.SMTPServer = "smtp.company.com"
        $this.LogPath = "$StorePath\Logs"
        
        # Ensure directories exist
        if (!(Test-Path $this.RequestStorePath)) {
            New-Item -ItemType Directory -Path $this.RequestStorePath -Force | Out-Null
        }
        if (!(Test-Path $this.LogPath)) {
            New-Item -ItemType Directory -Path $this.LogPath -Force | Out-Null
        }
    }
    
    [string] SubmitRequest([string]$UserName, [string]$TargetGroup, [string]$Justification, [int]$DurationMinutes) {
        # Validate user and group
        try {
            $User = Get-ADUser -Identity $UserName -ErrorAction Stop
            $Group = Get-ADGroup -Identity $TargetGroup -ErrorAction Stop
        }
        catch {
            throw "Invalid user or group: $($_.Exception.Message)"
        }
        
        # Create request
        $Request = [JITAccessRequest]::new($UserName, $TargetGroup, $Justification, $DurationMinutes)
        
        # Add metadata
        $Request.Metadata["SubmittedFrom"] = $env:COMPUTERNAME
        $Request.Metadata["UserDN"] = $User.DistinguishedName
        $Request.Metadata["GroupDN"] = $Group.DistinguishedName
        $Request.Metadata["RequesterIP"] = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}).IPv4Address.IPAddress
        
        # Check auto-approval rules
        if ($this.CheckAutoApproval($Request)) {
            $this.ApproveRequest($Request.RequestID, "System Auto-Approval")
        }
        else {
            # Send to approvers
            $this.SendApprovalRequest($Request)
        }
        
        # Store request
        $this.SaveRequest($Request)
        
        # Log request
        $this.LogActivity("RequestSubmitted", $Request)
        
        return $Request.RequestID
    }
    
    [bool] CheckAutoApproval([JITAccessRequest]$Request) {
        # Check if group has auto-approval rules
        if ($this.AutoApprovalRules.ContainsKey($Request.TargetGroup)) {
            $Rules = $this.AutoApprovalRules[$Request.TargetGroup]
            
            # Check time-based rules
            if ($Rules.ContainsKey("BusinessHours")) {
                $CurrentHour = (Get-Date).Hour
                $IsBusinessHours = $CurrentHour -ge 8 -and $CurrentHour -le 17
                
                if ($Rules.BusinessHours -eq $IsBusinessHours) {
                    return $true
                }
            }
            
            # Check duration-based rules
            if ($Rules.ContainsKey("MaxDurationMinutes")) {
                $RequestDuration = ($Request.ExpirationTime - $Request.RequestTime).TotalMinutes
                
                if ($RequestDuration -le $Rules.MaxDurationMinutes) {
                    return $true
                }
            }
            
            # Check user-based rules
            if ($Rules.ContainsKey("PreapprovedUsers")) {
                if ($Request.UserName -in $Rules.PreapprovedUsers) {
                    return $true
                }
            }
        }
        
        return $false
    }
    
    [void] SendApprovalRequest([JITAccessRequest]$Request) {
        $Approvers = $this.GetApproversForGroup($Request.TargetGroup)
        
        if ($Approvers.Count -eq 0) {
            throw "No approvers configured for group: $($Request.TargetGroup)"
        }
        
        $EmailBody = @"
A privileged access request requires your approval:

Request ID: $($Request.RequestID)
User: $($Request.UserName)
Target Group: $($Request.TargetGroup)
Justification: $($Request.Justification)
Duration: $(($Request.ExpirationTime - $Request.RequestTime).TotalMinutes) minutes
Requested: $($Request.RequestTime)
Expires: $($Request.ExpirationTime)

To approve this request:
Approve-JITRequest -RequestID $($Request.RequestID)

To deny this request:
Deny-JITRequest -RequestID $($Request.RequestID) -Reason "Your reason here"

Request details available at: \\PAMServer\Requests\$($Request.RequestID).json
"@
        
        foreach ($Approver in $Approvers) {
            Send-MailMessage -From "pam@company.com" -To $Approver -Subject "PAM Approval Required: $($Request.UserName) -> $($Request.TargetGroup)" -Body $EmailBody -SmtpServer $this.SMTPServer
        }
    }
    
    [string[]] GetApproversForGroup([string]$GroupName) {
        if ($this.GroupApprovers.ContainsKey($GroupName)) {
            return $this.GroupApprovers[$GroupName]
        }
        
        # Default to security group owners or administrators
        return @("security@company.com")
    }
    
    [void] ApproveRequest([string]$RequestID, [string]$ApproverName) {
        $Request = $this.LoadRequest($RequestID)
        
        if ($Request.Status -ne "Pending") {
            throw "Request $RequestID is not in pending status"
        }
        
        # Update request
        $Request.Status = "Approved"
        $Request.ApproverName = $ApproverName
        $Request.ApprovalTime = Get-Date
        
        # Grant access
        Add-ADGroupMember -Identity $Request.TargetGroup -Members $Request.UserName
        
        # Schedule revocation
        $this.ScheduleAccessRevocation($Request)
        
        # Save updated request
        $this.SaveRequest($Request)
        
        # Log approval
        $this.LogActivity("RequestApproved", $Request)
        
        # Notify user
        $this.NotifyUser($Request, "Approved")
    }
    
    [void] DenyRequest([string]$RequestID, [string]$ApproverName, [string]$Reason) {
        $Request = $this.LoadRequest($RequestID)
        
        if ($Request.Status -ne "Pending") {
            throw "Request $RequestID is not in pending status"
        }
        
        # Update request
        $Request.Status = "Denied"
        $Request.ApproverName = $ApproverName
        $Request.ApprovalTime = Get-Date
        $Request.DenialReason = $Reason
        
        # Save updated request
        $this.SaveRequest($Request)
        
        # Log denial
        $this.LogActivity("RequestDenied", $Request)
        
        # Notify user
        $this.NotifyUser($Request, "Denied")
    }
    
    [void] ScheduleAccessRevocation([JITAccessRequest]$Request) {
        $TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command `"Remove-ADGroupMember -Identity '$($Request.TargetGroup)' -Members '$($Request.UserName)' -Confirm:`$false`""
        $TaskTrigger = New-ScheduledTaskTrigger -Once -At $Request.ExpirationTime
        $TaskName = "PAM-Revoke-$($Request.RequestID)"
        
        Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Description "Auto-revoke PAM access for $($Request.UserName)"
    }
    
    [void] RevokeAccess([string]$RequestID, [string]$Reason) {
        $Request = $this.LoadRequest($RequestID)
        
        if ($Request.Status -ne "Approved") {
            throw "Request $RequestID is not in approved status"
        }
        
        # Remove access
        Remove-ADGroupMember -Identity $Request.TargetGroup -Members $Request.UserName -Confirm:$false
        
        # Update request
        $Request.Status = "Revoked"
        $Request.Metadata["RevocationReason"] = $Reason
        $Request.Metadata["RevocationTime"] = Get-Date
        
        # Remove scheduled task
        $TaskName = "PAM-Revoke-$($Request.RequestID)"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Save updated request
        $this.SaveRequest($Request)
        
        # Log revocation
        $this.LogActivity("AccessRevoked", $Request)
    }
    
    [void] SaveRequest([JITAccessRequest]$Request) {
        $RequestFile = Join-Path $this.RequestStorePath "$($Request.RequestID).json"
        $Request | ConvertTo-Json -Depth 10 | Out-File -FilePath $RequestFile -Encoding UTF8
    }
    
    [JITAccessRequest] LoadRequest([string]$RequestID) {
        $RequestFile = Join-Path $this.RequestStorePath "$RequestID.json"
        
        if (!(Test-Path $RequestFile)) {
            throw "Request $RequestID not found"
        }
        
        $RequestData = Get-Content $RequestFile | ConvertFrom-Json
        $Request = [JITAccessRequest]::new($RequestData.UserName, $RequestData.TargetGroup, $RequestData.Justification, 0)
        
        # Restore properties
        $Request.RequestID = $RequestData.RequestID
        $Request.RequestTime = $RequestData.RequestTime
        $Request.ExpirationTime = $RequestData.ExpirationTime
        $Request.Status = $RequestData.Status
        $Request.ApproverName = $RequestData.ApproverName
        $Request.ApprovalTime = $RequestData.ApprovalTime
        $Request.DenialReason = $RequestData.DenialReason
        $Request.Metadata = $RequestData.Metadata
        
        return $Request
    }
    
    [void] LogActivity([string]$Action, [JITAccessRequest]$Request) {
        $LogEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = $Action
            RequestID = $Request.RequestID
            UserName = $Request.UserName
            TargetGroup = $Request.TargetGroup
            Status = $Request.Status
            ApproverName = $Request.ApproverName
            Metadata = $Request.Metadata
        }
        
        $LogFile = Join-Path $this.LogPath "PAM-$(Get-Date -Format 'yyyyMM').log"
        $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogFile -Append -Encoding UTF8
        
        # Also write to Windows Event Log
        try {
            Write-EventLog -LogName Application -Source "PAM" -EventId 3001 -EntryType Information -Message "$Action for user $($Request.UserName) to group $($Request.TargetGroup)"
        }
        catch {
            # Event source might not exist, continue without error
        }
    }
    
    [void] NotifyUser([JITAccessRequest]$Request, [string]$Decision) {
        try {
            $User = Get-ADUser -Identity $Request.UserName -Properties EmailAddress
            
            if ($User.EmailAddress) {
                $Subject = "PAM Request $Decision: $($Request.TargetGroup)"
                
                if ($Decision -eq "Approved") {
                    $Body = @"
Your privileged access request has been approved.

Request ID: $($Request.RequestID)
Target Group: $($Request.TargetGroup)
Access Expires: $($Request.ExpirationTime)
Approved by: $($Request.ApproverName)

Your access is now active and will be automatically revoked at the expiration time.
"@
                }
                else {
                    $Body = @"
Your privileged access request has been denied.

Request ID: $($Request.RequestID)
Target Group: $($Request.TargetGroup)
Denial Reason: $($Request.DenialReason)
Reviewed by: $($Request.ApproverName)

Please contact your security team if you believe this is an error.
"@
                }
                
                Send-MailMessage -From "pam@company.com" -To $User.EmailAddress -Subject $Subject -Body $Body -SmtpServer $this.SMTPServer
            }
        }
        catch {
            Write-Warning "Failed to notify user: $($_.Exception.Message)"
        }
    }
}

# Global functions for easy use
function Initialize-PAM {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$StorePath = "C:\PAM"
    )
    
    $Global:PAMManager = [JITAccessManager]::new($StorePath)
    
    # Configure default approvers and rules
    $Global:PAMManager.GroupApprovers = @{
        "Domain Admins" = @("security@company.com", "ciso@company.com")
        "Enterprise Admins" = @("security@company.com", "ciso@company.com")
        "Schema Admins" = @("security@company.com", "ciso@company.com")
        "Server Operators" = @("serveradmins@company.com")
        "Backup Operators" = @("backupadmins@company.com")
    }
    
    $Global:PAMManager.AutoApprovalRules = @{
        "Server Operators" = @{
            "BusinessHours" = $true
            "MaxDurationMinutes" = 60
        }
        "Backup Operators" = @{
            "MaxDurationMinutes" = 240
        }
    }
    
    Write-Host "PAM Manager initialized at: $StorePath" -ForegroundColor Green
}

function Request-PrivilegedAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [string]$TargetGroup,
        
        [Parameter(Mandatory)]
        [string]$Justification,
        
        [Parameter()]
        [int]$DurationMinutes = 120
    )
    
    if (!$Global:PAMManager) {
        Initialize-PAM
    }
    
    try {
        $RequestID = $Global:PAMManager.SubmitRequest($UserName, $TargetGroup, $Justification, $DurationMinutes)
        Write-Host "Request submitted successfully. Request ID: $RequestID" -ForegroundColor Green
        return $RequestID
    }
    catch {
        Write-Error "Failed to submit request: $($_.Exception.Message)"
    }
}

function Approve-JITRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequestID,
        
        [Parameter()]
        [string]$ApproverName = $env:USERNAME
    )
    
    if (!$Global:PAMManager) {
        Initialize-PAM
    }
    
    try {
        $Global:PAMManager.ApproveRequest($RequestID, $ApproverName)
        Write-Host "Request $RequestID approved successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to approve request: $($_.Exception.Message)"
    }
}

function Deny-JITRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequestID,
        
        [Parameter(Mandatory)]
        [string]$Reason,
        
        [Parameter()]
        [string]$ApproverName = $env:USERNAME
    )
    
    if (!$Global:PAMManager) {
        Initialize-PAM
    }
    
    try {
        $Global:PAMManager.DenyRequest($RequestID, $ApproverName, $Reason)
        Write-Host "Request $RequestID denied successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to deny request: $($_.Exception.Message)"
    }
}

function Revoke-JITAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequestID,
        
        [Parameter()]
        [string]$Reason = "Manual revocation"
    )
    
    if (!$Global:PAMManager) {
        Initialize-PAM
    }
    
    try {
        $Global:PAMManager.RevokeAccess($RequestID, $Reason)
        Write-Host "Access revoked successfully for request $RequestID" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to revoke access: $($_.Exception.Message)"
    }
}
```

## Privileged Session Management

### Session Recording and Monitoring

```powershell
function Start-PrivilegedSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [string]$TargetSystem,
        
        [Parameter()]
        [string]$SessionType = "RDP",
        
        [Parameter()]
        [string]$Justification
    )
    
    $SessionID = [Guid]::NewGuid().ToString()
    $SessionStart = Get-Date
    
    # Create session record
    $SessionRecord = [PSCustomObject]@{
        SessionID = $SessionID
        UserName = $UserName
        TargetSystem = $TargetSystem
        SessionType = $SessionType
        Justification = $Justification
        StartTime = $SessionStart
        EndTime = $null
        Status = "Active"
        RecordingPath = "\\SessionRecorder\Recordings\$SessionID"
        KeystrokeLog = "\\SessionRecorder\Keystrokes\$SessionID.log"
        ScreenRecording = "\\SessionRecorder\Screens\$SessionID.mp4"
        Metadata = @{
            SourceIP = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}).IPv4Address.IPAddress
            ComputerName = $env:COMPUTERNAME
            ProcessId = $PID
        }
    }
    
    # Log session start
    Write-EventLog -LogName Application -Source "PAM" -EventId 4001 -EntryType Information -Message "Privileged session started: User $UserName accessing $TargetSystem (Session: $SessionID)"
    
    # Start recording if configured
    if ($SessionType -eq "RDP") {
        Start-RDPRecording -SessionID $SessionID -TargetSystem $TargetSystem
    }
    
    # Save session record
    $SessionFile = "C:\PAM\Sessions\$SessionID.json"
    $SessionRecord | ConvertTo-Json | Out-File -FilePath $SessionFile -Encoding UTF8
    
    Write-Host "Privileged session started. Session ID: $SessionID" -ForegroundColor Green
    return $SessionID
}

function Stop-PrivilegedSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionID,
        
        [Parameter()]
        [string]$EndReason = "Normal termination"
    )
    
    $SessionFile = "C:\PAM\Sessions\$SessionID.json"
    
    if (!(Test-Path $SessionFile)) {
        Write-Error "Session $SessionID not found"
        return
    }
    
    # Load session record
    $SessionRecord = Get-Content $SessionFile | ConvertFrom-Json
    
    # Update session
    $SessionRecord.EndTime = Get-Date
    $SessionRecord.Status = "Completed"
    $SessionRecord.Metadata.EndReason = $EndReason
    $SessionRecord.Metadata.Duration = ($SessionRecord.EndTime - $SessionRecord.StartTime).TotalMinutes
    
    # Stop recording
    Stop-SessionRecording -SessionID $SessionID
    
    # Save updated record
    $SessionRecord | ConvertTo-Json | Out-File -FilePath $SessionFile -Encoding UTF8
    
    # Log session end
    Write-EventLog -LogName Application -Source "PAM" -EventId 4002 -EntryType Information -Message "Privileged session ended: $SessionID (Duration: $($SessionRecord.Metadata.Duration) minutes)"
    
    Write-Host "Privileged session $SessionID ended" -ForegroundColor Green
}
```

## Privileged Account Discovery

### Account Risk Assessment

```powershell
function Get-PrivilegedAccountRiskAssessment {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DomainControllers = @(),
        
        [Parameter()]
        [string]$ReportPath = "C:\PAM\Reports\PrivilegedAccountRisk.html"
    )
    
    if ($DomainControllers.Count -eq 0) {
        $DomainControllers = (Get-ADDomainController -Filter *).Name
    }
    
    $RiskAssessment = @()
    $PrivilegedGroups = @(
        'Domain Admins',
        'Enterprise Admins',
        'Schema Admins',
        'Administrators',
        'Backup Operators',
        'Server Operators',
        'Account Operators',
        'Print Operators'
    )
    
    foreach ($GroupName in $PrivilegedGroups) {
        try {
            $Group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
            $Members = Get-ADGroupMember -Identity $Group -Recursive
            
            foreach ($Member in $Members) {
                if ($Member.objectClass -eq 'user') {
                    $User = Get-ADUser -Identity $Member.SamAccountName -Properties LastLogonDate, PasswordLastSet, PasswordNeverExpires, AccountExpirationDate, LockedOut, Enabled, ServicePrincipalName
                    
                    # Calculate risk score
                    $RiskScore = 0
                    $RiskFactors = @()
                    
                    # Age-based risks
                    if ($User.LastLogonDate -lt (Get-Date).AddDays(-30)) {
                        $RiskScore += 20
                        $RiskFactors += "Inactive account (>30 days)"
                    }
                    
                    if ($User.PasswordLastSet -lt (Get-Date).AddDays(-90)) {
                        $RiskScore += 15
                        $RiskFactors += "Old password (>90 days)"
                    }
                    
                    if ($User.PasswordNeverExpires) {
                        $RiskScore += 25
                        $RiskFactors += "Password never expires"
                    }
                    
                    # Account configuration risks
                    if (!$User.AccountExpirationDate) {
                        $RiskScore += 10
                        $RiskFactors += "No account expiration"
                    }
                    
                    if ($User.ServicePrincipalName) {
                        $RiskScore += 15
                        $RiskFactors += "Service account with SPN"
                    }
                    
                    # Security state risks
                    if (!$User.Enabled) {
                        $RiskScore += 5
                        $RiskFactors += "Disabled account in privileged group"
                    }
                    
                    if ($User.LockedOut) {
                        $RiskScore += 5
                        $RiskFactors += "Locked out account"
                    }
                    
                    # Group-specific risks
                    if ($GroupName -in @('Domain Admins', 'Enterprise Admins', 'Schema Admins')) {
                        $RiskScore += 10
                        $RiskFactors += "High-privilege group membership"
                    }
                    
                    $RiskLevel = switch ($RiskScore) {
                        {$_ -ge 60} { "Critical" }
                        {$_ -ge 40} { "High" }
                        {$_ -ge 20} { "Medium" }
                        default { "Low" }
                    }
                    
                    $RiskAssessment += [PSCustomObject]@{
                        UserName = $User.SamAccountName
                        DisplayName = $User.Name
                        PrivilegedGroup = $GroupName
                        RiskScore = $RiskScore
                        RiskLevel = $RiskLevel
                        RiskFactors = $RiskFactors -join '; '
                        LastLogon = $User.LastLogonDate
                        PasswordLastSet = $User.PasswordLastSet
                        PasswordNeverExpires = $User.PasswordNeverExpires
                        AccountExpires = $User.AccountExpirationDate
                        Enabled = $User.Enabled
                        LockedOut = $User.LockedOut
                        HasSPN = [bool]$User.ServicePrincipalName
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to assess group $GroupName : $($_.Exception.Message)"
        }
    }
    
    # Generate risk report
    $CriticalAccounts = ($RiskAssessment | Where-Object RiskLevel -eq "Critical").Count
    $HighRiskAccounts = ($RiskAssessment | Where-Object RiskLevel -eq "High").Count
    $TotalAccounts = $RiskAssessment.Count
    
    $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Privileged Account Risk Assessment</title>
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
    </style>
</head>
<body>
    <div class="header">
        <h1>Privileged Account Risk Assessment</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <div class="summary">
        <h2>Risk Summary</h2>
        <ul>
            <li>Total Privileged Accounts: $TotalAccounts</li>
            <li>Critical Risk: $CriticalAccounts</li>
            <li>High Risk: $HighRiskAccounts</li>
            <li>Overall Risk Rating: $(if ($CriticalAccounts -gt 0) { "Critical" } elseif ($HighRiskAccounts -gt 0) { "High" } else { "Medium" })</li>
        </ul>
    </div>
    
    <h2>Detailed Risk Assessment</h2>
    <table>
        <tr>
            <th>User</th>
            <th>Group</th>
            <th>Risk Level</th>
            <th>Score</th>
            <th>Risk Factors</th>
            <th>Last Logon</th>
            <th>Password Age</th>
        </tr>
"@
    
    foreach ($Account in ($RiskAssessment | Sort-Object RiskScore -Descending)) {
        $RowClass = $Account.RiskLevel.ToLower()
        $PasswordAge = if ($Account.PasswordLastSet) { ((Get-Date) - $Account.PasswordLastSet).Days } else { "Unknown" }
        
        $ReportHTML += @"
        <tr class="$RowClass">
            <td>$($Account.UserName)</td>
            <td>$($Account.PrivilegedGroup)</td>
            <td>$($Account.RiskLevel)</td>
            <td>$($Account.RiskScore)</td>
            <td>$($Account.RiskFactors)</td>
            <td>$($Account.LastLogon)</td>
            <td>$PasswordAge days</td>
        </tr>
"@
    }
    
    $ReportHTML += @"
    </table>
    
    <h2>Recommendations</h2>
    <ul>
        <li>Review and remove unnecessary privileged group memberships</li>
        <li>Implement regular access reviews for privileged accounts</li>
        <li>Enforce password rotation for service accounts</li>
        <li>Set account expiration dates for temporary privileged access</li>
        <li>Monitor and investigate inactive privileged accounts</li>
        <li>Implement Just-in-Time access for routine administrative tasks</li>
    </ul>
    
    <p><em>Generated by PAM Risk Assessment Tool</em></p>
</body>
</html>
"@
    
    # Save report
    $ReportDir = Split-Path $ReportPath -Parent
    if (!(Test-Path $ReportDir)) {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    }
    
    $ReportHTML | Out-File -FilePath $ReportPath -Encoding UTF8
    
    Write-Host "Risk assessment completed. Report saved to: $ReportPath" -ForegroundColor Green
    Write-Host "Critical Risk Accounts: $CriticalAccounts" -ForegroundColor Red
    Write-Host "High Risk Accounts: $HighRiskAccounts" -ForegroundColor Yellow
    
    return $RiskAssessment
}
```

## Related Topics

- [Active Directory Security](~/docs/services/activedirectory/Security/index.md)
- [Active Directory Monitoring](~/docs/services/activedirectory/ad-monitoring/index.md)
- [Group Policy Management](~/docs/services/activedirectory/GroupPolicy/index.md)
- [Infrastructure Security](~/docs/infrastructure/security/index.md)
- [Identity and Access Management](~/docs/infrastructure/security/iam/index.md)
