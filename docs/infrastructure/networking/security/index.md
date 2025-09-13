---
title: Network Infrastructure Security
description: Comprehensive network security guide covering firewall management, network segmentation, intrusion detection, and secure network design
author: Joseph Streeter
date: 2024-01-15
tags: [network-security, firewall, ids, ips, network-segmentation, vpn, wireless-security]
---

Network Infrastructure Security forms the foundation of enterprise cybersecurity, providing defense-in-depth through strategic network design, traffic monitoring, and access control mechanisms.

## Network Security Architecture

### Security Framework Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│               Network Security Architecture                     │
├─────────────────────────────────────────────────────────────────┤
│  Layer              │ Components                               │
│  ├─ Perimeter       │ Firewall, WAF, DDoS Protection         │
│  ├─ Internal        │ Segmentation, VLAN, Micro-segmentation │
│  ├─ Access          │ NAC, 802.1X, VPN, Wireless Security    │
│  ├─ Monitoring      │ IDS/IPS, SIEM, Flow Analysis           │
│  ├─ Application     │ Load Balancer, SSL/TLS, API Gateway    │
│  └─ Management      │ SNMP, SSH, Out-of-band Access          │
└─────────────────────────────────────────────────────────────────┘
```

### Core Security Principles

- **Zero Trust Architecture**: Never trust, always verify
- **Network Segmentation**: Isolate critical assets
- **Defense in Depth**: Multiple security layers
- **Continuous Monitoring**: Real-time threat detection
- **Secure by Default**: Security-first design approach

## Enterprise Firewall Management

### Advanced Firewall Configuration Framework

```powershell
<#
.SYNOPSIS
    Enterprise firewall management and automation framework.
.DESCRIPTION
    Provides comprehensive firewall policy management, change control,
    compliance verification, and automated rule optimization.
#>

class FirewallRule {
    [string]$RuleId
    [string]$Name
    [string]$Direction
    [string]$Action
    [string]$Protocol
    [string]$SourceAddress
    [string]$DestinationAddress
    [string]$SourcePort
    [string]$DestinationPort
    [string]$Application
    [string]$Service
    [bool]$Enabled
    [string]$Description
    [datetime]$CreatedDate
    [string]$CreatedBy
    [datetime]$LastModified
    [string]$ModifiedBy
    [string]$BusinessJustification
    [datetime]$ExpirationDate
    [hashtable]$Metadata
    
    FirewallRule([string]$Name, [string]$Direction, [string]$Action) {
        $this.RuleId = [Guid]::NewGuid().ToString()
        $this.Name = $Name
        $this.Direction = $Direction
        $this.Action = $Action
        $this.Protocol = "Any"
        $this.SourceAddress = "Any"
        $this.DestinationAddress = "Any"
        $this.SourcePort = "Any"
        $this.DestinationPort = "Any"
        $this.Application = "Any"
        $this.Service = "Any"
        $this.Enabled = $true
        $this.CreatedDate = Get-Date
        $this.CreatedBy = $env:USERNAME
        $this.LastModified = Get-Date
        $this.ModifiedBy = $env:USERNAME
        $this.Metadata = @{}
    }
    
    [string] ToConfigString([string]$Platform) {
        switch ($Platform) {
            "PaloAlto" {
                return $this.ToPaloAltoConfig()
            }
            "Cisco" {
                return $this.ToCiscoConfig()
            }
            "Fortinet" {
                return $this.ToFortinetConfig()
            }
            "CheckPoint" {
                return $this.ToCheckPointConfig()
            }
            default {
                return $this.ToGenericConfig()
            }
        }
    }
    
