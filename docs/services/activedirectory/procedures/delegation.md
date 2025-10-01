---
title: "Active Directory Delegation"
description: "Complete guide to Active Directory delegation, permissions, and administrative security"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

Active Directory delegation allows administrators to grant specific permissions to users or groups without giving them full administrative privileges. This principle of least privilege is essential for maintaining security while enabling distributed administration.

## Understanding Delegation

### What is Delegation?

Delegation in Active Directory involves:

- **Granting specific permissions** - Only what's needed for the task
- **Maintaining security boundaries** - Preventing privilege escalation
- **Enabling distributed administration** - Local teams manage their resources
- **Reducing administrative overhead** - Less dependency on domain admins
- **Improving compliance** - Clear audit trails and responsibility

### Types of Delegation

- **Administrative Delegation** - Rights to manage AD objects
- **Authentication Delegation** - Service account impersonation
- **Control Delegation** - Permissions over OUs and containers
- **Property-specific Delegation** - Rights to specific attributes

## Administrative Delegation

### Common Delegation Scenarios

Typical delegation requirements:

```powershell
# Help desk user management
$HelpDeskPermissions = @(
    "Reset Password"
    "Enable/Disable Account"
    "Unlock Account"
    "Modify User Properties"
    "Read User Information"
)

# Department administrators
$DeptAdminPermissions = @(
    "Create/Delete User Accounts"
    "Manage Group Membership"
    "Create/Delete Computer Accounts"
    "Modify OU Properties"
    "Read All Properties"
)

# Service account managers
$ServiceAccountPermissions = @(
    "Create Service Accounts"
    "Manage Service Principal Names"
    "Set Account Passwords"
    "Configure Account Properties"
)
```

### Delegation Wizard

Using the Delegation of Control Wizard:

```powershell
# PowerShell equivalent of delegation tasks
# Note: Use ADUC GUI for complex delegations

# Grant reset password permission
$Identity = "CN=HelpDesk,OU=Groups,DC=contoso,DC=com"
$TargetOU = "OU=Users,DC=contoso,DC=com"

# Set permission using DSACLS
dsacls $TargetOU /G "${Identity}:CA;Reset Password;user"
dsacls $TargetOU /G "${Identity}:CA;Change Password;user"
```

### Custom Delegation Scripts

PowerShell scripts for common delegations:

```powershell
# Help Desk Password Reset Delegation
function Grant-PasswordResetDelegation
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DelegatedUser,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetOU
    )
    
    try
    {
        # Import Active Directory module
        Import-Module ActiveDirectory -ErrorAction Stop
        
        # Get the distinguished name of the delegated user/group
        $DelegatedIdentity = Get-ADObject -Filter "Name -eq '$DelegatedUser'" -ErrorAction Stop
        
        # Grant reset password permission
        dsacls $TargetOU /G "$($DelegatedIdentity.DistinguishedName):CA;Reset Password;user"
        dsacls $TargetOU /G "$($DelegatedIdentity.DistinguishedName):CA;Change Password;user"
        dsacls $TargetOU /G "$($DelegatedIdentity.DistinguishedName):WP;pwdLastSet;user"
        dsacls $TargetOU /G "$($DelegatedIdentity.DistinguishedName):WP;lockoutTime;user"
        
        Write-Output "Password reset delegation granted to $DelegatedUser for $TargetOU"
    }
    catch
    {
        Write-Error "Failed to grant delegation: $($_.Exception.Message)"
    }
}

# Usage example
Grant-PasswordResetDelegation -DelegatedUser "HelpDesk" -TargetOU "OU=Users,DC=contoso,DC=com"
```

### OU-Based Delegation

Organizing delegation by Organizational Units:

```powershell
# Create delegation structure
$OUStructure = @{
    "Finance" = @{
        "Users" = "OU=Finance Users,OU=Finance,DC=contoso,DC=com"
        "Computers" = "OU=Finance Computers,OU=Finance,DC=contoso,DC=com"
        "Groups" = "OU=Finance Groups,OU=Finance,DC=contoso,DC=com"
        "Admins" = "CN=Finance Admins,OU=Finance Groups,OU=Finance,DC=contoso,DC=com"
    }
    "HR" = @{
        "Users" = "OU=HR Users,OU=HR,DC=contoso,DC=com"
        "Computers" = "OU=HR Computers,OU=HR,DC=contoso,DC=com"
        "Groups" = "OU=HR Groups,OU=HR,DC=contoso,DC=com"
        "Admins" = "CN=HR Admins,OU=HR Groups,OU=HR,DC=contoso,DC=com"
    }
}

# Apply delegation to each department
foreach ($Department in $OUStructure.Keys)
{
    $DeptConfig = $OUStructure[$Department]
    
    # Grant full control to department admins over their OUs
    dsacls $DeptConfig.Users /G "$($DeptConfig.Admins):GA"
    dsacls $DeptConfig.Computers /G "$($DeptConfig.Admins):GA"
    dsacls $DeptConfig.Groups /G "$($DeptConfig.Admins):GA"
    
    Write-Output "Delegation configured for $Department"
}
```

## Authentication Delegation

### Kerberos Delegation

Configure services for authentication delegation:

```powershell
# Constrained delegation for service accounts
$ServiceAccount = "svc-webapp01"
$TargetService = "HTTP/backend.contoso.com"

# Get service account object
$Account = Get-ADUser $ServiceAccount

# Configure constrained delegation
Set-ADUser $ServiceAccount -Add @{
    'msDS-AllowedToDelegateTo' = $TargetService
}

# Enable Kerberos delegation
Set-ADAccountControl $ServiceAccount -TrustedForDelegation $true

# Verify delegation settings
Get-ADUser $ServiceAccount -Properties msDS-AllowedToDelegateTo, TrustedForDelegation
```

### Unconstrained vs Constrained Delegation

Understanding delegation types:

```powershell
# Unconstrained delegation (security risk - avoid)
Set-ADAccountControl $ServiceAccount -TrustedForDelegation $true

# Constrained delegation (recommended)
Set-ADUser $ServiceAccount -Add @{
    'msDS-AllowedToDelegateTo' = @(
        'HTTP/web01.contoso.com',
        'HTTP/web02.contoso.com'
    )
}

# Resource-based constrained delegation (Windows 2012+)
$BackendComputer = Get-ADComputer "Backend01"
Set-ADComputer "Frontend01" -PrincipalsAllowedToDelegateToAccount $BackendComputer
```

## Permission Management

### Understanding Active Directory Permissions

Key permission types:

- **Full Control (GA)** - Complete control over object
- **Read (GR)** - Read all properties
- **Write (GW)** - Modify all properties
- **Create Child (CC)** - Create child objects
- **Delete Child (DC)** - Delete child objects
- **List Contents (LC)** - List child objects
- **Read Property (RP)** - Read specific property
- **Write Property (WP)** - Write specific property
- **Control Access (CA)** - Extended rights

### Using DSACLS for Delegation

Advanced permission management:

```powershell
# Grant specific permissions using DSACLS
$TargetOU = "OU=Users,DC=contoso,DC=com"
$DelegatedGroup = "CN=User Managers,OU=Groups,DC=contoso,DC=com"

# Grant create/delete user permissions
dsacls $TargetOU /G "${DelegatedGroup}:CC;user"
dsacls $TargetOU /G "${DelegatedGroup}:DC;user"

# Grant modify user properties
dsacls $TargetOU /G "${DelegatedGroup}:WP;General Information;user"
dsacls $TargetOU /G "${DelegatedGroup}:WP;Personal Information;user"

# Grant password reset rights
dsacls $TargetOU /G "${DelegatedGroup}:CA;Reset Password;user"
dsacls $TargetOU /G "${DelegatedGroup}:CA;Change Password;user"

# View current permissions
dsacls $TargetOU
```

### PowerShell ACL Management

Using PowerShell for advanced ACL management:

```powershell
# Function to set custom permissions
function Set-ADObjectPermission
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $true)]
        [string]$Permission,
        
        [string]$ObjectType = "All",
        [string]$InheritanceType = "All"
    )
    
    try
    {
        # Get the AD object
        $ADObject = Get-ADObject -Identity $Identity
        $ACL = Get-Acl -Path "AD:\$($ADObject.DistinguishedName)"
        
        # Create access rule
        $AccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $Principal,
            $Permission,
            [System.Security.AccessControl.AccessControlType]::Allow,
            $ObjectType,
            $InheritanceType
        )
        
        # Apply the rule
        $ACL.SetAccessRule($AccessRule)
        Set-Acl -Path "AD:\$($ADObject.DistinguishedName)" -AclObject $ACL
        
        Write-Output "Permission granted: $Permission to $Principal on $Identity"
    }
    catch
    {
        Write-Error "Failed to set permission: $($_.Exception.Message)"
    }
}
```

## Security Best Practices

### Principle of Least Privilege

Implementing minimal necessary permissions:

```powershell
# Create role-based groups for delegation
$DelegationRoles = @{
    "HelpDesk-PasswordReset" = @{
        "Description" = "Reset user passwords and unlock accounts"
        "Permissions" = @("Reset Password", "Change Password", "Write lockoutTime")
    }
    "DeptAdmin-UserMgmt" = @{
        "Description" = "Manage users within department OU"
        "Permissions" = @("Create User", "Delete User", "Write General Information")
    }
    "ServiceDesk-ComputerMgmt" = @{
        "Description" = "Manage computer accounts"
        "Permissions" = @("Create Computer", "Delete Computer", "Reset Computer Password")
    }
}

# Create groups and document their purpose
foreach ($Role in $DelegationRoles.Keys)
{
    $RoleConfig = $DelegationRoles[$Role]
    
    New-ADGroup -Name $Role -GroupScope Global -GroupCategory Security -Description $RoleConfig.Description
    
    # Log the role creation for audit purposes
    Write-Output "Created role: $Role - $($RoleConfig.Description)"
}
```

### Delegation Auditing

Monitor delegated permissions:

```powershell
# Audit delegation permissions
function Get-DelegationReport
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchBase
    )
    
    $DelegationReport = @()
    
    # Get all OUs and their permissions
    $OUs = Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase
    
    foreach ($OU in $OUs)
    {
        $ACL = Get-Acl -Path "AD:\$($OU.DistinguishedName)"
        
        foreach ($Access in $ACL.Access)
        {
            if ($Access.IdentityReference -notlike "*\Domain Admins" -and 
                $Access.IdentityReference -notlike "*\Enterprise Admins" -and
                $Access.IdentityReference -notlike "*\SYSTEM") {
                
                $DelegationReport += [PSCustomObject]@{
                    OU = $OU.Name
                    Principal = $Access.IdentityReference
                    Permission = $Access.ActiveDirectoryRights
                    AccessType = $Access.AccessControlType
                    Inheritance = $Access.InheritanceType
                }
            }
        }
    }
    
    return $DelegationReport
}

# Generate delegation report
$Report = Get-DelegationReport -SearchBase "DC=contoso,DC=com"
$Report | Export-Csv -Path "C:\Reports\AD-Delegation-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
```

### Regular Permission Reviews

Implement periodic access reviews:

