---

title:  PowerShell Dump DHCP Leases
date:   2015-12-02 00:00:00 -0500
categories: IT
---






Dump all of the DHCP leases from a Windows DHCP server into an object using PowerShell

```powershell
$PropArray = @()
$scopes = Get-DhcpServerv4Scope -ComputerName dhcpprd01

foreach ($scope in $scopes)
{
$Leases = Get-DhcpServerv4Lease -ComputerName dhcpprd01 -ScopeId $scope.ScopeId
foreach ($Lease in $Leases)
{
$Prop = New-Object System.Object
$Prop | Add-Member -type NoteProperty -name ScopeID -value $Lease.ScopeID
$Prop | Add-Member -type NoteProperty -name IpAddress -value $Lease.IPAddress
$Prop | Add-Member -type NoteProperty -name ClientID -value $Lease.ClientID
$Prop | Add-Member -type NoteProperty -name HostName -value $Lease.HostName
$Prop | Add-Member -type NoteProperty -name AddressState -value $Lease.AddressState
$PropArray += $Prop
}
}

$PropArray
```


