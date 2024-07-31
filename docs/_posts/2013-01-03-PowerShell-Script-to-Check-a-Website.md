---

title:  PowerShell Script to Check a Website
date:   2013-01-03 00:00:00 -0500
categories: IT
---






You can ping a web server and determine if it's "alive" by the ICMP response. However, it doesn't tell you if the sites running on the web server are actually serving data.

Here is one way to do it with PowerShell:

```powershell
$date = Get-date
$site = "http://www.joseph-streeter.com/"
$webClient = new-object System.Net.WebClient
$webClient.Headers.Add("user-agent", "PowerShell Script")
If (-Not $webClient.DownloadString($site).tolower().contains("crusader"))
{
    "Site is not available. Sent Email Alert: " + $date
}
Else
{
    "Site is available"
}
```

If you have multiple sites to check, you can do that too:

```powershell
$sites=@{}
$sites["http://www.google.com"] = "Google"
$sites["http://www.yahoo.com"] = "Yahoo"
$sites["http://www.hbo.com"] = "HBO"$date = Get-date
$webClient = new-object System.Net.WebClient
$webClient.Headers.Add("user-agent", "PowerShell Script")

foreach ($site in $sites.keys)
{
    If (-Not $webClient.DownloadString($site).tolower().contains($sites[$site].ToLower()))
    {
        $sites[$site]+" is not available. Sent Email Alert: " + $date
    }
    Else
    {
        $sites[$site]+" is available"
    }
}
```

You can schedule the script to run regularly and send you an email when the site fails to respond.
