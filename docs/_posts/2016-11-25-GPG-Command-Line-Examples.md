---
layout: post
title:  GPG Command Line Examples
date:   2016-11-25 00:00:00 -0500
categories: IT
---






Here are some GPG examples for creating symmetric and asymmetric encrypted messages. The code used below is written for PowerShell.

Download keys from a key server
{% highlight powershell %}
gpg --keyserver pgp.mit.edu --search-keys streeter76@gmail.com
gpg --keyserver pgp.mit.edu --recv-keys 88488596
{% endhighlight %}

Import private key
{% highlight powershell %}
gpg --import ./private.asc
{% endhighlight %}

Put the contents of a file into a variable to be encrypted
{% highlight powershell %}
$a = gc /etc/passwd
{% endhighlight %}

Symmetric encryption of the variable contents
{% highlight powershell %}
$a | gpg --symmetric --armor
# Decrypt the message
$a | gpg --decrypt
{% endhighlight %}

Symmetric encryption of the variable contents with the passphrase provided
{% highlight powershell %}
$a | gpg --symmetric --armor --passphrase password
# Decrypt the message with the passphrase provided
$a | gpg --decrypt --passphrase password
{% endhighlight %}

Encrypt the variable contents for a recipient
{% highlight powershell %}
$a | gpg -e -r joseph.streeter76@gmail.com --armor
{% endhighlight %}

Decrypt the message sent to recipient
{% highlight powershell %}
$b | gpg -d
{% endhighlight %}


