---
title:  Send-MailMessage Example
date:   2014-01-21 00:00:00 -0500
categories: IT
---

An example of using the Send-MailMessage to send an email and attachment

```powershell
Import-module activedirectory

$Domain = (get-addomain).Forest.toupper()
$RootDSE = (Get-ADRootDSE).defaultnamingcontext
$date = get-date -uformat "%Y-%m-%d"

Search-ADAccount -LockedOut | FT Name,ObjectClass -A | out-file c:\locked_out.txt
$Attachments = "c:\locked_out.txt"

$To = "Joe Admin <joe.admin@domain.tld>"
$From = "AD Service <ad.service@domain.tld>"
$Subject = "All Locked Out Users - $date ($domain)"
$Attachments = $NetIDList
$SmtpServer = "smtp.domain.tld"
$Body = " All user objects that are locked out. List of NetIDs is attached."

Send-MailMessage `
-To $To `
-From $From  `
-Subject $Subject `
-Body $Body `
-SmtpServer $SmtpServer `
-Attachments $Attachments

Remove-Item $Attachments
```
