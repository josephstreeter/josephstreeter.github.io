---
title: "Confirming LDAPS Certificates"
description: "Comprehensive guide for validating and confirming LDAPS (LDAP over SSL/TLS) certificates on Active Directory Domain Controllers using PowerShell, OpenSSL, and built-in Windows tools"
tags: ["active-directory", "ldaps", "ssl-certificates", "domain-controllers", "certificate-validation", "security"]
category: "services"
subcategory: "activedirectory"
difficulty: "intermediate"
last_updated: "2025-10-06"
author: "Joseph Streeter"
applies_to: ["Windows Server 2016+", "Active Directory Domain Services", "PowerShell 5.1+"]
---

## Overview

LDAPS (LDAP over SSL/TLS) provides secure communication between LDAP clients and Active Directory Domain Controllers. This guide provides comprehensive procedures for validating and confirming LDAPS certificates across your Active Directory infrastructure using multiple methods and tools.

**Key Validation Areas:**

- **Certificate Installation**: Verify certificates are properly installed on Domain Controllers
- **Certificate Chain Validation**: Confirm complete certificate trust chain
- **LDAPS Connectivity**: Test secure LDAP connections on port 636
- **Certificate Expiration**: Monitor certificate validity periods
- **Cross-Platform Validation**: Validate certificates from Windows, Linux, and other platforms

## Prerequisites

### System Requirements

- **Active Directory Environment**: Functional AD domain with Domain Controllers
- **LDAPS Configuration**: LDAPS enabled on Domain Controllers (port 636)
- **Certificate Infrastructure**: Valid SSL certificates installed on DCs
- **Network Access**: Connectivity to Domain Controllers on port 636
- **Administrative Privileges**: Domain administrator or certificate management rights

### Required Tools

- **PowerShell**: Version 5.1 or later with AD and PKI modules
- **OpenSSL**: For cross-platform certificate validation
- **certutil.exe**: Windows certificate utility
- **ldp.exe**: LDAP data interchange format directory exchange tool
- **Certificate Manager**: `certmgr.msc` for certificate management

### Security Considerations

- **Certificate Validation**: Always verify certificate authenticity and trust chain
- **Network Security**: Ensure secure transport of certificate validation traffic
- **Credential Protection**: Use secure methods for authentication during testing
- **Monitoring**: Log certificate validation activities for audit purposes

## Method 1: PowerShell Certificate Validation

### Comprehensive Domain Controller Certificate Check

**Enhanced PowerShell Validation Script:**

