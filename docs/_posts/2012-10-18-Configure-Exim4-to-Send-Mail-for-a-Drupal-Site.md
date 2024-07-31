---

title:  Configure Exim4 to Send Mail for a Drupal Site
date:   2012-10-18 00:00:00 -0500
categories: IT
---

Steps to configure Exim4 on Debian in order to send mail for a Drupal site. I haven't had the chance to try it our yet, but it looks reasonalble.
Taken from [Howto - Drupal Install on Debian or Ubuntu - dimmeria](http://dimmeria.com/node/1)

Step 6a exim4 - outgoing mail

So I thought drupal was set up right. Wrong. My friend tried to create an account, and he never got emailed his password. wtf, mate? Debian installed exim4 for me automatically when I installed - but it was not configured properly. Here is how you configure exim4 on debian so that it will work with drupal (and should work with everything else too). At the command line, run: dpkg-reconfigure exim4-config Go through the configuration script. Your setup may vary from mine. Here are the steps I took:

1. Do not break up the configuration file into smaller files - why make things more complicated for myself?
2. "internet site; mail is sent and received directly using SMTP"
3. mailname="dimmeria.com"
4. IPs to listen on ="127.0.0.1:192.168.0.x" where x is the last digit of my LAN ip. eg 192.168.0.5
5. other final destinations = blank
6. relay mail for domains - blank
7. Relay mail for local machines - 192.168.0.0/24 (meaning 192.168.0.[1-255])
8. Dial-on-demand: this is only necessary if you don't have a constant internet connection - you'll probably want to select no

Finally, do a

```console
update-exim4.conf
/etc/init.d/exim4 restart
```

Then test your email with drupal. If anyone has any mail problems, please post them here in the comments.

Section 6b - exim4 alternate

I actually wrote section 6b before I wrote section 6a, but then my mail stopped working after 2 days. The steps in section 6a work for me, so I consider them better. For those who are brave, or desperate, here is an alternate configuration. At the command line, run: dpkg-reconfigure exim4-config Go through the configuration script. Your setup may vary from mine. Here are the steps I took:

1. Do not break up the configuration file into smaller files - why make things more complicated for myself?
2. "Mail sent by smarthost; received via SMTP or fetchmail"
3. mailname="dimmeria.com"
4. IPs to listen on ="127.0.0.1:192.168.0.x" where x is the last digit of my LAN ip. eg 192.168.0.5
5. other final destinations = blank
6. relay mail for LAN IPs only - "192.168.0.0/24"
7. hostname for outgoing mail: "smtp.dslextreme.com" This is because my isp is dslextreme.com. To make life easier for myself, I'm using their smtp server to send mail. I don't know how to configure exim to send mail to any mail server..such as gmail or yahoo. Yours might be "smtp.mywebhost.com" or "mail.myisp.com" .
8. Hide local mail name? This is up to you. If you want your mail to come from "mydrupalsite.com" then select no. If you want your mail to come from something you create eg "myemailaddress.com" then select yes. I selected no.
9.Dial-on-demand: this is only necessary if you don't have a constant internet connection - you'll probably want to select no
