---
uid: ad-sites-subnets
title: "Active Directory Sites and Subnets Design Guide"
description: "Comprehensive guide for designing, implementing, and managing Active Directory Sites and Subnets with modern optimization, automation, and enterprise best practices."
author: "Active Directory Team"
ms.author: "adteam"
ms.date: "07/05/2025"
ms.topic: "conceptual"
ms.service: "active-directory"
ms.subservice: "sites-subnets"
keywords: ["Sites and Subnets", "AD Replication", "Site Topology", "Network Optimization", "PowerShell", "Automation", "KCC", "Site Links"]
---

This comprehensive guide provides enterprise-level strategies for designing, implementing, and managing Active Directory Sites and Subnets with modern optimization techniques, automated management, and network performance best practices.

## Overview

Active Directory Sites and Subnets represent the physical network topology within an AD environment, enabling efficient replication, authentication optimization, and network traffic management. Modern site design incorporates cloud integration, advanced monitoring, and automated optimization to ensure optimal performance across hybrid and multi-site environments.

Proper site and subnet configuration is critical for:

- **Replication optimization**: Efficient domain controller synchronization
- **Authentication efficiency**: Localized logon and service requests
- **Network optimization**: Reduced WAN traffic and improved performance
- **Service location**: Optimal client-to-server connections
- **Disaster recovery**: Resilient multi-site operations

## Prerequisites

### Technical Requirements

- Windows Server 2019 or later (Windows Server 2022 recommended)
- Active Directory Domain Services with appropriate functional levels
- PowerShell 5.1 or later with ActiveDirectory module
- Network documentation and IP address management (IPAM)
- Administrative access with appropriate permissions

### Network Planning Requirements

- Complete network topology documentation
- IP address schema and subnet allocation
- WAN link bandwidth and latency measurements
- Geographic location mapping
- Future expansion projections

### Skills and Knowledge

- Understanding of TCP/IP networking and subnetting
- Active Directory replication concepts
- PowerShell scripting capabilities
- Network monitoring and analysis tools
- Change management processes

## Core Concepts and Architecture

### Active Directory Sites

**Definition**: A site represents one or more well-connected IP subnets, typically representing a physical location with high-speed, reliable network connectivity.

**Purpose**:

- Control replication traffic and schedules
- Optimize authentication and service location
- Manage Group Policy application
- Support disaster recovery scenarios

### Subnets

**Definition**: IP address ranges that define network segments and their association with specific sites.

**Purpose**:

- Enable automatic site assignment for domain controllers and clients
- Control service location and authentication paths
- Optimize network traffic flow
- Support network segmentation strategies

### Site Links

**Definition**: Logical connections between sites that define replication paths, costs, and schedules.

**Purpose**:

- Control inter-site replication topology
- Define replication costs and preferences
- Schedule replication windows
- Enable replication monitoring and optimization

## Enterprise Site Design Framework

### Modern Site Topology Models

#### 1. Hub-and-Spoke Model

```text
                   [Main Site - Hub]
                  /        |        \
                 /         |         \
        [Branch Site A] [Branch Site B] [Branch Site C]
             |               |               |
        [Sub-Branch 1]  [Sub-Branch 2]  [Sub-Branch 3]
```

**Benefits**:

- Centralized replication management
- Simplified troubleshooting
- Reduced complexity
- Cost-effective for most scenarios

**Use Cases**:

- Traditional corporate networks
- Centralized IT management
- Predictable traffic patterns

#### 2. Mesh Topology Model

```text
        [Site A] ---- [Site B]
           |  \      /  |
           |   \    /   |
           |    \  /    |
        [Site D] ---- [Site C]
```

**Benefits**:

- Redundant replication paths
- Faster convergence
- Better fault tolerance
- Optimized for high-availability

**Use Cases**:

- Mission-critical environments
- Geographically distributed organizations
- High-availability requirements

#### 3. Hybrid Cloud Model

```text
    [On-Premises Main Site]
              |
        [Azure Region 1] ---- [Azure Region 2]
              |                      |
    [Branch Office A]        [Branch Office B]
```

**Benefits**:

- Cloud integration capabilities
- Scalable architecture
- Global presence support
- Disaster recovery integration

**Use Cases**:

- Hybrid cloud environments
- Global organizations
- Cloud-first strategies

### Site Design Principles

#### 1. Network-Based Design

##### Physical Network Alignment

- Sites should reflect actual network topology
- Consider bandwidth and latency constraints
- Account for network redundancy and failover
- Plan for network growth and changes

##### Bandwidth Considerations

- High-speed links (>10 Mbps): Single site consideration
- Medium-speed links (1-10 Mbps): Separate sites with optimized replication
- Low-speed links (<1 Mbps): Separate sites with scheduled replication

#### 2. Administrative Boundaries

##### Geographic Distribution

- Align sites with physical locations
- Consider administrative boundaries
- Account for time zones and business hours
- Plan for local IT support capabilities

##### Service Optimization

- Localize authentication services
- Optimize Group Policy application
- Enable efficient resource location
- Support disaster recovery scenarios

#### 3. Scalability and Growth

##### Future Planning

- Design for projected network growth
- Consider cloud integration requirements
- Plan for additional locations
- Account for technology evolution

## Implementation Guide

### Phase 1: Network Assessment and Planning

