---
layout: post
title:  A Truely Amazing Story of a Forest Recovery
date:   2012-10-19 00:00:00 -0500
categories: IT
---

by <a href="http://cbfive.com/blog/author/rcrandall.aspx">Rich Crandall</a>

A story of an Active Directory Forest recovery from an environment with one DC and no backup.


Not too long ago, through the InitialAssist("http://cbfive.com/InitialAssist.aspx") program, I had the opportunity to spend some time assisting an organization in the recovery of directory data and resource access.
The organization had put out a request for assistance from the Microsoft newsgroups and had received some excellent suggestions but unfortunately they didn&rsquo;t resolve the issue. On Saturday afternoon, after a half day session at the Microsoft Directory Services Masters program, I became involved through the request on the Microsoft directory service newsgroup forum.
The organization had lost their only domain controller and didn&rsquo;t have any backups. They had a mirrored set of the disks with the database file intact but after a variety of attempts, they were unable to bring back functionality. I thought that I may be able to help and at my request they provided me a Windows 2008 R2 server to terminal into, a Server 2003 32-bit ISO, and a copy of the data on the disks from the failed server. With that, we were able to recover all directory services and restore all user functionality; and have a good time doing it. I wasn&rsquo;t sure the process was going to work well at the time but I enjoyed the experience and I thought that you might as well.
# Background
The organization is a small business with about 300 users and like all small businesses, budgets were lean and resources thin. As a result, the organization had one all-purpose server to provide for all of their needs: file server, domain controller, DNS, DHCP, etc. One night, during hardware maintenance, as the technician was pulling his arm back out from over top of the server, he bumped the power cord. Unfortunately, the power cord was hit hard enough that it caused a hardware failure on the server (they believe with the motherboard) which prevented it from booting.
The truly unfortunate news was that the organization didn&rsquo;t have any redundancy or backups of their all-purpose server. The good news was that the disks with the directory database, SYSVOL, network shares, home folders, and user profile data were functional. Another server was rushed in with a freshly loaded operating system and the disks were attached. A few attempts were made to promote the machine as a domain controller and then run advanced database operations to replace the new database with the original database. Unfortunately, these attempts were unsuccessful.
The data was fully intact and readable but the real challenge was in knowing who it belonged to. A review of the access control list showed SIDs only (except for the ACEs from the new machine) so it was impossible (well &ndash; really, really difficult) to know who owned the data.
And this unfortunately is how their Friday evening progressed.
# Restoring Continuity
The first thing that I needed was to learn a little more about the environment that had been lost. Fortunately the disk with the original NTDS.DIT database file was intact.
### Prepping the Landing
I mounted the original NTDS.DIT file using the DSAMain database mounting utility. With the database mounted, I was able to use LDP to connect to the mounted database and collect some important and some critical information including:

- The domain name 
- Domain controller name 
- Domain SID [Critical] 

I installed the Hyper-V role on the terminal server and a 32-bit Server 2003 VM was built. Using NewSID, I set the SID of the Server 2003 VM to the domain SID that I collected by mounting the original database. After the new SID was applied, I promoted the server as the first domain controller in the domain; matching the new domain name to that of the legacy domain. Since a domain SID is set by the first domain controller promoted in the domain, I now had accomplished a critical step in the process of recreating the domain with the same SID as the old domain. This is why collecting the SID from the legacy domain was so critical.
### Exporting and Massaging Data
With the domain in place, I was part of the way there but I still don&rsquo;t have appropriate access to the file system data defined. In order to do that, using <a href="http://www.google.com/url?sa=t&amp;source=web&amp;cd=1&amp;ved=0CBgQFjAA&amp;url=http%3A%2F%2Fwww.joeware.net%2Ffreetools%2Ftools%2Fadfind%2Findex.htm&amp;ei=zEdQTPOcG4eglAfc6LC7CQ&amp;usg=AFQjCNEgasYTSzpF1ymJcQX4zu5MDnqZog">JoeWare&rsquo;s ADFind</a>, I&rsquo;d need to export all of the security principals (excluding computer accounts) from the mounted legacy database. While ADFind is a fine tool, it was used in this case particularly because I wanted to save some steps and pull the data (particularly the SID) in a friendly format. Besides the SID, other relevant user data was retained including display name, first and last name, logon scripts, home folders, profile paths, and others. Groups with their SIDs and membership were also collected. All of the data was exported in CSV format.

<table border="1" cellspacing="0" cellpadding="0" align="center">
<tbody>
<tr>
<td width="48" valign="top">
***Row***
</td>
<td width="133" valign="top">
***samAccountName***
</td>
<td width="129" valign="top">
***displayName***
</td>
<td width="177" valign="top">
***objectSID***
</td>
</tr>
<tr>
<td width="48" valign="top">
1
</td>
<td width="133" valign="top">
mkline
</td>
<td width="129" valign="top">
Mike Kline
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1321
</td>
</tr>
<tr>
<td width="48" valign="top">
2
</td>
<td width="133" valign="top">
ejansen
</td>
<td width="129" valign="top">
Eric Jansen
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1322
</td>
</tr>
<tr>
<td width="48" valign="top">
3
</td>
<td width="133" valign="top">
ffrommherz
</td>
<td width="129" valign="top">
Florian Frommherz
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1325
</td>
</tr>
</tbody>
</table>

