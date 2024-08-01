---
title:  Get a List of Unique IP Addresses from a Log File
date:   2012-10-19 00:00:00 -0500
categories: IT
---

I wanted to create an iptables firewall script based on the IPs of hosts that are trying unauthorized access to my public linux host. This is how I got the list of IPs from the "/var/log/auth.log" file:

```bash
less /var/log/auth.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq
```

You have to love regular expressions. The hard part will be looking up all of the subnet masks so that I can block the entire network.

Maybe I should just block everything and only allow connections from North America.
