---
layout: post
title:  PowerShell to Get a Webpage
date:   2012-11-29 00:00:00 -0500
categories: IT
---






In an earlier post I wrote about getting your public IP address from the CLI or script using the ip.appspot.com webpage and CLI. Here is how you can do the same thing using PowerShell and the Net.WebClient.

{% highlight powershell %}$web = New-Object net.WebClient
$web.downloadstring("http://ip.appspot.com")
{% endhighlight %}

You can use this to pull down any webpage. Have fun.


