---
title: "Windows Event Log Examples"
description: "Comprehensive PowerShell examples for querying, filtering, and analyzing Windows Event Logs with best practices for event log management, security monitoring, and system troubleshooting"
tags: ["powershell", "windows", "event-logs", "security", "monitoring"]
category: "development"
difficulty: "intermediate"
last_updated: "2025-11-17"
---

## Windows Event Log Examples

This document provides comprehensive PowerShell examples for querying, filtering, and analyzing Windows Event Logs. These examples demonstrate best practices for event log management, security monitoring, and system troubleshooting.

## Overview

Windows Event Logs are critical for system monitoring, security auditing, and troubleshooting. PowerShell provides powerful cmdlets for working with event logs:

- **Get-WinEvent**: Modern cmdlet for querying event logs with advanced filtering capabilities
- **Get-EventLog**: Legacy cmdlet (deprecated, use Get-WinEvent instead)
- **FilterHashtable**: Efficient server-side filtering to reduce network overhead and improve performance

## Prerequisites

```powershell
# Verify you have appropriate permissions (Administrator rights typically required)
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin)
{
    Write-Warning "Administrator privileges required for full event log access"
}
```

## Common Event Log Queries

### List Available Event Logs

```powershell
<#
.SYNOPSIS
    Lists all available event logs on the system.
.DESCRIPTION
    Retrieves and displays all event logs with their record counts and last write times.
.EXAMPLE
    Get-WinEvent -ListLog * | Where-Object RecordCount -gt 0 | Sort-Object RecordCount -Descending
#>
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | 
    Select-Object LogName, RecordCount, LastWriteTime, IsEnabled |
    Sort-Object RecordCount -Descending |
    Format-Table -AutoSize
```

### Query Security Event Log

```powershell
<#
.SYNOPSIS
    Retrieves failed logon attempts from the Security log.
.DESCRIPTION
    Queries Event ID 4625 (failed logon attempts) from the Security log.
    Requires Administrator privileges.
.EXAMPLE
    Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 50
#>
$FailedLogons = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
} -MaxEvents 50 -ErrorAction SilentlyContinue

$FailedLogons | Select-Object TimeCreated, Message | Format-Table -AutoSize
```

### Query System Errors and Warnings

```powershell
<#
.SYNOPSIS
    Retrieves recent system errors and warnings.
.DESCRIPTION
    Queries the System log for Error and Warning level events from the last 24 hours.
.EXAMPLE
    Get-WinEvent -FilterHashtable @{LogName='System'; Level=2,3; StartTime=(Get-Date).AddDays(-1)}
#>
$StartTime = (Get-Date).AddDays(-1)

$SystemIssues = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 2, 3  # 2 = Error, 3 = Warning
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

$SystemIssues | Select-Object TimeCreated, LevelDisplayName, ProviderName, Message |
    Format-Table -AutoSize
```

## Windows Defender Event Analysis

### Querying Defender Threat Detections

```powershell
<#
.SYNOPSIS
    Retrieves Windows Defender threat detection events.
.DESCRIPTION
    Queries Windows Defender Operational log for malware detection and remediation events.
    Event IDs:
    - 1116: Malware detected
    - 1117: Malware remediation action taken
.EXAMPLE
    Get-DefenderThreats -MaxEvents 20
.NOTES
    Requires Windows Defender to be installed and operational.
#>
function Get-DefenderThreats
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 20,
        
        [Parameter()]
        [datetime]$StartTime
    )
    
    try
    {
        $FilterHash = @{
            LogName = 'Microsoft-Windows-Windows Defender/Operational'
            ID = 1116, 1117
        }
        
        if ($StartTime)
        {
            $FilterHash['StartTime'] = $StartTime
        }
        
        $Events = Get-WinEvent -FilterHashtable $FilterHash -MaxEvents $MaxEvents -ErrorAction Stop
        
        $Events | ForEach-Object {
            $Xml = [xml]$_.ToXml()
            $EventData = $Xml.Event.EventData.Data
            
            # Extract domain and user, handling null values
            $Domain = ($EventData | Where-Object { $_.Name -eq 'Domain' }).'#text'
            $User = ($EventData | Where-Object { $_.Name -eq 'User' }).'#text'
            $UserString = if ($Domain -and $User) { "$Domain\$User" } else { "N/A" }
            
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                EventID = $_.Id
                ThreatName = ($EventData | Where-Object { $_.Name -eq 'Threat Name' }).'#text'
                Severity = ($EventData | Where-Object { $_.Name -eq 'Severity Name' }).'#text'
                Category = ($EventData | Where-Object { $_.Name -eq 'Category Name' }).'#text'
                Path = ($EventData | Where-Object { $_.Name -eq 'Path' }).'#text'
                User = $UserString
                ProcessName = ($EventData | Where-Object { $_.Name -eq 'Process Name' }).'#text'
                Action = ($EventData | Where-Object { $_.Name -eq 'Action Name' }).'#text'
            }
        }
    }
    catch [System.Exception]
    {
        Write-Error "Failed to retrieve Windows Defender events: $($_.Exception.Message)"
    }
}

# Usage example
Get-DefenderThreats -MaxEvents 20 | Format-Table -AutoSize
```

