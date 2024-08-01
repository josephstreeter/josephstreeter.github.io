---
title:  Configure Sudoers
date:   2013-11-12 00:00:00 -0500
categories: IT
---

Allow all user to sudo without password

```bash
<username>      ALL=(ALL)      NOPASSWD: ALL
```

Allow members of the wheel group to sudo without password

```bash
%wheel             ALL=(ALL)      NOPASSWD: ALL
```

Allow user to sudo for the listed commands

```bash
<username>     ALL=/sbin/shutdown -h now, reboot, tcpdump
```
