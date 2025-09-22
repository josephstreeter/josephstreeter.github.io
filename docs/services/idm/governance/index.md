---
title: Identity Governance
description: Comprehensive guide to Identity Governance and Administration (IGA) covering access management, compliance, and automated identity lifecycle management
author: Joseph Streeter
date: 2024-01-15
tags: [identity-governance, iga, access-management, compliance, security, automation]
---

Identity Governance and Administration (IGA) is a framework that provides organizations with the ability to manage user identities, enforce access policies, ensure compliance, and reduce security risks through automated identity lifecycle management.

## 🎯 Identity Governance Framework

### Core Principles

#### Identity Lifecycle Management

- Automated provisioning and deprovisioning
- Role-based access control (RBAC)
- Attribute-based access control (ABAC)
- Just-in-time (JIT) access provisioning

#### Access Governance

- Access certification and reviews
- Segregation of duties (SoD) enforcement
- Privileged access management (PAM)
- Risk-based access decisions

#### Compliance and Audit

- Regulatory compliance reporting
- Access audit trails
- Policy violation detection
- Continuous compliance monitoring

## 🏗️ Microsoft Identity Governance Architecture

### Entra ID Governance

```powershell
<#
.SYNOPSIS
    Microsoft Entra ID Governance management and automation
.DESCRIPTION
    Comprehensive functions for managing Entra ID Governance features including
    access reviews, entitlement management, and privileged identity management
#>

function New-AccessReviewCampaign
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CampaignName,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Groups", "Applications", "Roles", "Teams")]
        [string]$ReviewType,
        
        [Parameter()]
        [int]$DurationInDays = 14,
        
        [Parameter()]
        [string[]]$Reviewers = @(),
        
        [Parameter()]
        [ValidateSet("Weekly", "Monthly", "Quarterly", "SemiAnnually", "Annually")]
        [string]$Frequency = "Quarterly",
        
        [Parameter()]
        [switch]$AutoApplyRecommendations,
        
        [Parameter()]
        [switch]$RemoveAccessOnNonResponse
    )
    
    try
    {
        Write-Host "Creating Access Review Campaign: $CampaignName" -ForegroundColor Green
        
        # Connect to Microsoft Graph if not already connected
        try
        {
            $Context = Get-MgContext
            if (-not $Context)
            {
                Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
                Connect-MgGraph -Scopes "AccessReview.ReadWrite.All", "Directory.Read.All"
            }
        }
        catch
        {
            throw "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
        
        # Build access review configuration
        $ReviewConfig = @{
            displayName = $CampaignName
            descriptionForAdmins = $Description
            descriptionForReviewers = "Please review access and confirm if users still require access"
            scope = @{}
            reviewers = @()
            settings = @{
                mailNotificationsEnabled = $true
                reminderNotificationsEnabled = $true
                defaultDecision = "None"
                defaultDecisionEnabled = $false
                instanceDurationInDays = $DurationInDays
                autoApplyDecisionsEnabled = $AutoApplyRecommendations.IsPresent
                recommendationsEnabled = $true
                justificationRequiredOnApproval = $true
                applyActions = @()
            }
            recurrence = @{
                pattern = @{
                    type = switch ($Frequency) {
                        "Weekly" { "weekly" }
                        "Monthly" { "absoluteMonthly" }
                        "Quarterly" { "absoluteMonthly" }
                        "SemiAnnually" { "absoluteMonthly" }
                        "Annually" { "absoluteYearly" }
                    }
                    interval = switch ($Frequency) {
                        "Weekly" { 1 }
                        "Monthly" { 1 }
                        "Quarterly" { 3 }
                        "SemiAnnually" { 6 }
                        "Annually" { 1 }
                    }
                }
                range = @{
                    type = "noEnd"
                    startDate = (Get-Date).ToString("yyyy-MM-dd")
                }
            }
        }
        
        # Configure scope based on review type
        switch ($ReviewType)
        {
            "Groups" {
                $ReviewConfig.scope = @{
                    '@odata.type' = "#microsoft.graph.accessReviewQueryScope"
                    query = "/groups?$filter=(groupTypes/any(c:c eq 'Unified') or securityEnabled eq true)"
                    queryType = "MicrosoftGraph"
                }
            }
            "Applications" {
                $ReviewConfig.scope = @{
                    '@odata.type' = "#microsoft.graph.accessReviewQueryScope"
                    query = "/servicePrincipals"
                    queryType = "MicrosoftGraph"
                }
            }
            "Roles" {
                $ReviewConfig.scope = @{
                    '@odata.type' = "#microsoft.graph.accessReviewQueryScope"
                    query = "/roleManagement/directory/roleAssignments"
                    queryType = "MicrosoftGraph"
                }
            }
            "Teams" {
                $ReviewConfig.scope = @{
                    '@odata.type' = "#microsoft.graph.accessReviewQueryScope"
                    query = "/groups?$filter=resourceProvisioningOptions/Any(x:x eq 'Team')"
                    queryType = "MicrosoftGraph"
                }
            }
        }
        
        # Configure reviewers
        if ($Reviewers.Count -gt 0)
        {
            $ReviewConfig.reviewers = $Reviewers | ForEach-Object {
                @{
                    query = "/users/$_"
                    queryType = "MicrosoftGraph"
                }
            }
        }
        else
        {
            # Default to resource owners as reviewers
            $ReviewConfig.reviewers = @(
                @{
                    query = "./manager"
                    queryType = "MicrosoftGraph"
                    queryRoot = "decisions"
                }
            )
        }
        
        # Configure automatic actions
        if ($RemoveAccessOnNonResponse)
        {
            $ReviewConfig.settings.applyActions += @{
                '@odata.type' = "#microsoft.graph.removeAccessApplyAction"
            }
        }
        
        # Create the access review
        $AccessReview = New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $ReviewConfig
        
        Write-Host "✓ Access Review Campaign created successfully" -ForegroundColor Green
        Write-Host "  Campaign ID: $($AccessReview.Id)" -ForegroundColor Cyan
        Write-Host "  Review Type: $ReviewType" -ForegroundColor Cyan
        Write-Host "  Duration: $DurationInDays days" -ForegroundColor Cyan
        Write-Host "  Frequency: $Frequency" -ForegroundColor Cyan
        
        return [PSCustomObject]@{
            CampaignId = $AccessReview.Id
            CampaignName = $CampaignName
            ReviewType = $ReviewType
            Status = "Created"
            NextReviewDate = $AccessReview.Instances[0].StartDateTime
            Configuration = $ReviewConfig
        }
    }
    catch
    {
        Write-Error "Failed to create access review campaign: $($_.Exception.Message)"
        throw
    }
}

function Get-AccessReviewStatus
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$CampaignId,
        
        [Parameter()]
        [switch]$IncludeDecisions,
        
        [Parameter()]
        [switch]$ShowMetrics
    )
    
    try
    {
        Write-Host "Retrieving access review status..." -ForegroundColor Green
        
        # Get all access review definitions if no specific campaign ID provided
        if (-not $CampaignId)
        {
            $AccessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -All
            
            $ReviewSummary = $AccessReviews | ForEach-Object {
                $Review = $_
                $Instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $Review.Id
                
                [PSCustomObject]@{
                    CampaignId = $Review.Id
                    CampaignName = $Review.DisplayName
                    Status = $Review.Status
                    ReviewType = $Review.Scope.'@odata.type'
                    ActiveInstances = ($Instances | Where-Object Status -eq "InProgress").Count
                    CompletedInstances = ($Instances | Where-Object Status -eq "Completed").Count
                    NextReviewDate = ($Instances | Where-Object Status -eq "NotStarted" | Sort-Object StartDateTime | Select-Object -First 1).StartDateTime
                }
            }
            
            Write-Host "Access Review Campaigns Summary:" -ForegroundColor Cyan
            $ReviewSummary | Format-Table -AutoSize
            
            return $ReviewSummary
        }
        
        # Get specific campaign details
        $Campaign = Get-MgIdentityGovernanceAccessReviewDefinition -AccessReviewScheduleDefinitionId $CampaignId
        $Instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $CampaignId
        
        $CampaignStatus = [PSCustomObject]@{
            CampaignId = $Campaign.Id
            CampaignName = $Campaign.DisplayName
            Description = $Campaign.DescriptionForAdmins
            Status = $Campaign.Status
            CreatedDate = $Campaign.CreatedDateTime
            LastModified = $Campaign.LastModifiedDateTime
            TotalInstances = $Instances.Count
            ActiveInstances = ($Instances | Where-Object Status -eq "InProgress").Count
            CompletedInstances = ($Instances | Where-Object Status -eq "Completed").Count
            PendingInstances = ($Instances | Where-Object Status -eq "NotStarted").Count
        }
        
        Write-Host "Campaign Status:" -ForegroundColor Cyan
        $CampaignStatus | Format-List
        
        if ($ShowMetrics)
        {
            Write-Host "Campaign Metrics:" -ForegroundColor Yellow
            
            foreach ($Instance in $Instances | Where-Object Status -eq "Completed")
            {
                $Decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $CampaignId -AccessReviewInstanceId $Instance.Id
                
                $InstanceMetrics = [PSCustomObject]@{
                    InstanceId = $Instance.Id
                    ReviewPeriod = "$($Instance.StartDateTime) to $($Instance.EndDateTime)"
                    TotalDecisions = $Decisions.Count
                    ApprovedCount = ($Decisions | Where-Object Decision -eq "Approve").Count
                    DeniedCount = ($Decisions | Where-Object Decision -eq "Deny").Count
                    NotReviewedCount = ($Decisions | Where-Object Decision -eq "NotReviewed").Count
                    CompletionRate = [math]::Round((($Decisions | Where-Object {$_.Decision -ne "NotReviewed"}).Count / $Decisions.Count) * 100, 2)
                }
                
                $InstanceMetrics | Format-List
            }
        }
        
        if ($IncludeDecisions)
        {
            Write-Host "Recent Decisions:" -ForegroundColor Yellow
            
            $LatestInstance = $Instances | Sort-Object StartDateTime -Descending | Select-Object -First 1
            if ($LatestInstance)
            {
                $RecentDecisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $CampaignId -AccessReviewInstanceId $LatestInstance.Id | Select-Object -First 20
                
                $RecentDecisions | ForEach-Object {
                    [PSCustomObject]@{
                        ResourceName = $_.Resource.DisplayName
                        PrincipalName = $_.Principal.DisplayName
                        Decision = $_.Decision
                        Justification = $_.Justification
                        ReviewedBy = $_.ReviewedBy.DisplayName
                        ReviewedDate = $_.ReviewedDateTime
                    }
                } | Format-Table -AutoSize
            }
        }
        
        return $CampaignStatus
    }
    catch
    {
        Write-Error "Failed to retrieve access review status: $($_.Exception.Message)"
        throw
    }
}
```

