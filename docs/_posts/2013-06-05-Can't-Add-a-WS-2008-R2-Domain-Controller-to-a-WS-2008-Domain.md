---
layout: post
title:  Can't Add a WS 2008 R2 Domain Controller to a WS 2008 Domain
date:   2013-06-05 00:00:00 -0500
categories: IT
---

I've been trying to add a WS 2008 R2 DC to our WS 2008 test Active Directory for a little while now. A Microsoft PFE suggested checking the fSMORoleOwner attribute in the ForestDNSDomains and DomainDNSDomains partitions to make sure that they match the actual Infrastructure Master.

For example:

{% highlight powershell %}
PS C:\> netdom query fsmo
Schema master- - - - - - - - - - - - - - - DC1.domain.tld
Domain naming master- - - DC1.domain.tld
PDC- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  DC2.domain.tld
RID pool manager- - - - - - - - - - - DC2.domain.tld
Infrastructure master- - - - - -  DC3.domain.tld
The command completed successfully.
{% endhighlight %}

To check the value of these attributes you will need to add the partitions to the- ADSI Edit tool.

- Open ADSIEdit as an Administrator
- Right-click ADSI Edit at the top of the snap-in and select Connect toâ€¦
- In the Connection Settings dialog box:

- Enter â€œForestDNSZones Partition in the Name field
- Enter â€œdc=forestdnszones,dc=domain,dc=tld in the Select or type a Distinguished Name or Naming Context (Be sure to replace â€œdc=domain,dc=tld with the proper string for your environment)


- Click Ok
- Right-click ADSI Edit at the top of the snap-in and select Connect toâ€¦
- In the Connection Settings dialog box:

- Enter â€œDomainDNSZones Partition in the Name field
- Enter â€œdc=domaindnszones,dc=domain,dc=tld in the Select or type a Distinguished Name or Naming Context (Be sure to replace â€œdc=domain,dc=tld with the proper string for your environment)


- Click Ok



