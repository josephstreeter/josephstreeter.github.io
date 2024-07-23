---
layout: post
title:  PowerShell Script to Check if a User Exists
date:   2012-10-19 00:00:00 -0500
categories: IT
---






If you're creating or modifying users with a powershell script you might want to check to see if they exist first.

Here is some powershell code that will do just that for you:
{% highlight powershell %}
$account = "username"

if ( -not (Get-ADUser -LDAPFilter "(sAMAccountName=$account)"))
{ Write-Host "Create the account!" }
else
{ Write-Host "Already there" }
{% endhighlight %}

For this to work you will need to have the PowerShell AD modules installed and AD Web Services operational.