### Entitlement Management

```powershell
function New-AccessPackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$CatalogId,
        
        [Parameter()]
        [string[]]$ResourceRoles = @(),
        
        [Parameter()]
        [hashtable]$RequestorSettings = @{},
        
        [Parameter()]
        [hashtable]$ApprovalSettings = @{},
        
        [Parameter()]
        [int]$AccessDurationDays = 90
    )
    
    try
    {
        Write-Host "Creating Access Package: $PackageName" -ForegroundColor Green
        
        # Build access package configuration
        $AccessPackageConfig = @{
            displayName = $PackageName
            description = $Description
            catalogId = $CatalogId
            isHidden = $false
            accessPackageResourceRoleScopes = @()
        }
        
        # Add resource roles if specified
        foreach ($ResourceRole in $ResourceRoles)
        {
            # This would need to be expanded based on specific resource types
            $AccessPackageConfig.accessPackageResourceRoleScopes += @{
                accessPackageResourceRole = @{
                    id = $ResourceRole
                }
                accessPackageResourceScope = @{
                    id = "root"
                }
            }
        }
        
        # Create the access package
        $AccessPackage = New-MgEntitlementManagementAccessPackage -BodyParameter $AccessPackageConfig
        
        # Create assignment policy
        $PolicyConfig = @{
            displayName = "$PackageName - Default Policy"
            description = "Default assignment policy for $PackageName"
            accessPackageId = $AccessPackage.Id
            expiration = @{
                endDateTime = $null
                duration = "P$($AccessDurationDays)D"
                type = "afterDuration"
            }
            requestorSettings = @{
                scopeType = "AllExistingDirectoryMemberUsers"
                acceptRequests = $true
                allowedRequestors = @()
            }
            requestApprovalSettings = @{
                isApprovalRequired = $true
                isApprovalRequiredForExtension = $false
                isRequestorJustificationRequired = $true
                approvalMode = "SingleStage"
                approvalStages = @(
                    @{
                        approvalStageTimeOutInDays = 14
                        isApproverJustificationRequired = $true
                        isEscalationEnabled = $false
                        primaryApprovers = @()
                    }
                )
            }
        }
        
        # Apply custom settings if provided
        if ($RequestorSettings.Count -gt 0)
        {
            $PolicyConfig.requestorSettings = $RequestorSettings
        }
        
        if ($ApprovalSettings.Count -gt 0)
        {
            $PolicyConfig.requestApprovalSettings = $ApprovalSettings
        }
        
        $AssignmentPolicy = New-MgEntitlementManagementAccessPackageAssignmentPolicy -BodyParameter $PolicyConfig
        
        Write-Host "✓ Access Package created successfully" -ForegroundColor Green
        Write-Host "  Package ID: $($AccessPackage.Id)" -ForegroundColor Cyan
        Write-Host "  Policy ID: $($AssignmentPolicy.Id)" -ForegroundColor Cyan
        Write-Host "  Access Duration: $AccessDurationDays days" -ForegroundColor Cyan
        
        return [PSCustomObject]@{
            AccessPackageId = $AccessPackage.Id
            PackageName = $PackageName
            CatalogId = $CatalogId
            PolicyId = $AssignmentPolicy.Id
            Status = "Created"
        }
    }
    catch
    {
        Write-Error "Failed to create access package: $($_.Exception.Message)"
        throw
    }
}

function Get-AccessPackageRequests
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AccessPackageId,
        
        [Parameter()]
        [ValidateSet("Pending", "Approved", "Denied", "Delivered", "All")]
        [string]$Status = "All",
        
        [Parameter()]
        [int]$DaysBack = 30
    )
    
    try
    {
        Write-Host "Retrieving access package requests..." -ForegroundColor Green
        
        $StartDate = (Get-Date).AddDays(-$DaysBack)
        
        # Get all assignment requests
        $AllRequests = Get-MgEntitlementManagementAccessPackageAssignmentRequest -All
        
        # Filter by access package if specified
        if ($AccessPackageId)
        {
            $AllRequests = $AllRequests | Where-Object { $_.AccessPackage.Id -eq $AccessPackageId }
        }
        
        # Filter by date range
        $AllRequests = $AllRequests | Where-Object { [DateTime]$_.CreatedDateTime -ge $StartDate }
        
        # Filter by status if not "All"
        if ($Status -ne "All")
        {
            $AllRequests = $AllRequests | Where-Object { $_.State -eq $Status }
        }
        
        $RequestSummary = $AllRequests | ForEach-Object {
            [PSCustomObject]@{
                RequestId = $_.Id
                RequestedBy = $_.Requestor.DisplayName
                RequestedByUPN = $_.Requestor.UserPrincipalName
                AccessPackage = $_.AccessPackage.DisplayName
                RequestType = $_.RequestType
                Status = $_.State
                RequestDate = $_.CreatedDateTime
                CompletedDate = $_.CompletedDateTime
                Justification = $_.Answers | Where-Object { $_.DisplayValue } | Select-Object -First 1 -ExpandProperty DisplayValue
            }
        }
        
        Write-Host "Access Package Requests Summary:" -ForegroundColor Cyan
        Write-Host "Total Requests: $($RequestSummary.Count)" -ForegroundColor White
        
        if ($Status -eq "All")
        {
            $StatusGroups = $RequestSummary | Group-Object Status
            $StatusGroups | ForEach-Object {
                Write-Host "$($_.Name): $($_.Count)" -ForegroundColor Yellow
            }
        }
        
        $RequestSummary | Format-Table -AutoSize
        
        return $RequestSummary
    }
    catch
    {
        Write-Error "Failed to retrieve access package requests: $($_.Exception.Message)"
        throw
    }
}
```

