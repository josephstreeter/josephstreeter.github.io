---
title: "VS Code Snippets for PowerShell Development"
description: "Comprehensive collection of Visual Studio Code snippets for PowerShell administration, automation, and development tasks."
author: "Joseph Streeter"
ms.date: "2024-01-15"
ms.topic: "reference"
ms.service: "vscode"
keywords: ["Visual Studio Code", "VS Code", "PowerShell", "snippets", "templates", "automation"]
---

## VS Code Snippets for PowerShell

Snippets are reusable code templates that accelerate development by providing instant access to commonly used code patterns. This guide covers creating, configuring, and using snippets effectively in VS Code for PowerShell development.

---

## Understanding Snippets

Snippets provide instant access to code templates through trigger words. They support:

- **Tab stops** (`$1`, `$2`) for cursor positioning
- **Placeholders** (`${1:defaultText}`) with default values
- **Variables** for dynamic content insertion
- **Multi-cursor editing** for linked placeholders

### Accessing Snippets

**Methods to insert snippets:**

1. **IntelliSense**: Type the prefix and select from suggestions
2. **Quick Actions**: Press `Ctrl+.` and select from snippet menu
3. **Command Palette**: `Ctrl+Shift+P` → "Insert Snippet"

---

## Configuring Custom Snippets

### Access Snippet Configuration

1. **Open Command Palette**: `Ctrl+Shift+P`
2. **Type**: "Configure User Snippets"
3. **Select**: Language (e.g., "powershell.json") or "New Global Snippets file"
4. **Edit**: Add custom snippets to the JSON file

### Snippet File Structure

### JSON Format and Structure

Snippets are defined in JSON format with the following structure:

```json
{
    "Snippet Name": {
        "prefix": "trigger-word",
        "body": [
            "Line 1 of code",
            "Line 2 with ${1:placeholder}",
            "Line 3 with $2"
        ],
        "description": "Description shown in IntelliSense"
    }
}
```

**Key Elements:**

- **prefix**: Trigger word(s) that activate the snippet
- **body**: Array of strings representing code lines
- **description**: Optional description for IntelliSense
- **scope**: Optional language restriction

---

## PowerShell Administrative Snippets

The following snippets provide common administrative functions for PowerShell development:

### Core Function Templates

#### Advanced PowerShell Function

```json
{
    "Advanced PowerShell Function": {
        "prefix": "func-advanced",
        "body": [
            "function ${1:FunctionName} {",
            "\t[CmdletBinding()]",
            "\tparam (",
            "\t\t[Parameter(Mandatory=\\$true, ValueFromPipeline=\\$true)]",
            "\t\t[string]\\$${2:ParameterName}",
            "\t)",
            "\t",
            "\tbegin {",
            "\t\tWrite-Verbose \"Starting ${1:FunctionName}\"",
            "\t\t${3:# Begin block code}",
            "\t}",
            "\t",
            "\tprocess {",
            "\t\ttry {",
            "\t\t\t${4:# Process block code}",
            "\t\t}",
            "\t\tcatch {",
            "\t\t\tWrite-Error \\$_.Exception.Message",
            "\t\t}",
            "\t}",
            "\t",
            "\tend {",
            "\t\tWrite-Verbose \"Completed ${1:FunctionName}\"",
            "\t\t${5:# End block code}",
            "\t}",
            "}"
        ],
        "description": "Advanced PowerShell function with error handling"
    }
}
```

### Connection Snippets

#### Exchange Online Connection

```json
{
    "Exchange Online Connection": {
        "prefix": "connect-exchange",
        "body": [
            "function Connect-ExchangeOnline {",
            "\t[CmdletBinding()]",
            "\tparam (",
            "\t\t[Parameter(Mandatory=\\$true)]",
            "\t\t[string]\\$UserPrincipalName",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[string]\\$Organization",
            "\t\t[switch]\\$ShowProgress",
            "\t)",
            "\t",
            "\ttry {",
            "\t\t\\$connectParams = @{",
            "\t\t\tUserPrincipalName = \\$UserPrincipalName",
            "\t\t\tShowProgress = \\$ShowProgress",
            "\t\t}",
            "\t\t",
            "\t\tif (\\$Organization) {",
            "\t\t\t\\$connectParams.Organization = \\$Organization",
            "\t\t}",
            "\t\t",
            "\t\tConnect-ExchangeOnline @connectParams",
            "\t\tWrite-Host \"Successfully connected to Exchange Online\" -ForegroundColor Green",
            "\t}",
            "\tcatch {",
            "\t\tWrite-Error \"Failed to connect to Exchange Online: \\$_\"",
            "\t}",
            "}"
        ],
        "description": "Connect to Exchange Online with error handling"
    }
}
```