```powershell
# LDAPS Certificate Validation Script
[CmdletBinding()]
param(
    [string[]]$DomainControllers,
    [string]$Domain = $env:USERDNSDOMAIN,
    [int]$Port = 636,
    [switch]$ExportCertificates,
    [string]$ExportPath = "C:\CertValidation"
)

function Test-LDAPSCertificate 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        [int]$Port = 636,
        [switch]$ExportCertificate,
        [string]$ExportPath
    )
    
    try 
    {
        Write-Host "Validating LDAPS certificate for: $ComputerName" -ForegroundColor Cyan
        
        # Test LDAPS connectivity
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        $ConnectTask = $TcpClient.ConnectAsync($ComputerName, $Port)
        $ConnectResult = $ConnectTask.Wait(5000)
        
        if (!$ConnectResult -or !$TcpClient.Connected) 
        {
            Write-Warning "Cannot connect to $ComputerName on port $Port"
            return $null
        }
        
        # Get SSL stream and certificate
        $SslStream = New-Object System.Net.Security.SslStream($TcpClient.GetStream())
        $SslStream.AuthenticateAsClient($ComputerName)
        
        $Certificate = $SslStream.RemoteCertificate
        $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Certificate)
        
        # Validate certificate chain
        $Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $ChainValid = $Chain.Build($X509Certificate)
        
        # Calculate days until expiration
        $DaysUntilExpiry = ($X509Certificate.NotAfter - (Get-Date)).Days
        
        # Create result object
        $Result = [PSCustomObject]@{
            ComputerName = $ComputerName
            Subject = $X509Certificate.Subject
            Issuer = $X509Certificate.Issuer
            Thumbprint = $X509Certificate.Thumbprint
            NotBefore = $X509Certificate.NotBefore
            NotAfter = $X509Certificate.NotAfter
            DaysUntilExpiry = $DaysUntilExpiry
            IsValid = $ChainValid
            ChainStatus = $Chain.ChainStatus
            SANs = $X509Certificate.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" } | Select-Object -ExpandProperty Format -First 1
            KeySize = $X509Certificate.PublicKey.Key.KeySize
            Algorithm = $X509Certificate.SignatureAlgorithm
        }
        
        # Display results
        Write-Host "Certificate Details:" -ForegroundColor Green
        Write-Host "  Subject: $($X509Certificate.Subject)" -ForegroundColor White
        Write-Host "  Issuer: $($X509Certificate.Issuer)" -ForegroundColor White
        Write-Host "  Valid From: $($X509Certificate.NotBefore)" -ForegroundColor White
        Write-Host "  Valid Until: $($X509Certificate.NotAfter)" -ForegroundColor White
        Write-Host "  Days Until Expiry: $DaysUntilExpiry" -ForegroundColor $(if ($DaysUntilExpiry -lt 30) { "Red" } elseif ($DaysUntilExpiry -lt 90) { "Yellow" } else { "Green" })
        Write-Host "  Chain Valid: $ChainValid" -ForegroundColor $(if ($ChainValid) { "Green" } else { "Red" })
        
        if (!$ChainValid) 
        {
            Write-Warning "Certificate chain validation issues:"
            foreach ($Status in $Chain.ChainStatus) 
            {
                Write-Warning "  $($Status.Status): $($Status.StatusInformation)"
            }
        }
        
        # Export certificate if requested
        if ($ExportCertificate -and $ExportPath) 
        {
            if (!(Test-Path $ExportPath)) 
            {
                New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            }
            
            $CertFile = Join-Path $ExportPath "$ComputerName.cer"
            [System.IO.File]::WriteAllBytes($CertFile, $X509Certificate.RawData)
            Write-Host "  Certificate exported to: $CertFile" -ForegroundColor Green
        }
        
        return $Result
    }
    catch 
    {
        Write-Error "Failed to validate certificate for $ComputerName : $($_.Exception.Message)"
        return $null
    }
    finally 
    {
        if ($SslStream) { $SslStream.Dispose() }
        if ($TcpClient) { $TcpClient.Dispose() }
        if ($Chain) { $Chain.Dispose() }
    }
}

function Get-DomainControllerCertificates 
{
    [CmdletBinding()]
    param(
        [string[]]$DomainControllers,
        [string]$Domain,
        [int]$Port = 636,
        [switch]$ExportCertificates,
        [string]$ExportPath
    )
    
    # Get Domain Controllers if not specified
    if (!$DomainControllers) 
    {
        try 
        {
            Write-Host "Discovering Domain Controllers..." -ForegroundColor Yellow
            $DomainControllers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
            Write-Host "Found $($DomainControllers.Count) Domain Controllers" -ForegroundColor Green
        }
        catch 
        {
            Write-Error "Failed to discover Domain Controllers: $($_.Exception.Message)"
            return
        }
    }
    
    $Results = @()
    
    foreach ($DC in $DomainControllers) 
    {
        Write-Host "`n" + "="*50 -ForegroundColor Cyan
        $Result = Test-LDAPSCertificate -ComputerName $DC -Port $Port -ExportCertificate:$ExportCertificates -ExportPath $ExportPath
        if ($Result) 
        {
            $Results += $Result
        }
    }
    
    return $Results
}

# Main execution
Write-Host "LDAPS Certificate Validation Tool" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Create export directory if needed
if ($ExportCertificates -and !(Test-Path $ExportPath)) 
{
    New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
    Write-Host "Created export directory: $ExportPath" -ForegroundColor Green
}

# Run certificate validation
$ValidationResults = Get-DomainControllerCertificates -DomainControllers $DomainControllers -Domain $Domain -Port $Port -ExportCertificates:$ExportCertificates -ExportPath $ExportPath

if ($ValidationResults) 
{
    Write-Host "`n" + "="*50 -ForegroundColor Green
    Write-Host "VALIDATION SUMMARY" -ForegroundColor Green
    Write-Host "="*50 -ForegroundColor Green
    
    $ValidationResults | Format-Table ComputerName, Subject, DaysUntilExpiry, IsValid -AutoSize
    
    # Check for issues
    $ExpiringCerts = $ValidationResults | Where-Object { $_.DaysUntilExpiry -lt 90 }
    $InvalidCerts = $ValidationResults | Where-Object { !$_.IsValid }
    
    if ($ExpiringCerts) 
    {
        Write-Warning "Certificates expiring within 90 days:"
        $ExpiringCerts | Format-Table ComputerName, NotAfter, DaysUntilExpiry -AutoSize
    }
    
    if ($InvalidCerts) 
    {
        Write-Warning "Certificates with validation issues:"
        $InvalidCerts | Format-Table ComputerName, Subject, ChainStatus -AutoSize
    }
    
    if (!$ExpiringCerts -and !$InvalidCerts) 
    {
        Write-Host "✓ All certificates are valid and not expiring soon" -ForegroundColor Green
    }
}

# Example usage:
# .\Test-LDAPSCertificates.ps1 -ExportCertificates -ExportPath "C:\CertValidation"
# .\Test-LDAPSCertificates.ps1 -DomainControllers @("DC01.contoso.com", "DC02.contoso.com")
```

## Method 2: OpenSSL Cross-Platform Validation

### Basic OpenSSL Certificate Retrieval

**Simple Certificate Download and Validation:**

```bash
#!/bin/bash

