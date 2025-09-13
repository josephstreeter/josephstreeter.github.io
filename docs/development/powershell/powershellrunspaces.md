---
title: PowerShell Runspaces
description: Comprehensive guide to PowerShell runspaces for parallel processing, background jobs, and advanced PowerShell programming
author: Joseph Streeter
date: 2024-01-15
tags: [powershell, runspaces, parallel-processing, threading, performance]
---

PowerShell Runspaces provide the foundation for parallel processing and advanced PowerShell execution scenarios. This guide covers runspace fundamentals, parallel processing techniques, and practical implementations for performance-critical applications.

## Runspace Fundamentals

### Understanding Runspaces

A runspace is an operating environment for PowerShell commands, similar to a PowerShell session but more lightweight and programmatically controllable. Runspaces enable:

- **Parallel Execution**: Run multiple PowerShell commands simultaneously
- **Resource Isolation**: Separate execution environments for security and stability
- **Background Processing**: Non-blocking execution of long-running tasks
- **Scalable Processing**: Handle large datasets efficiently through parallelization

### Runspace Types

```powershell
# Single Runspace (default PowerShell execution)
$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()

# Runspace Pool for multiple parallel operations
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$RunspacePool.Open()

# Initial Session State for custom environments
$ISS = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$ISS.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("MyVar", "MyValue", "Custom variable"))
$CustomRunspace = [runspacefactory]::CreateRunspace($ISS)
```

## Parallel Processing Implementation

### Basic Parallel Processing Framework

```powershell
function Invoke-ParallelProcessing
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$InputObject,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [int]$ThrottleLimit = 5,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string[]]$ImportModules = @(),
        
        [Parameter()]
        [hashtable]$ImportVariables = @{}
    )
    
    begin
    {
        # Create Initial Session State
        $ISS = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # Import specified modules
        foreach ($Module in $ImportModules)
        {
            $ISS.ImportPSModule($Module)
        }
        
        # Add variables to session state
        foreach ($VarName in $ImportVariables.Keys)
        {
            $Variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
                $VarName, 
                $ImportVariables[$VarName], 
                "Imported variable"
            )
            $ISS.Variables.Add($Variable)
        }
        
        # Create Runspace Pool
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $ISS, $Host)
        $RunspacePool.Open()
        
        $Jobs = [System.Collections.Generic.List[object]]@()
        $Results = [System.Collections.Generic.List[object]]@()
    }
    
    process
    {
        foreach ($Item in $InputObject)
        {
            # Create PowerShell instance
            $PowerShell = [powershell]::Create()
            $PowerShell.RunspacePool = $RunspacePool
            
            # Add script block and parameters
            [void]$PowerShell.AddScript($ScriptBlock)
            [void]$PowerShell.AddArgument($Item)
            
            # Add additional parameters
            foreach ($ParamName in $Parameters.Keys)
            {
                [void]$PowerShell.AddParameter($ParamName, $Parameters[$ParamName])
            }
            
            # Start async execution
            $AsyncResult = $PowerShell.BeginInvoke()
            
            $Jobs.Add([PSCustomObject]@{
                PowerShell = $PowerShell
                AsyncResult = $AsyncResult
                Input = $Item
                StartTime = Get-Date
            })
        }
    }
    
    end
    {
        try
        {
            Write-Verbose "Processing $($Jobs.Count) jobs with $ThrottleLimit concurrent runspaces"
            
            # Wait for all jobs to complete
            while ($Jobs.Count -gt 0)
            {
                $CompletedJobs = $Jobs | Where-Object { $_.AsyncResult.IsCompleted }
                
                foreach ($Job in $CompletedJobs)
                {
                    try
                    {
                        # Get results
                        $Result = $Job.PowerShell.EndInvoke($Job.AsyncResult)
                        
                        # Check for errors
                        if ($Job.PowerShell.Streams.Error.Count -gt 0)
                        {
                            $ErrorInfo = [PSCustomObject]@{
                                Input = $Job.Input
                                Result = $null
                                Error = $Job.PowerShell.Streams.Error | ForEach-Object { $_.ToString() }
                                Duration = (Get-Date) - $Job.StartTime
                                Status = "Error"
                            }
                            $Results.Add($ErrorInfo)
                        }
                        else
                        {
                            $SuccessInfo = [PSCustomObject]@{
                                Input = $Job.Input
                                Result = $Result
                                Error = $null
                                Duration = (Get-Date) - $Job.StartTime
                                Status = "Success"
                            }
                            $Results.Add($SuccessInfo)
                        }
                    }
                    catch
                    {
                        $ExceptionInfo = [PSCustomObject]@{
                            Input = $Job.Input
                            Result = $null
                            Error = $_.Exception.Message
                            Duration = (Get-Date) - $Job.StartTime
                            Status = "Exception"
                        }
                        $Results.Add($ExceptionInfo)
                    }
                    finally
                    {
                        # Cleanup
                        $Job.PowerShell.Dispose()
                        $Jobs.Remove($Job)
                    }
                }
                
                if ($Jobs.Count -gt 0)
                {
                    Start-Sleep -Milliseconds 100
                }
            }
        }
        finally
        {
            # Cleanup runspace pool
            $RunspacePool.Close()
            $RunspacePool.Dispose()
        }
        
        Write-Verbose "Parallel processing completed. $($Results.Count) results returned."
        return $Results
    }
}
```

