---
layout: post
title:  Selective Dial Peers with Translation Rules
date:   2012-11-26 00:00:00 -0500
categories: IT
---






I'm not sure if I remember how these work, but just in case I need them in the future...here they are.

voice translation-rule 1
rule 1 /^9/ /19/
!
voice translation-rule 2
rule 1 /^9/ /29/
!
!
voice translation-profile 6444
translate called 1
!
voice translation-profile 6445
translate called 2

dial-peer voice 1010000 pots
destination-pattern 19911
no digit-strip
port 0/0/0
forward-digits 3
!
dial-peer voice 1020000 pots
destination-pattern 19[2-9]......
no digit-strip
port 0/0/0
forward-digits 7
!
dial-peer voice 1030000 pots
destination-pattern 191[2-9]..[2-9]......
no digit-strip
port 0/0/0
forward-digits 11
!
dial-peer voice 1040000 pots
destination-pattern 19011T
port 0/0/0
forward-digits all

!
dial-peer voice 1010001 pots
destination-pattern 29911
no digit-strip
port 0/0/1
forward-digits 3
!
dial-peer voice 1020001 pots
destination-pattern 29[2-9]......
no digit-strip
port 0/0/1
forward-digits 7
!
dial-peer voice 1030001 pots
destination-pattern 291[2-9]..[2-9]......
no digit-strip
port 0/0/1
forward-digits 11
!
dial-peer voice 1040001 pots
destination-pattern 29011T
port 0/0/1
forward-digits all
!


