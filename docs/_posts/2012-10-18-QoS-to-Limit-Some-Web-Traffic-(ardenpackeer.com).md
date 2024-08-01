---
title:  QoS to Limit Some Web Traffic (ardenpackeer.com)
date:   2012-10-18 00:00:00 -0500
categories: IT
---

I came across this blog post one day while doing some research on QoS. I've seen sites like youtube take down network links so that users could not do real work.
I would really like to use this somewhere. I guess it is a solution searching for a problem at this point. My hat is off to the author.

<br />
## <a href="http://ardenpackeer.com">ardenpackeer.com</a>
<a href="http://ardenpackeer.com/qos-voip/tutorial-how-to-use-cisco-mqc-nbar-to-filter-websites-like-youtube/">Tutorial: How to use Cisco MQC & NBAR to filter websites like YouTube</a>
<br />
I was asked a great question by one of my clients regarding filtering of websites. He had filtered http://www.youtube.com/ and http://video.google.com.au/ at his proxy server but with the number of different video sites popping up (metacafe, jibjab etc etc), his filters just couldn&#8217;t keep up&#8230;and neither could his bandwidth!
One solution to this problem is the use of Cisco&#8217;s Network Based Application Recognition (NBAR). NBAR is a deep packet inspection and classification engine. It was first introduced in experimental versions of IOS v12.1 and can be used with Cisco&#8217;s <a href="http://www.cisco.com/univercd/cc/td/doc/product/software/ios124/124cg/hqos_c/part40/qctmcli2.htm">Modular Quality Of Service Command Line (MQC)</a>.
In this article we will look at using MQC to filter websites. I will demonstrate using the <a href="http://www.cisco.com/univercd/cc/td/doc/product/software/ios124/124cr/hqos_r/qos_m1h.htm#wp1128712">match protocol http</a> command to match a URL, a host or MIME type. We will use the following topology for demonstration:
<img src="http://www.joseph-streeter.com/sites/default/files/topology1_0.jpg" alt="Network Topology - Webserver" style="width:95%;" />R3 will act as a webserver and R1 as a client. The filtering will be applied on R2. You can download the dynamips .net file the following topology <a href="http://ardenpackeer.com/wp-content/uploads/2007/12/webserver.net" >here</a>.<br />
R1 Base Configuration:
<br />

```console
hostname R1
!
int s1/0
ip add 10.0.12.1 255.255.255.0
no shut
!
router ospf 1
network 10.0.12.1 0.0.0.0 area 0
```

## R2 Base Configuration

```console
hostname R2
!
int s1/0
ip add 10.0.12.2 255.255.255.0
no shut
!
int s1/1
ip add 10.0.23.2 255.255.255.0
no shut
!
router ospf 1
network 10.0.12.2 0.0.0.0 area 0
network 10.0.23.2 0.0.0.0 area 0
```

## R3 Base Configuration

```console
hostname R3
!
int s1/0
ip add 10.0.23.3 255.255.255.0
no shut
!
int f0/0
ip add 192.168.1.100 255.255.255.0
no shut
!
router ospf 1
network 10.0.23.3 0.0.0.0 area 0
!
ip http server
ip http path flash:
```

We have set up R3 as a webserver. Details on how to setup R3 as a webserver using IOS can be found <a href="http://ardenpackeer.com/ios-features-management/how-to-set-up-a-cisco-router-as-a-webserver/" >here</a>.

```console
R3#sh run | in ip http
ip http server
no ip http secure-server
ip http path flash:
```

```console
R3#dir
Directory of flash:/

1  -rw-          90                    <no>  picture.gif
2  -rw-         329                    <no>  picture.jpg
3  -rw-         174                    <no>  index.html

8388604 bytes total (8387812 bytes free)
```<br />
***Basic HTTP Filtering using NBAR***
Lets set up basic http filtering with MQC on R2.

```powershellR2(config)#class-map match-all MATCH-HTTP
R2(config-cmap)#match protocol http
R2(config-cmap)#exit
R2(config)#policy-map HTTP-POLICY
R2(config-pmap)#class MATCH-HTTP
R2(config-pmap-c)#set dscp af13
R2(config-pmap-c)#exit
R2(config-pmap)#int s1/0
R2(config-if)#service-policy input HTTP-POLICY```<br />
In the code above we have a class map called MATCH-HTTP. The match protocol http command tells NBAR to match the http protocol. This will match all http traffic. The MATCH-HTTP class is then utilized in the HTTP-POLICY policy map. This policy map is used to set a DSCP marking on all traffic that matches the MATCH-HTTP class (ie all http traffic). The policy is then implemented on R2&#8217;s s1/0. Traffic is inspected and marked as it comes into that interface.
We can check how many packets have been marked using the show policy-map command.

```console
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
2 packets, 168 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
R2#
```

Lets generate some http traffic, and see if our policy marks some packets.