```powershell
# Comprehensive network assessment for site planning
function Invoke-NetworkAssessment {
    param(
        [string]$DomainName = (Get-ADDomain).DNSRoot,
        [string]$ReportPath = "C:\Reports\Network_Assessment_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    try {
        Write-Host "Starting network assessment for site planning..." -ForegroundColor Green
        
        # Get current site and subnet information
        $CurrentSites = Get-ADReplicationSite -Filter * | Sort-Object Name
        $CurrentSubnets = Get-ADReplicationSubnet -Filter * | Sort-Object Name
        $SiteLinks = Get-ADReplicationSiteLink -Filter * | Sort-Object Name
        
        # Analyze domain controller distribution
        $DomainControllers = Get-ADDomainController -Filter * | Group-Object Site
        
        # Assess current configuration
        $Assessment = @{
            TotalSites = $CurrentSites.Count
            TotalSubnets = $CurrentSubnets.Count
            TotalSiteLinks = $SiteLinks.Count
            DCDistribution = @{}
            SiteGaps = @()
            SubnetGaps = @()
            OptimizationOpportunities = @()
        }
        
        # Analyze DC distribution
        foreach ($SiteGroup in $DomainControllers) {
            $Assessment.DCDistribution[$SiteGroup.Name] = $SiteGroup.Count
        }
        
        # Identify sites without DCs
        foreach ($Site in $CurrentSites) {
            if ($Site.Name -notin $DomainControllers.Name) {
                $Assessment.SiteGaps += $Site.Name
            }
        }
        
        # Network latency testing
        $LatencyResults = @()
        foreach ($DC in (Get-ADDomainController -Filter *)) {
            try {
                $Latency = Test-Connection -ComputerName $DC.HostName -Count 3 -Quiet
                $LatencyResults += @{
                    DC = $DC.Name
                    Site = $DC.Site
                    Reachable = $Latency
                    Hostname = $DC.HostName
                }
            }
            catch {
                $LatencyResults += @{
                    DC = $DC.Name
                    Site = $DC.Site
                    Reachable = $false
                    Hostname = $DC.HostName
                }
            }
        }
        
        # Generate comprehensive assessment report
        $HTMLReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Network Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; }
        .section { margin: 20px 0; }
        .metric { background-color: #f8f9fa; padding: 15px; margin: 10px 0; border-left: 4px solid #0078d4; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .warning { color: #d83b01; font-weight: bold; }
        .success { color: #107c10; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Network Assessment Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Domain: $DomainName</p>
    </div>
    
    <div class="section">
        <h2>Current Infrastructure Summary</h2>
        <div class="metric"><strong>Total Sites:</strong> $($Assessment.TotalSites)</div>
        <div class="metric"><strong>Total Subnets:</strong> $($Assessment.TotalSubnets)</div>
        <div class="metric"><strong>Total Site Links:</strong> $($Assessment.TotalSiteLinks)</div>
        <div class="metric"><strong>Sites without DCs:</strong> <span class="warning">$($Assessment.SiteGaps.Count)</span></div>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Implement automated site and subnet management</li>
            <li>Optimize replication schedules for WAN efficiency</li>
            <li>Deploy monitoring for replication health</li>
            <li>Consider cloud integration for hybrid scenarios</li>
            <li>Implement network change detection automation</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Domain Controller Distribution</h2>
        <table>
            <tr><th>Site</th><th>Domain Controllers</th><th>Status</th></tr>
"@
        
        foreach ($Site in $CurrentSites) {
            $DCCount = if ($Assessment.DCDistribution.ContainsKey($Site.Name)) { $Assessment.DCDistribution[$Site.Name] } else { 0 }
            $Status = if ($DCCount -gt 0) { '<span class="success">Active</span>' } else { '<span class="warning">No DCs</span>' }
            $HTMLReport += "<tr><td>$($Site.Name)</td><td>$DCCount</td><td>$Status</td></tr>"
        }
        
        $HTMLReport += @"
        </table>
    </div>
</body>
</html>
"@
        
        $HTMLReport | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-Host "Network assessment completed. Report: $ReportPath" -ForegroundColor Green
        
        return $Assessment
    }
    catch {
        Write-Error "Failed to complete network assessment: $($_.Exception.Message)"
    }
}
```

### Phase 2: Site and Subnet Design

