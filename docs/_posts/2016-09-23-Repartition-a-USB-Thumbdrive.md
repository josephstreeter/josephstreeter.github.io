---
layout: post
title:  Repartition a USB Thumbdrive
date:   2016-09-23 00:00:00 -0500
categories: IT
---






Disk manager won't let you do it. Here's how you make it happen in Windows without a 3rd party application.

1 - Open an elevated command prompt.
2 - Run diskpart
3 - list disk

Find the disk number from the list of disks, make sure you have the right on!

DISKPART> list disk
Disk ###  Status         Size     Free     Dyn  Gpt
--------  -------------  -------  -------  ---  ---
Disk 0    Online          238 GB      0 B        *
Disk 1    Online         7728 MB  7239 MB

4 - list partition (There should only be a 0 and 1 partition number)
5 - select partition 0
6 - delete partition
7 - select partition 1
8 - delete partition
9 - create partition primary
10 - exit

Now you can use Disk Manager to format and name the volume


