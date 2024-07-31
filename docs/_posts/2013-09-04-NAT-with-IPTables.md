---
title:  NAT with IPTables
date:   2013-09-04 00:00:00 -0500
categories: IT
---

Turn on IP forwarding

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Configure IPTables rules. The following code assumes that interface "eth0" is connected to the public network and interface "eth1" is connected to the private network.

```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
```

Once you've run the commands and verified that it works you can save the config

```bash
/sbin/service iptables save
```