### Monitoring Defender Real-Time Protection Status

```powershell
<#
.SYNOPSIS
    Checks Windows Defender real-time protection status changes.
.DESCRIPTION
    Queries for Event ID 5001 (real-time protection disabled) to monitor security posture.
.EXAMPLE
    Get-DefenderProtectionStatus -Days 7
#>
function Get-DefenderProtectionStatus
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$Days = 7
    )
    
    $StartTime = (Get-Date).AddDays(-$Days)
    
    try
    {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Windows Defender/Operational'
            ID = 5001  # Real-time protection disabled
            StartTime = $StartTime
        } -ErrorAction Stop
        
        if ($Events)
        {
            Write-Warning "Real-time protection was disabled $($Events.Count) time(s) in the last $Days days"
            $Events | Select-Object TimeCreated, Message | Format-List
        }
        else
        {
            Write-Output "No real-time protection changes detected in the last $Days days"
        }
    }
    catch [System.Diagnostics.Eventing.Reader.EventLogNotFoundException]
    {
        Write-Error "Windows Defender event log not found. Ensure Windows Defender is installed."
    }
    catch
    {
        Write-Error "Failed to query Defender status: $($_.Exception.Message)"
    }
}
```

### Query Active Directory Domain Service for Insecure LDAP Binds

Windows Event ID 2889 occurs when a client attempts an insecure LDAP simple bind to a domain controller. This event logs the IP address of the client and the account it attempted to use, making it valuable for identifying devices or applications making unsecured LDAP requests. This event is triggered when the LDAP server is configured to require signed or encrypted binds, but a client does not support them or fails to use them.

#### Understanding LDAP Bind Security

**Event Context:**

- **Event ID**: 2889
- **Log Name**: Directory Service
- **Level**: Warning
- **Purpose**: Identifies insecure LDAP authentication attempts

**Common Causes:**

- Legacy applications using LDAP without encryption
- Devices or services not configured for LDAP signing
- Applications using simple binds over clear text
- Preparation for LDAP channel binding enforcement

#### Querying Insecure LDAP Bind Attempts

