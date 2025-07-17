# Automation

CLI snippets to manage different aspects of Azure DevOps.

## Export Iterations

```powershell
$Org = "https://dev.azure.com/MC-SEC-IAM" 
$Project = "Sandbox"

$Iterations = az boards iteration project list --org $Org --project $Project

$Sprints = ($Iterations | convertfrom-json).children | select name, @{n="FinishDate";e={$_.attributes.finishdate}}, @{n="StartDate";e={$_.attributes.startdate}}
```

## Create Interations

Create iterations for the project

```powershell
$Project = "Sandbox"

foreach ($Sprint in $Sprints)
{
    az boards iteration project create --name $Sprint.Name --finish-date $Sprint.finishdate --start-date $Sprint.startdate --project $Project --path "\$Project\iteration"
}
```

Add project iterations to a team.

```powershell
$iterations | convertfrom-json | select -ExpandProperty Children | % {az boards iteration team add --id $_.identifier --team "sandbox team" --org $org --project $project}
```
