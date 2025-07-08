---
title: "Active Directory Health Check and Diagnostic Report"
description: "Comprehensive PowerShell script for monitoring Active Directory forest health using DCDiag and RepAdmin tools with modern reporting capabilities"
author: "IT Operations"
ms.date: "07/05/2025"
ms.topic: "how-to"
ms.service: "active-directory"
keywords: Active Directory, DCDiag, RepAdmin, PowerShell, forest health, replication, diagnostics, monitoring
---

This comprehensive PowerShell module provides enterprise-grade Active Directory health monitoring and reporting capabilities. It combines DCDiag and RepAdmin functionality with modern PowerShell practices, error handling, and flexible output formats.

## Overview

The script performs comprehensive Active Directory forest health checks including:

- Domain controller diagnostics across all domains in the forest
- Replication status and failure analysis
- Flexible reporting with multiple output formats
- Error handling and validation
- Performance optimizations for large environments

## Prerequisites

Before running this script, ensure the following requirements are met:

### Software Requirements

- **PowerShell 5.1 or later** (PowerShell 7+ recommended)
- **Active Directory PowerShell Module** installed
- **Domain Controller Tools** (DCDiag and RepAdmin) available
- **Administrative privileges** on domain controllers

### Permissions Required

- **Domain Admin** or equivalent rights for comprehensive testing
- **Read access** to all domain controllers in the forest
- **Network connectivity** to all DCs on required ports

### Network Requirements

- Access to **LDAP ports** (389, 636, 3268, 3269)
- **DNS resolution** for all domain controllers
- **Kerberos authentication** (port 88)
- **RPC endpoint mapper** (port 135) and dynamic RPC ports

## Security Considerations

- **Run with least privilege**: Use dedicated service accounts when possible
- **Secure credential storage**: Avoid hardcoded passwords
- **Audit logging**: Enable monitoring of diagnostic activities
- **Network security**: Ensure encrypted connections where possible
- **Data protection**: Handle diagnostic output securely

## PowerShell Module: AD-HealthCheck

### Installation and Setup

```powershell
# Import required modules
Import-Module ActiveDirectory
Import-Module Microsoft.PowerShell.Utility

# Verify required tools are available
if (-not (Get-Command dcdiag.exe -ErrorAction SilentlyContinue)) {
    throw "DCDiag tool not found. Please install Remote Server Administration Tools (RSAT)."
}

if (-not (Get-Command repadmin.exe -ErrorAction SilentlyContinue)) {
    throw "RepAdmin tool not found. Please install Remote Server Administration Tools (RSAT)."
}
```

### Core Functions

#### Get-ForestDomainControllers Function

```powershell
function Get-ForestDomainControllers {
    <#
    .SYNOPSIS
        Retrieves all domain controllers from all domains in the current forest.
    
    .DESCRIPTION
        This function discovers all domains in the current Active Directory forest
        and returns a comprehensive list of all domain controllers.
    
    .PARAMETER Credential
        Optional credentials for forest access
    
    .EXAMPLE
        $DCs = Get-ForestDomainControllers
        
    .EXAMPLE
        $DCs = Get-ForestDomainControllers -Credential $cred
    #>
    [CmdletBinding()]
    param(
        [PSCredential]$Credential
    )
    
    try {
        Write-Verbose "Discovering forest domains..."
        $forestParams = @{}
        if ($Credential) { $forestParams.Credential = $Credential }
        
        $forest = Get-ADForest @forestParams
        $domainControllers = [System.Collections.Generic.List[PSObject]]::new()
        
        foreach ($domainName in $forest.Domains) {
            try {
                Write-Verbose "Getting domain controllers for domain: $domainName"
                $domainParams = @{
                    Identity = $domainName
                }
                if ($Credential) { $domainParams.Credential = $Credential }
                
                $domain = Get-ADDomain @domainParams
                
                foreach ($dc in $domain.ReplicaDirectoryServers) {
                    $dcObject = [PSCustomObject]@{
                        Name = $dc
                        Domain = $domainName
                        Site = $null
                        OperatingSystem = $null
                        IPv4Address = $null
                    }
                    
                    # Get additional DC information
                    try {
                        $dcInfo = Get-ADDomainController -Identity $dc @domainParams
                        $dcObject.Site = $dcInfo.Site
                        $dcObject.OperatingSystem = $dcInfo.OperatingSystem
                        $dcObject.IPv4Address = $dcInfo.IPv4Address
                    }
                    catch {
                        Write-Warning "Could not retrieve detailed information for DC: $dc"
                    }
                    
                    $domainControllers.Add($dcObject)
                }
            }
            catch {
                Write-Error "Failed to process domain $domainName : $($_.Exception.Message)"
            }
        }
        
        Write-Verbose "Found $($domainControllers.Count) domain controllers"
        return $domainControllers
    }
    catch {
        throw "Failed to retrieve forest domain controllers: $($_.Exception.Message)"
    }
}
```

