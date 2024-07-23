---
layout: post
title:  Install Cacti on Debian Squeeze
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Not too hard to get started. Once you have SNMPD installed and working just run:
{% highlight powershell %}
apt-get install cacti
{% endhighlight %}
When that is complete you will have to modify the Apache config.
Add the follwing to "/etc/apache2/sites-available/default" between the VirtualHost tags:
{% highlight powershell %}
Alias /cacti/ "/usr/share/cacti/site/"
<Directory "/usr/share/cacti/site/">
Options Indexes MultiViews FollowSymLinks
AllowOverride None
Order allow,deny
Allow from all
</Directory>
{% endhighlight %}
Then restart Apache:
{% highlight powershell %}
invoke-rc.d apache2 restart
{% endhighlight %}
Use the url http://hostname/cacti and log in with the username <b>admin</b> and password <b>admin</b>. You will be asked to change the password and then you're in!



