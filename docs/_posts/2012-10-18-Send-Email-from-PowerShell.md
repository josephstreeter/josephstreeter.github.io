---
title:  Send Email from PowerShell
date:   2012-10-18 00:00:00 -0500
categories: IT
---

Sometimes, even though you feel as though you have too much email, you want one of your machines to send you even more. It's pretty simple to use PowerShell as long as you have a host to relay SMTP for you.

```text
Send-MailMessage [-To] <string[]> [-Subject] <string> -From <string> [[-Body] <string>] [[-SmtpServer] <string>] [-Attachments <string[]>] [-Bcc <string[]
>] [-BodyAsHtml] [-Cc <string[]>] [-Credential <PSCredential>] [-DeliveryNotificationOption {None | OnSuccess | OnFailure | Delay | Never}] [-Encoding <En
coding>] [-Priority {Normal | Low | High}] [-UseSsl] [CommonParameters]
```

Example

```powershell
Send-MailMessage -to *alias@domain* -subject test -from *alias@domain* -body test -smtpserver *ip-address*
```
