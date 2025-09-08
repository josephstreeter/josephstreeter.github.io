---
title: Windows Security
description: Comprehensive guide to Windows security hardening, monitoring, and best practices
author: Joseph Streeter
date: 2024-01-15
tags: [windows, security, hardening, monitoring, compliance]
---

Windows security encompasses a comprehensive set of tools, technologies, and practices designed to protect Windows systems from threats and ensure data integrity. This guide covers essential security configurations, monitoring strategies, and best practices.

## Windows Security Architecture

### Security Components

#### Windows Defender

Built-in antivirus and anti-malware protection.

```powershell
# Check Windows Defender status
Get-MpComputerStatus

# Enable real-time protection
Set-MpPreference -DisableRealtimeMonitoring $false

# Update definitions
Update-MpSignature

# Run quick scan
Start-MpScan -ScanType QuickScan
```

#### Windows Firewall

Network traffic filtering and access control.

```powershell
# Check firewall status
Get-NetFirewallProfile

# Enable firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Create firewall rule
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Port 22 -Protocol TCP -Action Allow
```

#### User Account Control (UAC)

Privilege escalation protection mechanism.

```powershell
# Check UAC status
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA

# Configure UAC levels via registry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 2
```

## Security Hardening

### System Configuration

#### Disable Unnecessary Services

```powershell
# List all services
Get-Service

# Disable vulnerable services
$ServicesToDisable = @(
    "Fax",
    "WSearch",
    "RemoteRegistry",
    "Spooler"
)

foreach ($Service in $ServicesToDisable) {
    Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
}
```

#### Registry Security Settings

```powershell
# Disable SMBv1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name SMB1 -Type DWORD -Value 0

# Enable LSA protection
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL -Type DWORD -Value 1

# Disable LLMNR
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name EnableMulticast -Type DWORD -Value 0
```

#### Network Security

```powershell
# Disable NetBIOS over TCP/IP
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2)  # 2 = Disable NetBIOS over TCP/IP
}

# Configure network location
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
```

### Password Policies

#### Local Security Policy

```powershell
# Configure password policy via Group Policy
secedit /export /cfg C:\secpol.cfg

# Edit configuration
$secpol = Get-Content C:\secpol.cfg
$secpol = $secpol -replace "MinimumPasswordLength = .*", "MinimumPasswordLength = 12"
$secpol = $secpol -replace "MaximumPasswordAge = .*", "MaximumPasswordAge = 90"
$secpol = $secpol -replace "PasswordComplexity = .*", "PasswordComplexity = 1"
$secpol | Set-Content C:\secpol.cfg

# Apply configuration
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg
```

#### Account Lockout Policy

```powershell
# Configure account lockout
net accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30
```

## Security Monitoring

### Event Log Analysis

#### Security Event Monitoring

```powershell
# Monitor failed logon attempts
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 50

# Monitor successful logons
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 20

# Monitor privilege escalation
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4672} -MaxEvents 10

# Monitor process creation
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4688} -MaxEvents 25
```

#### System Event Analysis

```powershell
# Check system events
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2,3} -MaxEvents 50

# Monitor service failures
Get-WinEvent -FilterHashtable @{LogName='System'; ID=7034} -MaxEvents 20

# Check application crashes
Get-WinEvent -FilterHashtable @{LogName='Application'; Level=1,2} -MaxEvents 30
```

### Performance Monitoring

#### Resource Usage

```powershell
# Monitor CPU usage
Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 12

# Monitor memory usage
Get-Counter "\Memory\Available MBytes" -SampleInterval 5 -MaxSamples 12

# Monitor disk usage
Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -SampleInterval 5 -MaxSamples 12

# Monitor network activity
Get-Counter "\Network Interface(*)\Bytes Total/sec" -SampleInterval 5 -MaxSamples 12
```

#### Process Monitoring

```powershell
# List processes by CPU usage
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# List processes by memory usage
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10

# Monitor specific process
Get-Process -Name "notepad" | Format-Table Name, CPU, WorkingSet
```

