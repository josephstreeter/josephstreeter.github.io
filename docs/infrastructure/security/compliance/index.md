---
title: Compliance and Auditing Framework
description: Comprehensive compliance management covering STIG, NIST, ISO 27001, SOX, and automated audit frameworks for enterprise infrastructure
author: Joseph Streeter
date: 2024-01-15
tags: [compliance, auditing, stig, nist, iso27001, sox, governance, risk-management]
---

Compliance and Auditing Framework provides systematic approaches to meeting regulatory requirements, implementing security controls, and maintaining continuous compliance across enterprise infrastructure.

## Compliance Framework Overview

### Regulatory Standards Coverage

```text
┌─────────────────────────────────────────────────────────────────┐
│                  Compliance Framework                           │
├─────────────────────────────────────────────────────────────────┤
│  Standard        │ Focus Area                                   │
│  ├─ NIST CSF     │ Cybersecurity Framework (5 Functions)        │
│  ├─ NIST 800-53  │ Security Controls Catalog                    │
│  ├─ STIG         │ Security Technical Implementation Guides     │
│  ├─ ISO 27001    │ Information Security Management Systems      │
│  ├─ SOX          │ Financial Controls and IT General Controls   │
│  ├─ HIPAA        │ Healthcare Information Protection            │
│  ├─ PCI DSS      │ Payment Card Industry Data Security          │
│  └─ GDPR         │ Data Protection and Privacy Rights           │
└─────────────────────────────────────────────────────────────────┘
```

### Core Compliance Components

- **Policy Management**: Centralized governance framework
- **Control Implementation**: Technical and administrative controls
- **Evidence Collection**: Automated artifact gathering
- **Risk Assessment**: Continuous risk monitoring
- **Audit Management**: Internal and external audit coordination

## Automated Compliance Assessment Framework

### Multi-Framework Compliance Engine

