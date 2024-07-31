---

title:  Configure SSHD for Security
date:   2013-11-12 00:00:00 -0500
categories: IT
---

The Secure Shell daemon should be hardened to prevent unauthorized access before being put into production.

Verify that /etc/ssh/sshd_config contains the following lines and that they are not commented out.

- Protocol 2
- IgnoreRhosts yes
- HostbasedAuthentication no
- PermitRootLogin no
- Banner /etc/issue (See banner example below)
- PermitEmptyPasswords no
- AllowTcpForwarding no (unless needed)
- X11Forwarding no
- AllowUsers <username1> <username2> (Optional)
- DenyUsers <username1> <username2> (Optional)


```powershell
-------------------------------------------------------------------
You are accessing an Information System (IS) that is provided for
authorized use only.
By using this IS (which includes any device attached to this IS), you
consent to the following conditions:
+ Communications on this IS is routinely intercepted and monitored
for purposes including, but not limited to, penetration testing,
COMSEC monitoring, network operations and defense, personnel
misconduct (PM), law enforcement (LE), and counterintelligence (CI)
investigations.
+ At any time, data stored on this IS may be inspected and seized.
+ Communications using, or data stored on, this IS are not private, are
subject to routine monitoring, interception, and search, and may be
disclosed or used for any authorized purpose.
+ This IS includes security measures (e.g., authentication and access
controls) to protect the owners interests--not for your personal
benefit or privacy.
+ Notwithstanding the above, using this IS does not constitute
consent to PM, LE or CI investigative searching or monitoring of
the content of privileged communications, or work product, related
to personal representation or services by attorneys,
psychotherapists, or clergy, and their assistants. Such
communications and work product are private and confidential. See
User Agreement for details.
-------------------------------------------------------------------
```


