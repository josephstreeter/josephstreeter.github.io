---
title: Identity and Access Management (IAM)
description: Comprehensive guide to enterprise identity and access management including authentication, authorization, single sign-on, and identity governance
author: Joseph Streeter
date: 2024-01-15
tags: [identity-management, authentication, authorization, sso, identity-governance, rbac]
---

Identity and Access Management (IAM) is the framework of policies and technologies for ensuring that the right individuals access the right resources at the right times for the right reasons. This guide covers comprehensive IAM implementation strategies.

## IAM Architecture Overview

### Core Components

```text
┌─────────────────────────────────────────────────────────────────┐
│                    IAM Architecture                             │
├─────────────────────────────────────────────────────────────────┤
│  Layer                │ Components                              │
│  ├─ Identity Sources  │ AD, LDAP, HR Systems, Cloud Providers  │
│  ├─ Authentication    │ MFA, SSO, Biometrics, Certificates     │
│  ├─ Authorization     │ RBAC, ABAC, Policy Engines            │
│  ├─ Provisioning     │ Automated Account Lifecycle            │
│  ├─ Governance        │ Access Reviews, Compliance, Audit     │
│  └─ Integration       │ APIs, SAML, OAuth, OIDC, SCIM         │
└─────────────────────────────────────────────────────────────────┘
```

### IAM Ecosystem Components

- **Identity Providers (IdP)**: Central authentication authorities
- **Service Providers (SP)**: Applications consuming identity services
- **Directory Services**: User and group repositories
- **Policy Decision Points**: Authorization engines
- **Governance Systems**: Compliance and audit platforms

## Enterprise Authentication Framework

### Multi-Factor Authentication Implementation

