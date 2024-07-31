---

title:  Low Disk Space on Server 2008
date:   2013-01-25 00:00:00 -0500
categories: IT
---






For a while we had a production DC and a test DC complaining about low disk space on C:\. It didn't make any sense because the two DCs seemed to be configured identically to all of the other DCs. Eventually I narrowed it down to the Windows Error Reporting service. It was packing a directory full of logs for years.



To turn off the reporting:

- run the "oobe" tool
- In the Update this Server section click Enable Automatic Update and Feedback
- Click Manually configure settings"
- In the "Windows Error Reporting"- area of the "Manually Configure Settings" dialog box, click "Change Setting"
- On the "Windows Error Reporting Configuration"- dialog box, select "I don't want to participate, and don't ask me again" and click "OK"

To - clear the logs and free up some space you have to delete the contents of the "C:\programdata\microsoft\windows\wer\reportqueue" directory.


