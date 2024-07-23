﻿---
layout: post
title:  Active Directory Recycle Bin
date:   2013-08-13 00:00:00 -0500
categories: IT
---

Sometimes things get deleted. Ever since Microsoft added the Active Directory Recycle Bin its a lot easier to restore those objects. No need to do an authoritative restore from backup.

Enable the Active Directory Recycle Bin:
{% highlight powershell %}
Enable-ADOptionalFeature "Recycle Bin Feature" -server $((Get-ADForest -Current LocalComputer).DomainNamingMaster) -scope ForestOrConfigurationSet -target $(Get-ADForest -Current LocalComputer)
{% endhighlight %}
List Deleted Objects:
{% highlight powershell %}
Get-ADObject -filter {(isdeleted -eq $true) -and (name -ne "Deleted Objects")} -includeDeletedObjects -property * | format-list samAccountName,lastknownParent,DistinguishedName
{% endhighlight %}
Restore deleted object:
{% highlight powershell %}
restore-adobject -identity <distinguishedname>
{% endhighlight %}
Restore multiple deleted objects (objects that have a name that starts with smith):
{% highlight powershell %}
Get-ADObject -filter {(isdeleted -eq $true) -and (name -match "smith*")} -includeDeletedObjects -property * | restore-adobject
{% endhighlight %}


