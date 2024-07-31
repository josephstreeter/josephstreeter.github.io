---

title:  Configure PowerShell to Manage Office 365
date:   2012-10-19 00:00:00 -0500
categories: IT
---






<h5 id="O365PowerShellDirSyncKB-Requirements">Requirements:</h5>

- Windows 7 or Server 2008
- Windows PowerShell
- .NET Framework- 3.5.1
- Windows PowerShell and the .NET Framework- 3.5.1 enabled.
- Microsoft Online Services Sign-in Assistant

- <a href="http://go.microsoft.com/fwlink/p/?linkid=236299" rel="nofollow">32 bit version</a>
- <a href="http://go.microsoft.com/fwlink/p/?linkid=236300" rel="nofollow">64 bit version</a>


- Microsoft Online Services Module for PowerShell

- <a href="http://go.microsoft.com/fwlink/p/?linkid=236345" rel="nofollow">32 bit version</a>
- <a href="http://go.microsoft.com/fwlink/p/?linkid=236293" rel="nofollow">64 bit version</a>



<h5 id="O365PowerShellDirSyncKB-TostartaPowerShellsession">To start a PowerShell session:</h5>

- Run c:\program files\microsoft online directory sync\dirsyncconfigshell.psc1,
- To use an existing PowerShell session load the Directory Synchronization snapin:

- ***Add-PSSnapin Coexistence-Configuration***


- Import the Microsoft Online Services Module

- ***Import-Module MSOnline***



These commands can be added to the PowerShell Profile so that they run automatically:
<a href="http://msdn.microsoft.com/en-us/library/windows/desktop/bb613488(v=vs.85).aspx" rel="nofollow">http://msdn.microsoft.com/en-us/library/windows/desktop/bb613488(v=vs.85).aspx</a>


