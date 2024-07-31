---

title:  AD Forest DCDiag and RepAdmin Report
date:   2016-11-23 00:00:00 -0500
categories: IT
---






Two earlier posts, <a href=http://www.joseph-streeter.com/?p=1237>EASY TO READ DCDIAG REPORT</a> and <a href=http://www.joseph-streeter.com/?p=1234>EASY TO READ REPADMIN RESULTS</a>, included scripts for displaying the high level results of DCDiag and RepAdmin. I had since combined the two and made some tweaks, but it never really seemed right.

I've finally gotten around to making it presentable and more functional. It now displays all of the DCDiag tests and their results in two separate tables rather than just a few of the tests that I'd selected. It also accurately displays the server name for each set of tests. The previous versions would only create reports for a single domain, but now, since I work in a multi domain forest these days, it will grab the DCs in all domains in the forest.

The RepAdmin results are now broken up by domain controller and sorted by context. This makes it a little easier to read and track issues.

```powershell
# http://www.anilerduran.com/index.php/2013/how-to-parse-dcdiag-output-with-powershell/
# Functions

Function Get-ForestDomainControllers
{
    $Results=@()
    foreach ($domain in (Get-ADForest).domains )
    {
        $Results+=(Get-ADdomain $domain).ReplicaDirectoryServers
    }
    Return $Results
}

Function Get-DCDiagReport($DC)
{
    "Testing $DC"
    $DCDIAG = dcdiag /s:$DC /v #/test:Intersite /test:topology
    $DCDiagResults = New-Object System.Object
    $DCDiagResults | Add-Member -name Server -Value $DC -Type NoteProperty -Force

    Foreach ($Entry in $DCDIAG)
    {
        Switch -Regex ($Entry)
        {
            "Starting" {$Testname = ($Entry -replace ".*Starting test: ").Trim()}
            "passed|failed" {If ($Entry -match "passed") {$TestStatus = "Passed"} Else {$TestStatus = "failed"}}
        }

        If ($TestName -ne $null -and $TestStatus -ne $null)
        {
            $DCDiagResults | Add-Member -Type NoteProperty -name $($TestName.Trim()) -Value $TestStatus -Force
        }
    }
    Return $DCDiagResults
}

Function Get-ReplReport
{
    "Starting Repadmin Tests"

    $Repl = repadmin /showrepl * /csv
    $ReplResults = $Repl | ConvertFrom-Csv

    $ReplReport = @()

    Foreach ($result in $ReplResults)
    {
        $ReplReport += New-object PSObject -Property @{
            "DestSite" = $Result.'Destination DSA Site'
            "Dest" = $Result.'Destination DSA'
            "NamingContext" = $Result.'Naming Context'
            "SourceSite" = $Result.'Source DSA Site'
            "Source" = $Result.'Source DSA'
            "Transport" = $Result.'Transport Type'
            "NumberFailures" = $Result.'Number of Failures'
            "LastFailureTime" = $Result.'Last Failure Time'
            "LastSuccessTime" = $Result.'Last Success Time'
            "LastFailureStatus" = $Result.'Last Failure Status'
        }
    }
    
    Return $ReplReport
}

# Gather Data

Clear-Host
Import-Module activedirectory

"Collecting Forest Domain Controllers"
$DCs=Get-ForestDomainControllers

"Starting DCDiag Tests"
$DCDiagRpt=@()
foreach ($DC in $DCs | sort)
{
    $DCDiagRpt+=Get-DCDiagReport $DC.ToUpper()
}

# Display Results

"Starting Repadmin Tests"
$ReplRrt=Get-ReplReport

"DCDiag Test Results (Page 1 of 2)"
$DCDiagRpt | ft Server,Connectivity,Advertising,DFSREvent,SysVolCheck,KccEvent,NCSecDesc,Replications,RidManager,Services,Intersite,LocatorCheck -AutoSize
"DCDiag Test Results (Page 2 of 2)"
$DCDiagRpt | ft Server,FrsEvent,KnowsOfRoleHolders,MachineAccount,NetLogons,ObjectsReplicated,SystemLog,VerifyReferences,CheckSDRefDom,CrossRefValidation -AutoSize

"Replication Test Results"
$Servers = $ReplRrt | select -ExpandProperty Source -Unique

foreach ($Server in ($Servers | Sort))
{
    "$Server"
    $ReplRrt | ? {$_.Source -eq $Server} | select "NamingContext","Dest","SourceSite","DestSite","NumberFailures","LastFailureTime","LastFailureStatus","LastSuccessTime","Transport" | sort NamingContext,Dest | ft -AutoSize
}
```