    [string] ToPaloAltoConfig() {
        $Config = @"
set rulebase security rules "$($this.Name)" from any
set rulebase security rules "$($this.Name)" to any
set rulebase security rules "$($this.Name)" source [ $($this.SourceAddress) ]
set rulebase security rules "$($this.Name)" destination [ $($this.DestinationAddress) ]
set rulebase security rules "$($this.Name)" application [ $($this.Application) ]
set rulebase security rules "$($this.Name)" service [ $($this.Service) ]
set rulebase security rules "$($this.Name)" action $($this.Action.ToLower())
set rulebase security rules "$($this.Name)" description "$($this.Description)"
"@
        if (!$this.Enabled) {
            $Config += "`nset rulebase security rules `"$($this.Name)`" disabled yes"
        }
        return $Config
    }
    
    [string] ToCiscoConfig() {
        $Direction = if ($this.Direction -eq "Inbound") { "in" } else { "out" }
        $Protocol = if ($this.Protocol -eq "Any") { "ip" } else { $this.Protocol.ToLower() }
        
        $Config = "access-list OUTSIDE_IN extended $($this.Action.ToLower()) $Protocol $($this.SourceAddress) $($this.DestinationAddress)"
        
        if ($this.DestinationPort -ne "Any") {
            $Config += " eq $($this.DestinationPort)"
        }
        
        return $Config
    }
    
    [string] ToFortinetConfig() {
        return @"
config firewall policy
    edit 0
        set name "$($this.Name)"
        set srcintf "any"
        set dstintf "any"
        set srcaddr "$($this.SourceAddress)"
        set dstaddr "$($this.DestinationAddress)"
        set service "$($this.Service)"
        set action $($this.Action.ToLower())
        set schedule "always"
        set comments "$($this.Description)"
        set status $(if ($this.Enabled) { "enable" } else { "disable" })
    next
end
"@
    }
    
    [string] ToGenericConfig() {
        return @"
Rule: $($this.Name)
  Direction: $($this.Direction)
  Action: $($this.Action)
  Protocol: $($this.Protocol)
  Source: $($this.SourceAddress):$($this.SourcePort)
  Destination: $($this.DestinationAddress):$($this.DestinationPort)
  Application: $($this.Application)
  Service: $($this.Service)
  Enabled: $($this.Enabled)
  Description: $($this.Description)
"@
    }
}

class FirewallManager {
    [hashtable]$Rules
    [hashtable]$RuleSets
    [string]$ConfigPath
    [string]$LogPath
    [string]$BackupPath
    [hashtable]$Devices
    [hashtable]$Templates
    
    FirewallManager([string]$ConfigurationPath) {
        $this.Rules = @{}
        $this.RuleSets = @{}
        $this.ConfigPath = $ConfigurationPath
        $this.LogPath = Join-Path (Split-Path $ConfigurationPath) "Logs"
        $this.BackupPath = Join-Path (Split-Path $ConfigurationPath) "Backups"
        $this.Devices = @{}
        $this.Templates = @{}
        
        # Ensure directories exist
        foreach ($Path in @($this.ConfigPath, $this.LogPath, $this.BackupPath)) {
            $Dir = if (Test-Path $Path -PathType Leaf) { Split-Path $Path } else { $Path }
            if (!(Test-Path $Dir)) {
                New-Item -ItemType Directory -Path $Dir -Force | Out-Null
            }
        }
        
        $this.InitializeTemplates()
        $this.LoadConfiguration()
    }
    
    [void] InitializeTemplates() {
        $this.Templates = @{
            "WebServerAccess" = @{
                Name = "Web Server Access"
                Rules = @(
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "80"; Description = "HTTP Access" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "443"; Description = "HTTPS Access" }
                )
            }
            
            "DatabaseServerAccess" = @{
                Name = "Database Server Access"
                Rules = @(
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "1433"; Description = "SQL Server Access" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "3306"; Description = "MySQL Access" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "5432"; Description = "PostgreSQL Access" }
                )
            }
            
            "RemoteAccessVPN" = @{
                Name = "Remote Access VPN"
                Rules = @(
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "UDP"; DestinationPort = "500"; Description = "IKE" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "UDP"; DestinationPort = "4500"; Description = "NAT-T" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "ESP"; Description = "IPSec ESP" }
                )
            }
            
            "DomainControllerAccess" = @{
                Name = "Domain Controller Access"
                Rules = @(
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "53"; Description = "DNS" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "UDP"; DestinationPort = "53"; Description = "DNS" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "88"; Description = "Kerberos" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "UDP"; DestinationPort = "88"; Description = "Kerberos" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "135"; Description = "RPC Endpoint Mapper" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "389"; Description = "LDAP" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "445"; Description = "SMB" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "464"; Description = "Kerberos Password Change" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "636"; Description = "LDAPS" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "3268"; Description = "Global Catalog" },
                    @{ Direction = "Inbound"; Action = "Allow"; Protocol = "TCP"; DestinationPort = "3269"; Description = "Global Catalog SSL" }
                )
            }
        }
    }
    
    [FirewallRule] CreateRule([string]$Name, [string]$Direction, [string]$Action) {
        if ($this.Rules.ContainsKey($Name)) {
            throw "Rule '$Name' already exists"
        }
        
        $Rule = [FirewallRule]::new($Name, $Direction, $Action)
        $this.Rules[$Name] = $Rule
        
        $this.LogActivity("RuleCreated", "Created firewall rule: $Name")
        $this.SaveConfiguration()
        
        return $Rule
    }
    
    [void] RemoveRule([string]$Name) {
        if (!$this.Rules.ContainsKey($Name)) {
            throw "Rule '$Name' not found"
        }
        
        $this.Rules.Remove($Name)
        $this.LogActivity("RuleRemoved", "Removed firewall rule: $Name")
        $this.SaveConfiguration()
    }
    
    [FirewallRule] GetRule([string]$Name) {
        if (!$this.Rules.ContainsKey($Name)) {
            throw "Rule '$Name' not found"
        }
        
        return $this.Rules[$Name]
    }
    
    [void] CreateRuleSet([string]$Name, [string]$TemplateName, [hashtable]$Parameters) {
        if (!$this.Templates.ContainsKey($TemplateName)) {
            throw "Template '$TemplateName' not found"
        }
        
        $Template = $this.Templates[$TemplateName]
        $RuleSet = @{
            Name = $Name
            Template = $TemplateName
            Rules = @()
            CreatedDate = Get-Date
            CreatedBy = $env:USERNAME
            Parameters = $Parameters
        }
        
        foreach ($RuleTemplate in $Template.Rules) {
            $RuleName = "$Name-$($RuleTemplate.Description -replace ' ', '')"
            $Rule = $this.CreateRule($RuleName, $RuleTemplate.Direction, $RuleTemplate.Action)
            
            # Apply template properties
            $Rule.Protocol = $RuleTemplate.Protocol
            $Rule.DestinationPort = $RuleTemplate.DestinationPort
            $Rule.Description = "$($Template.Name) - $($RuleTemplate.Description)"
            
            # Apply parameters
            foreach ($Param in $Parameters.GetEnumerator()) {
                switch ($Param.Key) {
                    "SourceAddress" { $Rule.SourceAddress = $Param.Value }
                    "DestinationAddress" { $Rule.DestinationAddress = $Param.Value }
                    "SourcePort" { $Rule.SourcePort = $Param.Value }
                }
            }
            
            $RuleSet.Rules += $Rule.RuleId
        }
        
        $this.RuleSets[$Name] = $RuleSet
        $this.LogActivity("RuleSetCreated", "Created rule set '$Name' from template '$TemplateName'")
        $this.SaveConfiguration()
    }
    
    [string] GenerateConfiguration([string]$Platform, [string[]]$RuleNames = @()) {
        $Configuration = @()
        $RulesToExport = if ($RuleNames.Count -gt 0) { $RuleNames } else { $this.Rules.Keys }
        
        # Add platform-specific header
        switch ($Platform) {
            "PaloAlto" {
                $Configuration += "configure"
                $Configuration += "# Generated firewall configuration for Palo Alto"
                $Configuration += "# Generated on $(Get-Date)"
                $Configuration += ""
            }
            "Cisco" {
                $Configuration += "! Generated firewall configuration for Cisco ASA"
                $Configuration += "! Generated on $(Get-Date)"
                $Configuration += ""
            }
            "Fortinet" {
                $Configuration += "# Generated firewall configuration for Fortinet FortiGate"
                $Configuration += "# Generated on $(Get-Date)"
                $Configuration += ""
            }
        }
        
        # Add rules
        foreach ($RuleName in $RulesToExport) {
            if ($this.Rules.ContainsKey($RuleName)) {
                $Rule = $this.Rules[$RuleName]
                if ($Rule.Enabled) {
                    $Configuration += $Rule.ToConfigString($Platform)
                    $Configuration += ""
                }
            }
        }
        
        # Add platform-specific footer
        switch ($Platform) {
            "PaloAlto" {
                $Configuration += "commit"
                $Configuration += "exit"
            }
            "Cisco" {
                $Configuration += "write memory"
            }
        }
        
        return $Configuration -join "`n"
    }
    
    [void] ExportConfiguration([string]$Platform, [string]$OutputPath, [string[]]$RuleNames = @()) {
        $Configuration = $this.GenerateConfiguration($Platform, $RuleNames)
        
        # Create backup before export
        $this.CreateBackup("Export-$Platform")
        
        # Save configuration
        $Configuration | Out-File -FilePath $OutputPath -Encoding UTF8
        
        $this.LogActivity("ConfigurationExported", "Exported $Platform configuration to $OutputPath")
    }
    
    [void] CreateBackup([string]$BackupName) {
        $BackupFile = Join-Path $this.BackupPath "$BackupName-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        
        $BackupData = @{
            Rules = $this.Rules
            RuleSets = $this.RuleSets
            Devices = $this.Devices
            BackupDate = Get-Date
            BackupName = $BackupName
            CreatedBy = $env:USERNAME
        }
        
        $BackupData | ConvertTo-Json -Depth 10 | Out-File -FilePath $BackupFile -Encoding UTF8
        
        $this.LogActivity("BackupCreated", "Created backup: $BackupFile")
    }
    
    [hashtable] AnalyzeRules() {
        $Analysis = @{
            TotalRules = $this.Rules.Count
            EnabledRules = 0
            DisabledRules = 0
            ExpiredRules = 0
            RedundantRules = @()
            ConflictingRules = @()
            UnusedRules = @()
            SecurityRisks = @()
            Recommendations = @()
        }
        
        $CurrentDate = Get-Date
        
        foreach ($Rule in $this.Rules.Values) {
            if ($Rule.Enabled) {
                $Analysis.EnabledRules++
            } else {
                $Analysis.DisabledRules++
            }
            
            # Check for expired rules
            if ($Rule.ExpirationDate -and $Rule.ExpirationDate -lt $CurrentDate) {
                $Analysis.ExpiredRules++
            }
            
            # Check for security risks
            if ($Rule.Action -eq "Allow" -and $Rule.SourceAddress -eq "Any" -and $Rule.DestinationAddress -eq "Any") {
                $Analysis.SecurityRisks += @{
                    RuleName = $Rule.Name
                    Risk = "Overly permissive rule allowing any-to-any traffic"
                    Severity = "High"
                    Recommendation = "Restrict source and destination addresses"
                }
            }
            
            if ($Rule.Action -eq "Allow" -and $Rule.Protocol -eq "Any" -and $Rule.DestinationPort -eq "Any") {
                $Analysis.SecurityRisks += @{
                    RuleName = $Rule.Name
                    Risk = "Rule allows all protocols and ports"
                    Severity = "Medium"
                    Recommendation = "Specify required protocols and ports"
                }
            }
        }
        
        # Generate recommendations
        if ($Analysis.ExpiredRules -gt 0) {
            $Analysis.Recommendations += "Remove or update $($Analysis.ExpiredRules) expired rules"
        }
        
        if ($Analysis.SecurityRisks.Count -gt 0) {
            $Analysis.Recommendations += "Review and tighten $($Analysis.SecurityRisks.Count) rules with security risks"
        }
        
        if ($Analysis.DisabledRules -gt 0) {
            $Analysis.Recommendations += "Remove $($Analysis.DisabledRules) disabled rules if no longer needed"
        }
        
        return $Analysis
    }
    
    [void] SaveConfiguration() {
        $ConfigData = @{
            Rules = @{}
            RuleSets = $this.RuleSets
            Devices = $this.Devices
            LastModified = Get-Date
            Version = "1.0"
        }
        
        # Convert rules to serializable format
        foreach ($RuleName in $this.Rules.Keys) {
            $Rule = $this.Rules[$RuleName]
            $ConfigData.Rules[$RuleName] = @{
                RuleId = $Rule.RuleId
                Name = $Rule.Name
                Direction = $Rule.Direction
                Action = $Rule.Action
                Protocol = $Rule.Protocol
                SourceAddress = $Rule.SourceAddress
                DestinationAddress = $Rule.DestinationAddress
                SourcePort = $Rule.SourcePort
                DestinationPort = $Rule.DestinationPort
                Application = $Rule.Application
                Service = $Rule.Service
                Enabled = $Rule.Enabled
                Description = $Rule.Description
                CreatedDate = $Rule.CreatedDate
                CreatedBy = $Rule.CreatedBy
                LastModified = $Rule.LastModified
                ModifiedBy = $Rule.ModifiedBy
                BusinessJustification = $Rule.BusinessJustification
                ExpirationDate = $Rule.ExpirationDate
                Metadata = $Rule.Metadata
            }
        }
        
        $ConfigData | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.ConfigPath -Encoding UTF8
    }
    
    [void] LoadConfiguration() {
        if (Test-Path $this.ConfigPath) {
            try {
                $ConfigData = Get-Content $this.ConfigPath | ConvertFrom-Json
                
                # Load rules
                foreach ($RuleName in $ConfigData.Rules.PSObject.Properties.Name) {
                    $RuleData = $ConfigData.Rules.$RuleName
                    $Rule = [FirewallRule]::new($RuleData.Name, $RuleData.Direction, $RuleData.Action)
                    
                    # Restore all properties
                    $Rule.RuleId = $RuleData.RuleId
                    $Rule.Protocol = $RuleData.Protocol
                    $Rule.SourceAddress = $RuleData.SourceAddress
                    $Rule.DestinationAddress = $RuleData.DestinationAddress
                    $Rule.SourcePort = $RuleData.SourcePort
                    $Rule.DestinationPort = $RuleData.DestinationPort
                    $Rule.Application = $RuleData.Application
                    $Rule.Service = $RuleData.Service
                    $Rule.Enabled = $RuleData.Enabled
                    $Rule.Description = $RuleData.Description
                    $Rule.CreatedDate = $RuleData.CreatedDate
                    $Rule.CreatedBy = $RuleData.CreatedBy
                    $Rule.LastModified = $RuleData.LastModified
                    $Rule.ModifiedBy = $RuleData.ModifiedBy
                    $Rule.BusinessJustification = $RuleData.BusinessJustification
                    $Rule.ExpirationDate = $RuleData.ExpirationDate
                    $Rule.Metadata = $RuleData.Metadata
                    
                    $this.Rules[$RuleName] = $Rule
                }
                
                # Load rule sets
                if ($ConfigData.RuleSets) {
                    $this.RuleSets = $ConfigData.RuleSets
                }
                
                # Load devices
                if ($ConfigData.Devices) {
                    $this.Devices = $ConfigData.Devices
                }
            }
            catch {
                Write-Warning "Failed to load firewall configuration: $($_.Exception.Message)"
            }
        }
    }
    
    [void] LogActivity([string]$Action, [string]$Message) {
        $LogEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = $Action
            Message = $Message
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
        }
        
        $LogFile = Join-Path $this.LogPath "Firewall-$(Get-Date -Format 'yyyyMM').log"
        $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogFile -Append -Encoding UTF8
        
        try {
            Write-EventLog -LogName Application -Source "NetworkSecurity" -EventId 9001 -EntryType Information -Message "$Action : $Message"
        }
        catch {
            # Event source might not exist, continue without error
        }
    }
}

