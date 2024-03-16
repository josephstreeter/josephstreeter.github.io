---
layout: post
title:  Remote Registry with PowerShell
date:   2013-11-12 00:00:00 -0500
categories: IT
---






PowerShell can access the registry on a remote computer. There doesn't appear to be built-in cmdlets to do it, so we have to do it the old fashioned way.

The example below will return some important information about a domain controller:

<b>Note:</b> make sure the lines below are on a single line.
{% highlight powershell %}$Computer = <computername>
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $Computer)

$reg.OpenSubKey("System\CurrentControlSet\Services\NTDS\Parameters").GetValue("DSA Working Directory")
$reg.OpenSubKey("System\CurrentControlSet\Services\Netlogon\Parameters").GetValue("SysVol")
$reg.OpenSubKey("Software\Microsoft\Windows NT\CurrentVersion").GetValue("SystemRoot")
$reg.OpenSubKey("System\CurrentControlSet\Services\NTDS\Parameters").GetValue("Database log files path"){% endhighlight %}
This example does the same thing, but it uses a foreach loop to iterate through the keys and values stored in an array:
{% highlight powershell %}$keys = @(
"Database Location,System\CurrentControlSet\Services\NTDS\Parameters,DSA Working Directory"
"SYSVOL Location,System\CurrentControlSet\Services\Netlogon\Parameters,SysVol"
"System Partition,Software\Microsoft\Windows NT\CurrentVersion,SystemRoot"
"Database Log Location,System\CurrentControlSet\Services\NTDS\Parameters,Database log files path"
)

$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $Computer)

foreach ($key in $keys) {
$key.Split(",")[0] + ":  " + $reg.OpenSubKey($key.Split(",")[1]).GetValue($key.Split(",")[2])
}{% endhighlight %}