```powershell
# Schedule regular permission reviews
$ReviewScript = @'
# AD Permission Review Script
$ReviewDate = Get-Date
$DomainDN = (Get-ADDomain).DistinguishedName

# Get all delegated permissions
$DelegatedPermissions = Get-DelegationReport -SearchBase $DomainDN

# Check for unusual permissions
$SuspiciousPermissions = $DelegatedPermissions | Where-Object {
    $_.Permission -like "*FullControl*" -or
    $_.Permission -like "*GenericAll*" -or
    $_.Principal -like "*Guest*"
}

# Generate review report
$ReviewReport = @{
    ReviewDate = $ReviewDate
    TotalDelegations = $DelegatedPermissions.Count
    SuspiciousCount = $SuspiciousPermissions.Count
    Recommendations = @()
}

if ($SuspiciousPermissions.Count -gt 0)
{
    $ReviewReport.Recommendations += "Review suspicious permissions: $($SuspiciousPermissions.Count) found"
}

# Email report to security team
Send-MailMessage -To "security@contoso.com" -Subject "AD Delegation Review - $ReviewDate" -Body ($ReviewReport | ConvertTo-Json)
'@

# Schedule the review
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command $ReviewScript"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "8:00 AM"
Register-ScheduledTask -TaskName "AD Permission Review" -Action $Action -Trigger $Trigger
```

}

## Practical Delegation Examples

### Help Desk Delegation

Comprehensive help desk permissions:

```powershell
# Help Desk Group Setup
$HelpDeskGroup = "CN=HelpDesk,OU=Administrative Groups,DC=contoso,DC=com"
$UserOUs = @(
    "OU=Corporate Users,DC=contoso,DC=com",
    "OU=Contract Users,DC=contoso,DC=com"
)

foreach ($OU in $UserOUs)
{
    # Password management
    dsacls $OU /G "${HelpDeskGroup}:CA;Reset Password;user"
    dsacls $OU /G "${HelpDeskGroup}:CA;Change Password;user"
    dsacls $OU /G "${HelpDeskGroup}:WP;pwdLastSet;user"
    
    # Account management
    dsacls $OU /G "${HelpDeskGroup}:WP;userAccountControl;user"
    dsacls $OU /G "${HelpDeskGroup}:WP;lockoutTime;user"
    
    # Profile management
    dsacls $OU /G "${HelpDeskGroup}:WP;profilePath;user"
    dsacls $OU /G "${HelpDeskGroup}:WP;homeDirectory;user"
    dsacls $OU /G "${HelpDeskGroup}:WP;homeDrive;user"
    
    Write-Output "Help desk delegation configured for $OU"
}
```

### Department Administrator Delegation

Department-specific administration:

```powershell
# Department Admin Template
function New-DepartmentDelegation
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DepartmentName,
        
        [Parameter(Mandatory = $true)]
        [string]$DepartmentOU,
        
        [Parameter(Mandatory = $true)]
        [string]$AdminGroup
    )
    
    # Grant comprehensive permissions to department admins
    $Permissions = @(
        "GA;;organizationalUnit",  # Full control over OU
        "CC;bf967aba-0de6-11d0-a285-00aa003049e2;", # Create user
        "DC;bf967aba-0de6-11d0-a285-00aa003049e2;", # Delete user
        "CC;bf967a86-0de6-11d0-a285-00aa003049e2;", # Create computer
        "DC;bf967a86-0de6-11d0-a285-00aa003049e2;", # Delete computer
        "CC;bf967a9c-0de6-11d0-a285-00aa003049e2;", # Create group
        "DC;bf967a9c-0de6-11d0-a285-00aa003049e2;"  # Delete group
    )
    
    foreach ($Permission in $Permissions)
    {
        dsacls $DepartmentOU /G "${AdminGroup}:${Permission}"
    }
    
    # Create delegation log entry
    $LogEntry = @{
        Date = Get-Date
        Department = $DepartmentName
        OU = $DepartmentOU
        AdminGroup = $AdminGroup
        Action = "Department delegation configured"
    }
    
    $LogEntry | Export-Csv -Path "C:\Logs\AD-Delegations.csv" -Append -NoTypeInformation
}

# Usage examples
New-DepartmentDelegation -DepartmentName "Finance" -DepartmentOU "OU=Finance,DC=contoso,DC=com" -AdminGroup "CN=Finance Admins,OU=Finance,DC=contoso,DC=com"
New-DepartmentDelegation -DepartmentName "HR" -DepartmentOU "OU=HR,DC=contoso,DC=com" -AdminGroup "CN=HR Admins,OU=HR,DC=contoso,DC=com"
```

### Service Account Management

