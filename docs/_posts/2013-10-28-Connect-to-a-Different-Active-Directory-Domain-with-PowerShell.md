---
title:  Connect to a Different Active Directory Domain with PowerShell
author: Joseph Streeter
layout: post
date:   2013-10-28 00:00:00 -0500
categories: IT
---

PowerShell will automatically create a PSDrive for the Active Directory domain that the client is a member of. An additional PSDrive can be created for a different domain in another forest.

First, make sure that the Active Directory PowerShell module is loaded.

```powershell
import-module activedirectory
```

Now you can create the connection with the New-PSDrive commandlet.

```powershell
New-PSDrive `
    -Name <PSDrive-Name> `
    -PSProvider ActiveDirectory `
    -Server "<Domain-Controller>" `
    -Credential (Get-Credential "<User-Name>") `
    -Root "//RootDSE/" `
    -Scope Global
```

The new PSDrive can be used in several ways. Lets say that you have a test AD forest that you want to manage with PowerShell from a host joined to your production AD forest. The test forest has a domain controller named "dc-test-01.test.domain.com" that is providing the AD web service. The following command will create a PSDrive named "TEST" that will be connected to the "test.domain.com" domain.

If you're going to run this cmd-let from a script you will have to make sure that you include the "-Scope Global" switch. Otherwise the PSDrive will be created within the scope of the script and will not be available to you in the shell.

```powershell
New-PSDrive `
    -Name TEST `
    -PSProvider ActiveDirectory `
    -Server "dc-test-01.test.domain.com" `
    -Credential (Get-Credential "TEST\jsmith-da") `
    -Root "//RootDSE/" `
    -Scope Global
```

To use this PSDrive you can "cd" to the "TEST" PSDrive and then run the Active Directory modules as normal:

```powershell
PS C:\> cd TEST:
PS C:\> Get-ADDomain
```

The second method is to provide the "server" switch with the name of the domain controller:

```powershell
PS C:\> Get-ADDomain -server "dc-test-01.test.domain.com"
```

The following code will check to see if the drive exists prior to attempting creation of the new PSDrive

```powershell
if (-not(Get-PSDrive TEST))
{
    New-PSDrive `
        -Name TEST `
        -PSProvider ActiveDirectory `
        -Server "dc-test-01.test.domain.com" `
        -Credential (Get-Credential 'TEST\jsmith-da') `
        -Root '//RootDSE/' `
        -Scope Global
}
Else
{
"Drive already exists"
}
```

```powershell
if (-not(Get-PSDrive TEST))
{
    New-PSDrive `
        -Name TEST `
        -PSProvider ActiveDirectory `
        -Server "dc-test-01.test.domain.com" `
        -Credential (Get-Credential 'TEST\jsmith-da') `
        -Root '//RootDSE/' `
        -Scope Global
}
Else
{
    "Drive already exists"
}
```

## References

- [Active Directory Powershell: The Drive is the connection (Active Directory Powershell Blog)](http://blogs.msdn.com/b/adpowershell/archive/2009/03/11/the-drive-is-the-connection.aspx)
- [Using the New-PSDrive Cmdlet (TechNet)](http://technet.microsoft.com/en-us/library/ee176915.aspx)
- [Using the Get-PSDrive Cmdlet (TechNet)](http://technet.microsoft.com/en-us/library/ee176856.aspx)