```powershell
<#
.SYNOPSIS
    Retrieves insecure LDAP bind attempts across all domain controllers.
.DESCRIPTION
    Queries Event ID 2889 from the Directory Service log on all domain controllers
    to identify clients attempting insecure LDAP simple binds. Useful for auditing
    before enforcing LDAP channel binding or LDAP signing requirements.
.PARAMETER Days
    Number of days to look back for events (default: 7).
.EXAMPLE
    Get-InsecureLDAPBinds -Days 30
.NOTES
    Requires:
    - Active Directory PowerShell module
    - Administrator privileges on domain controllers
    - Event logging enabled for Directory Service events
#>
function Get-InsecureLDAPBinds
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$Days = 7
    )
    
    try
    {
        # Get all domain controllers
        $DomainControllers = Get-ADDomainController -Filter * -ErrorAction Stop
        Write-Verbose "Found $($DomainControllers.Count) domain controller(s)"
        
        $StartTime = (Get-Date).AddDays(-$Days)
        $AllEvents = [System.Collections.Generic.List[object]]::new()
        
        foreach ($DC in $DomainControllers)
        {
            Write-Verbose "Querying $($DC.HostName) for insecure LDAP bind attempts"
            
            try
            {
                $Events = Get-WinEvent -ComputerName $DC.HostName -FilterHashtable @{
                    LogName = 'Directory Service'
                    ID = 2889
                    StartTime = $StartTime
                } -ErrorAction Stop
                
                foreach ($Event in $Events)
                {
                    # Parse event properties
                    # Property[0] = Client IP address (may include port)
                    # Property[1] = User identity
                    
                    $ClientIP = if ($Event.Properties[0].Value)
                    {
                        # Remove port if present (e.g., "192.168.1.100:49152" -> "192.168.1.100")
                        $Event.Properties[0].Value -replace ':\d+$', ''
                    }
                    else
                    {
                        'Unknown'
                    }
                    
                    $UserIdentity = if ($Event.Properties[1].Value)
                    {
                        # Remove domain prefix if present
                        $Event.Properties[1].Value -replace '^[^\\]+\\', ''
                    }
                    else
                    {
                        'Unknown'
                    }
                    
                    $AllEvents.Add([PSCustomObject]@{
                        TimeCreated = $Event.TimeCreated
                        DomainController = $DC.HostName
                        ClientIPAddress = $ClientIP
                        UserIdentity = $UserIdentity
                        Message = $Event.Message
                    })
                }
                
                Write-Verbose "Found $($Events.Count) event(s) on $($DC.HostName)"
            }
            catch [System.Diagnostics.Eventing.Reader.EventLogNotFoundException]
            {
                Write-Warning "Directory Service log not found on $($DC.HostName)"
            }
            catch [System.UnauthorizedAccessException]
            {
                Write-Warning "Access denied to $($DC.HostName). Verify permissions."
            }
            catch
            {
                Write-Warning "Failed to query $($DC.HostName): $($_.Exception.Message)"
            }
        }
        
        Write-Output "Total insecure LDAP bind attempts found: $($AllEvents.Count)"
        return $AllEvents
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Error "Active Directory module not available. Install RSAT tools or run from domain controller."
    }
    catch
    {
        Write-Error "Failed to retrieve insecure LDAP binds: $($_.Exception.Message)"
    }
}

# Usage examples
# Get all insecure LDAP binds from the last 7 days
$InsecureBinds = Get-InsecureLDAPBinds -Days 7

# Group by client IP to identify problem systems
$InsecureBinds | Group-Object ClientIPAddress | 
    Sort-Object Count -Descending | 
    Select-Object Count, Name | 
    Format-Table -AutoSize

# Group by user identity to identify problem accounts
$InsecureBinds | Group-Object UserIdentity | 
    Sort-Object Count -Descending | 
    Select-Object Count, Name | 
    Format-Table -AutoSize

# Export to CSV for further analysis
$InsecureBinds | Export-Csv -Path "InsecureLDAPBinds.csv" -NoTypeInformation
```

#### Resolving Insecure LDAP Binds

Once you've identified clients using insecure LDAP binds:

1. **Identify the application or device** by IP address
2. **Update application configuration** to use LDAP signing or LDAPS (port 636)
3. **Configure LDAP signing requirements** on domain controllers
4. **Test application connectivity** after changes
5. **Monitor for new events** to ensure remediation was successful

**PowerShell example to enable LDAP signing on domain controllers:**

```powershell
<#
.SYNOPSIS
    Configures LDAP signing requirements on domain controllers.
.DESCRIPTION
    Sets registry values to require LDAP server signing and optionally
    LDAP channel binding to enhance security.
.PARAMETER RequireSigning
    Require LDAP server signing (default: $true).
.PARAMETER ChannelBinding
    LDAP channel binding policy: 'Never', 'IfSupported', or 'Always'.
.EXAMPLE
    Set-LDAPSigningPolicy -RequireSigning $true -ChannelBinding 'Always'
.NOTES
    Requires restart of domain controller or AD DS service to take effect.
    Test thoroughly before enforcing in production.
#>
function Set-LDAPSigningPolicy
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [bool]$RequireSigning = $true,
        
        [Parameter()]
        [ValidateSet('Never', 'IfSupported', 'Always')]
        [string]$ChannelBinding = 'IfSupported'
    )
    
    $RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters'
    
    if ($PSCmdlet.ShouldProcess("LDAP Signing Policy", "Update registry settings"))
    {
        try
        {
            # LDAP Server Integrity: 0=None, 1=Optional, 2=Required
            $SigningValue = if ($RequireSigning) { 2 } else { 1 }
            Set-ItemProperty -Path $RegistryPath -Name 'LDAPServerIntegrity' -Value $SigningValue -Type DWord
            
            # LDAP Channel Binding: 0=Never, 1=IfSupported, 2=Always
            $BindingValue = switch ($ChannelBinding)
            {
                'Never' { 0 }
                'IfSupported' { 1 }
                'Always' { 2 }
            }
            Set-ItemProperty -Path $RegistryPath -Name 'LdapEnforceChannelBinding' -Value $BindingValue -Type DWord
            
            Write-Output "LDAP security policy updated successfully"
            Write-Warning "Restart the domain controller or Active Directory Domain Services for changes to take effect"
        }
        catch
        {
            Write-Error "Failed to update LDAP security policy: $($_.Exception.Message)"
        }
    }
}
```

