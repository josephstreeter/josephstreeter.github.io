---
title: "Template Repository and Automation"
description: "A shared template repository, auto-generated content, and reusable documentation snippets"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "automation", "templates", "snippets"]
category: "development"
last_updated: "2026-08-01"
---
## Template Repository and Automation

Templates only get used if they are easy to reach. This covers publishing them
centrally and generating the parts that can be generated.

### 8.2 Template Repository

**Create a "Documentation Templates" repository:**

**Repository structure:**

```text

documentation-templates/
├── README.md                              # How to use templates
├── Service-Documentation/
│   ├── README-Template.md
│   ├── Architecture-Template.md
│   ├── Runbook-Template.md
│   ├── API-Documentation-Template.md
│   ├── Troubleshooting-Template.md
│   └── .order
├── Project-Wiki/
│   ├── Home-Page-Template.md
│   ├── Service-Catalog-Template.md
│   ├── Team-Directory-Template.md
│   └── Standards-Template.md
├── ADR-Template/
│   └── ADR-Template.md                   # Architecture Decision Record
├── Scripts/
│   ├── scaffold-service-docs.ps1         # Script to create docs from template
│   └── validate-documentation.py
└── .azuredevops/
    └── azure-pipelines-template-publish.yml

```

**Scaffold script example:**

**`Scripts/scaffold-service-docs.ps1`:**

```powershell
<#
.SYNOPSIS
    Scaffolds documentation for a new service using templates
.DESCRIPTION
    Creates a /docs folder in the specified repository with all
    required documentation files from templates
.PARAMETER RepositoryPath
    Path to the repository where docs should be created
.PARAMETER ServiceName
    Name of the service (used to populate templates)
.PARAMETER TeamName
    Name of the team owning this service
.EXAMPLE
    .\scaffold-service-docs.ps1 -RepositoryPath "C:\repos\email-gateway" -ServiceName "Email Gateway" -TeamName "IAM Team"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$TeamName
)

# Validate repository path
if (-not (Test-Path $RepositoryPath)) {
    Write-Error "Repository path does not exist: $RepositoryPath"
    exit 1
}

# Create docs folder structure
$docsPath = Join-Path $RepositoryPath "docs"
New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $docsPath ".attachments") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $docsPath "API") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $docsPath "Operations") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $docsPath "Development") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $docsPath "Integration") -ItemType Directory -Force | Out-Null

Write-Host "✅ Created folder structure in $docsPath"

# Get template path
$templatePath = Split-Path -Parent $PSScriptRoot
$serviceTemplatesPath = Join-Path $templatePath "Service-Documentation"

# Copy and customize templates
$templates = @{
    "README-Template.md" = "README.md"
    "Architecture-Template.md" = "Architecture.md"
    "Runbook-Template.md" = "Operations\Runbook.md"
    "API-Documentation-Template.md" = "API\Overview.md"
    "Troubleshooting-Template.md" = "Operations\Troubleshooting.md"
}

foreach ($template in $templates.Keys) {
    $sourcePath = Join-Path $serviceTemplatesPath $template
    $destPath = Join-Path $docsPath $templates[$template]
    
    # Read template
    $content = Get-Content $sourcePath -Raw
    
    # Replace placeholders
    $content = $content -replace '\[Service Name\]', $ServiceName
    $content = $content -replace '\[Team Name\]', $TeamName
    $content = $content -replace '\[YYYY-MM-DD\]', (Get-Date -Format "yyyy-MM-dd")
    
    # Write file
    Set-Content -Path $destPath -Value $content
    
    Write-Host "✅ Created $($templates[$template])"
}

# Create .order files
$orderFiles = @{
    "" = @("README", "Getting-Started", "Architecture", "API", "Operations", "Development", "Integration")
    "API" = @("Overview", "Authentication", "Endpoints", "Examples")
    "Operations" = @("Deployment", "Configuration", "Monitoring", "Troubleshooting", "Runbook")
    "Development" = @("Local-Setup", "Testing", "Contributing")
    "Integration" = @("Overview")
}

foreach ($folder in $orderFiles.Keys) {
    $orderPath = if ($folder -eq "") { 
        Join-Path $docsPath ".order"
    } else {
        Join-Path (Join-Path $docsPath $folder) ".order"
    }
    
    $orderContent = $orderFiles[$folder] -join "`n"
    Set-Content -Path $orderPath -Value $orderContent
    
    Write-Host "✅ Created .order file in $folder"
}