Delegation for service account administration:

```powershell
# Service Account Delegation
$ServiceAccountOU = "OU=Service Accounts,DC=contoso,DC=com"
$ServiceAccountAdmins = "CN=Service Account Admins,OU=Groups,DC=contoso,DC=com"

# Grant service account management permissions
$ServicePermissions = @{
    "Create Service Account" = "CC;bf967aba-0de6-11d0-a285-00aa003049e2;"
    "Delete Service Account" = "DC;bf967aba-0de6-11d0-a285-00aa003049e2;"
    "Reset Service Password" = "CA;Reset Password;user"
    "Modify SPN" = "WP;servicePrincipalName;user"
    "Modify Description" = "WP;description;user"
}

foreach ($Permission in $ServicePermissions.Keys)
{
    dsacls $ServiceAccountOU /G "${ServiceAccountAdmins}:$($ServicePermissions[$Permission])"
    Write-Output "Granted $Permission to Service Account Admins"
}
```

## Troubleshooting Delegation

### Common Issues

Diagnosing delegation problems:

```powershell
# Check effective permissions
function Test-EffectivePermissions
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserIdentity,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetObject
    )
    
    try
    {
        # Get user's security context
        $User = Get-ADUser $UserIdentity
        $UserSID = $User.SID
        
        # Get object's ACL
        $ACL = Get-Acl -Path "AD:\$TargetObject"
        
        # Check permissions
        $EffectivePermissions = @()
        
        foreach ($Access in $ACL.Access)
        {
            if ($Access.IdentityReference -eq $UserSID -or 
                (Get-ADPrincipalGroupMembership $UserIdentity | Where-Object {$_.SID -eq $Access.IdentityReference})) {
                
                $EffectivePermissions += [PSCustomObject]@{
                    Permission = $Access.ActiveDirectoryRights
                    AccessType = $Access.AccessControlType
                    Inheritance = $Access.InheritanceType
                    Source = $Access.IdentityReference
                }
            }
        }
        
        return $EffectivePermissions
    }
    catch
    {
        Write-Error "Failed to check effective permissions: $($_.Exception.Message)"
    }
}

# Usage
Test-EffectivePermissions -UserIdentity "john.doe" -TargetObject "CN=Jane Smith,OU=Users,DC=contoso,DC=com"
```

### Permission Inheritance Issues

Troubleshooting inheritance problems:

```powershell
# Check inheritance status
function Get-InheritanceStatus
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistinguishedName
    )
    
    $ACL = Get-Acl -Path "AD:\$DistinguishedName"
    
    $InheritanceInfo = @{
        InheritanceEnabled = -not $ACL.AreAccessRulesProtected
        InheritedRules = ($ACL.Access | Where-Object {$_.IsInherited}).Count
        ExplicitRules = ($ACL.Access | Where-Object {-not $_.IsInherited}).Count
    }
    
    return $InheritanceInfo
}

# Fix inheritance issues
function Repair-Inheritance
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistinguishedName,
        
        [switch]$EnableInheritance
    )
    
    $ACL = Get-Acl -Path "AD:\$DistinguishedName"
    
    if ($EnableInheritance)
    {
        $ACL.SetAccessRuleProtection($false, $true)
        Set-Acl -Path "AD:\$DistinguishedName" -AclObject $ACL
        Write-Output "Inheritance enabled for $DistinguishedName"
    }
}
```

## Related Documentation

- **[Active Directory Fundamentals](../fundamentals/index.md)** - AD fundamentals and basic concepts
- **[Domain Controllers](../fundamentals/domain-controllers.md)** - DC deployment and management  
- **[Group Policy Management](../../grouppolicy/index.md)** - Policy-based management
- **[Security Best Practices](../Security/index.md)** - AD security hardening
- **[Troubleshooting Guide](../operations/troubleshooting-guide.md)** - Common AD issues and solutions

---

*This guide provides comprehensive coverage of Active Directory delegation from basic concepts to advanced security practices. Proper delegation is essential for scalable and secure AD administration.*