## Parsing Event XML Data

Windows Event Logs store structured data in XML format. Understanding how to parse this XML data allows you to extract specific fields and create custom objects with exactly the information you need.

### Understanding Event XML Structure

Every Windows event has an XML representation that contains structured data:

```powershell
<#
.SYNOPSIS
    Displays the XML structure of an event.
.DESCRIPTION
    Retrieves a sample event and shows its XML structure for analysis.
.EXAMPLE
    Show-EventXMLStructure -LogName 'Security' -EventID 4624
#>
function Show-EventXMLStructure
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$EventID
    )
    
    try
    {
        # Get one event as a sample
        $Event = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            ID = $EventID
        } -MaxEvents 1 -ErrorAction Stop
        
        # Convert to XML and display
        $Xml = [xml]$Event.ToXml()
        
        Write-Output "Event XML Structure:"
        Write-Output "===================="
        $Xml.Event | Format-Custom -Depth 5
        
        Write-Output "`nEvent Data Elements:"
        Write-Output "===================="
        $Xml.Event.EventData.Data | ForEach-Object {
            Write-Output "Name: $($_.Name) = Value: $($_.'#text')"
        }
    }
    catch
    {
        Write-Error "Failed to retrieve event: $($_.Exception.Message)"
    }
}

# Example: View Security logon event structure
Show-EventXMLStructure -LogName 'Security' -EventID 4624
```

### Extracting Named EventData Fields

Events store their data in `<EventData>` elements with named fields:

```powershell
<#
.SYNOPSIS
    Parses Security logon events with detailed field extraction.
.DESCRIPTION
    Demonstrates parsing XML EventData to extract specific named fields.
    Event ID 4624: Successful logon
.EXAMPLE
    Get-LogonEvents -MaxEvents 10
#>
function Get-LogonEvents
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 100
    )
    
    try
    {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4624  # Successful logon
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        $Events | ForEach-Object {
            # Convert event to XML
            $Xml = [xml]$_.ToXml()
            $EventData = $Xml.Event.EventData.Data
            
            # Helper function to get named field value
            $GetField = {
                param([string]$FieldName)
                ($EventData | Where-Object { $_.Name -eq $FieldName }).'#text'
            }
            
            # Extract specific fields
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                EventID = $_.Id
                SubjectUserName = & $GetField 'SubjectUserName'
                SubjectDomainName = & $GetField 'SubjectDomainName'
                TargetUserName = & $GetField 'TargetUserName'
                TargetDomainName = & $GetField 'TargetDomainName'
                LogonType = & $GetField 'LogonType'
                LogonTypeName = switch (& $GetField 'LogonType') {
                    2 { 'Interactive' }
                    3 { 'Network' }
                    4 { 'Batch' }
                    5 { 'Service' }
                    7 { 'Unlock' }
                    8 { 'NetworkCleartext' }
                    9 { 'NewCredentials' }
                    10 { 'RemoteInteractive' }
                    11 { 'CachedInteractive' }
                    default { 'Unknown' }
                }
                IpAddress = & $GetField 'IpAddress'
                WorkstationName = & $GetField 'WorkstationName'
                LogonProcessName = & $GetField 'LogonProcessName'
                AuthenticationPackageName = & $GetField 'AuthenticationPackageName'
            }
        }
    }
    catch
    {
        Write-Error "Failed to retrieve logon events: $($_.Exception.Message)"
    }
}

# Usage example
Get-LogonEvents -MaxEvents 20 | 
    Where-Object { $_.LogonType -eq 10 } |  # Remote Desktop logons only
    Format-Table TimeCreated, TargetUserName, IpAddress, WorkstationName -AutoSize
```

### Handling Binary EventData

Some events use binary data instead of named fields. These require index-based extraction:

```powershell
<#
.SYNOPSIS
    Parses events with binary/indexed EventData.
.DESCRIPTION
    Demonstrates parsing events where EventData uses indexed Data elements
    rather than named elements.
.EXAMPLE
    Get-IndexedEventData -LogName 'System' -EventID 7036
