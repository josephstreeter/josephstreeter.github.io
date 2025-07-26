---
title: Tips and Tricks"
description: "Collection of practical PowerShell tips, tricks, and advanced techniques to improve productivity and solve common challenges"
tags: ["powershell", "tips", "tricks", "productivity", "advanced", "techniques"]
category: "development"
difficulty: "intermediate-to-advanced"
last_updated: "2025-07-21"
---

This comprehensive collection of PowerShell tips and tricks covers practical techniques, productivity enhancements, and solutions to common challenges encountered in PowerShell development and administration. These techniques have been tested in real-world scenarios and can significantly improve your PowerShell workflow.

## Setting Default Parameter Values

Use the $PSDefaultParameterValues preference variable to set custom default values for cmdlets and advanced functions that you frequently use. The parameters and the default values are stored as a hash table.

This feature is useful when you must specify the same parameter value nearly every time you use a cmdlet or when a particular parameter value is difficult to remember, such as an certificate thumbprint or Azure Subscription GUID.

Set a parameter default value:

```powershell
$PSDefaultParameterValues=@{“<CmdletName>:<ParameterName>”=”<DefaultValue>”}
```

Set several parameter default values:

```powershell
$PSDefaultParameterValues=@{
 “<CmdletName>:<ParameterName1>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName2>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName3>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName4>”=”<DefaultValue>”
}
```

Set a parameter default value based on conditions using a script block:

```powershell
$PSDefaultParameterValues=@{“<CmdletName>:<ParameterName>”={<ScriptBlock>}}
```

Use the Add() method to add preferences to an existing hash table.

```powershell
$PSDefaultParameterValues.Add({“<CmdletName>:<ParameterName>”,”<DefaultValue>”})
```

Use the Remove() method to remove preferences from an existing hash table.

```powershell
$PSDefaultParameterValues.Remove(“<CmdletName>:<ParameterName>”)
```

Use the Clear() method to remove all of the preferences from the hash table.

```powershell
$PSDefaultParameterValues.Clear()
```

Example: Setting Default Parameters for Connect-Exchange Online:

```powershell
$PSDefaultParameterValues = @{
    "Connect-ExchangeOnline:UserPrincipalName" = "username@domainname.com"
    "Connect-ExchangeOnline:ShowBanner" = $false
    "Connect-ExchangeOnline:ShowProgress" = $false
}
```

[about_Parameters_Default_Values](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-7.4)
>The $PSDefaultParameterValues preference variable lets you specify custom default values for any cmdlet or advanced function. Cmdlets and advanced functions use the custom default value unless you specify another value in the command.
>
>The authors of cmdlets and advanced functions set standard default values for their parameters. Typically, the standard default values are useful, but they might not be appropriate for all environments.
>
>This feature is especially useful when you must specify the same alternate parameter value nearly every time you use the command or when a particular parameter value is difficult to remember, such as an email server name or project GUID.
>
>If the desired default value varies predictably, you can specify a script block that provides different default values for a parameter under different conditions.

```powershell
$PSDefaultParameterValues = @{"CmdletName:ParameterName" = "DefaultValue"}
$PSDefaultParameterValues = @{"CmdletName:ParameterName" = {<ScriptBlock>}}
$PSDefaultParameterValues["Disabled"] = $true | $false
```

## Environment and Path Management

### PowerShell Paths with Folder Redirection

When Group Policy configures folder redirection for profile directories, including "Documents" where the default `$PSModulePath` and `$Profile` are located, performance issues can occur when using PowerShell remotely over VPN. This happens because PowerShell takes time to search `$PSModulePath` to auto-load modules from network locations.

**Solution:** Redirect PowerShell paths to local directories for better performance.

