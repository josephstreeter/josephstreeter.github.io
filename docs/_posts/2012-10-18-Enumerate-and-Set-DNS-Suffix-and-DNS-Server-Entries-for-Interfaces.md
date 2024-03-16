---
layout: post
title:  Enumerate and Set DNS Suffix and DNS Server Entries for Interfaces
date:   2012-10-18 00:00:00 -0500
categories: IT
---

This is a PowerShell script that will enumerate the DNS suffix and DNS server entries for TCP/IP enabled interfaces on hosts that run a Windows Server OS.

{% highlight powershell %}
$objName = "***filter-text***"
$searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")
$searcher.filter = "(&(objectClass=user)(objectCategory=computer)(cn= $objName*)(operatingSystem=*Server*))"
$objAd = $searcher.findall()

foreach ($objComp in $objAd)
{
	$strServerName = $objComp.properties.cn
	$strNICs = Get-WMIObject Win32_NetworkAdapterConfiguration -computername $strServerName | where{$_.IPEnabled -eq $TRUE}
	Foreach($strNIC in $strNICs)
	{
		write-host $strServerName
		$strNIC.DNSDomain
		$strNIC.DNSServerSearchOrder
		write-host ""
	}
}
{% endhighlight %}


This script will set the DNS suffix and DNS server entries for each interface. Just set the variables, $objName, $strDNSServers, and $strDNSName


{% highlight powershell %}
$objName = "***filter-text***"
$strDNSServers = "***dns-server-1***","***dns-server-1***"
$strDNSName = "***dns-suffix***"

$searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")
$searcher.filter = "(&(objectClass=user)(objectCategory=computer) (cn= $objName*)(operatingSystem=*Server*))"
$objAd = $searcher.findall()

foreach ($objComp in $objAd)
{
	$strServerName = $objComp.properties.cn
	$strNICs = Get-WMIObject Win32_NetworkAdapterConfiguration -computername $strServerName | where{$_.IPEnabled -eq $TRUE}

	Foreach($strNIC in $strNICs) 
	{
		$strNIC.SetDNSServerSearchOrder()
		$strNIC.SetDNSServerSearchOrder($strDNSServers)
		$strNIC.SetDNSDomain($strDNSName)
	}
}
{% endhighlight %}


