---
layout: post
title:  Set Aging on All DNS Zones
date:   2015-11-27 00:00:00 -0500
categories: IT
---






A quick script to set the aging on all zones. In this case it's only doing reverse lookup zones.

{% highlight powershell %}
$zones = Get-DnsServerZone -ComputerName dc | ? {($_.IsReverseLookupZone -eq $True) -and ($_.IsDsIntegrated -eq $True)}

foreach ($zone in $zones)
{
Set-DnsServerZoneAging -ComputerName dc -Name $zone.zonename -RefreshInterval 4.00:00:00 -NoRefreshInterval 4.00:00:00
}
{% endhighlight %}


