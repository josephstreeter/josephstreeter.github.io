---
title: Install Server Certificate for Domain Controllers
description: Comprehensive guide for installing and configuring SSL/TLS certificates for LDAPS on Active Directory domain controllers using modern methods and best practices
author: IT Operations Team
ms.date: 2025-01-01
ms.topic: how-to
ms.service: active-directory
ms.subservice: certificates
keywords: active directory, ldaps, ssl, tls, certificates, domain controller, security
---

## Install Server Certificate for Domain Controllers

## Overview

By default, Active Directory LDAP traffic is transmitted unencrypted and unsigned, making it susceptible to eavesdropping and replay attacks. This guide provides comprehensive procedures for securing LDAP communications using SSL/TLS encryption (LDAPS) through proper server certificate installation and configuration.

**LDAPS Benefits:**

- **Encryption**: Protects LDAP traffic from eavesdropping
- **Authentication**: Verifies domain controller identity
- **Integrity**: Prevents tampering with LDAP communications
- **Compliance**: Meets security requirements for encrypted directory access

## Prerequisites

Before beginning certificate installation, ensure the following requirements are met:

### System Requirements

- **Windows Server**: 2016 or later (2019/2022 recommended)
- **Administrative Access**: Domain Admin or local Administrator privileges
- **Certificate Authority Access**: Internal CA or external CA for certificate requests
- **DNS Resolution**: Proper FQDN resolution for all domain controllers
- **Time Synchronization**: Accurate system time (within 5 minutes of CA)

### Planning Considerations

- **Certificate Type**: Standard SSL/TLS server certificate with Server Authentication EKU
- **Subject Name**: Must match the FQDN of the domain controller
- **Key Length**: Minimum 4096-bit RSA or 256-bit ECC
- **Certificate Authority**: Choose between internal Microsoft CA or external commercial CA
- **Certificate Lifecycle**: Plan for renewal procedures and monitoring

### Security Considerations

⚠️ **Important**: Before beginning, verify that Active Directory Certificate Services (AD CS) is not installed on domain controllers if using external certificates. Mixed certificate authorities can cause authentication issues.

- **Certificate Validation**: Ensure proper certificate chain validation
- **Private Key Protection**: Use secure key storage and proper permissions
- **Certificate Templates**: Use appropriate templates for domain controllers
- **Root CA Trust**: Ensure root certificates are properly distributed

## Certificate Request Methods

### Method 1: Microsoft Certificate Authority (Recommended)

For organizations with an internal Microsoft Certificate Authority, this is the preferred method for domain controller certificates.

#### Using Certificate Templates

1. **Configure Domain Controller Certificate Template:**

   ```powershell
   # Enable the Domain Controller certificate template
   certlm.msc
   # Navigate to Personal > Certificates
   # Right-click > All Tasks > Request New Certificate
   # Select Domain Controller template
   ```

2. **PowerShell Certificate Request:**

   ```powershell
   # Request certificate using PowerShell
   $Template = "DomainController"
   $Subject = "CN=$env:COMPUTERNAME.$env:USERDNSDOMAIN"
   
   Get-Certificate -Template $Template -SubjectName $Subject -CertStoreLocation Cert:\LocalMachine\My
   ```

3. **Verify Certificate Installation:**

   ```powershell
   # Check installed certificates
   Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
   ```

#### Web Enrollment Method

1. **Access Certificate Services Web Interface:**
   - Navigate to `https://ca-server/certsrv`
   - Select "Request a certificate"
   - Choose "Advanced certificate request"

2. **Create Certificate Request:**
   - Select "Create and submit a request to this CA"
   - Choose "Domain Controller" or "Computer" template
   - Fill in required information

### Method 2: External Certificate Authority

For external commercial certificates or when internal CA is not available.

#### Generate Certificate Signing Request (CSR)