#### SQL Server Connection

```json
{
    "SQL Server Connection": {
        "prefix": "sql-query",
        "body": [
            "function Invoke-SQLQuery {",
            "\t[CmdletBinding()]",
            "\tparam (",
            "\t\t[Parameter(Mandatory=\\$true)]",
            "\t\t[string]\\$ServerInstance,",
            "\t\t[Parameter(Mandatory=\\$true)]",
            "\t\t[string]\\$Database,",
            "\t\t[Parameter(Mandatory=\\$true)]",
            "\t\t[string]\\$Query,",
            "\t\t[switch]\\$TrustServerCertificate",
            "\t)",
            "\t",
            "\ttry {",
            "\t\t\\$params = @{",
            "\t\t\tServerInstance = \\$ServerInstance",
            "\t\t\tDatabase = \\$Database",
            "\t\t\tQuery = \\$Query",
            "\t\t\tErrorAction = 'Stop'",
            "\t\t}",
            "\t\t",
            "\t\tif (\\$TrustServerCertificate) {",
            "\t\t\t\\$params.TrustServerCertificate = \\$true",
            "\t\t}",
            "\t\t",
            "\t\t\\$results = Invoke-Sqlcmd @params",
            "\t\treturn \\$results",
            "\t}",
            "\tcatch {",
            "\t\tWrite-Error \"SQL Query failed: \\$_\"",
            "\t}",
            "}"
        ],
        "description": "Enhanced SQL Server query function"
    }
}
```

### Utility Snippets

#### Password Generation

```json
{
    "Password Generation": {
        "prefix": "new-password",
        "body": [
            "function New-RandomPassword {",
            "\t[CmdletBinding()]",
            "\tparam (",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[int]\\$Length = 12,",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[int]\\$LowerCase = 3,",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[int]\\$UpperCase = 3,",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[int]\\$Numbers = 3,",
            "\t\t[Parameter(Mandatory=\\$false)]",
            "\t\t[int]\\$SpecialChar = 3,",
            "\t\t[switch]\\$AsSecureString",
            "\t)",
            "\t",
            "\ttry {",
            "\t\t\\$chars = @()",
            "\t\t\\$chars += [char[]]'abcdefghijklmnopqrstuvwxyz' | Get-Random -Count \\$LowerCase",
            "\t\t\\$chars += [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ' | Get-Random -Count \\$UpperCase",
            "\t\t\\$chars += [char[]]'0123456789' | Get-Random -Count \\$Numbers",
            "\t\t\\$chars += [char[]]'!@#\\$%^&*' | Get-Random -Count \\$SpecialChar",
            "\t\t",
            "\t\t\\$password = (\\$chars | Get-Random -Count \\$chars.Length) -join ''",
            "\t\t",
            "\t\tif (\\$AsSecureString) {",
            "\t\t\treturn ConvertTo-SecureString -String \\$password -AsPlainText -Force",
            "\t\t} else {",
            "\t\t\treturn \\$password",
            "\t\t}",
            "\t}",
            "\tcatch {",
            "\t\tWrite-Error \"Failed to generate password: \\$_\"",
            "\t}",
            "}"
        ],
        "description": "Generate secure random password"
    }
}
```

---

## Documentation Templates

The following snippets provide templates for various types of documentation articles:

### Knowledge Base Articles