```powershell
# Check current module path
Write-Host "Current PSModulePath:" -ForegroundColor Yellow
$env:PSModulePath -split ';' | ForEach-Object { Write-Host "  $_" }

# Update module path to local directory
$NetworkPath = "\\host.domain.com\Home\$env:USERNAME\Documents\PowerShell\Modules"
$LocalPath = "$env:USERPROFILE\Documents\PowerShell\Modules"

if ($env:PSModulePath -like "*$NetworkPath*")
{
    Write-Host "Updating PSModulePath from network to local path..." -ForegroundColor Green
    $env:PSModulePath = $env:PSModulePath.Replace($NetworkPath, $LocalPath)
}

# Function to fix profile path permanently
function Set-LocalPowerShellProfile
{
    [CmdletBinding()]
    param()
    
    $NetworkPattern = "\\\\[^\\]+\\.*"
    $LocalModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules"
    
    if ($env:PSModulePath -match $NetworkPattern)
    {
        Write-Host "Updating module path..." -ForegroundColor Green
        $env:PSModulePath = $env:PSModulePath -replace $NetworkPattern, $LocalModulePath
        
        Write-Host "PSModulePath updated to: $LocalModulePath" -ForegroundColor Green
    }
    
    $ProfilePath = $profile.CurrentUserCurrentHost
    
    if ($ProfilePath -like "\\*")
    {
        Write-Warning "Profile is on network path: $ProfilePath"
        Write-Host "Updating registry to use local Documents folder..." -ForegroundColor Yellow
        
        try
        {
            $ProcessName = (Get-Process -Id $PID).ProcessName
            $RegistryCommand = "& New-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' Personal -Value '%USERPROFILE%\Documents' -Type ExpandString -Force"
            
            if ($ProcessName -eq "pwsh")
            {
                pwsh -NoProfile -Command $RegistryCommand
            }
            else
            {
                powershell -NoProfile -Command $RegistryCommand
            }
            
            Write-Host "Restart command: $ProcessName" -ForegroundColor Yellow
            Write-Host "Registry updated. Please restart PowerShell for changes to take effect." -ForegroundColor Green
        }
        catch
        {
            Write-Error "Failed to update registry: $($_.Exception.Message)"
        }
    }
}

# Call the function
Set-LocalPowerShellProfile
```

### Environment Variable Management

**Setting temporary environment variables:**

```powershell
$env:API_KEY = "your-secret-key"
$env:DEBUG = "true"
```

**Setting persistent environment variables:**

```powershell
# Set for current user
[Environment]::SetEnvironmentVariable("API_KEY", "your-secret-key", "User")

# Set for all users (requires admin)
[Environment]::SetEnvironmentVariable("GLOBAL_SETTING", "value", "Machine")

# Set for current process only
[Environment]::SetEnvironmentVariable("TEMP_VAR", "value", "Process")
```

**Safely modifying PATH variable:**

```powershell
function Add-ToPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Directory,
        
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )
    
    if (-not (Test-Path $Directory))
    {
        Write-Warning "Directory does not exist: $Directory"
        return
    }
    
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", $Scope)
    
    if ($CurrentPath -split ';' -notcontains $Directory)
    {
        $NewPath = "$CurrentPath;$Directory"
        [Environment]::SetEnvironmentVariable("PATH", $NewPath, $Scope)
        Write-Host "Added to PATH: $Directory" -ForegroundColor Green
    }
    else
    {
        Write-Host "Directory already in PATH: $Directory" -ForegroundColor Yellow
    }
}

# Usage
Add-ToPath -Directory "C:\Tools\MyApp" -Scope User
```

---

## Dynamic PSCustomObject Creation

This section demonstrates creating custom objects dynamically from various data sources, which is a common requirement in PowerShell development.

**Important Performance Note:** Avoid using `+=` operator for arrays as it creates a new array each time, which is inefficient for large datasets.

