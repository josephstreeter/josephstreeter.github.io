# Tips and Tricks

## What Process is Using that Port

The ```netstat -ano``` command will give you an output that includes the PID that is associated with each port number.

```console
C:\>netstat -ano | find "52100"
UDP    0.0.0.0:52100        *:*              1736
```

Use the ```tasklist``` command to find the process information.

```console
C:\>tasklist /svc /fi "PID eq 1736"
Image Name         PID Services
============= ======== ==================
dns.exe           1736 DNS
```
