---
title: Azure DevOps Automation and CLI Management
description: Comprehensive guide to automating Azure DevOps operations using Azure CLI, PowerShell, and REST APIs for project management, boards, pipelines, and repositories
author: Joseph Streeter
date: 2025-09-13
tags: [azure-devops, automation, cli, powershell, rest-api, boards, pipelines, repositories]
---

Azure DevOps automation enables efficient management of projects, work items, pipelines, and repositories through command-line interfaces and APIs.

## 🎯 **Overview**

This guide provides practical automation scripts and techniques for:

- **Project and team management** - Create and configure projects, teams, and permissions
- **Work item and board automation** - Manage iterations, work items, and board configurations
- **Pipeline automation** - Create, configure, and manage build and release pipelines
- **Repository management** - Automate Git operations, branching policies, and security
- **Bulk operations** - Efficiently handle large-scale changes and migrations

## 🛠️ **Prerequisites and Setup**

### Azure CLI Installation and Configuration

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Azure DevOps extension
az extension add --name azure-devops

# Configure default organization and project
az devops configure --defaults organization=https://dev.azure.com/YourOrg project=YourProject

# Login with personal access token
export AZURE_DEVOPS_EXT_PAT=your_personal_access_token
```

### PowerShell Prerequisites

```powershell
# Install required modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name VSTeam -Force

# Set up authentication
$Pat = "your_personal_access_token"
$OrgUrl = "https://dev.azure.com/YourOrg"
Set-VSTeamAccount -Account $OrgUrl -PersonalAccessToken $Pat
```

### Common Variables Setup

```powershell
# Define common variables for reuse
$Organization = "https://dev.azure.com/YourOrg"
$Project = "YourProject"
$Team = "YourTeam"
$Pat = $env:AZURE_DEVOPS_PAT

# Create authentication header for REST API calls
$Headers = @{
    Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat")))"
    'Content-Type' = 'application/json'
}
```

## 📋 **Project and Team Management**

### Creating and Configuring Projects

```powershell
# Create a new project
function New-AzureDevOpsProject {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [string]$Description,
        [ValidateSet("Git", "Tfvc")]
        [string]$SourceControl = "Git",
        [ValidateSet("Agile", "Basic", "Scrum", "CMMI")]
        [string]$ProcessTemplate = "Agile"
    )
    
    $body = @{
        name = $ProjectName
        description = $Description
        capabilities = @{
            versioncontrol = @{
                sourceControlType = $SourceControl
            }
            processTemplate = @{
                templateTypeId = switch ($ProcessTemplate) {
                    "Agile" { "adcc42ab-9882-485e-a3ed-7678f01f66bc" }
                    "Basic" { "b8a3a935-7e91-48b8-a94c-606d37c3e9f2" }
                    "Scrum" { "6b724908-ef14-45cf-84f8-768b5384da45" }
                    "CMMI" { "27450541-8e31-4150-9947-dc59f998fc01" }
                }
            }
        }
    } | ConvertTo-Json -Depth 5
    
    $uri = "$Organization/_apis/projects?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        Write-Host "Project '$ProjectName' created successfully!" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to create project: $($_.Exception.Message)"
    }
}

# Usage example
New-AzureDevOpsProject -ProjectName "MyNewProject" -Description "Automated project creation" -ProcessTemplate "Agile"
```

### Team Management

```powershell
# Create teams and add members
function New-TeamWithMembers {
    param(
        [string]$TeamName,
        [string[]]$MemberEmails,
        [string]$Description
    )
    
    # Create team
    az devops team create --name $TeamName --description $Description --org $Organization --project $Project
    
    # Add members to team
    foreach ($email in $MemberEmails) {
        try {
            az devops team member add --team $TeamName --user $email --org $Organization --project $Project
            Write-Host "Added $email to team $TeamName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to add $email to team: $($_.Exception.Message)"
        }
    }
}

