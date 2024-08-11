# Networks

---

## VLANS/Subnets

The following tables outline the separate subnets/VLANS used for each site.

### Fall River

|Name     |VLAN |Subnet             |Description      |
|---------|-----|-------------------|-----------------|
|Default  |1    |192.168.0.0/24     |Native VLAN      |
|Trusted  |101  |192.168.1.0/24     |Trusted hosts    |
|Secure   |103  |192.168.3.0/24     |"Work" hosts     |
|Guest    |104  |192.168.4.0/24     |Guest devices    |
|VPN      |105  |192.168.5.0/24     |Remote devices   |
|Device   |106  |192.168.6.0/24     |IoT Devices      |
|Cameras  |107  |192.168.7.0/24     |Security Cameras |
|Gameing  |108  |192.168.8.0/24     |Gameing devices  |
|Servers  |127  |192.168.127.0/24   |Server devices   |

### Oconto

|Name     |VLAN |Subnet             |Description      |
|---------|-----|-------------------|-----------------|
|Default  |1    |192.168.128.0/24   |Native VLAN      |
|Trusted  |1129 |192.168.129.0/24   |Trusted hosts    |
|Secure   |1130 |192.168.130.0/24   |"Work" hosts     |
|Guest    |1131 |192.168.131.0/24   |Guest devices    |
|VPN      |1132 |192.168.132.0/24   |Remote devices   |
|Device   |1133 |192.168.133.0/24   |IoT Devices      |
|Cameras  |1134 |192.168.134.0/24   |Security Cameras |
|Gameing  |1135 |192.168.135.0/24   |Gameing devices  |
|Servers  |1136 |192.168.254.0/24   |Server devices   |

## Firewall Rules

## Guest Network
