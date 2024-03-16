---
layout: post
title:  Change UPN Suffix for Office 365 Users
date:   2012-12-28 00:00:00 -0500
categories: IT
---






We moved an instance of Office 365 from one Active Directory instance to another and required a UPN suffix change for the federated authentication. The PowerShell script below did the trick.

The script would occasionally bomb out when sending data to O365 for whatever reason. So, in order to avoid having the script start over with the users that were already done I put all the users that were not changed yet into the $Users variable. I also made it skip the accounts that exist only in O365 by not including accounts that begin with "svc-". Aren't naming conventions great?

I also put the number of user objects help in $users into the $i variable so that the script can count backwards as it runs to let you know how many users are left. I like progress- indicators.
{% highlight powershell %}
<p style="width: 270%;">$users=Get-MsolUser -all | Where {(-Not- $_.UserPrincipalName.ToLower().StartsWith("svc-")) -and (-Not $_.UserPrincipalName.ToLower().EndsWith("@new-domain.com"))}
$i=$users.count
ForEach ($user in $users)
{
Set-MsolUserPrincipalName -ObjectId $User.ObjectId -NewUserPrincipalName($User.UserPrincipalName.Split("@")[0]+"@new-domain.com")
if ($?) {$i- -}
$User.UserPrincipalName+"`t"+$i
}

{% endhighlight %}


