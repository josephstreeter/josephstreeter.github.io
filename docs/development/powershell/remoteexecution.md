---
title: PowerShell Remote Execution
description: Comprehensive guide to PowerShell remoting, remote sessions, and distributed PowerShell execution across enterprise environments
author: Joseph Streeter
date: 2024-01-15
tags: [powershell, remoting, winrm, distributed-computing, enterprise-administration]
---

PowerShell remote execution enables administrators to manage multiple systems efficiently and securely from a central location. This guide covers PowerShell remoting fundamentals, advanced remote execution patterns, and enterprise-scale management scenarios.

## PowerShell Remoting Fundamentals

### WinRM Configuration

PowerShell remoting relies on Windows Remote Management (WinRM) service. Proper configuration is essential for secure and reliable remote operations.

```powershell
# Enable PowerShell Remoting (run as Administrator)
Enable-PSRemoting -Force

# Configure WinRM for enterprise environments
winrm quickconfig

# Set WinRM service to automatic startup
Set-Service -Name WinRM -StartupType Automatic

# Configure WinRM for HTTPS (recommended for production)
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{
    Hostname="YourServerName"
    CertificateThumbprint="YourCertificateThumbprint"
}

# Configure authentication methods
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Kerberos -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Negotiate -Value $true

# Configure trusted hosts (for workgroup environments)
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "*.contoso.com"
```

### Session Management

