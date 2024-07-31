---

title:  Notes From My Postfix Setup
date:   2013-09-08 00:00:00 -0500
categories: IT
---






Just so that I don't have to keep looking this stuff up over and over again.

Configure Postfix main.cf
```powershell/etc/postfix/main.cf
# The host name of the system
myhostname = mail.domain.tld
# The domain name for the email server
mydomain = domain.tld
# The domain name that locally-posted email appears to have come from
myorigin = $mydomain
# Network interfaces that Postfix can receive mail on
inet_interfaces = all
# The list of domains that will be delivered
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
# Trusted IP addresses that may send or relay mail through the server
mynetworks = 192.168.0.0/24, xxx.xxx.xxx.xxx/32, 127.0.0.0/8
# List of destination domains this system will relay mail to
relay_domains =
# Path of the mailbox relative to the users home directory
home_mailbox = Maildir/```

Configure Postfix to listen on custom port
```powershell/etc/postfix/master.cf
Change:
smtp inet n - n - - smtpd```
to:
```powershell587 inet n - n - - smtpd```
Allow SMTP traffic to the custom port
```powershelliptables -A INPUT -p tcp -dport 587 -j ACCEPT```
Create Aliases
```powershellvi /etc/aliases
admin:  root
postmaster: root```
View the mail queue
```powershellmailq```


Flush the mail queue
```powershellpostqueue -f```