## 🔒 Privileged Identity Management (PIM)

### PIM Role Management

```powershell
function Enable-PIMRole
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RoleName,
        
        [Parameter(Mandatory = $true)]
        [string]$PrincipalId,
        
        [Parameter()]
        [int]$DurationHours = 8,
        
        [Parameter(Mandatory = $true)]
        [string]$Justification,
        
        [Parameter()]
        [string]$TicketNumber
    )
    
    try
    {
        Write-Host "Activating PIM role: $RoleName for $PrincipalId" -ForegroundColor Green
        
        # Get role definition
        $RoleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$RoleName'"
        
        if (-not $RoleDefinition)
        {
            throw "Role '$RoleName' not found"
        }
        
        # Create activation request
        $ActivationRequest = @{
            action = "selfActivate"
            principalId = $PrincipalId
            roleDefinitionId = $RoleDefinition.Id
            directoryScopeId = "/"
            justification = $Justification
            scheduleInfo = @{
                startDateTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                expiration = @{
                    type = "afterDuration"
                    duration = "PT$($DurationHours)H"
                }
            }
        }
        
        # Add ticket number to justification if provided
        if ($TicketNumber)
        {
            $ActivationRequest.justification += " (Ticket: $TicketNumber)"
        }
        
        $RoleAssignmentRequest = New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $ActivationRequest
        
        Write-Host "✓ PIM role activation requested" -ForegroundColor Green
        Write-Host "  Request ID: $($RoleAssignmentRequest.Id)" -ForegroundColor Cyan
        Write-Host "  Role: $RoleName" -ForegroundColor Cyan
        Write-Host "  Duration: $DurationHours hours" -ForegroundColor Cyan
        Write-Host "  Status: $($RoleAssignmentRequest.Status)" -ForegroundColor Cyan
        
        return [PSCustomObject]@{
            RequestId = $RoleAssignmentRequest.Id
            RoleName = $RoleName
            PrincipalId = $PrincipalId
            Duration = $DurationHours
            Status = $RoleAssignmentRequest.Status
            RequestedAt = Get-Date
        }
    }
    catch
    {
        Write-Error "Failed to activate PIM role: $($_.Exception.Message)"
        throw
    }
}

function Get-PIMRoleAssignments
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PrincipalId,
        
        [Parameter()]
        [ValidateSet("Active", "Eligible", "All")]
        [string]$AssignmentType = "All",
        
        [Parameter()]
        [switch]$IncludeExpiredAssignments
    )
    
    try
    {
        Write-Host "Retrieving PIM role assignments..." -ForegroundColor Green
        
        # Get role assignments
        if ($AssignmentType -eq "All" -or $AssignmentType -eq "Active")
        {
            $ActiveAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All
            
            if ($PrincipalId)
            {
                $ActiveAssignments = $ActiveAssignments | Where-Object PrincipalId -eq $PrincipalId
            }
            
            $ActiveResults = $ActiveAssignments | ForEach-Object {
                $RoleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_.RoleDefinitionId
                
                [PSCustomObject]@{
                    AssignmentType = "Active"
                    RoleName = $RoleDefinition.DisplayName
                    PrincipalId = $_.PrincipalId
                    StartDateTime = $_.StartDateTime
                    EndDateTime = $_.EndDateTime
                    AssignmentId = $_.Id
                    Status = if ($_.EndDateTime -and [DateTime]$_.EndDateTime -lt (Get-Date)) { "Expired" } else { "Active" }
                }
            }
        }
        
        if ($AssignmentType -eq "All" -or $AssignmentType -eq "Eligible")
        {
            $EligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All
            
            if ($PrincipalId)
            {
                $EligibleAssignments = $EligibleAssignments | Where-Object PrincipalId -eq $PrincipalId
            }
            
            $EligibleResults = $EligibleAssignments | ForEach-Object {
                $RoleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_.RoleDefinitionId
                
                [PSCustomObject]@{
                    AssignmentType = "Eligible"
                    RoleName = $RoleDefinition.DisplayName
                    PrincipalId = $_.PrincipalId
                    StartDateTime = $_.StartDateTime
                    EndDateTime = $_.EndDateTime
                    AssignmentId = $_.Id
                    Status = if ($_.EndDateTime -and [DateTime]$_.EndDateTime -lt (Get-Date)) { "Expired" } else { "Eligible" }
                }
            }
        }
        
        # Combine results
        $AllAssignments = @()
        if ($ActiveResults) { $AllAssignments += $ActiveResults }
        if ($EligibleResults) { $AllAssignments += $EligibleResults }
        
        # Filter expired assignments if not requested
        if (-not $IncludeExpiredAssignments)
        {
            $AllAssignments = $AllAssignments | Where-Object Status -ne "Expired"
        }
        
        Write-Host "PIM Role Assignments Summary:" -ForegroundColor Cyan
        $AssignmentGroups = $AllAssignments | Group-Object AssignmentType
        $AssignmentGroups | ForEach-Object {
            Write-Host "$($_.Name): $($_.Count)" -ForegroundColor Yellow
        }
        
        $AllAssignments | Sort-Object RoleName, AssignmentType | Format-Table -AutoSize
        
        return $AllAssignments
    }
    catch
    {
        Write-Error "Failed to retrieve PIM role assignments: $($_.Exception.Message)"
        throw
    }
}
```