1. **Create certificate request configuration file:**

   ```ini
   # Save as request.inf
   [Version]
   Signature="$Windows NT$"
   
   [NewRequest]
   Subject = "CN=dc1.contoso.com,O=Your Organization,C=US"
   KeySpec = 1
   KeyLength = 4096
   Exportable = TRUE
   MachineKeySet = TRUE
   SMIME = False
   PrivateKeyArchive = FALSE
   UserProtected = FALSE
   UseExistingKeySet = FALSE
   ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
   ProviderType = 12
   RequestType = PKCS10
   KeyUsage = 0xa0
   
   [EnhancedKeyUsageExtension]
   OID=1.3.6.1.5.5.7.3.1 ; Server Authentication
   ```

2. **Generate CSR using PowerShell (Recommended):**

   ```powershell
   # Modern PowerShell method
   $Subject = "CN=$env:COMPUTERNAME.$env:USERDNSDOMAIN"
   $Template = @{
       Subject = $Subject
       KeyLength = 4096
       KeyAlgorithm = "RSA"
       HashAlgorithm = "SHA256"
       KeyUsage = "DigitalSignature,KeyEncipherment"
       EnhancedKeyUsage = "Server Authentication"
       CertStoreLocation = "Cert:\LocalMachine\My"
   }
   
   $CSR = New-CertificateRequest @Template
   $CSR | Out-File -FilePath "C:\temp\$env:COMPUTERNAME.csr"
   ```

3. **Generate CSR using CertReq (Legacy):**

   ```cmd
   certreq -new request.inf request.csr
   ```

#### Submit Certificate Request

1. **Commercial Certificate Authority:**
   - Submit the CSR to your chosen CA (DigiCert, GlobalSign, etc.)
   - Specify "SSL/TLS Server Certificate" or "Domain Validation"
   - Provide domain validation as required by the CA

2. **Certificate Authority Requirements:**
   - Server Authentication Enhanced Key Usage (EKU)
   - Subject name matching domain controller FQDN
   - Key length minimum 4096-bit RSA or 256-bit ECC
   - SHA-256 or higher signature algorithm

### Method 3: PowerShell Automation (Enterprise)

For automated certificate management across multiple domain controllers.

```powershell
# Automated certificate deployment script
param(
    [string[]]$DomainControllers,
    [string]$CertificateTemplate = "DomainController",
    [string]$CertificateAuthority
)

foreach ($DC in $DomainControllers) {
    Invoke-Command -ComputerName $DC -ScriptBlock {
        param($Template, $CA)
        
        # Request certificate
        $Subject = "CN=$env:COMPUTERNAME.$env:USERDNSDOMAIN"
        Get-Certificate -Template $Template -SubjectName $Subject -CertStoreLocation Cert:\LocalMachine\My
        
        # Restart LDAP service to enable LDAPS
        Restart-Service NTDS -Force
        
    } -ArgumentList $CertificateTemplate, $CertificateAuthority
}
```

## Certificate Installation

### Install Certificate from External CA

1. **Install using CertReq (Traditional Method):**

   ```cmd
   # Install the certificate
   certreq -accept certificate.crt
   ```

2. **Install using PowerShell (Recommended):**

   ```powershell
   # Import certificate to Personal store
   Import-Certificate -FilePath "C:\temp\certificate.crt" -CertStoreLocation Cert:\LocalMachine\My
   
   # Verify installation
   Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
   ```

3. **Install Certificate Chain (If Required):**

   ```powershell
   # Import intermediate certificates
   Import-Certificate -FilePath "C:\temp\intermediate.crt" -CertStoreLocation Cert:\LocalMachine\CA
   
   # Import root certificate
   Import-Certificate -FilePath "C:\temp\root.crt" -CertStoreLocation Cert:\LocalMachine\Root
   ```

### Verify LDAPS Functionality

#### Using PowerShell

```powershell
# Test LDAPS connectivity
$DC = $env:COMPUTERNAME
$Domain = $env:USERDNSDOMAIN

# Test LDAPS port
Test-NetConnection -ComputerName $DC -Port 636

# Test LDAP SSL binding
$DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAPS://$DC:636")
try {
    $DirectoryEntry.Name
    Write-Host "LDAPS connection successful" -ForegroundColor Green
} catch {
    Write-Error "LDAPS connection failed: $($_.Exception.Message)"
}
```