```powershell
# Efficient approach using a list
$PSObjectList = [System.Collections.Generic.List[PSCustomObject]]@()

foreach ($Object in $Results)
{
    $CustomObject = [PSCustomObject]@{}
    
    foreach ($Property in $Object.Properties.PropertyNames)
    {
        $Value = $Object.Properties.Item($Property)
        
        # Handle array values - take first element or entire array based on count
        if ($Value -is [Array] -and $Value.Count -eq 1)
        {
            $CustomObject | Add-Member -MemberType NoteProperty -Name $Property -Value $Value[0] -Force
        }
        else
        {
            $CustomObject | Add-Member -MemberType NoteProperty -Name $Property -Value $Value -Force
        }
    }
    
    $PSObjectList.Add($CustomObject)
}

# Convert to array if needed
$PSObject = $PSObjectList.ToArray()
```

---

## Performance Optimization

### Collection Performance Tips

**Use Generic Lists Instead of Arrays for Dynamic Collections:**

```powershell
# Slow - creates new array each time
$SlowArray = @()
1..1000 | ForEach-Object { $SlowArray += $_ }

# Fast - uses efficient list structure
$FastList = [System.Collections.Generic.List[int]]@()
1..1000 | ForEach-Object { $FastList.Add($_) }

# Fastest - use pipeline when possible
$FastestResult = 1..1000 | ForEach-Object { $_ }
```

**Optimize Where-Object Usage:**

```powershell
# Slower - pipeline filtering
Get-Process | Where-Object { $_.Name -eq "notepad" }

# Faster - parameter filtering when available
Get-Process -Name "notepad"

# For complex filtering, use scriptblock optimization
Get-Process | Where-Object Name -eq "notepad"  # Faster than { $_.Name -eq "notepad" }
```

### String Building Optimization

```powershell
# Slow for many concatenations
$Result = ""
1..1000 | ForEach-Object { $Result += "Line $_`n" }

# Fast - use StringBuilder for many operations
$StringBuilder = [System.Text.StringBuilder]::new()
1..1000 | ForEach-Object { $StringBuilder.AppendLine("Line $_") | Out-Null }
$Result = $StringBuilder.ToString()

# Alternative - use -join for simple cases
$Result = (1..1000 | ForEach-Object { "Line $_" }) -join "`n"
```

---

## Error Handling Best Practices

**Use Structured Error Handling:**

```powershell
function Get-SafeUserInformation
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
    )
    
    try
    {
        $User = Get-ADUser $UserName -ErrorAction Stop
        Write-Output $User
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Warning "User '$UserName' not found in Active Directory"
        return $null
    }
    catch [System.Security.Authentication.AuthenticationException]
    {
        Write-Error "Authentication failed - check your credentials"
        throw
    }
    catch
    {
        Write-Error "Unexpected error retrieving user '$UserName': $($_.Exception.Message)"
        throw
    }
}
```

**Advanced Error Handling with Finally:**

```powershell
function Invoke-WithCleanup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [scriptblock]$CleanupScript
    )
    
    try
    {
        & $ScriptBlock
    }
    catch
    {
        Write-Error "Operation failed: $($_.Exception.Message)"
        throw
    }
    finally
    {
        Write-Verbose "Executing cleanup operations..."
        & $CleanupScript
    }
}

