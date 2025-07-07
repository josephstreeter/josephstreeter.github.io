---
title: "Documentation Templates"
description: "Ready-to-use templates for consistent documentation creation across different content types"
tags: ["templates", "documentation", "standards", "docfx"]
category: "development"
difficulty: "beginner"
last_updated: "2025-07-06"
---

## Documentation Templates

Templates provide a consistent starting point for creating different types of documentation. This collection includes templates for common documentation scenarios, ensuring uniformity and completeness across your Documentation as Code implementation.

## Template Categories

### Content Templates

**Purpose:** Standardize structure and format for different content types

**Benefits:**

- Consistent user experience
- Faster content creation
- Complete coverage of required elements
- Improved quality and completeness

### DocFX Templates

**Purpose:** Customize the appearance and functionality of generated sites

**Benefits:**

- Brand consistency
- Enhanced user interface
- Custom functionality
- Responsive design

## Documentation Content Templates

### Tutorial Template

Create step-by-step learning experiences:

````markdown
---
title: "How to [Accomplish Task]"
description: "Step-by-step guide to [specific outcome] using [technology/method]"
tags: ["tutorial", "how-to", "[technology]"]
category: "tutorials"
difficulty: "beginner|intermediate|advanced"
estimated_time: "[X] minutes"
prerequisites: ["Prerequisite 1", "Prerequisite 2"]
author: "[Author Name]"
last_updated: "YYYY-MM-DD"
---

## Overview

Brief description of what the user will learn and accomplish by following this tutorial.

### What You'll Learn

- Learning objective 1
- Learning objective 2
- Learning objective 3

### What You'll Build

Description of the final outcome or deliverable.

## Prerequisites

Before starting this tutorial, ensure you have:

- [ ] Prerequisite 1 with [link](link-to-setup)
- [ ] Prerequisite 2 with minimum version X.X
- [ ] Basic understanding of [relevant concept]

## Getting Started

### Step 1: [Initial Setup]

Clear, actionable instructions for the first step.

```bash
# Include relevant code examples
command-or-code-example
```

**Expected result:** Describe what should happen.

### Step 2: [Next Action]

Continue with sequential steps, each building on the previous.

```bash
# More code examples with explanations
example-code
```

**Tip:** Include helpful tips and best practices.

### Step 3: [Further Actions]

Continue the pattern with clear steps and examples.

## Verification

Describe how to verify the tutorial was completed successfully:

1. Check that [specific outcome] occurred
2. Verify [another measurable result]
3. Test [functionality or feature]

## Troubleshooting

### Common Issue 1

**Problem:** Description of the issue and symptoms.

**Solution:** Step-by-step resolution.

### Common Issue 2

**Problem:** Another common problem.

**Solution:** Clear resolution steps.

## Next Steps

- [Related tutorial or concept](link)
- [Advanced topics](link)
- [Additional resources](link)

## Additional Resources

- [External documentation](link)
- [Community resources](link)
- [Related tools](link)

---

*Last updated: [Date] | Estimated completion time: [X minutes]*
````

### API Reference Template

Document APIs comprehensively:

````markdown
---
title: "[API Name] Reference"
description: "Complete API reference for [API Name] including endpoints, parameters, and examples"
tags: ["api", "reference", "[api-name]"]
category: "reference"
difficulty: "intermediate"
api_version: "v1.0"
last_updated: "YYYY-MM-DD"
---

## [API Name] API Reference

Brief description of the API's purpose and capabilities.

### Base URL

```text
https://api.example.com/v1
```

### Authentication

Description of authentication method with examples:

```http
Authorization: Bearer YOUR_API_TOKEN
```

## Endpoints

### GET /endpoint

Brief description of what this endpoint does.

**URL:** `/endpoint`

**Method:** `GET`

**Auth required:** Yes/No

**Permissions required:** Permission level

#### Parameters

| Parameter | Type   | Required | Description | Default |
|-----------|--------|----------|-------------|---------|
| param1    | string | Yes      | Description | N/A     |
| param2    | number | No       | Description | 10      |

#### Query Parameters