```json
{
    "KB Troubleshooting Article": {
        "prefix": "KB Troubleshooting Article",
        "body": [
            "# ${1:Title}",
            "",
            "## Introduction",
            "",
            "${2:[Start with a brief introduction explaining the purpose and importance of the troubleshooting guide, emphasizing its role in resolving common issues efficiently.]}",
            "",
            "## Issue description",
            "",
            "${3:[Provide a clear and concise description of the specific issue or problem that this troubleshooting guide addresses.]}",
            "",
            "## Signs and Symptoms",
            "",
            "${4:[List the signs or indicators users may experience when encountering the issue.]}",
            "",
            "## Troubleshooting Steps",
            "",
            "${5:[Provide a checklist of common factors or configurations to verify so users can rule out potential causes of the issue.]}",
            "",
            "**Step 1.** ${6:[Step Title]}",
            "${7:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "**Step 2.** ${8:[Step Title]}",
            "${9:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "**Step 3.** ${10:[Step Title]}",
            "${11:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "## Contact Support",
            "",
            "${12:[Provide contact information or instructions for users to contact support for further assistance if the troubleshooting steps do not resolve the issue.]}",
            "",
            "## Additional Resources",
            "",
            "${13:[Offer links or references to additional resources (such as forums, knowledge base articles, or user guides) that may provide further assistance with troubleshooting the issue.]}",
            "",
            "## Conclusion",
            "",
            "${14:[Conclude the troubleshooting guide with a summary of key points and encourage users to refer back to the guide as needed for future troubleshooting needs.]}",
            "",
            "## Disclaimer",
            "",
            "${15:[Include a disclaimer stating any limitations or liabilities associated with following the troubleshooting guide template, and advise users to use their discretion and seek professional assistance if needed.]}",
            ""
        ],
        "description": "KB Troubleshooting Article"
    },
    "KB Service Description Article": {
        "prefix": "KB Service Description Article",
        "body": [
            "# ${1:Title: [Product/service name]} description",
            "",
            "## Introduction",
            "",
            "${2:[Begin with an engaging introduction that provides context about the product and its purpose.]}",
            "",
            "## Description",
            "",
            "${3:[Provide a brief description of the product, including its main use cases, functionalities, and benefits.]}",
            "",
            "## Key features",
            "",
            "${4:[List the product's key features in bullet points or a numbered list.]}",
            "",
            "## Technical specifications",
            "",
            "${5:[Detail the product's technical specifications, including dimensions, weight, materials, and other relevant technical details.]}",
            "",
            "## Compatibility",
            "",
            "${6:[Specify compatibility requirements or limitations, such as operating systems, software versions, or hardware requirements.]}",
            "",
            "## Maintenance tips",
            "",
            "${7:[Provide advice on maintaining the product for optimal performance and longevity.]}",
            "",
            "## Additional information",
            "",
            "${8:[Include any additional information about the product, such as warranty details, regulatory compliance, or certifications.]}",
            "",
            "## Conclusion",
            "",
            "${9:[Conclude the article by summarizing the main points about the product and encouraging users to explore further or reach out for assistance if needed.]}",
            ""
        ],
        "description": "KB Service Description Article"
    },
    "KB Process Article": {
        "prefix": "KB Process Article",
        "body": [
            "# ${1:Title}",
            "",
            "## Introduction",
            "",
            "${2:[Start with a brief introduction explaining the purpose and importance of the process covered in this guide.]}",
            "",
            "## Process description",
            "",
            "${3:[Provide a concise description of the process, outlining its objectives and significance.]}",
            "",
            "## Prerequisites",
            "",
            "${4:[Detail any prerequisites or requirements necessary before initiating the process.]}",
            "",
            "## Gathering materials/resources",
            "",
            "${5:[Provide instructions on gathering the necessary materials, resources, or information needed for the process.]}",
            "",
            "## Step-by-step instructions",
            "",
            "${6:[Offer detailed, step-by-step instructions for executing each stage of the process.]}",
            "",
            "1. [Insert step]",
            "",
            "2. [Insert step]",
            "",
            "etc.",
            "",
            "## Tips and best practices",
            "",
            "${7:[Include any tips, tricks, or best practices that may aid in completing the process efficiently and effectively.]}",
            "",
            "## Next steps",
            "",
            "${8:[Offer guidance on what to do after completing the process, including any follow-up actions or additional resources.]}",
            "",
            "## Additional information",
            "",
            "${9:[Include any supplementary information relevant to the process, such as related documents, templates, or references.]}",
            "",
            "## Disclaimer",
            "",
            "${10:[Include a disclaimer stating any limitations or liabilities associated with following the process guide template, and advise users to use their discretion and seek professional advice if needed.]}",
            ""
        ],
        "description": "KB Process Article"
    },
    "KB FAQ Article": {
        "prefix": "KB FAQ Article",
        "body": [
            "# ${1:[Title: Topic] FAQs}",
            "",
            "## Introduction",
            "",
            "${2:[Provide a brief introduction to the topic covered in this FAQ article.]}",
            "",
            "**Question 1:** ${3:[Example: What are the system requirements to run this software?]}",
            "",
            "**Answer:**",
            "${4:[Concisely answer the question or direct the reader to the product page where the system requirements can be found.]}",
            "",
            "**Question 2:** ${5:[Example: How do I use a coupon code at checkout?]}",
            "",
            "**Answer:**",
            "${6:[Explain where the promo code field is located and include a screenshot.]}",
            "",
            "**Question 3:** ${7:[Example: Do you offer a warranty?]}",
            "",
            "**Answer:**",
            "${8:[Mention how long the warranty lasts and direct the reader to the warranty page for more details.]}",
            "",
            "**Question 4:** ${9:[Example: Can I return an item if I've already opened it?]}",
            "",
            "**Answer:**",
            "${10:[Explain the criteria that must be met to return an item and receive a full refund.]}",
            "",
            "**Question 5:** ${11:[Example: How long is the free trial?]}",
            "",
            "**Answer:**",
            "${12:[Identify the free trial length and encourage the reader to talk to the sales team for more information.]}",
            "",
            "## Additional information",
            "",
            "${13:[Include any additional information or resources that may be helpful to the user, such as links to related articles or external websites, troubleshooting tips, or FAQs not covered in this article.]}",
            ""
        ],
        "description": "KB FAQ Article"
    }
}
```