## 📊 Compliance and Reporting

### Identity Compliance Dashboard

```powershell
function Get-IdentityComplianceDashboard
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$DaysBack = 30,
        
        [Parameter()]
        [switch]$IncludeDetails,
        
        [Parameter()]
        [string]$ExportPath
    )
    
    try
    {
        Write-Host "Generating Identity Compliance Dashboard..." -ForegroundColor Green
        
        $ComplianceData = [PSCustomObject]@{
            GeneratedDate = Get-Date
            ReportingPeriod = "$DaysBack days"
            UserAccounts = @{}
            PrivilegedAccounts = @{}
            AccessReviews = @{}
            AccessPackages = @{}
            PIMActivations = @{}
            ComplianceScore = 0
            RiskFactors = @()
            Recommendations = @()
        }
        
        # User account statistics
        Write-Host "Analyzing user accounts..." -ForegroundColor Cyan
        
        $AllUsers = Get-MgUser -All -Property "signInActivity,createdDateTime,accountEnabled,lastPasswordChangeDateTime,userPrincipalName,displayName"
        
        $ComplianceData.UserAccounts = @{
            Total = $AllUsers.Count
            Enabled = ($AllUsers | Where-Object AccountEnabled -eq $true).Count
            Disabled = ($AllUsers | Where-Object AccountEnabled -eq $false).Count
            RecentlyCreated = ($AllUsers | Where-Object { [DateTime]$_.CreatedDateTime -ge (Get-Date).AddDays(-$DaysBack) }).Count
            InactiveUsers = ($AllUsers | Where-Object { 
                $_.SignInActivity.LastSignInDateTime -and 
                [DateTime]$_.SignInActivity.LastSignInDateTime -lt (Get-Date).AddDays(-90) 
            }).Count
            NeverSignedIn = ($AllUsers | Where-Object { -not $_.SignInActivity.LastSignInDateTime }).Count
        }
        
        # Privileged account analysis
        Write-Host "Analyzing privileged accounts..." -ForegroundColor Cyan
        
        $PrivilegedRoles = @(
            "Global Administrator",
            "Privileged Role Administrator", 
            "User Administrator",
            "Security Administrator",
            "Exchange Administrator"
        )
        
        $PrivilegedAssignments = @()
        foreach ($Role in $PrivilegedRoles)
        {
            $RoleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$Role'"
            if ($RoleDefinition)
            {
                $Assignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter "roleDefinitionId eq '$($RoleDefinition.Id)'"
                $PrivilegedAssignments += $Assignments | ForEach-Object {
                    [PSCustomObject]@{
                        RoleName = $Role
                        PrincipalId = $_.PrincipalId
                        AssignmentType = "Active"
                        StartDateTime = $_.StartDateTime
                        EndDateTime = $_.EndDateTime
                    }
                }
            }
        }
        
        $ComplianceData.PrivilegedAccounts = @{
            TotalPrivilegedUsers = ($PrivilegedAssignments | Select-Object -Unique PrincipalId).Count
            RoleAssignments = $PrivilegedAssignments.Count
            RoleDistribution = $PrivilegedAssignments | Group-Object RoleName | ForEach-Object {
                [PSCustomObject]@{
                    RoleName = $_.Name
                    AssignmentCount = $_.Count
                }
            }
        }
        
        # Access review analysis
        Write-Host "Analyzing access reviews..." -ForegroundColor Cyan
        
        try
        {
            $AccessReviewDefinitions = Get-MgIdentityGovernanceAccessReviewDefinition -All
            $RecentReviews = @()
            
            foreach ($Review in $AccessReviewDefinitions)
            {
                $Instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $Review.Id
                $RecentInstances = $Instances | Where-Object { 
                    [DateTime]$_.StartDateTime -ge (Get-Date).AddDays(-$DaysBack) 
                }
                
                foreach ($Instance in $RecentInstances)
                {
                    $Decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $Review.Id -AccessReviewInstanceId $Instance.Id
                    
                    $RecentReviews += [PSCustomObject]@{
                        ReviewName = $Review.DisplayName
                        InstanceId = $Instance.Id
                        Status = $Instance.Status
                        StartDate = $Instance.StartDateTime
                        EndDate = $Instance.EndDateTime
                        TotalDecisions = $Decisions.Count
                        CompletedDecisions = ($Decisions | Where-Object Decision -ne "NotReviewed").Count
                        ApprovedCount = ($Decisions | Where-Object Decision -eq "Approve").Count
                        DeniedCount = ($Decisions | Where-Object Decision -eq "Deny").Count
                    }
                }
            }
            
            $ComplianceData.AccessReviews = @{
                ActiveCampaigns = $AccessReviewDefinitions.Count
                RecentReviews = $RecentReviews.Count
                CompletionRate = if ($RecentReviews.Count -gt 0) {
                    [math]::Round((($RecentReviews | Where-Object Status -eq "Completed").Count / $RecentReviews.Count) * 100, 2)
                } else { 0 }
                DecisionStats = if ($RecentReviews.Count -gt 0) {
                    @{
                        TotalDecisions = ($RecentReviews | Measure-Object TotalDecisions -Sum).Sum
                        CompletedDecisions = ($RecentReviews | Measure-Object CompletedDecisions -Sum).Sum
                        ApprovedCount = ($RecentReviews | Measure-Object ApprovedCount -Sum).Sum
                        DeniedCount = ($RecentReviews | Measure-Object DeniedCount -Sum).Sum
                    }
                } else {
                    @{
                        TotalDecisions = 0
                        CompletedDecisions = 0
                        ApprovedCount = 0
                        DeniedCount = 0
                    }
                }
            }
        }
        catch
        {
            $ComplianceData.AccessReviews = @{ Error = "Unable to retrieve access review data" }
        }
        
        # Calculate compliance score
        $ScoreFactors = @{
            InactiveUserRatio = if ($ComplianceData.UserAccounts.Total -gt 0) { 
                1 - ($ComplianceData.UserAccounts.InactiveUsers / $ComplianceData.UserAccounts.Total) 
            } else { 1 }
            AccessReviewCompletion = $ComplianceData.AccessReviews.CompletionRate / 100
            PrivilegedAccountRatio = if ($ComplianceData.UserAccounts.Enabled -gt 0) {
                1 - ([math]::Min($ComplianceData.PrivilegedAccounts.TotalPrivilegedUsers / $ComplianceData.UserAccounts.Enabled, 0.1) / 0.1)
            } else { 1 }
        }
        
        $ComplianceData.ComplianceScore = [math]::Round((
            ($ScoreFactors.InactiveUserRatio * 0.4) +
            ($ScoreFactors.AccessReviewCompletion * 0.4) +
            ($ScoreFactors.PrivilegedAccountRatio * 0.2)
        ) * 100, 2)
        
        # Generate risk factors and recommendations
        if ($ComplianceData.UserAccounts.InactiveUsers -gt ($ComplianceData.UserAccounts.Total * 0.1))
        {
            $ComplianceData.RiskFactors += "High number of inactive users ($($ComplianceData.UserAccounts.InactiveUsers))"
            $ComplianceData.Recommendations += "Review and disable inactive user accounts"
        }
        
        if ($ComplianceData.UserAccounts.NeverSignedIn -gt 0)
        {
            $ComplianceData.RiskFactors += "$($ComplianceData.UserAccounts.NeverSignedIn) users have never signed in"
            $ComplianceData.Recommendations += "Review users who have never signed in and consider account cleanup"
        }
        
        if ($ComplianceData.AccessReviews.CompletionRate -lt 80)
        {
            $ComplianceData.RiskFactors += "Low access review completion rate ($($ComplianceData.AccessReviews.CompletionRate)%)"
            $ComplianceData.Recommendations += "Improve access review campaign communication and follow-up"
        }
        
        # Display dashboard
        Write-Host "`nIdentity Governance Compliance Dashboard" -ForegroundColor Green
        Write-Host "=" * 50 -ForegroundColor Green
        Write-Host "Report Date: $($ComplianceData.GeneratedDate)" -ForegroundColor White
        Write-Host "Reporting Period: $($ComplianceData.ReportingPeriod)" -ForegroundColor White
        Write-Host "Overall Compliance Score: $($ComplianceData.ComplianceScore)%" -ForegroundColor $(
            if ($ComplianceData.ComplianceScore -ge 90) { "Green" }
            elseif ($ComplianceData.ComplianceScore -ge 75) { "Yellow" }
            else { "Red" }
        )
        
        Write-Host "`nUser Account Statistics:" -ForegroundColor Cyan
        Write-Host "  Total Users: $($ComplianceData.UserAccounts.Total)" -ForegroundColor White
        Write-Host "  Enabled: $($ComplianceData.UserAccounts.Enabled)" -ForegroundColor Green
        Write-Host "  Disabled: $($ComplianceData.UserAccounts.Disabled)" -ForegroundColor Yellow
        Write-Host "  Inactive (90+ days): $($ComplianceData.UserAccounts.InactiveUsers)" -ForegroundColor Red
        Write-Host "  Never Signed In: $($ComplianceData.UserAccounts.NeverSignedIn)" -ForegroundColor Red
        
        Write-Host "`nPrivileged Account Analysis:" -ForegroundColor Cyan
        Write-Host "  Privileged Users: $($ComplianceData.PrivilegedAccounts.TotalPrivilegedUsers)" -ForegroundColor White
        Write-Host "  Role Assignments: $($ComplianceData.PrivilegedAccounts.RoleAssignments)" -ForegroundColor White
        
        if ($ComplianceData.AccessReviews.Error)
        {
            Write-Host "`nAccess Reviews: $($ComplianceData.AccessReviews.Error)" -ForegroundColor Red
        }
        else
        {
            Write-Host "`nAccess Review Status:" -ForegroundColor Cyan
            Write-Host "  Active Campaigns: $($ComplianceData.AccessReviews.ActiveCampaigns)" -ForegroundColor White
            Write-Host "  Recent Reviews: $($ComplianceData.AccessReviews.RecentReviews)" -ForegroundColor White
            Write-Host "  Completion Rate: $($ComplianceData.AccessReviews.CompletionRate)%" -ForegroundColor White
        }
        
        if ($ComplianceData.RiskFactors.Count -gt 0)
        {
            Write-Host "`nRisk Factors:" -ForegroundColor Red
            $ComplianceData.RiskFactors | ForEach-Object {
                Write-Host "  ⚠ $_" -ForegroundColor Yellow
            }
        }
        
        if ($ComplianceData.Recommendations.Count -gt 0)
        {
            Write-Host "`nRecommendations:" -ForegroundColor Yellow
            $ComplianceData.Recommendations | ForEach-Object {
                Write-Host "  • $_" -ForegroundColor White
            }
        }
        
        # Export if requested
        if ($ExportPath)
        {
            $ComplianceData | ConvertTo-Json -Depth 5 | Out-File -FilePath $ExportPath
            Write-Host "`nDashboard data exported to: $ExportPath" -ForegroundColor Green
        }
        
        return $ComplianceData
    }
    catch
    {
        Write-Error "Failed to generate compliance dashboard: $($_.Exception.Message)"
        throw
    }
}