Write-Host "`n✅ Documentation scaffolding complete!"
Write-Host "Next steps:"
Write-Host "  1. Review and customize the generated documentation"
Write-Host "  2. Add diagrams to .attachments folder"
Write-Host "  3. Publish as code wiki in Azure DevOps"
Write-Host "  4. Add service to service catalog in Project Wiki"
```

**Usage:**

```powershell
# Clone templates repository
git clone https://dev.azure.com/org/project/_git/documentation-templates

# Run scaffold script
cd documentation-templates/Scripts
.\scaffold-service-docs.ps1 `
    -RepositoryPath "C:\repos\my-new-service" `
    -ServiceName "My New Service" `
    -TeamName "Platform Team"
```

### 8.3 Auto-Generated Content

**Some documentation can be generated automatically:**

#### 8.3.1 API Documentation from Code

**For .NET APIs (using Swashbuckle/Swagger):**

```csharp
// In Program.cs or Startup.cs
services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "Email Gateway API", 
        Version = "v1",
        Description = "API for sending email via FortiMail gateway"
    });
    
    // Include XML comments
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    c.IncludeXmlComments(xmlPath);
});

// Enable Swagger UI
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Email Gateway API V1");
});
```

**Generate Markdown from Swagger:**

```bash
# Install swagger-markdown
npm install -g swagger-markdown

# Generate Markdown
swagger-markdown -i swagger.json -o docs/API/Reference.md
```

Or use pipeline to auto-generate (see Section 7.6).

#### 8.3.2 Database Schema Documentation

**Using SchemaSpy or similar tools:**

```yaml
# In CI/CD pipeline
- script: |
    # Generate database documentation
    java -jar schemaspy.jar \
      -t mssql \
      -host db-server \
      -db database-name \
      -u username \
      -p password \
      -o docs/Database
  displayName: 'Generate database schema documentation'
```

#### 8.3.3 Dependency Documentation

**Auto-generate list of dependencies:**

**For .NET:**

```bash
# Generate package list
dotnet list package --include-transitive > docs/Dependencies.txt
```

**For Python:**

```bash
# Generate requirements with versions
pip freeze > docs/requirements.txt
```

**For Node.js:**

```bash
# Generate dependency tree
npm list --depth=0 > docs/dependencies.txt
```

### 8.4 Documentation Snippets

**Use Azure DevOps snippets for common content blocks:**

**Example snippet for "Prerequisites" section:**

```markdown
## Prerequisites

Before proceeding, ensure you have:

- [ ] **Azure Access**: Contributor role on subscription `[subscription-name]`
- [ ] **Repository Access**: Read access to repository `[repo-name]`
- [ ] **Tools Installed**:
  - Azure CLI v2.40+
  - Git v2.30+
  - [Additional tool]
- [ ] **Credentials**: Service principal or user credentials
- [ ] **Network Access**: Connectivity to [environment]

If you don't have the required prerequisites, see Getting Access.
```

**Create snippets in VS Code:**

1. File → Preferences → User Snippets
2. Select Markdown
3. Add snippet:

```json
{
  "Prerequisites Section": {
    "prefix": "prereq",
    "body": [
      "## Prerequisites",
      "",
      "Before proceeding, ensure you have:",
      "",
      "- [ ] **Azure Access**: Contributor role on subscription `${1:subscription-name}`",
      "- [ ] **Repository Access**: Read access to repository `${2:repo-name}`",
      "- [ ] **Tools Installed**:",
      "  - Azure CLI v2.40+",
      "  - Git v2.30+",
      "  - ${3:Additional tool}",
      "- [ ] **Credentials**: Service principal or user credentials",
      "- [ ] **Network Access**: Connectivity to ${4:environment}",
      "",
      "If you don't have the required prerequisites, see Getting Access."
    ],
    "description": "Insert prerequisites section"
  }
}
```

**Usage:** Type `prereq` and press Tab

---

## Related Topics

- [Overview](index.md)
- [Azure DevOps Wiki Types](wiki-types.md)
- [Architecture and Organization](architecture.md)
- [Project Wiki Implementation](project-wiki.md)
- [Code Wiki Implementation](code-wiki.md)
- [Markdown Standards and Best Practices](markdown-standards.md)
- [Version Control Workflow](version-control.md)
- [CI/CD Pipelines for Documentation](cicd-pipelines.md)
- [Documentation Templates](templates.md)
- [Template Repository and Automation](automation.md)
- [Access Control and Permissions](access-control.md)
- [Search and Discoverability](search.md)
- [Migration Strategy](migration.md)
- [Maintenance and Governance](governance.md)
- [Appendices](appendices.md)
