---

title:  What is Using That Network Port Anyways?
date:   2012-10-19 00:00:00 -0500
categories: IT
---






So, you see a list of ports that are open on your Windows host and you want to know what is using them.
Well, you're in luck. With a little command line-fu you can get the answer.
"netstat -ano" will give you an output that includes the PID that is associated with each port number.
```powershell
C:\>netstat -ano | find "52100"
UDP    0.0.0.0:52100        *:*              1736
```
Then use the "tasklist" command to find your answer.
```powershell
C:\>tasklist /svc /fi "PID eq 1736"
Image Name         PID Services
============= ======== ==================
dns.exe           1736 DNS
```