### Advanced Network Scanner Example

```powershell
function Invoke-ParallelNetworkScan
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,
        
        [Parameter()]
        [int[]]$Port = @(22, 80, 135, 139, 443, 445, 3389, 5985, 5986),
        
        [Parameter()]
        [int]$TimeoutMs = 1000,
        
        [Parameter()]
        [int]$ThrottleLimit = 20
    )
    
    $ScanScript = {
        param($Computer, $Ports, $Timeout)
        
        $Results = [System.Collections.Generic.List[object]]@()
        
        foreach ($PortNumber in $Ports)
        {
            try
            {
                $TcpClient = New-Object System.Net.Sockets.TcpClient
                $AsyncResult = $TcpClient.BeginConnect($Computer, $PortNumber, $null, $null)
                $Connected = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)
                
                if ($Connected)
                {
                    try
                    {
                        $TcpClient.EndConnect($AsyncResult)
                        $Status = "Open"
                    }
                    catch
                    {
                        $Status = "Filtered"
                    }
                }
                else
                {
                    $Status = "Closed"
                }
                
                $TcpClient.Close()
                
                $Results.Add([PSCustomObject]@{
                    ComputerName = $Computer
                    Port = $PortNumber
                    Status = $Status
                    ResponseTime = if ($Status -eq "Open") { $Timeout } else { $null }
                })
            }
            catch
            {
                $Results.Add([PSCustomObject]@{
                    ComputerName = $Computer
                    Port = $PortNumber
                    Status = "Error"
                    ResponseTime = $null
                    Error = $_.Exception.Message
                })
            }
        }
        
        return $Results
    }
    
    # Create input objects for parallel processing
    $ScanJobs = foreach ($Computer in $ComputerName)
    {
        [PSCustomObject]@{
            Computer = $Computer
            Ports = $Port
            Timeout = $TimeoutMs
        }
    }
    
    Write-Host "Starting parallel network scan of $($ComputerName.Count) hosts..." -ForegroundColor Green
    
    $ScanResults = $ScanJobs | Invoke-ParallelProcessing -ScriptBlock $ScanScript -ThrottleLimit $ThrottleLimit
    
    # Process results
    $AllScanResults = $ScanResults | Where-Object Status -eq "Success" | ForEach-Object { $_.Result }
    $FailedScans = $ScanResults | Where-Object Status -ne "Success"
    
    # Generate summary
    $OpenPorts = $AllScanResults | Where-Object Status -eq "Open"
    $Summary = @{
        TotalHosts = $ComputerName.Count
        HostsScanned = ($AllScanResults | Group-Object ComputerName).Count
        TotalPorts = $AllScanResults.Count
        OpenPorts = $OpenPorts.Count
        ClosedPorts = ($AllScanResults | Where-Object Status -eq "Closed").Count
        FilteredPorts = ($AllScanResults | Where-Object Status -eq "Filtered").Count
        Errors = $FailedScans.Count
    }
    
    Write-Host "`nScan Summary:" -ForegroundColor Cyan
    Write-Host "Hosts Scanned: $($Summary.HostsScanned)/$($Summary.TotalHosts)" -ForegroundColor White
    Write-Host "Open Ports: $($Summary.OpenPorts)" -ForegroundColor Green
    Write-Host "Closed Ports: $($Summary.ClosedPorts)" -ForegroundColor Red
    Write-Host "Filtered Ports: $($Summary.FilteredPorts)" -ForegroundColor Yellow
    Write-Host "Scan Errors: $($Summary.Errors)" -ForegroundColor Magenta
    
    return [PSCustomObject]@{
        ScanResults = $AllScanResults
        Summary = $Summary
        Errors = $FailedScans
    }
}
```

## Advanced Runspace Patterns

### Background Job Manager

```powershell
class RunspaceJobManager
{
    [System.Collections.Generic.Dictionary[string, object]]$Jobs
    [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool
    [int]$MaxConcurrentJobs
    
    RunspaceJobManager([int]$MaxJobs)
    {
        $this.MaxConcurrentJobs = $MaxJobs
        $this.Jobs = [System.Collections.Generic.Dictionary[string, object]]::new()
        $this.InitializeRunspacePool()
    }
    
    [void]InitializeRunspacePool()
    {
        $ISS = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, $this.MaxConcurrentJobs, $ISS, $Host)
        $this.RunspacePool.Open()
    }
    
