---
title: Windows DHCP Installation & Setup
description: Complete guide to installing and configuring Microsoft Windows DHCP Server role in enterprise environments
author: Joseph Streeter
date: 2025-09-12
tags: [windows-dhcp-installation, dhcp-setup, windows-server-roles, dhcp-configuration]
---

This guide provides step-by-step instructions for installing and performing initial configuration of the Windows DHCP Server role.

## 📋 Prerequisites

### System Requirements

- Windows Server 2019/2022 or later
- Administrative privileges on the target server
- Static IP address configuration
- Active Directory domain membership (recommended)

### Network Planning

- Determine IP address ranges for DHCP scopes
- Identify DNS servers and default gateways
- Plan for DHCP server placement and redundancy
- Consider DHCP relay agent requirements

## 🚀 Installation Process

### Using Server Manager

1. **Open Server Manager**
2. **Select "Add Roles and Features"**
3. **Choose "Role-based or feature-based installation"**
4. **Select target server**
5. **Select "DHCP Server" from Server Roles**
6. **Add required features when prompted**
7. **Complete the installation wizard**

### Using PowerShell

```powershell
# Install DHCP Server role
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Verify installation
Get-WindowsFeature -Name DHCP
```

## ⚙️ Initial Configuration

### Post-Installation Configuration Wizard

After installation, complete the configuration wizard:

1. **Authorize DHCP Server in Active Directory**
2. **Create DHCP Administrators security group**
3. **Create DHCP Users security group**
4. **Configure initial scope (optional)**

### PowerShell Configuration

```powershell
# Authorize DHCP server in Active Directory
Add-DhcpServerInDC -DnsName "DHCP-Server01.contoso.com" -IPAddress 192.168.1.10

# Create security groups
Add-DhcpServerSecurityGroup

# Configure server options
Set-DhcpServerv4OptionValue -OptionId 6 -Value "192.168.1.10","192.168.1.11"  # DNS Servers
Set-DhcpServerv4OptionValue -OptionId 15 -Value "contoso.com"                  # DNS Domain Name
```

## 🔧 Basic Configuration Tasks

### Creating Your First Scope

```powershell
# Create a new DHCP scope
Add-DhcpServerv4Scope -Name "Main Office Network" `
                      -StartRange 192.168.1.100 `
                      -EndRange 192.168.1.200 `
                      -SubnetMask 255.255.255.0 `
                      -Description "Primary office network scope"

# Configure scope options
Set-DhcpServerv4OptionValue -ScopeId 192.168.1.0 -OptionId 3 -Value "192.168.1.1"   # Default Gateway
Set-DhcpServerv4OptionValue -ScopeId 192.168.1.0 -OptionId 6 -Value "192.168.1.10"  # DNS Server

# Activate the scope
Set-DhcpServerv4Scope -ScopeId 192.168.1.0 -State Active
```

## 🛡️ Security Configuration

### DHCP Server Authorization

```powershell
# Check authorization status
Get-DhcpServerInDC

# Authorize server if not already done
Add-DhcpServerInDC -DnsName "DHCP-Server01.contoso.com" -IPAddress 192.168.1.10
```

### Security Group Configuration

```powershell
# Add users to DHCP Administrators group
Add-ADGroupMember -Identity "DHCP Administrators" -Members "DHCPAdmin1","DHCPAdmin2"

# Add users to DHCP Users group
Add-ADGroupMember -Identity "DHCP Users" -Members "DHCPUser1","DHCPUser2"
```

## 📊 Verification and Testing

### Verify Installation

```powershell
# Check DHCP service status
Get-Service DHCPServer

# Verify DHCP server configuration
Get-DhcpServerSetting

# Test DHCP server functionality
Get-DhcpServerv4Statistics
```

### Test DHCP Functionality

1. **Configure a test client** for DHCP
2. **Release and renew IP address** on test client
3. **Verify lease assignment** in DHCP console
4. **Test connectivity** to network resources

## 🔧 Troubleshooting Common Issues

### Authorization Problems

```powershell
# Check if server is authorized
Get-DhcpServerInDC

# Re-authorize if needed
Remove-DhcpServerInDC -DnsName "DHCP-Server01.contoso.com"
Add-DhcpServerInDC -DnsName "DHCP-Server01.contoso.com" -IPAddress 192.168.1.10
```

### Service Startup Issues

```powershell
# Check service dependencies
Get-Service DHCPServer | Select-Object -ExpandProperty ServicesDependedOn

# Restart DHCP service
Restart-Service DHCPServer
```

## 📚 Next Steps

After successful installation and initial configuration:

1. **[Configure DHCP Scopes](scope-configuration.md)** - Create and manage DHCP scopes
2. **[Implement Security](security-monitoring.md)** - Secure your DHCP infrastructure
3. **[Setup Advanced Features](advanced-features.md)** - Configure failover and advanced options

---

> **💡 Pro Tip**: Always authorize DHCP servers in Active Directory environments to prevent rogue DHCP servers from disrupting network operations.

*This installation guide provides the foundation for a secure and properly configured Windows DHCP Server deployment.*
