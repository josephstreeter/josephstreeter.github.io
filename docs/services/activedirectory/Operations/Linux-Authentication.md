---
title: Linux Active Directory Authentication
description: Comprehensive guide for configuring Linux systems to authenticate against Active Directory using modern methods including SSSD, Winbind, and Kerberos
author: IT Operations Team
ms.date: 2025-01-01
ms.topic: how-to
ms.service: active-directory
ms.subservice: authentication
keywords: linux, active directory, authentication, sssd, kerberos, winbind, domain join
---

## Linux Active Directory Authentication

## Overview

Linux hosts can be configured to authenticate against Active Directory using various methods, enabling centralized user management and single sign-on capabilities. This guide covers modern approaches including SSSD (recommended), Winbind, and Kerberos-only authentication.

**Supported Linux Distributions:**

- Red Hat Enterprise Linux 8/9
- CentOS Stream 8/9  
- Ubuntu 20.04/22.04 LTS
- SUSE Linux Enterprise 15
- Rocky Linux 8/9
- AlmaLinux 8/9

## Prerequisites

Before beginning configuration, ensure the following requirements are met:

### System Requirements

- **Time Synchronization**: System time must be synchronized within 5 minutes of Active Directory
- **DNS Resolution**: Proper DNS configuration pointing to AD domain controllers
- **Network Connectivity**: Ports 53 (DNS), 88 (Kerberos), 389/636 (LDAP), 445 (SMB) must be accessible
- **Administrative Access**: Root or sudo privileges on the Linux system
- **Active Directory Permissions**: Account with domain join privileges

### Security Considerations

- **Encryption**: Always use encrypted connections (LDAPS, Kerberos)
- **Certificate Validation**: Validate AD certificates to prevent man-in-the-middle attacks
- **Privilege Separation**: Limit domain user privileges on Linux systems
- **Audit Logging**: Enable comprehensive authentication logging
- **Home Directory Permissions**: Secure home directory creation and permissions

## Authentication Methods

### Method 1: SSSD (Recommended)

**System Security Services Daemon (SSSD)** is the modern, preferred method for Linux AD integration. It provides:

- **Caching**: Offline authentication capability
- **Performance**: Efficient LDAP queries and connection pooling
- **Security**: Built-in encryption and certificate validation
- **Flexibility**: Support for multiple identity providers
- **Maintenance**: Active development and security updates

### Method 2: Winbind (Legacy)

**Winbind** is part of the Samba suite and provides AD integration through:

- **SMB/CIFS Integration**: Native Windows protocol support
- **RID Mapping**: Consistent UID/GID mapping
- **Group Membership**: Full Windows group support

*Note: Winbind is considered legacy and SSSD is recommended for new deployments.*

### Method 3: Kerberos with Local Users

**Kerberos-only authentication** provides:

- **Simplified Setup**: Minimal configuration required
- **Security**: Strong cryptographic authentication
- **Limitations**: Requires local user account creation

### Unsupported Methods

- **Third-party Commercial Solutions**: Not covered in this guide
- **Plain LDAP Authentication**: Insecure and deprecated
- **Custom PAM Modules**: Not recommended for production useuthentication

## Summary

Linux hosts can be configured to allow local console logon or remote logon though a service such as SSH. The configuration steps will vary depending on the Linux distribution and version used. Linux hosts will utilize the Kerberos authentication service that is integrated with Active Directory

## Support

Support from the Campus Active Directory Service Team for Active Directory authentication on Linux hosts will be limited to distributions and versions that are supported by the DoIT Systems Engineering Linux Team. All other distributions and versions will be supported as â€œBest Effort.â€ While basic support of supported distributions and versions will be provided at no cost, advanced support may incur charges.

- **Plain LDAP Authentication**: Insecure and deprecated
- **Custom PAM Modules**: Not recommended for production use

## Technical Components

- **Active Directory**: Microsoft's directory service providing centralized authentication and authorization
- **SSSD**: System Security Services Daemon - modern Linux identity management
- **Samba/Winbind**: Open source SMB/CIFS implementation with AD integration
- **Kerberos**: Network authentication protocol using symmetric key cryptography
- **LDAP/LDAPS**: Lightweight Directory Access Protocol (with SSL/TLS encryption)
- **DNS**: Domain Name System for service discovery and name resolution
- **Chrony/NTP**: Network time protocol for clock synchronization
- **NSS**: Name Service Switch for user/group information lookup
- **PAM**: Pluggable Authentication Modules for flexible authentication

## Configuration Guide

### Method 1: SSSD Configuration (Recommended)

SSSD is the modern, preferred approach for Active Directory integration on Linux systems.

#### RHEL/CentOS/Rocky/Alma Linux

1. **Install required packages:**

   ```bash
   sudo dnf install -y sssd realmd oddjob oddjob-mkhomedir adcli samba-common-tools chrony
   ```

