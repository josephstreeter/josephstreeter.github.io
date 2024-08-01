---
title:  Links for Smart Card Authentication in Active Directory
date:   2012-10-19 00:00:00 -0500
categories: IT
---

Some info from Microsoft on setting up for Active Directory for smart card authentication. Since we're looking to use a non-Microsoft vendor for certificates information for use of a 3rd party CA are particularly important.


- <a href="http://blogs.technet.com/b/instan/archive/2011/05/17/smartcard-logon-using-certificates-from-a-3rd-party-on-a-domain-controller-and-kdc-event-id-29.aspx">Smartcard logon using certificates from a 3rd party on a Domain Controller and KDC Event ID 29 - AD Troubleshooting Blog</a>
- <a href="http://support.microsoft.com/kb/291010">Requirements for Domain Controller Certificates from a Third-Party CA</a>
- <a href="http://support.microsoft.com/kb/295663">How to import third-party certification authority (CA) certificates into the Enterprise NTAuth store</a>
- <a href="http://support.microsoft.com/kb/281245">Guidelines for enabling smart card logon with third-party certification authorities
</a>
- <a href="http://social.technet.microsoft.com/wiki/contents/articles/updated-requirements-for-a-windows-server-2008-r2-domain-controller-certificate-from-a-3rd-party-ca.aspx">Updated requirements for a Windows Server 2008 R2 domain controller certificate from a 3rd party CA</a>
- <a href="http://technet.microsoft.com/en-us/library/dd277320.aspx">Cryptography and Microsoft Public Key Infrastructure</a>


I've accomplished this at home in a lab and it isn't too hard. Once you have the appropriate certificates in place, smart card provisioned, and middleware installed you're almost there.