```powershell
<#
.SYNOPSIS
    Enterprise Multi-Factor Authentication management framework.
.DESCRIPTION
    Provides comprehensive MFA implementation, policy management,
    and compliance reporting for enterprise environments.
#>

class MFAPolicy {
    [string]$PolicyName
    [string[]]$UserGroups
    [string[]]$ApplicationGroups
    [string[]]$RequiredMethods
    [hashtable]$MethodSettings
    [bool]$IsEnabled
    [datetime]$LastModified
    [string]$CreatedBy
    
    MFAPolicy([string]$Name) {
        $this.PolicyName = $Name
        $this.UserGroups = @()
        $this.ApplicationGroups = @()
        $this.RequiredMethods = @()
        $this.MethodSettings = @{}
        $this.IsEnabled = $true
        $this.LastModified = Get-Date
        $this.CreatedBy = $env:USERNAME
    }
    
    [void] AddUserGroup([string]$GroupName) {
        if ($GroupName -notin $this.UserGroups) {
            $this.UserGroups += $GroupName
            $this.LastModified = Get-Date
        }
    }
    
    [void] AddApplicationGroup([string]$AppGroup) {
        if ($AppGroup -notin $this.ApplicationGroups) {
            $this.ApplicationGroups += $AppGroup
            $this.LastModified = Get-Date
        }
    }
    
    [void] SetRequiredMethods([string[]]$Methods) {
        $this.RequiredMethods = $Methods
        $this.LastModified = Get-Date
    }
    
    [void] ConfigureMethod([string]$Method, [hashtable]$Settings) {
        $this.MethodSettings[$Method] = $Settings
        $this.LastModified = Get-Date
    }
}

class MFAManager {
    [hashtable]$Policies
    [string]$ConfigPath
    [string]$LogPath
    [hashtable]$MethodProviders
    
    MFAManager([string]$ConfigurationPath) {
        $this.Policies = @{}
        $this.ConfigPath = $ConfigurationPath
        $this.LogPath = Join-Path (Split-Path $ConfigurationPath) "Logs"
        $this.MethodProviders = @{}
        
        # Ensure directories exist
        $ConfigDir = Split-Path $this.ConfigPath
        if (!(Test-Path $ConfigDir)) {
            New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        }
        if (!(Test-Path $this.LogPath)) {
            New-Item -ItemType Directory -Path $this.LogPath -Force | Out-Null
        }
        
        # Initialize default method providers
        $this.InitializeMethodProviders()
        
        # Load existing policies
        $this.LoadPolicies()
    }
    
    [void] InitializeMethodProviders() {
        $this.MethodProviders = @{
            "SMS" = @{
                Name = "SMS Text Message"
                Configuration = @{
                    Provider = "Twilio"
                    APIEndpoint = "https://api.twilio.com/2010-04-01"
                    MessageTemplate = "Your verification code is: {0}"
                    CodeLength = 6
                    CodeExpiry = 300  # 5 minutes
                }
                Enabled = $true
            }
            "Email" = @{
                Name = "Email Verification"
                Configuration = @{
                    SMTPServer = "smtp.company.com"
                    FromAddress = "noreply@company.com"
                    Subject = "Multi-Factor Authentication Code"
                    Template = "email-mfa-template.html"
                    CodeLength = 8
                    CodeExpiry = 600  # 10 minutes
                }
                Enabled = $true
            }
            "TOTP" = @{
                Name = "Time-based One-Time Password"
                Configuration = @{
                    Issuer = "Company IAM"
                    Algorithm = "SHA1"
                    Digits = 6
                    Period = 30
                    Window = 1  # Allow 1 period drift
                }
                Enabled = $true
            }
            "Push" = @{
                Name = "Push Notification"
                Configuration = @{
                    Provider = "Microsoft Authenticator"
                    Timeout = 60
                    AllowNumberMatching = $true
                    RequireBiometric = $false
                }
                Enabled = $true
            }
            "Hardware" = @{
                Name = "Hardware Token"
                Configuration = @{
                    SupportedTokens = @("YubiKey", "RSA SecurID")
                    TokenValidationEndpoint = "https://yubikey-validation.company.com"
                    RequireTouchPresence = $true
                }
                Enabled = $false
            }
            "Biometric" = @{
                Name = "Biometric Authentication"
                Configuration = @{
                    SupportedMethods = @("Fingerprint", "FaceID", "WindowsHello")
                    RequireLiveness = $true
                    FallbackToPin = $true
                }
                Enabled = $true
            }
        }
    }
    
    [MFAPolicy] CreatePolicy([string]$PolicyName) {
        if ($this.Policies.ContainsKey($PolicyName)) {
            throw "Policy '$PolicyName' already exists"
        }
        
        $Policy = [MFAPolicy]::new($PolicyName)
        $this.Policies[$PolicyName] = $Policy
        $this.SavePolicies()
        
        $this.LogActivity("PolicyCreated", "Created MFA policy: $PolicyName")
        
        return $Policy
    }
    
    [void] RemovePolicy([string]$PolicyName) {
        if (!$this.Policies.ContainsKey($PolicyName)) {
            throw "Policy '$PolicyName' not found"
        }
        
        $this.Policies.Remove($PolicyName)
        $this.SavePolicies()
        
        $this.LogActivity("PolicyRemoved", "Removed MFA policy: $PolicyName")
    }
    
    [MFAPolicy] GetPolicy([string]$PolicyName) {
        if (!$this.Policies.ContainsKey($PolicyName)) {
            throw "Policy '$PolicyName' not found"
        }
        
        return $this.Policies[$PolicyName]
    }
    
    [hashtable] EvaluateUserMFA([string]$UserName, [string]$Application) {
        $ApplicablePolicies = @()
        
        # Get user's group memberships
        try {
            $User = Get-ADUser -Identity $UserName -Properties MemberOf
            $UserGroups = $User.MemberOf | ForEach-Object { (Get-ADGroup -Identity $_).Name }
        }
        catch {
            Write-Warning "Could not retrieve user groups for $UserName"
            $UserGroups = @()
        }
        
        # Find applicable policies
        foreach ($Policy in $this.Policies.Values) {
            if (!$Policy.IsEnabled) { continue }
            
            $UserGroupMatch = $false
            foreach ($Group in $Policy.UserGroups) {
                if ($Group -in $UserGroups -or $Group -eq "*") {
                    $UserGroupMatch = $true
                    break
                }
            }
            
            $AppGroupMatch = $false
            foreach ($AppGroup in $Policy.ApplicationGroups) {
                if ($Application -like $AppGroup -or $AppGroup -eq "*") {
                    $AppGroupMatch = $true
                    break
                }
            }
            
            if ($UserGroupMatch -and $AppGroupMatch) {
                $ApplicablePolicies += $Policy
            }
        }
        
        # Combine requirements from all applicable policies
        $RequiredMethods = @()
        $MethodSettings = @{}
        
        foreach ($Policy in $ApplicablePolicies) {
            $RequiredMethods += $Policy.RequiredMethods
            foreach ($Method in $Policy.MethodSettings.Keys) {
                if (!$MethodSettings.ContainsKey($Method)) {
                    $MethodSettings[$Method] = $Policy.MethodSettings[$Method]
                }
            }
        }
        
        # Remove duplicates and prioritize stronger methods
        $RequiredMethods = $RequiredMethods | Select-Object -Unique
        
        return @{
            RequiredMethods = $RequiredMethods
            MethodSettings = $MethodSettings
            ApplicablePolicies = $ApplicablePolicies.PolicyName
            Evaluation = @{
                UserName = $UserName
                Application = $Application
                Timestamp = Get-Date
                UserGroups = $UserGroups
            }
        }
    }
    
    [string] GenerateVerificationCode([string]$Method, [int]$Length = 6) {
        $Characters = "0123456789"
        
        if ($Method -eq "Email") {
            $Characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        
        $Code = ""
        for ($i = 0; $i -lt $Length; $i++) {
            $Code += $Characters[(Get-Random -Minimum 0 -Maximum $Characters.Length)]
        }
        
        return $Code
    }
    
    [bool] SendVerificationCode([string]$UserName, [string]$Method, [string]$Code, [hashtable]$MethodSettings) {
        try {
            switch ($Method) {
                "SMS" {
                    $User = Get-ADUser -Identity $UserName -Properties MobilePhone
                    if ($User.MobilePhone) {
                        $Message = $MethodSettings.MessageTemplate -f $Code
                        Send-SMSMessage -PhoneNumber $User.MobilePhone -Message $Message -Settings $MethodSettings
                        return $true
                    }
                    return $false
                }
                
                "Email" {
                    $User = Get-ADUser -Identity $UserName -Properties EmailAddress
                    if ($User.EmailAddress) {
                        Send-EmailCode -EmailAddress $User.EmailAddress -Code $Code -Settings $MethodSettings
                        return $true
                    }
                    return $false
                }
                
                "Push" {
                    Send-PushNotification -UserName $UserName -Settings $MethodSettings
                    return $true
                }
                
                default {
                    Write-Warning "Unsupported MFA method: $Method"
                    return $false
                }
            }
        }
        catch {
            $this.LogActivity("SendCodeFailed", "Failed to send $Method code to $UserName : $($_.Exception.Message)")
            return $false
        }
    }
    
    [bool] ValidateVerificationCode([string]$UserName, [string]$Method, [string]$ProvidedCode, [string]$StoredCode, [datetime]$CodeTimestamp, [hashtable]$MethodSettings) {
        # Check if code has expired
        $Expiry = $MethodSettings.CodeExpiry
        if ((Get-Date) -gt $CodeTimestamp.AddSeconds($Expiry)) {
            $this.LogActivity("CodeExpired", "Verification code expired for user $UserName using method $Method")
            return $false
        }
        
        # Validate code based on method
        switch ($Method) {
            { $_ -in @("SMS", "Email") } {
                $IsValid = $ProvidedCode -eq $StoredCode
                break
            }
            
            "TOTP" {
                $IsValid = $this.ValidateTOTPCode($UserName, $ProvidedCode, $MethodSettings)
                break
            }
            
            "Hardware" {
                $IsValid = $this.ValidateHardwareToken($UserName, $ProvidedCode, $MethodSettings)
                break
            }
            
            default {
                $IsValid = $false
                break
            }
        }
        
        # Log validation result
        if ($IsValid) {
            $this.LogActivity("CodeValidated", "Successful MFA validation for user $UserName using method $Method")
        } else {
            $this.LogActivity("CodeValidationFailed", "Failed MFA validation for user $UserName using method $Method")
        }
        
        return $IsValid
    }
    
    [bool] ValidateTOTPCode([string]$UserName, [string]$ProvidedCode, [hashtable]$Settings) {
        # This would integrate with your TOTP library
        # Implementation depends on your TOTP provider (Google Authenticator, Microsoft Authenticator, etc.)
        
        try {
            # Get user's TOTP secret from secure storage
            $UserSecret = Get-UserTOTPSecret -UserName $UserName
            
            if (!$UserSecret) {
                return $false
            }
            
            # Calculate current time window
            $TimeWindow = [math]::Floor((Get-Date).ToUniversalTime().Subtract([datetime]'1970-01-01').TotalSeconds / $Settings.Period)
            
            # Allow for clock drift (check current window and adjacent windows)
            for ($drift = -$Settings.Window; $drift -le $Settings.Window; $drift++) {
                $TestWindow = $TimeWindow + $drift
                $ExpectedCode = Generate-TOTPCode -Secret $UserSecret -TimeWindow $TestWindow -Settings $Settings
                
                if ($ProvidedCode -eq $ExpectedCode) {
                    return $true
                }
            }
            
            return $false
        }
        catch {
            Write-Warning "TOTP validation error: $($_.Exception.Message)"
            return $false
        }
    }
    
    [void] SavePolicies() {
        $PolicyData = @{}
        foreach ($PolicyName in $this.Policies.Keys) {
            $Policy = $this.Policies[$PolicyName]
            $PolicyData[$PolicyName] = @{
                PolicyName = $Policy.PolicyName
                UserGroups = $Policy.UserGroups
                ApplicationGroups = $Policy.ApplicationGroups
                RequiredMethods = $Policy.RequiredMethods
                MethodSettings = $Policy.MethodSettings
                IsEnabled = $Policy.IsEnabled
                LastModified = $Policy.LastModified
                CreatedBy = $Policy.CreatedBy
            }
        }
        
        $PolicyData | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.ConfigPath -Encoding UTF8
    }
    
    [void] LoadPolicies() {
        if (Test-Path $this.ConfigPath) {
            try {
                $PolicyData = Get-Content $this.ConfigPath | ConvertFrom-Json
                
                foreach ($PolicyName in $PolicyData.PSObject.Properties.Name) {
                    $PolicyInfo = $PolicyData.$PolicyName
                    $Policy = [MFAPolicy]::new($PolicyInfo.PolicyName)
                    
                    $Policy.UserGroups = $PolicyInfo.UserGroups
                    $Policy.ApplicationGroups = $PolicyInfo.ApplicationGroups
                    $Policy.RequiredMethods = $PolicyInfo.RequiredMethods
                    $Policy.MethodSettings = $PolicyInfo.MethodSettings
                    $Policy.IsEnabled = $PolicyInfo.IsEnabled
                    $Policy.LastModified = $PolicyInfo.LastModified
                    $Policy.CreatedBy = $PolicyInfo.CreatedBy
                    
                    $this.Policies[$PolicyName] = $Policy
                }
            }
            catch {
                Write-Warning "Failed to load MFA policies: $($_.Exception.Message)"
            }
        }
    }
    
    [void] LogActivity([string]$Action, [string]$Message) {
        $LogEntry = [PSCustomObject]@{
            Timestamp = Get-Date
            Action = $Action
            Message = $Message
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
        }
        
        $LogFile = Join-Path $this.LogPath "MFA-$(Get-Date -Format 'yyyyMM').log"
        $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogFile -Append -Encoding UTF8
        
        # Also write to Windows Event Log
        try {
            Write-EventLog -LogName Application -Source "IAM-MFA" -EventId 8001 -EntryType Information -Message "$Action : $Message"
        }
        catch {
            # Event source might not exist, continue without error
        }
    }
}

# Global functions for MFA management
function Initialize-MFAFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = "C:\IAM\Config\MFA-Policies.json"
    )
    
    $Global:MFAManager = [MFAManager]::new($ConfigPath)
    
    # Create default policies
    $AdminPolicy = $Global:MFAManager.CreatePolicy("HighPrivilegeUsers")
    $AdminPolicy.AddUserGroup("Domain Admins")
    $AdminPolicy.AddUserGroup("Enterprise Admins")
    $AdminPolicy.AddUserGroup("Schema Admins")
    $AdminPolicy.AddApplicationGroup("*")
    $AdminPolicy.SetRequiredMethods(@("TOTP", "Push"))
    $AdminPolicy.ConfigureMethod("TOTP", @{ RequiredForAllSessions = $true })
    $AdminPolicy.ConfigureMethod("Push", @{ RequireBiometric = $true })
    
    $StandardPolicy = $Global:MFAManager.CreatePolicy("StandardUsers")
    $StandardPolicy.AddUserGroup("Domain Users")
    $StandardPolicy.AddApplicationGroup("Office365")
    $StandardPolicy.AddApplicationGroup("VPN")
    $StandardPolicy.SetRequiredMethods(@("SMS", "Email", "TOTP"))
    
    Write-Host "MFA Framework initialized with default policies" -ForegroundColor Green
}

function New-MFAPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyName,
        
        [Parameter()]
        [string[]]$UserGroups = @(),
        
        [Parameter()]
        [string[]]$ApplicationGroups = @(),
        
        [Parameter()]
        [string[]]$RequiredMethods = @()
    )
    
    if (!$Global:MFAManager) {
        Initialize-MFAFramework
    }
    
    try {
        $Policy = $Global:MFAManager.CreatePolicy($PolicyName)
        
        foreach ($Group in $UserGroups) {
            $Policy.AddUserGroup($Group)
        }
        
        foreach ($AppGroup in $ApplicationGroups) {
            $Policy.AddApplicationGroup($AppGroup)
        }
        
        if ($RequiredMethods.Count -gt 0) {
            $Policy.SetRequiredMethods($RequiredMethods)
        }
        
        Write-Host "MFA Policy '$PolicyName' created successfully" -ForegroundColor Green
        return $Policy
    }
    catch {
        Write-Error "Failed to create MFA policy: $($_.Exception.Message)"
    }
}

function Test-UserMFARequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [string]$Application
    )
    
    if (!$Global:MFAManager) {
        Initialize-MFAFramework
    }
    
    try {
        $Requirements = $Global:MFAManager.EvaluateUserMFA($UserName, $Application)
        
        Write-Host "MFA Requirements for $UserName accessing $Application:" -ForegroundColor Yellow
        Write-Host "Required Methods: $($Requirements.RequiredMethods -join ', ')" -ForegroundColor White
        Write-Host "Applicable Policies: $($Requirements.ApplicablePolicies -join ', ')" -ForegroundColor White
        
        return $Requirements
    }
    catch {
        Write-Error "Failed to evaluate MFA requirements: $($_.Exception.Message)"
    }
}
```

