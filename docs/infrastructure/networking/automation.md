---
title: "Network Automation"
description: "PowerShell and scripting tools for network management and automation"
tags: ["networking", "automation", "powershell", "scripting"]
category: "networking"
difficulty: "advanced"
last_updated: "2025-12-29"
author: "Joseph Streeter"
---

Automate repetitive networking tasks using PowerShell, Python, and other scripting tools. This section provides frameworks and examples for managing network infrastructure programmatically.

## PowerShell Network Management

### VLAN Management Framework

Enterprise VLAN management and automation framework for comprehensive VLAN planning, implementation, and monitoring.

#### Overview

The NetworkVLAN PowerShell class provides:

- Automated VLAN configuration generation
- Built-in validation against enterprise standards
- Self-documenting network infrastructure
- Integration with configuration management tools

#### Prerequisites

- PowerShell 5.1 or later
- Network administrator credentials
- Access to network device management interfaces

#### Quick Start

```powershell
# Create a new VLAN
$FinanceVlan = [NetworkVLAN]::new(
    100,                    # VLAN ID
    "Finance",              # Name
    "10.0.100.0/24"        # Subnet
)

# Set security zone
$FinanceVlan.SecurityZone = "Restricted"

# Generate switch configuration
$Config = $FinanceVlan.GenerateSwitchConfig("Cisco")
Write-Host $Config
```

### Complete Implementation