| Parameter | Type   | Required | Description | Example |
|-----------|--------|----------|-------------|---------|
| filter    | string | No       | Filter results | `active` |
| page      | number | No       | Page number | `1` |

#### Request Example

```http
GET /endpoint?filter=active&page=1
Authorization: Bearer YOUR_TOKEN
```

#### Response

**Success Response:**

**Code:** `200 OK`

**Content example:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "Example Item",
      "status": "active"
    }
  ],
  "pagination": {
    "page": 1,
    "total_pages": 5,
    "total_items": 50
  }
}
```

**Error Response:**

**Code:** `400 Bad Request`

**Content:**

```json
{
  "error": "Invalid parameter",
  "message": "The 'filter' parameter must be one of: active, inactive"
}
```

### POST /endpoint

Documentation for POST endpoints follows similar pattern.

#### Request Body

```json
{
  "name": "string (required)",
  "description": "string (optional)",
  "settings": {
    "enabled": "boolean (required)",
    "value": "number (optional)"
  }
}
```

## Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| 400  | Bad Request | Check request parameters |
| 401  | Unauthorized | Verify authentication token |
| 404  | Not Found | Check endpoint URL |
| 500  | Server Error | Contact support |

## Rate Limiting

- Limit: 1000 requests per hour
- Headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## SDK Examples

### JavaScript

```javascript
const client = new APIClient({
  token: 'YOUR_API_TOKEN',
  baseURL: 'https://api.example.com/v1'
});

const result = await client.get('/endpoint', {
  filter: 'active',
  page: 1
});
```

### Python

```python
import requests

headers = {'Authorization': 'Bearer YOUR_API_TOKEN'}
response = requests.get(
    'https://api.example.com/v1/endpoint',
    headers=headers,
    params={'filter': 'active', 'page': 1}
)
```

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.1    | 2025-07-06 | Added new filter parameter |
| v1.0    | 2025-06-01 | Initial release |

---

*API Version: v1.0 | Last updated: [Date]*
````

### Troubleshooting Template

Systematic problem-solving guides:

````markdown
---
title: "Troubleshooting [Component/Feature]"
description: "Common issues and solutions for [Component/Feature]"
tags: ["troubleshooting", "[component]", "support"]
category: "troubleshooting"
difficulty: "intermediate"
last_updated: "YYYY-MM-DD"
---

## Troubleshooting [Component/Feature]

This guide helps resolve common issues encountered when working with [Component/Feature].

## Quick Diagnostic Checklist

Before diving into specific issues, verify these common requirements:

- [ ] [Basic requirement 1]
- [ ] [Basic requirement 2]
- [ ] [Configuration check]
- [ ] [Permission verification]

## Common Issues

### Issue: [Specific Problem Description]

**Symptoms:**

- Symptom 1
- Symptom 2
- Error message: `"Specific error text"`

**Possible Causes:**

1. **Cause 1:** Brief explanation
2. **Cause 2:** Brief explanation
3. **Cause 3:** Brief explanation

**Solution Steps:**

1. **Check [specific item]:**

   ```bash
   # Diagnostic command
   diagnostic-command --check
   ```

1. **Verify [configuration]:**

   ```yaml
   # Expected configuration
   setting: correct_value
   ```

1. **Restart [service/component]:**

   ```bash
   # Restart command
   service restart component-name
   ```

**Verification:**

Test that the issue is resolved by:

- [ ] Running verification command
- [ ] Checking expected output
- [ ] Confirming normal operation

### Issue: [Another Problem]

Follow the same pattern for additional issues.

## Advanced Diagnostics

### Log Analysis

**Location:** `/path/to/logs/`

**Key log files:**

- `application.log` - Application events
- `error.log` - Error messages
- `access.log` - Access patterns

**Useful log commands:**

```bash
# View recent errors
tail -f /path/to/logs/error.log

# Search for specific issues
grep "ERROR" /path/to/logs/application.log | tail -20

# Monitor real-time logs
journalctl -f -u service-name
```

### Performance Issues

**Monitoring commands:**

```bash
# Check system resources
top
htop
df -h

