---
layout: post
title:  Monitor Disk Space on Domain Controllers
date:   2012-10-19 00:00:00 -0500
categories: IT
---






You have to keep an eye on things like disk space. Schedule this script and have the results for every Domain Controller in your forest emailed to you.

You will need to have the PowerShell Active Directory Module installed (Windows 7 or Server 2008 R2).

The script is attached.

This is what the results look like:

{% highlight powershell %}
Checking Space on DC01.domain.com
NTDS Partition	OK (Disk  C: Free Space  22050.8359375 )
SYSVOL Partition	OK (Disk  C: Free Space  22050.8359375 )
OS Partition	OK (Disk  C: Free Space  22050.8359375 )

Checking Space on DC02.domain.com
NTDS Partition	OK (Disk  C: Free Space  9297.06640625 )
SYSVOL Partition	OK (Disk  C: Free Space  9297.06640625 )
OS Partition	OK (Disk  C: Free Space  9297.06640625 )

Checking Space on DC03.domain.com
NTDS Partition	OK (Disk  C: Free Space  5845.15234375 )
SYSVOL Partition	OK (Disk  C: Free Space  5845.15234375 )
OS Partition	OK (Disk  C: Free Space  5845.15234375 )
{% endhighlight %}

Keep in mind that the limits set in this script are pretty low. If it triggers a "Low" warning you're in trouble!

You'll also notice that in the example output above that NTDS, SYSVOL, and OS are all on the C:\. Don't do that! Move NTDS and SYSVOL to separate volumes.