## Threat Detection

### Malware Detection

#### Windows Defender Advanced

```powershell
# Enable cloud protection
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendSafeSamples

# Configure scan settings
Set-MpPreference -ScanScheduleDay Everyday
Set-MpPreference -ScanScheduleTime 02:00:00

# Enable network protection
Set-MpPreference -EnableNetworkProtection Enabled
```

#### Suspicious Process Detection

```powershell
# Function to detect suspicious processes
function Get-SuspiciousProcesses {
    $suspiciousProcesses = @()
    
    # Check for processes running from temp directories
    $processes = Get-Process | Where-Object {$_.Path -like "*\Temp\*" -or $_.Path -like "*\AppData\*"}
    foreach ($process in $processes) {
        $suspiciousProcesses += [PSCustomObject]@{
            Name = $process.Name
            Path = $process.Path
            PID = $process.Id
            Reason = "Running from temporary directory"
        }
    }
    
    # Check for unsigned processes
    $processes = Get-Process | Where-Object {$_.Path -ne $null}
    foreach ($process in $processes) {
        try {
            $signature = Get-AuthenticodeSignature -FilePath $process.Path
            if ($signature.Status -ne "Valid") {
                $suspiciousProcesses += [PSCustomObject]@{
                    Name = $process.Name
                    Path = $process.Path
                    PID = $process.Id
                    Reason = "Unsigned or invalid signature"
                }
            }
        }
        catch {
            # Ignore errors for system processes
        }
    }
    
    return $suspiciousProcesses
}

# Run suspicious process detection
Get-SuspiciousProcesses | Format-Table -AutoSize
```

### Network Security Monitoring

#### Connection Monitoring

```powershell
# Monitor network connections
Get-NetTCPConnection | Where-Object {$_.State -eq "Established"} | 
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess

# Check for suspicious connections
Get-NetTCPConnection | Where-Object {
    $_.RemoteAddress -notlike "127.*" -and 
    $_.RemoteAddress -notlike "192.168.*" -and 
    $_.RemoteAddress -notlike "10.*" -and
    $_.State -eq "Established"
} | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort
```

#### DNS Monitoring

```powershell
# Monitor DNS queries
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-DNS-Client/Operational'} -MaxEvents 50 |
    Select-Object TimeCreated, Id, LevelDisplayName, Message
```

## Compliance and Auditing

### Security Baselines

#### CIS Controls Implementation

```powershell
# Implement CIS Critical Security Controls
function Invoke-CISControls {
    # Control 1: Inventory of Authorized and Unauthorized Devices
    Get-WmiObject -Class Win32_SystemEnclosure | Select-Object Manufacturer, Model, SerialNumber
    
    # Control 2: Inventory of Authorized and Unauthorized Software
    Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor
    
    # Control 3: Continuous Vulnerability Management
    Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20
    
    # Control 4: Controlled Use of Administrative Privileges
    Get-LocalGroupMember -Group "Administrators"
    
    # Control 5: Secure Configuration for Hardware and Software
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
}

Invoke-CISControls
```

#### NIST Framework Alignment

```powershell
# NIST Cybersecurity Framework implementation
function Invoke-NISTFramework {
    Write-Host "=== NIST CSF Implementation ===" -ForegroundColor Green
    
    # Identify
    Write-Host "IDENTIFY: Asset Management" -ForegroundColor Yellow
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
    
    # Protect
    Write-Host "PROTECT: Access Control" -ForegroundColor Yellow
    Get-LocalUser | Where-Object {$_.Enabled -eq $true} | Select-Object Name, LastLogon, PasswordRequired
    
    # Detect
    Write-Host "DETECT: Security Monitoring" -ForegroundColor Yellow
    Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 5 | 
        Select-Object TimeCreated, Id, LevelDisplayName
    
    # Respond
    Write-Host "RESPOND: Incident Response" -ForegroundColor Yellow
    Get-Service | Where-Object {$_.Status -ne "Running" -and $_.StartType -eq "Automatic"} |
        Select-Object Name, Status, StartType
    
    # Recover
    Write-Host "RECOVER: Backup Status" -ForegroundColor Yellow
    Get-WmiObject -Class Win32_ShadowCopy | Select-Object InstallDate, VolumeName
}

Invoke-NISTFramework
```