```powershell
<#
.SYNOPSIS
    Enterprise VLAN management and automation framework.
.DESCRIPTION
    Provides comprehensive VLAN planning, implementation, and monitoring
    for enterprise network environments.
#>

class NetworkVLAN
{
 [ValidateRange(1, 4094)]
 [int]$VLANId
 
 [ValidateNotNullOrEmpty()]
 [string]$Name
 
 [string]$Description
 [string]$IPSubnet
 [string]$Gateway
 [string[]]$DHCPScope
 [string]$SecurityZone
 [hashtable]$AccessPolicies
 [bool]$InterVLANRouting
 [string[]]$AllowedVLANs
 [hashtable]$QoSPolicies
 
 NetworkVLAN([int]$Id, [string]$Name, [string]$Subnet)
 {
  $this.VLANId = $Id
  $this.Name = $Name
  $this.IPSubnet = $Subnet
  $this.Description = ""
  $this.SecurityZone = "Standard"
  $this.AccessPolicies = @{}
  $this.InterVLANRouting = $true
  $this.AllowedVLANs = @()
  $this.QoSPolicies = @{}
  
  # Calculate gateway (first usable IP in subnet)
  $Network = [System.Net.IPAddress]::Parse($Subnet.Split('/')[0])
  $this.Gateway = $Network.ToString()
 }
 
 [string] GenerateSwitchConfig([string]$SwitchType)
 {
  switch ($SwitchType)
  {
   "Cisco"
   {
    return $this.GenerateCiscoConfig()
   }
   "HPE"
   {
    return $this.GenerateHPEConfig()
   }
   "Juniper"
   {
    return $this.GenerateJuniperConfig()
   }
   default
   {
    return $this.GenerateGenericConfig()
   }
  }
 }
 
 [string] GenerateCiscoConfig()
 {
  $Config = @"
! VLAN $($this.VLANId) Configuration
vlan $($this.VLANId)
 name $($this.Name)
 state active
exit

! SVI Configuration
interface vlan$($this.VLANId)
 description $($this.Description)
 ip address $($this.Gateway) $(($this.IPSubnet -split '/')[1])
 no shutdown
exit

"@
  
  if ($this.QoSPolicies.Count -gt 0)
  {
   $Config += @"
! QoS Configuration
interface vlan$($this.VLANId)
 service-policy input $($this.QoSPolicies.InputPolicy)
 service-policy output $($this.QoSPolicies.OutputPolicy)
exit

"@
  }
  
  return $Config
 }
 
 [string] GenerateHPEConfig()
 {
  return @"
# VLAN $($this.VLANId) Configuration
vlan $($this.VLANId)
   name "$($this.Name)"
   untagged 1-24
   ip address $($this.Gateway) $($this.IPSubnet)
   exit

"@
 }
 
 [string] GenerateGenericConfig()
 {
  return @"
VLAN Configuration:
  VLAN ID: $($this.VLANId)
  Name: $($this.Name)
  Description: $($this.Description)
  IP Subnet: $($this.IPSubnet)
  Gateway: $($this.Gateway)
  Security Zone: $($this.SecurityZone)
  Inter-VLAN Routing: $($this.InterVLANRouting)

"@
 }
}

class NetworkManager
{
 [hashtable]$VLANs
 [hashtable]$Subnets
 [hashtable]$Devices
 [string]$ConfigPath
 [string]$BackupPath
 
 NetworkManager([string]$ConfigurationPath)
 {
  $this.VLANs = @{}
  $this.Subnets = @{}
  $this.Devices = @{}
  $this.ConfigPath = $ConfigurationPath
  $this.BackupPath = Join-Path (Split-Path $ConfigurationPath) "Backups"
  
  # Ensure directories exist
  foreach ($Path in @($this.ConfigPath, $this.BackupPath))
  {
   $Dir = if (Test-Path $Path -PathType Leaf) { Split-Path $Path } else { $Path }
   if (!(Test-Path $Dir))
   {
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
   }
  }
  
  $this.LoadConfiguration()
 }
 
 [NetworkVLAN] CreateVLAN([int]$VLANId, [string]$Name, [string]$Subnet)
 {
  if ($this.VLANs.ContainsKey($VLANId))
  {
   throw "VLAN $VLANId already exists"
  }
  
  $VLAN = [NetworkVLAN]::new($VLANId, $Name, $Subnet)
  $this.VLANs[$VLANId] = $VLAN
  
  $this.LogActivity("VLANCreated", "Created VLAN $VLANId : $Name ($Subnet)")
  $this.SaveConfiguration()
  
  return $VLAN
 }
 
 [void] RemoveVLAN([int]$VLANId)
 {
  if (!$this.VLANs.ContainsKey($VLANId))
  {
   throw "VLAN $VLANId not found"
  }
  
  $VLANName = $this.VLANs[$VLANId].Name
  $this.VLANs.Remove($VLANId)
  
  $this.LogActivity("VLANRemoved", "Removed VLAN $VLANId : $VLANName")
  $this.SaveConfiguration()
 }
 
 [hashtable] PerformNetworkAnalysis()
 {
  $Analysis = @{
   TotalVLANs          = $this.VLANs.Count
   VLANUtilization     = @{}
   SecurityIssues      = @()
   Recommendations     = @()
   SubnetOverlaps      = @()
  }
  
  # Check for subnet overlaps
  $Subnets = $this.VLANs.Values | ForEach-Object { $_.IPSubnet }
  for ($i = 0; $i -lt $Subnets.Count; $i++)
  {
   for ($j = $i + 1; $j -lt $Subnets.Count; $j++)
   {
    if ($this.CheckSubnetOverlap($Subnets[$i], $Subnets[$j]))
    {
     $Analysis.SubnetOverlaps += @{
      Subnet1  = $Subnets[$i]
      Subnet2  = $Subnets[$j]
      Severity = "High"
     }
    }
   }
  }
  
  # Security analysis
  foreach ($VLAN in $this.VLANs.Values)
  {
   if ($VLAN.SecurityZone -eq "Standard" -and $VLAN.VLANId -lt 100)
   {
    $Analysis.SecurityIssues += @{
     VLAN           = $VLAN.VLANId
     Issue          = "Management VLAN should be in secure zone"
     Severity       = "Medium"
     Recommendation = "Change security zone to 'Management'"
    }
   }
   
   if ($VLAN.InterVLANRouting -eq $true -and $VLAN.SecurityZone -eq "Guest")
   {
    $Analysis.SecurityIssues += @{
     VLAN           = $VLAN.VLANId
     Issue          = "Guest VLAN allows inter-VLAN routing"
     Severity       = "High"
     Recommendation = "Disable inter-VLAN routing for guest networks"
    }
   }
  }
  
  # Generate recommendations
  if ($Analysis.SubnetOverlaps.Count -gt 0)
  {
   $Analysis.Recommendations += "Resolve subnet overlaps to prevent routing issues"
  }
  
  if ($Analysis.SecurityIssues.Count -gt 0)
  {
   $Analysis.Recommendations += "Address security configuration issues"
  }
  
  if ($Analysis.TotalVLANs -gt 50)
  {
   $Analysis.Recommendations += "Consider VLAN consolidation for better management"
  }
  
  return $Analysis
 }
 
 [bool] CheckSubnetOverlap([string]$Subnet1, [string]$Subnet2)
 {
  # Simplified overlap check - would need more sophisticated implementation
  $Network1 = $Subnet1.Split('/')[0]
  $Network2 = $Subnet2.Split('/')[0]
  
  # Basic check for same network
  return $Network1 -eq $Network2
 }
 
 [void] SaveConfiguration()
 {
  $ConfigData = @{
   VLANs        = @{}
   Devices      = $this.Devices
   LastModified = Get-Date
   Version      = "1.0"
  }
  
  # Convert VLANs to serializable format
  foreach ($VLANId in $this.VLANs.Keys)
  {
   $VLAN = $this.VLANs[$VLANId]
   $ConfigData.VLANs[$VLANId] = @{
    VLANId           = $VLAN.VLANId
    Name             = $VLAN.Name
    Description      = $VLAN.Description
    IPSubnet         = $VLAN.IPSubnet
    Gateway          = $VLAN.Gateway
    DHCPScope        = $VLAN.DHCPScope
    SecurityZone     = $VLAN.SecurityZone
    AccessPolicies   = $VLAN.AccessPolicies
    InterVLANRouting = $VLAN.InterVLANRouting
    AllowedVLANs     = $VLAN.AllowedVLANs
    QoSPolicies      = $VLAN.QoSPolicies
   }
  }
  
  $ConfigData | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.ConfigPath -Encoding UTF8
 }
 
 [void] LoadConfiguration()
 {
  if (Test-Path $this.ConfigPath)
  {
   try
   {
    $ConfigData = Get-Content $this.ConfigPath | ConvertFrom-Json
    
    # Load VLANs
    foreach ($VLANId in $ConfigData.VLANs.PSObject.Properties.Name)
    {
     $VLANData = $ConfigData.VLANs.$VLANId
     $VLAN = [NetworkVLAN]::new($VLANData.VLANId, $VLANData.Name, $VLANData.IPSubnet)
     
     # Restore all properties
     $VLAN.Description = $VLANData.Description
     $VLAN.Gateway = $VLANData.Gateway
     $VLAN.DHCPScope = $VLANData.DHCPScope
     $VLAN.SecurityZone = $VLANData.SecurityZone
     $VLAN.AccessPolicies = $VLANData.AccessPolicies
     $VLAN.InterVLANRouting = $VLANData.InterVLANRouting
     $VLAN.AllowedVLANs = $VLANData.AllowedVLANs
     $VLAN.QoSPolicies = $VLANData.QoSPolicies
     
     $this.VLANs[$VLANId] = $VLAN
    }
    
    # Load devices
    if ($ConfigData.Devices)
    {
     $this.Devices = $ConfigData.Devices
    }
   }
   catch
   {
    Write-Warning "Failed to load network configuration: $($_.Exception.Message)"
   }
  }
 }
 
 [void] LogActivity([string]$Action, [string]$Message)
 {
  $LogEntry = [PSCustomObject]@{
   Timestamp = Get-Date
   Action    = $Action
   Message   = $Message
   User      = $env:USERNAME
   Computer  = $env:COMPUTERNAME
  }
  
  $LogFile = Join-Path (Split-Path $this.ConfigPath) "Network-$(Get-Date -Format 'yyyyMM').log"
  $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogFile -Append -Encoding UTF8
 }
}

# Global functions for network management

function Initialize-NetworkManagement
{
 [CmdletBinding()]
 param(
  [Parameter()]
  [string]$ConfigPath = "C:\NetworkInfrastructure\Configuration.json"
 )
 
 $Global:NetworkManager = [NetworkManager]::new($ConfigPath)
 
 Write-Host "Network Management initialized" -ForegroundColor Green
 Write-Host "Configuration path: $ConfigPath" -ForegroundColor White
}

function New-NetworkVLAN
{
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)]
  [int]$VLANId,
  
  [Parameter(Mandatory)]
  [string]$Name,
  
  [Parameter(Mandatory)]
  [string]$Subnet,
  
  [Parameter()]
  [string]$Description = "",
  
  [Parameter()]
  [string]$SecurityZone = "Standard"
 )
 
 if (!$Global:NetworkManager)
 {
  Initialize-NetworkManagement
 }
 
 try
 {
  $VLAN = $Global:NetworkManager.CreateVLAN($VLANId, $Name, $Subnet)
  $VLAN.Description = $Description
  $VLAN.SecurityZone = $SecurityZone
  
  Write-Host "VLAN $VLANId '$Name' created successfully" -ForegroundColor Green
  return $VLAN
 }
 catch
 {
  Write-Error "Failed to create VLAN: $($_.Exception.Message)"
 }
}
```

