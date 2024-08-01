---
title:  Restart a Number of Services at Once
date:   2012-10-18 00:00:00 -0500
categories: IT
---

The following line of code will restart each of the listed services one after another.

```bash
for i in rsyslog apache2 postfix mysql slapd postfix-policyd dovecot amavis clamav-daemon clamav-freshclam cron iredapd iptables; do /etc/init.d/${i} restart; done
```
