---
layout: post
title:  Configure Nagios DNS Check
date:   2013-12-29 00:00:00 -0500
categories: IT
---






While its important to know that the DNS service is running, it's more important to know that DNS is serving up name resolution as expected. The check_dns command can be used to test name resolution for a name server.

On CentOS the commands are located here by default:
{% highlight powershell %}/usr/lib64/nagios/plugins/{% endhighlight %}
Arguments for the check_dns command:
{% highlight powershell %}check_dns -H host [-s server] [-a expected-address] [-A] [-t timeout] [-w warn] [-c crit]{% endhighlight %}
You can test the command from the command line:
{% highlight powershell %}/usr/lib64/nagios/plugins/check_dns -H www.google.com -s 8.8.8.8
DNS OK: 0.066 seconds response time. www.google.com returns 74.125.225.112,74.125.225.113,74.125.225.114,74.125.225.115,74.125.225.116|time=0.065503s;;;0.000000{% endhighlight %}
In order to use the command it must be defined in /etc/nagios/commands.cfg.
{% highlight powershell %}define command {
command_name    check_dns
command_line    $USER1$/check_dns -H $ARG1$ -s $HOSTADDRESS$
}{% endhighlight %}
Define the service for the host that you want to check (ns1.domain.com) and provide the name that you want to resolve (www.google.com).
{% highlight powershell %}define service {
use                        generic-service
host_name                  ns1.domain.com
service_description        Check name resolution
check_command              check_dns!www.google.com
}{% endhighlight %}


