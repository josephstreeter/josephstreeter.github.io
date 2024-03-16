---
layout: post
title:  Microsoft Tools to Configure Local Group Policy
date:   2012-10-19 00:00:00 -0500
categories: IT
---


I was doing some digging into a fully automated install and noticed some tools. By the names of them I couldn't tell if they were provided my Microsoft or home grown for these deployments.

Turns out that they are Microsoft tools and can be downloaded here:
<a href="http://blogs.technet.com/b/fdcc/archive/2008/05/07/lgpo-utilities.aspx">Utilities for automating Local Group Policy management</a>

These tools allow you to apply policy based Group Policy settings to the local Group Policy Object using text files for input.

For example, you have one or more text files with the Group Policy settings you want applied. One of them is a text file named lgpo.txt with some Advanced Firewall settings like the ones below:
{% highlight powershell %}; 
Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall
PolicyVersion
DWORD:0x00000200; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
DefaultOutboundAction
DWORD:0x00000000

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
DefaultInboundAction
DWORD:0x00000001

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
AllowLocalPolicyMerge
DWORD:0x00000001

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
AllowLocalIPsecPolicyMerge
DWORD:0x00000001

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
DisableNotifications
DWORD:0x00000000

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
DisableUnicastResponsesToMulticastBroadcast
DWORD:0x00000001

; Description
Computer
SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile
EnableFirewall
DWORD:0x00000001

{% endhighlight %}
The command you run looks something like:

Here is a bit of the documentation that comes with the tool.

***Command line syntax and usage:***

Apply_LGPO_Delta.exe inputfile0 [inputfile1 ...] [/log LogFile] [/error ErrorLogFile] [/boot]

***inputfileN*** One or more input files specifying the changes to make. Input files must be security template files, or registry-based policy files using a custom file format described below. Apply_LGPO_Delta automatically determines whether a file is a custom policy file or a security template. Security templates can be created using the Security Templates MMC snap-in.

***/log LogFile*** Writes detailed results to a log file. If this option is not specified, output is not logged nor displayed.

***/error ErrorLogFile*** Writes error information to a log file. If this option is not specified, error information is displayed in a message box dialog.

***/boot*** Reboots the computer when done.

This utility is not a console app, so you won't see a console window appear, and if you start it from a CMD prompt, it will run in the background â€“ CMD won't wait for it to complete. You can check in TaskMgr to see when it completes. If you want CMD to wait for Apply_LGPO_Delta to complete, run the utility with "start /wait".

Usage is demonstrated in the SampleUsage.cmd batch file that comes with Apply_LGPO_Delta.

***Input files:***

Apply_LGPO_Delta accepts two types of input files: security templates, and registry-based policy files. Apply_LGPO_Delta automatically determines whether each input file is a security template or a policy file and handles each appropriately.

Although security template files are text files that can be created or edited with Notepad, the MMC Security Templates snap-in is the recommended security template editor that ensures correct formatting and syntax. Apply_LGPO_Delta runs a secedit.exe /configure â€¦ command for each security template on the command line to import its settings. If the /log option is used, Apply_LGPO_Delta captures all secedit.exe output into the log file. Note that you may see secedit.exe in the process list (e.g., in Task Manager), but no visible window for it.

Windows normally uses registry.pol files to describe registry-based policy settings. Registry.pol is a documented, binary file format, but there aren't any good viewers or editors for directly manipulating those files. Therefore, for registry-based policy, a custom, Notepad-editable file format has been defined for Apply_LGPO_Delta. It is described in detail below. Apply_LGPO_Delta parses each file, and Group Policy APIs are used to apply them to local policy. (ImportRegPol.exe can parse registry.pol files and produce text files that Apply_LGPO_Delta can consume.)


