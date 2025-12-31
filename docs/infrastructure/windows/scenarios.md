---
title: Windows Server End-to-End Scenarios
description: Real-world deployment scenarios with step-by-step instructions for common Windows Server implementations
author: Joseph Streeter
ms.author: jstreeter
ms.date: 2024-12-30
ms.topic: tutorial
ms.service: windows-server
keywords: Windows Server scenarios, deployment guide, real-world examples, step-by-step, tutorials
uid: docs.infrastructure.windows.scenarios
---

This guide provides complete, real-world deployment scenarios for common Windows Server implementations. Each scenario includes prerequisites, step-by-step instructions, security considerations, and troubleshooting tips.

## Scenario 1: Deploying a Secure File Server

### Overview

Deploy a Windows Server as a secure file server with:

- SMB encryption enabled
- Access-based enumeration
- File screening (FSRM)
- Audit logging
- DFS for high availability

**Time to complete**: 60-90 minutes  
**Difficulty**: Intermediate

### Prerequisites

- Windows Server 2019 or later
- Static IP address configured
- Domain membership
- Administrative credentials

### Architecture Diagram

```mermaid
graph TB
    subgraph Users[\"User Workstations\"]
        PC1[Workstation 1]
        PC2[Workstation 2]
        PC3[Workstation 3]
    end
    
    subgraph FileServer[\"File Server Infrastructure\"]
        FS1[File Server 1<br/>Primary]
        FS2[File Server 2<br/>Replica]
        DFS[DFS Namespace<br/>\\\\contoso.com\\shares]
    end
    
    subgraph Storage[\"Backend Storage\"]
        Vol1[D: Department Shares]
        Vol2[E: User Home Drives]
        Vol3[F: Public Folders]
    end
    
    subgraph Security[\"Security Components\"]
        FSRM[File Server Resource Manager]
        Audit[Audit Logging]
        Encrypt[SMB Encryption]
    end
    
    PC1 -->|SMB 3.1.1| DFS
    PC2 -->|SMB 3.1.1| DFS
    PC3 -->|SMB 3.1.1| DFS
    
    DFS --> FS1
    DFS --> FS2
    
    FS1 --> Vol1
    FS1 --> Vol2
    FS1 --> Vol3
    
    FS1 --> FSRM
    FS1 --> Audit
    FS1 --> Encrypt
    
    style FS1 fill:#4caf50
    style FS2 fill:#66bb6a
    style Security fill:#ff9800
```

### Step 1: Install File Services Role

```powershell
# Install File Server role and management tools
Install-WindowsFeature -Name FS-FileServer,FS-Resource-Manager,FS-DFS-Namespace,FS-DFS-Replication -IncludeManagementTools

# Verify installation
Get-WindowsFeature | Where-Object {$_.Name -like "FS-*" -and $_.Installed -eq $true}
```

### Step 2: Configure Storage

```powershell
# Initialize and format disks for file shares
$Disks = Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"}

foreach ($Disk in $Disks)
{
    Initialize-Disk -Number $Disk.Number -PartitionStyle GPT
    $Partition = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter
    Format-Volume -DriveLetter $Partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "FileShare" -Confirm:$false
}

# Create directory structure
$ShareRoot = "D:\Shares"
$Departments = @("IT", "Finance", "HR", "Engineering")

New-Item -Path $ShareRoot -ItemType Directory -Force

foreach ($Dept in $Departments)
{
    New-Item -Path "$ShareRoot\$Dept" -ItemType Directory -Force
}

# Create home drives directory
New-Item -Path "E:\HomeDirectories" -ItemType Directory -Force
```

### Step 3: Create Secure SMB Shares

```powershell
# Create department shares with encryption
foreach ($Dept in $Departments)
{
    $ShareName = "${Dept}Share"
    $SharePath = "$ShareRoot\$Dept"
    
    New-SmbShare -Name $ShareName `
        -Path $SharePath `
        -EncryptData $true `
        -FolderEnumerationMode AccessBased `
        -FullAccess "CONTOSO\Domain Admins" `
        -ChangeAccess "CONTOSO\${Dept}_Users" `
        -ReadAccess "CONTOSO\${Dept}_Readers"
}

# Create administrative share for home directories
New-SmbShare -Name "HomeDirectories$" `
    -Path "E:\HomeDirectories" `
    -EncryptData $true `
    -FullAccess "CONTOSO\Domain Admins" `
    -ReadAccess "CONTOSO\Domain Users"
```

### Step 4: Configure NTFS Permissions

