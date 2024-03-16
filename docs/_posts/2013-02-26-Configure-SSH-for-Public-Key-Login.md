---
layout: post
title:  Configure SSH for Public Key Login
date:   2013-02-26 00:00:00 -0500
categories: IT
---






Some quick notes on creating and using a key pair for SSH logon.

1. Generate key pair on the client.
{% highlight powershell %}ssh-keygen -t rsa -b 2048{% endhighlight %}
2. Enter a passphrase when prompted. If you do not want a password so that you can use this key pair for automating logons just press Enter twice.
3. Copy the public key from the client to the server
{% highlight powershell %}scp ./ssh/id_rsa.pub username@server:.ssh/authorized_keys{% endhighlight %}
The ssh-copy-id command, if it is available, can be used to copy the public key to the server as well.
{% highlight powershell %}ssh-copy-id username@server{% endhighlight %}
4. Secure the .ssh folder on the server
{% highlight powershell %}
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
{% endhighlight %}


