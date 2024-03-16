﻿---
layout: post
title:  PowerShell Dump DHCP Reservations
date:   2015-12-02 00:00:00 -0500
categories: IT
---






A script to dump all of the reservations from a Windows DHCP server
{% highlight powershell %}
$PropArray = @()
$scopes = Get-DhcpServerv4Scope -ComputerName dhcpprd01

foreach ($scope in $scopes)
{
$Reservations = Get-DhcpServerv4Reservation -ComputerName dhcpprd01 -ScopeId $scope.ScopeId
foreach ($Reservation in $Reservations)
{
$Prop = New-Object System.Object
$Prop | Add-Member -type NoteProperty -name ScopeID -value $Reservation.ScopeID
$Prop | Add-Member -type NoteProperty -name IpAddress -value $Reservation.IPAddress
$Prop | Add-Member -type NoteProperty -name ClientID -value $Reservation.ClientID
$Prop | Add-Member -type NoteProperty -name Name -value $Reservation.Name
$Prop | Add-Member -type NoteProperty -name Type -value $Reservation.Type
$PropArray += $Prop

}
}
$PropArray | ft -AutoSize
{% endhighlight %}


