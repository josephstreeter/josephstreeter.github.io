---

title:  Cisco VoIP Troubleshooting Examples
date:   2012-11-26 00:00:00 -0500
categories: IT
---






Some quick examples of commands to troubleshoot voice issues on Cisco voice routers. Links to some resources can be found in an earlier post:
<a title="Permalink to Troubleshooting and Debugging VoIP Call Basics" href="../?p=4" rel="bookmark">Troubleshooting and Debugging VoIP Call Basics</a>

***show voice call status ***and ***show voice call summary*** â€“

Router#sh voice call status
CallID- - - -  CID-  ccVdb- - - - -  Port- - - - - - -  Slot/DSP:Ch-  Called #- -  Codec- - -  MLPP Dial-peers
0x21- - - - - -  1243 0x4A0C6EA0 0/1/0- - - - - - - - - - -  0/1:1- -  1234- - - - - -  g711ulaw- - - - - -  1000/1001
0x22- - - - - -  1243 0x4A0BE8AC 0/0/0- - - - - - - - - - -  0/1:2-  *1234- - - - - -  g711ulaw- - - - - -  1001/1000
1 active call found



Router#sh voice call summary
PORT- - - - - - - - - -  CODEC- - - -  VAD VTSP STATE- - - - - - - - - - -  VPM STATE
============== ========= === ====================
0/0/0- - - - - - - -  None- - - - - -  --  S_CONNECT- - - - - - - - - - - -  FXSLS_CONNECT
0/0/1- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - -  - FXSLS_ONHOOK
0/0/2- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - - -  FXSLS_ONHOOK
0/0/3- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - - -  FXSLS_ONHOOK
0/1/0- - - - - - - -  None- - - - - -  --  S_CONNECT- - - - - - - - - - - -  FXOLS_CONNECT
0/1/1- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - - -  FXOLS_ONHOOK
0/1/2- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - - -  FXOLS_ONHOOK
0/1/3- - - - - - - -  -- - - - - - - - -  --  -- - - - - - - - - - - - - - - - - - - -  FXOLS_ONHOOK



***Show voice port summary
***router#show voice port summary

IN- - - - - -  OUT
PORT- - - - - - - - - - -  CH- -  SIG-TYPE- -  ADMIN OPER STATUS- -  STATUS- -  EC
=============== == ============ ===== ==== ======== ======== ==
0/0/0:23- - - - - - -  01-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  02-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  03-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  04-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  05-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  06-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  07-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  08-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  09-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  10-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- -  - - - - - 11-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  12-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  13-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  14-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - -  - 15-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/0/0:23- - - - - - -  16-  isdn-voice-  up- - -  dorm none- - - -  none- - - -  y
0/2/0- - - - - - - - - -  ---  fxs-ls- - - - -  up- - -  dorm on-hook-  idle- - - -  y
0/2/1- - - - - - - - - -  ---  fxs-ls- - - - -  up- - -  dorm on-hook-  idle- - - -  y
0/2/2- - - - - - - - - -  ---  fxs-ls- - - - -  up- - -  dorm on-hook-  idle- - - -  y
0/2/3- - - - - - - - - -  ---  fxs-ls - - - - - up- - -  dorm on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  1- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  2- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  3- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  4- - - - -  efxs- - -  - up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  5- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  6- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  7- - - - -  efxs- - - -  up- - -  up- -  on-hook-  idle- - - -  y
50/0/1- - - - - - - - -  8- - - - -  efxs- - - -  up - - - up- -  on-hook-  idle- - - -  y

PWR FAILOVER PORT- - - - - - -  PSTN FAILOVER PORT
=================- - - - - - -  ==================




