---
layout: post
title:  Disable Computer Objects in Default Location Daily and Delete them Weekly
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Stale, or unused, objects in Active Directory pose a security risk to an organization as well affect replication performance, increase the size of system state backups, and increase the amount of time it takes to create and restore backups.

When computer objects are created by joining a computer to the domain they are created in the default computers container. After being joined to the domain these computer objects should be moved to the creator's delegated Organizational Unit where they will receive appropriate departmental Group Policy.

In order to avoid a large number of computer objects left in the default computer location the following script can be run nightly through a scheduled task. The script will disable all computers in the default computer location and update the object with the date. Any computer objects that have a date older than two weeks will be deleted. The script will determine what the default container is for computers without having the path provided manually if it was changed from the AD default.

If Administrators find that a computer object is disabled and is still in use the administrator can move the computer object to his/her OU and enable it for future use. In emergency situations computer objects that have been deleted could be restored from backup.

That should encourage your Computer admins to move the computer objects to the appropriate OU or start pre-staging them.



---

Import-Module ActiveDirectory
If (-not $?) { "Failed to import AD module!" ; exit }

$Disabled = 0
$Deleted = 0

$Computers = get-adcomputer -f * -pr comment -searchbase (get-ADDomain).ComputersContainer

foreach ($Computer in $Computers)
{
If (-not $Computer.Comment)
{
set-adComputer -identity $Computer.name -Enable $False '
-replace @{comment = (Get-Date).ToShortDateString()}

$Disabled++
}
Else
{
$d = $Computer.comment
If (((Get-Date)-(get-date $d)).days -ge 14)
{
Remove-ADComputer -Identity $Computer.name -Confirm:$False
$Deleted++
}
}
}

"$Disabled Computers disabled"
"$Deleted Computers deleted"

---


