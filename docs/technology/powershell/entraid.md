# Entra ID


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
Get-MgUser -All -filter "extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStatus eq 'A'" -Property Id,Mail,UserPrincipalName,DisplayName, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeNumber, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeType, extension_70b265ce78f3470882d0d4b4ff62c8ba_msDS_cloudExtensionAttribute2, extension_70b265ce78f3470882d0d4b4ff62c8ba_msDS_cloudExtensionAttribute1, extension_70b265ce78f3470882d0d4b4ff62c8ba_lockoutDuration, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeID, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStatus, extension_70b265ce78f3470882d0d4b4ff62c8ba_entitledEmail, extension_70b265ce78f3470882d0d4b4ff62c8ba_isManager, extension_70b265ce78f3470882d0d4b4ff62c8ba_contractEndDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_costCenter, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeEndDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeStartDate, extension_70b265ce78f3470882d0d4b4ff62c8ba_isContingent, extension_70b265ce78f3470882d0d4b4ff62c8ba_isFaculty, extension_70b265ce78f3470882d0d4b4ff62c8ba_isRetired, extension_70b265ce78f3470882d0d4b4ff62c8ba_jobCode, extension_70b265ce78f3470882d0d4b4ff62c8ba_officeLocationCode, extension_70b265ce78f3470882d0d4b4ff62c8ba_positionID, extension_70b265ce78f3470882d0d4b4ff62c8ba_positionTime, extension_70b265ce78f3470882d0d4b4ff62c8ba_employeeSubType, extension_70b265ce78f3470882d0d4b4ff62c8ba_entitledO365
```

[Directory Extensions to Customize Data Stored for Entra ID Objects](https://practical365.com/directory-extensions-entra-d/)