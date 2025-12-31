# GitHub Copilot Instructions for PowerShell Development

## Overview

When generating, reviewing, or modifying PowerShell code in this repository, strictly adhere to the PowerShell linting standards and best practices documented in `docs/development/powershell/index.md`. These instructions ensure consistent, maintainable, and professional PowerShell code.

## Code Style and Formatting Requirements

### Indentation and Spacing
- **Use allman formatting** for all PowerShell code
- **Place open braces on the next line** for functions and control structures
- **Use tabs for indentation**
- **Add space around operators**: `$a -eq $b` not `$a-eq$b`
- **Add space after commas**: `$list = "a", "b", "c"`
- **Use consistent line breaks** and avoid overly long lines (80-120 characters max)

```powershell
# ✅ Good
$UserList = Get-ADUser -Filter * | Where-Object { $_.Enabled -eq $true }

# ❌ Avoid
$ul=Get-ADUser -Filter *|?{$_.Enabled-eq$true}
```

### Variable Naming Standards
- **Use descriptive names** that explain the variable's purpose
- **Use PascalCase** for readability: `$UserName`, `$ComputerList`, `$ServerConfiguration`
- **Avoid abbreviations**: Use `$ServerList` instead of `$sl`
- **Avoid special characters** except underscore
- **Don't use reserved words** as variable names

```powershell
# ✅ Good
$ActiveUsers = Get-ADUser -Filter * | Where-Object Enabled -eq $true
$DatabaseConnectionString = "Server=localhost;Database=MyDB"

# ❌ Avoid
$au = Get-ADUser -Filter * | Where-Object Enabled -eq $true
$db_conn = "Server=localhost;Database=MyDB"
```

## Function Development Standards

### Function Naming
- **Use approved verbs**: Follow PowerShell's approved verb list (Get-, Set-, New-, Remove-, Add-, Update-, etc.)
- **Use Verb-Noun pattern**: `Get-UserInformation`, `Set-ServerConfiguration`
- **Use PascalCase**: `Get-ComputerInfo` not `get-computerinfo`

### Function Structure Requirements
- **Always include comment-based help** with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE
- **Use [CmdletBinding()]** for advanced functions
- **Implement parameter validation** using validation attributes
- **Support pipeline input** when appropriate with ValueFromPipeline
- **Return structured objects** instead of formatted text
- **Use Write-Output for returning data** to the pipeline
- **Use Write-Verbose for debugging information** and Write-Error for error messages
- **Use try/catch for error handling** with meaningful messages

```powershell
<#
.SYNOPSIS
    Gets computer information from remote machines.
.DESCRIPTION
    This function retrieves basic or detailed information from one or more computers.
.PARAMETER ComputerName
    One or more computer names to query.
.PARAMETER InfoLevel
    The level of information to retrieve (Basic or Detailed).
.EXAMPLE
    Get-ComputerInfo -ComputerName "Server01" -InfoLevel Basic
.NOTES
    Requires WinRM to be enabled on target computers.
#>
function Get-ComputerInfo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter()]
        [ValidateSet("Basic", "Detailed")]
        [string]$InfoLevel = "Basic"
    )
    
    # Function implementation
}
```

## Error Handling Requirements

### Always Use Structured Error Handling
- **Use try/catch blocks** for expected errors
- **Set -ErrorAction Stop** for cmdlets in try blocks
- **Handle specific exception types** when possible
- **Provide meaningful error messages** without exposing sensitive information
- **Use finally blocks** for cleanup when needed

```powershell
try 
{
    Get-ADUser $username -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    Write-Warning "User '$username' not found in Active Directory"
}
catch [System.Security.Authentication.AuthenticationException]
{
    Write-Error "Authentication failed - check credentials"
}
catch
{
    Write-Error "Unexpected error: $($_.Exception.Message)"
    throw  # Re-throw if needed
}
```

## Performance Optimization Requirements

### Collection Handling
- **Never use += for arrays** - use ArrayList or Generic Lists instead
- **Filter early in pipelines** - apply Where-Object as early as possible
- **Use specific cmdlet parameters** instead of filtering with Where-Object when available
- **Minimize object creation** - reuse objects when possible

