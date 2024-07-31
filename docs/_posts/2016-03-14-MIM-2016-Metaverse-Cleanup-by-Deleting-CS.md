---

title:  MIM 2016 Metaverse Cleanup by Deleting CS
date:   2016-03-14 00:00:00 -0500
categories: IT
---






Cleaning up poorly constructed joins in Microsoft Identity Manager by cleaning out the FIMMA and ADMA connector spaces with the following steps:

1 - Disable â€œSynchronization Rule Provisioning in the Synchronization Management tool
2 - Disable the Metaverse object deletion rule
3 - Delete the ADMA connector space
4 - Delete the FIMMA connector space
5 - Perform a Delta synchronize on each management agent to process disconnectors clean those objects from the the metaverse
6 - Run a Full Import on the ADMA and FIMMA
7 - Run a Full synchronization on FIMMA first to project objects into the metaverse
8 - RUn a Full synchronization on the ADMA so that the objects in the ADMA CS join objects in the MV
9 - Re-enable â€œSynchronization Rule Provisioning in the Synchronization Management tool
10 - Run Full synchronization and Export on both the AD and FIM management agents
11 - Recreate the object deletion rule