# Global functions for firewall management
function Initialize-FirewallManagement {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = "C:\NetworkSecurity\Firewall\Configuration.json"
    )
    
    $Global:FirewallManager = [FirewallManager]::new($ConfigPath)
    
    Write-Host "Firewall Management initialized" -ForegroundColor Green
    Write-Host "Configuration path: $ConfigPath" -ForegroundColor White
}

function New-FirewallRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,
        
        [Parameter(Mandatory)]
        [ValidateSet("Allow", "Deny")]
        [string]$Action,
        
        [Parameter()]
        [string]$Protocol = "Any",
        
        [Parameter()]
        [string]$SourceAddress = "Any",
        
        [Parameter()]
        [string]$DestinationAddress = "Any",
        
        [Parameter()]
        [string]$SourcePort = "Any",
        
        [Parameter()]
        [string]$DestinationPort = "Any",
        
        [Parameter()]
        [string]$Description = "",
        
        [Parameter()]
        [string]$BusinessJustification = ""
    )
    
    if (!$Global:FirewallManager) {
        Initialize-FirewallManagement
    }
    
    try {
        $Rule = $Global:FirewallManager.CreateRule($Name, $Direction, $Action)
        
        $Rule.Protocol = $Protocol
        $Rule.SourceAddress = $SourceAddress
        $Rule.DestinationAddress = $DestinationAddress
        $Rule.SourcePort = $SourcePort
        $Rule.DestinationPort = $DestinationPort
        $Rule.Description = $Description
        $Rule.BusinessJustification = $BusinessJustification
        
        Write-Host "Firewall rule '$Name' created successfully" -ForegroundColor Green
        return $Rule
    }
    catch {
        Write-Error "Failed to create firewall rule: $($_.Exception.Message)"
    }
}

