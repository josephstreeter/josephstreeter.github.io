---
title: "Troubleshooting Guide"
description: "Comprehensive troubleshooting guide for Windows Terminal - common issues, performance problems, and solutions"
tags: ["windows-terminal", "troubleshooting", "performance", "issues", "solutions"]
category: "development-tools"
difficulty: "advanced"
last_updated: "2025-07-11"
---

## Troubleshooting Guide

This comprehensive troubleshooting guide addresses common Windows Terminal issues, performance problems, and configuration challenges with practical solutions.

## Installation Issues

### Windows Store Installation Problems

**Symptoms:**

- Installation fails with error codes
- Windows Terminal not appearing in search
- "This app can't run on your PC" message

**Solutions:**

1. **Check System Requirements:**
   - Windows 10 version 19041.0 or higher
   - Windows Store access enabled

1. **Reset Windows Store:**

```powershell
# Run as Administrator
wsreset.exe
```

1. **Enable Developer Mode:**
   - Settings → Privacy & Security → For developers
   - Enable "Developer Mode"

### Winget Installation Issues

**Common Problems:**

- Winget command not found
- Package installation fails
- Version conflicts

**Solutions:**

```powershell
# Check winget installation
winget --version

# Install winget if missing
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

# Update winget
winget upgrade Microsoft.WindowsTerminal
```

## Performance Issues

### Slow Startup and Response

**Symptoms:**

- Long delays when opening Windows Terminal
- Sluggish text rendering
- High CPU usage during normal operation

**Diagnosis:**

```powershell
# Check Windows Terminal processes
Get-Process *terminal* | Format-Table Name, CPU, WorkingSet

# Monitor resource usage
Get-Counter "\Process(WindowsTerminal)\% Processor Time" -SampleInterval 1 -MaxSamples 10
```

**Solutions:**

```json
{
    "experimental.rendering.forceFullRepaint": false,
    "experimental.rendering.software": false,
    "antialiasingMode": "cleartype",
    "experimental.useBackgroundImageForWindow": false
}
```

### Memory Usage Issues

**Symptoms:**

- High memory consumption
- System slowdown with multiple tabs
- Out of memory errors

**Solutions:**

1. **Optimize History Settings:**

```json
{
    "historySize": 5000,
    "experimental.detectURLs": false
}
```

1. **Limit Background Processes:**

```powershell
# Check running processes in terminal
Get-Process | Where-Object {$_.ProcessName -like "*terminal*"} | Select-Object Name, WorkingSet, CPU
```

1. **Clear Terminal History:**

```powershell
# PowerShell: Clear command history
Clear-History
[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
```

## Font and Rendering Issues

### Font Not Displaying Correctly

**Symptoms:**

- Blurry or pixelated text
- Missing characters or symbols
- Inconsistent character spacing
- Ligatures not working

**Solutions:**

1. **Update Font Settings:**

```json
{
    "fontFace": "Cascadia Code",
    "fontSize": 11,
    "fontWeight": "normal",
    "antialiasingMode": "grayscale"
}
```

1. **Clear Font Cache:**

```powershell
# Run as Administrator
Stop-Service "FontCache"
Remove-Item -Path "$env:WinDir\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Force -Recurse
Start-Service "FontCache"
```

1. **Install Missing Fonts:**

```powershell
# Download and install Cascadia Code
$url = "https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode.zip"
$output = "$env:TEMP\CascadiaCode.zip"
Invoke-WebRequest -Uri $url -OutFile $output
Expand-Archive -Path $output -DestinationPath "$env:TEMP\CascadiaCode"
# Install fonts from extracted folder
```

### Unicode and Emoji Issues

**Symptoms:**

- Unicode characters displaying as boxes
- Emoji not rendering
- Special symbols missing

**Solutions:**

```json
{
    "experimental.rendering.software": false,
    "fontFace": "Cascadia Code, Segoe UI Emoji",
    "experimental.useBackgroundImageForWindow": false
}
```

## Profile and Configuration Issues

### Profile Not Loading

**Symptoms:**

- Profile doesn't appear in dropdown
- Wrong shell opens when selecting profile
- Custom settings not applying

**Diagnosis:**

```powershell
# List available profiles
wt --help

# Check profile configuration
Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
```

**Solutions:**

1. **Validate JSON Configuration:**