    [string]StartJob([scriptblock]$ScriptBlock, [hashtable]$Parameters, [string]$JobName)
    {
        if ([string]::IsNullOrEmpty($JobName))
        {
            $JobName = "Job_$([guid]::NewGuid().ToString().Substring(0,8))"
        }
        
        if ($this.Jobs.ContainsKey($JobName))
        {
            throw "Job with name '$JobName' already exists"
        }
        
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $this.RunspacePool
        [void]$PowerShell.AddScript($ScriptBlock)
        
        foreach ($ParamName in $Parameters.Keys)
        {
            [void]$PowerShell.AddParameter($ParamName, $Parameters[$ParamName])
        }
        
        $AsyncResult = $PowerShell.BeginInvoke()
        
        $this.Jobs[$JobName] = [PSCustomObject]@{
            Name = $JobName
            PowerShell = $PowerShell
            AsyncResult = $AsyncResult
            StartTime = Get-Date
            Status = "Running"
            Result = $null
            Error = $null
        }
        
        return $JobName
    }
    
    [object]GetJobResult([string]$JobName)
    {
        if (-not $this.Jobs.ContainsKey($JobName))
        {
            throw "Job '$JobName' not found"
        }
        
        $Job = $this.Jobs[$JobName]
        
        if ($Job.Status -eq "Running")
        {
            if ($Job.AsyncResult.IsCompleted)
            {
                try
                {
                    $Job.Result = $Job.PowerShell.EndInvoke($Job.AsyncResult)
                    $Job.Status = "Completed"
                    
                    if ($Job.PowerShell.Streams.Error.Count -gt 0)
                    {
                        $Job.Error = $Job.PowerShell.Streams.Error | ForEach-Object { $_.ToString() }
                        $Job.Status = "CompletedWithErrors"
                    }
                }
                catch
                {
                    $Job.Error = $_.Exception.Message
                    $Job.Status = "Failed"
                }
                finally
                {
                    $Job.EndTime = Get-Date
                    $Job.Duration = $Job.EndTime - $Job.StartTime
                }
            }
        }
        
        return $Job
    }
    
    [object[]]GetAllJobs()
    {
        $JobList = [System.Collections.Generic.List[object]]@()
        
        foreach ($JobName in $this.Jobs.Keys)
        {
            $JobList.Add($this.GetJobResult($JobName))
        }
        
        return $JobList.ToArray()
    }
    
    [object[]]GetCompletedJobs()
    {
        return $this.GetAllJobs() | Where-Object { $_.Status -in @("Completed", "CompletedWithErrors", "Failed") }
    }
    
    [object[]]GetRunningJobs()
    {
        return $this.GetAllJobs() | Where-Object { $_.Status -eq "Running" }
    }
    
    [void]WaitForJob([string]$JobName, [int]$TimeoutSeconds = 300)
    {
        $Job = $this.Jobs[$JobName]
        $TimeoutTime = (Get-Date).AddSeconds($TimeoutSeconds)
        
        while ($Job.AsyncResult.IsCompleted -eq $false -and (Get-Date) -lt $TimeoutTime)
        {
            Start-Sleep -Milliseconds 500
        }
        
        if ((Get-Date) -ge $TimeoutTime)
        {
            throw "Job '$JobName' timed out after $TimeoutSeconds seconds"
        }
    }
    
