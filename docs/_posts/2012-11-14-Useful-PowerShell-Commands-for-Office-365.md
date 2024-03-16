---
layout: post
title:  Useful PowerShell Commands for Office 365
date:   2012-11-14 00:00:00 -0500
categories: IT
---






Snippets of PowerShell commands to make your Office 365 administration experience more enjoyable.

***Connect to Office 365:***
<em>$user = "<MSOL-Admin>@<domain.tld>"
$cred = Get-Credential -Credential $user
Import-Module MSOnline
Connect-MsolService -Credential $cred
</em>

***List all licensed users:***
<em>Get-MsolUser -all | where {$_.isLicensed -eq $TRUE}</em>

***Show all disconnected users:***
<em>Get-MsolUser -returndeletedusers</em>

***A hard delete of a disconnected mailbox:
***<em>Remove-MsolUser -RemoveFromRecycleBin -UserPrincipalName user@domain.tld</em>

***A hard delete of all disconnected users:
***Get-MsolUser -returndeleteduser -all | Remove-MsolUser -removefromrecyclebin -force

***Set immutableID to match new user GUID:***
$cn = "<username>"
$guid = (get-aduser -f {cn -eq $cn} -pr objectguid).objectguid
$upn-  = (get-aduser -f {cn -eq $cn}).userprincipalname
$ImmutableID = [System.Convert]::ToBase64String($guid.ToByteArray())

set-msolUser -userprincipalname $upn -immutableID $ImmutableID

***Set immutableID to match new NULL (Allows SMTP macthing to connect mailbox):
***set-msolUser -userprincipalname <userprincipalname> -immutableID $NULL