function Export-FirewallConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("PaloAlto", "Cisco", "Fortinet", "CheckPoint")]
        [string]$Platform,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter()]
        [string[]]$RuleNames = @()
    )
    
    if (!$Global:FirewallManager) {
        Initialize-FirewallManagement
    }
    
    try {
        $Global:FirewallManager.ExportConfiguration($Platform, $OutputPath, $RuleNames)
        Write-Host "Configuration exported to: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export configuration: $($_.Exception.Message)"
    }
}
```

## Network Intrusion Detection and Prevention

### Advanced IDS/IPS Implementation

```powershell
function Deploy-NetworkIDS {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$SensorLocations = @(),
        
        [Parameter()]
        [string]$ManagementServer = "ids-mgmt.company.com",
        
        [Parameter()]
        [string]$ConfigPath = "C:\NetworkSecurity\IDS\Configuration.json"
    )
    
    $IDSConfig = @{
        ManagementServer = $ManagementServer
        Sensors = @{}
        Rules = @{}
        AlertPolicies = @{}
        ReportingConfig = @{
            SIEMIntegration = $true
            SyslogServer = "siem.company.com"
            SyslogPort = 514
            EmailAlerts = $true
            SMTPServer = "smtp.company.com"
            AlertRecipients = @("security@company.com")
        }
        ThreatIntelligence = @{
            FeedSources = @(
                "https://threatintel.company.com/feeds/malware",
                "https://threatintel.company.com/feeds/botnet",
                "https://threatintel.company.com/feeds/apt"
            )
            UpdateInterval = 3600  # 1 hour
            AutoBlock = $true
            BlockDuration = 86400  # 24 hours
        }
        PerformanceSettings = @{
            MaxConcurrentSessions = 10000
            MemoryLimit = "8GB"
            DiskSpaceThreshold = 80
            LogRetention = 90  # days
        }
    }
    
    # Configure sensors
    foreach ($Location in $SensorLocations) {
        $SensorConfig = @{
            Name = "IDS-Sensor-$Location"
            Location = $Location
            IPAddress = "192.168.1.100"  # This would be dynamically assigned
            MonitoredInterfaces = @("eth0", "eth1")
            AnalysisMode = "Inline"  # Inline or Passive
            BlockingEnabled = $true
            AlertThreshold = "Medium"
            CustomRules = @()
            Status = "Active"
            LastUpdate = Get-Date
        }
        
        $IDSConfig.Sensors[$Location] = $SensorConfig
    }
    
    # Configure default detection rules
    $IDSConfig.Rules = @{
        "MalwareDetection" = @{
            RuleId = "MAL-001"
            Name = "Malware Communication Detection"
            Category = "Malware"
            Severity = "High"
            Pattern = "Known malware C&C communication patterns"
            Action = "Alert"
            Enabled = $true
        }
        
        "BruteForceDetection" = @{
            RuleId = "ATK-001"
            Name = "Brute Force Attack Detection"
            Category = "Attack"
            Severity = "Medium"
            Pattern = "Multiple failed authentication attempts"
            Action = "Alert"
            Enabled = $true
            Threshold = @{
                Count = 10
                TimeWindow = 300  # 5 minutes
            }
        }
        
        "PortScanDetection" = @{
            RuleId = "SCN-001"
            Name = "Port Scan Detection"
            Category = "Reconnaissance"
            Severity = "Low"
            Pattern = "Systematic port scanning activity"
            Action = "Alert"
            Enabled = $true
            Threshold = @{
                PortsScanned = 20
                TimeWindow = 60  # 1 minute
            }
        }
        
        "DataExfiltration" = @{
            RuleId = "EXF-001"
            Name = "Potential Data Exfiltration"
            Category = "Data Loss"
            Severity = "Critical"
            Pattern = "Large outbound data transfers"
            Action = "Block"
            Enabled = $true
            Threshold = @{
                DataSize = "100MB"
                TimeWindow = 300  # 5 minutes
            }
        }
        
        "APTCommunication" = @{
            RuleId = "APT-001"
            Name = "APT Communication Patterns"
            Category = "Advanced Threat"
            Severity = "Critical"
            Pattern = "Known APT communication signatures"
            Action = "Block"
            Enabled = $true
        }
    }
    
    # Configure alert policies
    $IDSConfig.AlertPolicies = @{
        "Critical" = @{
            ImmediateNotification = $true
            EscalationTime = 300  # 5 minutes
            EscalationRecipients = @("soc@company.com", "ciso@company.com")
            AutoResponse = $true
            ResponseActions = @("BlockIP", "IsolateHost", "CreateTicket")
        }
        
        "High" = @{
            ImmediateNotification = $true
            EscalationTime = 900  # 15 minutes
            EscalationRecipients = @("soc@company.com")
            AutoResponse = $true
            ResponseActions = @("BlockIP", "CreateTicket")
        }
        
        "Medium" = @{
            ImmediateNotification = $false
            BatchNotification = $true
            BatchInterval = 3600  # 1 hour
            AutoResponse = $false
            ResponseActions = @("LogEvent")
        }
        
        "Low" = @{
            ImmediateNotification = $false
            BatchNotification = $true
            BatchInterval = 14400  # 4 hours
            AutoResponse = $false
            ResponseActions = @("LogEvent")
        }
    }
    
    # Save configuration
    $ConfigDir = Split-Path $ConfigPath
    if (!(Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    $IDSConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    Write-Host "IDS/IPS configuration deployed" -ForegroundColor Green
    Write-Host "Sensors configured: $($SensorLocations.Count)" -ForegroundColor White
    Write-Host "Detection rules: $($IDSConfig.Rules.Count)" -ForegroundColor White
    Write-Host "Configuration saved to: $ConfigPath" -ForegroundColor White
    
    return $IDSConfig
}

function Get-NetworkSecurityEvents {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$DaysBack = 7,
        
        [Parameter()]
        [string[]]$Severity = @("Critical", "High"),
        
        [Parameter()]
        [string]$OutputFormat = "Table",  # Table, JSON, CSV
        
        [Parameter()]
        [string]$ReportPath = "C:\NetworkSecurity\Reports\SecurityEvents.html"
    )
    
    $StartDate = (Get-Date).AddDays(-$DaysBack)
    $SecurityEvents = @()
    
    # This would integrate with your actual IDS/IPS solution
    # For demonstration, we'll simulate event collection
    
    # Simulate security events
    $EventTypes = @(
        @{ Type = "Malware Detection"; Severity = "Critical"; Source = "192.168.1.50"; Destination = "malware-c2.example.com" },
        @{ Type = "Brute Force Attack"; Severity = "High"; Source = "10.0.0.100"; Destination = "192.168.1.10" },
        @{ Type = "Port Scan"; Severity = "Medium"; Source = "172.16.0.50"; Destination = "192.168.1.0/24" },
        @{ Type = "Data Exfiltration"; Severity = "Critical"; Source = "192.168.1.25"; Destination = "external-server.com" },
        @{ Type = "APT Communication"; Severity = "Critical"; Source = "192.168.1.30"; Destination = "apt-c2.example.com" }
    )
    
    # Generate sample events
    for ($i = 0; $i -lt 50; $i++) {
        $EventType = $EventTypes | Get-Random
        $EventTime = $StartDate.AddMinutes((Get-Random -Minimum 0 -Maximum ($DaysBack * 1440)))
        
        if ($EventType.Severity -in $Severity) {
            $SecurityEvents += [PSCustomObject]@{
                EventId = [Guid]::NewGuid().ToString()
                Timestamp = $EventTime
                EventType = $EventType.Type
                Severity = $EventType.Severity
                SourceIP = $EventType.Source
                DestinationIP = $EventType.Destination
                SensorLocation = "DMZ-Sensor-01"
                RuleId = "$(($EventType.Type -replace ' ', '').Substring(0,3).ToUpper())-001"
                Description = "Detected $($EventType.Type) from $($EventType.Source) to $($EventType.Destination)"
                Status = "Open"
                AssignedTo = "SOC Team"
                ResponseActions = @("Alert Generated", "IP Logged")
            }
        }
    }
    
    # Sort by timestamp (newest first)
    $SecurityEvents = $SecurityEvents | Sort-Object Timestamp -Descending
    
    # Output based on format
    switch ($OutputFormat) {
        "Table" {
            return $SecurityEvents | Format-Table -AutoSize
        }
        
        "JSON" {
            return $SecurityEvents | ConvertTo-Json -Depth 5
        }
        
        "CSV" {
            $CSVPath = $ReportPath -replace '\.html$', '.csv'
            $SecurityEvents | Export-Csv -Path $CSVPath -NoTypeInformation
            Write-Host "CSV report saved to: $CSVPath" -ForegroundColor Green
            return $SecurityEvents
        }
        
        default {
            # Generate HTML report
            $CriticalEvents = ($SecurityEvents | Where-Object Severity -eq "Critical").Count
            $HighEvents = ($SecurityEvents | Where-Object Severity -eq "High").Count
            $TotalEvents = $SecurityEvents.Count
            
            $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Network Security Events Report</title>
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
        <h1>Network Security Events Report</h1>
        <p>Report Period: $StartDate to $(Get-Date)</p>
    </div>
    
    <div class="summary">
        <h2>Event Summary</h2>
        <ul>
            <li>Total Events: $TotalEvents</li>
            <li>Critical: $CriticalEvents</li>
            <li>High: $HighEvents</li>
            <li>Event Sources: $($SecurityEvents | Select-Object -ExpandProperty SensorLocation | Select-Object -Unique | Measure-Object).Count sensors</li>
        </ul>
    </div>
    
    <h2>Security Events</h2>
    <table>
        <tr>
            <th>Time</th>
            <th>Event Type</th>
            <th>Severity</th>
            <th>Source IP</th>
            <th>Destination IP</th>
            <th>Sensor</th>
            <th>Status</th>
        </tr>
"@
            
            foreach ($Event in ($SecurityEvents | Select-Object -First 100)) {
                $RowClass = $Event.Severity.ToLower()
                
                $ReportHTML += @"
        <tr class="$RowClass">
            <td>$($Event.Timestamp)</td>
            <td>$($Event.EventType)</td>
            <td>$($Event.Severity)</td>
            <td>$($Event.SourceIP)</td>
            <td>$($Event.DestinationIP)</td>
            <td>$($Event.SensorLocation)</td>
            <td>$($Event.Status)</td>
        </tr>
"@
            }
            
            $ReportHTML += @"
    </table>
    
    <h2>Response Recommendations</h2>
    <ul>
        <li>Investigate all critical severity events immediately</li>
        <li>Review source IPs for potential compromise indicators</li>
        <li>Update threat intelligence feeds with new IOCs</li>
        <li>Consider network segmentation for high-risk sources</li>
        <li>Enhance monitoring for detected attack patterns</li>
    </ul>
    
    <p><em>Generated by Network Security Monitoring System</em></p>
</body>
</html>
"@
            
            # Save HTML report
            $ReportDir = Split-Path $ReportPath
            if (!(Test-Path $ReportDir)) {
                New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
            }
            
            $ReportHTML | Out-File -FilePath $ReportPath -Encoding UTF8
            
            Write-Host "Security events report generated: $ReportPath" -ForegroundColor Green
            Write-Host "Critical Events: $CriticalEvents" -ForegroundColor Red
            Write-Host "High Severity Events: $HighEvents" -ForegroundColor Yellow
            
            return $SecurityEvents
        }
    }
}
```

## Network Access Control (NAC)

### 802.1X and Device Authentication

```powershell
function Deploy-NetworkAccessControl {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$SwitchIPs = @(),
        
        [Parameter()]
        [string]$RADIUSServer = "radius.company.com",
        
        [Parameter()]
        [string]$SharedSecret = "RadiusSharedSecret123!",
        
        [Parameter()]
        [string]$ConfigPath = "C:\NetworkSecurity\NAC\Configuration.json"
    )
    
    $NACConfig = @{
        RADIUSConfiguration = @{
            PrimaryServer = $RADIUSServer
            SecondaryServer = "radius-backup.company.com"
            AuthenticationPort = 1812
            AccountingPort = 1813
            SharedSecret = $SharedSecret
            Timeout = 5
            Retries = 3
        }
        
        AuthenticationPolicies = @{
            "DomainComputers" = @{
                Description = "Corporate domain-joined devices"
                AuthenticationMethod = "EAP-TLS"
                CertificateRequirement = "Machine Certificate"
                VLAN = 100
                AccessLevel = "Full"
                BandwidthLimit = "Unlimited"
                AllowedServices = @("All")
            }
            
            "DomainUsers" = @{
                Description = "Domain user authentication"
                AuthenticationMethod = "PEAP-MSCHAPv2"
                CertificateRequirement = "User Certificate"
                VLAN = 200
                AccessLevel = "Standard"
                BandwidthLimit = "50Mbps"
                AllowedServices = @("Web", "Email", "FileShare")
            }
            
            "GuestDevices" = @{
                Description = "Visitor and guest devices"
                AuthenticationMethod = "Web Portal"
                CertificateRequirement = "None"
                VLAN = 300
                AccessLevel = "Limited"
                BandwidthLimit = "10Mbps"
                AllowedServices = @("Web")
                SessionTimeout = 14400  # 4 hours
            }
            
            "IoTDevices" = @{
                Description = "Internet of Things devices"
                AuthenticationMethod = "MAC Authentication"
                CertificateRequirement = "None"
                VLAN = 400
                AccessLevel = "IoT"
                BandwidthLimit = "5Mbps"
                AllowedServices = @("Management", "NTP", "DNS")
            }
            
            "QuarantineDevices" = @{
                Description = "Non-compliant or suspicious devices"
                AuthenticationMethod = "None"
                CertificateRequirement = "None"
                VLAN = 999
                AccessLevel = "Quarantine"
                BandwidthLimit = "1Mbps"
                AllowedServices = @("Remediation")
            }
        }
        
        ComplianceChecks = @{
            "AntivirusCheck" = @{
                Enabled = $true
                RequiredProducts = @("Windows Defender", "Symantec", "McAfee")
                RequireRealTimeProtection = $true
                MaxDefinitionAge = 7  # days
            }
            
            "OSPatchLevel" = @{
                Enabled = $true
                RequireCurrentPatchLevel = $true
                MaxPatchAge = 30  # days
                CriticalPatchGracePeriod = 7  # days
            }
            
            "FirewallStatus" = @{
                Enabled = $true
                RequireEnabled = $true
                AllowedProducts = @("Windows Firewall", "Corporate Firewall")
            }
            
            "EncryptionStatus" = @{
                Enabled = $true
                RequireDiskEncryption = $true
                AllowedProducts = @("BitLocker", "FileVault", "TrueCrypt")
            }
        }
        
        NetworkSegmentation = @{
            VLANs = @{
                100 = @{ Name = "Corporate"; Description = "Domain-joined computers"; Subnet = "10.1.0.0/24" }
                200 = @{ Name = "Users"; Description = "User authentication"; Subnet = "10.2.0.0/24" }
                300 = @{ Name = "Guest"; Description = "Guest and visitor access"; Subnet = "10.3.0.0/24" }
                400 = @{ Name = "IoT"; Description = "Internet of Things devices"; Subnet = "10.4.0.0/24" }
                999 = @{ Name = "Quarantine"; Description = "Non-compliant devices"; Subnet = "10.99.0.0/24" }
            }
            
            ACLs = @{
                "Corporate" = @{
                    AllowInternet = $true
                    AllowInternalResources = $true
                    AllowPrinting = $true
                    AllowFileShares = $true
                }
                
                "Users" = @{
                    AllowInternet = $true
                    AllowInternalResources = $true
                    AllowPrinting = $true
                    AllowFileShares = $false
                }
                
                "Guest" = @{
                    AllowInternet = $true
                    AllowInternalResources = $false
                    AllowPrinting = $false
                    AllowFileShares = $false
                }
                
                "IoT" = @{
                    AllowInternet = $false
                    AllowInternalResources = $false
                    AllowPrinting = $false
                    AllowFileShares = $false
                    AllowedDestinations = @("time.company.com", "management.company.com")
                }
                
                "Quarantine" = @{
                    AllowInternet = $false
                    AllowInternalResources = $false
                    AllowPrinting = $false
                    AllowFileShares = $false
                    AllowedDestinations = @("remediation.company.com")
                }
            }
        }
        
        MonitoringAndReporting = @{
            LogAllAuthenticationAttempts = $true
            LogFailedAttempts = $true
            AlertOnMultipleFailures = $true
            FailureThreshold = 5
            TimeWindow = 300  # 5 minutes
            ReportingInterval = 3600  # 1 hour
            SyslogServer = "siem.company.com"
        }
    }
    
    # Configure switches
    foreach ($SwitchIP in $SwitchIPs) {
        Write-Host "Configuring NAC on switch $SwitchIP..." -ForegroundColor Yellow
        
        # This would be implemented based on your switch vendor (Cisco, HP, etc.)
        $SwitchConfig = Generate-SwitchNACConfig -SwitchIP $SwitchIP -NACConfig $NACConfig
        
        # Apply configuration via SSH/SNMP/API
        # Apply-SwitchConfiguration -SwitchIP $SwitchIP -Configuration $SwitchConfig
        
        Write-Host "NAC configuration applied to switch $SwitchIP" -ForegroundColor Green
    }
    
    # Save configuration
    $ConfigDir = Split-Path $ConfigPath
    if (!(Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    $NACConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    Write-Host "Network Access Control deployed successfully" -ForegroundColor Green
    Write-Host "Configuration saved to: $ConfigPath" -ForegroundColor White
    Write-Host "Configured switches: $($SwitchIPs.Count)" -ForegroundColor White
    
    return $NACConfig
}

function Generate-SwitchNACConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SwitchIP,
        
        [Parameter(Mandatory)]
        [hashtable]$NACConfig
    )
    
    # This is a simplified example for Cisco switches
    $SwitchConfig = @"