2. **Configure time synchronization:**

   ```bash
   sudo systemctl enable chronyd
   sudo systemctl start chronyd
   
   # Configure chrony for your domain controllers
   sudo tee -a /etc/chrony.conf << 'EOF'
   server your-dc1.example.com iburst
   server your-dc2.example.com iburst
   EOF
   
   sudo systemctl restart chronyd
   ```

3. **Configure DNS resolution:**

   ```bash
   # Ensure your domain controllers are in /etc/resolv.conf
   sudo tee /etc/resolv.conf << 'EOF'
   search example.com
   nameserver 192.168.1.10
   nameserver 192.168.1.11
   EOF
   ```

4. **Test AD connectivity:**

   ```bash
   # Test DNS resolution
   nslookup your-domain.com
   
   # Test SRV records
   dig _kerberos._tcp.your-domain.com SRV
   dig _ldap._tcp.your-domain.com SRV
   ```

5. **Join the domain using realmd:**

   ```bash
   # Discover the domain
   sudo realm discover your-domain.com
   
   # Join the domain
   sudo realm join --user=administrator your-domain.com
   
   # Verify join status
   sudo realm list
   ```

6. **Configure SSSD settings:**

   Edit `/etc/sssd/sssd.conf`:

   ```ini
   [sssd]
   domains = your-domain.com
   config_file_version = 2
   services = nss, pam
   
   [domain/your-domain.com]
   ad_domain = your-domain.com
   krb5_realm = YOUR-DOMAIN.COM
   realmd_tags = manages-system joined-with-adcli
   cache_credentials = True
   id_provider = ad
   krb5_store_password_if_offline = True
   default_shell = /bin/bash
   ldap_id_mapping = True
   use_fully_qualified_names = False
   fallback_homedir = /home/%u
   access_provider = ad
   ad_access_filter = (objectClass=user)
   
   # Security settings
   ldap_tls_reqcert = demand
   ldap_tls_cacert = /etc/ssl/certs/ca-certificates.crt
   ```

7. **Configure home directory creation:**

   ```bash
   sudo authselect enable-feature with-mkhomedir
   sudo systemctl enable oddjobd
   sudo systemctl start oddjobd
   ```

8. **Start and enable SSSD:**

   ```bash
   sudo systemctl enable sssd
   sudo systemctl start sssd
   ```

#### Ubuntu Configuration

1. **Install required packages:**

   ```bash
   sudo apt update
   sudo apt install -y sssd-ad sssd-tools realmd adcli packagekit chrony
   ```

2. **Configure time synchronization:**

   ```bash
   sudo systemctl enable chrony
   sudo systemctl start chrony
   
   # Add domain controllers to chrony
   echo "server your-dc1.example.com iburst" | sudo tee -a /etc/chrony/chrony.conf
   echo "server your-dc2.example.com iburst" | sudo tee -a /etc/chrony/chrony.conf
   
   sudo systemctl restart chrony
   ```

3. **Follow steps 3-8 from RHEL configuration above**

### Method 2: Winbind Configuration (Legacy)

*Note: This method is provided for compatibility with existing installations. SSSD is recommended for new deployments.*

#### RHEL/CentOS Configuration

1. **Install packages:**

   ```bash
   sudo dnf install -y samba samba-winbind samba-winbind-clients krb5-workstation chrony
   ```

2. **Configure hostname:**

   ```bash
   sudo hostnamectl set-hostname client1.your-domain.com
   ```

3. **Configure Samba for AD:**

   Edit `/etc/samba/smb.conf`:

   ```ini
   [global]
   workgroup = YOURDOMAIN
   realm = YOUR-DOMAIN.COM
   security = ads
   
   # ID mapping
   idmap config * : backend = tdb
   idmap config * : range = 10000-999999
   idmap config YOURDOMAIN : backend = rid
   idmap config YOURDOMAIN : range = 1000000-19999999
   
   # Winbind settings
   winbind use default domain = yes
   winbind offline logon = yes
   winbind refresh tickets = yes
   winbind expand groups = 2
   
   # Template settings
   template shell = /bin/bash
   template homedir = /home/%U
   
   # Security
   client signing = mandatory
   client use spnego = yes
   ```

4. **Configure Kerberos:**

   Edit `/etc/krb5.conf`:

   ```ini
   [libdefaults]
   default_realm = YOUR-DOMAIN.COM
   dns_lookup_realm = true
   dns_lookup_kdc = true
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
   
   [realms]
   YOUR-DOMAIN.COM = {
   }
   
   [domain_realm]
   .your-domain.com = YOUR-DOMAIN.COM
   your-domain.com = YOUR-DOMAIN.COM
   ```

5. **Join domain:**

   ```bash
   sudo net ads join -U administrator
   ```

6. **Configure NSS and PAM:**

   ```bash
   sudo authselect select winbind with-mkhomedir
   ```

7. **Start services:**

   ```bash
   sudo systemctl enable winbind smb nmb
   sudo systemctl start winbind smb nmb
   ```

### Kerberos-Only Authentication Configuration

This method provides Kerberos authentication while maintaining local user accounts.

