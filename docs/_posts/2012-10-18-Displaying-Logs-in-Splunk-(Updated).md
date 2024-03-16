---
layout: post
title:  Displaying Logs in Splunk (Updated)
date:   2012-10-18 00:00:00 -0500
categories: IT
---






<a href="http://ubuntuforums.org/showthread.php?t=900745">HOWTO: Simple Splunk install and config</a>

INSTALLING SPLUNK

1) Navigate to the /opt directory (the default for most Splunk installs... don't ask me why)
2) Grab Splunk from the offical repositories with the wget command
3) Unpack the downloaded .tgz file using tar
4) Run the script to install/start Splunk

{% highlight powershell %}
cd /opt

sudo wget 'http://www.splunk.com/index.php/download_track?file=3.4.8/linux/splunk-3.4.8-54309-Linux-i686.tgz&ac=&wget=true&name=wget&typed=releases'
sudo tar xvfz splunk-3.4.6-51113-Linux-i686.tgz
sudo splunk/bin/splunk start
{% endhighlight %}

Here is the link for 4.2.2
{% highlight powershell %}
wget -O splunk-4.2.2-101277-linux-2.6-amd64.deb 'http://www.splunk.com/index.php/download_track?file=4.2.2/splunk/linux/splunk-4.2.2-101277-linux-2.6-amd64.deb&ac=&wget=true&name=wget&typed=releases'
{% endhighlight %}
Accept the E.U.L.A. and your install is complete. The pretty web UI is now waiting for you at http://your.server.ip.address:8000 Simple, no?



UPGRADING SPLUNK
Stop the old version, download the new version and extract it in the same folder. Start Splunk back up and it will recognize the upgrade.

{% highlight powershell %}
cd /opt
sudo splunk/bin/splunk stop
sudo wget 'new-splunk-version-link-goes-here'
sudo tar xvfz new-splunk-downloaded-version.tgz
sudo splunk/bin/splunk start
{% endhighlight %}

CONFIGURING SPLUNK
This step will vary, depending on your needs. I still recommend a few settings for everyone:

Listen for logs on port 514:
Most devices and many apps (including syslog) use port 514 for sending log info. You'll want Splunk to be listening.
navigate to your Splunk web UI (http://your.server.ip.address:8000)
click "Admin"
click "Data Inputs"
click "Network Ports"
"New Input" button.
choose "UDP" and the port number will automagically change to 514.
click the "Submit" button to save the configuration change

Start upon bootup:
Pretty self-explanatory. When the machine boots up, so does Splunk.

Code:
{% highlight powershell %}
sudo /opt/splunk/bin/splunk enable boot-startOnly allow certain IP addresses to access the Web UI:
Since the free version of Splunk doesn't secure the web UI, I lock down access to all that sensitive information through iptables. Obviously, you'll want to replace "ip.address1.to.allow" with your address or a range you want to allow access from (i.e. 10.10.10.35 or 10.10.10.0/24).
{% endhighlight %}

Code:
{% highlight powershell %}
sudo iptables -A INPUT -s ip.address1.to.allow -p tcp --dport 8000 -j ACCEPT
sudo iptables -A INPUT -s ip.address2.to.allow -p tcp --dport 8000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000 -j DROP
{% endhighlight %}

SEND MAC/LINUX LOGS TO SPLUNK:

This is a two step process where you add your Slunk server to the list of known hosts on the client machine and then tell the syslog process to forward logs to Splunk.

Add the following line to /etc/hosts (NOTE: Use tabs, spaces won't work.)


Code:
{% highlight powershell %}
ip.address.of.splunkserver			 splunkserver
{% endhighlight %}

Where splunkserver is the name of your Splunk server. Now, add the following lines to /etc/syslog.conf:


Code:
{% highlight powershell %}
# additional config for sending logs to splunk
*.info
{% endhighlight %}
@splunkseverWhere *.info is the level of detail you desire to be sent.


SEND WINDOWS LOGS TO SPLUNK

Download and Install Snare here: <a href="http://www.intersectalliance.com/download.html?link=http://prdownloads.sourceforge.net/snare/SnareSetup-3.1.2-MultiArch.exe">http://www.intersectalliance.com/dow...-MultiArch.exe</a>

Open the Snare interface to configure its log management:
Click on "Network Configuration"
Set the "Destination Snare Server Address" to Splunk's IP
Change "Destination Port" to 514
Click the checkbox to "Enable SYSLOG header"
Select your desired "Syslog Priority" level from the drop down menu.
Click the "Change Configuration" button

You might need to add an exception for Snare in the Windows Firewall. (tested in XP)
Navigate to the Windows Firwall settings (Start > Control Panel > Windows Firewall)
Click on the Exceptions Tab
Click the "Add Program" button
Browse to C:\Program Files\Snare\SnareCore (or wherever you installed Snare)