```powershell
<#
.SYNOPSIS
    Enterprise compliance assessment and management framework.
.DESCRIPTION
    Provides automated compliance checking, evidence collection,
    and reporting across multiple regulatory frameworks.
#>

class ComplianceFramework {
    [string]$FrameworkName
    [string]$Version
    [hashtable]$Controls
    [hashtable]$Requirements
    [string]$Description
    [string]$Scope
    [datetime]$LastUpdated
    
    ComplianceFramework([string]$Name, [string]$Version) {
        $this.FrameworkName = $Name
        $this.Version = $Version
        $this.Controls = @{}
        $this.Requirements = @{}
        $this.LastUpdated = Get-Date
    }
    
    [void] AddControl([string]$ControlID, [hashtable]$ControlDefinition) {
        $this.Controls[$ControlID] = $ControlDefinition
        $this.LastUpdated = Get-Date
    }
    
    [hashtable] GetControl([string]$ControlID) {
        return $this.Controls[$ControlID]
    }
    
    [string[]] GetAllControlIDs() {
        return $this.Controls.Keys
    }
}

class ComplianceAssessment {
    [string]$AssessmentID
    [string]$AssessmentName
    [string]$Framework
    [datetime]$StartDate
    [datetime]$EndDate
    [string]$Scope
    [string]$Assessor
    [hashtable]$Results
    [string]$Status
    [hashtable]$Metadata
    
    ComplianceAssessment([string]$Name, [string]$Framework) {
        $this.AssessmentID = [Guid]::NewGuid().ToString()
        $this.AssessmentName = $Name
        $this.Framework = $Framework
        $this.StartDate = Get-Date
        $this.Scope = "Enterprise"
        $this.Assessor = $env:USERNAME
        $this.Results = @{}
        $this.Status = "In Progress"
        $this.Metadata = @{}
    }
    
    [void] AddResult([string]$ControlID, [hashtable]$Result) {
        $this.Results[$ControlID] = $Result
    }
    
    [hashtable] GetSummary() {
        $TotalControls = $this.Results.Count
        $PassedControls = ($this.Results.Values | Where-Object { $_.Status -eq "Pass" }).Count
        $FailedControls = ($this.Results.Values | Where-Object { $_.Status -eq "Fail" }).Count
        $NotApplicableControls = ($this.Results.Values | Where-Object { $_.Status -eq "N/A" }).Count
        $NotTestableControls = ($this.Results.Values | Where-Object { $_.Status -eq "Manual" }).Count
        
        return @{
            TotalControls = $TotalControls
            PassedControls = $PassedControls
            FailedControls = $FailedControls
            NotApplicableControls = $NotApplicableControls
            NotTestableControls = $NotTestableControls
            CompliancePercentage = if ($TotalControls -gt 0) { [math]::Round(($PassedControls / $TotalControls) * 100, 2) } else { 0 }
            RiskScore = $this.CalculateRiskScore()
        }
    }
    
    [int] CalculateRiskScore() {
        $RiskScore = 0
        
        foreach ($Result in $this.Results.Values) {
            if ($Result.Status -eq "Fail") {
                switch ($Result.Severity) {
                    "Critical" { $RiskScore += 25 }
                    "High" { $RiskScore += 15 }
                    "Medium" { $RiskScore += 10 }
                    "Low" { $RiskScore += 5 }
                }
            }
        }
        
        return $RiskScore
    }
}

class ComplianceManager {
    [hashtable]$Frameworks
    [hashtable]$Assessments
    [string]$ConfigPath
    [string]$EvidencePath
    [string]$ReportPath
    [string]$LogPath
    [hashtable]$AutomatedChecks
    
    ComplianceManager([string]$BasePath) {
        $this.ConfigPath = Join-Path $BasePath "Configuration"
        $this.EvidencePath = Join-Path $BasePath "Evidence"
        $this.ReportPath = Join-Path $BasePath "Reports"
        $this.LogPath = Join-Path $BasePath "Logs"
        $this.Frameworks = @{}
        $this.Assessments = @{}
        $this.AutomatedChecks = @{}
        
        # Ensure directories exist
        foreach ($Path in @($this.ConfigPath, $this.EvidencePath, $this.ReportPath, $this.LogPath)) {
            if (!(Test-Path $Path)) {
                New-Item -ItemType Directory -Path $Path -Force | Out-Null
            }
        }
        
        $this.InitializeFrameworks()
        $this.InitializeAutomatedChecks()
    }
    
    [void] InitializeFrameworks() {
        # Initialize NIST Cybersecurity Framework
        $NIST_CSF = [ComplianceFramework]::new("NIST-CSF", "1.1")
        $NIST_CSF.Description = "NIST Cybersecurity Framework"
        $NIST_CSF.Scope = "Cybersecurity Risk Management"
        
        # Add NIST CSF Functions and Categories
        $NIST_CSF.AddControl("ID.AM-1", @{
            Function = "Identify"
            Category = "Asset Management"
            Subcategory = "Physical devices and systems within the organization are inventoried"
            Title = "Asset Inventory"
            Description = "Maintain an inventory of physical devices and systems"
            Implementation = "Automated asset discovery and inventory management"
            TestProcedure = "Verify asset inventory is complete and current"
            Severity = "Medium"
        })
        
        $NIST_CSF.AddControl("ID.AM-2", @{
            Function = "Identify"
            Category = "Asset Management"
            Subcategory = "Software platforms and applications within the organization are inventoried"
            Title = "Software Inventory"
            Description = "Maintain an inventory of software platforms and applications"
            Implementation = "Software asset management tools and processes"
            TestProcedure = "Verify software inventory accuracy and completeness"
            Severity = "Medium"
        })
        
        $NIST_CSF.AddControl("PR.AC-1", @{
            Function = "Protect"
            Category = "Access Control"
            Subcategory = "Identities and credentials are issued, managed, verified, revoked, and audited"
            Title = "Identity and Credential Management"
            Description = "Implement identity and credential lifecycle management"
            Implementation = "IAM system with automated provisioning and deprovisioning"
            TestProcedure = "Verify identity lifecycle processes and controls"
            Severity = "High"
        })
        
        $NIST_CSF.AddControl("DE.CM-1", @{
            Function = "Detect"
            Category = "Security Continuous Monitoring"
            Subcategory = "The network is monitored to detect potential cybersecurity events"
            Title = "Network Monitoring"
            Description = "Implement continuous network monitoring"
            Implementation = "Network monitoring tools and SIEM integration"
            TestProcedure = "Verify network monitoring capabilities and alerting"
            Severity = "High"
        })
        
        $this.Frameworks["NIST-CSF"] = $NIST_CSF
        
        # Initialize STIG Framework
        $STIG = [ComplianceFramework]::new("STIG", "Latest")
        $STIG.Description = "Security Technical Implementation Guide"
        $STIG.Scope = "Technical Security Controls"
        
        $STIG.AddControl("V-73519", @{
            VulnID = "V-73519"
            Title = "Password history must be configured to 24 passwords"
            Description = "A system is more vulnerable to a password attack when it allows users to continually reuse a small number of passwords"
            CheckText = "Verify the effective setting in Local Group Policy Editor"
            FixText = "Set password history to 24 passwords"
            Severity = "Medium"
            Category = "Account Management"
            TestProcedure = "Check password history setting in group policy"
        })
        
        $STIG.AddControl("V-73521", @{
            VulnID = "V-73521"
            Title = "Minimum password length must be 14 characters"
            Description = "The shorter the password, the lower the number of possible combinations"
            CheckText = "Verify minimum password length policy setting"
            FixText = "Set minimum password length to 14 characters"
            Severity = "High"
            Category = "Account Management"
            TestProcedure = "Check minimum password length in group policy"
        })
        
        $this.Frameworks["STIG"] = $STIG
        
        # Initialize ISO 27001 Framework
        $ISO27001 = [ComplianceFramework]::new("ISO-27001", "2013")
        $ISO27001.Description = "Information Security Management Systems"
        $ISO27001.Scope = "Information Security Management"
        
        $ISO27001.AddControl("A.8.1.1", @{
            Domain = "Asset Management"
            Control = "Inventory of assets"
            Title = "Responsibility for assets"
            Description = "Assets associated with information and information processing facilities should be identified"
            Implementation = "Asset management system with clear ownership"
            TestProcedure = "Verify asset inventory and ownership records"
            Severity = "Medium"
        })
        
        $ISO27001.AddControl("A.9.1.1", @{
            Domain = "Access Control"
            Control = "Access control policy"
            Title = "Business requirement of access control"
            Description = "An access control policy should be established, documented and reviewed"
            Implementation = "Documented access control policy and procedures"
            TestProcedure = "Review access control policy documentation"
            Severity = "High"
        })
        
        $this.Frameworks["ISO-27001"] = $ISO27001
    }
    
    [void] InitializeAutomatedChecks() {
        $this.AutomatedChecks = @{
            "PasswordPolicy" = {
                param($ControlID, $Framework)
                
                try {
                    # Export security policy
                    secedit /export /cfg C:\temp\secpol.cfg /quiet | Out-Null
                    $Content = Get-Content C:\temp\secpol.cfg
                    
                    $PasswordHistory = ($Content | Where-Object { $_ -match "PasswordHistorySize" }) -replace "PasswordHistorySize = ", ""
                    $MinPasswordLength = ($Content | Where-Object { $_ -match "MinimumPasswordLength" }) -replace "MinimumPasswordLength = ", ""
                    
                    Remove-Item C:\temp\secpol.cfg -Force -ErrorAction SilentlyContinue
                    
                    $Results = @()
                    
                    # Check password history (STIG V-73519)
                    if ($ControlID -eq "V-73519" -or $Framework -eq "STIG") {
                        if ($PasswordHistory -ge 24) {
                            $Results += @{
                                ControlID = "V-73519"
                                Status = "Pass"
                                Finding = "Password history is configured to $PasswordHistory passwords"
                                Evidence = "Password history: $PasswordHistory"
                                Timestamp = Get-Date
                            }
                        } else {
                            $Results += @{
                                ControlID = "V-73519"
                                Status = "Fail"
                                Finding = "Password history is $PasswordHistory (required: 24)"
                                Evidence = "Password history: $PasswordHistory"
                                Recommendation = "Set password history to 24 passwords"
                                Timestamp = Get-Date
                                Severity = "Medium"
                            }
                        }
                    }
                    
                    # Check minimum password length (STIG V-73521)
                    if ($ControlID -eq "V-73521" -or $Framework -eq "STIG") {
                        if ($MinPasswordLength -ge 14) {
                            $Results += @{
                                ControlID = "V-73521"
                                Status = "Pass"
                                Finding = "Minimum password length is $MinPasswordLength characters"
                                Evidence = "Minimum password length: $MinPasswordLength"
                                Timestamp = Get-Date
                            }
                        } else {
                            $Results += @{
                                ControlID = "V-73521"
                                Status = "Fail"
                                Finding = "Minimum password length is $MinPasswordLength (required: 14)"
                                Evidence = "Minimum password length: $MinPasswordLength"
                                Recommendation = "Set minimum password length to 14 characters"
                                Timestamp = Get-Date
                                Severity = "High"
                            }
                        }
                    }
                    
                    return $Results
                }
                catch {
                    return @{
                        ControlID = $ControlID
                        Status = "Error"
                        Finding = "Failed to check password policy: $($_.Exception.Message)"
                        Timestamp = Get-Date
                    }
                }
            }
            
            "FirewallStatus" = {
                param($ControlID, $Framework)
                
                try {
                    $FirewallProfiles = Get-NetFirewallProfile
                    $Results = @()
                    
                    foreach ($Profile in $FirewallProfiles) {
                        $Result = @{
                            ControlID = $ControlID
                            Profile = $Profile.Name
                            Evidence = "Firewall $($Profile.Name) profile enabled: $($Profile.Enabled)"
                            Timestamp = Get-Date
                        }
                        
                        if ($Profile.Enabled) {
                            $Result.Status = "Pass"
                            $Result.Finding = "$($Profile.Name) firewall profile is enabled"
                        } else {
                            $Result.Status = "Fail"
                            $Result.Finding = "$($Profile.Name) firewall profile is disabled"
                            $Result.Recommendation = "Enable $($Profile.Name) firewall profile"
                            $Result.Severity = "High"
                        }
                        
                        $Results += $Result
                    }
                    
                    return $Results
                }
                catch {
                    return @{
                        ControlID = $ControlID
                        Status = "Error"
                        Finding = "Failed to check firewall status: $($_.Exception.Message)"
                        Timestamp = Get-Date
                    }
                }
            }
            
            "AssetInventory" = {
                param($ControlID, $Framework)
                
                try {
                    # Get computer inventory
                    $ComputerInfo = Get-ComputerInfo
                    $InstalledSoftware = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                                      Where-Object DisplayName | 
                                      Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
                    
                    $AssetInfo = @{
                        ComputerName = $ComputerInfo.CsName
                        Model = $ComputerInfo.CsModel
                        Manufacturer = $ComputerInfo.CsManufacturer
                        SerialNumber = $ComputerInfo.BiosSeralNumber
                        OperatingSystem = $ComputerInfo.WindowsProductName
                        OSVersion = $ComputerInfo.WindowsVersion
                        TotalPhysicalMemory = $ComputerInfo.TotalPhysicalMemory
                        ProcessorCount = $ComputerInfo.CsProcessors.Count
                        SoftwareCount = $InstalledSoftware.Count
                        LastInventoryDate = Get-Date
                    }
                    
                    return @{
                        ControlID = $ControlID
                        Status = "Pass"
                        Finding = "Asset inventory collected successfully"
                        Evidence = $AssetInfo | ConvertTo-Json -Depth 2
                        Timestamp = Get-Date
                    }
                }
                catch {
                    return @{
                        ControlID = $ControlID
                        Status = "Error"
                        Finding = "Failed to collect asset inventory: $($_.Exception.Message)"
                        Timestamp = Get-Date
                    }
                }
            }
            
            "EventLogConfiguration" = {
                param($ControlID, $Framework)
                
                try {
                    $SecurityLog = Get-EventLog -List | Where-Object Log -eq "Security"
                    $Results = @()
                    
                    $Result = @{
                        ControlID = $ControlID
                        Evidence = "Security log max size: $($SecurityLog.MaximumKilobytes)KB, Retention: $($SecurityLog.OverflowAction)"
                        Timestamp = Get-Date
                    }
                    
                    # Check log size (should be at least 1GB)
                    if ($SecurityLog.MaximumKilobytes -ge 1048576) {
                        $Result.Status = "Pass"
                        $Result.Finding = "Security log size is adequate ($($SecurityLog.MaximumKilobytes)KB)"
                    } else {
                        $Result.Status = "Fail"
                        $Result.Finding = "Security log size is too small ($($SecurityLog.MaximumKilobytes)KB)"
                        $Result.Recommendation = "Increase security log size to at least 1GB"
                        $Result.Severity = "Medium"
                    }
                    
                    return $Result
                }
                catch {
                    return @{
                        ControlID = $ControlID
                        Status = "Error"
                        Finding = "Failed to check event log configuration: $($_.Exception.Message)"
                        Timestamp = Get-Date
                    }
                }
            }
        }
    }
    
    [ComplianceAssessment] StartAssessment([string]$AssessmentName, [string]$Framework, [string[]]$ControlIDs = @()) {
        if (!$this.Frameworks.ContainsKey($Framework)) {
            throw "Framework '$Framework' not found"
        }
        
        $Assessment = [ComplianceAssessment]::new($AssessmentName, $Framework)
        $Assessment.Scope = if ($ControlIDs.Count -gt 0) { "Selected Controls" } else { "Full Framework" }
        
        $FrameworkObj = $this.Frameworks[$Framework]
        $ControlsToTest = if ($ControlIDs.Count -gt 0) { $ControlIDs } else { $FrameworkObj.GetAllControlIDs() }
        
        foreach ($ControlID in $ControlsToTest) {
            $Control = $FrameworkObj.GetControl($ControlID)
            
            if ($Control) {
                Write-Host "Testing control: $ControlID" -ForegroundColor Yellow
                
                # Try automated check first
                $Result = $this.RunAutomatedCheck($ControlID, $Framework, $Control)
                
                if (!$Result) {
                    # Manual check required
                    $Result = @{
                        ControlID = $ControlID
                        Status = "Manual"
                        Finding = "Manual verification required"
                        Evidence = "No automated check available"
                        Timestamp = Get-Date
                        RequiresManualReview = $true
                    }
                }
                
                $Assessment.AddResult($ControlID, $Result)
                
                # Save evidence
                $this.SaveEvidence($Assessment.AssessmentID, $ControlID, $Result)
            }
        }
        
        $Assessment.EndDate = Get-Date
        $Assessment.Status = "Completed"
        
        $this.Assessments[$Assessment.AssessmentID] = $Assessment
        $this.SaveAssessment($Assessment)
        
        $this.LogActivity("AssessmentCompleted", "Completed assessment: $AssessmentName ($Framework)")
        
        return $Assessment
    }
    
    [hashtable] RunAutomatedCheck([string]$ControlID, [string]$Framework, [hashtable]$Control) {
        # Determine which automated check to run based on control characteristics
        $CheckType = $null
        
        if ($Control.Category -like "*Password*" -or $Control.Title -like "*Password*") {
            $CheckType = "PasswordPolicy"
        }
        elseif ($Control.Category -like "*Firewall*" -or $Control.Title -like "*Firewall*") {
            $CheckType = "FirewallStatus"
        }
        elseif ($Control.Category -like "*Asset*" -or $Control.Title -like "*Inventory*") {
            $CheckType = "AssetInventory"
        }
        elseif ($Control.Category -like "*Audit*" -or $Control.Title -like "*Log*") {
            $CheckType = "EventLogConfiguration"
        }
        
        if ($CheckType -and $this.AutomatedChecks.ContainsKey($CheckType)) {
            try {
                $CheckResult = & $this.AutomatedChecks[$CheckType] $ControlID $Framework
                return $CheckResult
            }
            catch {
                return @{
                    ControlID = $ControlID
                    Status = "Error"
                    Finding = "Automated check failed: $($_.Exception.Message)"
                    Timestamp = Get-Date
                }
            }
        }
        
        return $null
    }
    
    [void] SaveEvidence([string]$AssessmentID, [string]$ControlID, [hashtable]$Result) {
        $EvidenceFile = Join-Path $this.EvidencePath "$AssessmentID-$ControlID-Evidence.json"
        
        $EvidencePackage = @{
            AssessmentID = $AssessmentID
            ControlID = $ControlID
            Result = $Result
            CollectionTime = Get-Date
            Collector = $env:USERNAME
            ComputerName = $env:COMPUTERNAME
            SystemInfo = @{
                OS = (Get-ComputerInfo).WindowsProductName
                Version = (Get-ComputerInfo).WindowsVersion
                Domain = $env:USERDNSDOMAIN
            }
        }
        
        $EvidencePackage | ConvertTo-Json -Depth 10 | Out-File -FilePath $EvidenceFile -Encoding UTF8
    }
    
    [void] SaveAssessment([ComplianceAssessment]$Assessment) {
        $AssessmentFile = Join-Path $this.ConfigPath "Assessment-$($Assessment.AssessmentID).json"
        
        $AssessmentData = @{
            AssessmentID = $Assessment.AssessmentID
            AssessmentName = $Assessment.AssessmentName
            Framework = $Assessment.Framework
            StartDate = $Assessment.StartDate
            EndDate = $Assessment.EndDate
            Scope = $Assessment.Scope
            Assessor = $Assessment.Assessor
            Status = $Assessment.Status
            Results = $Assessment.Results
            Summary = $Assessment.GetSummary()
            Metadata = $Assessment.Metadata
        }
        
        $AssessmentData | ConvertTo-Json -Depth 10 | Out-File -FilePath $AssessmentFile -Encoding UTF8
    }
    
    [string] GenerateComplianceReport([string]$AssessmentID, [string]$ReportFormat = "HTML") {
        if (!$this.Assessments.ContainsKey($AssessmentID)) {
            throw "Assessment '$AssessmentID' not found"
        }
        
        $Assessment = $this.Assessments[$AssessmentID]
        $Summary = $Assessment.GetSummary()
        
        switch ($ReportFormat) {
            "HTML" {
                return $this.GenerateHTMLReport($Assessment, $Summary)
            }
            "CSV" {
                return $this.GenerateCSVReport($Assessment, $Summary)
            }
            "JSON" {
                return $Assessment | ConvertTo-Json -Depth 10
            }
            default {
                throw "Unsupported report format: $ReportFormat"
            }
        }
    }
    
    [string] GenerateHTMLReport([ComplianceAssessment]$Assessment, [hashtable]$Summary) {
        $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Compliance Assessment Report - $($Assessment.AssessmentName)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .summary { background-color: #ecf0f1; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .metrics { display: flex; justify-content: space-around; margin: 20px 0; }
        .metric { text-align: center; padding: 10px; background-color: #3498db; color: white; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #34495e; color: white; }
        .pass { background-color: #d5f4e6; color: #27ae60; }
        .fail { background-color: #fadbd8; color: #e74c3c; }
        .manual { background-color: #fef9e7; color: #f39c12; }
        .error { background-color: #d5d5d5; color: #7f8c8d; }
        .progress-bar { width: 100%; background-color: #ecf0f1; border-radius: 5px; overflow: hidden; }
        .progress-fill { height: 20px; background-color: #27ae60; transition: width 0.3s ease; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Compliance Assessment Report</h1>
        <h2>$($Assessment.AssessmentName)</h2>
        <p>Framework: $($Assessment.Framework) | Assessment ID: $($Assessment.AssessmentID)</p>
        <p>Period: $($Assessment.StartDate) to $($Assessment.EndDate)</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <div class="metrics">
            <div class="metric">
                <h3>$($Summary.CompliancePercentage)%</h3>
                <p>Compliance Rate</p>
            </div>
            <div class="metric">
                <h3>$($Summary.PassedControls)</h3>
                <p>Controls Passed</p>
            </div>
            <div class="metric">
                <h3>$($Summary.FailedControls)</h3>
                <p>Controls Failed</p>
            </div>
            <div class="metric">
                <h3>$($Summary.RiskScore)</h3>
                <p>Risk Score</p>
            </div>
        </div>
        
        <div class="progress-bar">
            <div class="progress-fill" style="width: $($Summary.CompliancePercentage)%"></div>
        </div>
        <p style="text-align: center; margin-top: 10px;">Overall Compliance: $($Summary.CompliancePercentage)%</p>
    </div>
    
    <h2>Control Assessment Results</h2>
    <table>
        <tr>
            <th>Control ID</th>
            <th>Status</th>
            <th>Finding</th>
            <th>Severity</th>
            <th>Recommendation</th>
            <th>Test Date</th>
        </tr>
"@
        
        foreach ($ControlID in $Assessment.Results.Keys) {
            $Result = $Assessment.Results[$ControlID]
            $StatusClass = $Result.Status.ToLower()
            $Severity = if ($Result.Severity) { $Result.Severity } else { "N/A" }
            $Recommendation = if ($Result.Recommendation) { $Result.Recommendation } else { "None" }
            
            $ReportHTML += @"
        <tr class="$StatusClass">
            <td>$ControlID</td>
            <td>$($Result.Status)</td>
            <td>$($Result.Finding)</td>
            <td>$Severity</td>
            <td>$Recommendation</td>
            <td>$($Result.Timestamp)</td>
        </tr>
"@
        }
        
        $ReportHTML += @"
    </table>
    
    <h2>Recommendations</h2>
    <ul>
"@
        
        # Generate recommendations based on failed controls
        $FailedControls = $Assessment.Results.Values | Where-Object { $_.Status -eq "Fail" }
        $CriticalFailures = $FailedControls | Where-Object { $_.Severity -eq "Critical" }
        $HighFailures = $FailedControls | Where-Object { $_.Severity -eq "High" }
        
        if ($CriticalFailures.Count -gt 0) {
            $ReportHTML += "        <li><strong>Critical:</strong> Address $($CriticalFailures.Count) critical control failures immediately</li>`n"
        }
        
        if ($HighFailures.Count -gt 0) {
            $ReportHTML += "        <li><strong>High Priority:</strong> Remediate $($HighFailures.Count) high-severity control failures within 30 days</li>`n"
        }
        
        if ($Summary.NotTestableControls -gt 0) {
            $ReportHTML += "        <li><strong>Manual Review:</strong> Complete manual assessment of $($Summary.NotTestableControls) controls</li>`n"
        }
        
        $ReportHTML += @"        <li>Implement automated monitoring for continuous compliance</li>
        <li>Schedule regular reassessments to maintain compliance posture</li>
        <li>Document remediation efforts and maintain evidence</li>
    </ul>
    
    <p><em>Report generated on $(Get-Date) by $($Assessment.Assessor)</em></p>