```console
R1#copy http://10.0.23.3/index.html null:
Loading http://10.0.23.3/index.html
174 bytes copied in 0.544 secs (320 bytes/sec)
```

```console
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
5 packets, 344 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http
QoS Set
dscp af13
Packets marked 5

Class-map: class-default (match-any)
124 packets, 10340 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

We used the ***copy http://10.0.23.3/index.html null:*** command to generate some http traffic. We can see above that 5 packets were generated and were marked as af13. All other traffic will fall into the class-default class. With the packets marked, we could forward them or drop them.
Instead of matching all of the http protocol we can use NBAR to look further into the packet and classify or drop packets based on the host requested.

***Match protocol HTTP host***
The match protocol HTTP url command is used to match a url. It takes a regular expression as an argument. For example:

```console
match protocol http host *youtube.com*
! This would match anything in youtube.com like http://www.youtube.com or http://video.youtube.com
!
match protocol http host *google*
! This would match anything with google in the host like http://mail.google.com or
http://www.google.com.au
!
match protocol http host google*
! This would match http://google.com but not http://video.google.com
```

Lets set up R2 to filter based on a host.

```console
R2(config)#class-map MATCH-HTTP
R2(config-cmap)#no match protocol http
R2(config-cmap)#match protocol http host 10.0.23.3
```

```console
R2#clear counters s1/0
Clear "show interface" counters on this interface [confirm]
*Mar  1 00:04:42.071: %CLEAR-5-COUNTERS: Clear counter on interface Serial1/0 by console
R2#
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http host "10.0.23.3"
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
1 packets, 84 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

We&#8217;ve cleared the counters on R2, so lets generate some traffic on R1 again.

```console
R1#copy http://10.0.23.3/index.html null:
Loading http://10.0.23.3/index.html
174 bytes copied in 0.596 secs (292 bytes/sec)
```

```console
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
5 packets, 344 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http host "10.0.23.3"
QoS Set
dscp af13
Packets marked 5

Class-map: class-default (match-any)
64 packets, 5300 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

We can see here it matched 5 packets based on the host. We can use this to match whole sites like youtube.com or video.google.com.

***Match protocol HTTP url***

We can match strings AFTER the host portion of a URL using the match protocol http url command. It also takes a regular expression as an argument. For example:

```console
match protocol http url *video*
! This would match http://www.cisco.com/video/index.php or
http://www.google.com/stuff/video.html
!
match protocol http url video*
! This would match http://www.cisco.com/video but not http://www.cisco.com/stuff/video.html
! because stuff precedes the video portion of the url and in the expression above we have said
! it has to start with the string video
!
match protocol http url *.jpeg|*.jpg|*.gif
! This would match any .jpeg or .jpg or .gif extention in the url
```

Lets set up R2 to match based on a URL.

```console
R2(config)#class-map MATCH-HTTP
R2(config-cmap)#no match protocol http host 10.0.23.3
R2(config-cmap)#match protocol http url *.jpg
```

As you can see above we have used the match protocol http url function of NBAR to match any url that ends in a .jpg. This effectively blocks jpeg images (unless they have a different extension).
Let test it, before we send some traffic we&#8217;ll reset the counters on the interface.

```console
R2#clear counters s1/0
Clear "show interface" counters on this interface [confirm]
*Mar  1 00:43:39.135: %CLEAR-5-COUNTERS: Clear counter on interface Serial1/0 by console
R2#
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http url "*.jpg"
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
1 packets, 84 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

If we request a gif file we ***shouldn&#8217;t*** match the class MATCH-HTTP. Lets test that first.

```console
R1#copy http://10.0.23.3/picture.gif null:
Loading http://10.0.23.3/picture.gif
90 bytes copied in 0.644 secs (140 bytes/sec)
```

```console
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http url "*.jpg"
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
18 packets, 1209 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

Great Success! Looks pretty good. Now lets try a .jpg extension. We ***should*** match this.

```console
R1#copy http://10.0.23.3/picture.jpg null:
Loading http://10.0.23.3/picture.jpg
329 bytes copied in 0.820 secs (401 bytes/sec)
```

```console
R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
7 packets, 433 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http url "*.jpg"
QoS Set
dscp af13
Packets marked 7