# Bulk team creation from CSV
function Import-TeamsFromCsv {
    param([string]$CsvPath)
    
    $teams = Import-Csv $CsvPath
    foreach ($team in $teams) {
        $members = $team.Members -split ';'
        New-TeamWithMembers -TeamName $team.Name -MemberEmails $members -Description $team.Description
    }
}
```

## 📊 **Work Items and Board Automation**

### Advanced Iteration Management

```powershell
# Export iterations with complete details
function Export-ProjectIterations {
    param(
        [string]$OutputPath = "iterations.json"
    )
    
    $iterations = az boards iteration project list --org $Organization --project $Project --depth 2 | ConvertFrom-Json
    
    $exportData = $iterations.children | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.name
            StartDate = $_.attributes.startDate
            FinishDate = $_.attributes.finishDate
            Path = $_.path
            Id = $_.identifier
            Children = $_.children | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.name
                    StartDate = $_.attributes.startDate
                    FinishDate = $_.attributes.finishDate
                    Path = $_.path
                }
            }
        }
    }
    
    $exportData | ConvertTo-Json -Depth 4 | Out-File $OutputPath
    Write-Host "Iterations exported to $OutputPath" -ForegroundColor Green
}

# Create iterations from template
function New-SprintSchedule {
    param(
        [Parameter(Mandatory)]
        [datetime]$StartDate,
        [int]$SprintDuration = 14,
        [int]$NumberOfSprints = 6,
        [string]$SprintPrefix = "Sprint"
    )
    
    $currentDate = $StartDate
    
    for ($i = 1; $i -le $NumberOfSprints; $i++) {
        $sprintName = "$SprintPrefix $i"
        $endDate = $currentDate.AddDays($SprintDuration - 1)
        
        try {
            az boards iteration project create `
                --name $sprintName `
                --start-date $currentDate.ToString("yyyy-MM-dd") `
                --finish-date $endDate.ToString("yyyy-MM-dd") `
                --project $Project `
                --org $Organization `
                --path "\$Project\Iteration"
            
            Write-Host "Created $sprintName ($($currentDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd')))" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to create $sprintName: $($_.Exception.Message)"
        }
        
        $currentDate = $endDate.AddDays(1)
    }
}

# Add iterations to teams
function Add-IterationsToTeam {
    param(
        [string]$TeamName,
        [string[]]$IterationPaths
    )
    
    foreach ($path in $IterationPaths) {
        try {
            # Get iteration details
            $iteration = az boards iteration project show --path $path --org $Organization --project $Project | ConvertFrom-Json
            
            # Add to team
            az boards iteration team add --id $iteration.identifier --team $TeamName --org $Organization --project $Project
            Write-Host "Added iteration '$($iteration.name)' to team '$TeamName'" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to add iteration $path to team $TeamName: $($_.Exception.Message)"
        }
    }
}
```

### Work Item Automation

```powershell
# Bulk work item creation
function New-WorkItemFromTemplate {
    param(
        [Parameter(Mandatory)]
        [string]$WorkItemType,
        [Parameter(Mandatory)]
        [string]$Title,
        [string]$Description,
        [string]$AssignedTo,
        [string]$AreaPath,
        [string]$IterationPath,
        [hashtable]$CustomFields = @{}
    )
    
    $fields = @{
        "System.Title" = $Title
        "System.Description" = $Description
        "System.AssignedTo" = $AssignedTo
        "System.AreaPath" = $AreaPath
        "System.IterationPath" = $IterationPath
    }
    
    # Add custom fields
    foreach ($key in $CustomFields.Keys) {
        $fields[$key] = $CustomFields[$key]
    }
    
    $body = @(
        foreach ($field in $fields.GetEnumerator()) {
            if ($field.Value) {
                @{
                    op = "add"
                    path = "/fields/$($field.Key)"
                    value = $field.Value
                }
            }
        }
    ) | ConvertTo-Json -Depth 3
    
    $uri = "$Organization/$Project/_apis/wit/workitems/`$$WorkItemType" + "?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers -ContentType "application/json-patch+json"
        Write-Host "Created work item: $Title (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to create work item: $($_.Exception.Message)"
    }
}

# Bulk work item creation from CSV
function Import-WorkItemsFromCsv {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        [string]$WorkItemType = "User Story"
    )
    
    $workItems = Import-Csv $CsvPath
    $results = @()
    
    foreach ($item in $workItems) {
        $customFields = @{}
        
        # Add any additional columns as custom fields
        $item.PSObject.Properties | Where-Object { $_.Name -notin @('Title', 'Description', 'AssignedTo', 'AreaPath', 'IterationPath') } | ForEach-Object {
            if ($_.Value) {
                $customFields[$_.Name] = $_.Value
            }
        }
        
        $result = New-WorkItemFromTemplate -WorkItemType $WorkItemType -Title $item.Title -Description $item.Description -AssignedTo $item.AssignedTo -AreaPath $item.AreaPath -IterationPath $item.IterationPath -CustomFields $customFields
        $results += $result
    }
    
    Write-Host "Created $($results.Count) work items successfully!" -ForegroundColor Green
    return $results
}

