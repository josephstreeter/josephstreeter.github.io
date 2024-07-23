---
layout: post
title:  Create Legacy IPsec Policy from CLI
date:   2013-08-13 00:00:00 -0500
categories: IT
---






The following commands can be used to script the creation of legacy IPsec policies. The example here creates an IPsec policy meant to secure all IP traffic between domain controllers in separate forests in order to secure AD forest trust traffic.
This example uses PSK for authentication, but you should use certificates if possible.

Create the IPsec policy:
{% highlight powershell %}netsh ipsec static add policy name="AD Trusts" description="AD Forest Trust traffic" mmpfs="no" mmlifetime="10" activatedefaultrule="no" pollinginterval="5" assign=no mmsec="3DES-SHA1-2"{% endhighlight %}
Create a filter action:
{% highlight powershell %}netsh ipsec static add filteraction name="ESP-3DES-SHA1-0-3600" description="Require ESP 3DES/SHA1, no inbound clear, no fallback to clear, No PFS" qmpfs=no inpass=no soft=no action=negotiate qmsecmethods="ESP[3DES,SHA1]:3600s"{% endhighlight %}
Note: In the filter action example the name of the filter action reflects the settings in the filter action. This makes it easier to create reusable filter actions.
Create the filter list:
{% highlight powershell %}netsh ipsec static add filterlist "Domain Controllers"{% endhighlight %}
Create filters and add them to the filter list:
{% highlight powershell %}netsh ipsec static add filter filterlist="Domain Controllers" description="MyDC1 - TheirDC1" srcaddr=192.168.0.10 dstaddr=172.16.10.20
netsh ipsec static add filter filterlist="Domain Controllers" description="MyDC2 - TheirDC3" srcaddr=192.168.0.11 dstaddr=172.16.10.21
netsh ipsec static add filter filterlist="Domain Controllers" description="MyDC3 - TheirDC3" srcaddr=192.168.0.12 dstaddr=172.16.10.22{% endhighlight %}
Create a rule in the IPsec policy we created using the filter list and filter action that we created:
{% highlight powershell %}netsh ipsec static add rule name="My Forest - Their Forest" policy="AD Trusts" filterlist="Domain Controllers" filteraction="ESP-3DES-SHA1-0-3600" kerberos="no" psk="my complex password"{% endhighlight %}



