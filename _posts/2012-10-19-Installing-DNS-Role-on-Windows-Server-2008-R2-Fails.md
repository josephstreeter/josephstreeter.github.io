---
layout: post
title:  Installing DNS Role on Windows Server 2008 R2 Fails
date:   2012-10-19 00:00:00 -0500
categories: IT
---






This was something of a pain. It seems that if you limit the number of RPC ports as part of your server build it will cause you problems with installing the DNS role.

To check the current configuration:
{% highlight powershell %}
netsh int ipv4 show dynamicport tcp
netsh int ipv4 show dynamicport udp
{% endhighlight %}

I can't find the article that I used, but here was the fix.

First, use the netsh command to return to the defaults:
{% highlight powershell %}
netsh int ipv4 set dynamicport tcp start=49152 num=16383
netsh int ipv4 set dynamicport udp start=49152 num=16383
netsh int ipv6 set dynamicport tcp start=49152 num=16383
netsh int ipv6 set dynamicport udp start=49152 num=16383
{% endhighlight %}

Then install the DNS role.

Finally, use the netsh command to replace the custom settings:
{% highlight powershell %}
netsh int ipv4 set dynamicport tcp start=52044 num=255
netsh int ipv4 set dynamicport udp start=52044 num=255
netsh int ipv6 set dynamicport tcp start=52044 num=255
netsh int ipv6 set dynamicport udp start=52044 num=255
{% endhighlight %}


