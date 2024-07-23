---
layout: post
title:  Exchange 2010 PowerShell Search Root
date:   2015-03-12 00:00:00 -0500
categories: IT
---






In a multi-domain forest you may see the following error when attempting to use some Exchange PowerShell commands from a child domain.

"The requested search root <span class="skimlinks-unlinked">domain.local/Users</span>' is not within the scope of this operation. Cannot perform searches outside the scope '<span class="skimlinks-unlinked">child.domain.local</span>'."

Executing the following command will allow the your commands to succeed.

"Set-AdServerSettings -ViewEntireForest $True"

Additionally, you may add "â€“ignonreDefaultScope- " to the command that you are trying to run.

"get-mailbox user.name- â€“ignonreDefaultScope"