```powershell
# ✅ Efficient
$ProcessList = [System.Collections.Generic.List[object]]@()
Get-Process -Name "notepad" | ForEach-Object { $ProcessList.Add($_) }

# ❌ Inefficient
$ProcessList = @()
Get-Process | Where-Object Name -eq "notepad" | ForEach-Object { $ProcessList += $_ }
```

## Security Requirements

### Credential and Data Protection
- **Never hardcode passwords** or sensitive data
- **Use Get-Credential** or Read-Host -AsSecureString for password input
- **Validate all input parameters** using validation attributes
- **Set appropriate execution policies** for your environment
- **Use signed scripts** for production environments

```powershell
# ✅ Secure
$Credential = Get-Credential
$SecurePassword = Read-Host -AsSecureString "Enter password"

# ❌ Insecure
$Password = "MyPassword123"
$ConnectionString = "Server=db;User=admin;Password=secret"
```

## Documentation Requirements

### Comment-Based Help (Mandatory)
Every function must include:
- `.SYNOPSIS` - Brief description
- `.DESCRIPTION` - Detailed explanation
- `.PARAMETER` - For each parameter
- `.EXAMPLE` - At least one practical example
- `.NOTES` - Prerequisites or important information

### Code Comments
- **Document complex logic** - explain why, not just what
- **Use single-line comments** for brief explanations: `# Check if user exists`
- **Use multi-line comments** for detailed explanations:
```powershell
<#
This section handles the complex data transformation
required for the legacy system integration.
#>
```

## Output Stream Standards

### Use Appropriate Output Streams
- **Write-Output** for standard pipeline output
- **Write-Host** only for console-specific messages that shouldn't be captured
- **Write-Warning** for non-terminating warnings
- **Write-Error** for error messages
- **Write-Verbose** for detailed debugging information
- **Write-Debug** for development debugging

```powershell
Write-Output $results          # Standard output to pipeline
Write-Host "Processing..."      # Console message only
Write-Warning "Deprecated cmdlet used"
Write-Error "Failed to connect to server"
Write-Verbose "Querying Active Directory" -Verbose
```

## Data Type Guidelines

### Type Declarations
- **Use type accelerators** when specific types are required: `[string]`, `[int]`, `[datetime]`
- **Validate data types** using parameter attributes
- **Use appropriate collection types**: `[array]`, `[hashtable]`, `[System.Collections.Generic.List[]]`

```powershell
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName,
    
    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$MaxResults = 10,
    
    [Parameter()]
    [datetime]$StartDate = (Get-Date).AddDays(-30)
)
```

## Testing and Quality Assurance

### Required Practices
- **Test with various inputs** including edge cases
- **Use Write-Verbose** for debugging output
- **Implement Pester unit tests** for complex functions
- **Test in non-production environments** before deployment
- **Version control all scripts** and track changes

## Module Organization

### Structure Requirements
- **Group related functions** into modules
- **Use proper module manifests** (.psd1 files)
- **Export only necessary functions** using Export-ModuleMember
- **Include module-level help** and examples
- **Follow semantic versioning** for module versions

## Linting Enforcement

### Automated Checks
When possible, configure automated linting to enforce:
- PSScriptAnalyzer rules for code quality
- Consistent formatting standards
- Function and variable naming conventions
- Documentation completeness
- Security best practices compliance

### Code Review Requirements
All PowerShell code must be reviewed for:
- Allman formating
- Adherence to naming conventions
- Proper error handling implementation
- Security best practices compliance
- Performance optimization opportunities
- Documentation completeness

## Quick Reference Checklist

Before submitting PowerShell code, verify:
- ✅ tab indentation used consistently
- ✅ PascalCase naming for variables and functions
- ✅ Approved verbs used for function names
- ✅ Comment-based help included for all functions
- ✅ Parameter validation implemented
- ✅ Try/catch error handling used appropriately
- ✅ Performance optimizations applied (no += for arrays)
- ✅ Secure credential handling implemented
- ✅ Appropriate output streams used
- ✅ Code is readable and well-documented
- ✅ Open and close braces on separate lines

## Resources

- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PSScriptAnalyzer Rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme)

---

