---

title:  Shrink LVM Volume - Ubuntu
date:   2016-09-22 00:00:00 -0500
categories: IT
---

Boot from an Ubuntu LiveCD

Locate the volume group that you wish to shrink

```console
ubuntu@ubuntu:~$ sudo lvmdiskscan

ubuntu@ubuntu:/dev$ sudo lvmdiskscan
/dev/ram0             [      64.00 MiB]
/dev/loop0            [       1.41 GiB]
/dev/ubuntu-vg/root   [     460.32 GiB]
```

Issue the following command to shrink the file system and the volume

```console
ubuntu@ubuntu:~$ sudo lvreduce --resizefs --size -230G /dev/ubuntu-vg/root
```

Reboot
