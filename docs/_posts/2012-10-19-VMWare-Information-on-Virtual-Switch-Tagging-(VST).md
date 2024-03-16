---
layout: post
title:  VMWare Information on Virtual Switch Tagging (VST)
date:   2012-10-19 00:00:00 -0500
categories: IT
---






It's been a long wait until I've finally come around to configuring this at home in my lab.

Here is a VMWare White Paper and KB for configuring VST in an ESXi environment if you want to have VMs on different VLANs. It seemed easier than opening up the boxes and putting extra NICs in. However, I may still do that in the future so that I can etherchannel them.

The key that I'd missed the first time around is that you cannot assign a VLAN that is assigned as the native VLAN. I know, I know, I shouldn't have servers running on my native VLAN with my management traffic. It's a lab...sue me!


- <a href="http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1004074">Sample configuration of virtual switch VLAN tagging (VST Mode)</a>
- <a href="http://www.vmware.com/pdf/esx3_vlan_wp.pdf">VMware ESX Server 3 802.1Q VLAN Solutions WHITE PAPER</a>



