---

title:  Ongoing Active Directory Issue (Kerberos Related)
date:   2012-10-19 00:00:00 -0500
categories: IT
---






The KDC service hangs long enough on a booting Domain Controller to create an error and the popup messgage for a service failing to start. Unfortunatly the popup is visible to end users as they are also file/print servers that users have console access to (yeah, yeah, I know. I just can't do anything about it).

The results of *certutil -dcinfo verify* shows *Element.dwErrorStatus = CERT_TRUST_IS_NOT_VALID_FOR_USAGE (0x10)* and *The certificate is not valid for the requested usage. 0x800b0110*

It would appear that *certutil -dcinfo deletebad* but I'm nor 100% sure that the DC will auto enrole for a new certificate. I also have no idea what things might be using kerberos for authentication. At least I know that smart cards are not being used, but that is of little comfort.

To be continued....
<hr>
...later that same day.
Tried the *certutil -dcinfo deletebad* command. It succeded in giving me an error message:
```powershell
The currently selected KDC certificate was once valid, but now is invalid and no suitable replacement was found. Smartcard logon may not function correctly if this problem is not remedied. Have the system administrator check on the state of the domain's public key infrastructure. The chain status is in the error data.
```

For this error I used the follwing steps from Microsoft:
```powershell
<b>Resolve</b>
Request a new domain controller certificate
Kerberos uses a domain controller certificate to ensure that the authentication information sent over the network is encrypted. If the certificate is missing or is no longer valid, you must delete the domain controller certificate and then request a new one.

<b>To resolve this issue:</b>

Delete the domain controller certificate that is no longer valid.
Request a new certificate.
To perform these procedures, you must be a member of the Domain Admins group, or you must have been delegated the appropriate authority.

Delete the domain controller certificate that is no longer valid
To delete the domain controller certificate that is no longer valid:

1.On the domain controller in which the issue is occurring, click Start, and then click Run.
2.Type mmc.exe, and then press ENTER.
3.If the User Account Control dialog box appears, confirm that the action it displays is what you want, and then click Continue.
4.Click File, and then click Add/Remove Snap-in.
5.Click Certificates, and then click Add.
6.Click Computer account, click Next, and then click Finish.
7.Click OK to open the Certificates snap-in.
8.Expand Certificates (Local computer), expand Personal, and then click Certificates.
9.Right-click the old domain controller certificate, and then click Delete.
10.Click Yes, confirming that you want to delete the certificate.
11.After the certificate is deleted, follow the procedure in the "Request a new certificate" section.
Request a new certificate
To request a new certificate:

1.Expand Certificates (Local computer), right-click Personal, and then click Request New Certificate.
2.Complete the appropriate information in the Certificate Enrollment Wizard for a domain controller certificate.
3.Close the Certificates snap-in.
Verify
To perform this procedure, you must be a member of the Domain Admins group, or you must have been delegated the appropriate authority.

To verify that the Kerberos Key Distribution Center (KDC) certificate is available and working properly:

1.Log on to a computer within your domain.
2.Click Start, point to All Programs, click Accessories, right-click Command Prompt, and then click Run as administrator.
3.If the User Account Control dialog box appears, confirm that the action it displays is what you want, and then click Continue.
4.At the command prompt, type certutil -dcinfo verify, and then press ENTER.
5.If you receive a successful verification, the Kerberos KDC certificate is installed and operating correctly.
```

We will see how far down the rabbit hole this takes us....

Requesting new Domain Controller certificates didn't seem to fix the issue. However, requesting Domain Controller Authentication certificates appears to have fixed the errors on all DCs but one.


