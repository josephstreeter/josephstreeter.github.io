---
layout: post
title:  Active Directory Account and Password Settings
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Some helpful information about setting passwords and configuring accounts when programatically creating Active Directory user objects.



***pwdLastSet Attribute***

From MSDN:- <a href="http://msdn.microsoft.com/en-us/library/windows/desktop/ms679430(v=vs.85).aspx">Pwd-<em>Last</em>-<em>Set attribute</em></a>

The date and time that the password for this account was last changed. This value is stored as a large integer that represents the number of 100 nanosecond intervals since January 1, 1601 (UTC). If this value is set to 0 and the- <a href="http://msdn.microsoft.com/en-us/library/windows/desktop/ms680832(v=vs.85).aspx">***User-Account-Control***</a>- attribute does not contain the***UF_DONT_EXPIRE_PASSWD***- flag, then the user must set the password at the next logon.

***UserAccountControl Settings***
<table width="500" border="0" cellspacing="0" cellpadding="5">
<tbody>
<tr>
<td valign="top">512</td>
<td valign="top">Enabled Account</td>
</tr>
<tr>
<td valign="top">514</td>
<td valign="top">Disabled Account</td>
</tr>
<tr>
<td valign="top">544</td>
<td valign="top">Enabled, Password Not Required</td>
</tr>
<tr>
<td valign="top">546</td>
<td valign="top">Disabled, Password Not Required</td>
</tr>
<tr>
<td valign="top">66048</td>
<td valign="top">Enabled, Password Doesn't Expire</td>
</tr>
<tr>
<td valign="top">66050</td>
<td valign="top">Disabled, Password Doesn't Expire</td>
</tr>
<tr>
<td valign="top">66080</td>
<td valign="top">Enabled, Password Doesn't Expire &amp; Not Required</td>
</tr>
<tr>
<td valign="top">66082</td>
<td valign="top">Disabled, Password Doesn't Expire &amp; Not Required</td>
</tr>
<tr>
<td valign="top">262656</td>
<td valign="top">Enabled, Smartcard Required</td>
</tr>
<tr>
<td valign="top">262658</td>
<td valign="top">Disabled, Smartcard Required</td>
</tr>
<tr>
<td valign="top">262688</td>
<td valign="top">Enabled, Smartcard Required, Password Not Required</td>
</tr>
<tr>
<td valign="top">262690</td>
<td valign="top">Disabled, Smartcard Required, Password Not Required</td>
</tr>
<tr>
<td valign="top">328192</td>
<td valign="top">Enabled, Smartcard Required, Password Doesn't Expire</td>
</tr>
<tr>
<td valign="top">328194</td>
<td valign="top">Disabled, Smartcard Required, Password Doesn't Expire</td>
</tr>
<tr>
<td valign="top">328224</td>
<td valign="top">Enabled, Smartcard Required, Password Doesn't Expire &amp; Not Required</td>
</tr>
<tr>
<td valign="top">328226</td>
<td valign="top">Disabled, Smartcard Required, Password Doesn't Expire &amp; Not Required</td>
</tr>
</tbody>
</table>