</body>
</html>
"@
        
        # Save report
        $ReportFile = Join-Path $this.ReportPath "ComplianceReport-$($Assessment.AssessmentID).html"
        $ReportHTML | Out-File -FilePath $ReportFile -Encoding UTF8
        
        return $ReportFile
    }
    
    [void] LogActivity([string]$Action, [string]$Message) {
        $LogEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = $Action
            Message = $Message
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
        }
        
        $LogFile = Join-Path $this.LogPath "Compliance-$(Get-Date -Format 'yyyyMM').log"
        $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogFile -Append -Encoding UTF8
        
        try {
            Write-EventLog -LogName Application -Source "ComplianceFramework" -EventId 10001 -EntryType Information -Message "$Action : $Message"
        }
        catch {
            # Event source might not exist, continue without error
        }
    }
}

# Global functions for compliance management
function Initialize-ComplianceFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath = "C:\Compliance"
    )
    
    $Global:ComplianceManager = [ComplianceManager]::new($BasePath)
    
    Write-Host "Compliance Framework initialized" -ForegroundColor Green
    Write-Host "Base path: $BasePath" -ForegroundColor White
    Write-Host "Available frameworks: $($Global:ComplianceManager.Frameworks.Keys -join ', ')" -ForegroundColor White
}

