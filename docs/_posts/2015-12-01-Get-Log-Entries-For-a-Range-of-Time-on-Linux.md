---
layout: post
title:  Get Log Entries For a Range of Time on Linux
date:   2015-12-01 00:00:00 -0500
categories: IT
---







You need to check the logs for a problem and you know when it occurred. This will allow you to grab all of the entries for a period of time to make the search for clues easier.

{% highlight powershell %}
sudo cat secure | awk '/^Dec  1 09:27/,/^Dec  1 09:33/'
Dec  1 09:03:09 u16532612 sshd[24297]: Failed password for root from 43.229.53.54 port 43335 ssh2
Dec  1 09:03:12 u16532612 sshd[24297]: Failed password for root from 43.229.53.54 port 43335 ssh2
Dec  1 09:03:14 u16532612 sshd[24297]: Failed password for root from 43.229.53.54 port 43335 ssh2
{% endhighlight %}


