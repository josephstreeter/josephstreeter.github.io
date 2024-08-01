---

title:  Mount a Windows File Share in Linux from the CLI.
date:   2012-10-19 00:00:00 -0500
categories: IT
---

Mount a Windows file share in Linux from the CLI:

```cmd
mount -t cifs -o user=username,password=password //host-IP/sharename /media/share"
```

Notice to Windows users: These are forward slashes instead of back slashes. Not a typo.
