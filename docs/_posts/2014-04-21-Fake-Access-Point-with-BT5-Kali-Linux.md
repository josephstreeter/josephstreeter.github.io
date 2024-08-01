---
title:  Fake Access Point with BT5/Kali Linux
date:   2014-04-21 00:00:00 -0500
categories: IT
---

I'm not sure who to credit with the writing of the script below. It's all over the Internet and I haven't been able to determine with any certainty who originally wrote it.

While technically a way to attack wireless clients, I just wanted a quick way to set up and access point. This worked out well since I had a BackTrack 5 VM, a USB wireless NIC, some familiarity with the Aircrack suite, and a bit of free time.

This post assumes that you already have the Aircrack tools installed. You will also have to install and configure DHCP.

```bash
apt-get install dhcp3-server
```

Configure a DHCP scope for use by the wireless clients that connect to your access point. You can edit the one at â€œ/etc/dhcp3/dhcpd.conf or create a separate one for this task. Just be sure to change the final script to point at the new file location if you create a new one.

```bash
ddns-update-style ad-hoc;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 10.0.0.0 netmask 255.255.255.0 {
option subnet-mask 255.255.255.0;
option broadcast-address 10.0.0.255;
option routers 10.0.0.254;
option domain-name-servers 8.8.8.8;
range 10.0.0.1 10.0.0.140;
}
```

While this configuration uses Google's DNS for name resolution you may want to configure BIND as well. This may be useful for other reasons...just sayin'.

Use the below script to configure your NIC, DHCP, and start the AP. Be sure to cha

```bash
#!/bin/bash

echo "Killing Airbase-ng..."
pkill airbase-ng
sleep 2;
echo "Killing DHCP..."
pkill dhcpd3
sleep 5;

echo "Putting Wlan In Monitor Mode..."
airmon-ng stop wlan0 # Change to your wlan interface
sleep 5;
airmon-ng start wlan0 # Change to your wlan interface
sleep 5;
echo "Starting Fake AP..."
airbase-ng -e FreeWifi -c 11 -v wlan0 &amp; # Change essid, channel and interface
sleep 5;

ifconfig at0 up
# Change IP addresses as configured in your dhcpd.conf
ifconfig at0 10.0.0.254 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.254

sleep 5;

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o eth3 -j MASQUERADE # Change eth3 to your internet facing interface

echo > '/var/lib/dhcp3/dhcpd.leases'
ln -s /var/run/dhcp3-server/dhcpd.pid /var/run/dhcpd.pid
dhcpd3 -d -f -cf /etc/dhcp3/dhcpd.conf at0 &amp;

sleep 5;
echo "1" > /proc/sys/net/ipv4/ip_forward
```