# Query work items with filters
function Get-WorkItemsByQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Wiql,
        [string]$OutputFormat = "Table"
    )
    
    $body = @{ query = $Wiql } | ConvertTo-Json
    $uri = "$Organization/$Project/_apis/wit/wiql?api-version=6.0"
    
    try {
        $queryResult = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        
        if ($queryResult.workItems.Count -eq 0) {
            Write-Host "No work items found matching the query." -ForegroundColor Yellow
            return
        }
        
        # Get work item details
        $ids = ($queryResult.workItems | ForEach-Object { $_.id }) -join ','
        $detailsUri = "$Organization/$Project/_apis/wit/workitems?ids=$ids&api-version=6.0"
        $workItems = Invoke-RestMethod -Uri $detailsUri -Headers $Headers
        
        switch ($OutputFormat) {
            "Table" {
                $workItems.value | Select-Object @{n='ID';e={$_.id}}, @{n='Title';e={$_.fields.'System.Title'}}, @{n='State';e={$_.fields.'System.State'}}, @{n='Assigned To';e={$_.fields.'System.AssignedTo'.displayName}} | Format-Table -AutoSize
            }
            "Json" {
                return $workItems.value | ConvertTo-Json -Depth 3
            }
            "Object" {
                return $workItems.value
            }
        }
    }
    catch {
        Write-Error "Failed to execute query: $($_.Exception.Message)"
    }
}

# Example usage
$wiql = @"
SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo]
FROM WorkItems
WHERE [System.TeamProject] = '$Project'
AND [System.State] = 'Active'
AND [System.IterationPath] UNDER '$Project\Iteration\Sprint 1'
ORDER BY [System.Id]
"@

Get-WorkItemsByQuery -Wiql $wiql
```

## 🚀 **Pipeline Automation**

### Build Pipeline Management

```powershell
# Create build pipeline from YAML
function New-BuildPipeline {
    param(
        [Parameter(Mandatory)]
        [string]$PipelineName,
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        [Parameter(Mandatory)]
        [string]$YamlPath,
        [string]$Description,
        [string]$FolderPath = "\"
    )
    
    $body = @{
        name = $PipelineName
        description = $Description
        folder = $FolderPath
        configuration = @{
            type = "yaml"
            path = $YamlPath
            repository = @{
                id = $RepositoryName
                type = "azureReposGit"
            }
        }
    } | ConvertTo-Json -Depth 5
    
    $uri = "$Organization/$Project/_apis/build/definitions?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        Write-Host "Created build pipeline: $PipelineName (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to create build pipeline: $($_.Exception.Message)"
    }
}

# Queue build with parameters
function Start-BuildPipeline {
    param(
        [Parameter(Mandatory)]
        [int]$DefinitionId,
        [string]$SourceBranch = "refs/heads/main",
        [hashtable]$Parameters = @{}
    )
    
    $body = @{
        definition = @{ id = $DefinitionId }
        sourceBranch = $SourceBranch
    }
    
    if ($Parameters.Count -gt 0) {
        $body.parameters = ($Parameters | ConvertTo-Json -Compress)
    }
    
    $jsonBody = $body | ConvertTo-Json -Depth 3
    $uri = "$Organization/$Project/_apis/build/builds?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $jsonBody -Headers $Headers
        Write-Host "Started build: $($response.buildNumber) (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to start build: $($_.Exception.Message)"
    }
}