```powershell
# Test JSON validity
try {
    Get-Content "settings.json" | ConvertFrom-Json
    Write-Host "JSON is valid" -ForegroundColor Green
} catch {
    Write-Host "JSON is invalid: $($_.Exception.Message)" -ForegroundColor Red
}
```

1. **Reset to Default Configuration:**

```powershell
# Backup current settings
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Copy-Item "$settingsPath\settings.json" "$settingsPath\settings.json.backup"

# Remove settings file to regenerate defaults
Remove-Item "$settingsPath\settings.json"
# Restart Windows Terminal
```

### PowerShell Profile Issues

**Symptoms:**

- PowerShell profile not loading
- Custom functions and aliases missing
- Module import errors

**Solutions:**

```powershell
# Check PowerShell profile path
$PROFILE

# Test profile execution
PowerShell -NoProfile -Command "Write-Host 'PowerShell working without profile'"

# Recreate profile
if (!(Test-Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force
}

# Test profile content
try {
    . $PROFILE
    Write-Host "Profile loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Profile error: $($_.Exception.Message)" -ForegroundColor Red
}
```

## WSL Integration Issues

### WSL Not Appearing in Profiles

**Symptoms:**

- WSL distributions not showing in Windows Terminal
- WSL profile exists but won't launch
- "The system cannot find the file specified" error

**Solutions:**

1. **Check WSL Installation:**

```powershell
# List installed WSL distributions
wsl --list --verbose

# Check WSL status
wsl --status
```

1. **Update WSL Configuration:**

```json
{
    "guid": "{07b52e3e-de2c-5db4-bd2d-ba144ed6c273}",
    "name": "Ubuntu-20.04",
    "commandline": "wsl.exe -d Ubuntu-20.04",
    "startingDirectory": "//wsl$/Ubuntu-20.04/home/%USERNAME%",
    "icon": "ms-appx:///ProfileIcons/linux.png"
}
```

1. **Reinstall WSL Distribution:**

```powershell
# Unregister problematic distribution
wsl --unregister Ubuntu-20.04

# Reinstall from Microsoft Store
winget install Canonical.Ubuntu.2004
```

### WSL Path Issues

**Symptoms:**

- Cannot access Windows files from WSL
- Path translation not working
- File permissions errors

**Solutions:**

```bash
# WSL: Check mount points
mount | grep drvfs

# WSL: Access Windows files
cd /mnt/c/Users/$USER

# Windows: Access WSL files
explorer.exe \\wsl$\Ubuntu-20.04\home\username
```

## Git Integration Issues

### Git Bash Profile Problems

**Symptoms:**

- Git Bash profile won't start
- Git commands not working in Windows Terminal
- Path issues with Git executable

**Solutions:**

1. **Verify Git Installation:**

```powershell
# Check Git installation
git --version
where git

# Find Git Bash executable
Get-ChildItem "C:\Program Files\Git" -Recurse -Name "bash.exe"
```

1. **Update Git Bash Profile:**

```json
{
    "guid": "{00000000-0000-0000-ba54-000000000002}",
    "name": "Git Bash",
    "commandline": "\"%PROGRAMFILES%\\Git\\usr\\bin\\bash.exe\" -i -l",
    "icon": "%PROGRAMFILES%\\Git\\mingw64\\share\\git\\git-for-windows.ico",
    "startingDirectory": "%USERPROFILE%"
}
```

### Git Credential Issues

**Symptoms:**

- Authentication prompts appearing repeatedly
- Git operations failing with permission errors
- SSH key issues

**Solutions:**

```bash
# Configure Git credentials
git config --global credential.helper manager-core
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Test SSH connection
ssh -T git@github.com

# Regenerate SSH keys if needed
ssh-keygen -t ed25519 -C "your.email@example.com"
```

## Theme and Appearance Issues

### Color Scheme Not Applying

**Symptoms:**

- Custom color schemes not working
- Colors reverting to default
- Inconsistent theming across profiles

**Solutions:**

1. **Validate Color Scheme Definition:**

```json
{
    "schemes": [
        {
            "name": "Custom Dark",
            "foreground": "#FFFFFF",
            "background": "#1E1E1E",
            "black": "#000000",
            "red": "#FF6B6B",
            "green": "#51CF66",
            "yellow": "#FFD93D",
            "blue": "#74C0FC",
            "purple": "#D0BFFF",
            "cyan": "#66D9EF",
            "white": "#F8F8F2",
            "brightBlack": "#666666",
            "brightRed": "#FF8787",
            "brightGreen": "#69DB7C",
            "brightYellow": "#FFE066",
            "brightBlue": "#91A7FF",
            "brightPurple": "#E599F7",
            "brightCyan": "#87F5FB",
            "brightWhite": "#FFFFFF"
        }
    ]
}
```