    [void]WaitForAllJobs([int]$TimeoutSeconds = 300)
    {
        $TimeoutTime = (Get-Date).AddSeconds($TimeoutSeconds)
        
        do
        {
            $RunningJobs = $this.GetRunningJobs()
            if ($RunningJobs.Count -eq 0) { break }
            
            Start-Sleep -Milliseconds 1000
            
        } while ((Get-Date) -lt $TimeoutTime)
        
        $StillRunning = $this.GetRunningJobs()
        if ($StillRunning.Count -gt 0)
        {
            throw "Timeout waiting for $($StillRunning.Count) jobs to complete"
        }
    }
    
    [void]RemoveJob([string]$JobName)
    {
        if ($this.Jobs.ContainsKey($JobName))
        {
            $Job = $this.Jobs[$JobName]
            
            if ($Job.Status -eq "Running")
            {
                $Job.PowerShell.Stop()
            }
            
            $Job.PowerShell.Dispose()
            $this.Jobs.Remove($JobName)
        }
    }
    
    [void]Dispose()
    {
        # Clean up all jobs
        foreach ($JobName in $this.Jobs.Keys.Clone())
        {
            $this.RemoveJob($JobName)
        }
        
        # Close and dispose runspace pool
        if ($this.RunspacePool)
        {
            $this.RunspacePool.Close()
            $this.RunspacePool.Dispose()
        }
    }
}

