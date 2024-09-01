# Visual Studio Code Configuration

The overall intent of this document is to configure VS Code for use as a PowerShell development tool. The configuration will focus on PowerShell and other technologies that may be used in conjunction with PowerShell.

## Install Extensions

VS Code is designed to be very extensible. THere are a few Extensions that we will install to make it possible to develop PowerShell code.

**PowerShell Extension** - The Microsoft PowerShell extension for Visual Studio Code (VS Code) provides rich language support and capabilities such as syntax completions, definition tracking, and linting for PowerShell. The extension should work anywhere VS Code itself and PowerShell Core 7.2 or higher is supported.

The PowerShell extension can be installed from within VS Code by opening the Extensions view with keyboard shortcut ```Ctrl+Shift+X```, typing PowerShell, and selecting the PowerShell extension:

**GitHub Copilot** - GitHub Copilot is a subscription service that provides the capability to leverage AI to assist in writing code.

## Configure Extension Preferences

PowerShell Extension Settings
In this section we will be focusing on primarily configuring the PowerShell extension.

| Name | Setting |
|------|---------|
|      |         |

- Click the Settings Sproket in the lower left-hand corner and select "Settings" from the menu
- Select "User" at the top and scroll down and expand "Extensions" in the left pane
- Click on "PowerShell" under "Extensions" and then update the following settings as needed:
  - Code Folding – Enable
  - Add Whitespace Around Pipe (|) – Enable
  - Auto Correct Aliases – Enable
  - Avoid Semicolons As Line Terminators - Enable
  - Open Brace On Same Line – Disable
  - Trim Whitespace Around Pipe – Enable
  - Use Correct Casing – Enable

## Configure Code Snippets

VS Code provides the ability to create custom code snippets. This way, if there is a particular function that you used regularly, you can quickly and easily enter it with only a few key strokes.

> This is from the MS docs
[Snippets in Visual Studio Code](https://code.visualstudio.com/docs/editor/userdefinedsnippets)

You can easily define your own snippets without any extension. To create or edit your own snippets, select Configure User Snippets under File > Preferences, and then select the language (by language identifier) for which the snippets should appear, or the New Global Snippets file option if they should appear for all languages. VS Code manages the creation and refreshing of the underlying snippets file(s) for you.

Snippets files are written in JSON, support C-style comments, and can define an unlimited number of snippets. Snippets support most TextMate syntax for dynamic behavior, intelligently format whitespace based on the insertion context, and allow easy multiline editing.

Below is an example of a for loop snippet for JavaScript:

```javascript
// in file 'Code/User/snippets/javascript.json'
{
  "For Loop": {
    "prefix": ["for", "for-const"],
    "body": ["for (const ${2:element} of ${1:array}) {", "\t$0", "}"],
    "description": "A for loop."
  }
}
```

In the example above:

- "For Loop" is the snippet name. It is displayed via IntelliSense if no description is provided.
- prefix defines one or more trigger words that display the snippet in IntelliSense. Substring matching is performed on prefixes, so in this case, "fc" could match "for-const".
- body is one or more lines of content, which will be joined as multiple lines upon insertion. Newlines and embedded tabs will be formatted according to the context in which the snippet is inserted.
- description is an optional description of the snippet displayed by IntelliSense.

Additionally, the body of the example above has three placeholders (listed in order of traversal): ${1:array}, ${2:element}, and $0. You can quickly jump to the next placeholder with Tab, at which point you may edit the placeholder or jump to the next one. The string after the colon : (if any) is the default text, for example element in ${2:element}. Placeholder traversal order is ascending by number, starting from one; zero is an optional special case that always comes last, and exits snippet mode with the cursor at the specified position.
