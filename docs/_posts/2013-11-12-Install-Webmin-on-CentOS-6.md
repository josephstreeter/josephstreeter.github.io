---

title:  Install Webmin on CentOS 6
date:   2013-11-12 00:00:00 -0500
categories: IT
---






Webmin makes it easy to perform administrative tasks via a web interface. Once the Webmin repos are installed the package can be installed using Yum.

Download and install the key for the Webmin repo
```powershellwget http://www.webmin.com/jcameron-key.asc
rpm --import jcameron-key.asc```

Create a file for the Webmin repo
```powershellvi /etc/yum.repos.d/webmin.repo```
Add the repo information to the repo file
```powershell[Webmin] name=Webmin Distribution Neutral
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1```
Install Webmin package
```powershellyum â€“y install webmin```


