---
title:  Powershell Script to Find Stale User and Computer Objects
date:   2012-10-19 00:00:00 -0500
categories: IT
---

A couple powershell scripts to do some house cleaning on your AD. These scripts will find stale user and computer accounts. Right now they just report them, but later I will likely add code to move and disable the objects.

You will need the Quest ActiveRoles Managment tools for these scripts to work. Download them <a href="http://www.quest.com/powershell/activeroles-server.aspx">here</a>

PowerGUI Documentation Wiki will provide a ton of usefull information as well. <a href="http://wiki.powergui.org/index.php/Main_Page"> PowerGUI Wiki</a>

## Computers

```powershell
$COMPAREDATE=GET-DATE
$NumberDays=180
$x = 0

$Computers = GET-QADCOMPUTER -SizeLimit 0 -IncludedProperties LastLogonTimeStamp | where { $_.LastLogonTimeStamp -ne $null -and ($CompareDate-$_.LastLogonTimeStamp).Days -gt $NumberDays } | Select-Object Name, LastLogonTimeStamp, OSName, ParentContainerDN | Sort-Object LastLogonTimeStamp, Name

foreach ($Computer in $Computers)
{
$x = $x + 1
$Computer
}
""
"" + $x + " computers have not been used in for " + $NumberDays + " days."
```

## Users

```powershell
$COMPAREDATE=GET-DATE
$NumberDays=180
$x = 0

$Users = GET-QADUSER -SizeLimit 0 -IncludedProperties LastLogonTimeStamp | where { $_.LastLogonTimeStamp -ne $null -and ($CompareDate-$_.LastLogonTimeStamp).Days -gt $NumberDays } | Select-Object Name, LastLogonTimeStamp, ParentContainerDN | Sort-Object LastLogonTimeStamp, Name

foreach ($User in $Users)
{
$x = $x + 1
$User
}
""
"" + $x + " users have not logged in for " + $NumberDays + " days."
```