*These instructions ensure all PowerShell code in this repository maintains professional standards and follows industry best practices for maintainability, security, and performance.*

---

# Markdown Linting Standards

## Overview

When generating, reviewing, or modifying Markdown files in this repository, strictly adhere to the markdownlint rules to ensure consistent, readable, and properly rendered documentation.

## Heading Rules

### MD001 - Heading levels should only increment by one level at a time
- **Don't skip heading levels**: Follow `# H1` → `## H2` → `### H3`
- **Front matter support**: If YAML front matter contains `title`, treat it as top-level heading
- **Rationale**: Proper heading hierarchy ensures accessibility and document structure

```markdown
# ✅ Good
# Heading 1
## Heading 2
### Heading 3

# ❌ Avoid
# Heading 1
### Heading 3  # Skipped H2
```

### MD003 - Heading style
- **Use consistent heading style**: ATX (`#`), ATX closed (`# H1 #`), or Setext
- **Default**: Consistent with first heading in document
- **Rationale**: Consistency improves readability

### MD018 - No space after hash on atx style heading
- **Always add space after `#`**: `# Heading` not `#Heading`
- **Rationale**: Required for proper rendering

### MD019 - Multiple spaces after hash on atx style heading
- **Use single space after `#`**: `# Heading` not `#  Heading`

### MD022 - Headings should be surrounded by blank lines
- **Add blank line before and after headings**
- **Exception**: Start or end of document

```markdown
# ✅ Good
Some text

## Heading

More text

# ❌ Avoid
Some text
## Heading
More text
```

### MD023 - Headings must start at the beginning of the line
- **Don't indent headings** (except in block quotes)

### MD024 - Multiple headings with the same content
- **Avoid duplicate heading text** unless `siblings_only: true`
- **Common exception**: Changelogs with repeated section names

### MD025 - Multiple top-level headings in the same document
- **Use only one H1 per document**
- **Exception**: YAML front matter with `title` counts as H1
- **Rationale**: Document should have single title

### MD026 - Trailing punctuation in heading
- **Remove punctuation at end of headings**: `.`, `,`, `;`, `:`
- **Exception**: `?` is allowed (FAQ documents)

```markdown
# ✅ Good
# Installation Guide

# ❌ Avoid
# Installation Guide.
```

### MD041 - First line in a file should be a top-level heading
- **Start documents with H1** (or H2 if configured)
- **Exception**: YAML front matter, or `allow_preamble: true`

### MD043 - Required heading structure
- **Follow defined heading structure** when configured
- **Use for enforcing consistent document structure**

## List Rules

### MD004 - Unordered list style
- **Use consistent list markers**: `*`, `-`, or `+`
- **Default**: Consistent with first list in document

```markdown
# ✅ Good
* Item 1
* Item 2
* Item 3

# ❌ Avoid
* Item 1
+ Item 2
- Item 3
```

### MD005 - Inconsistent indentation for list items at the same level
- **Use same indentation for list items at same level**
- **Supports left-aligned or right-aligned markers**

### MD007 - Unordered list indentation
- **Indent nested lists by 2 spaces** (default)
- **Rationale**: Aligns nested content with parent list content

```markdown
# ✅ Good
* Item 1
  * Nested item
  * Another nested item

# ❌ Avoid
* Item 1
   * Nested item (3 spaces)
```

### MD029 - Ordered list item prefix
- **Use consistent numbering**: All `1.` or sequential (`1.` `2.` `3.`)
- **Default**: `one_or_ordered` allows both styles
- **Supports 0-prefixing** for alignment: `08.` `09.` `10.`

### MD030 - Spaces after list markers
- **Use consistent spacing** after list markers
- **Default**: 1 space after marker
- **Can configure separately** for single/multi-line items

### MD032 - Lists should be surrounded by blank lines
- **Add blank line before and after lists**
- **Exception**: Start or end of document

## Code Rules

### MD010 - Hard tabs
- **Use spaces instead of hard tabs**
- **Exception**: Can be allowed in code blocks with `code_blocks: false`
- **Rationale**: Tabs render inconsistently

### MD014 - Dollar signs used before commands without showing output
- **Don't use `$` prefix** if all commands lack output
- **Use `$` only when showing command output**