# Basic LDAPS Certificate Validation Script
# Usage: ./validate-ldaps.sh <domain-controller> [port]

DC_HOST="${1:-dc01.contoso.com}"
LDAPS_PORT="${2:-636}"
OUTPUT_DIR="./certificates"

echo "Validating LDAPS certificate for: $DC_HOST:$LDAPS_PORT"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Test connectivity
if ! timeout 10 bash -c "</dev/tcp/$DC_HOST/$LDAPS_PORT" 2>/dev/null; then
    echo "ERROR: Cannot connect to $DC_HOST:$LDAPS_PORT"
    exit 1
fi

# Retrieve certificate chain
echo "Retrieving certificate chain..."
openssl s_client -showcerts -verify 5 -connect "$DC_HOST:$LDAPS_PORT" < /dev/null 2>/dev/null > "$OUTPUT_DIR/${DC_HOST}_chain.pem"

# Extract individual certificates
awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN/) {a++}; out="'$OUTPUT_DIR'/'$DC_HOST'_cert"a".pem"; print >out}' "$OUTPUT_DIR/${DC_HOST}_chain.pem"

# Verify each certificate
echo "Verifying certificates..."
for cert in "$OUTPUT_DIR/${DC_HOST}_cert"*.pem; do
    if [ -f "$cert" ]; then
        echo "Verifying: $(basename "$cert")"
        openssl verify -show_chain "$cert"
        echo "Certificate details:"
        openssl x509 -in "$cert" -noout -subject -issuer -dates -fingerprint
        echo "---"
    fi
done
```

### Advanced OpenSSL Certificate Analysis

**Comprehensive Certificate Validation Script:**

```bash
#!/bin/bash

# Advanced LDAPS Certificate Validation Script
# Validates SSL certificates on Domain Controllers using OpenSSL

# Configuration
DOMAIN_CONTROLLERS=()
LDAPS_PORT=636
OUTPUT_DIR="./certificates"
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() 
{
    cat <<EOF
Usage: $0 [OPTIONS]
Options:
  -h, --help              Show this help message
  -d, --domain-controller Add domain controller (can be used multiple times)
  -p, --port             LDAPS port (default: 636)
  -o, --output-dir       Directory to save certificates (default: ./certificates)
  -v, --verbose          Enable verbose output
  --discover             Auto-discover domain controllers

Examples:
  $0 -d dc01.contoso.com -d dc02.contoso.com
  $0 --discover -v
  $0 -d 192.168.1.10 -p 636 -o /tmp/certs
EOF
}

# Function to log messages
log() 
{
    local level=$1
    local message=$2
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${CYAN}[DEBUG]${NC} $message"
            fi
            ;;
    esac
}

# Function to validate single certificate
validate_certificate() 
{
    local dc=$1
    local port=${2:-$LDAPS_PORT}
    
    log "INFO" "Validating certificate for: $dc:$port"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Test connectivity first
    if ! timeout 10 bash -c "</dev/tcp/$dc/$port" 2>/dev/null; then
        log "ERROR" "Cannot connect to $dc:$port"
        return 1
    fi
    
    log "DEBUG" "Connection successful to $dc:$port"
    
    # Get certificate chain
    local cert_file="$OUTPUT_DIR/${dc//[^a-zA-Z0-9]/_}.pem"
    local chain_file="$OUTPUT_DIR/${dc//[^a-zA-Z0-9]/_}_chain.pem"
    
    log "DEBUG" "Retrieving certificate chain..."
    
    # Retrieve certificate and chain
    echo | openssl s_client -showcerts -servername "$dc" -connect "$dc:$port" 2>/dev/null > "$chain_file"
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to retrieve certificate from $dc"
        return 1
    fi
    
    # Extract server certificate
    openssl x509 -in "$chain_file" 2>/dev/null > "$cert_file"
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to extract certificate from $dc"
        return 1
    fi
    
    # Get certificate details
    local subject=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/subject=//')
    local issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/issuer=//')
    local not_before=$(openssl x509 -in "$cert_file" -noout -startdate 2>/dev/null | sed 's/notBefore=//')
    local not_after=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    local fingerprint=$(openssl x509 -in "$cert_file" -noout -fingerprint -sha256 2>/dev/null | sed 's/SHA256 Fingerprint=//')
    
    # Calculate days until expiration
    local exp_date=$(date -d "$not_after" +%s 2>/dev/null || echo "0")
    local current_date=$(date +%s)
    local days_until_exp=$(( (exp_date - current_date) / 86400 ))
    
    # Display results
    echo -e "\n${CYAN}Certificate Details for $dc:${NC}"
    echo "----------------------------------------"
    echo "Subject: $subject"
    echo "Issuer: $issuer"
    echo "Valid From: $not_before"
    echo "Valid Until: $not_after"
    echo "SHA256 Fingerprint: $fingerprint"
    
    if [ $days_until_exp -lt 0 ]; then
        echo -e "Status: ${RED}EXPIRED${NC} ($((-days_until_exp)) days ago)"
    elif [ $days_until_exp -lt 30 ]; then
        echo -e "Status: ${RED}EXPIRING SOON${NC} ($days_until_exp days remaining)"
    elif [ $days_until_exp -lt 90 ]; then
        echo -e "Status: ${YELLOW}WARNING${NC} ($days_until_exp days remaining)"
    else
        echo -e "Status: ${GREEN}VALID${NC} ($days_until_exp days remaining)"
    fi
    
    # Verify certificate chain
    log "DEBUG" "Verifying certificate chain..."
    local verify_result=$(openssl verify -show_chain "$cert_file" 2>&1)
    
    if echo "$verify_result" | grep -q "OK"; then
        echo -e "Chain Validation: ${GREEN}VALID${NC}"
    else
        echo -e "Chain Validation: ${RED}INVALID${NC}"
        if [ "$VERBOSE" = true ]; then
            echo "Verification Details:"
            echo "$verify_result" | sed 's/^/  /'
        fi
    fi
    
    # Check SAN extensions
    local sans=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/^ *//')
    if [ -n "$sans" ]; then
        echo "Subject Alternative Names: $sans"
    fi
    
    log "INFO" "Certificate saved to: $cert_file"
    echo ""
    
    return 0
}