Class-map: class-default (match-any)
22 packets, 1469 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any
```

Awesome! You can see above we matched based on a URL.

***match protocol http mime***

We can also use the match protocol http mime to match internet mime types. The mime type has to be the same mime type that the web server responds with. For a list of valid mime types check out: <a href="http://www.sfsu.edu/training/mimetype.htm" onclick="javascript:pageTracker._trackPageview('/outbound/article/www.sfsu.edu');">http://www.sfsu.edu/training/mimetype.htm</a>. Lets look at an example:

```console
match protocol http mime image/jpeg
! This would match jpeg,jpg,jpe,jfif,pjpeg, and pjp types
!
match protocol http mime image/jpg
! This would not match anything as it is not a proper mime type. Get a list of the mime types
! here: http://www.sfsu.edu/training/mimetype.htm
!
match protocol http mime image*
! This would match all image mime types
!
match protocol http mime application/x-shockwave-flash
! This would not only match swf flash movies, but all of flash.
```

Lets set up R2 to filter the image/jpeg mime type:

```powershellR2#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
R2(config)#class-map MATCH-HTTP
R2(config-cmap)#no match protocol http url *.jpg
R2(config-cmap)#match protocol http mime ?
WORD  Enter a string as the sub-protocol parameter

R2(config-cmap)#match protocol http mime image/jpeg
R2(config-cmap)#exit
R2(config)#exit```<br />
Once again, we&#8217;ll clear the counters so we can verify that this works correctly.

```powershellR2#clear counters s1/0
Clear "show interface" counters on this interface [confirm]
*Mar  1 01:12:10.759: %CLEAR-5-COUNTERS: Clear counter on interface Serial1/0

R2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http mime "image/jpeg"
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
1 packets, 84 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any```<br />
On R1 lets generate some traffic. A gif file will be requested first. This ***should not*** match our policy.

```powershellR1#copy http://10.0.23.3/picture.gif null:
Loading http://10.0.23.3/picture.gif
90 bytes copied in 0.808 secs (111 bytes/sec)```<br />

```powershellR2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
0 packets, 0 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http mime "image/jpeg"
QoS Set
dscp af13
Packets marked 0

Class-map: class-default (match-any)
10 packets, 689 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any```<br />
All good! Ok lets do the final test and actually request a jpeg image and see if it matches our policy.

```powershellR1#copy http://10.0.23.3/picture.jpg null:
Loading http://10.0.23.3/picture.jpg
329 bytes copied in 1.216 secs (271 bytes/sec)```<br />

```powershellR2#sh policy-map int s1/0
Serial1/0

Service-policy input: HTTP-POLICY

Class-map: MATCH-HTTP (match-all)
5 packets, 220 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: protocol http mime "image/jpeg"
QoS Set
dscp af13
Packets marked 5

Class-map: class-default (match-any)
16 packets, 1162 bytes
5 minute offered rate 0 bps, drop rate 0 bps
Match: any```<br />
You can see above that the jpeg image was matched. It works!
***Putting it all together***
So lets put it all together. We can use all three match protocol http commands in a match-any class map. For example:

```powershellclass-map match-any INTERNET-SCUM
match protocol http host *youtube.com*|*video.google.com*
match protocol http mime video/flv|video/x-flv|video/mp4|video/x-m4v|audio/mp4a-latm
match protocol http mime video/3gpp|video/quicktime
match protocol http url *.flv|*.mp4|*.m4v|*.m4a|*.3gp|*.mov
! uncomment below if you don't want ANY flash.
! match protocol http mime application/x-shockwave-flash
! match protocol http url *.swf
!
policy-map NOINTERNETVIDEO
class INTERNET-SCUM
drop
!
int s1/0
service-policy input NOINTERNETVIDEO
!```<br />
This would match any traffic going to youtube or video.google.com, or any flash applications, or common video mime types, and any swf (flash or flash movie) files! Be aware that NBAR does make your router take a hit in CPU processor usage, I&#8217;d suggest evaluating your processor usage before using this in production.
HTH! Now back to labs!
***Summary:***

- Use the <a href="http://www.cisco.com/univercd/cc/td/doc/product/software/ios124/124cr/hqos_r/qos_m1h.htm#wp1128712" onclick="javascript:pageTracker._trackPageview('/outbound/article/www.cisco.com');">match http protocol</a> command to match the http protocol.
- match protocol http host matches the host portion
- match protocol http url matches the url after the hostname
- match protocol http mime matches mime types

***Resources***<br />
<a href="http://ardenpackeer.com/wp-content/uploads/2007/12/webserver.net"  title="Webserver - Dynamips .net configuration file">Webserver &#8211; Dynamips .net configuration file</a><br />
<a href="http://ardenpackeer.com/wp-content/uploads/2007/12/qoshttp-r1.txt"  title="QOS HTTP Filtering - R1 Final Configuration">QOS HTTP Filtering &#8211; R1 Final Configuration</a><br />
<a href="http://ardenpackeer.com/wp-content/uploads/2007/12/qoshttp-r2.txt"  title="QOS HTTP Filtering - R2 Final Configuration">QOS HTTP Filtering &#8211; R2 Final Configuration</a><br />
<a href="http://ardenpackeer.com/wp-content/uploads/2007/12/qoshttp-r3.txt"  title="QOS HTTP Filtering - R3 Final Configuration">QOS HTTP Filtering &#8211; R3 Final Configuration</a>


