---
title: "Active Directory Getting Started"
description: "Getting started guide for Active Directory fundamentals and basic administration"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Active Directory Getting Started

This guide provides essential information for administrators new to Active Directory, covering fundamental concepts, basic administration tasks, and initial setup procedures.

## What is Active Directory?

Microsoft Active Directory (AD) is a directory service that provides authentication, authorization, and other services in a Windows environment. It stores information about objects on the network and makes this information available to users and network administrators.

### Key Components

- **Domain Controller (DC)** - Server that hosts Active Directory Domain Services
- **Domain** - Administrative boundary that contains users, computers, and other objects
- **Forest** - Collection of one or more domain trees that share a common schema
- **Organizational Unit (OU)** - Container for organizing objects within a domain
- **Schema** - Defines the types of objects and attributes that can be stored

### Benefits of Active Directory

- **Centralized Authentication** - Single sign-on across network resources
- **Group Policy Management** - Centralized configuration management
- **Scalability** - Supports organizations from small businesses to enterprises
- **Security** - Robust authentication and authorization mechanisms
- **Integration** - Works seamlessly with Microsoft and third-party applications

## Prerequisites

### Knowledge Requirements

Before working with Active Directory, you should understand:

- **Windows Server Administration** - Basic server management concepts
- **Networking Fundamentals** - TCP/IP, DNS, DHCP concepts
- **Security Principles** - Authentication, authorization, and access control
- **PowerShell Basics** - Command-line administration skills

### Infrastructure Requirements

- **Windows Server** - Server 2019 or later recommended
- **DNS Infrastructure** - Properly configured DNS is critical
- **Network Connectivity** - Reliable network between sites
- **Hardware Resources** - Adequate CPU, memory, and storage
- **Backup Solution** - System State and AD database backup capability

## Basic Concepts

### Domains and Forests

Understanding the hierarchical structure:

```text
Forest: company.com
├── Domain: company.com (Root Domain)
│   ├── OU: Users
│   ├── OU: Computers
│   └── OU: Servers
├── Domain: sales.company.com (Child Domain)
│   ├── OU: Sales Users
│   └── OU: Sales Computers
└── Domain: hr.company.com (Child Domain)
    ├── OU: HR Users
    └── OU: HR Computers
```

### Organizational Units (OUs)

OUs provide administrative delegation and Group Policy application:

- **Purpose-based**: Organize by function (Sales, HR, IT)
- **Location-based**: Organize by geographical location
- **Administrative**: Delegate specific administrative tasks
- **Security**: Apply different security policies

### Global Catalog

The Global Catalog contains:

- **Complete replica** of all objects in its domain
- **Partial replica** of objects from other domains in the forest
- **Universal group membership** information
- **Schema and configuration** partition replicas

## Initial Setup

### Installing Active Directory Domain Services

Using PowerShell to install AD DS:

```powershell
# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Import AD DS module
Import-Module ADDSDeployment

# Promote server to domain controller (new forest)
Install-ADDSForest `
    -DomainName "company.com" `
    -DomainNetbiosName "COMPANY" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
    -Force
```

### Post-Installation Configuration

Essential configuration tasks:

```powershell
# Configure DNS forwarders
Add-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4

# Create organizational units
New-ADOrganizationalUnit -Name "Users" -Path "DC=company,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "DC=company,DC=com"
New-ADOrganizationalUnit -Name "Servers" -Path "DC=company,DC=com"
New-ADOrganizationalUnit -Name "Groups" -Path "DC=company,DC=com"

# Configure default password policy
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 12 -MaxPasswordAge 90

# Create administrative groups
New-ADGroup -Name "IT Administrators" -GroupScope Global -GroupCategory Security -Path "OU=Groups,DC=company,DC=com"
New-ADGroup -Name "Help Desk" -GroupScope Global -GroupCategory Security -Path "OU=Groups,DC=company,DC=com"
```

## Basic Administration Tasks

### User Management

Creating and managing user accounts:

```powershell
# Create a new user
New-ADUser `
    -Name "John Doe" `
    -GivenName "John" `
    -Surname "Doe" `
    -SamAccountName "jdoe" `
    -UserPrincipalName "jdoe@company.com" `
    -Path "OU=Users,DC=company,DC=com" `
    -AccountPassword (ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force) `
    -Enabled $true `
    -ChangePasswordAtLogon $true

# Add user to group
Add-ADGroupMember -Identity "IT Administrators" -Members "jdoe"

# Disable user account
Disable-ADAccount -Identity "jdoe"

# Reset user password
Set-ADAccountPassword -Identity "jdoe" -Reset -NewPassword (ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force)
```

### Computer Management

Managing computer accounts:

```powershell
# Add computer to domain (run on client)
Add-Computer -DomainName "company.com" -Credential (Get-Credential) -Restart

