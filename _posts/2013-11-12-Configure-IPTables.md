---
layout: post
title:  Configure IPTables
date:   2013-11-12 00:00:00 -0500
categories: IT
---






Configure and test the iptables script similar to the example below.

The following commands will flush existing rules and set the default rule to drop traffic:
{% highlight powershell %}
# Flush existing rules
iptables -F
iptables -F -t nat

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
{% endhighlight %}

Configure rules to allow services:
{% highlight powershell %}iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -p tcp --dport 22 -j ACCEPT #SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT #HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT #HTTPS
iptables -A INPUT -p tcp --dport 25 -j ACCEPT #SMTP
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT #Squid Proxy
iptables -A INPUT -p tcp --dport 10000 -j ACCEPT #WebMin
iptables -A INPUT -p udp --dport 53 -j ACCEPT #DNS{% endhighlight %}
Save the rules with the following command:
{% highlight powershell %}service iptables save{% endhighlight %}

You may have to insert rules into a chain. For example, if the last rule drops all traffic, none of the rules after it will get evaluated. So, we start by showing the rules with line numbers.
{% highlight powershell %}
iptables -L -n --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination
1    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED
2    ACCEPT     icmp --  0.0.0.0/0            0.0.0.0/0
3    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
4    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           state NEW tcp dpt:22
5    REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited
{% endhighlight %}
Now we can see that everything is being dropped by the rule on line 5. In order to allow TCP/80 and TCP/5666 we will have to insert rules before line 5.
{% highlight powershell %}
iptables -I INPUT 4 -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 4 -p tcp --dport 5666 -j ACCEPT
{% endhighlight %}
Now we can see that the new rules appear in the chain before the drop rule.
{% highlight powershell %}
[root@A0-MAD-02 ~]# iptables -L -n --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination
1    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED
2    ACCEPT     icmp --  0.0.0.0/0            0.0.0.0/0
3    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
4    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           tcp dpt:5666
5    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           tcp dpt:80
6    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           state NEW tcp dpt:22
7    REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited
{% endhighlight %}

The following lines will drop all access from BOGON addresses:
{% highlight powershell %}iptables -A INPUT -s 10.0.0.0/255.0.0.0 -j DROP
iptables -A INPUT -s 169.254.0.0/255.255.0.0 -j DROP
iptables -A INPUT -s 172.16.0.0/255.240.0.0 -j DROP
iptables -A INPUT -s 192.0.0.0/255.255.255.0 -j DROP
iptables -A INPUT -s 192.0.2.0/255.255.255.0 -j DROP
iptables -A INPUT -s 192.168.0.0/255.255.0.0 -j DROP
iptables -A INPUT -s 198.18.0.0/255.254.0.0 -j DROP
iptables -A INPUT -s 198.51.100.0/255.255.255.0 -j DROP
iptables -A INPUT -s 203.0.113.0/255.255.255.0 -j DROP
iptables -A INPUT -s 224.0.0.0/224.0.0.0 -j DROP
iptables -A INPUT -s 0.0.0.0/255.0.0.0 -j DROP{% endhighlight %}

Iptables can be configured to drop or accept traffic from certain countries. The following lines will drop all traffic from countries that have a bad habit of showing up in my logs:
{% highlight powershell %}# Ref: http://www.countryipblocks.net/
iptables -A INPUT -s 119.62.0.0/255.255.0.0 -j DROP #China
iptables -A INPUT -s 59.60.0.0/255.254.0.0 -j DROP #China
iptables -A INPUT -s 117.32.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 118.144.0.0/255.252.0.0 -j DROP #CHINA
iptables -A INPUT -s 119.176.0.0/255.240.0.0 -j DROP #CHINA
iptables -A INPUT -s 218.1.0.0/255.255.0.0 -j DROP #CHINA
iptables -A INPUT -s 218.68.0.0/255.254.0.0 -j DROP #CHINA
iptables -A INPUT -s 218.68.0.0/255.254.0.0 -j DROP #CHINA
iptables -A INPUT -s 122.64.0.0/255.224.0.0 -j DROP #CHINA
iptables -A INPUT -s 124.128.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 180.152.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 180.152.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 210.40.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 202.100.80.0/255.255.240.0 -j DROP #CHINA
iptables -A INPUT -s 202.96.192.0/255.255.248.0 -j DROP #CHINA
iptables -A INPUT -s 221.238.0.0/255.255.0.0 -j DROP #CHINA
iptables -A INPUT -s 222.184.0.0/255.248.0.0 -j DROP #CHINA
iptables -A INPUT -s 112.216.0.0/255.248.0.0 -j DROP #KOREA, REPUBLIC OF
iptables -A INPUT -s 121.88.0.0/255.255.0.0 -j DROP #KOREA, REPUBLIC OF
iptables -A INPUT -s 14.32.0.0/255.224.0.0 -j DROP #KOREA, REPUBLIC OF
iptables -A INPUT -s 219.240.0.0/255.254.0.0 -j DROP #KOREA, REPUBLIC OF
iptables -A INPUT -s 220.224.0.0/255.252.0.0 -j DROP #INDIA
iptables -A INPUT -s 217.160.0.0/255.255.0.0 -j DROP #INDIA
iptables -A INPUT -s 119.82.64.0/255.255.192.0 -j DROP #INDIA
iptables -A INPUT -s 18.0.0.0/255.0.0.0 -j DROP #
iptables -A INPUT -s 217.160.0.0/255.255.0.0 -j DROP #GERMANY
iptables -A INPUT -s 220.224.0.0/255.252.0.0 -j DROP #GERMANY
iptables -A INPUT -s 94.75.192.0/255.255.192.0 -j DROP #NETHERLANDS
iptables -A INPUT -s 94.75.192.0/255.255.192.0 -j DROP #NETHERLANDS
iptables -A INPUT -s 178.211.32.0/255.255.224.0 -j DROP #TURKEY
iptables -A INPUT -s 213.243.0.0/255.255.224.0 -j DROP #TURKEY
iptables -A INPUT -s 193.48.0.0/255.252.0.0 -j DROP #FRANCE
iptables -A INPUT -s 200.128.0.0/255.128.0.0 -j DROP #BRAZIL
iptables -A INPUT -s 210.188.0.0/255.252.0.0 -j DROP #JAPAN
iptables -A INPUT -s 212.33.64.0/255.255.224.0 -j DROP #POLAND
iptables -A INPUT -s 213.136.96.0/255.255.224.0 -j DROP #COTE D'IVOIRE
iptables -A INPUT -s 217.27.64.0/255.255.224.0 -j DROP #ITALY{% endhighlight %}


