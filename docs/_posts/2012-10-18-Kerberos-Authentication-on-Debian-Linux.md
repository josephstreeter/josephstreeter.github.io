---
title:  Kerberos Authentication on Debian Linux
date:   2012-10-18 00:00:00 -0500
categories: IT
---

This should be a fun experiment.

First I found this article:

- [Debian join windows domain](http://zeldor.biz/2010/12/debian-join-windows-domain/)

I had a problem with the following error:

```console
kinit: KDC reply did not match expectations while getting initial credentials
```

Solution seems to be that it likes to have the kerberos realm entered in all upper-case. Who knew....

I am able to receive a ticket from the KDC.

To be continued....

....Later that same day.

Got kerberos, Samba, and Winbind configured and working with the home network. I was able to log into my network management host with domain credentials.

Pretty cool stuff.