#### Get-DCDiagReport Function

```powershell
function Get-DCDiagReport {
    <#
    .SYNOPSIS
        Performs DCDiag tests on a specified domain controller.
    
    .DESCRIPTION
        Executes DCDiag against a domain controller and parses the results
        into a structured PowerShell object for analysis and reporting.
    
    .PARAMETER ComputerName
        The name or IP address of the domain controller to test
    
    .PARAMETER Tests
        Specific tests to run (default: all tests)
    
    .PARAMETER Verbose
        Include verbose DCDiag output
    
    .EXAMPLE
        $report = Get-DCDiagReport -ComputerName "DC01.contoso.com"
        
    .EXAMPLE
        $report = Get-DCDiagReport -ComputerName "DC01" -Tests @("Connectivity", "Replications")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [string[]]$Tests = @(),
        
        [switch]$IncludeVerbose
    )
    
    try {
        Write-Verbose "Running DCDiag tests on $ComputerName"
        
        # Build DCDiag command
        $dcdiagArgs = @("/s:$ComputerName")
        if ($IncludeVerbose) { $dcdiagArgs += "/v" }
        if ($Tests.Count -gt 0) {
            foreach ($test in $Tests) {
                $dcdiagArgs += "/test:$test"
            }
        }
        
        # Execute DCDiag
        $dcdiagOutput = & dcdiag.exe $dcdiagArgs 2>&1
        
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            throw "DCDiag failed with exit code: $LASTEXITCODE"
        }
        
        # Parse results
        $results = [PSCustomObject]@{
            ComputerName = $ComputerName
            Timestamp = Get-Date
            OverallStatus = "Unknown"
            Tests = @{}
            Errors = @()
            Warnings = @()
        }
        
        $currentTest = $null
        $testResults = @{}
        
        foreach ($line in $dcdiagOutput) {
            $lineStr = $line.ToString()
            
            # Parse test start
            if ($lineStr -match "Starting test: (.+)") {
                $currentTest = $matches[1].Trim()
                Write-Verbose "Processing test: $currentTest"
            }
            
            # Parse test results
            if ($lineStr -match "\.+ (PASSED|FAILED)") {
                $status = $matches[1]
                if ($currentTest) {
                    $testResults[$currentTest] = $status
                    $currentTest = $null
                }
            }
            
            # Parse errors and warnings
            if ($lineStr -match "Error|Fatal") {
                $results.Errors += $lineStr.Trim()
            }
            elseif ($lineStr -match "Warning") {
                $results.Warnings += $lineStr.Trim()
            }
        }
        
        $results.Tests = $testResults
        
        # Determine overall status
        $failedTests = ($testResults.Values | Where-Object { $_ -eq "FAILED" }).Count
        $results.OverallStatus = if ($failedTests -eq 0) { "PASSED" } else { "FAILED" }
        
        Write-Verbose "DCDiag completed for $ComputerName. Status: $($results.OverallStatus)"
        return $results
    }
    catch {
        throw "DCDiag test failed for $ComputerName : $($_.Exception.Message)"
    }
}
```

#### Get-ReplicationReport Function