#### Using LDP.exe

1. **Start Active Directory Administration Tool:**

   ```cmd
   ldp.exe
   ```

2. **Test LDAPS Connection:**
   - Click **Connection** → **Connect**
   - Enter domain controller name
   - Enter port **636**
   - Check **SSL** checkbox
   - Click **OK**

3. **Verify successful connection in the LDP console**

#### Using Command Line

```cmd
# Test LDAPS using ldifde
ldifde -f test.ldf -s dc1.contoso.com:636 -t 636

# Test using nltest
nltest /dsgetdc:contoso.com /ldaponly /force
```

### Enable Certificate in NTDS Personal Store (Multiple Certificates)

If multiple certificates exist, ensure the correct certificate is used for LDAPS:

1. **Export Certificate with Private Key:**

   ```powershell
   # Find the certificate
   $Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
   
   # Export to PFX
   $Password = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
   Export-PfxCertificate -Cert $Cert -FilePath "C:\temp\dc-cert.pfx" -Password $Password
   ```

2. **Import to NTDS Personal Store:**

   Since PowerShell cannot directly manage the NTDS Personal store, use the Certificates MMC:

   - Run `mmc.exe`
   - Add **Certificates** snap-in
   - Select **Service account** → **Local computer** → **Active Directory Domain Services**
   - Navigate to **NTDS\Personal** → **Certificates**
   - Right-click → **All Tasks** → **Import**
   - Import the PFX file with private key

3. **Restart Active Directory Domain Services:**

   ```powershell
   Restart-Service NTDS -Force
   ```

## Monitoring and Troubleshooting

### Enable LDAP Interface Events Logging

Monitor LDAP authentication and identify clients using unsecured connections.

#### Understanding LDAP Events

| Event ID | Description | Frequency |
|----------|-------------|-----------|
| **2887** | Summary of unsigned/unencrypted LDAP binds | Every 24 hours |
| **2889** | Individual unsigned/unencrypted LDAP bind | Per occurrence |
| **2888** | Summary of LDAP over non-SSL port | Every 24 hours |

#### Enable LDAP Interface Events

```powershell
# Enable LDAP Interface Events logging
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "16 LDAP Interface Events" -Value 2

# Restart NTDS service to apply changes
Restart-Service NTDS -Force
```

#### Legacy Registry Method

```cmd
# Enable logging
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" /v "16 LDAP Interface Events" /t REG_DWORD /d 2 /f

# Disable logging
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" /v "16 LDAP Interface Events" /t REG_DWORD /d 0 /f
```

#### Monitor LDAP Events

```powershell
# Monitor for unsecured LDAP binds
Get-WinEvent -LogName "Directory Service" | Where-Object {$_.Id -in 2887,2888,2889} | 
    Select-Object TimeCreated, Id, LevelDisplayName, Message

# Export events for analysis
Get-WinEvent -LogName "Directory Service" -FilterHashtable @{ID=2887,2888,2889} | 
    Export-Csv -Path "C:\temp\ldap-events.csv" -NoTypeInformation
```

### Common Issues and Solutions

#### Certificate Not Working

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| **Wrong Certificate Store** | LDAPS fails, Event ID 1220 | Move certificate to NTDS Personal store |
| **Certificate Chain Issues** | SSL errors, trust failures | Install intermediate and root certificates |
| **Subject Name Mismatch** | Certificate validation errors | Ensure certificate subject matches DC FQDN |
| **Expired Certificate** | LDAPS connections fail | Renew and install updated certificate |

#### Diagnostic Commands

```powershell
# Check certificate validity
$Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
$Cert | Select-Object Subject, NotBefore, NotAfter, Thumbprint

# Test certificate chain
Test-Certificate -Cert $Cert -Policy SSL

# Check LDAPS port
Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 636

# Verify certificate in NTDS store (requires manual check via MMC)
# Run: mmc.exe → Add Certificates snap-in → Service Account → NTDS
```

