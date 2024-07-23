---
layout: post
title:  Cisco CME Using Asterisk for Voice Mail
date:   2012-10-18 00:00:00 -0500
categories: IT
---






I configured Cisco CME on my 2801 router, but that just wasn't enough. I wanted voicemail and some other features that I was able to configure in Asterisk. I did some looking and found a few guides on how to do this.

<a href="http://www.voip-info.org/wiki/view/Asterisk+Cisco+CallManager+Express+Integration">Asterisk Cisco CallManager Express Integration</a>

<a href="http://uc-b.blogspot.com/2008/04/asterisk-cisco-callmanager-express-cme.html">Asterisk &amp; Cisco Callmanager Express (CME)</a>

<a href="http://www.pasewaldt.com/cme/cme_index.html#">pasewaldt Cisco CME/Asterisk</a>

This is my CME and Asterisk Configuration
### ***Asterisk Configuration***
***extensions.conf*********
{% highlight powershell %}[macro-dialout-callmanager]
exten => s,1,ChanIsAvail(SIP/callman01)
exten => s,2,Dial(${CUT(AVAILCHAN||1)}/${ARG1})
exten => s,3,Hangup
exten => s,102,Congestion

[outgoing]
exten => _1XXX,1,Macro(dialout-callmanager,${EXTEN})
exten => i,1,Congestion

[local]
ignorepat => 9
include => default
include => outgoing
include => macro-dialout-callmanager

[default]
include => local
exten => 2105,1,NoOp,${CALLERID(num)}
exten => 2105,2,Background(silence/1)
exten => 2105,3,VoicemailMain(s${CALLERID(num)})
exten => 2105,4,Hangup
exten => 2105,104,Hangup

exten => 2106,1,NoOp,${CALLERID(num)}
exten => 2106,2,NoOp,${CALLERID(rdnis)}
exten => 2106,3,Playback(silence/1)
exten => 2106,4,Voicemail(u${CALLERID(rdnis)})
exten => 2106,5,Hangup
exten => 2106,106,Hangup