#>
function Get-IndexedEventData
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,
        
        [Parameter(Mandatory = $true)]
        [int]$EventID,
        
        [Parameter()]
        [int]$MaxEvents = 50
    )
    
    try
    {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            ID = $EventID
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        $Events | ForEach-Object {
            $Xml = [xml]$_.ToXml()
            $EventData = $Xml.Event.EventData.Data
            
            # For indexed data, access by position
            if ($EventData -is [array])
            {
                [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    EventID = $_.Id
                    Data0 = $EventData[0].'#text'
                    Data1 = $EventData[1].'#text'
                    Data2 = if ($EventData.Count -gt 2) { $EventData[2].'#text' } else { $null }
                    Data3 = if ($EventData.Count -gt 3) { $EventData[3].'#text' } else { $null }
                    RawMessage = $_.Message
                }
            }
            else
            {
                # Single data element
                [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    EventID = $_.Id
                    Data = $EventData.'#text'
                    RawMessage = $_.Message
                }
            }
        }
    }
    catch
    {
        Write-Error "Failed to parse indexed event data: $($_.Exception.Message)"
    }
}
```

### Parsing Complex Nested XML

Some events contain complex nested XML structures:

```powershell
<#
.SYNOPSIS
    Parses events with complex nested XML structures.
.DESCRIPTION
    Demonstrates parsing events with UserData or other complex XML elements.
.EXAMPLE
    Get-ComplexEventData -LogName 'Microsoft-Windows-TaskScheduler/Operational' -EventID 100
#>
function Get-ComplexEventData
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        
        [Parameter(Mandatory = $true)]
        [int]$EventID,
        
        [Parameter()]
        [int]$MaxEvents = 50
    )
    
    try
    {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            ID = $EventID
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        $Events | ForEach-Object {
            $Xml = [xml]$_.ToXml()
            
            # Some events use UserData instead of EventData
            $UserData = $Xml.Event.UserData
            
            if ($UserData)
            {
                # Navigate the specific UserData structure
                $TaskData = $UserData.ChildNodes[0]  # First child element
                
                # Extract properties from nested structure
                $Properties = @{}
                $TaskData.ChildNodes | ForEach-Object {
                    $Properties[$_.LocalName] = $_.'#text'
                }
                
                # Create custom object
                $Output = [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    EventID = $_.Id
                }
                
                # Add all discovered properties
                $Properties.GetEnumerator() | ForEach-Object {
                    $Output | Add-Member -NotePropertyName $_.Key -NotePropertyValue $_.Value
                }
                
                $Output
            }
            else
            {
                # Fall back to standard EventData parsing
                [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    EventID = $_.Id
                    Message = $_.Message
                }
            }
        }
    }
    catch
    {
        Write-Error "Failed to parse complex event data: $($_.Exception.Message)"
    }
}
```

### Creating a Reusable XML Parser

Build a generic function to parse any event's XML data:

```powershell
<#
.SYNOPSIS
    Generic event XML parser for any event type.
.DESCRIPTION
    Parses event XML and returns all available fields as a custom object.
    Handles both named EventData and indexed Data elements.
.PARAMETER Event
    The event object to parse (from Get-WinEvent).
.EXAMPLE
    Get-WinEvent -LogName Security -MaxEvents 10 | ConvertFrom-EventXML
#>
function ConvertFrom-EventXML
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$Event
    )
    
    process
    {
        try
        {
            # Convert to XML
            $Xml = [xml]$Event.ToXml()
            
            # Create base object with System properties
            $Result = [PSCustomObject]@{
                TimeCreated = $Event.TimeCreated
                EventID = $Event.Id
                Level = $Event.LevelDisplayName
                Provider = $Event.ProviderName
                MachineName = $Event.MachineName
            }
            
            # Parse EventData if present
            if ($Xml.Event.EventData)
            {
                $EventData = $Xml.Event.EventData.Data
                
                if ($EventData)
                {
                    if ($EventData -is [array])
                    {
                        # Named fields
                        foreach ($DataElement in $EventData)
                        {
                            if ($DataElement.Name)
                            {
                                $FieldName = $DataElement.Name -replace '[^a-zA-Z0-9]', ''
                                $Result | Add-Member -NotePropertyName $FieldName -NotePropertyValue $DataElement.'#text' -Force
                            }
                        }
                    }
                    else
                    {
                        # Single element
                        if ($EventData.Name)
                        {
                            $FieldName = $EventData.Name -replace '[^a-zA-Z0-9]', ''
                            $Result | Add-Member -NotePropertyName $FieldName -NotePropertyValue $EventData.'#text' -Force
                        }
                    }
                }
            }
            
            # Parse UserData if present
            if ($Xml.Event.UserData)
            {
                $UserData = $Xml.Event.UserData.ChildNodes[0]
                if ($UserData)
                {
                    $UserData.ChildNodes | ForEach-Object {
                        $FieldName = $_.LocalName -replace '[^a-zA-Z0-9]', ''
                        $Result | Add-Member -NotePropertyName $FieldName -NotePropertyValue $_.'#text' -Force
                    }
                }
            }
            
            # Add raw message
            $Result | Add-Member -NotePropertyName 'Message' -NotePropertyValue $Event.Message -Force
            
            $Result
        }
        catch
        {
            Write-Error "Failed to parse event XML: $($_.Exception.Message)"
        }
    }
}

