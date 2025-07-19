# Troubleshooting

This page will try to outline some simple things to try in troubleshooting issues with PowerShell

## Visual Studio Code or Microsoft Graph Related

It is not uncommon to have issues with Microsoft Graph in Visual Studio Code. These problems are often frustrating and make little sense. A good indicator is that what versions of VS Code, the PowerShell extension and PowerShell itself are not all in the latest version. Sometimes specific modules, such as the Microsoft.Graph module, may need to be updated in order to resolve issues.

1. Make sure that you are using the latest version of the following components
    - Visual Studio Code

        ```powershell
        winget upgrade --id Microsoft.VisualStudioCode --source winget
        ```

    - Visual Studio Code PowerShell Extension - This may have updated automatically and is waiting for the extension to be restarted.
    - PowerShell

        ```powershell
        winget install --id Microsoft.Powershell --source winget
        ```

    - Microsoft.Graph PowerShell module

        ```powershell
        Update-Module Microsoft.Graph
        ```
