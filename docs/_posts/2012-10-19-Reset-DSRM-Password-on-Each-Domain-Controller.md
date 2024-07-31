---

title:  Reset DSRM Password on Each Domain Controller
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Sometimes you inherit an Active Directory environment that you didn't build and no one knows the DRSM admin password. Use NTDSUTIL command to change the DSRM Administrative Password

```powershell
C:\Users\Administrator>ntdsutil
ntdsutil: set dsrm password
Reset DSRM Administrator Password: reset password on server null
Please type password for DS Restore Mode Administrator Account: ********
Please confirm new password: ********
Password has been set successfully.

Reset DSRM Administrator Password: q
ntdsutil: q
```


