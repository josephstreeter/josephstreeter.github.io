---
title: "InCommon Silver Compliance Security Settings"
description: "Complete Active Directory security configuration guide for InCommon Silver certification compliance"
tags: ["incommon", "compliance", "active-directory", "security", "authentication", "identity-provider"]
category: "security"
subcategory: "compliance"
difficulty: "advanced"
last_updated: "2025-07-05"
applies_to: ["Active Directory", "Windows Server 2016+", "InCommon Silver", "Higher Education"]
compliance_framework: ["InCommon Silver", "NIST SP 800-63", "SAML 2.0"]
---

## Overview

This guide provides comprehensive implementation details for configuring Active Directory security settings to achieve InCommon Silver compliance. InCommon Silver certification ensures that identity providers meet enhanced security standards for protecting authentication credentials and communications in higher education environments.

**Current Status (July 2025):** This guide reflects current InCommon Silver requirements and modern Windows Server security capabilities.

## Executive Summary

InCommon Silver compliance requires implementing specific security controls to protect authentication secrets and communications. This certification is essential for higher education institutions that need to:

- Participate in federated identity ecosystems
- Meet enhanced security requirements for sensitive applications
- Comply with regulatory and institutional security policies
- Protect against credential theft and authentication attacks

### Key Security Requirements

The InCommon Silver standard mandates several critical security controls:

- **Stored Authentication Secrets Protection** - Credentials must not be stored in plaintext
- **Protected Channel Communications** - All authentication traffic must use encrypted channels
- **Replay Attack Resistance** - Authentication protocols must prevent replay attacks
- **Eavesdropper Attack Protection** - Communications must resist interception attacks
- **Industry Standard Cryptography** - Modern cryptographic algorithms and protocols required

## InCommon Silver Requirements and Implementation

### 4.2.3.4 Stored Authentication Secrets

**Requirement:** Authentication Secrets shall not be stored as plaintext. Access to encrypted stored Secrets and to decrypted copies shall be protected by discretionary access controls that limit access to administrators and applications that require access.

**Approved Implementation Methods:**

1. **Salted Hash Storage** - Authentication Secrets concatenated with variable salt and hashed using industry standard algorithms
2. **Encrypted Storage** - Secrets stored in encrypted form using industry standard algorithms, decrypted only when immediately required
3. **NIST SP 800-63 Level 3/4** - Any method meeting NIST SP 800-63 Level 3 or 4 requirements

#### Required Active Directory Security Settings

| Security Policy | Setting | Value | Purpose |
| --------------- | ------- | ----- | ------- |
| Network security: Do not store LAN Manager hash value on next password change | Enabled | `1` | Prevents storage of weak LM hashes |

#### Implementation Details

**Group Policy Path:** `Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options`

**Registry Location:** `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa`
**Registry Value:** `NoLMHash` = `1` (DWORD)

**PowerShell Verification:**

```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "NoLMHash"
```

### 4.2.3.5 Protected Authentication Secrets

**Requirement:** All authentication secret communications must use protected channels with appropriate access controls and encryption.

**Key Requirements:**

1. Credential Store communications require protected channels for provisioning operations
2. Authentication verification between services should use protected channels
3. IdP operators must have policies for minimizing credential exposure risk

#### Protected Channel Security Settings

| Security Policy | Setting | Value | Purpose |
| --------------- | ------- | ----- | ------- |
| Domain Controller: LDAP server signing requirements | Require signing | `2` | Forces LDAP communication signing |
| Network security: LDAP client signing requirements | Require signing | `2` | Forces LDAP client signing |

#### Protected Channel Implementation

**Group Policy Paths:**

- Server Setting: `Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options > Domain controller: LDAP server signing requirements`
- Client Setting: `Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options > Network security: LDAP client signing requirements`

**Registry Locations:**

- Server: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\LDAPServerIntegrity` = `2` (DWORD)
- Client: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ldap\ldapclientintegrity` = `2` (DWORD)

**PowerShell Configuration:**

```powershell
# Configure LDAP server signing
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -Value 2

# Configure LDAP client signing  
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ldap" -Name "ldapclientintegrity" -Value 2
```

### 4.2.5.1 Resist Replay Attack

**Requirement:** The authentication process must ensure that it is impractical to achieve successful authentication by recording and replaying a previous authentication message.

#### Replay Attack Prevention Settings