! NAC Configuration for Switch $SwitchIP
! Generated on $(Get-Date)

! Enable AAA
aaa new-model
aaa authentication dot1x default group radius
aaa authorization network default group radius
aaa accounting dot1x default start-stop group radius

! RADIUS Server Configuration
radius server ISE-Primary
 address ipv4 $($NACConfig.RADIUSConfiguration.PrimaryServer) auth-port $($NACConfig.RADIUSConfiguration.AuthenticationPort) acct-port $($NACConfig.RADIUSConfiguration.AccountingPort)
 key $($NACConfig.RADIUSConfiguration.SharedSecret)
 timeout $($NACConfig.RADIUSConfiguration.Timeout)
 retransmit $($NACConfig.RADIUSConfiguration.Retries)

radius server ISE-Secondary
 address ipv4 $($NACConfig.RADIUSConfiguration.SecondaryServer) auth-port $($NACConfig.RADIUSConfiguration.AuthenticationPort) acct-port $($NACConfig.RADIUSConfiguration.AccountingPort)
 key $($NACConfig.RADIUSConfiguration.SharedSecret)
 timeout $($NACConfig.RADIUSConfiguration.Timeout)
 retransmit $($NACConfig.RADIUSConfiguration.Retries)

! RADIUS Group Configuration
aaa group server radius ISE-GROUP
 server name ISE-Primary
 server name ISE-Secondary

