---

title:  Constant UAC Prompts in Windows 8.1
date:   2013-12-16 00:00:00 -0500
categories: IT
---






If you have a Windows 8.1 host that is domain joined and are using a domain user that is linked to a Live account you may be seeing constant UAC prompts. Whenever there is a network change of any sort there is a UAC prompt asking for authorization to CLSID {E5A040E9-1097-4D24-B89E-3C730036D615}.

There are two choices: Unlink the accounts or disable password synchronization. With the assumption that you want to maintain the link between the domain user and Live account the following steps will disable password sync.

To disable password sync:

- Go to the Start window
- Press Windows - C (Or move your cursor to the lower right-hand corner.)
- Click Settings -> Change PC Settings -> SkyDrive -> Sync settings
- Scroll down to Other settings and find Passwords
- Set Passwords to Off

That should take care of the UAC prompts until MS comes up with a better fix.