```powershell
# Function to set NTFS permissions
function Set-SecureNTFSPermissions
{
    param(
        [string]$Path,
        [string]$Group,
        [string]$Permission = "Modify"
    )
    
    $Acl = Get-Acl $Path
    
    # Remove inherited permissions
    $Acl.SetAccessRuleProtection($true, $false)
    
    # Add SYSTEM full control
    $SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "NT AUTHORITY\SYSTEM", "FullControl", 
        "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $Acl.AddAccessRule($SystemRule)
    
    # Add Administrators full control
    $AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "BUILTIN\Administrators", "FullControl", 
        "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $Acl.AddAccessRule($AdminRule)
    
    # Add group permissions
    $GroupRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Group, $Permission, 
        "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $Acl.AddAccessRule($GroupRule)
    
    Set-Acl -Path $Path -AclObject $Acl
}

# Apply permissions to department shares
foreach ($Dept in $Departments) {
    Set-SecureNTFSPermissions -Path "$ShareRoot\$Dept" -Group "CONTOSO\${Dept}_Users"
}
```

### Step 5: Configure File Server Resource Manager (FSRM)

```powershell
# Configure FSRM email notifications
Set-FsrmSetting -SmtpServer "mail.contoso.com" `
    -AdminEmailAddress "fileserver-admins@contoso.com" `
    -FromEmailAddress "fileserver@contoso.com"

# Create file screening template to block executables
New-FsrmFileGroup -Name "Executable Files" `
    -IncludePattern @("*.exe","*.com","*.bat","*.cmd","*.vbs","*.ps1")

New-FsrmFileScreenTemplate -Name "Block Executables" `
    -IncludeGroup "Executable Files" `
    -Active

# Apply file screen to shares
foreach ($Dept in $Departments)
{
    New-FsrmFileScreen -Path "$ShareRoot\$Dept" `
        -Template "Block Executables" `
        -Active
}

# Set up quota templates
New-FsrmQuotaTemplate -Name "100GB Limit" `
    -Size 100GB `
    -SoftLimit:$false `
    -Threshold (New-FsrmQuotaThreshold -Percentage 85 -Action Email,Event)

# Apply quotas
foreach ($Dept in $Departments)
{
    New-FsrmQuota -Path "$ShareRoot\$Dept" `
        -Template "100GB Limit"
}
```

### Step 6: Enable Auditing

```powershell
# Enable audit policy for file access
auditpol /set /subcategory:"File Share" /success:enable /failure:enable
auditpol /set /subcategory:"File System" /success:enable /failure:enable

# Configure audit ACLs on shares
foreach ($Dept in $Departments)
{
    $Path = "$ShareRoot\$Dept"
    $Acl = Get-Acl $Path
    
    # Audit successful file access
    $AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        "Everyone", "ReadData,WriteData,Delete", 
        "Success,Failure", "None", "ContainerInherit,ObjectInherit"
    )
    
    $Acl.AddAuditRule($AuditRule)
    Set-Acl -Path $Path -AclObject $Acl
}
```

### Step 7: Verify and Test

```powershell
# Verification script
Write-Host "=== File Server Configuration Verification ===" -ForegroundColor Cyan

# Check SMB shares
Write-Host "`nSMB Shares:" -ForegroundColor Yellow
Get-SmbShare | Where-Object {$_.Name -notlike "*$"} | 
    Format-Table Name, Path, EncryptData, FolderEnumerationMode -AutoSize

# Check FSRM file screens
Write-Host "`nFile Screens:" -ForegroundColor Yellow
Get-FsrmFileScreen | Format-Table Path, Active, Template -AutoSize

# Check quotas
Write-Host "`nQuotas:" -ForegroundColor Yellow
Get-FsrmQuota | Format-Table Path, Size, Usage -AutoSize

