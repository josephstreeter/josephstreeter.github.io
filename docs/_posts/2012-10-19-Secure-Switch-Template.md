---
layout: post
title:  Secure Switch Template
date:   2012-10-19 00:00:00 -0500
categories: IT
---






I think this is a good template to start with for configuring your layer 2 switches.

I have some "variables" for some information. They are prefixed with "str". This came from my attempts to create a vbscript to make config files. Be sure to change them to something more usefull. I've also selected an arbitrary VLAN number for the data VLAN. Really, anything other than VLAN 1 would be fine.

I have also added serial number and asset tag number for SNMP and banner purposes. It really has more to do with assisting administration tasks than it does securing the device.

There are no references to Voice VLAN or voice related traffic classification for VoIP traffic in this template.

I've also attached the Cisco guide to hardening IOS devices.

{% highlight powershell %}
no service pad
no service finger
no service tcp-small-servers
no service udp-small-servers
!
service tcp-keepalives-in
service tcp-keepalives-out
service timestamps debug datetime msec localtime show-timezone
service timestamps log datetime msec localtime show-timezone
service password-encryption
service sequence-numbers
!
hostname *strDevicename*
!
no logging console
enable secret 0 *strEnablesecret*
!
username *strUsername* password 0 *strUserpassword*
no aaa new-model
clock timezone CDT -6
clock summer-time CST recurring
system mtu routing 1500
vtp mode transparent
ip subnet-zero
no ip finger
no ip source-route
no ip gratuitous-arps
no ip domain-lookup
ip domain-name *strDomainname*
ip name-server *strPrimarydns*
ip name-server *strSecondarydns*
!
crypto key generate rsa
1024
!
spanning-tree mode rapid-pvst
no spanning-tree optimize bpdu transmission
spanning-tree extend system-id
spanning-tree uplinkfast
!
vlan internal allocation policy ascending
!
vlan 192
name ####_Data_VLAN_####
!
ip ssh time-out 60
ip ssh version 2
ip ssh authentication-retries 3
!
interface FastEthernet0/1
description #### UPS ####
switchport access vlan 192
switchport mode access
switchport nonegotiate
spanning-tree portfast
spanning-tree bpduguard enable
switchport port-security
switchport port-security max-mac-count 1
switchport port-security action shutdown
!
interface FastEthernet0/2
description #### Print Server ####
switchport access vlan 192
switchport mode access
switchport nonegotiate
spanning-tree portfast
spanning-tree bpduguard enable
switchport port-security
switchport port-security max-mac-count 1
switchport port-security action shutdown
!
interface range FastEthernet0/3 - *strPortnumber*
switchport access vlan 192
switchport mode access
switchport nonegotiate
spanning-tree portfast
spanning-tree bpduguard enable
switchport port-security
switchport port-security max-mac-count 1
switchport port-security action shutdown
!
interface range GigabitEthernet0/1 - 2
switchport trunk encapsulation dot1q
switchport trunk native vlan 192
switchport mode trunk
switchport trunk allowed vlan 192
switchport nonegotiate
!
interface Vlan1
description #### Default VLAN - Do NOT use ####
no ip address
no ip route-cache
no ip redirects
no ip unreachables
no ip proxy-arp
shutdown
!
interface Vlan192
description #### Management Interface ####
ip address *strManagementip* *strManagementnetmask*
no ip redirects
no ip unreachables
no ip proxy-arp
no ip route-cache
!
ip default-gateway *strDefaultgateway*
no ip http server
no ip http secure-server
logging facility local6
logging strSyslog-server
snmp-server community *strSnmp-communityreadonly* RO
snmp-server community *strSnmp-communityreadwrite* RW
snmp-server location *strLocation*
snmp-server chassis-id sn# *strDevicesn* Asset# *strDeviceassettag*
snmp ifmib ifindex persist
!
banner motd %
*strDevicename*   *strLocation*
NOTICE TO USERS
###############################################################
This is an official computer system and is the property of the
*strOrganization*. It is for authorized users only.
Unauthorized users are prohibited. Users (authorized or unauthorized)
have no explicit or implicit expectation of privacy. Any or all uses
of this system may be subject to one or more of the following actions:
interception,  monitoring, recording, auditing, inspection and disclosing
to security personnel and law enforcement personnel, as well as authorized
officials of other agencies, both domestic and foreign. By using this
system, the user consents to these actions. Unauthorized or improper
use of this system may result in administrative disciplinary action
and civil and criminal penalties. By accessing this system you
indicate your awareness of and consent to these terms and conditions
of use. Discontinue access immediately if you do not agree to the
conditions stated in this notice.^
###############################################################
%
!
line con 0
exec-timeout 5 0
password 0 *strConsolepassword*
logging synchronous
login local
line vty 0 4
exec-timeout 5 0
password 0 *strVtypassword*
logging synchronous
login local
transport input ssh
line vty 5 15
exec-timeout 5 0
password 0 *strVtypassword*
logging synchronous
login local
transport input ssh
!
ntp server *strNtpserver*
end
{% endhighlight %}