#### Event Log Analysis

```powershell
# Check for certificate-related errors
Get-WinEvent -LogName System | Where-Object {$_.Message -like "*certificate*" -or $_.Message -like "*SSL*"} |
    Select-Object TimeCreated, Id, LevelDisplayName, Message

# Check NTDS service events
Get-WinEvent -LogName "Directory Service" | Where-Object {$_.Id -in 1220,1221,1222} |
    Select-Object TimeCreated, Id, Message
```

### Certificate Lifecycle Management

#### Automated Certificate Monitoring

```powershell
# Script to monitor certificate expiration
$Certificates = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.EnhancedKeyUsageList -match "Server Authentication"}

foreach ($Cert in $Certificates) {
    $DaysUntilExpiry = ($Cert.NotAfter - (Get-Date)).Days
    
    if ($DaysUntilExpiry -lt 30) {
        Write-Warning "Certificate expires in $DaysUntilExpiry days: $($Cert.Subject)"
        # Send alert or log to monitoring system
    }
}
```

#### Certificate Renewal Process

1. **Automated Renewal (Internal CA):**

   ```powershell
   # Enable auto-renewal for domain controllers
   certlm.msc
   # Right-click certificate → All Tasks → Renew Certificate with New Key
   ```

2. **Manual Renewal Process:**
   - Generate new CSR using updated procedures
   - Submit to certificate authority
   - Install new certificate
   - Verify LDAPS functionality
   - Remove old certificate after validation

### Security Best Practices

#### Certificate Security

- **Private Key Protection**: Use HSM or secure key storage
- **Certificate Templates**: Use restrictive templates for domain controllers
- **Key Length**: Minimum 4096-bit RSA or 256-bit ECC
- **Certificate Authority**: Use trusted, well-managed CA infrastructure

#### Operational Security

```powershell
# Enforce LDAPS-only connections
# Set LDAP signing requirements
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -Value 2

# Require SSL for LDAP client connections
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "RequireSSLOnNonSSLPort" -Value 1
```

#### Compliance and Auditing

- **Regular Certificate Audits**: Monitor certificate validity and usage
- **Access Logging**: Enable comprehensive LDAP access logging
- **Certificate Inventory**: Maintain inventory of all certificates
- **Compliance Reporting**: Generate regular compliance reports

## Advanced Configuration

### Multiple Certificate Scenarios

When domain controllers have multiple certificates installed, Schannel may select the wrong certificate for LDAPS connections. This section addresses certificate selection and management.

#### Certificate Store Priority

1. **NTDS Personal Store** (Highest Priority)
   - Dedicated store for Active Directory Domain Services
   - Ensures correct certificate selection for LDAPS
   - Requires manual management (no PowerShell cmdlets)

2. **Local Computer Personal Store** (Default)
   - Standard certificate location
   - May cause conflicts with multiple certificates
   - Accessible via PowerShell certificate providers

#### Managing Multiple Certificates

```powershell
# List all certificates in Computer Personal store
Get-ChildItem Cert:\LocalMachine\My | 
    Select-Object Subject, FriendlyName, NotAfter, Thumbprint

# Identify certificates with Server Authentication EKU
Get-ChildItem Cert:\LocalMachine\My | 
    Where-Object {$_.EnhancedKeyUsageList -match "Server Authentication"} |
    Select-Object Subject, NotAfter, Thumbprint
```

#### Certificate Export and Import Process

1. **Export Certificate with Private Key:**

   ```powershell
   # Select the correct certificate
   $Cert = Get-ChildItem Cert:\LocalMachine\My | 
       Where-Object {$_.Subject -like "*dc1.contoso.com*"}
   
   # Create secure password for export
   $Password = Read-Host "Enter password for PFX export" -AsSecureString
   
   # Export to PFX format
   Export-PfxCertificate -Cert $Cert -FilePath "C:\temp\dc-certificate.pfx" -Password $Password
   ```