```powershell
function Get-ReplicationReport {
    <#
    .SYNOPSIS
        Generates a comprehensive Active Directory replication report.
    
    .DESCRIPTION
        Uses RepAdmin to analyze replication status across the forest
        and provides detailed reporting on replication health and failures.
    
    .PARAMETER ComputerName
        Specific domain controller to analyze (default: all DCs)
    
    .PARAMETER IncludeSuccessful
        Include successful replications in the report
    
    .EXAMPLE
        $report = Get-ReplicationReport
        
    .EXAMPLE
        $report = Get-ReplicationReport -ComputerName "DC01" -IncludeSuccessful
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = "*",
        
        [switch]$IncludeSuccessful
    )
    
    try {
        Write-Verbose "Gathering replication information..."
        
        # Execute repadmin
        $repadminOutput = & repadmin.exe /showrepl $ComputerName /csv 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "RepAdmin failed with exit code: $LASTEXITCODE"
        }
        
        # Parse CSV output
        $replData = $repadminOutput | ConvertFrom-Csv
        
        $replicationReport = [System.Collections.Generic.List[PSObject]]::new()
        
        foreach ($entry in $replData) {
            $replObject = [PSCustomObject]@{
                DestinationDC = $entry.'Destination DSA'
                DestinationSite = $entry.'Destination DSA Site'
                NamingContext = $entry.'Naming Context'
                SourceDC = $entry.'Source DSA'
                SourceSite = $entry.'Source DSA Site'
                TransportType = $entry.'Transport Type'
                NumberOfFailures = [int]$entry.'Number of Failures'
                LastFailureTime = if ($entry.'Last Failure Time') { 
                    try { [datetime]$entry.'Last Failure Time' } catch { $entry.'Last Failure Time' }
                } else { $null }
                LastSuccessTime = if ($entry.'Last Success Time') { 
                    try { [datetime]$entry.'Last Success Time' } catch { $entry.'Last Success Time' }
                } else { $null }
                LastFailureStatus = $entry.'Last Failure Status'
                ConsecutiveFailures = [int]$entry.'Number of Failures'
                ReplicationHealth = $null
            }
            
            # Determine replication health
            if ($replObject.NumberOfFailures -eq 0) {
                $replObject.ReplicationHealth = "Healthy"
            }
            elseif ($replObject.NumberOfFailures -le 3) {
                $replObject.ReplicationHealth = "Warning"
            }
            else {
                $replObject.ReplicationHealth = "Critical"
            }
            
            # Add time since last success
            if ($replObject.LastSuccessTime) {
                $timeSinceSuccess = (Get-Date) - $replObject.LastSuccessTime
                Add-Member -InputObject $replObject -NotePropertyName "HoursSinceLastSuccess" -NotePropertyValue $timeSinceSuccess.TotalHours
            }
            
            if ($IncludeSuccessful -or $replObject.NumberOfFailures -gt 0) {
                $replicationReport.Add($replObject)
            }
        }
        
        Write-Verbose "Processed $($replicationReport.Count) replication partnerships"
        return $replicationReport
    }
    catch {
        throw "Replication report generation failed: $($_.Exception.Message)"
    }
}
```

#### Export Functions