### Usage Examples

#### Example 1: Create Multiple VLANs

```powershell
# Initialize network management
Initialize-NetworkManagement -ConfigPath "C:\Network\config.json"

# Create Management VLAN
$MgmtVlan = New-NetworkVLAN -VLANId 10 -Name "Management" `
 -Subnet "192.168.10.0/24" `
 -Description "Network management devices" `
 -SecurityZone "Management"

# Create Server VLAN
$ServerVlan = New-NetworkVLAN -VLANId 20 -Name "Servers" `
 -Subnet "10.0.20.0/24" `
 -Description "Application servers" `
 -SecurityZone "Restricted"

# Create User VLAN
$UserVlan = New-NetworkVLAN -VLANId 30 -Name "Users" `
 -Subnet "10.0.30.0/22" `
 -Description "User workstations" `
 -SecurityZone "Standard"
```

#### Example 2: Generate Configuration for Different Platforms

```powershell
# Generate Cisco configuration
$CiscoConfig = $MgmtVlan.GenerateSwitchConfig("Cisco")
$CiscoConfig | Out-File -FilePath "C:\Network\cisco-vlan-config.txt"

# Generate HPE configuration
$HPEConfig = $MgmtVlan.GenerateSwitchConfig("HPE")
$HPEConfig | Out-File -FilePath "C:\Network\hpe-vlan-config.txt"
```

#### Example 3: Perform Network Analysis

```powershell
# Run security analysis
$Analysis = $Global:NetworkManager.PerformNetworkAnalysis()

# Display results
Write-Host "Total VLANs: $($Analysis.TotalVLANs)"
Write-Host "Security Issues: $($Analysis.SecurityIssues.Count)"
Write-Host "Subnet Overlaps: $($Analysis.SubnetOverlaps.Count)"

# Show recommendations
foreach ($Recommendation in $Analysis.Recommendations)
{
 Write-Warning $Recommendation
}
```

## Python Network Automation

Coming soon: Python-based network automation using Netmiko, NAPALM, and Nornir.

## Ansible Playbooks

Coming soon: Ansible playbooks for network device configuration and management.

## Related Topics

- [VLAN Strategy](vlans.md) - VLAN design and implementation
- [Network Security](security/index.md) - Security automation
- [Monitoring](troubleshooting.md) - Automated monitoring setup
