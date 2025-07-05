# Connect to Another Forest with PowerShell

## Summary

PowerShell will automatically create a PSDrive for the Active Directory domain that the client is a member of. An additional PSDrive can be created for a different domain in another forest. Body: The following command will create a PSDrive for a different domain than the one the host is joined to.

```powershell
New-PSDrive -Name <PSDrive-Name> -PSProvider ActiveDirectory -Server "<Domain-Controller>" -Scope Global c-credential (Get-Credential "<User-Name>") -root "//RootDSE/"
```

The ```-Scope Global``` switch is required if you run this cmd-let from a script. The new PSDrive can be used in several ways. Lets say that you want the to manage objects inadtest.wisc.edu with PowerShell from a host joined to the production AD forest.

The following command will create a PSDrive named "ADTEST" that will be connected to the ```adtest.wisc.edu``` domain.

```powershell
New-PSDrive -Name ADTEST -PSProvider ActiveDirectory -Server "tnads2.adtest.wisc.edu" -Scope Global -credential (Get-Credential "ADTESTjsmith-ou") -root "//RootDSE/"
```

To use this PSDrive you can "cd" to the "ADTEST" PSDrive and then run the Active Directory modules as normal:

```powershell
PS C:> cd ADTEST:
PS C:> Get-ADDomain
```

The second method is to provide the "server" switch with the name of the domain controller:

```powershell
PS C:> Get-ADDomain -server "tnads2.adtest.wisc.edu"
```

The following code will check to see if the drive exists prior to attempting creation of the new PSDrive

```powershell
if (-not(Get-PSDrive TEST))
{
    New-PSDrive -Name ADTEST -PSProvider ActiveDirectory -Server "tnads2.adtest.wisc.edu" -Scope Global -credential (Get-Credential "ADTESTjsmith-ou") -root "//RootDSE/"
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
