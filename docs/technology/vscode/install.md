# Installation

The following steps will install and configure VS Code with the primary intended purpose of working with PowerShell.

## Install VS Code

### [Windows](#tab/vscodewindows)

WinGet:

Install Without Overrides:

```powershell
winget install --id Microsoft.VisualStudioCode -e --source winget
```

Install With Overrides:

```powershell
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"' 
```

### [Linux](#tab/vscodelinux)

Debian/Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install ....
```

---

## Install Git

### [Windows](#tab/gitwindows)

Git for Windows

```powershell
winget install --id Git.Git -e --source winget
```

### [Linux](#tab/gitlinux)

Debian/Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install 
```

---

## Install PowerShell

### [Windows](#tab/pwshwindows)

WinGet:

```powershell
winget install --id Microsoft.PowerShell -e --source winget
```

### [Linux](#tab/pwshlinux)

Debian/Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install ....
```

---

## Resources

- [How to use winget to install VSCode with custom options? · microsoft/winget-cli · Discussion #1798 · GitHub](https://github.com/microsoft/winget-cli/discussions/1798)

```text
You can use the --override argument on winget install to replace the arguments winget uses with ones you want yourself. Unfortunately, you'll probably have to do some googling or run the installer with /? to get all possible arguments.

To install VSCode with those options selected, run winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,     addcontextmenufiles,addcontextmenufolders"'
```
