---

title:  Change Console Resolution and Remove Splash on Linux
date:   2013-02-11 00:00:00 -0500
categories: IT
---

***CentOS/Redhat***

Open "/boot/grub/grub.conf" and add "vga=791" to the kernel line.


Example
Change:
```powershell
kernel /vmlinuz-2.6.18-53.1.19.el5PAE ro root=/dev/VolGroup00/LogVol00 console=ttyS0,57600 console=tty0
```
To:
```powershell
kernel /vmlinuz-2.6.18-53.1.19.el5PAE ro root=/dev/VolGroup00/LogVol00 console=ttyS0,57600 console=tty0 vga=791
```

Once you've edited and saved the file, reboot the host and you should see the new resolution.

***Fedora***

For new versions of Fedora make the same change to the "/etc/default/grub" file by adding "vga=791" to the "GRUB_CMDLINE_LINUX" line. Then run the following command:
```powershell
grub2-mkconfig -o /boot/grub2/grub.cfg
```

***Debian***

Similar to the Fedora fix, edit the "/etc/default/grub" file by adding "vga=791" to the "GRUB_CMDLINE_LINUX" line. Then run the following command:
```powershell
grub-mkconfig -o /boot/grub/grub.cfg
```

***Other Resolutions and Color Depths***
```powershell
791 - 1024x768, 16 bit
792 - 1024x768, 24 bit
794 - 1280x1024, 16 bit
795 - 1280x1024, 24 bit
```

If your linux install has a flash image that launches during boot, you can remove it so you can see the kernel do it's thing. Using the same methods above on the- kernel line or GRUB_CMDLINE_LINUX- line, depending on distro,- remove 'rhgb' and 'quiet'.

