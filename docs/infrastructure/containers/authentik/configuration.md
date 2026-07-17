---
title: "Authentik Configuration and Authentication Flows"
description: "Configuring Authentik and building authentication and authorization flows"
category: "infrastructure"
author: "Joseph Streeter"
ms.date: 2026-07-17
---

## Configuration and Setup

### Initial Configuration

#### First-Time Setup Process

1. **Access the Web Interface**

   ```bash
   # After deployment, access Authentik
   http://localhost:9000
   # or
   https://your-domain.com
   ```

2. **Initial Admin Account**

   ```bash
   # Get default admin credentials
   docker-compose exec authentik-server ak create_admin_group
   docker-compose exec authentik-server ak create_admin_user
   ```

#### Core Configuration Steps

##### 1. Basic System Settings

```yaml
# System settings configuration
authentik:
  default_user_change_email: true
  default_user_change_name: true
  default_user_change_username: true
  avatars: "gravatar"
  footer_links:
    - name: "Documentation"
      href: "https://docs.goauthentik.io"
  
  # Branding configuration
  ui:
    theme: "automatic"
    locale: "en"
  
  # Security settings
  security:
    secret_key: "your-secret-key"
    csrf:
      trusted_origins:
        - "https://auth.example.com"
```

##### 2. Email Configuration

```yaml
# Email settings for notifications
email:
  host: "smtp.example.com"
  port: 587
  username: "authentik@example.com"
  password: "your-smtp-password"
  use_tls: true
  use_ssl: false
  timeout: 30
  from: "Authentik <authentik@example.com>"
  
  # Email templates
  templates:
    account_confirmation: "email/account_confirmation.html"
    password_reset: "email/password_reset.html"
    invitation: "email/invitation.html"
```

### Advanced Configuration

#### Environment Variables Reference

```bash
# Core Configuration
AUTHENTIK_SECRET_KEY=your-secret-key                    # Required: Encryption key
AUTHENTIK_LOG_LEVEL=info                               # Options: debug, info, warning, error
AUTHENTIK_ERROR_REPORTING__ENABLED=false              # Disable error reporting to Authentik

# Database Configuration
AUTHENTIK_POSTGRESQL__HOST=postgres                    # Database host
AUTHENTIK_POSTGRESQL__PORT=5432                       # Database port
AUTHENTIK_POSTGRESQL__NAME=authentik                  # Database name
AUTHENTIK_POSTGRESQL__USER=authentik                  # Database user
AUTHENTIK_POSTGRESQL__PASSWORD=your-password          # Database password
AUTHENTIK_POSTGRESQL__USE_PGBOUNCER=false            # Enable connection pooling

# Redis Configuration
AUTHENTIK_REDIS__HOST=redis                           # Redis host
AUTHENTIK_REDIS__PORT=6379                           # Redis port
AUTHENTIK_REDIS__DB=0                               # Redis database number
AUTHENTIK_REDIS__PASSWORD=                          # Redis password (if required)

# Email Configuration
AUTHENTIK_EMAIL__HOST=smtp.example.com               # SMTP server
AUTHENTIK_EMAIL__PORT=587                           # SMTP port
AUTHENTIK_EMAIL__USERNAME=authentik@example.com     # SMTP username
AUTHENTIK_EMAIL__PASSWORD=your-smtp-password        # SMTP password
AUTHENTIK_EMAIL__USE_TLS=true                       # Enable TLS
AUTHENTIK_EMAIL__USE_SSL=false                      # Enable SSL
AUTHENTIK_EMAIL__TIMEOUT=10                         # Connection timeout
AUTHENTIK_EMAIL__FROM=Authentik <authentik@example.com>  # From address

# Web Configuration
AUTHENTIK_LISTEN__HTTP=0.0.0.0:9000                # HTTP bind address
AUTHENTIK_LISTEN__HTTPS=0.0.0.0:9443               # HTTPS bind address
AUTHENTIK_LISTEN__METRICS=0.0.0.0:9300             # Metrics bind address
AUTHENTIK_WEB__WORKERS=2                           # Number of web workers

# Security Configuration
AUTHENTIK_COOKIE__DOMAIN=.example.com               # Cookie domain
AUTHENTIK_DISABLE_UPDATE_CHECK=true                # Disable update notifications
AUTHENTIK_AVATARS=gravatar                         # Avatar provider
```

---

## Authentication Flows

Authentik uses a flexible flow system that allows you to customize the authentication experience for different scenarios and applications.

### Flow Types and Configuration

#### Core Flow Types

| Flow Type | Purpose | Use Cases |
| --------- | ------- | --------- |
| **Authentication** | User login process | SSO, multi-step authentication |
| **Authorization** | Access control decisions | Policy enforcement, consent |
| **Invalidation** | Session termination | Logout, account suspension |
| **Enrollment** | User registration | Self-service registration |
| **Recovery** | Password reset | Forgotten password recovery |
| **Unenrollment** | Account deletion | GDPR compliance, self-service |

#### Default Authentication Flow

```yaml
# Example authentication flow configuration
name: "default-authentication-flow"
title: "Welcome to Example Corp"
designation: "authentication"
policy_engine_mode: "any"

stages:
  - identification:
      user_fields: ["username", "email"]
      password_fields: ["password"]
      sources: ["internal"]
      
  - password:
      backends: ["internal", "ldap"]
      failed_attempts_before_cancel: 5
      
  - mfa:
      device_classes: ["totp", "webauthn", "sms"]
      configuration_stages: ["mfa-setup"]
      
  - user_login:
      session_duration: "hours=8"
      remember_me_offset: "days=30"
```

### Multi-Factor Authentication Setup

#### TOTP Configuration

```python
# TOTP authenticator configuration
from authentik.stages.authenticator_totp.models import TOTPDevice

# Configure TOTP settings
totp_config = {
    'issuer': 'Example Corp',
    'period': 30,
    'algorithm': 'SHA1',
    'digits': 6,
    'drift': 1
}
```

#### WebAuthn/FIDO2 Setup

```yaml
# WebAuthn stage configuration
webauthn_stage:
  user_verification: "preferred"
  authenticator_attachment: "cross-platform"
  resident_key_requirement: "discouraged"
  allowed_devices:
    - "usb"
    - "nfc"
    - "ble"
    - "internal"
```

### Custom Authentication Flows

#### Enterprise SSO Flow

```yaml
# Enterprise SSO with step-up authentication
enterprise_sso_flow:
  name: "Enterprise SSO"
  stages:
    - ldap_identification:
        sources: ["corporate-ldap"]
        password_backends: ["ldap"]
        
    - password_validation:
        backend: "ldap"
        
    - risk_assessment:
        policies: ["location-based", "device-trust"]
        
    - conditional_mfa:
        conditions:
          - high_risk_score: "required"
          - admin_group: "required"
          - external_network: "required"
          
    - authorization:
        policies: ["group-membership", "time-based"]
        
    - user_login:
        session_duration: "hours=4"
```

---

## Navigation

[◄ Installation and Deployment](installation.md) · [Authentik Overview](index.md) · [Integration and Users ►](integration.md)
