---
title:  Read DoD STIG XML file into MS Access Database
date:   2015-02-12 00:00:00 -0500
categories: IT
---

The Department of Defense offers public access to the Security Technical Implementation Guides for various equipment and technologies. They come in XML so it's possible to manipulate the information with PowerShell and put it into an Access Database.

In order to access an MS Access database with PowerShell from Windows 8 you will need to install the Microsoft Access Database Engine.
[Microsoft Access Database Engine](http://www.microsoft.com/en-us/download/details.aspx?id=13255)

```powershell
# Variables
$STIG = "c:\scripts\STIGS\U_Windows_2008_R2_DC_V1R10_STIG_Manual-xccdf.xml"
$Database = "C:\scripts\STIG.accdb"
$Table = "WS2008R2DC"

Function Read-STIG
{
Foreach ($Rule in $Rules)
{
#"#############################"
$discussion = ""+$Rule.rule.description+""
$discussion = [xml] $discussion

$Global:GroupID = $Rule.id
$Global:GroupTitle = $Rule.title
$Global:RuleTitle = $Rule.rule.title
$Global:id = $Rule.rule.id
$Global:Severity = $Rule.rule.severity
$Global:Weight = $Rule.rule.weight
$Global:Version = $Rule.rule.version
$Global:CheckContent = $Rule.rule.fixtext."#text"

$Global:VulnerabilityDiscussion = $discussion.test.VulnDiscussion

If ($discussion.test.FalsePositives)
{
$Global:FalsePositives = $discussion.test.FalsePositives
}
Else
{
$Global:FalsePositives = "None"
}

If ($discussion.test.FalseNegatives)
{
$Global:FalseNegatives =$discussion.test.FalseNegatives
}
Else
{
$Global:FalseNegatives = "None"
}

$Global:Documentable = $discussion.test.Documentable

If ($discussion.test.FalseNegatives)
{
$Global:Mitigations = $discussion.test.Mitigations
}
Else
{
$Global:Mitigations = "None"
}

If ($discussion.test.SeverityOverrideGuidance)
{
$Global:SeverityOverride = $discussion.test.SeverityOverrideGuidance
}
Else
{
$Global:SeverityOverride = "None"
}

If ($discussion.test.PotentialImpacts)
{
$Global:PotentialImpacts = $discussion.test.PotentialImpacts
}
Else
{
$Global:PotentialImpacts = "None"
}

If ($discussion.test.ThirdPartyTools)
{
$Global:ThirdPartyTools = $discussion.test.ThirdPartyTools
}
Else
{
$Global:ThirdPartyTools = "None"
}

If ($discussion.test.MitigationControl)
{
$Global:MitigationControls = $discussion.test.MitigationControl
}
Else
{
$Global:MitigationControls = "None"
}

If ($discussion.test.Responsibility)
{
$Global:Responsibility = $discussion.test.Responsibility
}
Else
{
$Global:Responsibility = "None"
}

If ($discussion.test.IAControls)
{
$Global:IAControls = $discussion.test.IAControls
}
Else
{
$Global:IAControls = "None"
}
#"Group ID: $GroupID"
#"Group Title: $GroupTitle"
#"ID: $Id"
#"Severity: $Severity"
#"Weight: $Weight"
#"Version: $Version"
#"Rule Title: $RuleTitle"
#"Check Content: $CheckContent"
#"Vulnerability Discussion: $VulnerabilityDiscussion"
#"False Positives: $FalsePositives"
#"False Negatives: $FalseNegatives"
#"Documentable: $Documentable"
#"Mitigations: $Mitigations"
#"Severity Override: $SeverityOverride"
#"Potential Impacts: $ThirdPartyTools"
#"Third Party Tools: $MitigationControls"
#"Mitigation Controls: $Responsibility"
"Responsibility: $Responsibility"
#"IA Controls: $IAControls"
#""

Connect-Database
Upate-Database
Close-Database
}
}

Function Upate-Database
{
$rs.addnew()
$rs.Fields.Item("GroupID").Value = $GroupID
$rs.Fields.Item("GroupTitle").Value = $GroupTitle
$rs.Fields.Item("RuleID").Value = $id
$rs.Fields.Item("Severity").Value = $Severity
$rs.Fields.Item("RuleVersion").Value = $Version
$rs.Fields.Item("RuleTitle").Value = $RuleTitle
$rs.Fields.Item("VunlDiscuss").Value = $VulnerabilityDiscussion
$rs.Fields.Item("FlaseNeg").Value = $FalseNegatives
$rs.Fields.Item("FalsePos").Value = $FalsePositives
$rs.Fields.Item("Documentable").Value = $Documentable
#$rs.Fields.Item("Responsibility").Value = $Responsibility
$rs.Fields.Item("IAControls").Value = $IAControls
$rs.Fields.Item("CheckContent").Value = $CheckContent
$rs.Fields.Item("FixText").Value = $MitigationControls
$rs.Update()

}

Function Connect-Database
{
# Configure database connection
$adOpenStatic = 3
$adLockOptimistic = 3

$Global:conn=New-Object -com "ADODB.Connection"
$Global:rs = New-Object -com "ADODB.Recordset"
$Global:conn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$Database;Persist Security Info=True;")

$rs.Open("SELECT * FROM $Table",$conn,$adOpenStatic,$adLockOptimistic)
}

Function Close-Database
{
$rs.Close()
$conn.Close()
}

Function Get-STIG
{
# Get STIG info from XML
$Global:xml = [xml] $(Get-Content $STIG)
$Global:Rules = $xml.Benchmark.Group
}


Get-STIG
Read-STIG
```
