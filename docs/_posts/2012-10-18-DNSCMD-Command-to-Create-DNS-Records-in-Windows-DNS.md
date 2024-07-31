---
title:  DNSCMD Command to Create DNS Records in Windows DNS
date:   2012-10-18 00:00:00 -0500
categories: IT
---

With the AD migration in full swing we had to create all of the static DNS records that we use for our routers, switches,  and other non-Windows hosts. That's a lot of hand jamming. I would rather script anything that is going to take me that long and invite errors.

What I did was use the DNSCMD command to export the records to a text file. Then I deleted all the dynamic records and converted it to a CSV.

The contents of the file, records.txt, consists of the following on separate lines:

```text
hostname-1 A ip-address
hostname-2 A ip-address
hostname-3 A ip-address
```

This is the batch script that uses the data in the text file to create the records in the new DNS zone.

```batch
@ECHO OFF
SET DNS_SERVER=<b>DNS-Server</b>
FOR /f "TOKENS=1,2,3 DELIMS=," %%a IN (records.txt) DO dnscmd %DNS_SERVER% /recordadd <b>Zone-Name</b> %%a %%b %%c
```

It worked pretty good and took a fraction of the time.
