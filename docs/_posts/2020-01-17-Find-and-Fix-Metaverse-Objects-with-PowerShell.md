---
layout: post
title:  Find and Fix Metaverse Objects with PowerShell
date:   2020-01-17 00:00:00 -0500
categories: IT
---

I have had to fix Metaverse objects that, for some unknown reason, aren't connected to all Management Agents. There was a specific case where user objects were not created in Active Directory and the only fix seemed to be disconnect all of the MAs to allow the MV object to be deleted. Then, most times, the next sync would join them all and provision the AD user object.   

The "Get-Records" function finds all the MV objects that meet the supplied criteria. In our case that is based on employeeStatus and employeeType. The function returns a PSCustomObject that has meteverse data including the connector space ID for each connector.   

The "Evaluate-Records" function identifies the bad records by counting the number of connectors and capturing any that don't have all four and returns a PSCustomObject of all broken meteverse objects.   

The "Remove-Connectors" function will disconnect each of the existing connectors that do exist so that the meteverse deletion rule will delete the meteverse object.   

The "Run-Sync" function executes the run profiles.  

This script will require the Lithnet MIIS Automation module.   
{% highlight powershell %} 
Import-Module LithnetMIISAutomation  
function Get-Records($EmpTypes) 
{
     Write-Host "Retieving records"
     $Records=@()
     foreach ($EmpType in $EmpTypes)
     {
         Write-Host "  EmployeeType: $EmpType"
         $queries = @();
         $queries += New-MVQuery -Attribute employeeStatus -Operator Equals -Value "P"
         $queries += New-MVQuery -Attribute employeeType -Operator Equals -Value $EmpType
         $Records += Get-MVObject -Queries $queries
     }      
     $Results=@()
     foreach ($Record in $Records)
     {
         $Results+=[PSCustomObject] @{"AccountName"=$Record.Attributes["accountName"].Values.valueString
                                     "EmployeeID"=$Record.Attributes["employeeID"].Values.valueString
                                     "EmployeeNumber"=$Record.Attributes["employeeNumber"].Values.valueString
                                     "EmployeeType"=$Record.Attributes["employeeType"].Values.valueString
                                     "EmployeeStatus"=$Record.Attributes["employeeStatus"].Values.valueString
                                     "MVDN"=$Record.DN
                                     "ADMA-Main"=($Record.CSMVLinks | ? {$_.managementAgentName -eq "ADMA-Main"}).ConnectorSpaceID
                                     "ADMA-DM-Z"=($Record.CSMVLinks | ? {$_.managementAgentName -eq "ADMA-DM-Z"}).ConnectorSpaceID
                                     "SQLMA-SD"=($Record.CSMVLinks | ? {$_.managementAgentName -eq "SQLMA-SD"}).ConnectorSpaceID
                                     "MIMMA"=($Record.CSMVLinks | ? {$_.managementAgentName -eq "MIMMA"}).ConnectorSpaceID
                                     }
      }
     Return $Results }  
function Evaluate-Records($Records) 
{
     Write-Host "Evaluating records"
     $Results=@()
     foreach ($Record in $Records)
     {
         if (-not $Record."ADMA-MAIN".Guid)
         {
         $Results+=$Record
         }
     }
     Return $Results 
}   

function Run-Sync() 
{
     Write-Host "Running Delta Syncs"
     $MAs="ADMA-MAIN","ADMA-DMZ","SQLMA-SD","MIMMA"
     $RPs="DI","DS","EX","DI"
     foreach($MA in $MAs)
     {
         foreach ($RP in $RPs)
         {
             Write-Host "  $MA - $RP"
             Start-ManagementAgent -MA $MA -RunProfileName $RP
         }
     }
}  

function Remove-Connectors($Conns) 
{
     foreach ($Conn in $Conns)
     {
        $ADMCS=$ADDCS=$SDCS=$MCS=$NuLL
        if ($Result.ADMMA)
        {
            $ADMCS=Get-CSObject -MA ADMA-MAIN -DN $Conn.ADMMA
            if ($ADMCS){Disconnect-CSObject -CSObject $ADMCS -Force}
        }
        if ($Result.ADDMA)
        {
            $ADDCS=Get-CSObject -MA ADMA-DM-Z -DN $Conn.ADDMA
            if ($ADDCS){Disconnect-CSObject -CSObject $ADDCS -Force}
        }
        if ($Result.SDMA)
        {
            $SDCS=Get-CSObject -MA SQLMA-SD -DN $Conn.SDMA
            if ($SDCS){Disconnect-CSObject -CSObject $SDCS -Force}
        }
        if ($Result.MIMMA)
        {
            $MCS=Get-CSObject -MA MIMMA -DN $Conn.MIMMA
            if ($mcs){Disconnect-CSObject -CSObject $mcs -Force}
        }
    } 
}  

if ($BrokenIDs){Clear-Variable BrokenIDs}  
$IDs=Get-Records ("A","C","E","F","I") 
$BrokenIDs=Evaluate-Records $IDs  
if ($BrokenIDs) 
{
     if ($BrokenIDs)
     {
         Run-Sync
         Remove-Connectors $BrokenIDs
         Run-Sync
     }
     Else
     {
         "No objects to be disconnected"
     }
} 
Else 
{
     Write-Host "No broken records" 
} 
{% endhighlight %}  