# Test from client
Write-Host "`nTest Access from Client:" -ForegroundColor Yellow
Write-Host "Run: Test-Path \\\\$env:COMPUTERNAME\\ITShare" -ForegroundColor Green
```

### Security Checklist

- ✅ SMB encryption enabled on all shares
- ✅ Access-based enumeration configured
- ✅ NTFS permissions follow least privilege
- ✅ File screening prevents malware execution
- ✅ Quotas prevent storage exhaustion
- ✅ Audit logging enabled for compliance
- ✅ Shares hidden with $ suffix where appropriate

### Troubleshooting

**Issue**: Users cannot access shares  
**Solution**: Check group membership and NTFS permissions

```powershell
Get-ADGroupMember "ITShare_Users"
Get-Acl "D:\Shares\IT" | Format-List
```

**Issue**: File screening blocks legitimate files  
**Solution**: Create exception for specific file types

```powershell
New-FsrmFileScreenException -Path "D:\Shares\IT\Tools" -AllowedFileGroups "Executable Files"
```

**Issue**: SMB encryption not working  
**Solution**: Verify SMB version and client support

```powershell
Get-SmbConnection
Get-SmbServerConfiguration | Select-Object EncryptData, RejectUnencryptedAccess
```

---

## Scenario 2: Deploying a Web Application on IIS

### Scenario Overview

Deploy a secure web application using IIS with:

- SSL/TLS certificates
- Application pools isolation
- URL rewriting
- IP restrictions
- Application Request Routing (ARR)

**Time to complete**: 45-60 minutes  
**Difficulty**: Intermediate

### Deployment Architecture

```mermaid
graph TB
    Internet[Internet Traffic]
    Internet --> FW[Firewall<br/>Port 443]
    
    FW --> LB[Load Balancer<br/>ARR]
    
    subgraph DMZ[\"DMZ Network\"]
        LB --> IIS1[IIS Server 1<br/>Web01]
        LB --> IIS2[IIS Server 2<br/>Web02]
    end
    
    subgraph AppTier[\"Application Tier\"]
        IIS1 --> App1[Application Pool 1]
        IIS1 --> App2[Application Pool 2]
        
        App1 --> Site1[Website 1<br/>app.contoso.com]
        App2 --> Site2[Website 2<br/>api.contoso.com]
    end
    
    subgraph DataTier[\"Data Tier\"]
        Site1 --> DB[(SQL Server)]
        Site2 --> DB
        Site1 --> Cache[(Redis Cache)]
    end
    
    subgraph Security[\"Security Components\"]
        WAF[Web Application Firewall]
        Cert[SSL Certificate]
        IPRestrict[IP Restrictions]
    end
    
    LB --> WAF
    IIS1 --> Cert
    IIS1 --> IPRestrict
    
    style LB fill:#2196f3
    style IIS1 fill:#4caf50
    style IIS2 fill:#4caf50
    style Security fill:#ff9800
```

### Step 1: Install IIS with Required Features

```powershell
# Install IIS with all required features
Install-WindowsFeature -Name Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,`
    Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,`
    Web-App-Dev,Web-Asp-Net45,Web-Net-Ext45,Web-ISAPI-Ext,Web-ISAPI-Filter,`
    Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,`
    Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,`
    Web-Security,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-Digest-Auth,`
    Web-Cert-Auth,Web-IP-Security,Web-Url-Auth,`
    Web-Mgmt-Tools,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Service `
    -IncludeManagementTools

# Verify installation
Get-WindowsFeature | Where-Object {$_.Name -like "Web-*" -and $_.Installed -eq $true}
```

### Step 2: Configure SSL Certificate

```powershell
# Option 1: Import existing certificate
$CertPassword = Read-Host -AsSecureString -Prompt "Enter certificate password"
$Cert = Import-PfxCertificate -FilePath "C:\Certificates\app.contoso.com.pfx" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -Password $CertPassword

# Option 2: Request certificate from internal CA
$CertRequest = @"
[NewRequest]
Subject = "CN=app.contoso.com"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; Server Authentication

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=app.contoso.com&"
_continue_ = "dns=www.app.contoso.com&"
"@

$CertRequest | Out-File "C:\Temp\certrequest.inf"
certreq -new "C:\Temp\certrequest.inf" "C:\Temp\certrequest.req"
certreq -submit "C:\Temp\certrequest.req" "C:\Temp\cert.cer"
certreq -accept "C:\Temp\cert.cer"
```

### Step 3: Create Application Pools

```powershell
# Import IIS module
Import-Module WebAdministration

# Create isolated application pools
$AppPools = @(
    @{Name="AppPool1"; Identity="ApplicationPoolIdentity"; Pipeline="Integrated"},
    @{Name="AppPool2"; Identity="ApplicationPoolIdentity"; Pipeline="Integrated"},
    @{Name="APIPool"; Identity="NetworkService"; Pipeline="Integrated"}
)

foreach ($Pool in $AppPools)
{
    # Create app pool
    New-WebAppPool -Name $Pool.Name
    
    # Configure settings
    Set-ItemProperty "IIS:\AppPools\$($Pool.Name)" -Name "processModel.identityType" -Value 4  # ApplicationPoolIdentity
    Set-ItemProperty "IIS:\AppPools\$($Pool.Name)" -Name "managedRuntimeVersion" -Value "v4.0"
    Set-ItemProperty "IIS:\AppPools\$($Pool.Name)" -Name "managedPipelineMode" -Value $Pool.Pipeline
    Set-ItemProperty "IIS:\AppPools\$($Pool.Name)" -Name "recycling.periodicRestart.time" -Value "1.00:00:00"  # 1 day
    Set-ItemProperty "IIS:\AppPools\$($Pool.Name)" -Name "processModel.idleTimeout" -Value "00:20:00"  # 20 minutes
}
```

### Step 4: Create and Configure Websites

```powershell
# Create website directories
$SitePath1 = "C:\inetpub\wwwroot\App1"
$SitePath2 = "C:\inetpub\wwwroot\API"

New-Item -Path $SitePath1 -ItemType Directory -Force
New-Item -Path $SitePath2 -ItemType Directory -Force

# Deploy application files (example)
Copy-Item -Path "\\deployserver\apps\app1\*" -Destination $SitePath1 -Recurse -Force
Copy-Item -Path "\\deployserver\apps\api\*" -Destination $SitePath2 -Recurse -Force

# Remove default website
Remove-Website -Name "Default Web Site" -ErrorAction SilentlyContinue

# Create new websites
New-Website -Name "App1" `
    -PhysicalPath $SitePath1 `
    -ApplicationPool "AppPool1" `
    -Port 443 -Ssl `
    -HostHeader "app.contoso.com"

New-Website -Name "APIService" `
    -PhysicalPath $SitePath2 `
    -ApplicationPool "APIPool" `
    -Port 443 -Ssl `
    -HostHeader "api.contoso.com"

# Bind SSL certificates
$Cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Subject -like "*app.contoso.com*"}
New-WebBinding -Name "App1" -Protocol https -Port 443 -HostHeader "app.contoso.com" -SslFlags 1
(Get-WebBinding -Name "App1" -Protocol https).AddSslCertificate($Cert.Thumbprint, "My")
```

### Step 5: Configure Security Settings

```powershell
# Disable unnecessary HTTP methods
Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/security/requestFiltering/verbs" `
    -Name "Collection" `
    -Value @{verb="TRACE";allowed="False"}

# Enable detailed error messages only for local requests
Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/httpErrors" `
    -Name "errorMode" `
    -Value "DetailedLocalOnly"

# Configure IP restrictions (allow only specific IPs)
Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/security/ipSecurity" `
    -Name "Collection" `
    -Value @{ipAddress="192.168.1.0";subnetMask="255.255.255.0";allowed="True"}

Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/security/ipSecurity" `
    -Name "Collection" `
    -Value @{ipAddress="10.0.0.0";subnetMask="255.0.0.0";allowed="True"}

Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/security/ipSecurity" `
    -Name "allowUnlisted" `
    -Value "False"

# Enable custom headers for security
Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/httpProtocol/customHeaders" `
    -Name "Collection" `
    -Value @{name="X-Frame-Options";value="SAMEORIGIN"}

Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/httpProtocol/customHeaders" `
    -Name "Collection" `
    -Value @{name="X-Content-Type-Options";value="nosniff"}

Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/httpProtocol/customHeaders" `
    -Name "Collection" `
    -Value @{name="Strict-Transport-Security";value="max-age=31536000"}
```

### Step 6: Configure URL Rewrite (Optional)

```powershell
# Install URL Rewrite module if not already installed
# Download from: https://www.iis.net/downloads/microsoft/url-rewrite

# HTTP to HTTPS redirect rule
$RuleName = "HTTP to HTTPS Redirect"
Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules" `
    -Name "Collection" `
    -Value @{
        name=$RuleName
        stopProcessing="True"
    }

Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules/rule[@name='$RuleName']/match" `
    -Name "url" `
    -Value "(.*)"

Add-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules/rule[@name='$RuleName']/conditions" `
    -Name "Collection" `
    -Value @{input="{HTTPS}";pattern="off"}

Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules/rule[@name='$RuleName']/action" `
    -Name "type" `
    -Value "Redirect"

Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules/rule[@name='$RuleName']/action" `
    -Name "url" `
    -Value "https://{HTTP_HOST}/{R:1}"

Set-WebConfigurationProperty -PSPath "IIS:\Sites\App1" `
    -Filter "system.webServer/rewrite/rules/rule[@name='$RuleName']/action" `
    -Name "redirectType" `
    -Value "Permanent"
```

### Step 7: Test and Verify

```powershell
# Test script
Write-Host "=== IIS Configuration Verification ===" -ForegroundColor Cyan

# Check websites
Write-Host "`nWebsites:" -ForegroundColor Yellow
Get-Website | Format-Table Name, State, PhysicalPath, Bindings -AutoSize

# Check application pools
Write-Host "`nApplication Pools:" -ForegroundColor Yellow
Get-WebAppPoolState -Name * | Format-Table

# Check bindings
Write-Host "`nSSL Bindings:" -ForegroundColor Yellow
Get-WebBinding | Where-Object {$_.protocol -eq "https"} | 
    Format-Table protocol, bindingInformation, certificateHash -AutoSize

# Test URL access
Write-Host "`nTesting HTTPS Access:" -ForegroundColor Yellow
$TestUrl = "https://app.contoso.com"
try {
    $Response = Invoke-WebRequest -Uri $TestUrl -UseBasicParsing
    Write-Host "✓ $TestUrl - Status: $($Response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "✗ $TestUrl - Error: $($_.Exception.Message)" -ForegroundColor Red
}
```

### Production Deployment Checklist

- ✅ SSL certificate installed and bound
- ✅ Application pools isolated
- ✅ Custom error pages configured
- ✅ Security headers added
- ✅ IP restrictions applied
- ✅ HTTP to HTTPS redirect enabled
- ✅ Logging and monitoring configured
- ✅ Backup and recovery tested
- ✅ Load balancing configured (if applicable)
- ✅ Web Application Firewall rules created

### Troubleshooting Common IIS Issues

**Issue**: HTTP 503 - Service Unavailable  
**Cause**: Application pool stopped or crashed  
**Solution**:

```powershell
# Check application pool status
Get-WebAppPoolState -Name "AppPool1"

# Restart application pool
Restart-WebAppPool -Name "AppPool1"

# Check application pool identity permissions
icacls "C:\inetpub\wwwroot\App1"
```

**Issue**: SSL certificate errors  
**Solution**:

```powershell
# Verify certificate
Get-ChildItem -Path "Cert:\LocalMachine\My" | Format-List Subject, Thumbprint, NotAfter

# Check binding
Get-WebBinding -Name "App1" -Protocol https

# Test SSL
Test-NetConnection -ComputerName app.contoso.com -Port 443
```

---

## Scenario 3: Configuring a Privileged Access Workstation (PAW)

### PAW Overview

Configure a secure workstation for administrative tasks following the tiered admin model.

**Time to complete**: 30-45 minutes  
**Difficulty**: Advanced

### Step 1: Base Configuration

```powershell
# Rename computer
Rename-Computer -NewName "PAW-ADMIN-01" -Force

# Enable BitLocker
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector

# Disable unnecessary features
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName "Internet-Explorer-Optional-amd64" -NoRestart

# Configure Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -EnableControlledFolderAccess Enabled
Set-MpPreference -EnableNetworkProtection Enabled
Set-MpPreference -MAPSReporting Advanced
```

### Step 2: Restrict Applications

```powershell
# Enable AppLocker
Set-Service -Name "AppIDSvc" -StartupType Automatic
Start-Service -Name "AppIDSvc"

# Create AppLocker policy
$PolicyXml = @"
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="Enabled">
    <FilePathRule Id="$(New-Guid)" Name="Allow Program Files" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePathCondition Path="%PROGRAMFILES%\*"/>
      </Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
"@

$PolicyXml | Out-File "C:\Temp\AppLockerPolicy.xml"
Set-AppLockerPolicy -XmlPolicy "C:\Temp\AppLockerPolicy.xml"
```

### Step 3: Configure Network Restrictions

```powershell
# Block internet access except for specific destinations
New-NetFirewallRule -DisplayName "Block Internet" -Direction Outbound -Action Block -RemoteAddress "Internet"

# Allow specific management endpoints
$AllowedEndpoints = @("DC01.contoso.com", "DC02.contoso.com", "admin.contoso.com")

foreach ($Endpoint in $AllowedEndpoints) {
    New-NetFirewallRule -DisplayName "Allow $Endpoint" `
        -Direction Outbound -Action Allow `
        -RemoteAddress (Resolve-DnsName $Endpoint).IPAddress
}
```

---

## Additional Scenarios

For more scenarios, see:

- **[Configuration Management](configuration-management.md)** - Automation scenarios
- **[Security (Advanced)](security/index.md)** - Security implementation scenarios

## Related Topics

- **[Windows Server Overview](index.md)** - Server roles and features
- **[Configuration Overview](configuration/index.md)** - Quick configuration guide
- **[Security Quick Start](security/quick-start.md)** - Security hardening guide