# Example usage demonstration
if [ "$#" -eq 0 ]; then
    echo "LDAPS Certificate Validation Script"
    echo "Example usage:"
    echo "  $0 -d dc01.contoso.com -d dc02.contoso.com -v"
    echo "  $0 --help"
    exit 0
fi
```

## Method 3: Windows Certificate Utilities

### certutil.exe Validation

**Remote Certificate Validation using certutil:**

```powershell
function Invoke-CertutilValidation 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$DomainControllers,
        [PSCredential]$Credential
    )
    
    $ScriptBlock = {
        # Get hostname for certificate matching
        $HostName = "{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN
        
        # Find certificate matching hostname
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | 
            Where-Object { $_.Subject -match $HostName }
        
        if ($Certificate) 
        {
            # Export certificate for validation
            $CertPath = "C:\Windows\Temp\$HostName.cer"
            [System.IO.File]::WriteAllBytes($CertPath, $Certificate.RawData)
            
            # Validate certificate using certutil
            Write-Host "Validating certificate for $HostName" -ForegroundColor Green
            certutil.exe -v -urlfetch -verify $CertPath
            
            # Clean up
            Remove-Item $CertPath -Force -ErrorAction SilentlyContinue
        }
        else 
        {
            Write-Warning "No matching certificate found for $HostName"
        }
    }
    
    foreach ($DC in $DomainControllers) 
    {
        Write-Host "`nValidating certificates on: $DC" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Cyan
        
        try 
        {
            if ($Credential) 
            {
                Invoke-Command -ComputerName $DC -ScriptBlock $ScriptBlock -Credential $Credential
            }
            else 
            {
                Invoke-Command -ComputerName $DC -ScriptBlock $ScriptBlock
            }
        }
        catch 
        {
            Write-Error "Failed to validate certificate on $DC : $($_.Exception.Message)"
        }
    }
}

