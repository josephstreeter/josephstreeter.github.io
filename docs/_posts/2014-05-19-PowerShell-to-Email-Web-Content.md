---

title:  PowerShell to Email Web Content
date:   2014-05-19 00:00:00 -0500
categories: IT
---






I wanted a script that would email me the daily links that are posted on a web site for a radio show I listen to. This script will need some rewriting for other sites, but it does what I want it to do.
```powershell$Page = "http://www.site.com/daily_links.html"
$Div_Class = "main_content"

$Site = Invoke-WebRequest $Page -UseBasicParsing
$Body = $Site | Select-String -Pattern '(?s)<div class="main_content">.*?&lt/div&gt' | % {$_.matches} | % {$_.Value}

Send-MailMessage `
-to from@domain.tld `
-subject "Daily Links" `
-from to@domain.tld `
-body $Body `
-smtpserver smtp.domain.tld `
-BodyAsHtml
```


First, I set two variables. One is the URL for the site that has the links and the other is the class associated with the <div> tag that contains the links I want.

```powershell$Page = "http://www.site.com/daily_links.html"
$Div_Class = "main_content"```

To do this I used the Invoke-Webrequest cmdlet. In this case I was prompted to accept a cookie every time the script ran preventing it from being non-interactive. To get around this I had to add the "-UseBasicParsing" switch. Then I use the Select-String cmdlet to parse out the HTML <div> that contains the links.

```powershell
$Site = Invoke-WebRequest $Page -UseBasicParsing
$Body = $Site | Select-String -Pattern '(?s)<div class="main_content">.*?&lt/div&gt' | % {$_.matches} | % {$_.Value}
```

Now, just use the Send-MailMessage cmdlet to send the variable that contains the links. Since the content is the remaining HTML from the site I use the "-BodyAsHtml" switch.
```powershellSend-MailMessage `
-to to.domain.tld `
-subject "Daily Links" `
-from from.domain.tld `
-body $Body `
-smtpserver smtp.domain.tld `
-BodyAsHtml
```