---

## Best Practices for Snippet Creation

### Naming Conventions

- **Use descriptive names**: Make snippet names clear and self-explanatory
- **Consistent prefixes**: Use consistent prefixes for related snippets (e.g., `connect-`, `new-`, `get-`)
- **Avoid conflicts**: Check for existing snippet prefixes to avoid conflicts

### Content Guidelines

- **Include error handling**: Always add try-catch blocks for robust code
- **Use proper formatting**: Follow PowerShell style guidelines
- **Add parameter validation**: Include proper parameter attributes
- **Document functionality**: Provide clear descriptions for each snippet

### Tab Stops and Placeholders

- **Logical order**: Number tab stops in the order users will fill them
- **Meaningful defaults**: Provide sensible default values in placeholders
- **Connected placeholders**: Use same numbers for related values

---

## Advanced Snippet Features

### Variables

VS Code supports several built-in variables in snippets:

| Variable | Description |
|----------|-------------|
| `$TM_SELECTED_TEXT` | Currently selected text |
| `$TM_CURRENT_LINE` | Current line content |
| `$TM_CURRENT_WORD` | Current word under cursor |
| `$TM_LINE_INDEX` | Zero-based line number |
| `$TM_LINE_NUMBER` | One-based line number |
| `$TM_FILENAME` | Current filename |
| `$TM_FILENAME_BASE` | Filename without extension |
| `$TM_DIRECTORY` | Directory of current file |
| `$TM_FILEPATH` | Full file path |
| `$WORKSPACE_NAME` | Workspace name |
| `$WORKSPACE_FOLDER` | Workspace folder path |

### Date and Time Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `$CURRENT_YEAR` | Current year | 2024 |
| `$CURRENT_MONTH` | Current month | 07 |
| `$CURRENT_DATE` | Current date | 15 |
| `$CURRENT_HOUR` | Current hour | 14 |
| `$CURRENT_MINUTE` | Current minute | 30 |
| `$CURRENT_SECOND` | Current second | 45 |

---

## References and Additional Resources

### Official Documentation

- **[VS Code Snippets Documentation](https://code.visualstudio.com/docs/editor/userdefinedsnippets)** - Complete guide to creating and using snippets
- **[TextMate Snippet Syntax](https://manual.macromates.com/en/snippets)** - Detailed syntax reference for advanced features
- **[VS Code Variables Reference](https://code.visualstudio.com/docs/editor/variables-reference)** - Complete list of available variables
- **[PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)** - Official PowerShell documentation

### Snippet Tools and Generators

- **[Snippet Generator](https://snippet-generator.app/)** - Online tool for creating VS Code snippets
- **[Snippets Manager Extension](https://marketplace.visualstudio.com/items?itemName=zjffun.snippetsmanager)** - VS Code extension for managing snippets
- **[PowerShell Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)** - Includes built-in PowerShell snippets

### Community Resources

- **[Awesome VS Code](https://github.com/viatsko/awesome-vscode)** - Curated list of VS Code resources
- **[PowerShell Community](https://github.com/PowerShell/PowerShell)** - PowerShell GitHub repository
- **[r/PowerShell](https://www.reddit.com/r/PowerShell/)** - PowerShell community discussions
- **[PowerShell.org](https://powershell.org/)** - PowerShell community hub

### Best Practices and Style Guides

- **[PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)** - Community style guide
- **[PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)** - Code analysis rules
- **[The PowerShell Best Practices and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)** - Comprehensive style guide
- **[Microsoft PowerShell Coding Guidelines](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)** - Official development guidelines

---

Last updated: {{ site.time | date: "%Y-%m-%d" }}
