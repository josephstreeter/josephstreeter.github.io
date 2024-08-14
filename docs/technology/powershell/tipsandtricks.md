# PowerShell Tips and Tricks

The following is a list of tips and tricks that I've used to make the use of PowerShell better in certain situations.

## Setting Default Parameter Values

Use the $PSDefaultParameterValues preference variable to set custom default values for cmdlets and advanced functions that you frequently use. The parameters and the default values are stored as a hash table.

This feature is useful when you must specify the same parameter value nearly every time you use a cmdlet or when a particular parameter value is difficult to remember, such as an certificate thumbprint or Azure Subscription GUID.

Set a parameter default value:

```powershell
$PSDefaultParameterValues=@{“<CmdletName>:<ParameterName>”=”<DefaultValue>”}
```

Set several parameter default values:

```powershell
$PSDefaultParameterValues=@{
 “<CmdletName>:<ParameterName1>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName2>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName3>”=”<DefaultValue>”
 “<CmdletName>:<ParameterName4>”=”<DefaultValue>”
}
```

Set a parameter default value based on conditions using a script block:

```powershell
$PSDefaultParameterValues=@{“<CmdletName>:<ParameterName>”={<ScriptBlock>}}
```

Use the Add() method to add preferences to an existing hash table.

```powershell
$PSDefaultParameterValues.Add({“<CmdletName>:<ParameterName>”,”<DefaultValue>”})
```

Use the Remove() method to remove preferences from an existing hash table.

```powershell
$PSDefaultParameterValues.Remove(“<CmdletName>:<ParameterName>”)
```

Use the Clear() method to remove all of the preferences from the hash table.

```powershell
$PSDefaultParameterValues.Clear()
```

Example: Setting Default Parameters for Connect-Exchange Online:

```powershell
$PSDefaultParameterValues=@{
 "Connect-ExchangeOnline:UserPrincipalName"="username@domainname.com"
 "Connect-ExchangeOnline:ShowBanner"=$false
 "Connect-ExchangeOnline:ShowProgress"=$false
}
```

[about_Parameters_Default_Values](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-7.4)
>The $PSDefaultParameterValues preference variable lets you specify custom default values for any cmdlet or advanced function. Cmdlets and advanced functions use the custom default value unless you specify another value in the command.
>
>The authors of cmdlets and advanced functions set standard default values for their parameters. Typically, the standard default values are useful, but they might not be appropriate for all environments.
>
>This feature is especially useful when you must specify the same alternate parameter value nearly every time you use the command or when a particular parameter value is difficult to remember, such as an email server name or project GUID.
>
>If the desired default value varies predictably, you can specify a script block that provides different default values for a parameter under different conditions.

```powershell
$PSDefaultParameterValues=@{"CmdletName:ParameterName"="DefaultValue"}
$PSDefaultParameterValues=@{ "CmdletName:ParameterName"={{ScriptBlock}} }
$PSDefaultParameterValues["Disabled"]=$True | $False
```

## PowerShell Paths When Using Folder Redirection

Group Policy is configuring folder redirection for several profile directories, including "Documents" where the default $PSModulePath and $Profile is located.  There has been performance issues when using PowerShell remotely over VPN as it takes PowerShell a while to search $PSModulePath to autoload modules.

The following PowerShell code seemed to work to change the directory that $PSModulePath points to and improved performance significantly. Setting the $Profile path to local is also included. This is not really polished or significantly tested. Your mileage may vary.

```powershell
# Update Profile Path
$env:PSModulePath = ($env:PSModulePath).replace("\\host.domain.com\Home\UserName\Documents\PowerShell\Modules","C:\Users\UserName\Documents\PowerShell\Modules")
$ProfilePath = $profile.CurrentUserCurrentHost

if ($ProfilePath -like "\\*")
{
    Write-Output "ProfilePath is set to $ProfilePath. We will update this to your local profile"
    $Cmd = "& New-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' Personal -Value '%USERPROFILE%\Documents' -Type ExpandString -Force"

    $p = Get-Process -Id $PID

    if ($p.processname -eq "pwsh")
    {
        pwsh -noprofile -command $Cmd
    }
    else
    {
        powershell -noprofile -command $Cmd
    }

    Write-Output ("Restart {0} to continue" -f $p.processname)
}
```

## Dynamic PSCustomObject

> [!NOTE]
> This was just copied out of a script. Needs some work.

```powershell
$PSObject = @()
foreach ($Object in $Results)
{
    $objs = [PSCustomObject]@{}
    foreach ($Property in $Object.Properties.PropertyNames)
    {
        $objs | Add-Member -MemberType NoteProperty -Name $Property -Value $Object.Properties.item($Property)[0] -Force
    }
    $PSObject += $objs
}
```

## Bulk Create Entra ID Dynamic Security Groups

```powershell
Grps = @('MC-GS-Role-Employee-BoardMember','Entitlements and licenses for Board Members',"BM"),
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
