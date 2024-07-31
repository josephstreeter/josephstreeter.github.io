# Installation

---
The following steps will install and configure VS Code with the primary intended purpose of working with PowerShell.

1. Install VS Code
    [How to use winget to install VSCode with custom options? · microsoft/winget-cli · Discussion #1798 · GitHub](https://github.com/microsoft/winget-cli/discussions/1798)

    ```powershell
    winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"' 
    ```

2. Install Git for Windows

    ```powershell
    winget install --id Git.Git -e --source winget
    ```

3. Install PowerShell

    ```powershell
    winget install --id Microsoft.PowerShell -e --source winget
    ```