# Usage example
$DomainControllers = (Get-ADDomainController -Filter *).HostName
$Credentials = Get-Credential -Message "Enter credentials for Domain Controller access"
Invoke-CertutilValidation -DomainControllers $DomainControllers -Credential $Credentials
```

## Troubleshooting Common Issues

### Certificate Chain Problems

**Common certificate chain validation errors and solutions:**

| Error | Description | Solution |
|-------|-------------|----------|
| `unable to get local issuer certificate` | Root CA not in trusted store | Install root CA certificate in trusted store |
| `certificate signature failure` | Certificate tampered or corrupted | Re-issue certificate from CA |
| `certificate has expired` | Certificate past validity period | Renew certificate before expiration |
| `certificate not yet valid` | System time incorrect or certificate future-dated | Verify system time and certificate dates |
| `self signed certificate` | Certificate is self-signed | Install self-signed cert in trusted store or use proper CA |

### LDAPS Connection Failures

**Troubleshooting LDAPS connectivity issues:**

```powershell
function Diagnose-LDAPSConnectivity 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainController,
        [int]$Port = 636
    )
    
    Write-Host "Diagnosing LDAPS connectivity to $DomainController`:$Port" -ForegroundColor Yellow
    
    # Test 1: Network connectivity
    Write-Host "`n1. Testing network connectivity..." -ForegroundColor Cyan
    $TcpTest = Test-NetConnection -ComputerName $DomainController -Port $Port -WarningAction SilentlyContinue
    
    if ($TcpTest.TcpTestSucceeded) 
    {
        Write-Host "   ✓ Network connection successful" -ForegroundColor Green
    }
    else 
    {
        Write-Host "   ✗ Network connection failed" -ForegroundColor Red
        Write-Host "     - Check firewall rules" -ForegroundColor Yellow
        Write-Host "     - Verify LDAPS is enabled" -ForegroundColor Yellow
        Write-Host "     - Check network routing" -ForegroundColor Yellow
        return
    }
    
    # Test 2: Certificate validation
    Write-Host "`n2. Testing certificate validation..." -ForegroundColor Cyan
    try 
    {
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        $TcpClient.Connect($DomainController, $Port)
        $SslStream = New-Object System.Net.Security.SslStream($TcpClient.GetStream())
        $SslStream.AuthenticateAsClient($DomainController)
        
        Write-Host "   ✓ SSL/TLS handshake successful" -ForegroundColor Green
        
        $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SslStream.RemoteCertificate)
        Write-Host "   Certificate Subject: $($Certificate.Subject)" -ForegroundColor White
        Write-Host "   Certificate Issuer: $($Certificate.Issuer)" -ForegroundColor White
        Write-Host "   Valid Until: $($Certificate.NotAfter)" -ForegroundColor White
        
        # Check certificate chain
        $Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $ChainValid = $Chain.Build($Certificate)
        
        if ($ChainValid) 
        {
            Write-Host "   ✓ Certificate chain validation successful" -ForegroundColor Green
        }
        else 
        {
            Write-Host "   ✗ Certificate chain validation failed" -ForegroundColor Red
            foreach ($Status in $Chain.ChainStatus) 
            {
                Write-Host "     - $($Status.Status): $($Status.StatusInformation)" -ForegroundColor Yellow
            }
        }
    }
    catch 
    {
        Write-Host "   ✗ SSL/TLS handshake failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally 
    {
        if ($SslStream) { $SslStream.Dispose() }
        if ($TcpClient) { $TcpClient.Dispose() }
        if ($Chain) { $Chain.Dispose() }
    }
    
    # Test 3: LDAP bind test
    Write-Host "`n3. Testing LDAP bind..." -ForegroundColor Cyan
    try 
    {
        $LDAP = "LDAP://$DomainController`:$Port"
        $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($LDAP)
        $SchemaEntry = $DirectoryEntry.SchemaEntry
        
        if ($SchemaEntry) 
        {
            Write-Host "   ✓ LDAP bind successful" -ForegroundColor Green
        }
        else 
        {
            Write-Host "   ✗ LDAP bind failed" -ForegroundColor Red
        }
    }
    catch 
    {
        Write-Host "   ✗ LDAP bind failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "     - Check authentication credentials" -ForegroundColor Yellow
        Write-Host "     - Verify LDAP service is running" -ForegroundColor Yellow
    }
    finally 
    {
        if ($DirectoryEntry) { $DirectoryEntry.Dispose() }
    }
}

# Usage example
$DomainControllers = (Get-ADDomainController -Filter *).HostName
foreach ($DC in $DomainControllers) 
{
    Diagnose-LDAPSConnectivity -DomainController $DC
    Write-Host "`n" + "="*60 + "`n"
}
```

## Monitoring and Automation

### Automated Certificate Monitoring

**PowerShell script for scheduled certificate monitoring:**

```powershell
# LDAPS Certificate Monitoring Script
# Schedule this script to run daily via Task Scheduler

[CmdletBinding()]
param(
    [string]$LogPath = "C:\Logs\LDAPS-Monitoring.log",
    [string]$EmailRecipients = "admin@contoso.com",
    [string]$SMTPServer = "mail.contoso.com",
    [int]$WarningDays = 90,
    [int]$CriticalDays = 30
)