1. **Install Kerberos packages:**

   ```bash
   # RHEL/CentOS
   sudo dnf install -y krb5-workstation pam_krb5 chrony
   
   # Ubuntu
   sudo apt install -y krb5-user libpam-krb5 chrony
   ```

2. **Configure Kerberos client:**

   Edit `/etc/krb5.conf`:

   ```ini
   [libdefaults]
   default_realm = YOUR-DOMAIN.COM
   dns_lookup_realm = true
   dns_lookup_kdc = true
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
   
   [realms]
   YOUR-DOMAIN.COM = {
   }
   
   [domain_realm]
   .your-domain.com = YOUR-DOMAIN.COM
   your-domain.com = YOUR-DOMAIN.COM
   ```

3. **Create local user accounts:**

   ```bash
   # Create user with AD username
   sudo useradd -m -s /bin/bash john.doe
   
   # Set up Kerberos principal mapping
   echo "john.doe@YOUR-DOMAIN.COM john.doe" | sudo tee -a /etc/krb5.equiv
   ```

4. **Configure PAM for Kerberos:**

   Edit `/etc/pam.d/system-auth` (or use authselect):

   ```bash
   sudo authselect select minimal with-krb5
   ```

## Verification and Testing

### Test Authentication

1. **Test user lookup:**

   ```bash
   # SSSD/Winbind
   getent passwd john.doe
   getent group "domain users"
   
   # Check ID mapping
   id john.doe
   ```

2. **Test Kerberos authentication:**

   ```bash
   # Get Kerberos ticket
   kinit john.doe@YOUR-DOMAIN.COM
   
   # List tickets
   klist
   
   # Test SSH authentication
   ssh john.doe@localhost
   ```

3. **Test home directory creation:**

   ```bash
   su - john.doe
   pwd  # Should be in /home/john.doe
   ```

### Verify Services

```bash
# Check service status
sudo systemctl status sssd         # For SSSD
sudo systemctl status winbind      # For Winbind

# Check logs
sudo journalctl -u sssd -f         # SSSD logs
sudo tail -f /var/log/samba/log.wb-*  # Winbind logs
```

## Troubleshooting

### Common Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Time skew | Authentication failures | Synchronize time with `chrony` |
| DNS resolution | Domain join fails | Verify DNS points to domain controllers |
| Certificate errors | LDAPS failures | Install/update CA certificates |
| Home directory not created | Login succeeds but no home dir | Enable and start `oddjobd` service |
| Permission denied | User exists but can't login | Check group membership and access controls |

### Diagnostic Commands

```bash
# Test domain connectivity
realm discover your-domain.com

# Check Kerberos
kinit -V username@DOMAIN.COM
klist -e

# Test LDAP connectivity
ldapsearch -H ldap://dc.domain.com -x -s base

# Check SSSD status
sudo sssctl status
sudo sssctl domain-list

# Winbind testing
sudo wbinfo -t
sudo wbinfo -u
sudo wbinfo -g
```

### Log Analysis

```bash
# SSSD logs
sudo tail -f /var/log/sssd/*.log

# System authentication logs
sudo tail -f /var/log/secure     # RHEL/CentOS
sudo tail -f /var/log/auth.log   # Ubuntu

# Kerberos logs
sudo tail -f /var/log/krb5kdc.log
```

## Security Best Practices

### System Hardening

1. **Use encrypted connections**: Always enable LDAPS and certificate validation
2. **Implement access controls**: Use AD groups to control Linux access
3. **Enable audit logging**: Monitor authentication events
4. **Regular updates**: Keep packages and certificates current
5. **Principle of least privilege**: Limit user permissions

### Configuration Security

```bash
# Set secure permissions on configuration files
sudo chmod 600 /etc/sssd/sssd.conf
sudo chmod 600 /etc/samba/smb.conf
sudo chmod 644 /etc/krb5.conf

# Enable SELinux/AppArmor
sudo systemctl enable selinux
```

### Access Control Example

Configure SSSD for group-based access:

```ini
[domain/your-domain.com]
access_provider = ad
ad_access_filter = (memberOf=CN=Linux-Users,OU=Groups,DC=your-domain,DC=com)
```

## Monitoring and Maintenance

### Regular Maintenance Tasks

1. **Certificate renewal**: Monitor AD certificate expiration
2. **Time synchronization**: Verify chrony is functioning
3. **Log rotation**: Ensure logs don't fill disk space
4. **Security updates**: Apply patches regularly
5. **Backup configuration**: Maintain config file backups

### Performance Monitoring

```bash
# Monitor SSSD performance
sudo sssctl logs-fetch

# Check cache status
sudo sssctl cache-expire --everything

# Monitor authentication latency
time su - username
```

## Conclusion

This guide provides comprehensive coverage of Linux Active Directory authentication methods. SSSD is recommended for new deployments due to its modern architecture, security features, and active maintenance. Regardless of the chosen method, proper time synchronization, DNS configuration, and security practices are essential for reliable operation.

For production environments, implement proper monitoring, logging, and maintenance procedures to ensure continued functionality and security.