| Security Policy | Setting | Value | Purpose |
| --------------- | ------- | ----- | ------- |
| Domain Controller: LDAP server signing requirements | Require signing | `2` | Prevents LDAP replay attacks |
| Network security: LDAP client signing requirements | Require signing | `2` | Ensures client-side replay protection |

### 4.2.5.2 Resist Eavesdropper Attack

**Requirement:** The authentication protocol must resist an eavesdropper attack. Any eavesdropper who records all messages between a Subject and Verifier must find it impractical to learn the Authentication Secret or obtain impersonation information.

#### Eavesdropper Attack Prevention Settings

| Security Policy | Setting | Value | Purpose |
| --------------- | ------- | ----- | ------- |
| Domain Controller: LDAP server signing requirements | Require signing | `2` | Prevents credential interception |
| Network security: LDAP client signing requirements | Require signing | `2` | Protects client communications |
| Network security: LAN Manager authentication level | Send NTLMv2 response only. Refuse LM & NTLM | `5` | Enforces strongest authentication |

#### Authentication Level Implementation

**Group Policy Path:** `Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options > Network security: LAN Manager authentication level`

**Registry Location:** `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel` = `5` (DWORD)

**PowerShell Configuration:**

```powershell
# Set LAN Manager authentication level to highest security
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 5
```

### 4.2.5.3 Secure Communication

**Requirement:** Industry standard cryptographic operations are required between Subject and IdP to ensure use of Protected Channels for communication.

#### Secure Communication Settings

| Security Policy | Setting | Value | Purpose |
| --------------- | ------- | ----- | ------- |
| Domain Controller: LDAP server signing requirements | Require signing | `2` | Ensures encrypted LDAP communications |
| Network security: LDAP client signing requirements | Require signing | `2` | Mandates client-side encryption |

## Additional Security Requirements

### RADIUS Authentication Security

**Requirement:** RADIUS clients must use PEAP-MS-CHAPv2 and not MS-CHAPv2 alone.

**Implementation:** Configure Network Policy Server (NPS) to require PEAP authentication:

```powershell
# Configure NPS for PEAP-MS-CHAPv2
netsh nps set config parameter="RequireEncryption" value="True"
```

### Intrusion Detection and Monitoring

**Requirements:**

1. **NTLMv1 Detection** - Deploy monitoring to detect legacy NTLMv1 authentication attempts
2. **LDAP Clear Bind Detection** - Monitor for unencrypted LDAP binds
3. **SASL Signing Audit** - Enable auditing for SASL binds without required signing

#### Audit Policy Configuration

**Enable LDAP Diagnostics:**

```powershell
# Enable LDAP interface events logging
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
Set-ItemProperty -Path $regPath -Name "16 LDAP Interface Events" -Value 2
```

**Audit Events to Monitor:**

- Event ID 2887: Unsigned LDAP binds summary
- Event ID 2889: Specific unsigned LDAP bind attempts
- Event ID 2888: Rejected unsigned bind attempts

## Compatibility Impact and Mitigation

### Modern System Compatibility

**Current Status (2025):** The security settings in this guide are fully compatible with all supported Windows versions and modern applications.

**Supported Systems:**

- Windows Server 2016 and later
- Windows 10 version 1607 and later
- Windows 11 (all versions)
- Modern LDAP clients with TLS support

### Legacy System Considerations

> **Warning:** The following legacy systems are no longer supported by Microsoft and should be migrated to modern alternatives.

| Legacy System | Impact | Recommended Action |
| ------------- | ------ | ------------------ |
| Windows Server 2008/2008 R2 | End of extended support | Migrate to Windows Server 2019+ |
| Windows 7 | End of extended support | Upgrade to Windows 10/11 |
| Samba < 4.0 | Compatibility issues | Upgrade to Samba 4.15+ |

### Application Compatibility Testing

Before implementing these settings in production:

1. **Test LDAP Applications** - Verify all applications properly support signed LDAP communications
2. **Check Third-Party Tools** - Ensure monitoring and management tools support modern authentication
3. **Validate Network Services** - Test RADIUS, DNS, and other network services

## Verification and Validation

### PowerShell Verification Script

Use this comprehensive script to verify all InCommon Silver settings:

```powershell
# InCommon Silver Compliance Verification Script
Write-Host "Verifying InCommon Silver Compliance Settings..." -ForegroundColor Green

# Check LM Hash Storage
$noLMHash = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "NoLMHash" -ErrorAction SilentlyContinue
Write-Host "LM Hash Storage Disabled: $($noLMHash.NoLMHash -eq 1)" -ForegroundColor $(if($noLMHash.NoLMHash -eq 1){"Green"}else{"Red"})

# Check LDAP Server Signing
$ldapServerSigning = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -ErrorAction SilentlyContinue
Write-Host "LDAP Server Signing Required: $($ldapServerSigning.LDAPServerIntegrity -eq 2)" -ForegroundColor $(if($ldapServerSigning.LDAPServerIntegrity -eq 2){"Green"}else{"Red"})

# Check LDAP Client Signing
$ldapClientSigning = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ldap" -Name "ldapclientintegrity" -ErrorAction SilentlyContinue
Write-Host "LDAP Client Signing Required: $($ldapClientSigning.ldapclientintegrity -eq 2)" -ForegroundColor $(if($ldapClientSigning.ldapclientintegrity -eq 2){"Green"}else{"Red"})

# Check LAN Manager Authentication Level
$lmAuthLevel = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -ErrorAction SilentlyContinue
Write-Host "LAN Manager Auth Level (NTLMv2 Only): $($lmAuthLevel.LmCompatibilityLevel -eq 5)" -ForegroundColor $(if($lmAuthLevel.LmCompatibilityLevel -eq 5){"Green"}else{"Red"})

# Check LDAP Diagnostics
$ldapDiag = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "16 LDAP Interface Events" -ErrorAction SilentlyContinue
Write-Host "LDAP Diagnostics Enabled: $($ldapDiag.'16 LDAP Interface Events' -ge 2)" -ForegroundColor $(if($ldapDiag.'16 LDAP Interface Events' -ge 2){"Green"}else{"Yellow"})
```

### Group Policy Verification

Verify settings through Group Policy Management:

1. Open **Group Policy Management Console**
2. Navigate to **Default Domain Controllers Policy**
3. Check **Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options**
4. Verify the following policies are set correctly:
   - Domain controller: LDAP server signing requirements = **Require signing**
   - Network security: Do not store LAN Manager hash value on next password change = **Enabled**
   - Network security: LDAP client signing requirements = **Require signing**
   - Network security: LAN Manager authentication level = **Send NTLMv2 response only. Refuse LM & NTLM**

### Event Log Monitoring

Monitor these Windows Event Logs for compliance verification:

**Directory Service Log (Applications and Services Logs > Directory Service):**

- Event ID 2887: Summary of unsigned LDAP binds
- Event ID 2889: Specific unsigned LDAP bind attempts  
- Event ID 2888: Rejected unsigned bind attempts

**Security Log:**

- Event ID 4625: Failed logon attempts using weak authentication
- Event ID 4768: Kerberos TGT requests
- Event ID 4776: NTLM authentication attempts

## Troubleshooting Common Issues

### Issue: Applications Cannot Connect to LDAP

**Symptoms:** Applications fail to authenticate after enabling LDAP signing

**Resolution:**

1. Verify application supports LDAP signing
2. Check certificates are properly installed
3. Test with LDAP over SSL (LDAPS) on port 636
4. Use `ldp.exe` to test LDAP connectivity

### Issue: Legacy Systems Authentication Failures  

**Symptoms:** Older systems cannot authenticate after implementing settings

**Resolution:**

1. Identify systems using Event ID 2889
2. Upgrade systems to supported versions
3. Configure applications for modern authentication
4. Implement staged deployment for testing

### Issue: Performance Impact

**Symptoms:** Increased CPU usage or slower authentication

**Resolution:**

1. Monitor domain controller performance
2. Scale domain controllers if needed
3. Optimize network connectivity
4. Consider LDAP connection pooling

## References and Additional Resources

### Official Documentation

- [InCommon Silver Documentation](https://incommon.org/federation/silver/index.md)
- [NIST SP 800-63B: Authentication and Lifecycle Management](https://pages.nist.gov/800-63-3/sp800-63b.html)
- [Microsoft LDAP Signing Requirements](https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/enable-ldap-signing-in-windows-server)

### Related Security Guides

- [LDAP Channel Binding and LDAP Signing Implementation](ldap-channel-binding-and-ldap-signing.md)
- [Active Directory Security Best Practices](../Security/index.md)
- [Identity Management](../../iam/index.md)

### Support Resources

- [Microsoft Security Compliance Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=55319)
- [InCommon Support Documentation](https://spaces.at.internet2.edu/display/InCFederation/InCommon+Federation+Support)
- [Windows Server Security Baseline](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines)