### Audit Configuration

#### Security Auditing

```powershell
# Configure security auditing
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable

# Check current audit policy
auditpol /get /category:*
```

#### File System Auditing

```powershell
# Enable file system auditing on sensitive directories
$paths = @("C:\Windows\System32", "C:\Users", "C:\Program Files")

foreach ($path in $paths) {
    $acl = Get-Acl $path
    $accessRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        "Everyone",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Success,Failure"
    )
    $acl.SetAuditRule($accessRule)
    Set-Acl $path $acl
}
```

## Incident Response

### Initial Response

#### System Isolation

```powershell
# Isolate compromised system
function Invoke-SystemIsolation {
    Write-Host "Isolating system from network..." -ForegroundColor Red
    
    # Disable network adapters
    Get-NetAdapter | Disable-NetAdapter -Confirm:$false
    
    # Stop suspicious processes
    $suspiciousProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*temp*" -or 
        $_.ProcessName -like "*tmp*" -or
        $_.CPU -gt 50
    }
    
    $suspiciousProcesses | Stop-Process -Force -Confirm:$false
    
    Write-Host "System isolated. Manual investigation required." -ForegroundColor Yellow
}
```

#### Evidence Collection

```powershell
# Collect incident evidence
function Collect-IncidentEvidence {
    param([string]$OutputPath = "C:\IncidentResponse")
    
    New-Item -Path $OutputPath -ItemType Directory -Force
    
    # System information
    Get-ComputerInfo | Out-File "$OutputPath\SystemInfo.txt"
    
    # Running processes
    Get-Process | Select-Object Name, Id, CPU, WorkingSet, Path | 
        Export-Csv "$OutputPath\Processes.csv" -NoTypeInformation
    
    # Network connections
    Get-NetTCPConnection | Export-Csv "$OutputPath\NetworkConnections.csv" -NoTypeInformation
    
    # Event logs
    Get-WinEvent -FilterHashtable @{LogName='Security'} -MaxEvents 1000 |
        Export-Csv "$OutputPath\SecurityEvents.csv" -NoTypeInformation
    
    # Registry snapshots
    reg export HKLM\SOFTWARE "$OutputPath\Registry_Software.reg"
    reg export HKLM\SYSTEM "$OutputPath\Registry_System.reg"
    
    Write-Host "Evidence collected in $OutputPath" -ForegroundColor Green
}

Collect-IncidentEvidence
```

## Security Tools and Utilities

### Built-in Security Tools

#### Windows Security Center

```powershell
# Check Windows Security Center status
Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct
Get-WmiObject -Namespace "root\SecurityCenter2" -Class FirewallProduct
Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiSpywareProduct
```

#### Cipher and BitLocker

```powershell
# Check BitLocker status
Get-BitLockerVolume

# Enable BitLocker on system drive
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector

# Cipher utility for secure deletion
cipher /w:C:\DeletedFiles
```

### Third-Party Integration

#### Sysmon Configuration

```xml
<!-- Sysmon configuration for enhanced logging -->
<Sysmon schemaversion="4.22">
  <EventFiltering>
    <!-- Process creation -->
    <ProcessCreate onmatch="include">
      <Image condition="contains">powershell</Image>
      <Image condition="contains">cmd</Image>
      <Image condition="contains">wscript</Image>
      <Image condition="contains">cscript</Image>
    </ProcessCreate>
    
    <!-- Network connections -->
    <NetworkConnect onmatch="include">
      <DestinationPort condition="is">443</DestinationPort>
      <DestinationPort condition="is">80</DestinationPort>
    </NetworkConnect>
    
    <!-- File creation -->
    <FileCreate onmatch="include">
      <TargetFilename condition="contains">Downloads</TargetFilename>
      <TargetFilename condition="contains">Temp</TargetFilename>
    </FileCreate>
  </EventFiltering>
</Sysmon>
```

