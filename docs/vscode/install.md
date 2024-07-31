# Installation

---
The following steps will install and configure VS Code with the primary intended purpose of working with PowerShell. 

1. Download and Install VS Code and Git for Windows  
    - winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"' 
    (How to use winget to install VSCode with custom options? · microsoft/winget-cli · Discussion #1798 · GitHub) 
    - `winget install --id Git.Git -e --source winget`
