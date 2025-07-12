---
title: "Configuration Guide"
description: "Comprehensive configuration guide for Windows Terminal - profiles, themes, and customization options"
tags: ["windows-terminal", "configuration", "profiles", "themes", "customization"]
category: "development-tools"
difficulty: "intermediate"
last_updated: "2025-07-11"
---

## Configuration Guide

Windows Terminal's power lies in its extensive customization capabilities. This guide covers essential configuration options, profile management, and advanced customization techniques.

## Configuration File Location

Windows Terminal stores its configuration in a JSON file that can be easily customized.

### Accessing Settings

**Via GUI:**

1. Click the dropdown arrow next to the new tab button
2. Select **Settings**

**Via keyboard:**

- Press `Ctrl + ,`

**Direct file access:**

- Location: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

## Essential Configuration Options

### Setting Default Profile

```json
{
    "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "profiles": {
        "defaults": {
            "fontFace": "Cascadia Code",
            "fontSize": 11
        }
    }
}
```

### Startup Behavior

```json
{
    "startupActions": "new-tab -p \"PowerShell\"; split-pane -p \"Command Prompt\"",
    "launchMode": "maximized",
    "initialCols": 120,
    "initialRows": 30
}
```

## Profile Management

### Understanding Profiles

Profiles define the appearance and behavior of each shell environment. Each profile includes:

- **Command-line executable** and arguments
- **Visual appearance** (colors, fonts, background)
- **Working directory** and environment variables
- **Tab title** and icon

### Common Profile Configurations

#### PowerShell Profile

```json
{
    "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "name": "PowerShell",
    "commandline": "pwsh.exe",
    "icon": "ms-appx:///ProfileIcons/pwsh.png",
    "colorScheme": "Campbell Powershell",
    "fontFace": "Cascadia Code",
    "fontSize": 11,
    "startingDirectory": "%USERPROFILE%"
}
```

#### WSL Profile

```json
{
    "guid": "{07b52e3e-de2c-5db4-bd2d-ba144ed6c273}",
    "name": "Ubuntu-20.04",
    "commandline": "wsl.exe -d Ubuntu-20.04",
    "icon": "ms-appx:///ProfileIcons/linux.png",
    "colorScheme": "One Half Dark",
    "startingDirectory": "//wsl$/Ubuntu-20.04/home/username"
}
```

#### Git Bash Profile

```json
{
    "guid": "{00000000-0000-0000-ba54-000000000002}",
    "name": "Git Bash",
    "commandline": "\"%PROGRAMFILES%\\Git\\usr\\bin\\bash.exe\" -i -l",
    "icon": "%PROGRAMFILES%\\Git\\mingw64\\share\\git\\git-for-windows.ico",
    "startingDirectory": "%USERPROFILE%"
}
```

## Customization and Themes

### Color Schemes

Windows Terminal supports extensive color customization through predefined and custom color schemes.

#### Popular Color Schemes

**Campbell (Default):**

```json
{
    "name": "Campbell",
    "foreground": "#CCCCCC",
    "background": "#0C0C0C",
    "black": "#0C0C0C",
    "red": "#C50F1F",
    "green": "#13A10E",
    "yellow": "#C19C00"
}
```

**One Half Dark:**

```json
{
    "name": "One Half Dark",
    "foreground": "#DCDFE4",
    "background": "#282C34",
    "black": "#282C34",
    "red": "#E06C75",
    "green": "#98C379",
    "yellow": "#E5C07B"
}
```

### Background Customization

#### Solid Colors

```json
{
    "background": "#1E1E1E",
    "useAcrylic": false
}
```

#### Acrylic Transparency

```json
{
    "useAcrylic": true,
    "acrylicOpacity": 0.8,
    "background": "#1E1E1E"
}
```

#### Background Images

```json
{
    "backgroundImage": "C:\\Users\\username\\Pictures\\terminal-bg.jpg",
    "backgroundImageOpacity": 0.3,
    "backgroundImageStretchMode": "uniformToFill"
}
```

### Font Configuration

#### Recommended Fonts

| Font | Features | Best For |
|------|----------|----------|
| **Cascadia Code** | Ligatures, designed for terminals | General development |
| **JetBrains Mono** | Ligatures, high readability | IDE-like experience |
| **Fira Code** | Extensive ligature support | Functional programming |
| **Consolas** | Windows native, good readability | Traditional Windows feel |

#### Font Settings

```json
{
    "fontFace": "Cascadia Code",
    "fontSize": 11,
    "fontWeight": "normal",
    "antialiasingMode": "grayscale"
}
```

## Advanced Configuration

### Custom Key Bindings

#### Common Customizations

```json
{
    "keybindings": [
        {
            "command": "find",
            "keys": "ctrl+shift+f"
        },
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
        },
        {
            "command": "toggleFullscreen",
            "keys": "f11"
        }
    ]
}
```

### Pane Configuration

```json
{
    "keybindings": [
        {
            "command": {
                "action": "splitPane",
                "split": "vertical",
                "profile": "PowerShell"
            },
            "keys": "ctrl+shift+v"
        }
    ]
}
```

### Tab Renaming

```json
{
    "keybindings": [
        {
            "command": {
                "action": "renameTab",
                "title": "New Title"
            },
            "keys": "ctrl+shift+r"
        }
    ]
}
```

## Configuration Best Practices

### Backup and Versioning

1. **Regular Backups**: Create backups before major changes
2. **Version Control**: Store configuration in Git repository
3. **Modular Configuration**: Use includes for shared settings
4. **Testing**: Test configurations in isolated environments

### Performance Considerations

1. **Limit Complex Themes**: Avoid overly complex color schemes
2. **Optimize Fonts**: Choose performant font rendering options
3. **Resource Management**: Monitor memory usage with multiple profiles
4. **Background Effects**: Use transparency and effects judiciously

---

*Next: Learn about [productivity features](productivity.md) to maximize your Windows Terminal efficiency.*