```markdown
# ✅ Good
ls
cat foo
less bar

# ❌ Avoid (no output shown)
$ ls
$ cat foo
$ less bar
```

### MD031 - Fenced code blocks should be surrounded by blank lines
- **Add blank line before and after code blocks**
- **Can disable for list items** with `list_items: false`

### MD040 - Fenced code blocks should have a language specified
- **Always specify language**: ` ```python ` not just ` ``` `
- **Use `text` for plain text code blocks**
- **Rationale**: Enables syntax highlighting

````markdown
# ✅ Good
```python
print("Hello")
```

# ❌ Avoid
```
print("Hello")
```
````

### MD046 - Code block style
- **Use consistent style**: Fenced (` ``` `) or indented (4 spaces)
- **Default**: Consistent with first code block

### MD048 - Code fence style
- **Use consistent fence character**: Backtick (`` ` ``) or tilde (`~`)

## Whitespace Rules

### MD009 - Trailing spaces
- **Remove trailing spaces** from lines
- **Exception**: 2 spaces for hard line break (if `br_spaces: 2`)
- **Rationale**: Trailing space has no purpose

### MD012 - Multiple consecutive blank lines
- **Use single blank line** (no consecutive blank lines)
- **Exception**: Inside code blocks

### MD027 - Multiple spaces after blockquote symbol
- **Use single space** after `>`: `> Text` not `>  Text`

### MD037 - Spaces inside emphasis markers
- **No spaces inside bold/italic**: `**bold**` not `** bold **`

```markdown
# ✅ Good
**bold** and *italic*

# ❌ Avoid
** bold ** and * italic *
```

### MD038 - Spaces inside code span elements
- **No extra spaces in code spans**: `` `code` `` not `` ` code ` ``
- **Exception**: Allowed for code starting/ending with backtick

### MD039 - Spaces inside link text
- **No spaces inside link brackets**: `[link](url)` not `[ link ](url)`

## Link Rules

### MD011 - Reversed link syntax
- **Correct order**: `[text](url)` not `(text)[url]`

### MD034 - Bare URL used
- **Wrap URLs in angle brackets**: `<https://example.com>`
- **Or use link syntax**: `[Example](https://example.com)`
- **Rationale**: Some parsers don't convert bare URLs

```markdown
# ✅ Good
Visit <https://example.com>
Visit [our website](https://example.com)

# ❌ Avoid
Visit https://example.com
```

### MD042 - No empty links
- **Don't use empty link destinations**: `[text]()` or `[text](#)`

### MD045 - Images should have alternate text (alt text)
- **Always provide alt text**: `![Description](image.png)`
- **Rationale**: Accessibility for screen readers

```markdown
# ✅ Good
![Company logo](logo.png)

# ❌ Avoid
![](logo.png)
```

### MD051 - Link fragments should be valid
- **Verify fragment links** match heading IDs
- **Follow GitHub heading algorithm**: lowercase, spaces→dashes, remove punctuation
- **Support custom fragments**: `{#custom-id}` or HTML `id` attribute

```markdown
# ✅ Good
## My Heading
[Link](#my-heading)

# ❌ Avoid
## My Heading
[Link](#My-Heading)  # Wrong case
```

### MD052 - Reference links and images should use a label that is defined
- **Define all reference labels** used in links/images

### MD053 - Link and image reference definitions should be needed
- **Remove unused reference definitions**
- **Don't duplicate reference definitions**

### MD054 - Link and image style
- **Use consistent link style**: inline, reference, autolink
- **Default**: All styles allowed

### MD059 - Link text should be descriptive
- **Avoid generic text**: "click here", "here", "link"
- **Use descriptive text**: "Download the guide" not "click here"
- **Rationale**: Important for screen readers

## Line Length Rules

### MD013 - Line length
- **Default limit**: 80 characters
- **Can configure separately** for headings (`heading_line_length`) and code (`code_block_line_length`)
- **Exception for long URLs**: Lines without spaces beyond limit
- **`strict` mode**: Report all violations
- **`stern` mode**: Report only fixable violations

## HTML and Inline Content Rules

### MD033 - Inline HTML
- **Avoid inline HTML** when pure Markdown available
- **Can allow specific elements** with `allowed_elements` parameter
- **Rationale**: Ensures portability and consistent rendering