## Single Sign-On (SSO) Implementation

### SAML and OAuth Integration

```powershell
function Deploy-SSOConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$IdentityProvider = "ADFS",
        
        [Parameter()]
        [string[]]$ServiceProviders = @(),
        
        [Parameter()]
        [string]$ConfigurationPath = "C:\IAM\SSO\Configuration.xml"
    )
    
    $SSOConfig = @{
        IdentityProvider = @{
            Type = $IdentityProvider
            Endpoint = "https://sts.company.com/adfs/ls/"
            MetadataURL = "https://sts.company.com/FederationMetadata/2007-06/FederationMetadata.xml"
            SigningCertificate = "C:\IAM\Certificates\ADFS-Signing.cer"
            EncryptionCertificate = "C:\IAM\Certificates\ADFS-Encryption.cer"
            NameIDFormat = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
            AttributeMapping = @{
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" = "mail"
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" = "givenName"
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" = "sn"
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" = "sAMAccountName"
                "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups" = "memberOf"
            }
        }
        ServiceProviders = @{}
        TrustRelationships = @{}
        SecurityPolicies = @{
            SessionTimeout = 480  # 8 hours
            RequireSignedRequests = $true
            RequireEncryptedAssertions = $true
            AllowedClockSkew = 300  # 5 minutes
            MaxAssertionAge = 3600  # 1 hour
        }
    }
    
    # Configure service providers
    foreach ($SP in $ServiceProviders) {
        $SSOConfig.ServiceProviders[$SP] = @{
            Name = $SP
            EntityID = "https://$SP.company.com"
            AssertionConsumerService = "https://$SP.company.com/saml/acs"
            SingleLogoutService = "https://$SP.company.com/saml/sls"
            RequiredAttributes = @("emailaddress", "givenname", "surname", "groups")
            AttributeReleasePolicy = "StandardUser"
            EncryptAssertions = $true
            SignAssertions = $true
        }
    }
    
    # Generate configuration
    $ConfigXML = @"
<?xml version="1.0" encoding="UTF-8"?>
<SSOConfiguration>
    <IdentityProvider>
        <Type>$($SSOConfig.IdentityProvider.Type)</Type>
        <Endpoint>$($SSOConfig.IdentityProvider.Endpoint)</Endpoint>
        <MetadataURL>$($SSOConfig.IdentityProvider.MetadataURL)</MetadataURL>
        <NameIDFormat>$($SSOConfig.IdentityProvider.NameIDFormat)</NameIDFormat>
        <AttributeMapping>
"@
    
    foreach ($Mapping in $SSOConfig.IdentityProvider.AttributeMapping.GetEnumerator()) {
        $ConfigXML += @"
            <Attribute ClaimType="$($Mapping.Key)" AttributeName="$($Mapping.Value)" />
"@
    }
    
    $ConfigXML += @"
        </AttributeMapping>
    </IdentityProvider>
    <ServiceProviders>
"@
    
    foreach ($SP in $SSOConfig.ServiceProviders.GetEnumerator()) {
        $SPConfig = $SP.Value
        $ConfigXML += @"
        <ServiceProvider Name="$($SPConfig.Name)">
            <EntityID>$($SPConfig.EntityID)</EntityID>
            <AssertionConsumerService>$($SPConfig.AssertionConsumerService)</AssertionConsumerService>
            <SingleLogoutService>$($SPConfig.SingleLogoutService)</SingleLogoutService>
            <EncryptAssertions>$($SPConfig.EncryptAssertions)</EncryptAssertions>
            <SignAssertions>$($SPConfig.SignAssertions)</SignAssertions>
            <RequiredAttributes>
"@
        foreach ($Attr in $SPConfig.RequiredAttributes) {
            $ConfigXML += "                <Attribute>$Attr</Attribute>`n"
        }
        $ConfigXML += @"
            </RequiredAttributes>
        </ServiceProvider>