# Example usage and best practices documentation
Write-Host @"

IDENTITY GOVERNANCE IMPLEMENTATION GUIDE

Access Reviews Best Practices:
• Implement quarterly access reviews for all security groups
• Require manager approval for access extensions
• Enable automatic access removal for non-responsive reviews
• Use risk-based scoping for high-privilege roles

Entitlement Management:
• Create access packages for common role-based access patterns
• Implement approval workflows for sensitive resources
• Set appropriate access duration based on business needs
• Regular review of access package usage and effectiveness

Privileged Identity Management:
• Enable PIM for all administrative roles
• Require justification and approval for role activation
• Set maximum activation duration based on role requirements
• Monitor PIM activation patterns for anomalies

Compliance Monitoring:
• Generate monthly compliance dashboards
• Track access review completion rates
• Monitor inactive and unused accounts
• Regular audit of privileged role assignments

Automation Strategies:
• Automated provisioning based on HR system changes
• Dynamic group membership for role-based access
• Automated access certification reminders
• Risk-based conditional access policies

"@ -ForegroundColor Greeny Governance"
description: "Documentation for Identity Governance"
author: "Joseph Streeter"
ms.date: "2025-07-18"
ms.topic: "article"
---

## Identity Governance

This is a placeholder for Identity Governance content.

## Overview

Content will be added here soon.

## Topics

Add topics here.