# Usage Example
function Test-RunspaceJobManager
{
    $JobManager = [RunspaceJobManager]::new(5)
    
    try
    {
        # Start multiple background jobs
        $Job1 = $JobManager.StartJob({
            param($Seconds)
            Start-Sleep $Seconds
            return "Job completed after $Seconds seconds"
        }, @{ Seconds = 5 }, "LongRunningJob")
        
        $Job2 = $JobManager.StartJob({
            Get-Process | Where-Object CPU -gt 100 | Select-Object Name, CPU
        }, @{}, "ProcessJob")
        
        $Job3 = $JobManager.StartJob({
            param($Path)
            Get-ChildItem $Path -Recurse | Measure-Object Length -Sum
        }, @{ Path = "C:\Windows" }, "FileSystemJob")
        
        # Monitor jobs
        Write-Host "Started $($JobManager.GetRunningJobs().Count) jobs" -ForegroundColor Green
        
        # Wait for specific job
        $JobManager.WaitForJob("ProcessJob", 30)
        $ProcessResult = $JobManager.GetJobResult("ProcessJob")
        Write-Host "Process job completed: $($ProcessResult.Result.Count) high-CPU processes found" -ForegroundColor Cyan
        
        # Wait for all jobs
        Write-Host "Waiting for all jobs to complete..." -ForegroundColor Yellow
        $JobManager.WaitForAllJobs(60)
        
        # Get all results
        $AllJobs = $JobManager.GetCompletedJobs()
        foreach ($Job in $AllJobs)
        {
            Write-Host "Job '$($Job.Name)' - Status: $($Job.Status) - Duration: $($Job.Duration.TotalSeconds)s" -ForegroundColor White
        }
    }
    finally
    {
        $JobManager.Dispose()
    }
}
```

## Performance Optimization

### Memory-Efficient Processing

```powershell
function Invoke-OptimizedParallelProcessing
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ProcessingScript,
        
        [Parameter()]
        [int]$BatchSize = 100,
        
        [Parameter()]
        [int]$MaxConcurrentBatches = 4,
        
        [Parameter()]
        [string]$TempPath = $env:TEMP
    )
    
    try
    {
        Write-Host "Processing $($InputData.Count) items in batches of $BatchSize..." -ForegroundColor Green
        
        # Split data into batches
        $Batches = [System.Collections.Generic.List[object[]]]@()
        for ($i = 0; $i -lt $InputData.Count; $i += $BatchSize)
        {
            $BatchEnd = [Math]::Min($i + $BatchSize - 1, $InputData.Count - 1)
            $Batch = $InputData[$i..$BatchEnd]
            $Batches.Add($Batch)
        }
        
        Write-Host "Created $($Batches.Count) batches for processing" -ForegroundColor Cyan
        
        # Process batches in parallel
        $BatchResults = [System.Collections.Generic.List[object]]@()
        $JobManager = [RunspaceJobManager]::new($MaxConcurrentBatches)
        
        try
        {
            # Start batch processing jobs
            for ($BatchIndex = 0; $BatchIndex -lt $Batches.Count; $BatchIndex++)
            {
                $JobName = "Batch_$BatchIndex"
                $BatchScript = {
                    param($BatchData, $Script, $BatchId)
                    
                    $Results = [System.Collections.Generic.List[object]]@()
                    
                    for ($ItemIndex = 0; $ItemIndex -lt $BatchData.Count; $ItemIndex++)
                    {
                        try
                        {
                            $Item = $BatchData[$ItemIndex]
                            $Result = & $Script $Item
                            
                            $Results.Add([PSCustomObject]@{
                                BatchId = $BatchId
                                ItemIndex = $ItemIndex
                                Input = $Item
                                Result = $Result
                                Status = "Success"
                                Error = $null
                            })
                        }
                        catch
                        {
                            $Results.Add([PSCustomObject]@{
                                BatchId = $BatchId
                                ItemIndex = $ItemIndex
                                Input = $Item
                                Result = $null
                                Status = "Error"
                                Error = $_.Exception.Message
                            })
                        }
                        
                        # Memory cleanup
                        if ($ItemIndex % 10 -eq 0)
                        {
                            [System.GC]::Collect()
                        }
                    }
                    
                    return $Results.ToArray()
                }
                
                $Parameters = @{
                    BatchData = $Batches[$BatchIndex]
                    Script = $ProcessingScript
                    BatchId = $BatchIndex
                }
                
                $JobManager.StartJob($BatchScript, $Parameters, $JobName)
            }
            
            # Wait for batches to complete and collect results
            $CompletedBatches = 0
            while ($CompletedBatches -lt $Batches.Count)
            {
                $CompletedJobs = $JobManager.GetCompletedJobs()
                
                foreach ($Job in $CompletedJobs)
                {
                    if ($Job.Name -match "Batch_(\d+)" -and $Job.Status -eq "Completed")
                    {
                        $BatchResults.AddRange($Job.Result)
                        $JobManager.RemoveJob($Job.Name)
                        $CompletedBatches++
                        
                        Write-Progress -Activity "Processing Batches" -Status "Completed batch $CompletedBatches of $($Batches.Count)" -PercentComplete (($CompletedBatches / $Batches.Count) * 100)
                    }
                }
                
                Start-Sleep -Milliseconds 500
            }
        }
        finally
        {
            $JobManager.Dispose()
        }
        
        Write-Progress -Activity "Processing Batches" -Completed
        
        # Generate processing summary
        $Summary = @{
            TotalItems = $InputData.Count
            ProcessedItems = $BatchResults.Count
            SuccessfulItems = ($BatchResults | Where-Object Status -eq "Success").Count
            ErrorItems = ($BatchResults | Where-Object Status -eq "Error").Count
            Batches = $Batches.Count
            BatchSize = $BatchSize
            SuccessRate = [math]::Round((($BatchResults | Where-Object Status -eq "Success").Count / $BatchResults.Count) * 100, 2)
        }
        
        Write-Host "`nProcessing Summary:" -ForegroundColor Cyan
        Write-Host "Total Items: $($Summary.TotalItems)" -ForegroundColor White
        Write-Host "Successful: $($Summary.SuccessfulItems)" -ForegroundColor Green
        Write-Host "Errors: $($Summary.ErrorItems)" -ForegroundColor Red
        Write-Host "Success Rate: $($Summary.SuccessRate)%" -ForegroundColor Yellow
        
        return [PSCustomObject]@{
            Results = $BatchResults
            Summary = $Summary
        }
    }
    catch
    {
        Write-Error "Optimized parallel processing failed: $($_.Exception.Message)"
        throw
    }
}

# Usage Examples
Write-Host @"

POWERSHELL RUNSPACES EXAMPLES

1. Basic Parallel Processing:
   $Results = 1..100 | Invoke-ParallelProcessing -ScriptBlock { param($num) $num * $num } -ThrottleLimit 10

2. Network Scanning:
   $ScanResults = Invoke-ParallelNetworkScan -ComputerName @("server1", "server2", "server3") -Port @(80, 443, 3389)

3. Background Job Management:
   $JobManager = [RunspaceJobManager]::new(5)
   $JobId = $JobManager.StartJob({ Get-Process }, @{}, "ProcessJob")

4. Optimized Batch Processing:
   $Data = 1..10000
   $Results = Invoke-OptimizedParallelProcessing -InputData $Data -ProcessingScript { param($x) Start-Sleep 1; $x * 2 }

These examples demonstrate PowerShell runspace capabilities for:
- High-performance parallel processing
- Background job management
- Memory-efficient batch processing
- Network operations at scale
- Advanced threading patterns

Runspaces provide significant performance improvements for:
- Large dataset processing
- Network operations
- File system operations
- API calls and web requests
- CPU-intensive calculations

"@ -ForegroundColor Green
```