# Usage examples
# Parse Security events
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 5 | 
    ConvertFrom-EventXML |
    Select-Object TimeCreated, TargetUserName, IpAddress, LogonType

# Parse System events
Get-WinEvent -FilterHashtable @{LogName='System'; ID=7036} -MaxEvents 10 |
    ConvertFrom-EventXML |
    Select-Object TimeCreated, EventID, *
```

### Extracting Properties by XPath

Use XPath to directly query specific XML elements:

```powershell
<#
.SYNOPSIS
    Extracts specific fields using XPath queries.
.DESCRIPTION
    Demonstrates using SelectNodes and XPath to extract specific data
    from event XML without parsing the entire structure.
.EXAMPLE
    Get-WinEvent -LogName Security -MaxEvents 10 | Get-EventFieldByXPath -XPath "//Data[@Name='TargetUserName']"
#>
function Get-EventFieldByXPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$Event,
        
        [Parameter(Mandatory = $true)]
        [string]$XPath
    )
    
    process
    {
        try
        {
            $Xml = [xml]$Event.ToXml()
            $Nodes = $Xml.SelectNodes($XPath)
            
            if ($Nodes.Count -gt 0)
            {
                [PSCustomObject]@{
                    TimeCreated = $Event.TimeCreated
                    EventID = $Event.Id
                    ExtractedValue = $Nodes[0].'#text'
                    AllValues = @($Nodes | ForEach-Object { $_.'#text' })
                }
            }
        }
        catch
        {
            Write-Error "XPath query failed: $($_.Exception.Message)"
        }
    }
}

# Example: Extract specific field from Security events
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 5 |
    Get-EventFieldByXPath -XPath "//Data[@Name='TargetUserName']" |
    Format-Table TimeCreated, EventID, ExtractedValue -AutoSize
```

### Performance Considerations for XML Parsing

When parsing large numbers of events:

```powershell
<#
.SYNOPSIS
    Efficiently parses large event sets with minimal memory overhead.
.DESCRIPTION
    Demonstrates techniques for parsing thousands of events efficiently.
.EXAMPLE
    Get-BulkEventData -LogName System -Hours 168 -MaxEvents 10000
#>
function Get-BulkEventData
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        
        [Parameter()]
        [int]$Hours = 24,
        
        [Parameter()]
        [int]$MaxEvents = 10000
    )
    
    $StartTime = (Get-Date).AddHours(-$Hours)
    
    # Use pipeline processing to minimize memory usage
    Get-WinEvent -FilterHashtable @{
        LogName = $LogName
        Level = 1, 2, 3
        StartTime = $StartTime
    } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue |
    ForEach-Object {
        # Parse only what you need
        $Xml = [xml]$_.ToXml()
        
        # Create minimal object with only required fields
        [PSCustomObject]@{
            Time = $_.TimeCreated
            ID = $_.Id
            Level = $_.Level
            Source = $_.ProviderName
            # Add only the specific EventData fields you need
            # This is much faster than parsing everything
        }
    }
}
```

### Best Practices for XML Parsing

1. **Cache frequently accessed nodes**: Store XPath queries in variables
2. **Use pipeline processing**: Process events one at a time to reduce memory usage
3. **Extract only needed fields**: Don't parse the entire XML if you only need specific fields
4. **Handle null values**: Always check if fields exist before accessing them
5. **Use -ErrorAction**: Prevent errors from stopping your entire pipeline

```powershell
# ✅ Efficient XML parsing
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 1000 |
ForEach-Object {
    $Xml = [xml]$_.ToXml()
    $EventData = $Xml.Event.EventData.Data
    
    # Only extract the fields you need
    [PSCustomObject]@{
        Time = $_.TimeCreated
        User = ($EventData | Where-Object Name -eq 'TargetUserName').'#text'
        IP = ($EventData | Where-Object Name -eq 'IpAddress').'#text'
    }
} | Export-Csv -Path "logons.csv" -NoTypeInformation

