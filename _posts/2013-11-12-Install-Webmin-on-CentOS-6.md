---
layout: post
title:  Install Webmin on CentOS 6
date:   2013-11-12 00:00:00 -0500
categories: IT
---






Webmin makes it easy to perform administrative tasks via a web interface. Once the Webmin repos are installed the package can be installed using Yum.

Download and install the key for the Webmin repo
{% highlight powershell %}wget http://www.webmin.com/jcameron-key.asc
rpm --import jcameron-key.asc{% endhighlight %}

Create a file for the Webmin repo
{% highlight powershell %}vi /etc/yum.repos.d/webmin.repo{% endhighlight %}
Add the repo information to the repo file
{% highlight powershell %}[Webmin] name=Webmin Distribution Neutral
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1{% endhighlight %}
Install Webmin package
{% highlight powershell %}yum â€“y install webmin{% endhighlight %}


