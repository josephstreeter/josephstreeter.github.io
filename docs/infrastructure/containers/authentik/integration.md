---
title: "Authentik Application Integration and User Management"
description: "Integrating applications (SAML, OAuth2, OIDC, LDAP) and managing users and groups"
category: "infrastructure"
author: "Joseph Streeter"
ms.date: 2026-07-17
---

## Application Integration

### Protocol Support and Implementation

#### SAML 2.0 Integration

```xml
<!-- SAML Service Provider configuration -->
<saml:Provider
    entityID="https://app.example.com"
    protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    
    <saml:SPSSODescriptor>
        <saml:AssertionConsumerService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location="https://app.example.com/saml/acs/"
            index="0" />
            
        <saml:SingleLogoutService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
            Location="https://app.example.com/saml/sls/" />
    </saml:SPSSODescriptor>
</saml:Provider>
```

#### OAuth2/OIDC Configuration

```json
{
  "client_id": "example-app",
  "client_secret": "your-client-secret",
  "authorization_endpoint": "https://auth.example.com/application/o/authorize/",
  "token_endpoint": "https://auth.example.com/application/o/token/",
  "userinfo_endpoint": "https://auth.example.com/application/o/userinfo/",
  "jwks_uri": "https://auth.example.com/application/o/example-app/jwks/",
  "scopes": ["openid", "email", "profile"],
  "response_types": ["code"],
  "grant_types": ["authorization_code", "refresh_token"],
  "redirect_uris": ["https://app.example.com/callback"]
}
```

### Application Templates

#### Grafana Integration

```powershell
function Configure-GrafanaAuthentik
{
    param(
        [Parameter(Mandatory)]
        [string]$GrafanaUrl,
        [Parameter(Mandatory)]
        [string]$AuthentikUrl,
        [string]$ClientId = "grafana",
        [string[]]$AdminGroups = @("grafana-admins")
    )
    
    Write-Host "Configuring Grafana with Authentik OIDC" -ForegroundColor Cyan
    
    # Grafana configuration
    $grafanaConfig = @"
[auth.generic_oauth]
enabled = true
name = Authentik
client_id = $ClientId
client_secret = \$__file{/etc/grafana/oauth_secret}
scopes = openid profile email
auth_url = $AuthentikUrl/application/o/authorize/
token_url = $AuthentikUrl/application/o/token/
api_url = $AuthentikUrl/application/o/userinfo/
allow_sign_up = true
auto_login = false
role_attribute_path = contains(groups[*], 'grafana-admins') && 'Admin' || contains(groups[*], 'grafana-editors') && 'Editor' || 'Viewer'
role_attribute_strict = false
"@
    
    Write-Host "Grafana OAuth configuration:" -ForegroundColor Yellow
    Write-Host $grafanaConfig -ForegroundColor White
    
    return @{
        Config = $grafanaConfig
        ClientId = $ClientId
        RedirectUri = "$GrafanaUrl/login/generic_oauth"
    }
}
```

#### Proxmox Integration

```yaml
# Proxmox OIDC configuration
proxmox_oidc:
  realm: "authentik"
  client_id: "proxmox"
  client_key: "your-client-secret"
  issuer_url: "https://auth.example.com/application/o/proxmox/"
  scopes: "openid profile email"
  username_claim: "preferred_username"
  prompt: "login"
```

---

## User and Group Management

### User Lifecycle Management

#### Automated User Provisioning

```powershell
function New-AuthentikUser
{
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter(Mandatory)]
        [string]$Email,
        [string]$FirstName,
        [string]$LastName,
        [string[]]$Groups = @(),
        [string]$AuthentikUrl,
        [string]$ApiToken,
        [switch]$SendWelcomeEmail
    )
    
    $headers = @{
        'Authorization' = "Bearer $ApiToken"
        'Content-Type' = 'application/json'
    }
    
    $userData = @{
        username = $Username
        email = $Email
        first_name = $FirstName
        last_name = $LastName
        is_active = $true
        groups = $Groups
    } | ConvertTo-Json
    
    try
    {
        $response = Invoke-RestMethod -Uri "$AuthentikUrl/api/v3/core/users/" -Method POST -Headers $headers -Body $userData
        
        Write-Host "User created successfully: $Username" -ForegroundColor Green
        
        if ($SendWelcomeEmail)
        {
            # Trigger welcome email
            $emailData = @{
                user = $response.pk
                template = "welcome"
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri "$AuthentikUrl/api/v3/stages/email/send/" -Method POST -Headers $headers -Body $emailData
            Write-Host "Welcome email sent to $Email" -ForegroundColor Green
        }
        
        return $response
    }
    catch
    {
        Write-Error "Failed to create user: $($_.Exception.Message)"
        return $null
    }
}
```

### Group Management and Policies

#### Dynamic Group Assignment

```python
# Dynamic group assignment based on attributes
group_policies = {
    "developers": {
        "conditions": [
            {"attribute": "department", "value": "Engineering"},
            {"attribute": "job_title", "contains": "Developer"}
        ],
        "permissions": [
            "access_development_apps",
            "code_repository_access"
        ]
    },
    "admins": {
        "conditions": [
            {"attribute": "is_superuser", "value": True}
        ],
        "permissions": [
            "admin_panel_access",
            "user_management",
            "system_configuration"
        ]
    }
}
```

---

## Navigation

[◄ Configuration and Flows](configuration.md) · [Authentik Overview](index.md) · [Security and Monitoring ►](security.md)