! Enable 802.1X globally
dot1x system-auth-control

! VLAN Configuration
"@
    
    foreach ($VLAN in $NACConfig.NetworkSegmentation.VLANs.GetEnumerator()) {
        $SwitchConfig += @"
vlan $($VLAN.Key)
 name $($VLAN.Value.Name)

"@
    }
    
    $SwitchConfig += @"

! Interface Template for Access Ports
interface range GigabitEthernet1/0/1-48
 switchport mode access
 switchport access vlan 999
 authentication event fail action authorize vlan 999
 authentication event server dead action authorize vlan 999
 authentication event server alive action reinitialize
 authentication host-mode multi-host
 authentication order dot1x mab
 authentication priority dot1x mab
 authentication port-control auto
 authentication periodic
 authentication timer reauthenticate server
 dot1x pae authenticator
 dot1x timeout tx-period 3
 mab
 spanning-tree portfast
 spanning-tree bpduguard enable

! Logging Configuration
logging buffered 64000
logging host $($NACConfig.MonitoringAndReporting.SyslogServer)
logging trap informational

! SNMP Configuration (if applicable)
snmp-server community public RO
snmp-server host $($NACConfig.MonitoringAndReporting.SyslogServer) version 2c public

end
"@
    
    return $SwitchConfig
}
```

## Related Topics

- [Windows Infrastructure Security](../../windows/security/index.md)
- [Active Directory Security](../../../services/activedirectory/Security/index.md)
- [Identity and Access Management](../../security/iam/index.md)
- [Infrastructure Monitoring](../../monitoring/index.md)
- [Compliance and Auditing](../../security/compliance/index.md)
