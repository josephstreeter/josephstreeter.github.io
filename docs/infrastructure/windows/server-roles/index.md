---
title: Windows Server Roles and Features
description: Overview of Windows Server roles including Active Directory, DNS, DHCP, File Services, IIS, and Hyper-V
author: Joseph Streeter
ms.author: jstreeter
ms.date: 2024-12-30
ms.topic: overview
ms.service: windows-server
keywords: server roles, Windows features, AD DS, DNS, DHCP, file services, IIS, Hyper-V
uid: docs.infrastructure.windows.server-roles
---

Windows Server provides numerous roles and features that enable specific server functionality. This section covers the most common server roles and their configuration.

## Overview

Server roles are discrete units of functionality that you can install to provide specific services. Features are additional software components that support or augment roles.

### Common Server Roles

- **[Active Directory Domain Services (AD DS)](ad-ds.md)** - Identity and access management
- **[DNS Server]#common-server-roles)** - Name resolution services
- **[DHCP Server]#common-server-roles)** - Automatic IP address assignment
- **[File and Storage Services]#common-server-roles)** - File sharing and storage management
- **[Web Server (IIS)]#common-server-roles)** - Web application hosting
- **[Hyper-V]#common-server-roles)** - Virtualization platform

### Installation Methods

#### Using Server Manager (Desktop Experience)

1. Open Server Manager
2. Click "Add Roles and Features"
3. Select "Role-based or feature-based installation"
4. Select the target server
5. Choose roles and features to install
6. Follow the wizard to complete installation

#### Using PowerShell for Installation

```powershell
# List available roles and features
Get-WindowsFeature

# Install a specific role
Install-WindowsFeature -Name RoleName -IncludeManagementTools

# Install multiple roles
Install-WindowsFeature -Name Role1,Role2,Role3 -IncludeManagementTools

# Remove a role
Uninstall-WindowsFeature -Name RoleName
```

## Quick Reference

### Installation Commands

```powershell
# Active Directory Domain Services
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# DNS Server
Install-WindowsFeature DNS -IncludeManagementTools

# DHCP Server
Install-WindowsFeature DHCP -IncludeManagementTools

# File Services
Install-WindowsFeature FS-FileServer,FS-DFS-Namespace,FS-DFS-Replication,FS-Resource-Manager -IncludeManagementTools

# Web Server (IIS)
Install-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools

# Hyper-V
Install-WindowsFeature Hyper-V -IncludeManagementTools -Restart
```

## Server Role Details

### Core Infrastructure Roles

| Role | Purpose | Key Features | Typical Use Cases |
| --- | --- | --- | --- |
| **AD DS** | Identity management | User accounts, Groups, GPO, Authentication | Domain controller, identity provider |
| **DNS** | Name resolution | Forward/reverse lookup, zone management | Internal DNS, AD integration |
| **DHCP** | IP management | Automatic addressing, reservations, failover | Network automation, IP allocation |

### Application and Service Roles

| Role | Purpose | Key Features | Typical Use Cases |
| --- | --- | --- | --- |
| **File Services** | File sharing | SMB shares, DFS, FSRM, quotas | File server, departmental shares |
| **IIS** | Web hosting | HTTP/HTTPS, app pools, SSL/TLS | Web applications, APIs, websites |
| **Hyper-V** | Virtualization | VMs, live migration, replication | Virtual infrastructure, lab environments |

### Additional Roles

- **Print and Document Services**: Centralized print management
- **Remote Desktop Services**: VDI and session-based desktops
- **Windows Deployment Services**: Network-based OS deployment
- **Active Directory Certificate Services**: Public Key Infrastructure (PKI)
- **Active Directory Federation Services**: SSO and claims-based authentication
- **Network Policy Server**: RADIUS and NAP

## Feature Installation

Common features to install alongside roles:

```powershell
# .NET Framework
Install-WindowsFeature NET-Framework-45-Core,NET-Framework-45-ASPNET

# Failover Clustering
Install-WindowsFeature Failover-Clustering -IncludeManagementTools

# PowerShell desired State Configuration
Install-WindowsFeature DSC-Service

# Windows Server Backup
Install-WindowsFeature Windows-Server-Backup

# SNMP Service
Install-WindowsFeature SNMP-Service

# Telemetry and Diagnostics
Install-WindowsFeature RSAT-Feature-Tools-BitLocker
```

## Role Dependencies

Some roles require or benefit from other roles:

- **AD DS** typically requires **DNS**
- **DHCP** works best with **DNS** integration
- **File Services** may require **DFS** for high availability
- **IIS** may need **.NET Framework** for ASP.NET applications
- **Hyper-V** may require **Failover Clustering** for high availability

## Planning Considerations

### Before Installing Roles

1. **Hardware Requirements**: Ensure adequate CPU, RAM, and disk space
2. **Network Configuration**: Configure static IP for infrastructure servers
3. **Licensing**: Verify role usage is covered by your licenses
4. **Dependencies**: Identify and install prerequisite roles/features
5. **Security**: Plan firewall rules and access controls
6. **Backup Strategy**: Ensure backup solution supports the role

### Best Practices

- ✅ Install only required roles to minimize attack surface
- ✅ Use Server Core for infrastructure roles when possible
- ✅ Document all installed roles and their purpose
- ✅ Implement monitoring for critical roles
- ✅ Plan for high availability on production systems
- ✅ Test role configuration in non-production first
- ✅ Keep roles updated with latest patches

## Management and Monitoring

### Using Server Manager

Server Manager provides a centralized interface for:

- Installing and removing roles
- Viewing role status and health
- Managing multiple servers
- Configuring role-specific settings
- Accessing management tools

### Using PowerShell for Management

```powershell
# Check installed roles
Get-WindowsFeature | Where-Object {$_.InstallState -eq "Installed"}

# Get specific role configuration
Get-Service | Where-Object {$_.DisplayName -like "*DNS*"}
Get-Service | Where-Object {$_.DisplayName -like "*DHCP*"}

# Monitor role health
Get-WinEvent -LogName "Microsoft-Windows-DNS-Server/Operational" -MaxEvents 20
Get-WinEvent -LogName "Microsoft-Windows-Dhcp-Server/Operational" -MaxEvents 20
```

## Troubleshooting

### Common Issues

**Role installation fails:**

```powershell
# Check source files
Get-WindowsFeature | Where-Object {$_.InstallState -eq "Available"}

# Verify Windows Update connectivity
Test-NetConnection windowsupdate.microsoft.com

# Check disk space
Get-PSDrive C | Select-Object Free,Used
```

**Role service not starting:**

```powershell
# Check service status
Get-Service -Name DNS,DHCP,W3SVC,NTDS

# View service dependencies
Get-Service -Name ServiceName -DependentServices
Get-Service -Name ServiceName -RequiredServices

# Check event logs
Get-WinEvent -LogName System | Where-Object {$_.LevelDisplayName -eq "Error"} | Select-Object -First 10
```

## Next Steps

- Explore individual role documentation for detailed configuration
- Review security best practices for each role
- Implement monitoring and alerting
- Plan for high availability and disaster recovery

## Related Topics

- **[Getting Started](../getting-started/index.md)** - Windows Server installation and setup
- **[Configuration Management](../configuration/index.md)** - Automation and standardization
- **[Security](../security/quick-start.md)** - Role-specific security hardening
- **[Scenarios](../scenarios.md)** - End-to-end deployment examples
