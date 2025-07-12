---
title: "VS Code Installation and Setup"
description: "Comprehensive guide for installing and configuring Visual Studio Code for PowerShell development across Windows and Linux platforms."
author: "Joseph Streeter"
ms.date: "2024-01-15"
ms.topic: "get-started"
ms.service: "vscode"
keywords: ["Visual Studio Code", "VS Code", "PowerShell", "installation", "setup", "Windows", "Linux"]
---

## VS Code Installation and Setup

This guide provides comprehensive instructions for installing and configuring Visual Studio Code with a focus on PowerShell development across Windows and Linux platforms.

## Prerequisites

Before beginning the installation process, ensure you have:

- Administrative privileges on your system
- Active internet connection for downloading packages
- Basic familiarity with command-line interfaces

## Install VS Code

### [Windows](#tab/vscodewindows)

#### Method 1: WinGet (Recommended)

Install without customization:

```powershell
winget install --id Microsoft.VisualStudioCode -e --source winget
```

Install with custom options (silent install, add context menu entries):

```powershell
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
```

#### Method 2: Manual Download

1. Visit [VS Code Download Page](https://code.visualstudio.com/Download)
2. Download the Windows installer (.exe)
3. Run the installer and follow the setup wizard

#### Method 3: Chocolatey

```powershell
choco install vscode
```

### [Linux](#tab/vscodelinux)

#### Method 1: APT Repository (Debian/Ubuntu)

Setup Microsoft repository and install:

```bash
# Update package index
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install wget gpg software-properties-common apt-transport-https

# Add Microsoft GPG key and repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

# Update package index and install VS Code
sudo apt update
sudo apt install code
```

#### Method 2: Snap Package

```bash
sudo snap install --classic code
```

#### Method 3: Flatpak

```bash
flatpak install flathub com.visualstudio.code
```

#### Method 4: Direct Download (.deb)

```bash
# Download and install .deb package
wget -O code.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
sudo dpkg -i code.deb
sudo apt-get install -f  # Fix dependencies if needed
rm code.deb
```

---

## Install Git

Git is essential for version control and is required for many VS Code features and extensions.

### [Windows](#tab/gitwindows)

#### Method 1: WinGet

```powershell
winget install --id Git.Git -e --source winget
```

#### Method 2: Chocolatey

```powershell
choco install git
```

#### Method 3: Manual Download

Download from [Git for Windows](https://gitforwindows.org/) and run the installer.

### [Linux](#tab/gitlinux)

#### Debian/Ubuntu

```bash
sudo apt update
sudo apt install git
```

#### RHEL/CentOS/Fedora

```bash
# Fedora
sudo dnf install git

# CentOS/RHEL
sudo yum install git
```

#### Arch Linux

```bash
sudo pacman -S git
```

#### Verify Git Installation

```bash
git --version
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Install PowerShell

PowerShell 7+ provides cross-platform scripting capabilities and enhanced features for modern development.

### [Windows](#tab/pwshwindows)

#### WinGet Installation

```powershell
winget install --id Microsoft.PowerShell -e --source winget
```

#### Alternative: Microsoft Store

Search for "PowerShell" in the Microsoft Store and install.

#### Verify Installation

```powershell
pwsh --version
```

### [Linux](#tab/pwshlinux)

#### Debian/Ubuntu - Package Repository Method

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y wget apt-transport-https software-properties-common

# Get Ubuntu version and download Microsoft repository key
source /etc/os-release
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb

# Register Microsoft repository
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package index and install PowerShell
sudo apt update
sudo apt install -y powershell
```

#### Direct Download Method

```bash
# Download latest PowerShell package
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.11/powershell_7.4.11-1.deb_amd64.deb

# Install the package
sudo dpkg -i powershell_7.4.11-1.deb_amd64.deb

# Fix any dependency issues
sudo apt-get install -f

# Clean up
rm powershell_7.4.11-1.deb_amd64.deb
```

#### Verify PowerShell Installation

```bash
pwsh --version
```

---

## Essential VS Code Extensions for PowerShell

After installing VS Code, install these essential extensions for PowerShell development:

### Core Extensions

```bash
# PowerShell extension (essential)
code --install-extension ms-vscode.PowerShell

# Additional recommended extensions
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension davidanson.vscode-markdownlint
```

### Extension Details

| Extension | Publisher | Purpose |
|-----------|-----------|---------|
| **PowerShell** | Microsoft | Syntax highlighting, IntelliSense, debugging |
| **JSON** | Microsoft | JSON file support and validation |
| **YAML** | Red Hat | YAML syntax support |
| **Code Spell Checker** | Street Side Software | Spell checking in code and comments |
| **markdownlint** | David Anson | Markdown linting and formatting |

---

## Initial Configuration

### PowerShell Extension Settings

Open VS Code settings (`Ctrl+,` / `Cmd+,`) and configure:

```json
{
    "powershell.codeFormatting.preset": "OTBS",
    "powershell.codeFormatting.openBraceOnSameLine": false,
    "powershell.codeFormatting.newLineAfterOpenBrace": true,
    "powershell.codeFormatting.newLineAfterCloseBrace": true,
    "powershell.scriptAnalysis.enable": true,
    "powershell.integratedConsole.showOnStartup": false
}
```

### Verify Setup

1. **Open VS Code**: Launch Visual Studio Code
2. **Open PowerShell Terminal**: `Terminal` → `New Terminal` → Select PowerShell
3. **Test PowerShell**: Run `$PSVersionTable` to verify PowerShell is working
4. **Create Test Script**: Create a new `.ps1` file and verify syntax highlighting works

---

## Troubleshooting

### Common Issues

#### PowerShell Extension Not Loading

```powershell
# Update PowerShell to latest version
winget upgrade Microsoft.PowerShell

# Reload VS Code window
# Ctrl+Shift+P → "Developer: Reload Window"
```

#### Git Not Recognized

```bash
# Restart VS Code after Git installation
# Check PATH includes Git installation directory
```

#### Linux Permission Issues

```bash
# Fix VS Code desktop entry permissions
sudo chmod +x /usr/share/applications/code.desktop

# Fix executable permissions
sudo chmod +x /usr/bin/code
```

---

## Next Steps

After completing the installation:

1. **Configure PowerShell Development**: See the [VS Code Configuration Guide](configure.md) for optimal PowerShell settings
2. **Learn Productivity Tips**: Explore [VS Code Tips and Tricks](tipsandtricks.md) for keyboard shortcuts and advanced features  
3. **Set Up Code Snippets**: Create custom templates with the [VS Code Snippets Guide](snippets.md)
4. **Set Up Version Control**: Configure Git repositories for your PowerShell projects
5. **Install Additional Extensions**: Explore the VS Code marketplace for productivity extensions

## References and Additional Resources

### Official Documentation

- **[Visual Studio Code Documentation](https://code.visualstudio.com/docs)** - Comprehensive VS Code documentation
- **[PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)** - Official PowerShell documentation by Microsoft
- **[Git Documentation](https://git-scm.com/doc)** - Official Git documentation and tutorials

### Installation Guides

- **[VS Code on Linux](https://code.visualstudio.com/docs/setup/linux)** - Official Linux installation guide
- **[Installing PowerShell on Ubuntu](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.5)** - Microsoft's Ubuntu installation guide
- **[Git for Windows](https://gitforwindows.org/)** - Git installation for Windows systems

### PowerShell Extension Resources

- **[PowerShell Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)** - Official extension page
- **[PowerShell Extension Documentation](https://code.visualstudio.com/docs/languages/powershell)** - Usage guide and features
- **[PowerShell Development in VS Code](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode)** - Microsoft's development guide

### Package Managers

- **[WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)** - Windows Package Manager guide
- **[Chocolatey](https://chocolatey.org/)** - Package manager for Windows
- **[Snap Store](https://snapcraft.io/store)** - Universal Linux packages

### Community Resources

- **[VS Code Tips and Tricks](https://code.visualstudio.com/docs/getstarted/tips-and-tricks)** - Productivity tips
- **[PowerShell Community](https://github.com/PowerShell/PowerShell)** - PowerShell GitHub repository
- **[r/PowerShell](https://www.reddit.com/r/PowerShell/)** - PowerShell community on Reddit

### Advanced Configuration

- **[VS Code User and Workspace Settings](https://code.visualstudio.com/docs/getstarted/settings)** - Configuration guide
- **[PowerShell Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles)** - Customizing PowerShell environment
- **[Git Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)** - Git setup and customization

---

Last updated: {{ site.time | date: "%Y-%m-%d" }}