```powershell
function Export-ADHealthReport {
    <#
    .SYNOPSIS
        Exports Active Directory health report to various formats.
    
    .DESCRIPTION
        Combines DCDiag and replication data into comprehensive reports
        with support for multiple output formats including HTML, CSV, and JSON.
    
    .PARAMETER DCDiagResults
        Array of DCDiag test results
    
    .PARAMETER ReplicationResults
        Array of replication status results
    
    .PARAMETER OutputPath
        Path for output files
    
    .PARAMETER Format
        Output format: HTML, CSV, JSON, or Console
    
    .EXAMPLE
        Export-ADHealthReport -DCDiagResults $dcResults -ReplicationResults $replResults -OutputPath "C:\Reports" -Format "HTML"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject[]]$DCDiagResults,
        
        [Parameter(Mandatory = $true)]
        [PSObject[]]$ReplicationResults,
        
        [string]$OutputPath = ".",
        
        [ValidateSet("HTML", "CSV", "JSON", "Console")]
        [string]$Format = "Console"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    switch ($Format) {
        "HTML" {
            $htmlReport = Generate-HTMLReport -DCDiagResults $DCDiagResults -ReplicationResults $ReplicationResults
            $htmlPath = Join-Path $OutputPath "AD-HealthReport-$timestamp.html"
            $htmlReport | Out-File -FilePath $htmlPath -Encoding UTF8
            Write-Host "HTML report saved to: $htmlPath" -ForegroundColor Green
        }
        
        "CSV" {
            $csvPath = Join-Path $OutputPath "DCDiag-Results-$timestamp.csv"
            $DCDiagResults | Export-Csv -Path $csvPath -NoTypeInformation
            
            $replPath = Join-Path $OutputPath "Replication-Results-$timestamp.csv"
            $ReplicationResults | Export-Csv -Path $replPath -NoTypeInformation
            
            Write-Host "CSV reports saved to: $csvPath and $replPath" -ForegroundColor Green
        }
        
        "JSON" {
            $report = @{
                Timestamp = Get-Date
                DCDiagResults = $DCDiagResults
                ReplicationResults = $ReplicationResults
            }
            
            $jsonPath = Join-Path $OutputPath "AD-HealthReport-$timestamp.json"
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
            Write-Host "JSON report saved to: $jsonPath" -ForegroundColor Green
        }
        
        "Console" {
            Show-ConsoleReport -DCDiagResults $DCDiagResults -ReplicationResults $ReplicationResults
        }
    }
}

function Generate-HTMLReport {
    param($DCDiagResults, $ReplicationResults)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #2E5AA8; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .passed { background-color: #d4edda; }
        .failed { background-color: #f8d7da; }
        .warning { background-color: #fff3cd; }
        .critical { background-color: #f8d7da; }
        .healthy { background-color: #d4edda; }
    </style>
</head>
<body>
    <h1>Active Directory Health Report</h1>
    <p>Generated: $(Get-Date)</p>
    
    <h2>DCDiag Test Results Summary</h2>
    <table>
        <tr>
            <th>Domain Controller</th>
            <th>Overall Status</th>
            <th>Failed Tests</th>
            <th>Errors</th>
            <th>Warnings</th>
        </tr>
"@
    
    foreach ($result in $DCDiagResults) {
        $failedTests = ($result.Tests.Values | Where-Object { $_ -eq "FAILED" }).Count
        $statusClass = if ($result.OverallStatus -eq "PASSED") { "passed" } else { "failed" }
        
        $html += @"
        <tr class="$statusClass">
            <td>$($result.ComputerName)</td>
            <td>$($result.OverallStatus)</td>
            <td>$failedTests</td>
            <td>$($result.Errors.Count)</td>
            <td>$($result.Warnings.Count)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Replication Status Summary</h2>
    <table>
        <tr>
            <th>Source DC</th>
            <th>Destination DC</th>
            <th>Naming Context</th>
            <th>Failures</th>
            <th>Status</th>
            <th>Last Success</th>
        </tr>
"@
    
    foreach ($repl in ($ReplicationResults | Sort-Object SourceDC, NamingContext)) {
        $statusClass = switch ($repl.ReplicationHealth) {
            "Healthy" { "healthy" }
            "Warning" { "warning" }
            "Critical" { "critical" }
            default { "" }
        }
        
        $html += @"
        <tr class="$statusClass">
            <td>$($repl.SourceDC)</td>
            <td>$($repl.DestinationDC)</td>
            <td>$($repl.NamingContext)</td>
            <td>$($repl.NumberOfFailures)</td>
            <td>$($repl.ReplicationHealth)</td>
            <td>$($repl.LastSuccessTime)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    return $html
}

function Show-ConsoleReport {
    param($DCDiagResults, $ReplicationResults)
    
    Write-Host "`n=== Active Directory Health Report ===" -ForegroundColor Cyan
    Write-Host "Generated: $(Get-Date)" -ForegroundColor Gray
    
    Write-Host "`n--- DCDiag Results Summary ---" -ForegroundColor Yellow
    $DCDiagResults | Format-Table ComputerName, OverallStatus, @{
        Name = "Failed Tests"
        Expression = { ($_.Tests.Values | Where-Object { $_ -eq "FAILED" }).Count }
    }, @{
        Name = "Errors"
        Expression = { $_.Errors.Count }
    }, @{
        Name = "Warnings" 
        Expression = { $_.Warnings.Count }
    } -AutoSize
    
    Write-Host "`n--- Replication Issues ---" -ForegroundColor Yellow
    $criticalRepl = $ReplicationResults | Where-Object { $_.NumberOfFailures -gt 0 }
    if ($criticalRepl) {
        $criticalRepl | Format-Table SourceDC, DestinationDC, NamingContext, NumberOfFailures, LastFailureStatus -AutoSize
    } else {
        Write-Host "No replication failures detected!" -ForegroundColor Green
    }
}
```

### Main Execution Script

```powershell
function Start-ADHealthCheck {
    <#
    .SYNOPSIS
        Performs comprehensive Active Directory health check.
    
    .DESCRIPTION
        Main function that orchestrates DCDiag and replication testing
        across the entire forest with comprehensive reporting.
    
    .PARAMETER OutputPath
        Directory for output files
    
    .PARAMETER Format
        Output format for reports
    
    .PARAMETER IncludeSuccessfulReplication
        Include successful replication in reports
    
    .PARAMETER Credential
        Credentials for forest access
    
    .EXAMPLE
        Start-ADHealthCheck -OutputPath "C:\Reports" -Format "HTML"
        
    .EXAMPLE
        Start-ADHealthCheck -Format "Console" -IncludeSuccessfulReplication
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath = ".",
        
        [ValidateSet("HTML", "CSV", "JSON", "Console")]
        [string]$Format = "Console",
        
        [switch]$IncludeSuccessfulReplication,
        
        [PSCredential]$Credential
    )
    
    try {
        Write-Host "Starting Active Directory Health Check..." -ForegroundColor Green
        
        # Verify prerequisites
        Test-Prerequisites
        
        # Get all domain controllers
        Write-Host "Discovering domain controllers..." -ForegroundColor Yellow
        $forestParams = @{}
        if ($Credential) { $forestParams.Credential = $Credential }
        
        $domainControllers = Get-ForestDomainControllers @forestParams
        Write-Host "Found $($domainControllers.Count) domain controllers" -ForegroundColor Green
        
        # Run DCDiag tests
        Write-Host "Running DCDiag tests..." -ForegroundColor Yellow
        $dcdiagResults = [System.Collections.Generic.List[PSObject]]::new()
        
        $counter = 0
        foreach ($dc in $domainControllers) {
            $counter++
            Write-Progress -Activity "Running DCDiag Tests" -Status "Testing $($dc.Name)" -PercentComplete (($counter / $domainControllers.Count) * 100)
            
            try {
                $result = Get-DCDiagReport -ComputerName $dc.Name
                $dcdiagResults.Add($result)
            }
            catch {
                Write-Warning "DCDiag failed for $($dc.Name): $($_.Exception.Message)"
            }
        }
        Write-Progress -Activity "Running DCDiag Tests" -Completed
        
        # Run replication tests
        Write-Host "Analyzing replication status..." -ForegroundColor Yellow
        $replicationResults = Get-ReplicationReport -IncludeSuccessful:$IncludeSuccessfulReplication
        
        # Generate reports
        Write-Host "Generating reports..." -ForegroundColor Yellow
        Export-ADHealthReport -DCDiagResults $dcdiagResults -ReplicationResults $replicationResults -OutputPath $OutputPath -Format $Format
        
        # Summary
        $failedDCs = ($dcdiagResults | Where-Object { $_.OverallStatus -eq "FAILED" }).Count
        $replIssues = ($replicationResults | Where-Object { $_.NumberOfFailures -gt 0 }).Count
        
        Write-Host "`n=== Health Check Summary ===" -ForegroundColor Cyan
        Write-Host "Domain Controllers Tested: $($dcdiagResults.Count)" -ForegroundColor White
        Write-Host "Domain Controllers with Issues: $failedDCs" -ForegroundColor $(if ($failedDCs -eq 0) { "Green" } else { "Red" })
        Write-Host "Replication Partnerships with Issues: $replIssues" -ForegroundColor $(if ($replIssues -eq 0) { "Green" } else { "Red" })
        
        if ($failedDCs -eq 0 -and $replIssues -eq 0) {
            Write-Host "✓ Active Directory forest appears healthy!" -ForegroundColor Green
        } else {
            Write-Host "⚠ Issues detected - review detailed reports" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Health check failed: $($_.Exception.Message)"
        throw
    }
}

