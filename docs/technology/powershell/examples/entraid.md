# Entra ID

Some PowerShell for managing Entra ID, Conditional Access, Identity Protection, etc.

## Table of Contents

- [Add IP Addresses to Conditional Access Named Location](#add-ip-addresses-to-conditional-access-named-location)
- [Bulk Create Entra ID Dynamic Security Groups](#bulk-create-entra-id-dynamic-security-groups)
- [View Entra ID Custom Extensions](#view-entra-id-custom-extensions)
- [Manage Microsoft 365 Groups](#manage-microsoft-365-groups)
- [Change Group Membership Type (i.e. Static or Dynamic)](#change-group-membership-type-ie-static-or-dynamic)
- [Create Custom Role-Based Access Control Roles in Entra ID](#create-custom-role-based-access-control-roles-in-entra-id)

[Top](#table-of-contents)

## Add IP Addresses to Conditional Access Named Location

```powershell
$IPAddresses = 
'188.130.185.167',
'46.8.212.27',
'109.248.49.142',
'45.86.1.158',
'46.8.17.93',
'95.182.124.28',
'46.8.56.213',
'188.130.186.19',
'5.183.130.182',
'46.8.56.173',
'188.130.186.213',
'192.162.100.241',
'188.130.184.159'

$NamedLocation = "Threat IP Ranges"

$namedLocationId = Get-MgIdentityConditionalAccessNamedLocation -Filter "DisplayName eq '$($NamedLocation)'" | Select-Object -ExpandProperty id

foreach ($IPAddress in $IPAddresses)
{
    $params = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        displayName = "Threat IP Ranges"
        isTrusted = $false
        ipRanges = @(
            @{
                "@odata.type" = "#microsoft.graph.iPv4CidrRange"
                cidrAddress = "$IPAddress/32"
            }
        )
    }

    Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $namedLocationId -BodyParameter $params
}
```

[Top](#table-of-contents)

## Bulk Create Entra ID Dynamic Security Groups

```powershell
Grps = @('MC-GS-Role-Employee-BoardMember','Entitlements and licenses for Board Members',"BRD"),
@('MC-GS-Role-Employee-Casual','Entitlements and licenses for Casual',"CAS"),
@('MC-GS-Role-Employee-Contractor','Entitlements and licenses for Contractors',"CON"),
@('MC-GS-Role-Employee-DualCredit-Instructors','Entitlements and licenses for Dual Credit Instructors',"DCI"),
@('MC-GS-Role-Employee-External-Auditor','Entitlements and licenses for External Auditors',"EA"),
@('MC-GS-Role-Employee-Faculty-FullTime','Entitlements and licenses for full-time Faculty',"FFT"),
@('MC-GS-Role-Employee-Faculty-PartTime','Entitlements and licenses for part-time Faculty',"FPT"),
@('MC-GS-Role-Employee-Foundation-Staff','Entitlements and licenses for Foundation Staff',"FS"),
@('MC-GS-Role-Employee-Guests','Entitlements and licenses for Guest Speakers and Presenters',"GS"),
@('MC-GS-Role-Employee-Manager','Entitlements and licenses for Managers','MGR'),
@('MC-GS-Role-Employee-Retiree','Entitlements and licenses for retired employees',"RET"),
@('MC-GS-Role-Employee-Staff-FullTime','Entitlements and licenses for full-time staff',"SFT"),
@('MC-GS-Role-Employee-Staff-PartTime','Entitlements and licenses for part-time staff',"SPT"),
@('MC-GS-Role-Employee-TempAgency','Entitlements and licenses for Temp Agency',"TA"),
@('MC-GS-Role-Employee-Volunteer','Entitlements and licenses for volunteers',"VOL")

foreach ($Grp in $Grps)
{
    $GroupParam = @{
        DisplayName = $Grp[0]
        Description = $Grp[1]
        GroupTypes = @("DynamicMembership")
        SecurityEnabled     = $true
        IsAssignableToRole  = $false
        MailEnabled         = $false
        MailNickname        = (New-Guid).Guid.Substring(0,10)
        MembershipRule      = ('(user.extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeType -in ["A","C","E","F","I"]) and (user.extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeSubType -eq "{0}") and (user.extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStatus -eq "A")' -f $Grp[2])
        MembershipRuleProcessingState = "On"
   }
    
   New-MgGroup -BodyParameter $GroupParam
}
```

[Top](#table-of-contents)

## View Entra ID Custom Extensions

Get Extensions for one user:

```powershell
$UserID = "user@domain.com"

$App = Get-MgApplication -Filter "DisplayName eq 'Tenant Schema Extension App'"
$Extensions = Get-MgApplicationExtensionProperty -ApplicationId $App.Id
$User = Get-MgUser -UserId $UserId -Property $($Extensions.name -join ",")

$User.AdditionalProperties
```

Results:

```text
Key                                                           Value
---                                                           -----
@odata.context                                                https://graph.microsoft.com/v1.0/$metadata#users… 
extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeNumber     f35bb4f35b31105e9dc1729a5a21766a
extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStatus     A
extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeType       I
extension_70b265ce78f3470882d0d4b4ff62c8ba_isManager          false
extension_70b265ce78f3470882d0d4b4ff62c8ba_costCenter         CC730
extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStartDate  2019-01-02
extension_70b265ce78f3470882d0d4b4ff62c8ba_isContingent       false
extension_70b265ce78f3470882d0d4b4ff62c8ba_isFaculty          false
extension_70b265ce78f3470882d0d4b4ff62c8ba_isRetired          false
extension_70b265ce78f3470882d0d4b4ff62c8ba_jobCode            300459
extension_70b265ce78f3470882d0d4b4ff62c8ba_officeLocationCode CCL01
extension_70b265ce78f3470882d0d4b4ff62c8ba_positionTime       Full_time
```

Filter users based on extension attribute value:

```powershell
Get-MgUser -All -filter "extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStatus eq 'A'" -Property Id,Mail,UserPrincipalName,DisplayName, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeNumber, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeType, extension_70b265ce78f3470882d0d4b4ff62c8ba_msDS_cloudExtensionAttribute2, extension_70b265ce78f3470882d0d4b4ff62c8ba_msDS_cloudExtensionAttribute1, extension_70b265ce78f3470882d0d4b4ff62c8ba_lockoutDuration, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeID, extension_70b265ce78f3470882d0d4b4ff62c8ba_isManager, extension_70b265ce78f3470882d0d4b4ff62c8ba_contractEndDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_costCenter, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeEndDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStartDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeSubType
```

[Directory Extensions to Customize Data Stored for Entra ID Objects](https://practical365.com/directory-extensions-entra-d/)

[Top](#table-of-contents)

## Manage Microsoft 365 Groups

Connect to Office 365

```powershell
$UserCredential = get-Credential
$session = New-PSSession `
    -ConfigurationName Microsoft.Exchange `
    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -Credential $UserCredential `
    -Authentication Basic `
    -AllowRedirection
    
Import-PSSession $session
```

Create New Office 365 Group

```powershell
New-UnifiedGroup `
    -DisplayName  "MC-OG-Group-Name" `
    -Alias  "MC-OG-Group-Name" `
           -EmailAddresses  "MC-OG-Group-Name@madisoncollege.edu" `
    -AccessType Private
```

Update Office 365 Group

```powershell
Set-UnifiedGroup `
    -Identity "MC-OG-Group-Name" `
    -AutoSubscribeNewMembers:$true `
    -AlwaysSubscribeMembersToCalendarEvents:$true `
    -HiddenFromAddressListsEnabled:$false `
    -UnifiedGroupWelcomeMessageEnabled:$false `
    -HiddenFromExchangeClientsEnabled:$false `
    -SubscriptionEnabled:$true
```

Disable Welcome Message

```powershell
Set-UnifiedGroup -Identity "MC-OG-Group-Name" -UnifiedGroupWelcomeMessageEnable:$false
```

Hide Microsoft 365 Group from GAL

```powershell
Set-UnifiedGroup -Identity "MC-OG-Group-Name" -HiddenFromAddressListsEnabled:$true
```

Hide Office 365 Group from Outlook Clients

```powershell
Set-UnifiedGroup -Identity "MC-OG-Group-Name" -HiddenFromExchangeClientsEnabled:$true
```

Subscribe New Group Members to Calendar Events

```powershell
Set-UnifiedGroup -Identity "MC-OG-Group-Name" -AlwaysSubscribeMembersToCalendarEvents:$true
```

Change Display Name of Microsoft 365 Group

```powershell
Set-UnifiedGroup -Identity "MC-OG-Group-Name" -DisplayName "MC Group-Name"
```

Get Subscribers to the Microsoft 365 Group

```powershell
Get-UnifiedGroupLinks -Identity "MC-OG-Group-Name" -linktype Subscribers
```

Get Subscribers to the Microsoft 365 Group

```powershell
Get-UnifiedGroup -Identity WorkdayUserGroup | select Identity,AutoSubscribeNewMembers,AlwaysSubscribeMembersToCalendarEvents,HiddenFromAddressListsEnabled,UnifiedGroupWelcomeMessageEnabled,HiddenFromExchangeClientsEnabled,SubscriptionEnabled,AccessType
```

A member of an Microsoft 365 group may not be subscribed to the group and not receiving messages in their inbox. The following PowerShell will check for members that are not subscribed.

```powershell
$GrpName = "GroupName"
$mems=Get-UnifiedGroupLinks -Identity $GrpName -LinkType members | select -ExpandProperty name
$subs=Get-UnifiedGroupLinks -Identity $GrpName -LinkType Subscribers | select -ExpandProperty name

Compare-Object -ReferenceObject $mems -DifferenceObject $subs
```

The following code will subscribe all members of the group that are not currently subscribed. 

```powershell
$GrpName = "GroupName"
$Group = Get-UnifiedGroup -Identity $GrpName
$Members = Get-UnifiedGroupLinks -Identity $group.Name -LinkType Members
$Subscribers = Get-UnifiedGroupLinks -Identity $group.name -LinkType Subscribers

foreach ($Member in $Members) 
{
    If ($Member.Name -NotIn $Subscribers.Name)
    { 
        Add-UnifiedGroupLinks -Identity $Group.Name -LinkType Subscribers -Links $Member.Name
    }
}
```

[Top](#table-of-contents)

## Dynamic Groups

Tenant Schema Extension AppID

To use Entra ID custom attributes, get the Application ID that the attributes are kept in. This App ID is used to pull the custom extensions (attribs) into the dynamic query builder. For example, "70b265ce-78f3-4708-82d0-d4b4ff62c8ba"

You can also use the "user.extension_70b265ce78f3470882d0d4b4ff62c8ba_AttribName" in the Rules Editor.

### Dynamic Rules

String

```text
user.department -eq "Sales"
user.department -match "Sa.*"
user.department -ne null
```

Boolean

```text
user.accountEnabled -eq true
```

String Collection

```text
(user.proxyAddresses -contains "SMTP: alias@domain")
```

Using "in" and "notin" Operators

```text
(user.extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeType -in ["A","C","E","F","I"])
```

Multiple Expressions

```text
(user.department -eq "Sales") -or (user.department -eq "Marketing") (user.department -eq "Sales") -and -not (user.jobTitle -contains "SDE")
```

[Top](#table-of-contents)

## Change Group Membership Type (i.e. Static or Dynamic)

> [!WARNING]
> This should be rewritten using the Microsoft Graph Cmdlets!

```powershell
#The moniker for dynamic groups as used in the GroupTypes property of a group object
$dynamicGroupTypeString = "DynamicMembership"

function ConvertDynamicGroupToStatic
{
    Param([string]$groupId)

    #existing group types
    [System.Collections.ArrayList]$groupTypes = (Get-AzureAdMsGroup -Id $groupId).GroupTypes

    if($groupTypes -eq $null -or !$groupTypes.Contains($dynamicGroupTypeString))
    {
        throw "This group is already a static group. Aborting conversion.";
    }


    #remove the type for dynamic groups, but keep the other type values
    $groupTypes.Remove($dynamicGroupTypeString)

    #modify the group properties to make it a static group: i) change GroupTypes to remove the dynamic type, ii) pause execution of the current rule
    Set-AzureAdMsGroup -Id $groupId -GroupTypes $groupTypes.ToArray() -MembershipRuleProcessingState "Paused"
}
```

```powershell
function ConvertStaticGroupToDynamic
{
    Param([string]$groupId, [string]$dynamicMembershipRule)

    #existing group types
    [System.Collections.ArrayList]$groupTypes = (Get-AzureAdMsGroup -Id $groupId).GroupTypes

    if($groupTypes -ne $null -and $groupTypes.Contains($dynamicGroupTypeString))
    {
        throw "This group is already a dynamic group. Aborting conversion.";
    }
    #add the dynamic group type to existing types
    $groupTypes.Add($dynamicGroupTypeString)

    #modify the group properties to make it a static group: i) change GroupTypes to add the dynamic type, ii) start execution of the rule, iii) set the rule
    Set-AzureAdMsGroup -Id $groupId -GroupTypes $groupTypes.ToArray() -MembershipRuleProcessingState "On" -MembershipRule $dynamicMembershipRule
}
```

[Top](#table-of-contents)

## Create Custom Role-Based Access Control Roles in Entra ID

[Create custom roles in Azure AD role-based access control - Microsoft Entra | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/roles/custom-create)

New Role

```powershell
# Basic role information
$displayName = "TS Help Desk"
$description = "Can manage basic aspects of the directory."
$templateId = (New-Guid).Guid
 
# Set of permissions to grant
$allowedResourceAction =
@(
    "microsoft.directory/auditLogs/allProperties/read"
    "microsoft.directory/groups/standard/read"
    "microsoft.directory/groups/memberOf/read"
    "microsoft.directory/groups/members/read"
    "microsoft.directory/groups/owners/read"
    "microsoft.directory/users/standard/read"
    "microsoft.directory/users/ownedDevices/read"
    "microsoft.directory/users/licenseDetails/read"
    "microsoft.directory/users/registeredDevices/read"
    "microsoft.directory/users/authenticationMethods/create"
    "microsoft.directory/users/authenticationMethods/delete"
    "microsoft.directory/users/authenticationMethods/standard/restrictedRead"
    "microsoft.directory/users/authenticationMethods/basic/update"
)

$rolePermissions = @{'allowedResourceActions'= $allowedResourceAction}
 
# Create new custom admin role
$customAdmin = New-AzureADMSRoleDefinition -RolePermissions $rolePermissions -DisplayName $displayName -Description $description -TemplateId $templateId -IsEnabled $true
```

Update Role

```powershell
# Get current role
$Role = Get-AzureADMSRoleDefinition -Filter "startswith(displayName, 'TS Help Desk')"

# Set of permissions to grant
$allowedResourceAction =
@(
        "microsoft.directory/auditLogs/allProperties/read"
        "microsoft.directory/groups/standard/read"
        "microsoft.directory/groups/memberOf/read"
        "microsoft.directory/groups/members/read"
        "microsoft.directory/groups/owners/read"
        "microsoft.directory/users/standard/read"
        "microsoft.directory/users/ownedDevices/read"
        "microsoft.directory/users/licenseDetails/read"
        "microsoft.directory/users/registeredDevices/read"
        "microsoft.directory/users/authenticationMethods/create"
        "microsoft.directory/users/authenticationMethods/delete"
        "microsoft.directory/users/authenticationMethods/standard/restrictedRead"
        "microsoft.directory/users/authenticationMethods/basic/update"
)

$rolePermissions = @{'allowedResourceActions'= $allowedResourceAction}

Set-AzureADMSRoleDefinition `
    -ID $Role.Id `
    -RolePermissions $rolePermissions
```