function Write-Log 
{
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

try 
{
    Write-Log "Starting LDAPS certificate monitoring"
    
    # Get all Domain Controllers
    $DomainControllers = (Get-ADDomainController -Filter *).HostName
    Write-Log "Found $($DomainControllers.Count) Domain Controllers"
    
    $Issues = @()
    
    foreach ($DC in $DomainControllers) 
    {
        try 
        {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $TcpClient.Connect($DC, 636)
            $SslStream = New-Object System.Net.Security.SslStream($TcpClient.GetStream())
            $SslStream.AuthenticateAsClient($DC)
            
            $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SslStream.RemoteCertificate)
            $DaysUntilExpiry = ($Certificate.NotAfter - (Get-Date)).Days
            
            if ($DaysUntilExpiry -le $CriticalDays) 
            {
                $Issue = [PSCustomObject]@{
                    DomainController = $DC
                    Subject = $Certificate.Subject
                    NotAfter = $Certificate.NotAfter
                    DaysUntilExpiry = $DaysUntilExpiry
                    Severity = "CRITICAL"
                }
                $Issues += $Issue
                Write-Log "CRITICAL: Certificate on $DC expires in $DaysUntilExpiry days" "ERROR"
            }
            elseif ($DaysUntilExpiry -le $WarningDays) 
            {
                $Issue = [PSCustomObject]@{
                    DomainController = $DC
                    Subject = $Certificate.Subject
                    NotAfter = $Certificate.NotAfter
                    DaysUntilExpiry = $DaysUntilExpiry
                    Severity = "WARNING"
                }
                $Issues += $Issue
                Write-Log "WARNING: Certificate on $DC expires in $DaysUntilExpiry days" "WARN"
            }
            else 
            {
                Write-Log "OK: Certificate on $DC is valid for $DaysUntilExpiry days"
            }
        }
        catch 
        {
            $Issue = [PSCustomObject]@{
                DomainController = $DC
                Subject = "CONNECTION FAILED"
                NotAfter = "N/A"
                DaysUntilExpiry = "N/A"
                Severity = "ERROR"
            }
            $Issues += $Issue
            Write-Log "ERROR: Failed to validate certificate on $DC : $($_.Exception.Message)" "ERROR"
        }
        finally 
        {
            if ($SslStream) { $SslStream.Dispose() }
            if ($TcpClient) { $TcpClient.Dispose() }
        }
    }
    
    # Send email notification if issues found
    if ($Issues -and $EmailRecipients -and $SMTPServer) 
    {
        $Subject = "LDAPS Certificate Alert - $($Issues.Count) Issues Found"
        $Body = @"
LDAPS Certificate Monitoring Report
Generated: $(Get-Date)

Issues Found: $($Issues.Count)

$($Issues | Format-Table -AutoSize | Out-String)

Please review and take appropriate action.
"@
        
        Send-MailMessage -To $EmailRecipients -Subject $Subject -Body $Body -SmtpServer $SMTPServer -From "ldaps-monitor@contoso.com"
        Write-Log "Email notification sent to $EmailRecipients"
    }
    
    Write-Log "LDAPS certificate monitoring completed successfully"
}
catch 
{
    Write-Log "LDAPS certificate monitoring failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
```

## Best Practices

### Security Best Practices

- **Certificate Validation**: Always validate the complete certificate chain
- **Private Key Protection**: Ensure private keys are properly secured
- **Certificate Renewal**: Plan certificate renewals well in advance
- **Monitoring**: Implement automated monitoring for certificate expiration
- **Documentation**: Maintain detailed records of certificate deployments

### Performance Optimization

- **Connection Pooling**: Use connection pooling for frequent LDAPS connections
- **Caching**: Cache certificate validation results where appropriate
- **Parallel Processing**: Validate multiple Domain Controllers in parallel
- **Resource Management**: Properly dispose of SSL streams and TCP connections

### Compliance Requirements

- **Audit Logging**: Log all certificate validation activities
- **Regular Reviews**: Conduct regular certificate security reviews
- **Backup Procedures**: Maintain secure backups of certificates and private keys
- **Change Management**: Follow proper change management for certificate updates

## See Also

- [Certificate Management](certificate-management.md) - Comprehensive certificate lifecycle management
- [Apply Baseline Group Policy and Security Template](apply-baseline-group-policy-and-security-template.md) - Security baseline implementation
- [Active Directory Security Configuration](../security/index.md) - AD security hardening procedures

## External References

- [How to test the CA certificate and LDAP connection over SSL/TLS (IBM)](https://www.ibm.com/support/pages/how-test-ca-certificate-and-ldap-connection-over-ssltls)
- [Configuring LDAP over SSL (Microsoft Learn)](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/enable-ldap-over-ssl-3rd-certification-authority)
- [OpenSSL Certificate Verification (OpenSSL Documentation)](https://www.openssl.org/docs/man1.1.1/man1/verify.html)
- [PowerShell Certificate Management (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/pki/)
- [Active Directory Certificate Services (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/active-directory-certificate-services-overview)

verify depth is 5

Can't use SSL_get_servername

depth=0 CN = IDMDCPRD05.MATC.Madison.Login

verify error:num=66:EE certificate key too weak

verify return:1

depth=1 DC = Login, DC = Madison, DC = MATC, CN = MCICA01

verify error:num=20:unable to get local issuer certificate

verify return:1

depth=0 CN = IDMDCPRD05.MATC.Madison.Login

verify return:1

DONE

CN = IDMDCPRD05.MATC.Madison.Login

error 20 at 0 depth lookup: unable to get local issuer certificate

error matc-dc-cert1.pem: verification failed

DC = Login, DC = Madison, DC = MATC, CN = MCICA01

error 20 at 0 depth lookup: unable to get local issuer certificate

error matc-dc-cert2.pem: verification failed

**

**

The following PowerShell script will validate the installed SSL cert on each Domain Controller:

```powershell
$DCs=Get-ADDomainController -Filter * | select -ExpandProperty hostname

$ScriptBlock={
    $HostName="{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN
    $Cert=Get-ChildItem -Path cert:LocalMachineMy | ? {$_.Subject -match $HostName}
    $FilePath="c:scripts$HostName.cer"
    certutil -v -urlfetch -verify $FilePath
}

foreach ($DC in $DCs)
{
    Invoke-Command -ComputerName $DC -ScriptBlock $ScriptBlock -Credential $creds
}
```

Example results shown below. Look at the output for errors.

```text
Issuer:
CN=MCICA01
DC=MATC
DC=Madison
DC=Login
[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)
0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD06.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD06.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 36 2e 4d 41 54 43 2e IDMDCPRD06.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 36 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.6...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): 728d2dbde8343b2658abc38f11bb4d4ac26fd5cc