# ❌ Inefficient - parsing entire XML structure for every event
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 1000 |
ConvertTo-Json -Depth 10 |
ConvertFrom-Json
```

## Application Event Log Analysis

### Query Application Errors

```powershell
<#
.SYNOPSIS
    Retrieves application error events with detailed information.
.DESCRIPTION
    Queries the Application log for error-level events, grouping by source for analysis.
.EXAMPLE
    Get-ApplicationErrors -Hours 24 | Group-Object ProviderName | Sort-Object Count -Descending
#>
function Get-ApplicationErrors
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 720)]
        [int]$Hours = 24
    )
    
    $StartTime = (Get-Date).AddHours(-$Hours)
    
    $ApplicationErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Level = 2  # Error level
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue
    
    $ApplicationErrors | Select-Object TimeCreated, 
        @{Name='Source'; Expression={$_.ProviderName}},
        Id,
        @{Name='ErrorMessage'; Expression={$_.Message}}
}

# Usage: Find most common error sources
Get-ApplicationErrors -Hours 24 | 
    Group-Object Source | 
    Sort-Object Count -Descending | 
    Select-Object Count, Name |
    Format-Table -AutoSize
```

## Advanced Filtering and Performance

### Using XPath Queries

```powershell
<#
.SYNOPSIS
    Demonstrates XPath filtering for complex event queries.
.DESCRIPTION
    XPath provides more flexibility than FilterHashtable for complex queries.
.EXAMPLE
    Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4624) and TimeCreated[timediff(@SystemTime) <= 86400000]]]"
#>

# Query failed logons with specific substatus codes
$XPathQuery = @"
*[System[
    (EventID=4625) and 
    TimeCreated[timediff(@SystemTime) <= 86400000]
]] and 
*[EventData[
    Data[@Name='SubStatus']='0xC000006A'
]]
"@

Get-WinEvent -LogName 'Security' -FilterXPath $XPathQuery -MaxEvents 100 -ErrorAction SilentlyContinue
```

### Efficient Remote Event Log Queries

```powershell
<#
.SYNOPSIS
    Queries event logs from remote computers efficiently.
.DESCRIPTION
    Demonstrates best practices for remote event log queries with proper error handling.
.PARAMETER ComputerName
    One or more remote computer names to query.
.PARAMETER LogName
    The event log name to query.
.PARAMETER MaxEvents
    Maximum number of events to retrieve per computer.
.EXAMPLE
    Get-RemoteEventLog -ComputerName "Server01", "Server02" -LogName System -MaxEvents 50
#>
function Get-RemoteEventLog
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,
        
        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 100
    )
    
    process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Querying $LogName log on $Computer"
            
            try
            {
                $Events = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                    LogName = $LogName
                    Level = 1, 2, 3  # Critical, Error, Warning
                } -MaxEvents $MaxEvents -ErrorAction Stop
                
                $Events | Select-Object @{Name='Computer'; Expression={$Computer}},
                    TimeCreated, 
                    LevelDisplayName, 
                    ProviderName, 
                    Id, 
                    Message
            }
            catch [System.UnauthorizedAccessException]
            {
                Write-Error "Access denied to $Computer. Verify credentials and permissions."
            }
            catch [System.Exception]
            {
                Write-Error "Failed to query $Computer : $($_.Exception.Message)"
            }
        }
    }
}
```

## Event Log Export and Reporting

### Export Events to CSV

```powershell
<#
.SYNOPSIS
    Exports event log data to CSV for analysis.
.DESCRIPTION
    Retrieves events and exports to CSV with proper formatting.
.EXAMPLE
    Export-EventLogToCSV -LogName System -OutputPath "C:\Reports\SystemEvents.csv" -Days 7
#>
function Export-EventLogToCSV
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$Days = 1
    )
    
    $StartTime = (Get-Date).AddDays(-$Days)
    
    try
    {
        Write-Verbose "Retrieving events from $LogName log for the last $Days days"
        
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            StartTime = $StartTime
        } -ErrorAction Stop
        
        $Events | Select-Object TimeCreated, 
            LevelDisplayName, 
            ProviderName, 
            Id, 
            @{Name='Message'; Expression={$_.Message -replace "`r`n", " "}} |
            Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        
        Write-Output "Exported $($Events.Count) events to $OutputPath"
    }
    catch
    {
        Write-Error "Failed to export events: $($_.Exception.Message)"
    }
}
```

### Generate HTML Report

```powershell
<#
.SYNOPSIS
    Generates an HTML report of critical system events.
