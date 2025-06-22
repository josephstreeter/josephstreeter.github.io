# Visual Studio Code Configuration

The overall intent of this document is to configure VS Code for use as a PowerShell development tool. The configuration will focus on PowerShell and other technologies that may be used in conjunction with PowerShell.

## Extensions

VS Code is designed to be very extensible. There are a few extensions that we will install to make it possible to develop PowerShell code.

Extensions can be installed through the **Extensions** view (`Ctrl+Shift+X`).

To configure an extension:

- Click the Settings Sprocket in the lower left-hand corner and select **Settings** from the menu.
- Select the **User** tab at the top of the screen.
- Scroll down and expand **Extensions** in the left pane.
- Click on the extension and then update settings in the right pane as needed.

## Recommended Extensions

The following are some recommended extensions for use as a PowerShell developer.

**PowerShell Extension**  
The Microsoft PowerShell extension for Visual Studio Code (VS Code) provides rich language support and capabilities such as syntax completions, definition tracking, and linting for PowerShell. The extension should work anywhere VS Code itself and PowerShell Core 7.2 or higher is supported.

The PowerShell extension can be installed from within VS Code by opening the Extensions view with keyboard shortcut `Ctrl+Shift+X`, typing "PowerShell", and selecting the PowerShell extension.

### PowerShell Extension Settings

In this section we will be focusing on primarily configuring the PowerShell extension.

| **Name**                             | **Setting** |
|--------------------------------------|-------------|
| Code Folding                         | Enable      |
| Add Whitespace Around Pipe           | Enable      |
| Auto Correct Aliases                 | Enable      |
| Avoid Semicolons As Line Terminators | Enable      |
| Open Brace On Same Line              | Disable     |
| Trim Whitespace Around Pipe          | Enable      |
| Use Correct Casing                   | Enable      |

**GitHub Copilot**  
GitHub Copilot is a subscription service that provides the capability to leverage AI to assist in writing code.

**markdownlint**  
The markdownlint extension includes a library of rules to encourage standards and consistency for Markdown files. This is useful when documentation is maintained in a wiki or other technology that relies on markdown.

## Code Snippets

VS Code provides the ability to create custom code snippets. This way, if there is a particular function that you use regularly, you can quickly and easily enter it with only a few keystrokes.

> **Reference:**  
> [Snippets in Visual Studio Code](https://code.visualstudio.com/docs/editor/userdefinedsnippets)  
> You can easily define your own snippets without any extension. To create or edit your own snippets, select **Configure User Snippets** under File > Preferences, and then select the language (by language identifier) for which the snippets should appear, or the New Global Snippets file option if they should appear for all languages. VS Code manages the creation and refreshing of the underlying snippets file(s) for you.  
> Snippets files are written in JSON, support C-style comments, and can define an unlimited number of snippets. Snippets support most TextMate syntax for dynamic behavior, intelligently format whitespace based on the insertion context, and allow easy multiline editing.

Below is an example of a snippet for a PowerShell function.

- `"Snip-MSSQLConnection"` is the snippet name. It is displayed via IntelliSense if no description is provided.
- `prefix` defines one or more trigger words that display the snippet in IntelliSense. Substring matching is performed on prefixes, so in this case, `snip` could match `Snip-MSSQLConnection`.
- `body` is one or more lines of content, which will be joined as multiple lines upon insertion. Newlines and embedded tabs will be formatted according to the context in which the snippet is inserted.
- `description` is an optional description of the snippet displayed by IntelliSense.

```json
// in file 'Code/User/snippets/powershell.json'
{
  "SQL Server Connection": {
    "prefix": "Snip-MSSQLConnection",
    "body": [
      "function Invoke-SQLQuery()",
      "{",
      "\t[CmdletBinding()]",
      "\tParam",
      "\t(",
      "\t\t[Parameter(Mandatory=$$true)][string]$$instance,",
      "\t\t[Parameter(Mandatory=$$true)][string]$$database,",
      "\t\t[Parameter(Mandatory=$$true)][string]$$query",
      "\t)",
      "\ttry",
      "\t{",
      "\t\t$$Results = Invoke-Sqlcmd -ServerInstance $instance -Database $database -Query $query -TrustServerCertificate -ErrorAction stop",
      "\t\tReturn $$Results",
      "\t}",
      "\tcatch",
      "\t{",
      "\t\tWrite-Host $_.Exception.Message",
      "\t}",
      "}"
    ],
    "description": "Connect to MS SQL"
  }
}
```

Here is an example of a markdown snippet used as a template for a knowledgebase article. The body of the example has placeholders (listed in order of traversal): `${1:...}`, `${2:...}`, and so on. After inserting the snippet you can Tab to each placeholder for editing or jump to the next one. The string after the colon `:` is the default text.

```json
"KB Article": {
  "prefix": "KB MATC Article",
  "body": [
    "# ${1:Title}",
    "",
    "## DESCRIPTION",
    "",
    "${2:[Start with a brief introduction explaining the purpose and importance of the troubleshooting guide, emphasizing its role in resolving common issues efficiently.]}",
    "",
    "## Details",
    "",
    "${3:[Provide a clear and concise description of the specific issue or problem that this troubleshooting guide addresses.]}",
    "",
    "## INFORMATION",
    "",
    "${4:[List the signs or indicators users may experience when encountering the issue.]}",
    "",
    "## ADDITIONAL INSTRUCTION",
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
    "## REFERENCES",
    "",
    "${12:[Provide contact information or instructions for users to contact support for further assistance if the troubleshooting steps do not resolve the issue.]}",
    "",
    "## Additional Resources",
    "",
    "If you have any questions, please contact our Help Desk at (608) 246-6666 or [helpdesk@madisoncollege.edu](mailto:helpdesk@madisoncollege.edu).",
    ""
  ],
  "description": "KB MATC Article"
}
```