I needed the consecutive rows to have consecutive SIDs so I inserted missing rows between row 2 and row 3 and created dummy user accounts with the mandatory attributes so it looked like this:
<p align="center">
<table border="1" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td width="48" valign="top">
***Row***
</td>
<td width="133" valign="top">
***samAccountName***
</td>
<td width="129" valign="top">
***displayName***
</td>
<td width="177" valign="top">
***objectSID***
</td>
</tr>
<tr>
<td width="48" valign="top">
1
</td>
<td width="133" valign="top">
mkline
</td>
<td width="129" valign="top">
Mike Kline
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1321
</td>
</tr>
<tr>
<td width="48" valign="top">
2
</td>
<td width="133" valign="top">
ejansen
</td>
<td width="129" valign="top">
Eric Jansen
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1322
</td>
</tr>
<tr>
<td width="48" valign="top">
3
</td>
<td width="133" valign="top">
deleteMe01
</td>
<td width="129" valign="top">
Del Me01
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1323
</td>
</tr>
<tr>
<td width="48" valign="top">
4
</td>
<td width="133" valign="top">
deleteMe02
</td>
<td width="129" valign="top">
Del Me02
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1324
</td>
</tr>
<tr>
<td width="48" valign="top">
5
</td>
<td width="133" valign="top">
ffrommherz
</td>
<td width="129" valign="top">
Florian Frommherz
</td>
<td width="177" valign="top">
S-1-5-21-<domain>-1325
</td>
</tr>
</tbody>
</table>

This was done throughout the data to ensure that all rows matched to consecutive SIDs. All system created attributes (columns) were removed including the ***objectSID ***column. Other attributes were removed as well such as the ***member*** attribute which we would save for later so that I could later restore group membership.
I had now reached another critical milestone in the process. I had an ordered list of accounts with the lowest RID at the top and the highest RID at the bottom - with no gaps in numbering.
### Importing Data
Before I could import our data into the new environment, I needed to know what the highest used RID was in our VM recovery environment. I did a quick check and realized that a RID that belonged to a user in the legacy environment had already been eaten in the target environment. So we had our first casualty. I had to remove the first row from the CSV file. That user had to have their access recreated manually.
Now that I knew that the next available RID in the environment was the same as the first RID that I needed from the CSV file, I could begin the import. Using CSVDE, I took the newly formatted CSV file and imported it into our new directory. CSVDE ran through the file and created each user and group in ascending order resulting in each account receiving the exact same SID that it had in the legacy domain.
Then using the membership data that was saved, group membership was restored in the directory. A quick script was run to reset each user password and enable the account. The password was set to a combination of attribute data so that each user would have a unique password and that would hopefully not be <em>easily</em> known to other users if they got there first.
### A Quick Test
While collecting, massaging, and importing the data as described above, I had built another VM that I joined to the domain as a regular member server after the import was complete. Once joined to the domain, an account was randomly selected and logged on to test the results.
At logon I was able to connect to the domain and manually browse to data that was permissioned for the user account (home folders were named after user names so I knew where to go for some data to test). Equally important, I was unable to access other user&rsquo;s data.
Logon scripts ran but drive mappings failed because shares no longer existed. That problem would get fixed after a while but at this point there was a bigger issue to solve.
### Orphaned Workstations
Logging on to our test machine was successful but users had their own machines to log on to and these machines were now lost sheep that needed to be brought back into the fold. We knew the local admin password so a quick script was wrapped around NETDOM REMOVE to remove workstations from the domain. Then after reboot another script was used to bring them into the new target domain.
Now workstations were back on board and users could log in and almost have the same experience that they had on Friday when they left &ndash; now 2 days ago.
### What&rsquo;s Left
There were a few loose ends left to sew up and a few that were sewn up along the way. For instance, as part of the user and group export and import, I also exported and imported OUs along with their gpLink attribute. The data was moved from the legacy SYSVOL into the target SYSVOL and the domain portion of the policy was programmatically created. As mentioned above, logon scripts were reviewed to identify and create shares.
Throughout the process, snapshots of the VM were taken in case something happened again. The last thing that was done though was that a second domain controller was promoted to provide some redundancy and a proper backup was taken.
There were a few other things that we would have liked to work on but I had run out of time. I had been working nonstop on this issue since late afternoon on Saturday and it was now into the early hours of morning on Monday.Later that day I had the first exam for the Masters program and I needed to get some sleep to be best prepared.
# Summary
One thing that I can&rsquo;t help to take notice of from this experience is how what would traditionally be considered fringe knowledge was so important in the recovery of this organization&rsquo;s continuity of service. The one key piece of knowledge that the domain takes on the SID of the first DC promoted is what prevented a poor user experience.
I can&rsquo;t tell you how many times as a trainer or student that I heard someone say, &ldquo;Who cares about that? What&rsquo;s the relevance of that really?&rdquo; In a classroom setting, it&rsquo;s often hard to say what the relevance is. However, I wanted to provide one example that demonstrates that sometimes fringe knowledge, and a solid understanding of concepts, can help to solve a significant issue.