Name Hash(md5): a1746256349a6bd75fbc1429b0d83df5

Cert Serial Number: 1d0001d8ec61dacb7425ceb8a800000001d8ec

0000 ec d8 01 00 00 00 a8 b8 ce 25 74 cb da 61 ec d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 33 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 33 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 4:36 AM

NotAfter: 11/27/2023 4:36 AM

Subject: CN=IDMDCPRD06.MATC.Madison.Login

Serial: 1d0001d8ec61dacb7425ceb8a800000001d8ec

SubjectAltName: Other Name:DS Object Guid=04 10 0d 59 76 7d bf 8e c1 46 bb 07 80 e4 67 66 5b 05, DNS Name=IDMDCPRD06.MATC.Madison.Login

Template: DomainController

Cert: efdd3818e8e4fe8dc2b2b8694a7270555d82cc8f

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

OK "Delta CRL (0680)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

OK "Delta CRL (0680)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/5/2023 4:05 PM

NextUpdate: 9/13/2023 4:25 AM

CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3

Delta CRL 0680:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/7/2023 4:05 PM

NextUpdate: 9/9/2023 4:25 AM

CRL: 4203206d8432188dae986ab21d319375d9f24823

Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication

Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication

CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 11:45 AM

NotAfter: 2/20/2029 11:55 AM

Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

Serial: 61000000022fcc148140855cf0000000000002

Template: SubCA

Cert: f8b246170aababcdb629e1a65cfda395d78c4746

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Expired "Base CRL (03)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>

Expired "Base CRL (03)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:

Issuer: CN=MCRCA

ThisUpdate: 2/1/2023 2:42 PM

NextUpdate: 2/22/2024 3:02 AM

CRL: 95bd64510f142a48195b6b8d7053066ec1617bed

CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 10:15 AM

NotAfter: 2/20/2039 10:25 AM

Subject: CN=MCRCA

Serial: 46ec1044f89f81aa401aad4340a7767f

Cert: 15681660643728508078bac9a48d95b9778d42d1

Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)

Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:

Chain: b5c88c49ba27e91ef3e0b361b2ba15176ecebff4

Full chain:

Chain: 89350a2bf63781ae5899c84dc5bef0cba1d22418

------------------------------------

Verified Issuance Policies: None

Verified Application Policies:

1.3.6.1.5.5.7.3.2 Client Authentication

1.3.6.1.5.5.7.3.1 Server Authentication

Leaf certificate revocation check passed

CertUtil: -verify command completed successfully.

Issuer:

CN=MCICA01

DC=MATC

DC=Madison

DC=Login

[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD07.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD07.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 37 2e 4d 41 54 43 2e IDMDCPRD07.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 37 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.7...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): b2283a197289a44a7f04054f1fb8bdb8c53301ac

Name Hash(md5): 4b8b37d30cbe24434bc26faf4b2019f8

Cert Serial Number: 1d0001d8ed5934f230f36107d400000001d8ed

0000 ed d8 01 00 00 00 d4 07 61 f3 30 f2 34 59 ed d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 35 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 35 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 5:36 AM

NotAfter: 11/27/2023 5:36 AM

Subject: CN=IDMDCPRD07.MATC.Madison.Login

Serial: 1d0001d8ed5934f230f36107d400000001d8ed

SubjectAltName: Other Name:DS Object Guid=04 10 f7 c9 4e 21 f2 1b 64 44 b6 81 02 16 4b 3f 0b 11, DNS Name=IDMDCPRD07.MATC.Madison.Login

Template: DomainController

Cert: 2c881217dec461466be25257e19d6c0d32b1831b

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

OK "Delta CRL (0680)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

OK "Delta CRL (0680)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/5/2023 4:05 PM

NextUpdate: 9/13/2023 4:25 AM

CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3

Delta CRL 0680:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/7/2023 4:05 PM

NextUpdate: 9/9/2023 4:25 AM