function Start-ComplianceAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AssessmentName,
        
        [Parameter(Mandatory)]
        [ValidateSet("NIST-CSF", "STIG", "ISO-27001")]
        [string]$Framework,
        
        [Parameter()]
        [string[]]$ControlIDs = @()
    )
    
    if (!$Global:ComplianceManager) {
        Initialize-ComplianceFramework
    }
    
    try {
        Write-Host "Starting compliance assessment: $AssessmentName" -ForegroundColor Yellow
        $Assessment = $Global:ComplianceManager.StartAssessment($AssessmentName, $Framework, $ControlIDs)
        
        $Summary = $Assessment.GetSummary()
        Write-Host "Assessment completed successfully" -ForegroundColor Green
        Write-Host "Compliance Rate: $($Summary.CompliancePercentage)%" -ForegroundColor White
        Write-Host "Controls Passed: $($Summary.PassedControls)" -ForegroundColor Green
        Write-Host "Controls Failed: $($Summary.FailedControls)" -ForegroundColor Red
        Write-Host "Risk Score: $($Summary.RiskScore)" -ForegroundColor Yellow
        
        return $Assessment
    }
    catch {
        Write-Error "Failed to complete assessment: $($_.Exception.Message)"
    }
}

function New-ComplianceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AssessmentID,
        
        [Parameter()]
        [ValidateSet("HTML", "CSV", "JSON")]
        [string]$Format = "HTML"
    )
    
    if (!$Global:ComplianceManager) {
        Initialize-ComplianceFramework
    }
    
    try {
        $ReportPath = $Global:ComplianceManager.GenerateComplianceReport($AssessmentID, $Format)
        Write-Host "Compliance report generated: $ReportPath" -ForegroundColor Green
        return $ReportPath
    }
    catch {
        Write-Error "Failed to generate report: $($_.Exception.Message)"
    }
}
```

## Continuous Compliance Monitoring

### Automated Evidence Collection

```powershell
function Enable-ContinuousCompliance {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Frameworks = @("NIST-CSF", "STIG"),
        
        [Parameter()]
        [int]$AssessmentInterval = 24,  # hours
        
        [Parameter()]
        [string]$ScheduleName = "ComplianceMonitoring"
    )
    
    # Create scheduled task for continuous monitoring
    $TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command `"Start-ComplianceAssessment -AssessmentName 'Automated-$(Get-Date -Format 'yyyyMMdd-HHmm')' -Framework '$($Frameworks[0])'`""
    $TaskTrigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $TaskPrincipal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $ScheduleName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Principal $TaskPrincipal -Description "Automated compliance assessment and monitoring"
    
    Write-Host "Continuous compliance monitoring enabled" -ForegroundColor Green
    Write-Host "Assessment interval: $AssessmentInterval hours" -ForegroundColor White
    Write-Host "Scheduled task: $ScheduleName" -ForegroundColor White
}
```

## Related Topics

- [Windows Infrastructure Security](../../windows/security/index.md)
- [Network Infrastructure Security](../../networking/security/index.md)
- [Identity and Access Management](../iam/index.md)
- [Active Directory Security](../../../services/activedirectory/Security/index.md)
- [Infrastructure Monitoring](../../monitoring/index.md)
