---
title:  Another Article About QoS for Non-work Related Traffic (Networkers-Online)
date:   2012-10-18 00:00:00 -0500
categories: IT
---

More info on QoS to help make sure the traffic you need to get through gets though. This one puts time limits on the policies. I find QoS to be so cool.

- [Networkers-Online](http://www.networkers-online.com/blog/index.md)
- [Limiting non-business related applications during work hours](http://www.networkers-online.com/blog/2008/07/limiting-non-business-related-applications-during-work-hours/index.md)


In this post we will explore how to limit or even stop your employees from using applications that are not related to the business during work hours.
In the following example I am going to use HTTP as an example for unwanted applications, you can specify any type of application you would like to limit or stop (file sharing, chatting, downloading ..)
***Configuration Steps:***
1- create your time range in which these applications will be deined as show below

This timerange matches everyday from 9am to 5pm expcet weekends

```text
time-range WEEKDAYS<br />
periodic ***weekdays ***9:00 to 17:00</td>
```

2- Identify non-business applications using an ACL and attach the time-range to it. If you want to drop this traffic completely you can just attach this ACL to an interface.

Specify all types of traffic you need to limit

```text
access-list 180 permit tcp any any eq ***www ***time-range ***WEEKDAYS***
```

3- Classify this traffic using class-map commands and configure your policy map to ***police*** this traffic to what ever suitable value may be 64Kbps or drop them as I am doing in the configuration below:

```text
class-map match-all NON-WORK-APPS
match access-group 180policy-map WORK-POLICY
class NON-WORK-APPS
drop
```

4- Apply the policy map to the router interface in the right direction.

```text
int f0/0<br />
service-policy output WORK-POLICY</td>
```

***Operation verfication:***

```console
R1#show clock<br />
*** 10:03:59.183*** UTC ***Mon ***Jun 2 2008
```

Notice the ACL is active as the time is matching the time range.

```console
R1#sh access-list 180
Extended IP access list 180
10 permit tcp any any eq www time-range WEEKDAYS ***(active) (4 matches)***
R1#sh policy-map int f0/0
FastEthernet0/0
Service-policy output: WORK-POLICY
Class-map: WORK-APPS (match-all)
*** 4 packets, 240 bytes***
5 minute offered rate 0 bps, drop rate 0 bps
Match: access-group 180
drop
Class-map: class-default (match-any)
69 packets, 6349 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

***using telnet to port 80 to test the configuration***

```console
R1#telnet 192.168.12.2 80
Trying 192.168.12.2, 80
% ***Connection timed out***; remote host not responding
```

Notice the increment in the dropped number of packets

```console
R1#sh policy-map int f0/0
FastEthernet0/0
Service-policy output: WORK-POLICY
Class-map: WORK-APPS (match-all)
*** 8 packets, 480 bytes***
5 minute offered rate 0 bps, drop rate 0 bps
Match: access-group 180
drop
Class-map: class-default (match-any)
80 packets, 7557 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

***Now lets set the clock outside our defined time range to check the operation.***

```console
R1#clock set ***18:0:0*** 2 june 2008
R1#show access-list 180<br />
Extended IP access list 180<br />
10 permit tcp any any eq www time-range WEEKDAYS ***(inactive) (8 matches)***
***!telnet to port 80 succeeded***
R1#telnet 192.168.12.2 80
Trying 192.168.12.2, 80  ***Open ***
```

That was a basic example you can modify to suite your organization policy by changing any of the configuration parameters.