1. **Apply Color Scheme to Profile:**

```json
{
    "profiles": {
        "list": [
            {
                "guid": "{your-profile-guid}",
                "colorScheme": "Custom Dark"
            }
        ]
    }
}
```

### Background Image Issues

**Symptoms:**

- Background images not displaying
- Images appearing distorted
- Performance issues with background images

**Solutions:**

```json
{
    "backgroundImage": "C:\\Users\\username\\Pictures\\terminal-background.jpg",
    "backgroundImageOpacity": 0.3,
    "backgroundImageStretchMode": "uniformToFill",
    "backgroundImageAlignment": "center"
}
```

## Keyboard Shortcut Issues

### Custom Shortcuts Not Working

**Symptoms:**

- Key bindings not responding
- Conflicts with system shortcuts
- Actions not executing

**Solutions:**

1. **Check Key Binding Syntax:**

```json
{
    "keybindings": [
        {
            "command": {
                "action": "copy",
                "singleLine": false
            },
            "keys": "ctrl+c"
        },
        {
            "command": "paste",
            "keys": "ctrl+v"
        }
    ]
}
```

1. **Resolve Conflicts:**

```json
{
    "keybindings": [
        {
            "command": "unbound",
            "keys": "ctrl+shift+t"
        },
        {
            "command": "newTab",
            "keys": "ctrl+t"
        }
    ]
}
```

## Network and Connectivity Issues

### Azure Cloud Shell Integration

**Symptoms:**

- Azure Cloud Shell profile not working
- Authentication failures
- Connection timeouts

**Solutions:**

```powershell
# Check Azure CLI installation
az --version

# Login to Azure
az login

# Test Azure Cloud Shell
az cloudshell open
```

### SSH Connection Issues

**Symptoms:**

- SSH connections failing through Windows Terminal
- Key authentication not working
- Connection timeouts

**Solutions:**

```bash
# Test SSH configuration
ssh -v user@hostname

# Check SSH client configuration
cat ~/.ssh/config

# Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new
```

## Diagnostic Tools and Commands

### Built-in Diagnostics

```powershell
# Check Windows Terminal version
wt --version

# Validate settings
wt --validate-settings

# List available profiles
wt --help
```

### System Information

```powershell
# Windows version
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion

# Terminal processes
Get-Process | Where-Object {$_.Name -like "*terminal*"}

# Font information
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
```

### Log Files and Debugging

```powershell
# Windows Terminal logs location
$logPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\DiagOutputDir"
Get-ChildItem $logPath -Recurse | Sort-Object LastWriteTime -Descending

# Event Viewer entries
Get-WinEvent -LogName Application | Where-Object {$_.ProviderName -like "*Terminal*"} | Select-Object -First 10
```

## Recovery Procedures

### Complete Reset

```powershell
# Backup current configuration
$packagePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
$backupPath = "$env:USERPROFILE\Desktop\WindowsTerminal_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $packagePath $backupPath -Recurse

# Reset Windows Terminal
Get-AppxPackage Microsoft.WindowsTerminal | Reset-AppxPackage
```

### Selective Recovery

```powershell
# Restore specific configuration
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Copy-Item "$backupPath\LocalState\settings.json" "$settingsPath\settings.json"
```

## Getting Additional Help

### Official Resources

- [Windows Terminal Documentation](https://docs.microsoft.com/en-us/windows/terminal/)
- [GitHub Issues](https://github.com/microsoft/terminal/issues)
- [Community Discord](https://discord.gg/terminal)

### Community Support

- [Stack Overflow](https://stackoverflow.com/questions/tagged/windows-terminal)
- [Reddit r/WindowsTerminal](https://reddit.com/r/WindowsTerminal)
- [Microsoft Q&A](https://docs.microsoft.com/en-us/answers/topics/windows-terminal.html)

---

*This troubleshooting guide covers the most common Windows Terminal issues. For persistent problems, consider filing an issue on the [official GitHub repository](https://github.com/microsoft/terminal/issues).*
