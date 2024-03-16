﻿---
layout: post
title:  Change Linux Hostname
date:   2013-02-11 00:00:00 -0500
categories: IT
---

***Redhat/CentOS***
Edit the line that starts with "HOSTNAME" in the /etc/sysconfig/network file to reflect the new name
{% highlight powershell %}
HOSTNAME=host.domain.com
{% endhighlight %}

***Debian/Ubuntu***
Echo the new host name to "/etc/hostname"
{% highlight powershell %}
echo “host.example.com” > /etc/hostname
{% endhighlight %}

***All Distros***
For both types of distributions update the "/etc/hosts" file so that the new name points to the loopback
{% highlight powershell %}
127.0.0.1- - - - - -  localhost
127.0.1.1- - - - - -  host.example.com localhost
{% endhighlight %}