"@
    }
    
    $ConfigXML += @"
    </ServiceProviders>
    <SecurityPolicies>
        <SessionTimeout>$($SSOConfig.SecurityPolicies.SessionTimeout)</SessionTimeout>
        <RequireSignedRequests>$($SSOConfig.SecurityPolicies.RequireSignedRequests)</RequireSignedRequests>
        <RequireEncryptedAssertions>$($SSOConfig.SecurityPolicies.RequireEncryptedAssertions)</RequireEncryptedAssertions>
        <AllowedClockSkew>$($SSOConfig.SecurityPolicies.AllowedClockSkew)</AllowedClockSkew>
        <MaxAssertionAge>$($SSOConfig.SecurityPolicies.MaxAssertionAge)</MaxAssertionAge>
    </SecurityPolicies>
</SSOConfiguration>
"@
    
    # Save configuration
    $ConfigDir = Split-Path $ConfigurationPath
    if (!(Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    $ConfigXML | Out-File -FilePath $ConfigurationPath -Encoding UTF8
    
    Write-Host "SSO Configuration saved to: $ConfigurationPath" -ForegroundColor Green
    Write-Host "Configured Service Providers: $($ServiceProviders.Count)" -ForegroundColor White
}
```

## Role-Based Access Control (RBAC)

### Advanced RBAC Framework

```powershell
function Deploy-RBACFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = "C:\IAM\RBAC\Framework.json"
    )
    
    $RBACFramework = @{
        Roles = @{
            "SystemAdministrator" = @{
                Description = "Full system administration privileges"
                Permissions = @(
                    "System.FullControl",
                    "User.Create", "User.Read", "User.Update", "User.Delete",
                    "Group.Create", "Group.Read", "Group.Update", "Group.Delete",
                    "Policy.Create", "Policy.Read", "Policy.Update", "Policy.Delete",
                    "Security.Audit", "Security.Configure"
                )
                Constraints = @{
                    TimeRestriction = $false
                    IPRestriction = $false
                    ApprovalRequired = $true
                    SessionDuration = 480  # 8 hours
                    RequiredMFA = @("TOTP", "Hardware")
                }
                InheritedRoles = @()
            }
            
            "SecurityAnalyst" = @{
                Description = "Security monitoring and incident response"
                Permissions = @(
                    "Security.Read", "Security.Audit",
                    "Log.Read", "Event.Read",
                    "User.Read", "Group.Read",
                    "Report.Generate", "Alert.Manage"
                )
                Constraints = @{
                    TimeRestriction = $true
                    AllowedHours = @{ Start = 6; End = 22 }
                    IPRestriction = $true
                    AllowedNetworks = @("10.0.0.0/8", "192.168.0.0/16")
                    ApprovalRequired = $false
                    SessionDuration = 240  # 4 hours
                    RequiredMFA = @("TOTP")
                }
                InheritedRoles = @("BaseUser")
            }
            
            "HelpDeskTier1" = @{
                Description = "Basic user support and password resets"
                Permissions = @(
                    "User.Read", "User.UnlockAccount", "User.ResetPassword",
                    "Group.Read",
                    "Ticket.Create", "Ticket.Update"
                )
                Constraints = @{
                    TimeRestriction = $true
                    AllowedHours = @{ Start = 8; End = 17 }
                    IPRestriction = $true
                    AllowedNetworks = @("10.1.0.0/24")
                    ApprovalRequired = $false
                    SessionDuration = 480  # 8 hours
                    RequiredMFA = @("SMS", "Email")
                }
                InheritedRoles = @("BaseUser")
            }
            
            "HelpDeskTier2" = @{
                Description = "Advanced user support and group management"
                Permissions = @(
                    "User.Read", "User.Create", "User.Update", "User.UnlockAccount", "User.ResetPassword",
                    "Group.Read", "Group.Update", "Group.AddMember", "Group.RemoveMember",
                    "Computer.Read", "Computer.Reset",
                    "Ticket.Create", "Ticket.Update", "Ticket.Escalate"
                )
                Constraints = @{
                    TimeRestriction = $true
                    AllowedHours = @{ Start = 7; End = 19 }
                    IPRestriction = $true
                    AllowedNetworks = @("10.1.0.0/24")
                    ApprovalRequired = $false
                    SessionDuration = 480  # 8 hours
                    RequiredMFA = @("TOTP", "Push")
                }
                InheritedRoles = @("HelpDeskTier1")
            }
            
            "BaseUser" = @{
                Description = "Standard user access rights"
                Permissions = @(
                    "Profile.Read", "Profile.Update",
                    "File.Read", "File.Write",
                    "Application.Access"
                )
                Constraints = @{
                    TimeRestriction = $false
                    IPRestriction = $false
                    ApprovalRequired = $false
                    SessionDuration = 480  # 8 hours
                    RequiredMFA = @()
                }
                InheritedRoles = @()
            }
        }
        
        Resources = @{
            "ActiveDirectory" = @{
                Type = "Directory"
                Permissions = @("User.Create", "User.Read", "User.Update", "User.Delete", "Group.Create", "Group.Read", "Group.Update", "Group.Delete")
                AccessPattern = "LDAP"
            }
            
            "SecurityLogs" = @{
                Type = "LogStore"
                Permissions = @("Log.Read", "Event.Read", "Security.Audit")
                AccessPattern = "EventLog"
            }
            
            "FileServer" = @{
                Type = "FileSystem"
                Permissions = @("File.Read", "File.Write", "File.Delete", "File.Execute")
                AccessPattern = "NTFS"
            }
            
            "Applications" = @{
                Type = "ApplicationSuite"
                Permissions = @("Application.Access", "Application.Configure")
                AccessPattern = "SAML"
            }
        }
        
        PolicyEngine = @{
            DefaultDeny = $true
            CombinePermissions = "Union"  # Union, Intersection, Deny-Override
            InheritanceModel = "Hierarchical"
            AuditAllAccess = $true
            CacheTimeout = 300  # 5 minutes
        }
    }
    
    # Save RBAC framework configuration
    $ConfigDir = Split-Path $ConfigPath
    if (!(Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    $RBACFramework | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    Write-Host "RBAC Framework deployed to: $ConfigPath" -ForegroundColor Green
    Write-Host "Roles configured: $($RBACFramework.Roles.Count)" -ForegroundColor White
    Write-Host "Resources defined: $($RBACFramework.Resources.Count)" -ForegroundColor White
}

function Test-UserAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [string]$Resource,
        
        [Parameter(Mandatory)]
        [string]$Permission,
        
        [Parameter()]
        [string]$ConfigPath = "C:\IAM\RBAC\Framework.json"
    )
    
    if (!(Test-Path $ConfigPath)) {
        Write-Error "RBAC configuration not found. Run Deploy-RBACFramework first."
        return
    }
    
    try {
        $RBACConfig = Get-Content $ConfigPath | ConvertFrom-Json
        
        # Get user's roles
        $User = Get-ADUser -Identity $UserName -Properties MemberOf
        $UserGroups = $User.MemberOf | ForEach-Object { (Get-ADGroup -Identity $_).Name }
        
        # Map groups to roles (this would be configurable)
        $UserRoles = @()
        foreach ($Group in $UserGroups) {
            switch ($Group) {
                "Domain Admins" { $UserRoles += "SystemAdministrator" }
                "Security Team" { $UserRoles += "SecurityAnalyst" }
                "Help Desk L1" { $UserRoles += "HelpDeskTier1" }
                "Help Desk L2" { $UserRoles += "HelpDeskTier2" }
                default { $UserRoles += "BaseUser" }
            }
        }
        
        # Remove duplicates
        $UserRoles = $UserRoles | Select-Object -Unique
        
        # Evaluate access
        $AccessGranted = $false
        $GrantingRole = $null
        $AppliedConstraints = @()
        
        foreach ($RoleName in $UserRoles) {
            if ($RBACConfig.Roles.$RoleName) {
                $Role = $RBACConfig.Roles.$RoleName
                
                # Check direct permissions
                if ($Permission -in $Role.Permissions -or "System.FullControl" -in $Role.Permissions) {
                    $AccessGranted = $true
                    $GrantingRole = $RoleName
                    $AppliedConstraints += $Role.Constraints
                    break
                }
                
                # Check inherited permissions
                foreach ($InheritedRole in $Role.InheritedRoles) {
                    $ParentRole = $RBACConfig.Roles.$InheritedRole
                    if ($ParentRole -and ($Permission -in $ParentRole.Permissions)) {
                        $AccessGranted = $true
                        $GrantingRole = "$RoleName (inherited from $InheritedRole)"
                        $AppliedConstraints += $Role.Constraints
                        $AppliedConstraints += $ParentRole.Constraints
                        break
                    }
                }
                
                if ($AccessGranted) { break }
            }
        }
        
        # Evaluate constraints
        $ConstraintViolations = @()
        foreach ($Constraint in $AppliedConstraints) {
            if ($Constraint.TimeRestriction -and $Constraint.AllowedHours) {
                $CurrentHour = (Get-Date).Hour
                if ($CurrentHour -lt $Constraint.AllowedHours.Start -or $CurrentHour -gt $Constraint.AllowedHours.End) {
                    $ConstraintViolations += "Time restriction: Current hour $CurrentHour is outside allowed hours $($Constraint.AllowedHours.Start)-$($Constraint.AllowedHours.End)"
                }
            }
            
            if ($Constraint.IPRestriction -and $Constraint.AllowedNetworks) {
                # This would check current user IP against allowed networks
                # Implementation depends on your network configuration
            }
            
            if ($Constraint.ApprovalRequired) {
                $ConstraintViolations += "Approval required for this access"
            }
        }
        
        # Generate access decision
        $AccessDecision = [PSCustomObject]@{
            UserName = $UserName
            Resource = $Resource
            Permission = $Permission
            AccessGranted = $AccessGranted -and ($ConstraintViolations.Count -eq 0)
            GrantingRole = $GrantingRole
            UserRoles = $UserRoles
            ConstraintViolations = $ConstraintViolations
            Timestamp = Get-Date
            DecisionId = [Guid]::NewGuid().ToString()
        }
        
        # Log access decision
        $LogEntry = @{
            Timestamp = Get-Date
            User = $UserName
            Resource = $Resource
            Permission = $Permission
            Decision = if ($AccessDecision.AccessGranted) { "ALLOW" } else { "DENY" }
            GrantingRole = $GrantingRole
            Violations = $ConstraintViolations
            DecisionId = $AccessDecision.DecisionId
        }
        
        $LogPath = "C:\IAM\Logs\AccessDecisions-$(Get-Date -Format 'yyyyMM').log"
        $LogDir = Split-Path $LogPath
        if (!(Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        }
        
        $LogEntry | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append -Encoding UTF8
        
        return $AccessDecision
    }
    catch {
        Write-Error "Failed to evaluate user access: $($_.Exception.Message)"
    }
}
```

## Identity Governance and Compliance

### Access Certification and Review

```powershell
function Start-AccessCertificationCampaign {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CampaignName,
        
        [Parameter()]
        [string[]]$TargetGroups = @(),
        
        [Parameter()]
        [int]$DurationDays = 30,
        
        [Parameter()]
        [string[]]$Reviewers = @(),
        
        [Parameter()]
        [string]$ReportPath = "C:\IAM\AccessReviews"
    )
    
    $Campaign = @{
        CampaignId = [Guid]::NewGuid().ToString()
        Name = $CampaignName
        StartDate = Get-Date
        EndDate = (Get-Date).AddDays($DurationDays)
        Status = "Active"
        TargetGroups = $TargetGroups
        Reviewers = $Reviewers
        CreatedBy = $env:USERNAME
        ReviewItems = @()
        CompletionRate = 0
        Statistics = @{
            TotalItems = 0
            ReviewedItems = 0
            CertifiedItems = 0
            RevokedItems = 0
            PendingItems = 0
        }
    }
    
    # Generate review items
    foreach ($GroupName in $TargetGroups) {
        try {
            $Group = Get-ADGroup -Identity $GroupName -Properties Description, ManagedBy
            $Members = Get-ADGroupMember -Identity $Group -Recursive
            
            foreach ($Member in $Members) {
                if ($Member.objectClass -eq 'user') {
                    $User = Get-ADUser -Identity $Member.SamAccountName -Properties Department, Manager, LastLogonDate, PasswordLastSet
                    
                    $ReviewItem = @{
                        ItemId = [Guid]::NewGuid().ToString()
                        UserName = $User.SamAccountName
                        DisplayName = $User.Name
                        Department = $User.Department
                        Manager = if ($User.Manager) { (Get-ADUser -Identity $User.Manager).Name } else { "N/A" }
                        GroupName = $GroupName
                        GroupDescription = $Group.Description
                        LastLogon = $User.LastLogonDate
                        PasswordLastSet = $User.PasswordLastSet
                        AccessRisk = Get-AccessRiskScore -User $User -Group $Group
                        Status = "Pending"
                        ReviewDate = $null
                        ReviewedBy = $null
                        Decision = $null
                        Comments = $null
                        DueDate = (Get-Date).AddDays($DurationDays)
                    }
                    
                    $Campaign.ReviewItems += $ReviewItem
                }
            }
        }
        catch {
            Write-Warning "Failed to process group $GroupName : $($_.Exception.Message)"
        }
    }
    
    $Campaign.Statistics.TotalItems = $Campaign.ReviewItems.Count
    $Campaign.Statistics.PendingItems = $Campaign.ReviewItems.Count
    
    # Save campaign
    $CampaignFile = Join-Path $ReportPath "$($Campaign.CampaignId).json"
    $CampaignDir = Split-Path $CampaignFile
    if (!(Test-Path $CampaignDir)) {
        New-Item -ItemType Directory -Path $CampaignDir -Force | Out-Null
    }
    
    $Campaign | ConvertTo-Json -Depth 10 | Out-File -FilePath $CampaignFile -Encoding UTF8
    
    # Generate reviewer assignments
    $ReviewerAssignments = @{}
    $ItemsPerReviewer = [math]::Ceiling($Campaign.ReviewItems.Count / $Reviewers.Count)
    
    for ($i = 0; $i -lt $Campaign.ReviewItems.Count; $i++) {
        $ReviewerIndex = [math]::Floor($i / $ItemsPerReviewer)
        if ($ReviewerIndex -ge $Reviewers.Count) {
            $ReviewerIndex = $Reviewers.Count - 1
        }
        
        $Reviewer = $Reviewers[$ReviewerIndex]
        if (!$ReviewerAssignments.ContainsKey($Reviewer)) {
            $ReviewerAssignments[$Reviewer] = @()
        }
        
        $ReviewerAssignments[$Reviewer] += $Campaign.ReviewItems[$i]
    }
    
    # Send review notifications
    foreach ($Reviewer in $ReviewerAssignments.Keys) {
        $AssignedItems = $ReviewerAssignments[$Reviewer]
        Send-AccessReviewNotification -Reviewer $Reviewer -Campaign $Campaign -ReviewItems $AssignedItems
    }
    
    Write-Host "Access certification campaign '$CampaignName' started" -ForegroundColor Green
    Write-Host "Campaign ID: $($Campaign.CampaignId)" -ForegroundColor White
    Write-Host "Total review items: $($Campaign.Statistics.TotalItems)" -ForegroundColor White
    Write-Host "Duration: $DurationDays days" -ForegroundColor White
    
    return $Campaign
}