CRL: 4203206d8432188dae986ab21d319375d9f24823

Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication

Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication

CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 11:45 AM

NotAfter: 2/20/2029 11:55 AM

Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

Serial: 61000000022fcc148140855cf0000000000002

Template: SubCA

Cert: f8b246170aababcdb629e1a65cfda395d78c4746

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Expired "Base CRL (03)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>

Expired "Base CRL (03)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:

Issuer: CN=MCRCA

ThisUpdate: 2/1/2023 2:42 PM

NextUpdate: 2/22/2024 3:02 AM

CRL: 95bd64510f142a48195b6b8d7053066ec1617bed

CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 10:15 AM

NotAfter: 2/20/2039 10:25 AM

Subject: CN=MCRCA

Serial: 46ec1044f89f81aa401aad4340a7767f

Cert: 15681660643728508078bac9a48d95b9778d42d1

Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)

Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:

Chain: b7e55f737dece5fbe5eb89297d7d723b417c204f

Full chain:

Chain: e3f847c9a0c65cca23edd248b66fbc377bce7783

------------------------------------

Verified Issuance Policies: None

Verified Application Policies:

1.3.6.1.5.5.7.3.2 Client Authentication

1.3.6.1.5.5.7.3.1 Server Authentication

Leaf certificate revocation check passed

CertUtil: -verify command completed successfully.

Issuer:

CN=MCICA01

DC=MATC

DC=Madison

DC=Login

[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD05.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD05.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 35 2e 4d 41 54 43 2e IDMDCPRD05.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 35 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.5...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): 2c0ea41f62ac2c31b54460a27c8c288379be22db

Name Hash(md5): 11ac3051bd85043a2bef847fdaaf258d

Cert Serial Number: 1d0001d8ee8b21ecc717b0446500000001d8ee

0000 ee d8 01 00 00 00 65 44 b0 17 c7 ec 21 8b ee d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 38 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 38 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 5:37 AM

NotAfter: 11/27/2023 5:37 AM

Subject: CN=IDMDCPRD05.MATC.Madison.Login

Serial: 1d0001d8ee8b21ecc717b0446500000001d8ee

SubjectAltName: Other Name:DS Object Guid=04 10 de fb e1 6c 12 75 12 4d 85 ae 6e 84 94 3d 50 7a, DNS Name=IDMDCPRD05.MATC.Madison.Login

Template: DomainController

Cert: 3a532f19113ca84ec7fb925ce086057b29dea022

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0
[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint
Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint
Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>
Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>
Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>
Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0
[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0
[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0
[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0
[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0
[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0
[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint
OK "Delta CRL (0680)" Time: 0
[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>
OK "Delta CRL (0680)" Time: 0
[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:
Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
ThisUpdate: 9/5/2023 4:05 PM
NextUpdate: 9/13/2023 4:25 AM
CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3
Delta CRL 0680:
Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
ThisUpdate: 9/7/2023 4:05 PM
NextUpdate: 9/9/2023 4:25 AM
CRL: 4203206d8432188dae986ab21d319375d9f24823
Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication
Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication
CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0
Issuer: CN=MCRCA
NotBefore: 2/20/2019 11:45 AM
NotAfter: 2/20/2029 11:55 AM
Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
Serial: 61000000022fcc148140855cf0000000000002
Template: SubCA
Cert: f8b246170aababcdb629e1a65cfda395d78c4746
Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)
Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0
[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority
Verified "Certificate (0)" Time: 0
[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>
Verified "Certificate (0)" Time: 0
[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0
[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint
Expired "Base CRL (03)" Time: 0
[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>
Expired "Base CRL (03)" Time: 0
[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:
Issuer: CN=MCRCA
ThisUpdate: 2/1/2023 2:42 PM
NextUpdate: 2/22/2024 3:02 AM
CRL: 95bd64510f142a48195b6b8d7053066ec1617bed
CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0
Issuer: CN=MCRCA
NotBefore: 2/20/2019 10:15 AM
NotAfter: 2/20/2039 10:25 AM
Subject: CN=MCRCA
Serial: 46ec1044f89f81aa401aad4340a7767f
Cert: 15681660643728508078bac9a48d95b9778d42d1
Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)
Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)
Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:
Chain: ff271dee5771bf249cac826a7f417f35f3345178
Full chain:
Chain: 145ded082019de1d35fb16c7048659978b508cc9

------------------------------------

Verified Issuance Policies: None
Verified Application Policies:
1.3.6.1.5.5.7.3.2 Client Authenticatio
1.3.6.1.5.5.7.3.1 Server Authentication
Leaf certificate revocation check passed
CertUtil: -verify command completed successfully.
```

## References

[How to test the CA certificate and LDAP connection over SSL/TLS (ibm.com)](https://www.ibm.com/support/pages/how-test-ca-certificate-and-ldap-connection-over-ssltls)