2. **Import to NTDS Personal Store:**

   Due to limitations with PowerShell cmdlets, use the Certificates MMC snap-in:

   - Run `mmc.exe` as Administrator
   - Add **Certificates** snap-in
   - Select **Service account** → **Local computer** → **Active Directory Domain Services**
   - Navigate to **NTDS** → **Personal** → **Certificates**
   - Right-click → **All Tasks** → **Import**
   - Select the PFX file and provide the password
   - Choose to make the key exportable if required

3. **Post-Installation Steps:**

   ```powershell
   # Restart Active Directory Domain Services
   Restart-Service NTDS -Force
   
   # Verify LDAPS functionality
   Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 636
   ```

### Root Certificate Management

#### Install Root and Intermediate Certificates

```powershell
# Install root certificate to Trusted Root Certification Authorities
Import-Certificate -FilePath "C:\temp\root-ca.crt" -CertStoreLocation Cert:\LocalMachine\Root

# Install intermediate certificate to Intermediate Certification Authorities
Import-Certificate -FilePath "C:\temp\intermediate-ca.crt" -CertStoreLocation Cert:\LocalMachine\CA

# Publish root certificate to NTAuthCertificates (for AD CS integration)
certutil -dspublish -f "C:\temp\root-ca.crt" NTAuthCA
```

#### Verify Certificate Chain

```powershell
# Test certificate chain validation
$Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
$Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$Chain.Build($Cert)

if ($Chain.ChainStatus.Count -eq 0) {
    Write-Host "Certificate chain is valid" -ForegroundColor Green
} else {
    Write-Warning "Certificate chain issues detected:"
    $Chain.ChainStatus | ForEach-Object { Write-Host $_.StatusInformation }
}
```

## Additional Resources

### Microsoft Documentation

- [Microsoft Learn: Configure LDAP over SSL (LDAPS)](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/enable-ldap-over-ssl-3rd-certification-authority)
- [Microsoft Learn: How to enable LDAP signing in Windows Server](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/enable-ldap-signing-windows-server)
- [Microsoft Learn: Certificate Templates](https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/certificate-templates)
- [Microsoft Learn: Active Directory Certificate Services](https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/active-directory-certificate-services-overview)

### PowerShell Certificate Management

- [Microsoft Learn: PKI PowerShell Cmdlets](https://learn.microsoft.com/en-us/powershell/module/pki/index.md)
- [Microsoft Learn: Certificate Provider](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/about/about_certificate_provider)

### Security and Compliance

- [NIST Special Publication 800-52: Guidelines for TLS](https://csrc.nist.gov/publications/detail/sp/800-52/rev-2/final)
- [Microsoft Security Baseline for Windows Server](https://www.microsoft.com/en-us/download/details.aspx?id=55319)

### Troubleshooting Resources

- [Microsoft Learn: Troubleshoot LDAP over SSL connection problems](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/ldap-over-ssl-connection-issues)
- [Microsoft Learn: Event ID 2889, 2887, 2888](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/event-id-2889-2887-2888)

## Conclusion

Implementing LDAPS on Active Directory domain controllers is essential for securing directory communications and meeting compliance requirements. This guide provides comprehensive procedures for certificate installation, configuration, and management using modern tools and best practices.

**Key Takeaways:**

- **Use Internal CA when possible** for simplified certificate management
- **Monitor certificate expiration** to prevent service disruptions
- **Implement proper certificate store management** for multiple certificate scenarios
- **Enable comprehensive logging** to identify unsecured connections
- **Follow security best practices** for certificate lifecycle management

**Next Steps:**

1. Implement certificate monitoring and alerting
2. Configure LDAP signing requirements
3. Establish certificate renewal procedures
4. Document certificate inventory and management processes

Proper LDAPS implementation enhances Active Directory security and provides the foundation for secure directory-enabled applications and services.