# Move computer to different OU
Move-ADObject -Identity "CN=Computer01,CN=Computers,DC=company,DC=com" -TargetPath "OU=Servers,DC=company,DC=com"

# Get computer information
Get-ADComputer -Identity "Computer01" -Properties *
```

### Group Management

Creating and managing groups:

```powershell
# Create security group
New-ADGroup -Name "Sales Team" -GroupScope Global -GroupCategory Security -Path "OU=Groups,DC=company,DC=com"

# Create distribution group
New-ADGroup -Name "All Employees" -GroupScope Universal -GroupCategory Distribution -Path "OU=Groups,DC=company,DC=com"

# Add members to group
Add-ADGroupMember -Identity "Sales Team" -Members "jdoe", "jsmith"

# Get group membership
Get-ADGroupMember -Identity "Sales Team"
```

## Essential Tools

### Active Directory Administrative Center

Modern GUI tool for AD management:

- **Dashboard view** - Overview of AD health and recent activities
- **Dynamic access control** - Advanced permissions management
- **Password settings objects** - Fine-grained password policies
- **Windows PowerShell history** - View generated PowerShell commands

### Active Directory Users and Computers

Traditional management console:

- **User and computer management** - Create, modify, and delete objects
- **Group management** - Manage group membership and properties
- **Organizational unit management** - Create and manage OUs
- **Delegation of control** - Assign administrative permissions

### PowerShell AD Module

Command-line administration:

```powershell
# Import Active Directory module
Import-Module ActiveDirectory

# Common cmdlets
Get-ADUser -Filter *
Get-ADComputer -Filter *
Get-ADGroup -Filter *
Get-ADOrganizationalUnit -Filter *

# Search examples
Get-ADUser -Filter {Enabled -eq $false}
Get-ADComputer -Filter {OperatingSystem -like "*Server*"}
Get-ADGroup -Filter {GroupScope -eq "Global"}
```

## Common Scenarios

### Adding New Users

Standard user creation process:

1. **Plan user account** - Determine naming convention and OU placement
2. **Create user account** - Use consistent naming and initial password
3. **Assign group memberships** - Add to appropriate security groups
4. **Configure user properties** - Set department, manager, contact info
5. **Test account** - Verify login and resource access

### Joining Computers to Domain

Process for domain joining:

1. **Configure DNS** - Point client to domain controller
2. **Join domain** - Use domain admin credentials
3. **Restart computer** - Complete domain join process
4. **Move computer object** - Place in appropriate OU
5. **Test connectivity** - Verify domain authentication

### Basic Troubleshooting

Common issues and solutions:

```powershell
# Test domain controller connectivity
Test-ComputerSecureChannel -Verbose

# Check AD replication
repadmin /showrepl

# Test DNS resolution
nslookup company.com

# Check time synchronization
w32tm /query /status

# Verify Kerberos tickets
klist

# Test LDAP connectivity
ldp.exe
```

## Security Basics

### Account Security

- **Strong passwords** - Enforce complexity requirements
- **Account lockout** - Configure lockout policies
- **Password expiration** - Set appropriate expiration periods
- **Privileged accounts** - Separate admin accounts from user accounts

### Group Policy Basics

Essential Group Policy configurations:

```powershell
# Create new GPO
New-GPO -Name "Security Baseline" -Comment "Basic security settings"

# Link GPO to OU
New-GPLink -Name "Security Baseline" -Target "OU=Users,DC=company,DC=com"

# Common security settings
# - Password policies
# - Account lockout policies
# - User rights assignments
# - Security options
```

## Next Steps

### Intermediate Topics

After mastering the basics, explore:

- **[Forests and Domains](forests-and-domains.md)** - Advanced domain design
- **[Group Policy](group-policy.md)** - Centralized configuration management
- **[Sites and Subnets](sites-and-subnets.md)** - Multi-site deployments
- **[Global Catalogs](global-catalogs.md)** - Directory query optimization

### Advanced Administration

- **[Operations](../Operations/index.md)** - Day-to-day administrative procedures
- **[Security Best Practices](../security-best-practices.md)** - Hardening guidelines
- **[Monitoring and Logging](../Operations/monitoring-and-alerting.md)** - Health monitoring
- **[Disaster Recovery](../configuration/disaster-recovery.md)** - Backup and recovery procedures

## Related Documentation

- **[Windows Server](../../../infrastructure/windows/index.md)** - Server administration
- **[PowerShell](../../../development/powershell/index.md)** - Automation and scripting
- **[Group Policy](group-policy.md)** - Policy management
- **[Security](../../../security/index.md)** - Enterprise security practices

---

*This getting started guide provides the foundation for Active Directory administration. Take time to understand these basics before moving to more advanced topics.*
