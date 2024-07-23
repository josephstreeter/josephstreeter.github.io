---
layout: post
title:  Install SNMP on Debian Squeeze
date:   2012-10-18 00:00:00 -0500
categories: IT
---






This seems to have changed some from Debian Lenny. I don't think I have all the bugs worked out yet, but here it goes.

First install SNMPD.

{% highlight powershell %}
apt-get install snmpd
{% endhighlight %}

The default config file seems to be what was giving be some trouble early on. You can create one from scratch using the following command:

{% highlight powershell %}
snmpconf -g basic_setup
{% endhighlight %}

Just answer the questions and it will create the file for you. If you run the command from the "/etc/snmp" directory and you won't have to move the file when you're done.

You will have to install the MIB files yourself since they are no longer included due to the usual licensing issues. You can, however, add them with a couple changes.

First you will have to have "non-free" added to your apt sources and uncomment the one line in "/etc/snmp/snmp.conf"

Then run the the following command:

{% highlight powershell %}
apt-get install apt-get install snmp-mibs-downloader
{% endhighlight %}

That should do it. Try a snmpwalk command against the box and see what you get.

{% highlight powershell %}
snmpwalk -c community -v 2c 192.168.0.10
{% endhighlight %}