function Test-Prerequisites {
    # Test required modules
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "Active Directory PowerShell module is not installed"
    }
    
    # Test required tools
    if (-not (Get-Command dcdiag.exe -ErrorAction SilentlyContinue)) {
        throw "DCDiag tool not found. Install Remote Server Administration Tools (RSAT)"
    }
    
    if (-not (Get-Command repadmin.exe -ErrorAction SilentlyContinue)) {
        throw "RepAdmin tool not found. Install Remote Server Administration Tools (RSAT)"
    }
    
    # Test AD connectivity
    try {
        $null = Get-ADForest -ErrorAction Stop
    }
    catch {
        throw "Cannot connect to Active Directory forest: $($_.Exception.Message)"
    }
}
```

## Usage Examples

### Basic Health Check

```powershell
# Simple console output
Start-ADHealthCheck

# Generate HTML report
Start-ADHealthCheck -OutputPath "C:\Reports" -Format "HTML"

# Include successful replications
Start-ADHealthCheck -Format "Console" -IncludeSuccessfulReplication
```

### Advanced Usage

```powershell
# Use alternate credentials
$cred = Get-Credential
Start-ADHealthCheck -Credential $cred -Format "JSON" -OutputPath "C:\Reports"

# Test specific domain controller
$dcResult = Get-DCDiagReport -ComputerName "DC01.contoso.com" -IncludeVerbose