```powershell
<#
.SYNOPSIS
    Comprehensive PowerShell session management functions
.DESCRIPTION
    Provides functions for creating, managing, and monitoring PowerShell sessions
    across multiple remote systems with enterprise-grade error handling
#>

function New-PSSessionPool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter()]
        [string]$ConfigurationName = "Microsoft.PowerShell",
        
        [Parameter()]
        [int]$ThrottleLimit = 32,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30,
        
        [Parameter()]
        [switch]$UseSSL
    )
    
    try
    {
        Write-Verbose "Creating PowerShell session pool for $($ComputerName.Count) computers"
        
        $SessionOptions = New-PSSessionOption -OperationTimeout ([timespan]::FromSeconds($TimeoutSeconds))
        
        $SessionParams = @{
            ComputerName = $ComputerName
            ConfigurationName = $ConfigurationName
            SessionOption = $SessionOptions
            ThrottleLimit = $ThrottleLimit
            ErrorAction = 'SilentlyContinue'
        }
        
        if ($Credential)
        {
            $SessionParams.Credential = $Credential
        }
        
        if ($UseSSL)
        {
            $SessionParams.UseSSL = $true
            $SessionParams.Port = 5986
        }
        
        # Create sessions with progress tracking
        $Sessions = [System.Collections.Generic.List[object]]@()
        $FailedConnections = [System.Collections.Generic.List[object]]@()
        
        Write-Progress -Activity "Creating PowerShell Sessions" -Status "Connecting..." -PercentComplete 0
        
        $CreatedSessions = New-PSSession @SessionParams
        
        foreach ($Computer in $ComputerName)
        {
            $Session = $CreatedSessions | Where-Object ComputerName -eq $Computer
            
            if ($Session)
            {
                $Sessions.Add([PSCustomObject]@{
                    ComputerName = $Computer
                    Session = $Session
                    Status = "Connected"
                    ConnectionTime = Get-Date
                    Error = $null
                })
            }
            else
            {
                # Get detailed error information
                $ErrorDetails = $Error | Where-Object { $_.TargetObject -eq $Computer } | Select-Object -First 1
                
                $FailedConnections.Add([PSCustomObject]@{
                    ComputerName = $Computer
                    Session = $null
                    Status = "Failed"
                    ConnectionTime = Get-Date
                    Error = if ($ErrorDetails) { $ErrorDetails.Exception.Message } else { "Unknown connection error" }
                })
            }
        }
        
        Write-Progress -Activity "Creating PowerShell Sessions" -Completed
        
        $Result = [PSCustomObject]@{
            SuccessfulSessions = $Sessions
            FailedConnections = $FailedConnections
            TotalRequested = $ComputerName.Count
            SuccessCount = $Sessions.Count
            FailureCount = $FailedConnections.Count
            SuccessRate = [math]::Round(($Sessions.Count / $ComputerName.Count) * 100, 2)
        }
        
        Write-Host "Session Creation Summary:" -ForegroundColor Cyan
        Write-Host "Successful: $($Result.SuccessCount)/$($Result.TotalRequested) ($($Result.SuccessRate)%)" -ForegroundColor Green
        
        if ($Result.FailureCount -gt 0)
        {
            Write-Host "Failed Connections:" -ForegroundColor Red
            $FailedConnections | ForEach-Object {
                Write-Host "  $($_.ComputerName): $($_.Error)" -ForegroundColor Yellow
            }
        }
        
        return $Result
    }
    catch
    {
        Write-Error "Failed to create PowerShell session pool: $($_.Exception.Message)"
        throw
    }
}

function Invoke-RemoteCommandWithRetry
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [hashtable]$ArgumentList = @{},
        
        [Parameter()]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [int]$RetryDelaySeconds = 5,
        
        [Parameter()]
        [switch]$AsJob
    )
    
    $Results = [System.Collections.Generic.List[object]]@()
    
    foreach ($PSSession in $Session)
    {
        $Attempts = 0
        $Success = $false
        $LastError = $null
        
        do
        {
            $Attempts++
            
            try
            {
                Write-Verbose "Executing command on $($PSSession.ComputerName) (Attempt $Attempts)"
                
                $InvokeParams = @{
                    Session = $PSSession
                    ScriptBlock = $ScriptBlock
                    ErrorAction = 'Stop'
                }
                
                if ($ArgumentList.Count -gt 0)
                {
                    $InvokeParams.ArgumentList = $ArgumentList.Values
                }
                
                if ($AsJob)
                {
                    $InvokeParams.AsJob = $true
                    $InvokeParams.JobName = "RemoteJob_$($PSSession.ComputerName)_$(Get-Date -Format 'HHmmss')"
                }
                
                $CommandResult = Invoke-Command @InvokeParams
                
                $Results.Add([PSCustomObject]@{
                    ComputerName = $PSSession.ComputerName
                    Result = $CommandResult
                    Status = "Success"
                    Attempts = $Attempts
                    ExecutionTime = Get-Date
                    Error = $null
                })
                
                $Success = $true
            }
            catch
            {
                $LastError = $_.Exception.Message
                Write-Warning "Command failed on $($PSSession.ComputerName) (Attempt $Attempts): $LastError"
                
                if ($Attempts -lt $MaxRetries)
                {
                    Write-Verbose "Retrying in $RetryDelaySeconds seconds..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
            }
            
        } while (-not $Success -and $Attempts -lt $MaxRetries)
        
        if (-not $Success)
        {
            $Results.Add([PSCustomObject]@{
                ComputerName = $PSSession.ComputerName
                Result = $null
                Status = "Failed"
                Attempts = $Attempts
                ExecutionTime = Get-Date
                Error = $LastError
            })
        }
    }
    
    return $Results
}
```

## Advanced Remote Execution Patterns

### Parallel Remote Processing