.DESCRIPTION
    Creates a formatted HTML report of errors and warnings for easy review.
.EXAMPLE
    New-EventLogHTMLReport -OutputPath "C:\Reports\EventReport.html" -Hours 24
#>
function New-EventLogHTMLReport
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateRange(1, 720)]
        [int]$Hours = 24
    )
    
    $StartTime = (Get-Date).AddHours(-$Hours)
    $ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Gather events from multiple logs
    $SystemEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1, 2, 3
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue
    
    $ApplicationEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Level = 1, 2, 3
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue
    
    # Build HTML report
    $HtmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Event Log Report - $env:COMPUTERNAME</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 2px solid #ddd; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background-color: #4CAF50; color: white; padding: 8px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .critical { background-color: #ffcccc; }
        .error { background-color: #ffe6cc; }
        .warning { background-color: #ffffcc; }
    </style>
</head>
<body>
    <h1>Event Log Report: $env:COMPUTERNAME</h1>
    <p>Report Generated: $ReportDate</p>
    <p>Time Range: Last $Hours hours</p>
    
    <h2>System Events Summary</h2>
    <p>Total Events: $($SystemEvents.Count)</p>
    $($SystemEvents | Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, Message | ConvertTo-Html -Fragment)
    
    <h2>Application Events Summary</h2>
    <p>Total Events: $($ApplicationEvents.Count)</p>
    $($ApplicationEvents | Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, Message | ConvertTo-Html -Fragment)
</body>
</html>
"@
    
    $HtmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Output "HTML report generated: $OutputPath"
}
```

## Best Practices

### Performance Optimization

1. **Use FilterHashtable for server-side filtering** - Reduces network traffic and improves query speed
2. **Limit MaxEvents** - Avoid retrieving more events than necessary
3. **Use specific time ranges** - Narrow your query window with StartTime and EndTime
4. **Avoid Where-Object when possible** - Use FilterHashtable parameters instead

```powershell
# ❌ Inefficient - Client-side filtering
Get-WinEvent -LogName System | Where-Object { $_.Level -eq 2 }

# ✅ Efficient - Server-side filtering
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2}
```

### Error Handling

Always use proper error handling when querying event logs:

```powershell
try
{
    $Events = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -ErrorAction Stop
}
catch [System.Diagnostics.Eventing.Reader.EventLogNotFoundException]
{
    Write-Error "Event log not found"
}
catch [System.UnauthorizedAccessException]
{
    Write-Error "Access denied - Administrator rights required"
}
catch
{
    Write-Error "Unexpected error: $($_.Exception.Message)"
}
```

### Security Considerations

1. **Require appropriate permissions** - Many event logs require Administrator rights
2. **Sanitize output** - Be careful when displaying or exporting event data that may contain sensitive information
3. **Audit access** - Event log queries themselves may be audited in security-sensitive environments
4. **Use secure remoting** - When querying remote systems, ensure secure communication channels

## Common Event IDs Reference

### Security Log

| Event ID | Description |
|----------|-------------|
| 4624 | Successful logon |
| 4625 | Failed logon attempt |
| 4634 | Logoff |
| 4648 | Logon using explicit credentials |
| 4672 | Special privileges assigned to new logon |
| 4720 | User account created |
| 4722 | User account enabled |
| 4725 | User account disabled |
| 4732 | Member added to security-enabled local group |

### System Log

| Event ID | Description |
|----------|-------------|
| 1074 | System shutdown/restart |
| 6005 | Event log service started |
| 6006 | Event log service stopped |
| 6008 | Unexpected shutdown |
| 7034 | Service crashed unexpectedly |
| 7036 | Service state change |

### Windows Defender

| Event ID | Description |
|----------|-------------|
| 1116 | Malware detected |
| 1117 | Malware remediation action |
| 1118 | Malware remediation failed |
| 5001 | Real-time protection disabled |
| 5007 | Configuration changed |

## Related Resources

- [Get-WinEvent Documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent)
- [Windows Event Log Reference](https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/security-auditing-overview)
- [PowerShell Best Practices](../index.md)
