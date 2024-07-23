---
layout: post
title:  Loading IOS image via TFTP in ROMMON
date:   2012-10-18 00:00:00 -0500
categories: IT
---







I think I am going to need this later this week. To bail out a IOS-less device. Why oh why do you leave us IOS image?


First I will need to get the IOS image off of another switch


Create a new file, router-image, in the /tftpboot directory of the TFTP server. On UNIX, use the syntax touch *filename*.

{% highlight powershell %}
touch *filename*
{% endhighlight %}

Use the same file name shown in the show flash output in order to create the file on the /tftpboot directory of the TFTP server. For this example, the router lists c2600-i-mz.122-2.XA as the output for the show flash: command.

{% highlight powershell %}
touch c2600-i-mz.122-2.XA
{% endhighlight %}
Change the permissions of the file to 777 with syntax chmod <permissions> <filename>.
{% highlight powershell %}
chmod 777 c2600-i-mz.122-2.XA
{% endhighlight %}

From the Cisco device:

{% highlight powershell %}
copy flash:*IOS-Image-File* tftp:
{% endhighlight %}

Now on to loading it onto the device that was nuked. First we have to give it an IP address in ROMMON since it has no OS. Then we can copy the file from the TFTP server to the device.

{% highlight powershell %}
rommon 11 > IP_ADDRESS=192.168.1.5
rommon 12 > IP_SUBNET_MASK=255.255.255.0
rommon 13 > DEFAULT_GATEWAY=192.168.1.1
rommon 14 > TFTP_SERVER=192.168.1.10
rommon 15 > TFTP_FILE=c1841-advipservicesk9-mz.124-13a.bin
rommon 16 > tftpdnld
.
IP_ADDRESS: 192.168.1.5
IP_SUBNET_MASK: 255.255.255.0
DEFAULT_GATEWAY: 192.168.1.1
TFTP_SERVER: 192.168.1.10
TFTP_FILE: c1841-advipservicesk9-mz.124-13a.bin
TFTP_MACADDR: 00:13:80:7b:20:1e
TFTP_VERBOSE: Progress
TFTP_RETRY_COUNT: 18
TFTP_TIMEOUT: 7200
TFTP_CHECKSUM: Yes
FE_PORT: 0
FE_SPEED_MODE: Auto Detect
.
Invoke this command for disaster recovery only.
WARNING: all existing data in all partitions on flash will be lost!
Do you wish to continue? y/n: [n]: y
...
Receiving c1841-advipservicesk9-mz.124-13a.bin from 192.168.1.10 !!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
....
File reception completed.
Validating checksum.
Copying file c1841-advipservicesk9-mz.124-13a.bin to flash.
program load complete, entry point: 0x8000f000, size: 0xc100
.
Initializing ATA monitor library.......
.
Format: Drive communication & 1st Sector Write OK...
Writing Monlib sectors.
................................................................................
..................
Monlib write complete
Format: All system sectors written. OK...
Format: Operation completed successfully.
Format of flash: complete
program load complete, entry point: 0x8000f000, size: 0xc100
Initializing ATA monitor library.......
rommon 17 >
{% endhighlight %}

All done!