```powershell
function Invoke-ParallelRemoteExecution
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter()]
        [int]$ThrottleLimit = 20,
        
        [Parameter()]
        [int]$TimeoutMinutes = 10,
        
        [Parameter()]
        [string[]]$ModulesToImport = @(),
        
        [Parameter()]
        [hashtable]$VariablesToImport = @{}
    )
    
    try
    {
        Write-Host "Starting parallel remote execution on $($ComputerName.Count) computers..." -ForegroundColor Green
        
        # Create session pool
        $SessionPoolParams = @{
            ComputerName = $ComputerName
            ThrottleLimit = $ThrottleLimit
        }
        
        if ($Credential)
        {
            $SessionPoolParams.Credential = $Credential
        }
        
        $SessionPool = New-PSSessionPool @SessionPoolParams
        $SuccessfulSessions = $SessionPool.SuccessfulSessions
        
        if ($SuccessfulSessions.Count -eq 0)
        {
            throw "No successful sessions created. Cannot proceed with remote execution."
        }
        
        Write-Host "Created $($SuccessfulSessions.Count) successful sessions" -ForegroundColor Cyan
        
        # Import modules and variables if specified
        if ($ModulesToImport.Count -gt 0)
        {
            Write-Host "Importing modules: $($ModulesToImport -join ', ')" -ForegroundColor Yellow
            
            $ModuleScript = {
                param($Modules)
                foreach ($Module in $Modules)
                {
                    try
                    {
                        Import-Module $Module -Force -ErrorAction Stop
                    }
                    catch
                    {
                        Write-Warning "Failed to import module $Module`: $($_.Exception.Message)"
                    }
                }
            }
            
            $ModuleResults = Invoke-RemoteCommandWithRetry -Session ($SuccessfulSessions.Session) -ScriptBlock $ModuleScript -ArgumentList @{ Modules = $ModulesToImport }
        }
        
        if ($VariablesToImport.Count -gt 0)
        {
            Write-Host "Importing variables: $($VariablesToImport.Keys -join ', ')" -ForegroundColor Yellow
            
            foreach ($VarName in $VariablesToImport.Keys)
            {
                $SuccessfulSessions.Session | ForEach-Object {
                    Set-Variable -Name $VarName -Value $VariablesToImport[$VarName] -Scope Global
                }
            }
        }
        
        # Execute main script block
        Write-Host "Executing script block on remote systems..." -ForegroundColor Yellow
        
        $StartTime = Get-Date
        $ExecutionResults = Invoke-RemoteCommandWithRetry -Session ($SuccessfulSessions.Session) -ScriptBlock $ScriptBlock -ArgumentList $Parameters
        $EndTime = Get-Date
        $TotalDuration = $EndTime - $StartTime
        
        # Process results
        $SuccessfulExecutions = $ExecutionResults | Where-Object Status -eq "Success"
        $FailedExecutions = $ExecutionResults | Where-Object Status -eq "Failed"
        
        # Generate summary
        $Summary = [PSCustomObject]@{
            TotalComputers = $ComputerName.Count
            SessionsCreated = $SuccessfulSessions.Count
            SessionsFailed = $SessionPool.FailedConnections.Count
            ExecutionsSuccessful = $SuccessfulExecutions.Count
            ExecutionsFailed = $FailedExecutions.Count
            OverallSuccessRate = [math]::Round(($SuccessfulExecutions.Count / $ComputerName.Count) * 100, 2)
            TotalExecutionTime = $TotalDuration
            AverageExecutionTime = if ($SuccessfulExecutions.Count -gt 0) { 
                [timespan]::FromMilliseconds($TotalDuration.TotalMilliseconds / $SuccessfulExecutions.Count) 
            } else { 
                [timespan]::Zero 
            }
        }
        
        Write-Host "`nExecution Summary:" -ForegroundColor Cyan
        Write-Host "Total Duration: $($Summary.TotalExecutionTime.ToString('hh\:mm\:ss'))" -ForegroundColor White
        Write-Host "Overall Success Rate: $($Summary.OverallSuccessRate)%" -ForegroundColor $(
            if ($Summary.OverallSuccessRate -ge 90) { "Green" }
            elseif ($Summary.OverallSuccessRate -ge 75) { "Yellow" } 
            else { "Red" }
        )
        Write-Host "Successful Executions: $($Summary.ExecutionsSuccessful)" -ForegroundColor Green
        Write-Host "Failed Executions: $($Summary.ExecutionsFailed)" -ForegroundColor Red
        
        if ($FailedExecutions.Count -gt 0)
        {
            Write-Host "`nFailed Executions:" -ForegroundColor Red
            $FailedExecutions | ForEach-Object {
                Write-Host "  $($_.ComputerName): $($_.Error)" -ForegroundColor Yellow
            }
        }
        
        # Cleanup sessions
        try
        {
            $SuccessfulSessions.Session | Remove-PSSession -ErrorAction SilentlyContinue
            Write-Verbose "Cleaned up $($SuccessfulSessions.Count) PowerShell sessions"
        }
        catch
        {
            Write-Warning "Some sessions may not have been cleaned up properly: $($_.Exception.Message)"
        }
        
        return [PSCustomObject]@{
            Results = $ExecutionResults
            Summary = $Summary
            FailedConnections = $SessionPool.FailedConnections
        }
    }
    catch
    {
        Write-Error "Parallel remote execution failed: $($_.Exception.Message)"
        throw
    }
}
```

### Enterprise System Management

```powershell
function Invoke-EnterpriseSystemScan
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter()]
        [string]$OutputPath = "C:\Reports",
        
        [Parameter()]
        [switch]$IncludeServices,
        
        [Parameter()]
        [switch]$IncludeEventLogs,
        
        [Parameter()]
        [switch]$IncludePerformanceCounters
    )
    
    $ScanScript = {
        param($IncludeServices, $IncludeEventLogs, $IncludePerformanceCounters)
        
        $SystemInfo = @{}
        
        try
        {
            # Basic system information
            $OS = Get-CimInstance -ClassName Win32_OperatingSystem
            $Computer = Get-CimInstance -ClassName Win32_ComputerSystem
            $BIOS = Get-CimInstance -ClassName Win32_BIOS
            $Processor = Get-CimInstance -ClassName Win32_Processor
            $Memory = Get-CimInstance -ClassName Win32_PhysicalMemory
            
            $SystemInfo.BasicInfo = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                OperatingSystem = $OS.Caption
                Version = $OS.Version
                BuildNumber = $OS.BuildNumber
                Architecture = $OS.OSArchitecture
                InstallDate = $OS.InstallDate
                LastBootUpTime = $OS.LastBootUpTime
                TotalMemoryGB = [math]::Round(($Memory | Measure-Object Capacity -Sum).Sum / 1GB, 2)
                ProcessorName = $Processor[0].Name
                ProcessorCores = ($Processor | Measure-Object NumberOfCores -Sum).Sum
                ProcessorLogicalCores = ($Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum
                Manufacturer = $Computer.Manufacturer
                Model = $Computer.Model
                BIOSVersion = $BIOS.SMBIOSBIOSVersion
                SerialNumber = $BIOS.SerialNumber
                Domain = $Computer.Domain
                Workgroup = $Computer.Workgroup
            }
            
            # Disk information
            $Disks = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object DriveType -eq 3
            $SystemInfo.DiskInfo = $Disks | ForEach-Object {
                [PSCustomObject]@{
                    Drive = $_.DeviceID
                    Label = $_.VolumeName
                    SizeGB = [math]::Round($_.Size / 1GB, 2)
                    FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
                    PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                }
            }
            
            # Network adapters
            $NetworkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object IPEnabled -eq $true
            $SystemInfo.NetworkInfo = $NetworkAdapters | ForEach-Object {
                [PSCustomObject]@{
                    Description = $_.Description
                    IPAddress = $_.IPAddress -join ', '
                    SubnetMask = $_.IPSubnet -join ', '
                    DefaultGateway = $_.DefaultIPGateway -join ', '
                    DNSServers = $_.DNSServerSearchOrder -join ', '
                    DHCPEnabled = $_.DHCPEnabled
                    MACAddress = $_.MACAddress
                }
            }
            
            # Installed software
            $InstalledSoftware = Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, Vendor, InstallDate
            $SystemInfo.SoftwareInfo = $InstalledSoftware | Sort-Object Name
            
            # Windows Updates
            try
            {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
                $SystemInfo.PendingUpdates = $SearchResult.Updates | ForEach-Object {
                    [PSCustomObject]@{
                        Title = $_.Title
                        Description = $_.Description
                        SizeKB = [math]::Round($_.MaxDownloadSize / 1024, 2)
                        IsDownloaded = $_.IsDownloaded
                        IsMandatory = $_.IsMandatory
                    }
                }
            }
            catch
            {
                $SystemInfo.PendingUpdates = "Unable to retrieve: $($_.Exception.Message)"
            }
            
            # Services (if requested)
            if ($IncludeServices)
            {
                $Services = Get-Service | Select-Object Name, DisplayName, Status, StartType
                $SystemInfo.ServiceInfo = $Services | Sort-Object Name
            }
            
            # Event logs (if requested)
            if ($IncludeEventLogs)
            {
                $RecentErrors = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 50 -ErrorAction SilentlyContinue
                $SystemInfo.RecentErrors = $RecentErrors | ForEach-Object {
                    [PSCustomObject]@{
                        TimeCreated = $_.TimeCreated
                        LogName = $_.LogName
                        LevelDisplayName = $_.LevelDisplayName
                        Id = $_.Id
                        ProviderName = $_.ProviderName
                        Message = $_.Message.Substring(0, [math]::Min(200, $_.Message.Length))
                    }
                }
            }
            
            # Performance counters (if requested)
            if ($IncludePerformanceCounters)
            {
                $SystemInfo.PerformanceCounters = [PSCustomObject]@{
                    CPUPercent = (Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 5 | 
                        Select-Object -ExpandProperty CounterSamples | 
                        Measure-Object CookedValue -Average).Average
                    MemoryUsedPercent = [math]::Round(((Get-Counter -Counter "\Memory\% Committed Bytes In Use").CounterSamples.CookedValue), 2)
                    DiskQueueLength = (Get-Counter -Counter "\PhysicalDisk(_Total)\Current Disk Queue Length").CounterSamples.CookedValue
                    NetworkBytesPerSec = (Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" | 
                        Select-Object -ExpandProperty CounterSamples | 
                        Measure-Object CookedValue -Sum).Sum
                }
            }
            
            return $SystemInfo
        }
        catch
        {
            return [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Error = $_.Exception.Message
                ScanTime = Get-Date
            }
        }
    }
    
    try
    {
        Write-Host "Starting enterprise system scan..." -ForegroundColor Green
        
        $ScanParams = @{
            ComputerName = $ComputerName
            ScriptBlock = $ScanScript
            Parameters = @{
                IncludeServices = $IncludeServices.IsPresent
                IncludeEventLogs = $IncludeEventLogs.IsPresent
                IncludePerformanceCounters = $IncludePerformanceCounters.IsPresent
            }
            ThrottleLimit = 15
        }
        
        if ($Credential)
        {
            $ScanParams.Credential = $Credential
        }
        
        $ScanResults = Invoke-ParallelRemoteExecution @ScanParams
        
        # Process and export results
        if (-not (Test-Path $OutputPath))
        {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        $ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $SuccessfulResults = $ScanResults.Results | Where-Object Status -eq "Success"
        
        # Export basic system information
        $BasicInfo = $SuccessfulResults | ForEach-Object { $_.Result.BasicInfo }
        $BasicInfoPath = Join-Path $OutputPath "SystemInfo_Basic_$ReportDate.csv"
        $BasicInfo | Export-Csv -Path $BasicInfoPath -NoTypeInformation
        
        # Export disk information
        $DiskInfo = $SuccessfulResults | ForEach-Object { 
            $ComputerName = $_.ComputerName
            $_.Result.DiskInfo | ForEach-Object { 
                $_ | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName -PassThru 
            }
        }
        $DiskInfoPath = Join-Path $OutputPath "SystemInfo_Disks_$ReportDate.csv"
        $DiskInfo | Export-Csv -Path $DiskInfoPath -NoTypeInformation
        
        # Export network information
        $NetworkInfo = $SuccessfulResults | ForEach-Object { 
            $ComputerName = $_.ComputerName
            $_.Result.NetworkInfo | ForEach-Object { 
                $_ | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName -PassThru 
            }
        }
        $NetworkInfoPath = Join-Path $OutputPath "SystemInfo_Network_$ReportDate.csv"
        $NetworkInfo | Export-Csv -Path $NetworkInfoPath -NoTypeInformation
        
        # Generate summary report
        $SummaryReport = [PSCustomObject]@{
            ScanDate = Get-Date
            TotalSystemsScanned = $ComputerName.Count
            SuccessfulScans = $SuccessfulResults.Count
            FailedScans = ($ScanResults.Results | Where-Object Status -eq "Failed").Count
            OperatingSystems = $BasicInfo | Group-Object OperatingSystem | ForEach-Object { "$($_.Name): $($_.Count)" }
            TotalMemoryGB = ($BasicInfo | Measure-Object TotalMemoryGB -Sum).Sum
            TotalDiskSpaceGB = ($DiskInfo | Measure-Object SizeGB -Sum).Sum
            TotalFreeDiskSpaceGB = ($DiskInfo | Measure-Object FreeSpaceGB -Sum).Sum
            AverageDiskUtilization = [math]::Round((($DiskInfo | ForEach-Object { 100 - $_.PercentFree } | Measure-Object -Average).Average), 2)
        }
        
        $SummaryPath = Join-Path $OutputPath "SystemScan_Summary_$ReportDate.json"
        $SummaryReport | ConvertTo-Json -Depth 2 | Out-File -FilePath $SummaryPath
        
        Write-Host "`nEnterprise System Scan Complete!" -ForegroundColor Green
        Write-Host "Successful Scans: $($SummaryReport.SuccessfulScans)/$($SummaryReport.TotalSystemsScanned)" -ForegroundColor Cyan
        Write-Host "Reports saved to: $OutputPath" -ForegroundColor Cyan
        Write-Host "  - Basic Info: $BasicInfoPath" -ForegroundColor White
        Write-Host "  - Disk Info: $DiskInfoPath" -ForegroundColor White
        Write-Host "  - Network Info: $NetworkInfoPath" -ForegroundColor White
        Write-Host "  - Summary: $SummaryPath" -ForegroundColor White
        
        return $ScanResults
    }
    catch
    {
        Write-Error "Enterprise system scan failed: $($_.Exception.Message)"
        throw
    }
}

# Usage Examples
Write-Host @"

POWERSHELL REMOTE EXECUTION EXAMPLES

1. Create Session Pool:
   $SessionPool = New-PSSessionPool -ComputerName @("server1", "server2", "server3") -Credential $Cred

2. Parallel Remote Execution:
   $Results = Invoke-ParallelRemoteExecution -ComputerName @("server1", "server2") -ScriptBlock { Get-Process | Where-Object CPU -gt 100 }

3. Enterprise System Scan:
   $ScanResults = Invoke-EnterpriseSystemScan -ComputerName (Get-Content "C:\servers.txt") -IncludeServices -IncludeEventLogs

4. Remote Command with Retry:
   $CommandResults = Invoke-RemoteCommandWithRetry -Session $Sessions -ScriptBlock { Restart-Service "Spooler" } -MaxRetries 3

These examples demonstrate PowerShell remote execution capabilities for:
- Large-scale system administration
- Enterprise environment management
- Parallel processing across multiple systems
- Reliable command execution with error handling
- Comprehensive system inventory and monitoring

PowerShell remoting enables efficient management of:
- Windows Server environments
- Domain controllers and member servers
- Workstation deployments
- Hybrid cloud infrastructures
- DevOps automation workflows

"@ -ForegroundColor Green
