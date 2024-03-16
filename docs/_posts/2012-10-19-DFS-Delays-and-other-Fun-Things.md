---
layout: post
title:  DFS Delays and other Fun Things
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Starting to work my way through some DFS issues now that we have it up and running. For hosts that are domain memebers it works like a champ. The hosts that are not joined to the domain, Windows and Macs, it's not so slick.


- <a href="http://blogs.technet.com/b/askds/archive/2009/09/29/o-dfs-shares-where-art-thou-part-1-3.aspx">O'DFS Shares! Where Art Thou? â€“ Part 1/3 - Ask the Directory Services Team</a>
- <a href="http://blogs.technet.com/b/askds/archive/2009/09/30/o-dfs-shares-where-art-thou-part-2-3.aspx">O'DFS Shares! Where Art Thou? â€“ Part 2/3 - Ask the Directory Services Team</a>
- <a href="http://blogs.technet.com/b/askds/archive/2009/10/01/o-dfs-shares-where-art-thou-part-3-3.aspx">O'DFS Shares! Where Art Thou? â€“ Part 3/3 - Ask the Directory Services Team</a>
- <a href="http://support.microsoft.com/kb/244380">How to configure DFS to use fully qualified domain names in referrals
- TechNet</a>


It appears that the "DfsDnsConfig" registry key that the TechNet article says must be added to all DFS servers must also be added to all Domain Controllers.