# Network diagnostics
ping target-host
traceroute target-host
netstat -tulpn
```

**Performance benchmarks:**

- Expected response time: < 200ms
- Memory usage: < 80% of available
- CPU usage: < 75% sustained

## Getting Help

### Before Contacting Support

Gather this information:

1. **Environment details:**
   - Operating system and version
   - Software version
   - Configuration files (sanitized)

2. **Error information:**
   - Complete error messages
   - Steps to reproduce
   - Log files (relevant sections)

3. **Troubleshooting attempted:**
   - Solutions tried
   - Results of diagnostic commands
   - Timeline of issue occurrence

### Support Resources

- [Community Forum](link)
- [Knowledge Base](link)
- [Support Portal](link)
- [Documentation](link)

### Emergency Contacts

- **Critical Issues:** <emergency@support.com>
- **Business Hours:** <support@company.com>
- **Phone Support:** +1-555-0123

---

*Last updated: [Date] | For additional help, contact [support resource]*
````

### Configuration Reference Template

Document configuration options comprehensively:

````markdown
---
title: "[Component] Configuration Reference"
description: "Complete configuration reference for [Component]"
tags: ["configuration", "reference", "[component]"]
category: "reference"
difficulty: "intermediate"
last_updated: "YYYY-MM-DD"
---

## [Component] Configuration Reference

Comprehensive guide to configuring [Component] for optimal performance and functionality.

## Configuration File Structure

**Location:** `/path/to/config/file.yml`

**Format:** YAML/JSON/INI

**Example structure:**

```yaml
# Main configuration file
component:
  name: "example-app"
  version: "1.0.0"
  
  # Server configuration
  server:
    host: "localhost"
    port: 8080
    ssl:
      enabled: false
      cert_path: "/path/to/cert.pem"
      key_path: "/path/to/key.pem"
  
  # Database configuration
  database:
    type: "postgresql"
    host: "db.example.com"
    port: 5432
    name: "app_database"
    username: "app_user"
    password: "${DB_PASSWORD}"
  
  # Application settings
  application:
    debug: false
    log_level: "info"
    features:
      feature1: true
      feature2: false
```

## Configuration Sections

### Server Configuration

**Description:** Web server and network settings

| Setting | Type | Required | Default | Description |
|---------|------|----------|---------|-------------|
| `host` | string | No | `localhost` | Server bind address |
| `port` | number | No | `8080` | Server port number |
| `ssl.enabled` | boolean | No | `false` | Enable HTTPS |
| `ssl.cert_path` | string | Conditional | N/A | SSL certificate path |
| `ssl.key_path` | string | Conditional | N/A | SSL private key path |

**Examples:**

```yaml
# HTTP configuration
server:
  host: "0.0.0.0"
  port: 3000

# HTTPS configuration
server:
  host: "0.0.0.0"
  port: 443
  ssl:
    enabled: true
    cert_path: "/etc/ssl/certs/app.crt"
    key_path: "/etc/ssl/private/app.key"
```

### Database Configuration

**Description:** Database connection and settings

| Setting | Type | Required | Default | Description |
|---------|------|----------|---------|-------------|
| `type` | string | Yes | N/A | Database type |
| `host` | string | Yes | N/A | Database server |
| `port` | number | No | varies | Database port |
| `name` | string | Yes | N/A | Database name |
| `username` | string | Yes | N/A | Database user |
| `password` | string | Yes | N/A | Database password |

**Supported database types:**

- `postgresql`
- `mysql`
- `sqlite`
- `mongodb`

## Environment Variables

**Security best practice:** Use environment variables for sensitive configuration.

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_PASSWORD` | Database password | `secure_password_123` |
| `API_KEY` | External API key | `ak_live_1234567890` |
| `JWT_SECRET` | JWT signing secret | `random_256_bit_key` |

**Usage:**

```bash
# Set environment variables
export DB_PASSWORD="secure_password"
export API_KEY="your_api_key"

# Or use .env file
echo "DB_PASSWORD=secure_password" > .env
echo "API_KEY=your_api_key" >> .env
```

## Validation

**Configuration validation command:**

```bash
# Validate configuration file
component validate --config /path/to/config.yml

# Test configuration with dry-run
component start --dry-run --config /path/to/config.yml
```

