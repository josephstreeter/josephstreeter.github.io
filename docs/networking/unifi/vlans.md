# VLANs

This document outlines the VLAN and subnet configuration for each site in the Unifi environment. Use these tables as a reference for network segmentation, device assignment, and firewall rule planning.

---

## VLANs/Subnets

The following tables outline the separate subnets and VLANs used for each site.

### Fall River

| Name    | VLAN | Subnet           | Description        |
|---------|------|------------------|--------------------|
| Default | 1    | 192.168.0.0/24   | Native VLAN        |
| Trusted | 101  | 192.168.1.0/24   | Trusted hosts      |
| Secure  | 103  | 192.168.3.0/24   | "Work" hosts       |
| Guest   | 104  | 192.168.4.0/24   | Guest devices      |
| VPN     | 105  | 192.168.5.0/24   | Remote devices     |
| Device  | 106  | 192.168.6.0/24   | IoT Devices        |
| Cameras | 107  | 192.168.7.0/24   | Security Cameras   |
| Gaming  | 108  | 192.168.8.0/24   | Gaming devices     |
| Servers | 127  | 192.168.127.0/24 | Server devices     |

---

### Oconto

| Name    | VLAN  | Subnet            | Description        |
|---------|-------|-------------------|--------------------|
| Default | 1     | 192.168.128.0/24  | Native VLAN        |
| Trusted | 1129  | 192.168.129.0/24  | Trusted hosts      |
| Secure  | 1130  | 192.168.130.0/24  | "Work" hosts       |
| Guest   | 1131  | 192.168.131.0/24  | Guest devices      |
| VPN     | 1132  | 192.168.132.0/24  | Remote devices     |
| Device  | 1133  | 192.168.133.0/24  | IoT Devices        |
| Cameras | 1134  | 192.168.134.0/24  | Security Cameras   |
| Gaming  | 1135  | 192.168.135.0/24  | Gaming devices     |
| Servers | 1136  | 192.168.254.0/24  | Server devices     |

---

## Firewall Rules

_Describe or list your firewall rules here. For example:_

- Restrict traffic between Guest and Trusted VLANs.
- Allow IoT devices outbound internet access only.
- Block inter-VLAN routing except where explicitly allowed.

---

## Guest Network

_Describe your guest network setup here. For example:_

- Guest VLAN is isolated from all other VLANs.
- Captive portal enabled for guest authentication.
- Bandwidth limits applied to guest devices.

---

**Legend:**

- **VLAN:** Virtual LAN identifier.
- **Subnet:** IP address range assigned to the VLAN.
- **Description:** Purpose or typical devices assigned to