exten => 2107,1,NoOp,${CALLERID(num)}
exten => 2107,2,NoOp,${CALLERID(rdnis)}
exten => 2107,3,Playback(silence/1)
exten => 2107,4,Voicemail(b${CALLERID(rdnis)}
exten => 2107,5,Hangup
exten => 2107,106,Hangup{% endhighlight %}
***sip.conf***
{% highlight powershell %}[callman01]
type=friend
context=incoming
host=192.168.4.1
disallow=all
allow=ulaw
allow=alaw
nat=no
canreinvite=yes
qualify=yes
dtmfmode=rfc2833

[1001]
type=friend
host=dynamic
context=local
canreinvite=no
mailbox=1001

[1002]
type=friend
host=dynamic
context=local
canreinvite=no
mailbox=1002{% endhighlight %}
***voicemail.conf***
{% highlight powershell %}[default]
1001 => 1234,Streeter Joseph A,joseph.streeter@us.army.mil
1002 => 1002,Moran Erin L,yeahu14@aol.com{% endhighlight %}
### ***Cisco Call Manager Express Configuration***
***TFTP Server Configuration***
{% highlight powershell %}tftp-server flash:phone\Analog2.raw
tftp-server flash:Analog1.raw
tftp-server flash:Analog2.raw
tftp-server flash:AreYouThere.raw
tftp-server flash:AreYouThereF.raw
tftp-server flash:Bass.raw
tftp-server flash:CallBack.raw
tftp-server flash:Chime.raw
tftp-server flash:Classic1.raw
tftp-server flash:Classic2.raw
tftp-server flash:ClockShop.raw
tftp-server flash:DistinctiveRingList.xml
tftp-server flash:Drums1.raw
tftp-server flash:Drums2.raw
tftp-server flash:FilmScore.raw
tftp-server flash:HarpSynth.raw
tftp-server flash:Jamaica.raw
tftp-server flash:KotoEffect.raw
tftp-server flash:MusicBox.raw
tftp-server flash:Piano1.raw
tftp-server flash:Piano2.raw
tftp-server flash:Pop.raw
tftp-server flash:Pulse1.raw
tftp-server flash:Ring1.raw
tftp-server flash:Ring2.raw
tftp-server flash:Ring3.raw
tftp-server flash:Ring4.raw
tftp-server flash:Ring5.raw
tftp-server flash:Ring6.raw
tftp-server flash:Ring7.raw
tftp-server flash:RingList.xml
tftp-server flash:Sax1.raw
tftp-server flash:Sax2.raw
tftp-server flash:Vibe.raw
tftp-server flash:P00308000500.bin
tftp-server flash:P00308000500.loads
tftp-server flash:P00308000500.sb2
tftp-server flash:P00308000500.sbn{% endhighlight %}
***Dial Peer to send calls to Asterisk***
{% highlight powershell %}dial-peer voice 13 voip
destination-pattern [2-9]...
session protocol sipv2
session target ipv4:192.168.0.21
dtmf-relay rtp-nte
codec g711ulaw{% endhighlight %}
***Configure CME to be a SIP client to Asterisk***
{% highlight powershell %}sip-ua
mwi-server ipv4:192.168.0.21 expires 86400 port 5060 transport tcp unsolicited
registrar ipv4:192.168.0.21 expires 3600 secondary{% endhighlight %}
***Configure CME itself***
{% highlight powershell %}telephony-service
load 7960-7940 P00308000500
max-ephones 30
max-dn 100
ip source-address 192.168.4.1 port 2000
system message Madison
url services http://phone-xml.berbee.com/menu.xml
time-format 24
create cnf-files version-stamp 7960 Jul 29 2010 08:17:10
dialplan-pattern 1 5123781291 extension-length 4
voicemail 2105
max-conferences 4 gain -6
moh music-on-hold.au
transfer-system full-consult
secondary-dialtone 9{% endhighlight %}
***Configure each of the DNs registered to CME***
{% highlight powershell %}ephone-dn  1  dual-line
number 1001
label Streeter
description Joseph A Streeter
name Joseph A Streeter
call-forward busy 2107
call-forward noan 2106 timeout 10

ephone-dn  2  dual-line
number 1002
label Moran
description Erin L Moran
name Erin L Moran
call-forward busy 2107
call-forward noan 2106 timeout 10

ephone-dn  10
number 1000 no-reg primary
label Paging
description Paging
name Paging
paging ip 239.1.1.2 port 2000{% endhighlight %}
***Configure each of the ephones registered to CME***
{% highlight powershell %}ephone  1
description Joseph A Streeter
mac-address 0024.C445.168B
paging-dn 10
button  1:1

ephone  2
description Erin L Moran
mac-address 0023.EB54.2389
paging-dn 10
button  1:2{% endhighlight %}
***Commands on CME to show SCCP registered ephones***
{% highlight powershell %}rt-mad-01#show dial-peer voice summary
dial-peer hunt 0
AD                                    PRE PASS                OUT
TAG    TYPE  MIN  OPER PREFIX    DEST-PATTERN      FER THRU SESS-TARGET    STAT PORT
13     voip  up   up             [2-9]...           0  syst ipv4:192.168.0.21
20001  pots  up   up             1001$              0                           50/0/1
20002  pots  up   up             1002$              0                           50/0/2
20003  pots  up   up             1000$              0                           50/0/10
20005  pots  up   up             1003$              0                           50/0/13
20006  pots  up   up             1004$              0                           50/0/14
20008  pots  up   up             1002$              0                           50/0/15{% endhighlight %}
***Same as above, but with more detail***
{% highlight powershell %}rt-mad-01#sh ephone registered

ephone-1 Mac:0024.C445.168B TCP socket:[4] activeLine:0 REGISTERED in SCCP ver 17 and Server in ver 5
mediaActive:0 offhook:0 ringing:0 reset:0 reset_sent:0 paging 0 debug:0
IP:192.168.4.27 42249 7941   keepalive 2442 max_line 2
button 1: dn 1  number 1001 CH1   IDLE         CH2   0IDLE         shared
paging-dn 10

ephone-2 Mac:0023.EB54.2389 TCP socket:[6] activeLine:0 REGISTERED in SCCP ver 17 and Server in ver 5
mediaActive:0 offhook:0 ringing:0 reset:0 reset_sent:0 paging 0 debug:0
IP:192.168.4.23 16183 7941   keepalive 2441 max_line 2
button 1: dn 2  number 1002 CH1   IDLE         CH2   IDLE         mwi shared
paging-dn 10{% endhighlight %}
***Voice ports on CME <em>before</em> a call***
{% highlight powershell %}rt-mad-01#sh voice port summary
IN       OUT
PORT            CH   SIG-TYPE   ADMIN OPER STATUS   STATUS   EC
=============== == ============ ===== ==== ======== ======== ==
50/0/1          1      efxs     up    dorm on-hook  idle     y
50/0/1          2      efxs     up    dorm on-hook  idle     y
50/0/2          1      efxs     up    dorm on-hook  idle     y
50/0/2          2      efxs     up    dorm on-hook  idle     y
50/0/10         1      efxs     up    dorm on-hook  idle     y
50/0/13         1      efxs     up    dorm on-hook  idle     y
50/0/14         1      efxs     up    dorm on-hook  idle     y
50/0/15         1      efxs     up    dorm on-hook  idle     y

PWR FAILOVER PORT        PSTN FAILOVER PORT
=================        =================={% endhighlight %}
***Voice ports on CME while a call is coming in***
{% highlight powershell %}rt-mad-01#sh voice port summary
IN       OUT
PORT            CH   SIG-TYPE   ADMIN OPER STATUS   STATUS   EC
=============== == ============ ===== ==== ======== ======== ==
50/0/1          1      efxs     up    dorm off-hook idle     y
50/0/1          2      efxs     up    dorm off-hook idle     y
50/0/2          1      efxs     up    dorm on-hook  idle     y
50/0/2          2      efxs     up    dorm on-hook  idle     y
50/0/10         1      efxs     up    dorm on-hook  idle     y
50/0/13         1      efxs     up    dorm on-hook  idle     y
50/0/14         1      efxs     up    dorm on-hook  idle     y
50/0/15         1      efxs     up    up   on-hook  ringing  y

PWR FAILOVER PORT        PSTN FAILOVER PORT
=================        =================={% endhighlight %}
***Voice ports on CME <em>during</em> a call***
{% highlight powershell %}rt-mad-01#sh voice port summary
IN       OUT
PORT            CH   SIG-TYPE   ADMIN OPER STATUS   STATUS   EC
=============== == ============ ===== ==== ======== ======== ==
50/0/1          1      efxs     up    dorm off-hook idle     y
50/0/1          2      efxs     up    dorm off-hook idle     y
50/0/2          1      efxs     up    dorm on-hook  idle     y
50/0/2          2      efxs     up    dorm on-hook  idle     y
50/0/10         1      efxs     up    dorm on-hook  idle     y
50/0/13         1      efxs     up    dorm on-hook  idle     y
50/0/14         1      efxs     up    dorm on-hook  idle     y
50/0/15         1      efxs     up    up   off-hook idle     y

PWR FAILOVER PORT        PSTN FAILOVER PORT
=================        =================={% endhighlight %}
***Two of the phones and CME registered in Asterisk as SIP clients***
{% highlight powershell %}A0-MAD-01*CLI> sip show peers
Name/username              Host            Dyn Nat ACL Port     Status
1002/1002                  192.168.0.1      D          5060     Unmonitored
1001/1001                  192.168.0.1      D          5060     Unmonitored
callman01                  192.168.4.1                 5060     OK (6 ms)
3 sip peers [Monitored: 1 online, 0 offline Unmonitored: 2 online, 0 offline]{% endhighlight %}
***Debug of a call going to VM on Asterisk***
{% highlight powershell %}    -- Executing [2106@local:1] NoOp("SIP/1002-081a8b98", "1002") in new stack
-- Executing [2106@local:2] NoOp("SIP/1002-081a8b98", "1001") in new stack
-- Executing [2106@local:3] Playback("SIP/1002-081a8b98", "silence/1") in new stack
-- <SIP/1002-081a8b98> Playing 'silence/1' (language 'en')
-- Executing [2106@local:4] VoiceMail("SIP/1002-081a8b98", "u1001") in new stack
-- <SIP/1002-081a8b98> Playing 'vm-theperson' (language 'en')
-- <SIP/1002-081a8b98> Playing 'digits/1' (language 'en')
-- <SIP/1002-081a8b98> Playing 'digits/0' (language 'en')
-- <SIP/1002-081a8b98> Playing 'digits/0' (language 'en')
-- <SIP/1002-081a8b98> Playing 'digits/1' (language 'en')
-- <SIP/1002-081a8b98> Playing 'vm-isunavail' (language 'en')
-- <SIP/1002-081a8b98> Playing 'vm-intro' (language 'en')
-- <SIP/1002-081a8b98> Playing 'beep' (language 'en')
-- Recording the message
-- x=0, open writing:  /var/spool/asterisk/voicemail/default/1001/tmp/LFLFHk format: wav49, 0x81bbc50
-- x=1, open writing:  /var/spool/asterisk/voicemail/default/1001/tmp/LFLFHk format: gsm, 0x8154ba0
-- x=2, open writing:  /var/spool/asterisk/voicemail/default/1001/tmp/LFLFHk format: wav, 0x81c1e30
-- User hung up
-- Recording was 0 seconds long but needs to be at least 3 - abandoning
== Spawn extension (local, 2106, 4) exited non-zero on 'SIP/1002-081a8b98'{% endhighlight %}
***These are some errors that I was getting. I don't know why I can't make them go away, but they don't seem to hurt anything.***
{% highlight powershell %}[Jul 29 17:14:44] NOTICE[2315]: chan_sip.c:15642 handle_request_register: Registration from '"1000" ' failed for '192.168.0.1' - No matching peer found
[Jul 29 17:14:44] NOTICE[2315]: chan_sip.c:15642 handle_request_register: Registration from '"1003" ' failed for '192.168.0.1' - No matching peer found
[Jul 29 17:14:44] NOTICE[2315]: chan_sip.c:15642 handle_request_register: Registration from '"1004" ' failed for '192.168.0.1' - No matching peer found{% endhighlight %}


