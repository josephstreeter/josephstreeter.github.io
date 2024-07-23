---
layout: post
title:  NAT with IPTables
date:   2013-09-04 00:00:00 -0500
categories: IT
---






Turn on IP forwarding
{% highlight powershell %}echo 1 > /proc/sys/net/ipv4/ip_forward{% endhighlight %}
<span style="line-height: 1.714285714; font-size: 1rem;">Configure IPTables rules. The following code assumes that interface "eth0" is connected to the public network and interface "eth1" is connected to the private network.</span>
{% highlight powershell %}iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT{% endhighlight %}


Once you've run the commands and verified that it works you can save the config
{% highlight powershell %}/sbin/service iptables save{% endhighlight %}