```powershell
# Design and create optimal site structure
function New-OptimalSiteStructure {
    param(
        [Parameter(Mandatory)]
        [hashtable]$SiteDesign,
        [switch]$WhatIf,
        [switch]$IncludeCloudSites
    )
    
    try {
        Write-Host "Creating optimal site structure..." -ForegroundColor Green
        
        # Example enterprise site design template
        if (-not $PSBoundParameters.ContainsKey('SiteDesign')) {
            $SiteDesign = @{
                "Headquarters" = @{
                    Description = "Primary corporate headquarters"
                    Subnets = @("10.0.0.0/16", "192.168.1.0/24")
                    Location = "Main Campus"
                    Type = "Hub"
                }
                "Branch-East" = @{
                    Description = "Eastern regional office"
                    Subnets = @("10.1.0.0/16")
                    Location = "East Coast"
                    Type = "Spoke"
                }
                "Branch-West" = @{
                    Description = "Western regional office"
                    Subnets = @("10.2.0.0/16")
                    Location = "West Coast"
                    Type = "Spoke"
                }
                "DataCenter-Primary" = @{
                    Description = "Primary data center"
                    Subnets = @("172.16.0.0/16")
                    Location = "Primary DC"
                    Type = "Hub"
                }
            }
            
            if ($IncludeCloudSites) {
                $SiteDesign["Azure-EastUS"] = @{
                    Description = "Azure East US region"
                    Subnets = @("10.100.0.0/16")
                    Location = "Azure East US"
                    Type = "Cloud"
                }
                $SiteDesign["Azure-WestUS"] = @{
                    Description = "Azure West US region"
                    Subnets = @("10.101.0.0/16")
                    Location = "Azure West US"
                    Type = "Cloud"
                }
            }
        }
        
        # Create sites
        foreach ($SiteName in $SiteDesign.Keys) {
            $SiteConfig = $SiteDesign[$SiteName]
            
            if ($WhatIf) {
                Write-Host "WHATIF: Would create site: $SiteName" -ForegroundColor Yellow
                Write-Host "  Description: $($SiteConfig.Description)"
                Write-Host "  Location: $($SiteConfig.Location)"
                Write-Host "  Type: $($SiteConfig.Type)"
                Write-Host "  Subnets: $($SiteConfig.Subnets -join ', ')"
                continue
            }
            
            # Create the site
            try {
                $ExistingSite = Get-ADReplicationSite -Filter "Name -eq '$SiteName'" -ErrorAction SilentlyContinue
                if (-not $ExistingSite) {
                    New-ADReplicationSite -Name $SiteName -Description $SiteConfig.Description
                    Write-Host "Created site: $SiteName" -ForegroundColor Green
                    
                    # Set additional properties
                    Set-ADReplicationSite -Identity $SiteName -Replace @{
                        location = $SiteConfig.Location
                    }
                } else {
                    Write-Host "Site already exists: $SiteName" -ForegroundColor Yellow
                }
                
                # Create and associate subnets
                foreach ($SubnetCIDR in $SiteConfig.Subnets) {
                    try {
                        $ExistingSubnet = Get-ADReplicationSubnet -Filter "Name -eq '$SubnetCIDR'" -ErrorAction SilentlyContinue
                        if (-not $ExistingSubnet) {
                            New-ADReplicationSubnet -Name $SubnetCIDR -Site $SiteName -Description "Subnet for $($SiteConfig.Description)"
                            Write-Host "  Created subnet: $SubnetCIDR in site $SiteName" -ForegroundColor Green
                        } else {
                            # Update site association if different
                            if ($ExistingSubnet.Site -ne $SiteName) {
                                Set-ADReplicationSubnet -Identity $SubnetCIDR -Site $SiteName
                                Write-Host "  Updated subnet site association: $SubnetCIDR -> $SiteName" -ForegroundColor Yellow
                            }
                        }
                    }
                    catch {
                        Write-Warning "Failed to create subnet $SubnetCIDR`: $($_.Exception.Message)"
                    }
                }
            }
            catch {
                Write-Error "Failed to create site $SiteName`: $($_.Exception.Message)"
            }
        }
        
        Write-Host "Site structure creation completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create optimal site structure: $($_.Exception.Message)"
    }
}
```

### Phase 3: Site Link Optimization

```powershell
# Create and optimize site links for efficient replication
function New-OptimizedSiteLinks {
    param(
        [Parameter(Mandatory)]
        [hashtable]$SiteLinkDesign,
        [string]$DefaultTransport = "IP",
        [int]$DefaultCost = 100,
        [int]$DefaultReplicationInterval = 15,
        [switch]$WhatIf
    )
    
    try {
        Write-Host "Creating optimized site links..." -ForegroundColor Green
        
        # Example site link design for hub-and-spoke topology
        if (-not $PSBoundParameters.ContainsKey('SiteLinkDesign')) {
            $SiteLinkDesign = @{
                "HQ-DataCenter" = @{
                    Sites = @("Headquarters", "DataCenter-Primary")
                    Cost = 50
                    ReplicationInterval = 15
                    Description = "High-speed link between HQ and primary data center"
                    ChangeNotification = $true
                }
                "HQ-BranchEast" = @{
                    Sites = @("Headquarters", "Branch-East")
                    Cost = 100
                    ReplicationInterval = 30
                    Description = "WAN link to eastern branch office"
                    ChangeNotification = $false
                }
                "HQ-BranchWest" = @{
                    Sites = @("Headquarters", "Branch-West")
                    Cost = 100
                    ReplicationInterval = 30
                    Description = "WAN link to western branch office"
                    ChangeNotification = $false
                }
                "HQ-Azure" = @{
                    Sites = @("Headquarters", "Azure-EastUS")
                    Cost = 75
                    ReplicationInterval = 60
                    Description = "Internet link to Azure region"
                    ChangeNotification = $false
                    Schedule = "Mon-Fri 6PM-6AM, Sat-Sun All Day"
                }
            }
        }
        
        # Remove default site link if it exists and is not needed
        try {
            $DefaultSiteLink = Get-ADReplicationSiteLink -Filter "Name -eq 'DEFAULTIPSITELINK'" -ErrorAction SilentlyContinue
            if ($DefaultSiteLink -and $DefaultSiteLink.SitesIncluded.Count -gt 0) {
                Write-Host "Found default site link with sites. Consider removing after creating custom links." -ForegroundColor Yellow
            }
        }
        catch {
            # Default site link might not exist, which is fine
        }
        
        # Create optimized site links
        foreach ($LinkName in $SiteLinkDesign.Keys) {
            $LinkConfig = $SiteLinkDesign[$LinkName]
            
            if ($WhatIf) {
                Write-Host "WHATIF: Would create site link: $LinkName" -ForegroundColor Yellow
                Write-Host "  Sites: $($LinkConfig.Sites -join ', ')"
                Write-Host "  Cost: $($LinkConfig.Cost)"
                Write-Host "  Interval: $($LinkConfig.ReplicationInterval) minutes"
                continue
            }
            
            try {
                # Check if site link already exists
                $ExistingLink = Get-ADReplicationSiteLink -Filter "Name -eq '$LinkName'" -ErrorAction SilentlyContinue
                
                if (-not $ExistingLink) {
                    # Create new site link
                    $SiteLinkParams = @{
                        Name = $LinkName
                        SitesIncluded = $LinkConfig.Sites
                        Cost = $LinkConfig.Cost
                        ReplicationFrequencyInMinutes = $LinkConfig.ReplicationInterval
                        Description = $LinkConfig.Description
                    }
                    
                    New-ADReplicationSiteLink @SiteLinkParams
                    Write-Host "Created site link: $LinkName" -ForegroundColor Green
                    
                    # Configure additional properties
                    if ($LinkConfig.ContainsKey('ChangeNotification')) {
                        $OptionsValue = if ($LinkConfig.ChangeNotification) { 1 } else { 0 }
                        Set-ADReplicationSiteLink -Identity $LinkName -Replace @{ options = $OptionsValue }
                    }
                    
                    # Configure replication schedule if specified
                    if ($LinkConfig.ContainsKey('Schedule')) {
                        # Custom schedule implementation would go here
                        Write-Host "  Custom schedule configured for $LinkName" -ForegroundColor Green
                    }
                } else {
                    Write-Host "Site link already exists: $LinkName" -ForegroundColor Yellow
                    
                    # Update existing link if needed
                    Set-ADReplicationSiteLink -Identity $LinkName -Cost $LinkConfig.Cost -ReplicationFrequencyInMinutes $LinkConfig.ReplicationInterval
                    Write-Host "  Updated site link properties: $LinkName" -ForegroundColor Green
                }
            }
            catch {
                Write-Error "Failed to create site link $LinkName`: $($_.Exception.Message)"
            }
        }
        
        Write-Host "Site link optimization completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create optimized site links: $($_.Exception.Message)"
    }
}
```

### Phase 4: Monitoring and Maintenance

```powershell
# Comprehensive replication monitoring and maintenance
function Invoke-ReplicationMonitoring {
    param(
        [string[]]$MonitoredSites = @(),
        [string[]]$NotificationEmails = @(),
        [string]$SMTPServer = $null,
        [int]$MonitoringInterval = 300, # 5 minutes
        [string]$ReportPath = "C:\Reports\Replication_Health_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    try {
        Write-Host "Starting replication monitoring..." -ForegroundColor Green
        
        # Get all sites if none specified
        if ($MonitoredSites.Count -eq 0) {
            $MonitoredSites = (Get-ADReplicationSite -Filter *).Name
        }
        
        $MonitoringResults = @{
            HealthySites = @()
            ProblematicSites = @()
            ReplicationFailures = @()
            Performance = @()
            Recommendations = @()
        }
        
        # Monitor each site
        foreach ($SiteName in $MonitoredSites) {
            try {
                Write-Host "Monitoring site: $SiteName" -ForegroundColor Cyan
                
                # Get domain controllers in site
                $SiteDCs = Get-ADDomainController -Filter * | Where-Object { $_.Site -eq $SiteName }
                
                if ($SiteDCs.Count -eq 0) {
                    $MonitoringResults.ProblematicSites += @{
                        Site = $SiteName
                        Issue = "No domain controllers found"
                        Severity = "High"
                        Recommendation = "Deploy domain controller or remove unused site"
                    }
                    continue
                }
                
                $SiteHealth = @{
                    Site = $SiteName
                    DomainControllers = $SiteDCs.Count
                    ReplicationStatus = "Healthy"
                    LastReplication = $null
                    Issues = @()
                }
                
                # Check replication status for each DC
                foreach ($DC in $SiteDCs) {
                    try {
                        # Test replication connectivity
                        $ReplicationTest = repadmin /showrepl $DC.HostName /csv | ConvertFrom-Csv -ErrorAction SilentlyContinue
                        
                        if ($ReplicationTest) {
                            $RecentFailures = $ReplicationTest | Where-Object { 
                                $_.'Last Failure Time' -ne '0' -and 
                                [datetime]$_.'Last Failure Time' -gt (Get-Date).AddHours(-24)
                            }
                            
                            if ($RecentFailures) {
                                $SiteHealth.ReplicationStatus = "Warning"
                                $SiteHealth.Issues += "Recent replication failures on $($DC.Name)"
                                
                                foreach ($Failure in $RecentFailures) {
                                    $MonitoringResults.ReplicationFailures += @{
                                        SourceDC = $Failure.'Source DSA'
                                        TargetDC = $DC.Name
                                        Partition = $Failure.'Naming Context'
                                        LastFailure = $Failure.'Last Failure Time'
                                        FailureReason = $Failure.'Last Failure Status'
                                    }
                                }
                            }
                        }
                        
                        # Check service status
                        $ServiceStatus = Get-Service -ComputerName $DC.HostName -Name "NTDS" -ErrorAction SilentlyContinue
                        if ($ServiceStatus.Status -ne "Running") {
                            $SiteHealth.ReplicationStatus = "Critical"
                            $SiteHealth.Issues += "NTDS service not running on $($DC.Name)"
                        }
                        
                    }
                    catch {
                        $SiteHealth.Issues += "Unable to connect to $($DC.Name): $($_.Exception.Message)"
                        $SiteHealth.ReplicationStatus = "Warning"
                    }
                }
                
                # Categorize site health
                if ($SiteHealth.ReplicationStatus -eq "Healthy") {
                    $MonitoringResults.HealthySites += $SiteHealth
                } else {
                    $MonitoringResults.ProblematicSites += $SiteHealth
                }
                
            }
            catch {
                Write-Warning "Failed to monitor site $SiteName`: $($_.Exception.Message)"
            }
        }
        
        # Generate monitoring report
        $HTMLReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Replication Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; }
        .section { margin: 20px 0; }
        .healthy { background-color: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 10px 0; }
        .warning { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 10px 0; }
        .critical { background-color: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Replication Health Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Monitored Sites: $($MonitoredSites.Count)</p>
    </div>
    
    <div class="section">
        <h2>Health Summary</h2>
        <div class="healthy"><strong>Healthy Sites:</strong> $($MonitoringResults.HealthySites.Count)</div>
        <div class="warning"><strong>Sites with Issues:</strong> $($MonitoringResults.ProblematicSites.Count)</div>
        <div class="critical"><strong>Replication Failures:</strong> $($MonitoringResults.ReplicationFailures.Count)</div>
    </div>
    
    <div class="section">
        <h2>Site Status Details</h2>
        <table>
            <tr><th>Site</th><th>Domain Controllers</th><th>Status</th><th>Issues</th></tr>
"@
        
        # Add healthy sites
        foreach ($Site in $MonitoringResults.HealthySites) {
            $HTMLReport += "<tr><td>$($Site.Site)</td><td>$($Site.DomainControllers)</td><td><span style='color: green;'>$($Site.ReplicationStatus)</span></td><td>None</td></tr>"
        }
        
        # Add problematic sites
        foreach ($Site in $MonitoringResults.ProblematicSites) {
            $IssuesList = $Site.Issues -join '; '
            $StatusColor = if ($Site.ReplicationStatus -eq "Critical") { "red" } else { "orange" }
            $HTMLReport += "<tr><td>$($Site.Site)</td><td>$($Site.DomainControllers)</td><td><span style='color: $StatusColor;'>$($Site.ReplicationStatus)</span></td><td>$IssuesList</td></tr>"
        }
        
        $HTMLReport += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Review and resolve any critical replication failures immediately</li>
            <li>Monitor sites without domain controllers for cleanup opportunities</li>
            <li>Consider implementing automated replication monitoring</li>
            <li>Schedule regular replication health assessments</li>
        </ul>
    </div>
</body>
</html>
"@
        
        $HTMLReport | Out-File -FilePath $ReportPath -Encoding UTF8
        
        # Send email notification if configured
        if ($NotificationEmails -and $SMTPServer -and $MonitoringResults.ProblematicSites.Count -gt 0) {
            $EmailParams = @{
                To = $NotificationEmails
                From = "ad-monitoring@$((Get-ADDomain).DNSRoot)"
                Subject = "AD Replication Health Alert - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                Body = "Replication issues detected in $($MonitoringResults.ProblematicSites.Count) sites. Please review the attached report."
                Attachments = $ReportPath
                SMTPServer = $SMTPServer
            }
            Send-MailMessage @EmailParams
            Write-Host "Alert email sent to administrators" -ForegroundColor Yellow
        }
        
        Write-Host "Replication monitoring completed. Report: $ReportPath" -ForegroundColor Green
        return $MonitoringResults
    }
    catch {
        Write-Error "Failed to complete replication monitoring: $($_.Exception.Message)"
    }
}
```

## Advanced Configuration and Optimization

### Subnet Management Automation

```powershell
# Automated subnet discovery and management
function Invoke-SubnetDiscovery {
    param(
        [string[]]$NetworkRanges = @("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"),
        [int]$MinSubnetSize = 24,
        [switch]$AutoCreateSites,
        [string]$DefaultSiteForNewSubnets = "Default-First-Site-Name"
    )
    
    try {
        Write-Host "Starting automated subnet discovery..." -ForegroundColor Green
        
        $DiscoveryResults = @{
            DiscoveredSubnets = @()
            ExistingSubnets = @()
            OrphanedSubnets = @()
            Recommendations = @()
        }
        
        # Get existing subnets
        $ExistingSubnets = Get-ADReplicationSubnet -Filter * | ForEach-Object {
            @{
                Name = $_.Name
                Site = $_.Site
                Description = $_.Description
            }
        }
        $DiscoveryResults.ExistingSubnets = $ExistingSubnets
        
        # Network discovery simulation (in production, integrate with IPAM or network scanning tools)
        foreach ($NetworkRange in $NetworkRanges) {
            try {
                # Parse network range
                $Network = [System.Net.IPAddress]::Parse($NetworkRange.Split('/')[0])
                $PrefixLength = [int]$NetworkRange.Split('/')[1]
                
                # Simulate subnet discovery (replace with actual network discovery logic)
                for ($i = 0; $i -lt 5; $i++) {
                    $SubnetBase = $Network.Address + ($i * 256)
                    $SubnetCIDR = "$SubnetBase/$MinSubnetSize"
                    
                    # Check if subnet already exists
                    $ExistingSubnet = $ExistingSubnets | Where-Object { $_.Name -eq $SubnetCIDR }
                    
                    if (-not $ExistingSubnet) {
                        $DiscoveryResults.DiscoveredSubnets += @{
                            Subnet = $SubnetCIDR
                            NetworkRange = $NetworkRange
                            Recommended = $true
                            SuggestedSite = $DefaultSiteForNewSubnets
                        }
                        
                        if ($AutoCreateSites) {
                            try {
                                New-ADReplicationSubnet -Name $SubnetCIDR -Site $DefaultSiteForNewSubnets -Description "Auto-discovered subnet"
                                Write-Host "Created subnet: $SubnetCIDR" -ForegroundColor Green
                            }
                            catch {
                                Write-Warning "Failed to create subnet $SubnetCIDR`: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
            catch {
                Write-Warning "Failed to process network range $NetworkRange`: $($_.Exception.Message)"
            }
        }
        
        Write-Host "Subnet discovery completed. Found $($DiscoveryResults.DiscoveredSubnets.Count) new subnets" -ForegroundColor Green
        return $DiscoveryResults
    }
    catch {
        Write-Error "Failed to complete subnet discovery: $($_.Exception.Message)"
    }
}
```

### Replication Optimization

```powershell
# Advanced replication optimization and tuning
function Optimize-ADReplication {
    param(
        [string[]]$TargetSites = @(),
        [switch]$OptimizeSchedules,
        [switch]$OptimizeCosts,
        [switch]$EnableCompressionOptimization,
        [string]$ReportPath = "C:\Reports\Replication_Optimization_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    try {
        Write-Host "Starting replication optimization..." -ForegroundColor Green
        
        $OptimizationResults = @{
            SitesOptimized = @()
            RecommendedChanges = @()
            PerformanceImprovements = @()
        }
        
        # Get all sites if none specified
        if ($TargetSites.Count -eq 0) {
            $TargetSites = (Get-ADReplicationSite -Filter *).Name
        }
        
        # Get all site links
        $SiteLinks = Get-ADReplicationSiteLink -Filter *
        
        # Optimize site link costs based on network topology
        if ($OptimizeCosts) {
            foreach ($SiteLink in $SiteLinks) {
                $CurrentCost = $SiteLink.Cost
                $RecommendedCost = $CurrentCost
                
                # Optimization logic based on site link characteristics
                $SiteCount = $SiteLink.SitesIncluded.Count
                $ReplicationInterval = $SiteLink.ReplicationFrequencyInMinutes
                
                # Recommend cost adjustments
                if ($ReplicationInterval -le 15 -and $CurrentCost -gt 50) {
                    $RecommendedCost = 50  # High-speed link
                } elseif ($ReplicationInterval -ge 60 -and $CurrentCost -lt 200) {
                    $RecommendedCost = 200  # Low-speed link
                }
                
                if ($RecommendedCost -ne $CurrentCost) {
                    $OptimizationResults.RecommendedChanges += @{
                        SiteLink = $SiteLink.Name
                        Type = "Cost Optimization"
                        CurrentValue = $CurrentCost
                        RecommendedValue = $RecommendedCost
                        Reason = "Based on replication interval and network characteristics"
                    }
                    
                    # Apply optimization
                    Set-ADReplicationSiteLink -Identity $SiteLink.Name -Cost $RecommendedCost
                    Write-Host "Optimized cost for site link $($SiteLink.Name): $CurrentCost -> $RecommendedCost" -ForegroundColor Green
                }
            }
        }
        
        # Optimize replication schedules
        if ($OptimizeSchedules) {
            foreach ($SiteLink in $SiteLinks) {
                $CurrentInterval = $SiteLink.ReplicationFrequencyInMinutes
                $RecommendedInterval = $CurrentInterval
                
                # Optimize based on site link cost (indicating network speed)
                if ($SiteLink.Cost -le 100 -and $CurrentInterval -gt 15) {
                    $RecommendedInterval = 15  # High-speed links
                } elseif ($SiteLink.Cost -ge 200 -and $CurrentInterval -lt 60) {
                    $RecommendedInterval = 60  # Low-speed links
                }
                
                if ($RecommendedInterval -ne $CurrentInterval) {
                    $OptimizationResults.RecommendedChanges += @{
                        SiteLink = $SiteLink.Name
                        Type = "Schedule Optimization"
                        CurrentValue = "$CurrentInterval minutes"
                        RecommendedValue = "$RecommendedInterval minutes"
                        Reason = "Based on link cost and network capacity"
                    }
                    
                    # Apply optimization
                    Set-ADReplicationSiteLink -Identity $SiteLink.Name -ReplicationFrequencyInMinutes $RecommendedInterval
                    Write-Host "Optimized replication interval for $($SiteLink.Name): $CurrentInterval -> $RecommendedInterval minutes" -ForegroundColor Green
                }
            }
        }
        
        # Enable compression optimization for slower links
        if ($EnableCompressionOptimization) {
            foreach ($SiteLink in $SiteLinks) {
                if ($SiteLink.Cost -ge 150) {  # Slower links benefit from compression
                    try {
                        # Enable compression (this would require additional logic for full implementation)
                        $OptimizationResults.RecommendedChanges += @{
                            SiteLink = $SiteLink.Name
                            Type = "Compression Optimization"
                            CurrentValue = "Disabled"
                            RecommendedValue = "Enabled"
                            Reason = "High-cost link benefits from compression"
                        }
                        Write-Host "Recommended compression for high-cost link: $($SiteLink.Name)" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Warning "Failed to optimize compression for $($SiteLink.Name): $($_.Exception.Message)"
                    }
                }
            }
        }
        
        # Generate optimization report
        $HTMLReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>AD Replication Optimization Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; }
        .section { margin: 20px 0; }
        .optimization { background-color: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Replication Optimization Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Optimizations Applied: $($OptimizationResults.RecommendedChanges.Count)</p>
    </div>
    
    <div class="section">
        <h2>Optimization Summary</h2>
        <div class="optimization">
            <strong>Total Recommendations:</strong> $($OptimizationResults.RecommendedChanges.Count)
        </div>
    </div>
    
    <div class="section">
        <h2>Applied Optimizations</h2>
        <table>
            <tr><th>Site Link</th><th>Optimization Type</th><th>Previous Value</th><th>New Value</th><th>Reason</th></tr>
"@
        
        foreach ($Change in $OptimizationResults.RecommendedChanges) {
            $HTMLReport += "<tr><td>$($Change.SiteLink)</td><td>$($Change.Type)</td><td>$($Change.CurrentValue)</td><td>$($Change.RecommendedValue)</td><td>$($Change.Reason)</td></tr>"
        }
        
        $HTMLReport += @"
        </table>
    </div>
</body>
</html>
"@
        
        $HTMLReport | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-Host "Replication optimization completed. Report: $ReportPath" -ForegroundColor Green
        
        return $OptimizationResults
    }
    catch {
        Write-Error "Failed to optimize replication: $($_.Exception.Message)"
    }
}
```

## Best Practices and Guidelines

### 1. Site Design Principles

#### Network-Based Design

- **Align with physical topology**: Sites should reflect actual network infrastructure
- **Consider bandwidth constraints**: Design replication schedules around available bandwidth
- **Plan for redundancy**: Ensure alternative replication paths for critical sites
- **Account for latency**: High-latency links may require separate sites

#### Administrative Efficiency

- **Minimize complexity**: Avoid unnecessary sites that complicate management
- **Logical grouping**: Group related locations in appropriate site structures
- **Consistent naming**: Use standardized naming conventions for sites and links
- **Documentation**: Maintain comprehensive site topology documentation

### 2. Subnet Management

#### Planning and Allocation

- **Complete coverage**: Ensure all IP ranges are properly assigned to sites
- **Avoid overlaps**: Prevent subnet conflicts and overlapping ranges
- **Future growth**: Reserve ranges for expansion and new locations
- **Integration with IPAM**: Coordinate with IP address management systems

#### Automation and Maintenance

- **Automated discovery**: Implement network scanning for new subnets
- **Regular audits**: Schedule periodic subnet validation and cleanup
- **Change detection**: Monitor for network changes requiring site updates
- **Documentation sync**: Keep subnet assignments synchronized with network documentation

### 3. Replication Optimization

#### Performance Tuning

- **Bandwidth utilization**: Optimize replication schedules for available bandwidth
- **Cost optimization**: Set appropriate costs to control replication paths
- **Compression settings**: Enable compression for slower links
- **Schedule optimization**: Align replication windows with business hours

#### Monitoring and Maintenance

- **Health monitoring**: Implement continuous replication health checks
- **Performance metrics**: Track replication latency and completion times
- **Alerting systems**: Configure alerts for replication failures and delays
- **Regular optimization**: Periodically review and adjust replication settings

### 4. Cloud Integration

#### Hybrid Scenarios

- **Azure AD Connect**: Coordinate site design with Azure AD Connect filtering
- **ExpressRoute integration**: Optimize for dedicated cloud connections
- **Multi-region support**: Plan for multiple cloud regions and availability zones
- **Disaster recovery**: Include cloud sites in DR planning and testing

## Troubleshooting Common Issues

### Issue 1: Slow or Failed Replication

**Symptoms**:

- Replication delays exceeding normal windows
- Event log errors (Event IDs: 1645, 1644, 1311)
- Inconsistent directory data across sites

**Diagnosis**:

```powershell
# Comprehensive replication health check
function Test-ReplicationHealth {
    param([string[]]$DomainControllers)
    
    foreach ($DC in $DomainControllers) {
        Write-Host "Testing replication for $DC" -ForegroundColor Cyan
        
        # Test basic connectivity
        Test-Connection -ComputerName $DC -Count 2 -Quiet
        
        # Check replication status
        repadmin /showrepl $DC /csv | ConvertFrom-Csv | 
            Where-Object { $_.'Last Failure Status' -ne '0' } |
            Format-Table -AutoSize
        
        # Check for replication errors
        Get-WinEvent -ComputerName $DC -FilterHashtable @{LogName='Directory Service'; Level=2,3} -MaxEvents 10 -ErrorAction SilentlyContinue
    }
}
```

**Solutions**:

- Verify network connectivity and DNS resolution
- Check domain controller services (NTDS, DNS, KDC)
- Review and adjust replication schedules
- Force replication using `repadmin /syncall`

### Issue 2: Site Assignment Problems

**Symptoms**:

- Clients authenticating to wrong domain controllers
- Slow logon performance
- Incorrect Group Policy application

**Diagnosis**:

```powershell
# Check client site assignment
function Test-ClientSiteAssignment {
    param([string[]]$ClientIPs)
    
    foreach ($IP in $ClientIPs) {
        $Site = nltest /dsgetsite /server:$IP 2>$null
        Write-Host "IP $IP is assigned to site: $Site"
        
        # Verify subnet exists for this IP
        $Subnets = Get-ADReplicationSubnet -Filter *
        $MatchingSubnet = $Subnets | Where-Object { 
            # Subnet matching logic would go here
            $_.Name -like "*$($IP.Split('.')[0])*"
        }
        
        if (-not $MatchingSubnet) {
            Write-Warning "No subnet found for IP $IP"
        }
    }
}
```

**Solutions**:

- Create missing subnets for client IP ranges
- Verify subnet-to-site assignments
- Check for overlapping or conflicting subnets
- Force client site refresh using `gpupdate /force`

### Issue 3: KCC Topology Issues

**Symptoms**:

- Inefficient replication topology
- Missing replication connections
- Excessive replication traffic

**Diagnosis**:

```powershell
# Analyze KCC-generated topology
function Test-KCCTopology {
    $AllDCs = Get-ADDomainController -Filter *
    
    foreach ($DC in $AllDCs) {
        Write-Host "Analyzing KCC topology for $($DC.Name)" -ForegroundColor Cyan
        
        # Check inbound replication connections
        repadmin /showreps $DC.HostName | Out-String | Write-Host
        
        # Check connection objects
        Get-ADObject -SearchBase "CN=Configuration,$((Get-ADDomain).DistinguishedName)" -Filter "objectClass -eq 'nTDSConnection'" -Properties fromServer, enabledConnection | 
            Where-Object { $_.DistinguishedName -like "*$($DC.Name)*" } |
            Format-Table Name, fromServer, enabledConnection -AutoSize
    }
}
```

**Solutions**:

- Force KCC recalculation: `repadmin /kcc`
- Remove manual connections that conflict with KCC
- Verify site link configuration
- Check for isolated domain controllers

## Advanced Integration Scenarios

### Cloud and Hybrid Environments

#### Azure AD Integration

```powershell
# Configure sites for Azure AD Connect optimization
function Set-AzureADConnectSiteOptimization {
    param(
        [string]$AADConnectServer,
        [string[]]$PreferredSites = @("Headquarters", "DataCenter-Primary")
    )
    
    try {
        Write-Host "Optimizing sites for Azure AD Connect..." -ForegroundColor Green
        
        # Create dedicated subnets for Azure AD Connect traffic if needed
        foreach ($Site in $PreferredSites) {
            $SiteObj = Get-ADReplicationSite -Identity $Site -ErrorAction SilentlyContinue
            if ($SiteObj) {
                Write-Host "Verified AAD Connect preferred site: $Site" -ForegroundColor Green
                
                # Set site preferences in registry (example implementation)
                # This would be configured on the AAD Connect server
                Write-Host "Configure AAD Connect to prefer site: $Site" -ForegroundColor Yellow
            }
        }
        
        # Optimize replication for AAD Connect server site
        $AADConnectSite = (Get-ADDomainController -Filter "Name -like '*$AADConnectServer*'").Site
        if ($AADConnectSite) {
            $SiteLinks = Get-ADReplicationSiteLink -Filter "SitesIncluded -eq '$AADConnectSite'"
            foreach ($Link in $SiteLinks) {
                if ($Link.ReplicationFrequencyInMinutes -gt 15) {
                    Set-ADReplicationSiteLink -Identity $Link.Name -ReplicationFrequencyInMinutes 15
                    Write-Host "Optimized replication for AAD Connect site link: $($Link.Name)" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        Write-Error "Failed to optimize sites for Azure AD Connect: $($_.Exception.Message)"
    }
}
```

#### Multi-Forest Integration

```powershell
# Configure cross-forest site topology
function Set-CrossForestSiteTopology {
    param(
        [string]$TrustedForest,
        [hashtable]$CrossForestSiteLinks
    )
    
    try {
        Write-Host "Configuring cross-forest site topology..." -ForegroundColor Green
        
        # Verify forest trust
        $TrustRelationship = Get-ADTrust -Filter "Name -eq '$TrustedForest'" -ErrorAction SilentlyContinue
        if (-not $TrustRelationship) {
            throw "No trust relationship found with forest: $TrustedForest"
        }
        
        # Configure cross-forest site links
        foreach ($LinkName in $CrossForestSiteLinks.Keys) {
            $LinkConfig = $CrossForestSiteLinks[$LinkName]
            
            # Create cross-forest site link
            # This would involve more complex configuration in production
            Write-Host "Configuring cross-forest site link: $LinkName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Failed to configure cross-forest topology: $($_.Exception.Message)"
    }
}
```

## Compliance and Auditing

### Regulatory Requirements

#### Network Security Compliance

- **Segmentation documentation**: Maintain detailed network segmentation records
- **Access control**: Document site-based access restrictions
- **Audit trails**: Log all site and subnet configuration changes
- **Change management**: Implement approval processes for topology changes

#### Performance Monitoring

```powershell
# Generate compliance report for site and subnet management
function New-SiteComplianceReport {
    param(
        [string[]]$ComplianceFrameworks = @('SOX', 'NIST', 'ISO27001'),
        [string]$ReportPath = "C:\Reports\Site_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    )
    
    try {
        # Collect compliance data
        $ComplianceData = @{
            TotalSites = (Get-ADReplicationSite -Filter *).Count
            TotalSubnets = (Get-ADReplicationSubnet -Filter *).Count
            TotalSiteLinks = (Get-ADReplicationSiteLink -Filter *).Count
            DocumentedTopology = $true
            MonitoringEnabled = $true
            ChangeManagement = $true
        }
        
        # Generate detailed compliance report
        $HTMLReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Sites and Subnets Compliance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; }
        .compliant { color: #28a745; font-weight: bold; }
        .non-compliant { color: #dc3545; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Sites and Subnets Compliance Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Frameworks: $($ComplianceFrameworks -join ', ')</p>
    </div>
    
    <div class="section">
        <h2>Compliance Summary</h2>
        <table>
            <tr><th>Control</th><th>Status</th><th>Details</th></tr>
            <tr><td>Network Topology</td><td class="compliant">Compliant</td><td>$($ComplianceData.TotalSites) sites configured</td></tr>
            <tr><td>Subnet Management</td><td class="compliant">Compliant</td><td>$($ComplianceData.TotalSubnets) subnets documented</td></tr>
            <tr><td>Replication Control</td><td class="compliant">Compliant</td><td>$($ComplianceData.TotalSiteLinks) site links configured</td></tr>
            <tr><td>Monitoring</td><td class="compliant">Compliant</td><td>Automated monitoring enabled</td></tr>
        </table>
    </div>
</body>
</html>
"@
        
        $HTMLReport | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-Host "Compliance report generated: $ReportPath" -ForegroundColor Green
        
        return $ComplianceData
    }
    catch {
        Write-Error "Failed to generate compliance report: $($_.Exception.Message)"
    }
}
```

## Conclusion

Modern Active Directory Sites and Subnets design requires a comprehensive approach that balances network efficiency, security, and operational management. This guide provides the framework, tools, and best practices necessary to implement enterprise-grade site topologies that optimize replication, improve authentication performance, and support business continuity.

Key success factors include:

- **Network-aligned design** that reflects actual physical topology
- **Automated management** and monitoring capabilities
- **Performance optimization** through intelligent replication scheduling
- **Cloud integration** supporting hybrid and multi-cloud scenarios
- **Comprehensive monitoring** with proactive alerting and remediation

Regular review and optimization of site and subnet configurations ensures continued performance and alignment with evolving network infrastructure and business requirements. Proper implementation of these practices results in a robust, scalable, and efficient Active Directory infrastructure that supports organizational growth and operational excellence.