## Blockquote Rules

### MD028 - Blank line inside blockquote
- **Don't separate blockquotes** with just blank line
- **Either**: Add text between blockquotes
- **Or**: Add `>` on blank line to continue blockquote

```markdown
# ✅ Good
> Quote 1
>
> Still quote 1

> Quote 2

# ❌ Avoid
> Quote 1

> Quote 2  # Appears as separate quote
```

## Horizontal Rule Rules

### MD035 - Horizontal rule style
- **Use consistent HR style**: `---`, `***`, or `* * *`
- **Default**: Consistent with first HR in document

## Emphasis Rules

### MD036 - Emphasis used instead of a heading
- **Use headings** for section titles, not bold/italic text
- **Rationale**: Enables proper document structure parsing

```markdown
# ✅ Good
## Section Title

# ❌ Avoid
**Section Title**
```

### MD049 - Emphasis style
- **Use consistent emphasis**: asterisk (`*`) or underscore (`_`)
- **Default**: Consistent with first emphasis

### MD050 - Strong style
- **Use consistent strong**: asterisk (`**`) or underscore (`__`)
- **Default**: Consistent with first strong

## Table Rules

### MD055 - Table pipe style
- **Use consistent pipe placement**: leading/trailing, leading only, trailing only
- **Rationale**: Visual clarity and parser compatibility

### MD056 - Table column count
- **Same number of cells in every row**
- **Rationale**: Missing/extra cells create rendering issues

### MD058 - Tables should be surrounded by blank lines
- **Add blank line before and after tables**

### MD060 - Table column style
- **Use consistent column style**: `aligned`, `compact`, or `tight`
- **`aligned`**: Pipes vertically aligned
- **`compact`**: Single space padding
- **`tight`**: No padding

```markdown
# Aligned
| Column | Column |
| ------ | ------ |
| Cell   | Cell   |

# Compact
| Column | Column |
| --- | --- |
| Cell | Cell |

# Tight
|Column|Column|
|---|---|
|Cell|Cell|
```

## Document Structure Rules

### MD047 - Files should end with a single newline character
- **Add newline at end of file**
- **Rationale**: Required by some programs

## Proper Names Rules

### MD044 - Proper names should have the correct capitalization
- **Configure list of proper names** with correct capitalization
- **Enforce consistent spelling**: "JavaScript" not "javascript"

## Quick Reference Checklist

Before committing Markdown files, verify:
- ✅ Single H1 heading at start of document
- ✅ Heading levels increment by one
- ✅ Blank lines around headings, lists, code blocks, tables
- ✅ Consistent list markers and indentation
- ✅ Code blocks have language specified
- ✅ No trailing spaces (except intentional line breaks)
- ✅ No hard tabs (use spaces)
- ✅ Links have descriptive text and valid fragments
- ✅ Images have alt text
- ✅ URLs wrapped in angle brackets or link syntax
- ✅ Consistent emphasis and strong styles
- ✅ No inline HTML (unless necessary)
- ✅ File ends with single newline

## Common Violations and Fixes

### Missing blank lines
```markdown
# ❌ Avoid
Some text
## Heading
More text

# ✅ Fix
Some text

## Heading

More text
```

### Hard tabs in code
```markdown
# ❌ Avoid (uses tab)
	echo "Hello"

# ✅ Fix (uses spaces)
    echo "Hello"
```

### Missing code fence language
````markdown
# ❌ Avoid
```
code here
```

# ✅ Fix
```bash
code here
```
````

### Trailing punctuation in headings
```markdown
# ❌ Avoid
## Installation Guide.

# ✅ Fix
## Installation Guide
```

### Generic link text
```markdown
# ❌ Avoid
[Click here](https://example.com) for more information.

# ✅ Fix
Read the [installation guide](https://example.com) for more information.
```

## Resources

- [markdownlint Rules Documentation](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [markdownlint Repository](https://github.com/DavidAnson/markdownlint)
- [CommonMark Specification](https://commonmark.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)

---

*These Markdown linting standards ensure all documentation in this repository is consistent, accessible, and properly rendered across all platforms.*