# Monitor build status
function Wait-ForBuildCompletion {
    param(
        [Parameter(Mandatory)]
        [int]$BuildId,
        [int]$TimeoutMinutes = 30
    )
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $uri = "$Organization/$Project/_apis/build/builds/$BuildId" + "?api-version=6.0"
    
    do {
        $build = Invoke-RestMethod -Uri $uri -Headers $Headers
        $status = $build.status
        $result = $build.result
        
        Write-Host "Build status: $status" -ForegroundColor Cyan
        
        if ($status -eq "completed") {
            if ($result -eq "succeeded") {
                Write-Host "Build completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "Build failed with result: $result" -ForegroundColor Red
            }
            return $build
        }
        
        Start-Sleep -Seconds 30
    } while ((Get-Date) -lt $timeout)
    
    Write-Warning "Build timeout reached after $TimeoutMinutes minutes"
    return $build
}
```

### Release Pipeline Automation

```powershell
# Create release pipeline
function New-ReleasePipeline {
    param(
        [Parameter(Mandatory)]
        [string]$PipelineName,
        [Parameter(Mandatory)]
        [int]$ArtifactSourceId,
        [Parameter(Mandatory)]
        [array]$Environments
    )
    
    $body = @{
        name = $PipelineName
        artifacts = @(
            @{
                type = "Build"
                alias = "BuildArtifact"
                definitionReference = @{
                    definition = @{
                        id = $ArtifactSourceId.ToString()
                        name = "Build Pipeline"
                    }
                    project = @{
                        id = $Project
                        name = $Project
                    }
                }
            }
        )
        environments = $Environments
    } | ConvertTo-Json -Depth 10
    
    $uri = "$Organization/$Project/_apis/release/definitions?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        Write-Host "Created release pipeline: $PipelineName (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to create release pipeline: $($_.Exception.Message)"
    }
}

# Trigger release
function Start-Release {
    param(
        [Parameter(Mandatory)]
        [int]$DefinitionId,
        [string]$Description = "Automated release"
    )
    
    $body = @{
        definitionId = $DefinitionId
        description = $Description
    } | ConvertTo-Json
    
    $uri = "$Organization/$Project/_apis/release/releases?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        Write-Host "Started release: $($response.name) (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to start release: $($_.Exception.Message)"
    }
}
```

## 📁 **Repository Management**

### Repository Creation and Configuration

```powershell
# Create repository with initial content
function New-Repository {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        [string]$Description,
        [switch]$InitializeWithReadme
    )
    
    $body = @{
        name = $RepositoryName
    }
    
    if ($Description) {
        $body.description = $Description
    }
    
    $jsonBody = $body | ConvertTo-Json
    $uri = "$Organization/$Project/_apis/git/repositories?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $jsonBody -Headers $Headers
        Write-Host "Created repository: $RepositoryName (ID: $($response.id))" -ForegroundColor Green
        
        if ($InitializeWithReadme) {
            Add-InitialCommit -RepositoryId $response.id -RepositoryName $RepositoryName
        }
        
        return $response
    }
    catch {
        Write-Error "Failed to create repository: $($_.Exception.Message)"
    }
}

# Add initial commit with README
function Add-InitialCommit {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryId,
        [Parameter(Mandatory)]
        [string]$RepositoryName
    )
    
    $readmeContent = @"
# $RepositoryName

This repository was created automatically.

## Getting Started