# Get replication status for specific DC
$replStatus = Get-ReplicationReport -ComputerName "DC01.contoso.com"
```

### Scheduled Automation

```powershell
# Create scheduled task for daily health checks
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\AD-HealthCheck.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "6:00 AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "AD Health Check" -Action $action -Trigger $trigger -Settings $settings
```

## Troubleshooting

### Common DCDiag Test Failures

#### Connectivity Test Failures

**Symptoms**: "Connectivity" test fails

**Common Causes**:

- Network connectivity issues
- DNS resolution problems
- Firewall blocking required ports
- Domain controller service stopped

**Solutions**:

```powershell
# Test network connectivity
Test-NetConnection -ComputerName "DC01.contoso.com" -Port 389
Test-NetConnection -ComputerName "DC01.contoso.com" -Port 636

# Test DNS resolution
Resolve-DnsName "DC01.contoso.com"
nslookup DC01.contoso.com

# Check AD services
Get-Service -ComputerName "DC01" -Name "NTDS","DNS","Netlogon","KDC"
```

#### Replication Test Failures

**Symptoms**: "Replications" test fails

**Common Causes**:

- Network latency or timeouts
- Authentication issues
- Knowledge Consistency Checker (KCC) problems
- Lingering objects

**Solutions**:

```powershell
# Force replication
repadmin /replicate DC02.contoso.com DC01.contoso.com "DC=contoso,DC=com"

# Check replication topology
repadmin /showreps DC01.contoso.com

# Force KCC to run
repadmin /kcc DC01.contoso.com
```

#### Services Test Failures

**Symptoms**: "Services" test fails

**Common Causes**:

- Required AD services not running
- Service account issues
- Registry corruption

**Solutions**:

```powershell
# Check critical AD services
$services = @("NTDS", "DNS", "Netlogon", "KDC", "W32Time")
Get-Service -Name $services | Format-Table Name, Status, StartType

# Restart services if needed
Restart-Service -Name "NTDS" -Force
```

### Common Replication Issues

#### High Failure Counts

**Symptoms**: NumberOfFailures > 0 in replication report

**Investigation Steps**:

```powershell
# Check replication status
repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object {$_.'Number of Failures' -gt 0}

# Check event logs for replication errors
Get-WinEvent -LogName "Directory Service" -MaxEvents 100 | Where-Object {$_.Id -in @(1311, 1388, 1925, 2042)}

# Verify naming contexts
repadmin /showreps * | findstr "FAIL"
```

#### Time Synchronization Issues

**Symptoms**: Authentication failures, Kerberos errors

**Solutions**:

```powershell
# Check time synchronization
w32tm /query /status
w32tm /query /peers

# Force time sync
w32tm /resync /force

# Configure reliable time source
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual
```

### Performance Optimization

#### Large Forest Considerations

For forests with many domain controllers, consider:

```powershell
# Run tests in parallel
$jobs = @()
foreach ($dc in $domainControllers) {
    $jobs += Start-Job -ScriptBlock {
        param($dcName)
        Get-DCDiagReport -ComputerName $dcName
    } -ArgumentList $dc.Name
}

# Wait for completion and gather results
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
```

#### Memory and Resource Management

```powershell
# Monitor script performance
Measure-Command { Start-ADHealthCheck }