function Get-AccessRiskScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        
        [Parameter(Mandatory)]
        [Microsoft.ActiveDirectory.Management.ADGroup]$Group
    )
    
    $RiskScore = 0
    
    # Inactive user risk
    if ($User.LastLogonDate -lt (Get-Date).AddDays(-90)) {
        $RiskScore += 30
    }
    elseif ($User.LastLogonDate -lt (Get-Date).AddDays(-30)) {
        $RiskScore += 15
    }
    
    # Password age risk
    if ($User.PasswordLastSet -lt (Get-Date).AddDays(-180)) {
        $RiskScore += 20
    }
    elseif ($User.PasswordLastSet -lt (Get-Date).AddDays(-90)) {
        $RiskScore += 10
    }
    
    # Group privilege level
    $HighPrivilegeGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")
    if ($Group.Name -in $HighPrivilegeGroups) {
        $RiskScore += 25
    }
    
    # Orphaned account (no manager)
    if (!$User.Manager) {
        $RiskScore += 15
    }
    
    # Account disabled but still in group
    if (!$User.Enabled) {
        $RiskScore += 40
    }
    
    # Classify risk level
    $RiskLevel = switch ($RiskScore) {
        {$_ -ge 60} { "Critical" }
        {$_ -ge 40} { "High" }
        {$_ -ge 20} { "Medium" }
        default { "Low" }
    }
    
    return @{
        Score = $RiskScore
        Level = $RiskLevel
    }
}