**Common validation errors:**

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid YAML syntax` | Malformed YAML | Check indentation and syntax |
| `Missing required field` | Required setting missing | Add required configuration |
| `Invalid value type` | Wrong data type | Check expected type |

## Performance Tuning

### Recommended Settings

**Production environment:**

```yaml
application:
  debug: false
  log_level: "warn"
  
server:
  host: "0.0.0.0"
  port: 8080
  
database:
  pool_size: 20
  connection_timeout: 30
  idle_timeout: 300
```

**Development environment:**

```yaml
application:
  debug: true
  log_level: "debug"
  
server:
  host: "localhost"
  port: 3000
  
database:
  pool_size: 5
  connection_timeout: 10
  idle_timeout: 60
```

### Scaling Considerations

**High-traffic configurations:**

- Increase database pool size
- Enable connection pooling
- Configure load balancing
- Optimize cache settings

## Examples

### Basic Setup

```yaml
# Minimal configuration for getting started
component:
  name: "my-app"
  server:
    port: 8080
  database:
    type: "sqlite"
    name: "app.db"
```

### Production Setup

```yaml
# Production-ready configuration
component:
  name: "production-app"
  version: "2.1.0"
  
  server:
    host: "0.0.0.0"
    port: 8080
    ssl:
      enabled: true
      cert_path: "/etc/ssl/certs/app.crt"
      key_path: "/etc/ssl/private/app.key"
  
  database:
    type: "postgresql"
    host: "prod-db.internal"
    port: 5432
    name: "prod_database"
    username: "prod_user"
    password: "${DB_PASSWORD}"
    pool_size: 25
    connection_timeout: 30
  
  application:
    debug: false
    log_level: "info"
    features:
      analytics: true
      debug_mode: false
      rate_limiting: true
  
  logging:
    file: "/var/log/app/application.log"
    max_size: "100MB"
    max_files: 10
    format: "json"