Add your project documentation here.
"@
    
    $body = @{
        refUpdates = @(
            @{
                name = "refs/heads/main"
                oldObjectId = "0000000000000000000000000000000000000000"
            }
        )
        commits = @(
            @{
                comment = "Initial commit"
                changes = @(
                    @{
                        changeType = "add"
                        item = @{
                            path = "/README.md"
                        }
                        newContent = @{
                            content = $readmeContent
                            contentType = "rawtext"
                        }
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $uri = "$Organization/$Project/_apis/git/repositories/$RepositoryId/pushes?api-version=6.0"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers
        Write-Host "Added initial commit to repository" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Error "Failed to add initial commit: $($_.Exception.Message)"
    }
}

# Set up branch policies
function Set-BranchPolicy {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryId,
        [string]$BranchName = "main",
        [bool]$RequirePullRequest = $true,
        [int]$MinimumApprovers = 1,
        [bool]$ResetApprovalOnNewPush = $true,
        [bool]$RequireBuildValidation = $true,
        [int]$BuildDefinitionId
    )
    
    # Minimum approver policy
    if ($RequirePullRequest) {
        $approverPolicy = @{
            isEnabled = $true
            isBlocking = $true
            type = @{
                id = "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"
            }
            settings = @{
                minimumApproverCount = $MinimumApprovers
                creatorVoteCounts = $false
                allowDownvotes = $false
                resetOnSourcePush = $ResetApprovalOnNewPush
                scope = @(
                    @{
                        repositoryId = $RepositoryId
                        refName = "refs/heads/$BranchName"
                        matchKind = "exact"
                    }
                )
            }
        } | ConvertTo-Json -Depth 10
        
        $uri = "$Organization/$Project/_apis/policy/configurations?api-version=6.0"
        Invoke-RestMethod -Uri $uri -Method Post -Body $approverPolicy -Headers $Headers | Out-Null
    }
    
    # Build validation policy
    if ($RequireBuildValidation -and $BuildDefinitionId) {
        $buildPolicy = @{
            isEnabled = $true
            isBlocking = $true
            type = @{
                id = "0609b952-1397-4640-95ec-e00a01b2c241"
            }
            settings = @{
                buildDefinitionId = $BuildDefinitionId
                displayName = "Build Validation"
                scope = @(
                    @{
                        repositoryId = $RepositoryId
                        refName = "refs/heads/$BranchName"
                        matchKind = "exact"
                    }
                )
            }
        } | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Uri $uri -Method Post -Body $buildPolicy -Headers $Headers | Out-Null
    }
    
    Write-Host "Branch policies configured for $BranchName" -ForegroundColor Green
}
```

## 📊 **Reporting and Analytics**

### Build and Deployment Analytics

```powershell
# Generate build success rate report
function Get-BuildSuccessRate {
    param(
        [int]$DaysBack = 30,
        [int]$DefinitionId
    )
    
    $fromDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-dd")
    $uri = "$Organization/$Project/_apis/build/builds?api-version=6.0&minTime=$fromDate"
    
    if ($DefinitionId) {
        $uri += "&definitions=$DefinitionId"
    }
    
    $builds = Invoke-RestMethod -Uri $uri -Headers $Headers
    
    $report = $builds.value | Group-Object result | ForEach-Object {
        [PSCustomObject]@{
            Result = $_.Name
            Count = $_.Count
            Percentage = [math]::Round(($_.Count / $builds.value.Count) * 100, 2)
        }
    }
    
    Write-Host "Build Success Rate Report (Last $DaysBack days):" -ForegroundColor Cyan
    $report | Format-Table -AutoSize
    
    return $report
}

# Generate work item velocity report
function Get-TeamVelocity {
    param(
        [string]$TeamName,
        [int]$NumberOfSprints = 6
    )
    
    # Get team iterations
    $iterations = az boards iteration team list --team $TeamName --timeframe current --org $Organization --project $Project | ConvertFrom-Json
    
    $velocityData = @()
    
    foreach ($iteration in $iterations | Select-Object -First $NumberOfSprints) {
        $wiql = @"
SELECT [System.Id], [Microsoft.VSTS.Scheduling.StoryPoints]
FROM WorkItems
WHERE [System.TeamProject] = '$Project'
AND [System.IterationPath] = '$($iteration.path)'
AND [System.WorkItemType] IN ('User Story', 'Bug')
AND [System.State] = 'Done'
"@
        
        $workItems = Get-WorkItemsByQuery -Wiql $wiql -OutputFormat "Object"
        $storyPoints = ($workItems | ForEach-Object { [int]($_.fields.'Microsoft.VSTS.Scheduling.StoryPoints' -replace '[^\d]', '') } | Measure-Object -Sum).Sum
        
        $velocityData += [PSCustomObject]@{
            Iteration = $iteration.name
            StoryPoints = $storyPoints
            StartDate = $iteration.attributes.startDate
            EndDate = $iteration.attributes.finishDate
        }
    }
    
    Write-Host "Team Velocity Report for $TeamName:" -ForegroundColor Cyan
    $velocityData | Format-Table -AutoSize
    
    $averageVelocity = ($velocityData.StoryPoints | Measure-Object -Average).Average
    Write-Host "Average Velocity: $([math]::Round($averageVelocity, 2)) story points" -ForegroundColor Green
    
    return $velocityData
}
```

## 🔧 **Utility Functions**

### Bulk Export and Import

```powershell
# Export complete project configuration
function Export-ProjectConfiguration {
    param(
        [string]$OutputDirectory = ".\ProjectExport"
    )
    
    if (!(Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force
    }
    
    # Export teams
    $teams = az devops team list --org $Organization --project $Project | ConvertFrom-Json
    $teams | ConvertTo-Json -Depth 3 | Out-File "$OutputDirectory\teams.json"
    
    # Export iterations
    Export-ProjectIterations -OutputPath "$OutputDirectory\iterations.json"
    
    # Export repositories
    $repos = az repos list --org $Organization --project $Project | ConvertFrom-Json
    $repos | ConvertTo-Json -Depth 3 | Out-File "$OutputDirectory\repositories.json"
    
    # Export build definitions
    $builds = az pipelines list --org $Organization --project $Project | ConvertFrom-Json
    $builds | ConvertTo-Json -Depth 3 | Out-File "$OutputDirectory\build-pipelines.json"
    
    Write-Host "Project configuration exported to $OutputDirectory" -ForegroundColor Green
}

# Backup work items
function Backup-WorkItems {
    param(
        [string]$OutputPath = "workitems-backup.json",
        [string]$AreaPath,
        [string]$IterationPath
    )
    
    $wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$Project'"
    
    if ($AreaPath) {
        $wiql += " AND [System.AreaPath] UNDER '$AreaPath'"
    }
    
    if ($IterationPath) {
        $wiql += " AND [System.IterationPath] UNDER '$IterationPath'"
    }
    
    $workItems = Get-WorkItemsByQuery -Wiql $wiql -OutputFormat "Object"
    
    $backup = @{
        ExportDate = Get-Date
        Project = $Project
        WorkItemCount = $workItems.Count
        WorkItems = $workItems
    }
    
    $backup | ConvertTo-Json -Depth 10 | Out-File $OutputPath
    Write-Host "Backed up $($workItems.Count) work items to $OutputPath" -ForegroundColor Green
}
```

## 🔐 **Security and Permissions**

### Permission Management

```powershell
# Set repository permissions
function Set-RepositoryPermissions {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryId,
        [Parameter(Mandatory)]
        [string]$GroupName,
        [hashtable]$Permissions
    )
    
    # Get security namespace for Git repositories
    $namespace = "2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87"
    
    # Set permissions
    foreach ($permission in $Permissions.GetEnumerator()) {
        $body = @{
            token = "repoV2/$Project/$RepositoryId"
            merge = $true
            accessControlEntries = @(
                @{
                    descriptor = $GroupName
                    allow = if ($permission.Value) { $permission.Key } else { 0 }
                    deny = if (!$permission.Value) { $permission.Key } else { 0 }
                }
            )
        } | ConvertTo-Json -Depth 5
        
        $uri = "$Organization/_apis/accesscontrollists/$namespace" + "?api-version=6.0"
        
        try {
            Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $Headers | Out-Null
            Write-Host "Set permission $($permission.Key) = $($permission.Value) for $GroupName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to set permission: $($_.Exception.Message)"
        }
    }
}
```

## 📚 **Best Practices and Tips**

### Error Handling and Logging

```powershell
# Enhanced error handling function
function Invoke-AzureDevOpsOperation {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        [string]$OperationName,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 5
    )
    
    $attempt = 1
    
    do {
        try {
            Write-Host "Executing: $OperationName (Attempt $attempt)" -ForegroundColor Cyan
            $result = & $Operation
            Write-Host "✓ $OperationName completed successfully" -ForegroundColor Green
            return $result
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "✗ $OperationName failed (Attempt $attempt): $errorMessage"
            
            if ($attempt -eq $MaxRetries) {
                Write-Error "Operation failed after $MaxRetries attempts: $OperationName"
                throw
            }
            
            Write-Host "Retrying in $RetryDelay seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryDelay
            $attempt++
        }
    } while ($attempt -le $MaxRetries)
}

# Usage example
$result = Invoke-AzureDevOpsOperation -Operation {
    New-AzureDevOpsProject -ProjectName "TestProject" -Description "Test project creation"
} -OperationName "Create Test Project" -MaxRetries 3
```

### Performance Optimization

```powershell
# Parallel operations for bulk tasks
function Invoke-ParallelOperations {
    param(
        [Parameter(Mandatory)]
        [array]$Items,
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        [int]$ThrottleLimit = 10
    )
    
    $Items | ForEach-Object -Parallel $Operation -ThrottleLimit $ThrottleLimit
}

# Example: Create multiple work items in parallel
$workItemData = @(
    @{ Title = "Item 1"; Type = "Task" }
    @{ Title = "Item 2"; Type = "Task" }
    @{ Title = "Item 3"; Type = "Task" }
)

Invoke-ParallelOperations -Items $workItemData -Operation {
    $item = $_
    New-WorkItemFromTemplate -WorkItemType $item.Type -Title $item.Title -Description "Auto-created task"
} -ThrottleLimit 5
```

---

## 📖 **Additional Resources**

- [Azure DevOps CLI Reference](https://docs.microsoft.com/en-us/azure/devops/cli/)
- [Azure DevOps REST API Documentation](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [PowerShell for Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/integrate/concepts/dotnet-client-libraries)
- [VSTeam PowerShell Module](https://github.com/DarqueWarrior/vsteam)

[Back to Azure DevOps Getting Started](getting-started.md) | [Back to Development Home](../index.md)