function Send-AccessReviewNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Reviewer,
        
        [Parameter(Mandatory)]
        [hashtable]$Campaign,
        
        [Parameter(Mandatory)]
        [array]$ReviewItems
    )
    
    try {
        $ReviewerUser = Get-ADUser -Identity $Reviewer -Properties EmailAddress
        
        if ($ReviewerUser.EmailAddress) {
            $Subject = "Access Review Required: $($Campaign.Name)"
            
            $Body = @"
You have been assigned $($ReviewItems.Count) items to review in the access certification campaign: $($Campaign.Name)

Campaign Details:
- Campaign ID: $($Campaign.CampaignId)
- Due Date: $($Campaign.EndDate)
- Total Items: $($Campaign.Statistics.TotalItems)

Your Review Items:
"@
            
            foreach ($Item in ($ReviewItems | Select-Object -First 10)) {
                $Body += "`n- $($Item.DisplayName) ($($Item.UserName)) - Access to $($Item.GroupName)"
            }
            
            if ($ReviewItems.Count -gt 10) {
                $Body += "`n... and $($ReviewItems.Count - 10) more items"
            }
            
            $Body += @"

To complete your review:
1. Log into the IAM portal at https://iam.company.com
2. Navigate to Access Reviews > Pending Reviews
3. Review each item and make certification decisions
4. Complete all reviews before the due date

If you have questions, contact the Identity Team at identity@company.com
"@
            
            Send-MailMessage -From "identity@company.com" -To $ReviewerUser.EmailAddress -Subject $Subject -Body $Body -SmtpServer "smtp.company.com"
        }
    }
    catch {
        Write-Warning "Failed to send notification to $Reviewer : $($_.Exception.Message)"
    }
}
```

## Related Topics

- [Active Directory Security](../../../services/activedirectory/Security/index.md)
- [Privileged Access Management](../../../services/activedirectory/privileged-access/index.md)
- [Windows Infrastructure Security](../../windows/security/index.md)
- [Network Security](../../networking/security/index.md)
- [Compliance and Auditing](../compliance/index.md)
