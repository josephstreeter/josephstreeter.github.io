---
title:  Useful PowerShell Commands for Office 365
date:   2012-11-14 00:00:00 -0500
categories: IT
---

Snippets of PowerShell commands to make your Office 365 administration experience more enjoyable.

***Connect to Office 365:***

```powershell
$user = "<MSOL-Admin>@<domain.tld>"
$cred = Get-Credential -Credential $user
Import-Module MSOnline
Connect-MsolService -Credential $cred
```

***List all licensed users:***

```powershell
Get-MsolUser -all | where {$_.isLicensed -eq $TRUE}
```

***Show all disconnected users:***

```powershell
Get-MsolUser -returndeletedusers
```

***A hard delete of a disconnected mailbox:***

```powershell
Remove-MsolUser -RemoveFromRecycleBin -UserPrincipalName user@domain.tld
```

***A hard delete of all disconnected users:

```powershell
Get-MsolUser -returndeleteduser -all | Remove-MsolUser -removefromrecyclebin -force
```

***Set immutableID to match new user GUID:***

```powershell
$cn = "<username>"
$guid = (get-aduser -f {cn -eq $cn} -pr objectguid).objectguid
$upn-  = (get-aduser -f {cn -eq $cn}).userprincipalname
$ImmutableID = [System.Convert]::ToBase64String($guid.ToByteArray())

set-msolUser -userprincipalname $upn -immutableID $ImmutableID
```

***Set immutableID to match new NULL (Allows SMTP macthing to connect mailbox):

```powershell
set-msolUser -userprincipalname <userprincipalname> -immutableID $NULL
```
