---
layout: post
title:  Enterprise Printer Status
date:   2015-11-27 00:00:00 -0500
categories: IT
---






Most places have a lot of printers. Too many printers. This will get you a list of them and their status.
{% highlight powershell %}
$PrintServers = (Get-ADObject -f 'objectClass -eq "printqueue"' -pr servername) | group servername | select name

$PrintRpt = @()

foreach ($PrintServer in $PrintServers)
{
$PrintServer
$Printers = get-printer -ComputerName $PrintServer.name
foreach ($Printer in $Printers)
{
$print = New-Object -TypeName System.Object
$print | add-member -MemberType NoteProperty -name PrintServer -value $PrintServer.name
$print | add-member -MemberType NoteProperty -name PrinterName -value $Printer.name
$print | add-member -MemberType NoteProperty -name PrinterStatus -value $Printer.printerstatus
$print | add-member -MemberType NoteProperty -name PrinterPortName -value $Printer.PortName
$PrintRpt += $Print
}
}

Function Create-Report {
"`nOperational"
$printrpt | ? {$_.PrinterStatus -match "normal"} | ft -AutoSize
"`nLow Toner"
$printrpt | ? {$_.PrinterStatus -match "tonerLow"} | ft -AutoSize
"`nPaused"
$printrpt | ? {($_.PrinterStatus -match "Paused") -and ($_.PrinterStatus -notmatch "offline") -and ($_.PrinterStatus -notmatch "Error")} | ft -AutoSize
"`nOffline"
$printrpt | ? {($_.PrinterStatus -match "offline")} | ft -AutoSize
"`nError"
$printrpt | ? {($_.PrinterStatus -match "Error") -and ($_.PrinterStatus -notmatch "offline")} | ft -AutoSize
"`nNot Pending Deletion"
$printrpt | ? {($_.PrinterStatus -match "PendingDeletion")} | ft -AutoSize
}

Create-Report
{% endhighlight %}


