---

title:  Generate Unique Logon Name with PowerShell
date:   2016-02-09 00:00:00 -0500
categories: IT
---






This script takes the first name, last name, and middle initial to create a logon name so that it's unique. It creates an array of available names for that user and then selects the first one that will work.

```powershell
Param(
$firstName = "Joseph",
$LastName = "Streeter",
$MI = "A"
)

BEGIN
{
Import-Module ActiveDirectory
}

PROCESS
{
Function Check-UserName($UserName)
{
if (Get-ADUser -f {samaccountname -eq $UserName} -ea 0)
{
Return $False
}
Else
{
Return $True
}
}

$UserNames = @()
$UserNames += $firstName.substring(0,1) + $LastName
$UserNames += $firstName.substring(0,1) + $MI + $LastName

$i=1
do
{
$UserNames += $firstName.substring(0,1) + $LastName + $i

$i++
}
while ($i -lt 99)

foreach ($UserName in $UserNames)
{
if (Check-UserName $UserName -eq "True")
{
$UserName
Break
}
}
}

END
{
Clear-Variable UserNames
}
```


