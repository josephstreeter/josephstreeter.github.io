---
layout: post
title:  Apply FDCC LGPO
date:   2014-05-29 00:00:00 -0500
categories: IT
---






In earlier posts I showed how to script the local group policy object.

- <a title="Appy CIS Benchmarks to Windows Server 2008 R2 and Windows 7" href="http://www.joseph-streeter.com/?p=299" target="_blank">Apply CIS Benchmarks to Windows Server 2008 R2 and Windows 7</a>
- <a title="Microsoft Tools to Configure Local Group Policy" href="http://www.joseph-streeter.com/?p=291" target="_blank">Microsoft Tools to Configure Local Group Policy</a>

Here is a post from the- <a href="http://blogs.technet.com/b/fdcc/default.aspx">Microsoft's USGCB Tech Blog</a>- that shows another method:

<a href="http://blogs.technet.com/b/fdcc/archive/2011/08/10/set-fdcc-lgpo-for-windows-7.aspx" target="_blank">Set_FDCC_LGPO for Windows 7â€¦</a>

Here is the important part of the blog post:
{% highlight powershell %}Here's all you need to do:

- Extract the combined GPO zip file downloaded from NIST's site to your hard drive. To follow this example, extract it into C:\USGCB. (Note: don't just download the zip file â€“ extract its contents into C:\USGCB and retain the folder structures.)
- Copy ImportRegPol.exe and Apply_LGPO_Delta.exe into C:\USGCB.
- Using Notepad or any other text editor (I use vi.exe, believe it or not), create a PowerShell script called ApplyUSGCB.ps1 in C:\USGCB with the following commands, which you can copy and paste directly from here:

{% highlight powershell %}dir -recurse -include registry.pol |
?{ $_.FullName.Contains("\Machine\") } |
%{ cmd /c start /wait .\importregpol.exe -m $_ /log .\Policies.log }

dir -recurse -include registry.pol |
?{ $_.FullName.Contains("\User\") } |
%{ cmd /c start /wait .\importregpol.exe -u $_ /log .\Policies.log }

dir -recurse -include GptTmpl.inf  |
%{ cmd /c start /wait .\Apply_LGPO_Delta.exe $_ /log .\SecTempl.log }

.\Apply_LGPO_Delta.exe .\Deltas.txt /log .\Deltas.log /boot{% endhighlight %}
Here's how it works: The first command (which spans the first three lines) recursively searches for registry.pol files that have a full path including the text â€œ\Machine\; these are Computer Configuration administrative template files. Each one is is imported into Computer Configuration using ImportRegPol.exe with results logged to Policies.log. The â€œcmd /c start /wait is needed because ImportRegPol and Apply_LGPO_Delta are not console applications, but we want the script to wait for the commands to complete before continuing the script. The second command does the same, but looking for User Configuration administrative templates under â€œ\User\ folders. The third command searches for GptTmpl.inf security templates and applies them with Apply_LGPO_Delta, logging detailed results to SecTempl.log. The last command applies your policy customizations (see below), logging results to Deltas.log, and then rebooting.

- Create a Deltas.txt file listing any modifications you want to make to the NIST-provided GPOs. I have attached the Deltas.txt that I often use for my own work to this blog post (you will probably need at least the WindowsFirewall changes it includes). The file must adhere to the Apply_LGPO_Delta file format (a simple text format described in the Apply_LGPO_Delta documentation). There are some other sample files you can use here.
- You're ready to go! Start PowerShell with administrative rights, and run the following commands:

{% highlight powershell %}Set-ExecutionPolicy RemoteSigned

cd C:\USGCB

.\ApplyUSGCB.ps1{% endhighlight %}
The Set-ExecutionPolicy command needs to be configured only once. By default, PowerShell lets you run individual commands but not scripts. Setting the execution policy to RemoteSigned allows local unsigned scripts to run, but requires that any downloaded scripts or configuration files be digitally signed by a trusted publisher.

The â€œ.\ before the script (and commands in the script file) are required because unlike the rest of Windows, PowerShell does not include the current directory in the search path.{% endhighlight %}