# Usage
Invoke-WithCleanup -ScriptBlock {
    # Main operation
    $Connection = Connect-Database
    Get-DatabaseData -Connection $Connection
} -CleanupScript {
    # Cleanup operations
    if ($Connection) { $Connection.Close() }
}
```

---

## Advanced Function Development

### Function Template with Best Practices

```powershell
function Get-EnhancedSystemInfo
{
    <#
    .SYNOPSIS
        Retrieves comprehensive system information from local or remote computers.
    
    .DESCRIPTION
        This function gathers detailed system information including hardware, 
        operating system, and performance data. Supports pipeline input and 
        parallel processing for multiple computers.
    
    .PARAMETER ComputerName
        One or more computer names to query. Accepts pipeline input.
    
    .PARAMETER Credential
        Credentials to use for remote connections.
    
    .PARAMETER IncludePerformance
        Include performance counters in the output.
    
    .EXAMPLE
        Get-EnhancedSystemInfo -ComputerName "Server01"
        
        Retrieves system information from Server01.
    
    .EXAMPLE
        "Server01", "Server02" | Get-EnhancedSystemInfo -IncludePerformance
        
        Retrieves system information with performance data from multiple servers.
    
    .NOTES
        Requires WinRM to be enabled on target computers for remote queries.
        
        Author: Your Name
        Version: 1.0
        Last Modified: 2025-07-21
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("CN", "MachineName")]
        [string[]]$ComputerName,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [switch]$IncludePerformance
    )
    
    begin
    {
        Write-Verbose "Starting system information collection..."
        $Results = [System.Collections.Generic.List[PSCustomObject]]@()
    }
    
    process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Processing computer: $Computer"
            
            try
            {
                $SystemInfo = [PSCustomObject]@{
                    ComputerName = $Computer
                    OperatingSystem = $null
                    TotalMemoryGB = $null
                    ProcessorCount = $null
                    LastBootTime = $null
                    ErrorMessage = $null
                }
                
                # Build scriptblock for remote execution
                $ScriptBlock = {
                    $OS = Get-WmiObject -Class Win32_OperatingSystem
                    $CS = Get-WmiObject -Class Win32_ComputerSystem
                    
                    [PSCustomObject]@{
                        OperatingSystem = $OS.Caption
                        TotalMemoryGB = [Math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
                        ProcessorCount = $CS.NumberOfProcessors
                        LastBootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
                    }
                }
                
                # Execute locally or remotely
                if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost")
                {
                    $Result = & $ScriptBlock
                }
                else
                {
                    $InvokeParams = @{
                        ComputerName = $Computer
                        ScriptBlock = $ScriptBlock
                        ErrorAction = "Stop"
                    }
                    
                    if ($Credential)
                    {
                        $InvokeParams.Credential = $Credential
                    }
                    
                    $Result = Invoke-Command @InvokeParams
                }
                
                # Update system info object
                $SystemInfo.OperatingSystem = $Result.OperatingSystem
                $SystemInfo.TotalMemoryGB = $Result.TotalMemoryGB
                $SystemInfo.ProcessorCount = $Result.ProcessorCount
                $SystemInfo.LastBootTime = $Result.LastBootTime
                
                $Results.Add($SystemInfo)
            }
            catch
            {
                Write-Warning "Failed to retrieve information from $Computer`: $($_.Exception.Message)"
                
                $SystemInfo.ErrorMessage = $_.Exception.Message
                $Results.Add($SystemInfo)
            }
        }
    }
    
    end
    {
        Write-Verbose "System information collection completed. Processed $($Results.Count) computers."
        return $Results
    }
}
```

---

## Pipeline Techniques

### Advanced Pipeline Processing

```powershell
# Efficient pipeline processing with ForEach-Object -Parallel (PowerShell 7+)
1..100 | ForEach-Object -Parallel {
    Start-Sleep -Seconds 1
    "Processed item $_"
} -ThrottleLimit 10

# Custom pipeline functions
function ConvertTo-Base64
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputString
    )
    
    process
    {
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
        $EncodedString = [System.Convert]::ToBase64String($Bytes)
        
        [PSCustomObject]@{
            Original = $InputString
            Base64 = $EncodedString
            Length = $EncodedString.Length
        }
    }
}

# Usage
"Hello", "World", "PowerShell" | ConvertTo-Base64
```

---

## References and Additional Resources

- [PowerShell Best Practices and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- [about_Parameters_Default_Values](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-7.4)
- [about_Advanced_Functions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced?view=powershell-7.4)
- [about_Error_Handling](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally?view=powershell-7.4)
- [PowerShell Performance Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations?view=powershell-7.4)