## Automation and Scripting

### Security Automation Scripts

#### Daily Security Check

```powershell
# Daily security health check
function Invoke-DailySecurityCheck {
    $report = @{}
    
    # Check Windows Defender status
    $defenderStatus = Get-MpComputerStatus
    $report.DefenderEnabled = $defenderStatus.RealTimeProtectionEnabled
    $report.DefenderUpToDate = $defenderStatus.AntivirusSignatureLastUpdated -gt (Get-Date).AddDays(-1)
    
    # Check firewall status
    $firewallProfiles = Get-NetFirewallProfile
    $report.FirewallEnabled = ($firewallProfiles | Where-Object {$_.Enabled -eq $false}).Count -eq 0
    
    # Check for failed logons
    $failedLogons = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 10 -ErrorAction SilentlyContinue
    $report.FailedLogonAttempts = $failedLogons.Count
    
    # Check for critical updates
    $updates = Get-HotFix | Where-Object {$_.InstalledOn -gt (Get-Date).AddDays(-7)}
    $report.RecentUpdates = $updates.Count
    
    # Generate report
    Write-Host "=== Daily Security Report ===" -ForegroundColor Green
    $report | Format-Table -AutoSize
    
    # Send alerts if issues found
    if (-not $report.DefenderEnabled -or -not $report.FirewallEnabled) {
        Write-Host "ALERT: Critical security controls disabled!" -ForegroundColor Red
    }
    
    if ($report.FailedLogonAttempts -gt 5) {
        Write-Host "WARNING: Multiple failed logon attempts detected!" -ForegroundColor Yellow
    }
}

Invoke-DailySecurityCheck
```

#### Automated Hardening

```powershell
# Automated Windows hardening script
function Invoke-WindowsHardening {
    Write-Host "Starting Windows security hardening..." -ForegroundColor Green
    
    # Disable unnecessary services
    $servicesToDisable = @("Fax", "WSearch", "RemoteRegistry")
    foreach ($service in $servicesToDisable) {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $service" -ForegroundColor Yellow
    }
    
    # Configure firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "Enabled Windows Firewall for all profiles" -ForegroundColor Yellow
    
    # Enable Windows Defender
    Set-MpPreference -DisableRealtimeMonitoring $false
    Write-Host "Enabled Windows Defender real-time protection" -ForegroundColor Yellow
    
    # Configure UAC
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 2
    Write-Host "Configured UAC for secure desktop prompts" -ForegroundColor Yellow
    
    # Disable SMBv1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name SMB1 -Type DWORD -Value 0
    Write-Host "Disabled SMBv1 protocol" -ForegroundColor Yellow
    
    Write-Host "Windows hardening completed!" -ForegroundColor Green
}

Invoke-WindowsHardening
```

## Best Practices

### Security Configuration

1. **Keep Systems Updated**
   - Enable automatic updates
   - Regular patch management
   - Security baseline compliance

2. **Access Control**
   - Principle of least privilege
   - Regular access reviews
   - Strong authentication

3. **Network Security**
   - Firewall configuration
   - Network segmentation
   - Monitoring and logging

4. **Data Protection**
   - Encryption at rest and in transit
   - Regular backups
   - Data loss prevention

### Monitoring Strategy

1. **Continuous Monitoring**
   - Real-time threat detection
   - Automated alerting
   - Regular security assessments

2. **Log Management**
   - Centralized logging
   - Log retention policies
   - Regular log analysis

3. **Incident Response**
   - Documented procedures
   - Regular drills
   - Lessons learned integration

## Related Topics

- [Active Directory Security](~/docs/services/activedirectory/index.md)
- [Group Policy Security](~/docs/services/grouppolicy/index.md)
- [PowerShell Security](~/docs/development/powershell/index.md)
- [Network Security](~/docs/security/networking/index.md)
- [Infrastructure Monitoring](~/docs/infrastructure/monitoring/index.md)
