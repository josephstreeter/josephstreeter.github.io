---
layout: post
title:  Configure BIND on CentOS
date:   2013-09-09 00:00:00 -0500
categories: IT
---






The following instructions will help you install and configure BIND on CentOS 6.

Install BIND with the following command:
{% highlight powershell %}yum install bind -y{% endhighlight %}


Create a zone file for the new domain
{% highlight powershell %}vi /var/named/test.domain.com{% endhighlight %}
Add the zone information for the new domain
{% highlight powershell %}$TTL	1H
@       IN      SOA     test.domain.com. hostmaster.test.domain.com. (
2012080701      ; Serial
1H      ; Refresh
30M       ; Retry
20D    ; Expire
1H )  ; Minimum

@       IN      NS      ns1.test.domain.com.
@       IN      NS      ns2.test.domain.com.
ns1     IN      A       192.168.0.254
ns2     IN      A       192.168.0.253

@       IN      MX  10  smtp.test.domain.com.

www     IN      A       192.168.0.1
smtp    IN      A       192.168.0.1
ftp     IN      A       192.168.0.1{% endhighlight %}
Add the new zone file to the named.conf file.
{% highlight powershell %}vi /etc/named.conf{% endhighlight %}


Add the following text to add the zone file
{% highlight powershell %}zone "test.domain.com" {
type master;
file "/var/named/test.domain.com";
};{% endhighlight %}


Change the following lines from:
{% highlight powershell %}listen-on port 53 {127.0.0.1; };
allow-query { localhost; };{% endhighlight %}
to:
{% highlight powershell %}listen-on port 53 { 192.168.254.254; }; // Enter the interface you want BIND to listen on.
allow-query { any; };  // May also be an IP address or subnet{% endhighlight %}
Optionally add forwarders by adding the following line:
{% highlight powershell %}forwarders { 8.8.8.8; 8.8.4.4; };{% endhighlight %}
You may turn off recursion if it isn't required by changing the following line"
{% highlight powershell %}recursion yes;{% endhighlight %}
To
{% highlight powershell %}recursion no;{% endhighlight %}
Restart the named service
{% highlight powershell %}service named restart{% endhighlight %}


