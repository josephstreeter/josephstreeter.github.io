---
layout: post
title:  Find GPOs that aren't linked or Don't Contain Policies
date:   2015-11-27 00:00:00 -0500
categories: IT
---






Creates a list of all Group Policy objects that are not linked or don't have any policies configured.

{% highlight powershell %}
Import-Module grouppolicy

Write-Host "`nUnlinked GPOs`n"
$allGPOs = Get-GPO -All | sort DisplayName
ForEach ($gpo in $allGPOs) {
$xml = [xml](Get-GPOReport $gpo.Id xml)
If (!$xml.GPO.LinksTo) {
$gpo.DisplayName
}
}

Write-Host "`nGPOs with no settings`n"
$allGPOs = Get-GPO -All | sort DisplayName
ForEach ($gpo in $allGPOs) {
$xml = [xml](Get-GPOReport $gpo.Id xml)
If ($xml.GPO.LinksTo) {
If (!$xml.GPO.Computer.ExtensionData -and !$xml.GPO.User.ExtensionData) {
$gpo.DisplayName
}
}
}
{% endhighlight %}


