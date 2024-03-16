---
layout: post
title:  Cisco AnyConnect Reconnecting Errors
date:   2013-12-03 00:00:00 -0500
categories: IT
---






On a new Windows 8 desktop I started seeing the Cisco AnyConnect client display a message telling me that it is reconnecting. It would continue to do this and never really connect. In the message logs in the client I found the following entry.
{% highlight powershell %}"A VPN reconnect resulted in different configuration settings. The VPN network interface is being re-initialized. Applications utilizing the private network may need to be restarted."{% endhighlight %}
There was a forum post that I found that recommended lowering the MTU for the interface created by the AnyConnect client to 1273. It appears to have worked.

The following NetSh command can be used to check the MTU for your interfaces:
{% highlight powershell %}netsh interface ipv4 show subinterfaces{% endhighlight %}
Check the value of the "loopback pseudo-interface 1" adapter. The "loopback pseudo-interface 1" is the network adapter name for Cisco Anyconnect.

Set the MTU value for the "loopback pseudo-interface 1" interface with the following NetSH command:
{% highlight powershell %}netsh interface ipv4 set subinterface "loopback pseudo-interface 1" mtu=1273 store=persistent{% endhighlight %}


