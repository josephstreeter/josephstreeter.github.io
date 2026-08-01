---
title: "Performance Optimization"
description: "Boot analysis, startup ordering, resource control, and tuning systemd service performance"
author: "josephstreeter"
tags: ["systemd", "linux", "performance", "resource control", "boot"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Performance Optimization

SystemD provides numerous features for optimizing service performance, resource management, and system efficiency.

### Resource Management and Limits

#### CPU Control

```ini
[Service]
# CPU scheduling
CPUWeight=100              # Default: 100, Range: 1-10000
CPUQuota=50%              # Limit to 50% of one CPU core
CPUAffinity=0 1 2         # Bind to specific CPU cores

# Nice and priority
Nice=10                   # Process priority (-20 to 19)
IOSchedulingClass=2       # I/O scheduling class (0-3)
IOSchedulingPriority=4    # I/O priority (0-7)
```

#### Memory Management

```ini
[Service]
# Memory limits
MemoryLimit=2G            # Hard memory limit
MemoryMax=2G             # Maximum memory (cgroups v2)
MemoryHigh=1.5G          # Soft memory limit
MemorySwapMax=1G         # Maximum swap usage

# Memory accounting
MemoryAccounting=true     # Enable memory accounting
```

#### I/O Control

```ini
[Service]
# I/O bandwidth limits
IOReadBandwidthMax=/dev/sda 50M    # Read bandwidth limit
IOWriteBandwidthMax=/dev/sda 20M   # Write bandwidth limit

# I/O operations limits
IOReadIOPSMax=/dev/sda 1000        # Read IOPS limit
IOWriteIOPSMax=/dev/sda 500        # Write IOPS limit

# I/O weight
IOWeight=100              # I/O scheduling weight (1-10000)
```

### Advanced Performance Configuration

#### High-Performance Web Server

```ini
# /etc/systemd/system/high-perf-web.service
[Unit]
Description=High-Performance Web Server
After=network.target

[Service]
Type=forking
User=nginx
Group=nginx
PIDFile=/var/run/nginx.pid
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID

# Performance optimization
Nice=-5                   # Higher priority
IOSchedulingClass=1       # Real-time I/O scheduling
IOSchedulingPriority=2    # High I/O priority

# CPU optimization
CPUWeight=500            # Higher CPU weight
CPUAffinity=0-3         # Use first 4 CPU cores

# Memory optimization
MemoryMax=4G            # Maximum memory
MemoryHigh=3G           # Soft limit
MemoryAccounting=true

# I/O optimization
IOWeight=500            # Higher I/O weight
IOReadBandwidthMax=/dev/sda 200M
IOWriteBandwidthMax=/dev/sda 100M

# File descriptor limits
LimitNOFILE=65536       # Increase file descriptor limit
LimitNPROC=8192         # Process limit

# Security (basic)
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

#### Database Performance Tuning

```ini
# /etc/systemd/system/high-perf-db.service
[Unit]
Description=High-Performance Database
After=network.target

[Service]
Type=notify
User=postgres
Group=postgres
Environment=PGDATA=/var/lib/postgresql/data

# Execution
ExecStart=/usr/local/bin/postgres -D $PGDATA
ExecReload=/bin/kill -HUP $MAINPID

# Performance tuning
Nice=-10                # Highest priority for database
IOSchedulingClass=1     # Real-time I/O
IOSchedulingPriority=1  # Highest I/O priority
OOMScoreAdjust=-800     # Protect from OOM killer

# CPU allocation
CPUWeight=1000          # Maximum CPU weight
CPUAffinity=4-7         # Dedicated CPU cores

# Memory configuration
MemoryMax=16G           # Large memory allocation
MemoryHigh=14G          # Soft limit
MemoryAccounting=true
MemorySwapMax=0         # Disable swap for database

# I/O optimization
IOWeight=1000           # Maximum I/O weight
IOReadBandwidthMax=/dev/nvme0n1 1G    # High-speed NVMe
IOWriteBandwidthMax=/dev/nvme0n1 500M
IOReadIOPSMax=/dev/nvme0n1 10000
IOWriteIOPSMax=/dev/nvme0n1 5000

# File system limits
LimitNOFILE=131072      # Large file descriptor limit
LimitLOCKS=65536        # File locking limit
LimitMEMLOCK=infinity   # Memory locking

# Process limits
LimitNPROC=16384        # Process limit
TasksMax=32768          # Task limit

[Install]
WantedBy=multi-user.target
```

### Performance Monitoring Scripts

#### Resource Usage Monitor

```powershell
function Monitor-SystemdServicePerformance
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ServiceNames,
        [int]$IntervalSeconds = 5,
        [int]$DurationMinutes = 10,
        [switch]$ExportData,
        [string]$OutputPath = "./performance_data_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    )
    
    Write-Host "Starting performance monitoring for $($ServiceNames.Count) services" -ForegroundColor Cyan
    Write-Host "Monitoring interval: $IntervalSeconds seconds" -ForegroundColor Yellow
    Write-Host "Total duration: $DurationMinutes minutes" -ForegroundColor Yellow
    Write-Host "Services: $($ServiceNames -join ', ')" -ForegroundColor White
    
    $performanceData = @()
    $totalIterations = ($DurationMinutes * 60) / $IntervalSeconds
    $iteration = 0
    
    try
    {
        while ($iteration -lt $totalIterations)
        {
            $timestamp = Get-Date
            Write-Host "[$($timestamp.ToString('HH:mm:ss'))] Collecting performance data..." -ForegroundColor Gray
            
            foreach ($serviceName in $ServiceNames)
            {
                try
                {
                    # Get service properties
                    $properties = @{}
                    $showOutput = & systemctl show $serviceName --property=MainPID,ActiveState,CPUUsageNSec,MemoryCurrent,TasksCurrent,IPIngressBytes,IPEgressBytes
                    
                    foreach ($line in $showOutput)
                    {
                        if ($line -match "^([^=]+)=(.*)$")
                        {
                            $properties[$matches[1]] = $matches[2]
                        }
                    }
                    
                    # Get process-level metrics if service is running
                    $processMetrics = $null
                    if ($properties.MainPID -and $properties.MainPID -ne "0")
                    {
                        try
                        {
                            $processInfo = Get-Process -Id $properties.MainPID -ErrorAction Stop
                            $processMetrics = @{
                                CPU = $processInfo.CPU
                                WorkingSet = $processInfo.WorkingSet64
                                VirtualMemory = $processInfo.VirtualMemorySize64
                                Threads = $processInfo.Threads.Count
                                HandleCount = $processInfo.HandleCount
                            }
                        }
                        catch
                        {
                            # Process might have exited
                        }
                    }
                    
                    $performanceEntry = [PSCustomObject]@{
                        Timestamp = $timestamp
                        ServiceName = $serviceName
                        ActiveState = $properties.ActiveState
                        MainPID = $properties.MainPID
                        CPUUsageNSec = $properties.CPUUsageNSec
                        MemoryCurrent = $properties.MemoryCurrent
                        TasksCurrent = $properties.TasksCurrent
                        IPIngressBytes = $properties.IPIngressBytes
                        IPEgressBytes = $properties.IPEgressBytes
                        ProcessCPU = if ($processMetrics) { $processMetrics.CPU } else { $null }
                        ProcessMemory = if ($processMetrics) { $processMetrics.WorkingSet } else { $null }
                        ProcessThreads = if ($processMetrics) { $processMetrics.Threads } else { $null }
                    }
                    
                    $performanceData += $performanceEntry
                    
                    # Display current metrics
                    $memoryMB = if ($properties.MemoryCurrent -and $properties.MemoryCurrent -ne "[not set]") 
                    { 
                        [math]::Round([int64]$properties.MemoryCurrent / 1MB, 2) 
                    } else { "N/A" }
                    
                    Write-Host "  $serviceName - Memory: ${memoryMB}MB, Tasks: $($properties.TasksCurrent), State: $($properties.ActiveState)" -ForegroundColor White
                }
                catch
                {
                    Write-Warning "Failed to collect metrics for $serviceName : $($_.Exception.Message)"
                }
            }
            
            $iteration++
            $progress = [math]::Round(($iteration / $totalIterations) * 100, 1)
            Write-Host "Progress: $progress% ($iteration/$totalIterations)" -ForegroundColor Cyan
            
            if ($iteration -lt $totalIterations)
            {
                Start-Sleep -Seconds $IntervalSeconds
            }
        }
        
        # Calculate summary statistics
        Write-Host "`nPerformance Monitoring Summary:" -ForegroundColor Green
        
        foreach ($serviceName in $ServiceNames)
        {
            $serviceData = $performanceData | Where-Object { $_.ServiceName -eq $serviceName }
            if ($serviceData)
            {
                $memoryData = $serviceData | Where-Object { $_.MemoryCurrent -and $_.MemoryCurrent -ne "[not set]" } | ForEach-Object { [int64]$_.MemoryCurrent }
                $taskData = $serviceData | Where-Object { $_.TasksCurrent -and $_.TasksCurrent -ne "[not set]" } | ForEach-Object { [int]$_.TasksCurrent }
                
                Write-Host "`n  $serviceName Statistics:" -ForegroundColor Yellow
                
                if ($memoryData)
                {
                    $avgMemory = ($memoryData | Measure-Object -Average).Average / 1MB
                    $maxMemory = ($memoryData | Measure-Object -Maximum).Maximum / 1MB
                    $minMemory = ($memoryData | Measure-Object -Minimum).Minimum / 1MB
                    Write-Host "    Memory - Avg: $([math]::Round($avgMemory, 2))MB, Max: $([math]::Round($maxMemory, 2))MB, Min: $([math]::Round($minMemory, 2))MB" -ForegroundColor White
                }
                
                if ($taskData)
                {
                    $avgTasks = ($taskData | Measure-Object -Average).Average
                    $maxTasks = ($taskData | Measure-Object -Maximum).Maximum
                    Write-Host "    Tasks - Avg: $([math]::Round($avgTasks, 1)), Max: $maxTasks" -ForegroundColor White
                }
            }
        }
        
        if ($ExportData)
        {
            $performanceData | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "`nPerformance data exported to: $OutputPath" -ForegroundColor Cyan
        }
        
        return $performanceData
    }
    catch
    {
        Write-Error "Performance monitoring failed: $($_.Exception.Message)"
        return $performanceData
    }
}
```

## Related Topics

- [systemd Overview](index.md) — architecture and essential commands
- [Unit Files and Service Configuration](unit-files.md)
- [Timer Units and Scheduling](timers.md)
- [Logging and Monitoring](logging.md)
- [Security and Hardening](security.md)
- [Performance Optimization](performance.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Enterprise Best Practices](best-practices.md)
