---
layout: post
title:  Send Email to Gmail from Powershell
date:   2012-10-19 00:00:00 -0500
categories: IT
---






As if we don't all get enough email already....

Sending email to Gmail requires you to provide a username/password and a custom port number. This will send the output from DCDIAG in the body of the message.
{% highlight powershell %}$EmailFrom = "joseph.admin@domain.tld"
$EmailTo = "joseph.admin@gmail.com"
$Subject = "subject"
$Body = (DCDIAG /e /q /s:DC_Name)

$SMTPServer = "smtp.gmail.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("username", "pass");
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body){% endhighlight %}
The following code can be used if you have the Send-MailMessage available to you. This script will send a message if the disk space on C: falls below 125GB. This one will prompt for credentials, but the hash could easily be stored in a file. Not totally secure, but slightly better than keeping it in plain text.
{% highlight powershell %}$HostName = (Get-WmiObject -Class win32_computersystem).name
$From = "Admin, Joseph A <joseph.admin@domain.tld>"
$To = "Admin, Joseph A <joseph.admin@gmail.com>"
$Subject = "Disk Space Warning"
$Port = 587
$SmtpServer = "smtp.gmail.com"
$DiskSpace = (Get-PSDrive c).free / 1GB
$Body = "Low disk space on $hostname. `n$DiskSpace available on C:\"
$Warning = 125

if (!($hash)) {$hash = Get-Credential}

if ($DiskSpace -lt $Warning) {
Send-MailMessage `
-From $From `
-To $To `
-Subject $Subject `
-Body $Body `
-SmtpServer $SmtpServer `
-Port $Port `
-UseSsl `
-Credential $hash
}{% endhighlight %}