# Use streaming for large datasets
Get-ReplicationReport | Where-Object {$_.NumberOfFailures -gt 0} | Export-Csv "Issues.csv" -NoTypeInformation
```

## Integration Examples

### SCOM Integration

```powershell
# Custom SCOM discovery script
function New-SCOMDiscovery {
    $domainControllers = Get-ForestDomainControllers
    foreach ($dc in $domainControllers) {
        # Create SCOM discovery data
        $discoveryData = @{
            ComputerName = $dc.Name
            Domain = $dc.Domain
            Site = $dc.Site
        }
        # Submit to SCOM
    }
}
```

### Email Reporting

```powershell
function Send-ADHealthReport {
    param(
        [string[]]$Recipients,
        [string]$SmtpServer,
        [PSCredential]$Credential
    )
    
    $report = Start-ADHealthCheck -Format "HTML" -OutputPath $env:TEMP
    
    $mailParams = @{
        To = $Recipients
        From = "ad-health@contoso.com"
        Subject = "Active Directory Health Report - $(Get-Date -Format 'yyyy-MM-dd')"
        Body = "Please see attached Active Directory health report."
        SmtpServer = $SmtpServer
        Attachments = $report
    }
    
    if ($Credential) { $mailParams.Credential = $Credential }
    
    Send-MailMessage @mailParams
}
```

### PowerBI Integration

```powershell
# Export data for PowerBI analysis
function Export-PowerBIData {
    $dcResults = Start-ADHealthCheck -Format "JSON"
    
    # Transform for PowerBI
    $powerBIData = $dcResults | Select-Object @{
        Name = "Date"
        Expression = { Get-Date -Format "yyyy-MM-dd" }
    }, ComputerName, OverallStatus, @{
        Name = "FailedTestCount"
        Expression = { ($_.Tests.Values | Where-Object { $_ -eq "FAILED" }).Count }
    }
    
    $powerBIData | Export-Csv "PowerBI-ADHealth.csv" -NoTypeInformation
}
```

## Best Practices

### Security Best Practices

1. **Use dedicated service accounts** for automated health checks
2. **Store credentials securely** using Windows Credential Manager or Azure Key Vault
3. **Implement audit logging** for all diagnostic activities
4. **Restrict access** to health check reports containing sensitive information
5. **Use encrypted connections** when possible

### Operational Best Practices

1. **Schedule regular health checks** (daily recommended)
2. **Set up alerting** for critical failures
3. **Maintain historical data** for trend analysis
4. **Document remediation procedures** for common failures
5. **Test disaster recovery scenarios** regularly

### Performance Best Practices

1. **Run during maintenance windows** for comprehensive tests
2. **Use parallel processing** for large environments
3. **Implement caching** for repeated operations
4. **Monitor resource usage** during execution
5. **Optimize network connectivity** between test systems and DCs

## Advanced Configuration

### Custom Test Selection

```powershell
# Define custom test suites
$CriticalTests = @("Connectivity", "Replications", "Services", "Advertising")
$FullTests = @("Connectivity", "Advertising", "CheckSDRefDom", "CrossRefValidation", "DFSREvent", "DNS", "FrsEvent", "Intersite", "KccEvent", "KnowsOfRoleHolders", "MachineAccount", "NCSecDesc", "NetLogons", "ObjectsReplicated", "Replications", "RidManager", "Services", "SystemLog", "VerifyReferences")

# Run specific test suite
Start-ADHealthCheck -Tests $CriticalTests
```

### Multi-Forest Support

```powershell
function Get-MultiForestHealth {
    param([string[]]$Forests)
    
    $allResults = @()
    foreach ($forest in $Forests) {
        try {
            $forestResults = Start-ADHealthCheck -Forest $forest
            $allResults += $forestResults
        }
        catch {
            Write-Warning "Failed to check forest $forest : $_"
        }
    }
    return $allResults
}
```

## References

- [DCDiag Command Reference](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc731968(v=ws.11))
- [RepAdmin Command Reference](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc770963(v=ws.11))
- [Active Directory Replication](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/replication/active-directory-replication-concepts)
- [PowerShell Active Directory Module](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)
- [AD DS Troubleshooting](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/troubleshoot/troubleshooting-active-directory-domain-services)
