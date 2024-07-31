---

title:  Configure Linux Network Interface
date:   2013-02-27 00:00:00 -0500
categories: IT
---

## Red Hat/Centos

Edit interface settings by editing the "/etc/sysconfig/network-scrips/ifcfg-eth0" file. The following settings will configure an interface to have a static IP address:

```text
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
NETMASK=255.255.255.0
IPADDR=192.168.1.27
USERCTL=no```
The following settings will configure an interface to use DHCP:


```text
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
```

Some additional details from <a href="http://www.centos.org/docs/5/html/5.1/Deployment_Guide/s2-networkscripts-interfaces-eth0.html">http://www.centos.org/docs/5/html/5.1/Deployment_Guide/s2-networkscripts-interfaces-eth0.html</a>

BOOTPROTO=<protocol>
where <protocol> is one of the following:

none â€” No boot-time protocol should be used.
bootp â€” The BOOTP protocol should be used.
dhcp â€” The DHCP protocol should be used.

BROADCAST=<address>
where <address> is the broadcast address. This directive is deprecated, as the value is calculated automatically with ifcalc.

DEVICE=<name>
where <name> is the name of the physical device

HWADDR=<MAC-address>
where <MAC-address> is the hardware address of the Ethernet device in the form AA:BB:CC:DD:EE:FF. This directive is useful for machines with multiple NICs to ensure that the interfaces are assigned the correct device names regardless of the configured load order for each NIC's module. This directive should not be used in conjunction with MACADDR.

IPADDR=<address>
where <address> is the IP address.

MACADDR=<MAC-address>
where <MAC-address> is the hardware address of the Ethernet device in the form AA:BB:CC:DD:EE:FF. This directive is used to assign a MAC address to an interface, overriding the one assigned to the physical NIC. This directive should not be used in conjunction with

NETMASK=<mask>
where <mask> is the netmask value.

ONBOOT=<answer>
where <answer> is one of the following:
yes â€” This device should be activated at boot-time.
no â€” This device should not be activated at boot-time.

## Debian

Edit interface settings by editing the "/etc/network/interfaces" file. The following settings will configure an interface to have a static IP address:

```text
iface eth0 inet static
address 192.168.1.5
netmask 255.255.255.0
gateway 192.168.1.254
```

The following settings will configure an interface to use DHCP:

```text
auto eth0
iface eth0 inet dhcp
```

Some additional details from <a href="http://www.debian.org/doc/manuals/debian-reference/ch05.en.html">http://www.debian.org/doc/manuals/debian-reference/ch05.en.html</a>

"auto <interface_name>" or "allow-auto <interface_name>"
start interface <interface_name> upon start of the system

"allow-hotplug <interface_name>"
start interface <interface_name> when the kernel detects a hotplug event from the interface

Lines started with "iface <config_name>" define the network configuration <config_name>
Lines started with "mapping <interface_name_glob>" define mapping value of <config_name> for the matching <interface_name>

Lines started with iface stanza has the following syntax.

```text
iface <config_name> <address_family> <method_name>
<option1> <value1>
<option2> <value2>
...
```