```

---

*Configuration version: v2.1 | Last updated: [Date]*
````

## DocFX Site Templates

### Custom Theme Template

Create branded documentation sites:

```htmlhtml
<!-- templates/conceptual.html.primary.tmpl -->
{{!Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.}}
{{!include(/^styles/.*/)}}
{{!include(/^fonts/.*/)}}
{{!include(favicon.ico)}}
{{!include(logo.svg)}}
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <title>{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}} {{#_appTitle}}{{{_appTitle}}}{{/_appTitle}}</title>
  <meta name="viewport" content="width=device-width">
  <meta name="title" content="{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}} {{#_appTitle}}{{{_appTitle}}}{{/_appTitle}}">
  <meta name="generator" content="docfx {{_docfxVersion}}">
  {{#_description}}<meta name="description" content="{{_description}}">{{/_description}}
  <link rel="shortcut icon" href="{{_rel}}{{{_appFaviconPath}}}{{^_appFaviconPath}}favicon.ico{{/_appFaviconPath}}">
  <link rel="stylesheet" href="{{_rel}}styles/docfx.vendor.css">
  <link rel="stylesheet" href="{{_rel}}styles/docfx.css">
  <link rel="stylesheet" href="{{_rel}}styles/main.css">
  <meta property="docfx:navrel" content="{{_navRel}}">
  <meta property="docfx:tocrel" content="{{_tocRel}}">
  {{#_enableSearch}}<meta property="docfx:rel" content="{{_rel}}">{{/_enableSearch}}
  {{#_enableNewTab}}<meta property="docfx:newtab" content="true">{{/_enableNewTab}}
</head>
<body data-spy="scroll" data-target="#affix" data-offset="120">
  <div id="wrapper">
    <header>
      {{>partials/navbar}}
    </header>
    {{#_enableSearch}}
    <div class="container body-content">
      {{>partials/searchResults}}
    </div>
    {{/_enableSearch}}
    <div role="main" class="container body-content hide-when-search">
      {{>partials/breadcrumb}}
      <article class="content wrap" id="_content" data-uid="{{uid}}">
        {{!body}}
      </article>
    </div>
    {{>partials/footer}}
  </div>
  {{>partials/scripts}}
</body>
</html>
```

### Navigation Template

```html
<!-- partials/navbar.tmpl -->
<nav id="autocollapse" class="navbar navbar-inverse ng-scope" role="navigation">
  <div class="container">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#navbar">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      {{#_appLogoPath}}
      <a class="navbar-brand" href="{{_appLogoUrl}}{{^_appLogoUrl}}{{_rel}}index.html{{/_appLogoUrl}}">
        <img id="logo" class="svg" src="{{_rel}}{{{_appLogoPath}}}" alt="{{_appName}}" >
      </a>
      {{/_appLogoPath}}
      {{^_appLogoPath}}
      <a class="navbar-brand" href="{{_appLogoUrl}}{{^_appLogoUrl}}{{_rel}}index.html{{/_appLogoUrl}}">{{_appName}}</a>
      {{/_appLogoPath}}
    </div>
    <div class="collapse navbar-collapse" id="navbar">
      <form class="navbar-form navbar-right" role="search" id="search">
        <div class="form-group">
          <input type="text" class="form-control" id="search-query" placeholder="{{__global.search}}" autocomplete="off">
        </div>
      </form>
    </div>
  </div>
</nav>
```

## Template Management

### Organization Structure

```text
templates/
├── content/
│   ├── tutorial.md
│   ├── api-reference.md
│   ├── troubleshooting.md
│   └── configuration.md
├── docfx/
│   ├── conceptual.html.primary.tmpl
│   ├── partials/
│   │   ├── navbar.tmpl
│   │   ├── footer.tmpl
│   │   └── breadcrumb.tmpl
│   └── styles/
│       ├── main.css
│       └── custom.css
└── scripts/
    ├── create-from-template.ps1
    └── validate-template.sh
```

### Template Automation

**PowerShell script for template creation:**

```powershell
# create-from-template.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Variables = @{}
)

$templatePath = "templates/content/$TemplateName.md"

if (!(Test-Path $templatePath)) {
    Write-Error "Template not found: $templatePath"
    exit 1
}

$content = Get-Content $templatePath -Raw

# Replace template variables
foreach ($key in $Variables.Keys) {
    $content = $content -replace "\{\{$key\}\}", $Variables[$key]
}

# Set current date if not specified
$content = $content -replace "\{\{date\}\}", (Get-Date -Format "yyyy-MM-dd")

# Create output directory if needed
$outputDir = Split-Path $OutputPath -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force
}

# Write the new file
Set-Content -Path $OutputPath -Value $content

Write-Host "Created new document from template: $OutputPath"
```

**Usage example:**

```bash
# Create new tutorial
./create-from-template.ps1 -TemplateName "tutorial" -OutputPath "docs/tutorials/new-feature.md" -Variables @{
    title = "How to Use New Feature"
    technology = "Azure App Service"
    difficulty = "intermediate"
    estimated_time = "45 minutes"
}
```

### Template Validation

**Template testing script:**

```bash
#!/bin/bash
# validate-template.sh

TEMPLATE_DIR="templates/content"
ERRORS=0

echo "Validating content templates..."

for template in "$TEMPLATE_DIR"/*.md; do
    echo "Checking $(basename "$template")..."
    
    # Check required front matter
    if ! grep -q "^title:" "$template"; then
        echo "  ❌ Missing 'title' in front matter"
        ((ERRORS++))
    fi
    
    if ! grep -q "^description:" "$template"; then
        echo "  ❌ Missing 'description' in front matter"
        ((ERRORS++))
    fi
    
    # Check for template variables
    if grep -q "{{[^}]*}}" "$template"; then
        echo "  ✅ Contains template variables"
    else
        echo "  ⚠️  No template variables found"
    fi
    
    # Validate markdown syntax
    if command -v markdownlint &> /dev/null; then
        if markdownlint "$template" > /dev/null 2>&1; then
            echo "  ✅ Markdown syntax valid"
        else
            echo "  ❌ Markdown syntax issues"
            ((ERRORS++))
        fi
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "✅ All templates validated successfully"
    exit 0
else
    echo "❌ Found $ERRORS issues"
    exit 1
fi
```

---

*This template collection provides a foundation for consistent, high-quality documentation. Customize templates to match your organization's specific needs and style requirements.*
