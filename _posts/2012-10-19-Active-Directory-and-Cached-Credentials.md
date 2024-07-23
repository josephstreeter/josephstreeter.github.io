---
layout: post
title:  Active Directory and Cached Credentials
date:   2012-10-19 00:00:00 -0500
categories: IT
---






We usually just take for granted that cached credentials work. Ever wonder how they work?

<hr>

From "Web Active Directory LLC"

<a href="http://blog.webactivedirectory.com/2011/06/09/windows-active-directory-cached-user-credentials/">Windows Active Directory Cached User Credentials
</a>

<hr>

From the AD Troubleshooting Blog
<a href="http://blogs.technet.com/b/instan/archive/2011/08/29/the-effect-on-cached-log
ons-when-smart-card-is-required-for-interactive-logon-is-set.aspx">The effect on Cached Logons when Smart Card is required for interactive logon is set</a>

<hr>

From the "Ask the Directory Services Team" blog:

<a href="http://blogs.technet.com/b/askds/archive/2011/04/15/friday-mail-sack-now-with-100-more-words.aspx">Friday Mail Sack: Now with 100% more words<a>
{% highlight powershell %}
We don't do a great job in documenting how the cached interactive logon credentials work. There is some info here that might be helpful, but it's fairly limited:

How Interactive Logon Works
<a href="http://technet.microsoft.com/en-us/library/cc780332(v=WS.10).aspx">http://technet.microsoft.com/en-us/library/cc780332(v=WS.10).aspx</a>

But from hearing this scenario many times, I can tell you that you are seeing expected behavior. Since a user is logging on interactively with cached creds (stored here in an encrypted form: HKEY_LOCAL_MACHINE\Security\Cache) while offline to a DC in your scenario, then they get a network created and access resources, anything that only happens at the interactive logon phase is not going to work. For example, logon scripts delivered by AD or group policy. Or security policies that apply when the computer is started back up (and won't apply for another 90-120 minutes while VPN connected â€“ which may not actually happen if the user only starts VPN for short periods).

I made a hideous flowchart to explain this better. It works â€“ very oversimplified  â€“ like <a href="http://blogs.technet.com/cfs-file.ashx/__key/CommunityServer-Blogs-Components-WeblogFiles/00-00-00-58-02-metablogapi/2474.image_5F00_502813A3.png">this</a>:

As you can see, with a VPN not yet running, it is impossible to access a number of resources at interactive logon. So if your application's â€œresource authentication only works at interactive logon, there is nothing you can do unless the app changes.

This is why we created VPN at Logon and DirectAccess â€“ there would be no reason to make use of those technologies otherwise.

How to configure a VPN connection to your corporate network in Windows XP Professional
<a href="http://support.microsoft.com/kb/305550">http://support.microsoft.com/kb/305550</a>

Where Is â€œLogon Using Dial-Up Connections in Windows Vista?
<a href="http://blogs.technet.com/b/grouppolicy/archive/2007/07/30/where-is-logon-using-dial-up-connections-in-windows-vista.aspx">http://blogs.technet.com/b/grouppolicy/archive/2007/07/30/where-is-logon-using-dial-up-connections-in-windows-vista.aspx</a>

DirectAccess
<a href="http://technet.microsoft.com/en-us/network/dd420463.aspx">http://technet.microsoft.com/en-us/network/dd420463.aspx</a>

If you have a VPN solution that doesn't allow XP to create the â€œdial-up network at interactive logon, that's something your remote-access vendor has to fix. Nothing we can do for you I'm afraid.
{% endhighlight %}



