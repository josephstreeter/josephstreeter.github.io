---
title:  Dump DHCP Leases with PowerShell
date:   2015-07-06 00:00:00 -0500
categories: IT
---

This PowerShell script will dump all of the leases from a Windows DHCP server. From there you can output them to a file if you need to.

```powershell
$Scopes = netsh dhcp server 192.168.0.254 show scope
$LeaseReport = @()
foreach ($Scope in $Scopes)
{
	$Leases = (netsh dhcp server 192.168.0.254 scope $Scope.split("-")[0].trim() show clients 1) | Select-String "-D-"

	foreach ($Lease in $Leases)
	{
		If ($Lease -notmatch "NEVER EXPIRES")
		{
			$Info = New-Object -type System.Object
			$Hostname = $Lease.tostring().replace("-D-",";").Split(";").Trim()
			$Info | Add-Member -MemberType NoteProperty -name Hostname -Value $Hostname[1]
			$IP = $Hostname[0].replace(" - ",";").Split(";")
			$Info | Add-Member -MemberType NoteProperty -name IPAddress -Value $IP[0]
			$Info | Add-Member -MemberType NoteProperty -name SubnetMask -Value $IP[1]
			$Info | Add-Member -MemberType NoteProperty -name MACAddress -Value $IP[2].replace(" -",";").Split(";")[0].Trim()
			$LeaseReport += $Info
			$Info | ft -AutoSize
		}
	}

}
$LeaseReport | ft -AutoSize
```


