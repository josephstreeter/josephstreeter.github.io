---
uid: infrastructure.packer.installing
title: Installing Packer
description: Step-by-step guide to installing HashiCorp Packer on Windows, Linux, and macOS platforms
ms.date: 01/18/2026
---

This section covers the installation process for HashiCorp Packer on various platforms.

## Prerequisites

Before installing Packer, ensure your system meets these requirements:

- **Operating System**: Windows 10+, macOS 10.13+, or modern Linux distribution
- **Disk Space**: At least 100 MB for Packer binary and dependencies
- **Network Access**: Internet connection for downloading Packer and building images
- **Administrator/Root Access**: Required for system-wide installation
- **Command Line Knowledge**: Basic familiarity with terminal/command prompt

### Additional Prerequisites for Building Images

Depending on the target platform, you may need:

- Cloud provider CLI tools (AWS CLI, Azure CLI, gcloud)
- Virtualization software (VirtualBox, VMware)
- Docker Engine (for container images)
- Valid credentials for target platforms

## Installation Methods

Packer can be installed using several methods:

1. **Manual binary download** (works on all platforms)
2. **Package managers** (recommended for ease of updates)
3. **Docker container** (for isolated environments)

## Installation on Windows

### Method 1: Manual Installation

1. Download the latest Packer binary:
   - Visit <https://www.packer.io/downloads>
   - Download the Windows 64-bit ZIP file

2. Extract the archive:
   - Right-click the downloaded ZIP file
   - Select "Extract All"
   - Choose a destination directory (e.g., `C:\Program Files\Packer`)

3. Add Packer to system PATH:
   - Open "System Properties" → "Advanced" → "Environment Variables"
   - Under "System variables", find and select "Path"
   - Click "Edit" → "New"
   - Add the path to the Packer directory
   - Click "OK" to save changes

4. Restart your command prompt or PowerShell

### Method 2: Chocolatey Package Manager

```powershell
choco install packer
```

### Method 3: Scoop Package Manager

```powershell
scoop install packer
```

## Installation on Linux

### Method 1: Manual Installation (Linux)

```bash
# Download the latest version
wget https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_linux_amd64.zip

# Unzip the package
unzip packer_1.10.0_linux_amd64.zip

# Move to system path
sudo mv packer /usr/local/bin/

# Set executable permissions
sudo chmod +x /usr/local/bin/packer
```

### Method 2: Using Package Managers

#### Ubuntu/Debian

```bash
# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Update and install
sudo apt-get update
sudo apt-get install packer
```

#### Fedora/RHEL/CentOS

```bash
# Add HashiCorp repository
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

# Install Packer
sudo dnf install packer
```

#### Arch Linux

```bash
# Install from community repository
sudo pacman -S packer
```

### Method 3: Using Homebrew on Linux

```bash
brew install packer
```

## Installation on macOS

### Method 1: Homebrew (Recommended)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Packer
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

### Method 2: Manual Installation

```bash
# Download the latest version
curl -O https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_darwin_amd64.zip

# Unzip the package
unzip packer_1.10.0_darwin_amd64.zip

# Move to system path
sudo mv packer /usr/local/bin/

# Set executable permissions
sudo chmod +x /usr/local/bin/packer
```

### Method 3: MacPorts

```bash
sudo port install packer
```

## Installation Using Docker

For containerized environments or testing:

```bash
# Pull the official Packer image
docker pull hashicorp/packer:latest

# Run Packer in a container
docker run -it --rm hashicorp/packer:latest version
```

To use Packer with local templates:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  hashicorp/packer:latest build template.pkr.hcl
```

## Verifying the Installation

After installation, verify that Packer is correctly installed:

### Check Version

```bash
packer version
```

Expected output:

```text
Packer v1.10.0
```

### Check Available Commands

```bash
packer --help
```

This displays all available Packer commands and options.

### Test with Version Check

```bash
packer -v
```

Should output the installed version number.

## Post-Installation Configuration

### Setting up Environment Variables

For cloud providers, set up authentication:

#### AWS

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### Azure

```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

#### Google Cloud

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

### Enabling Shell Completion

#### Bash

```bash
packer -autocomplete-install
```

#### Zsh

```bash
packer -autocomplete-install
```

Restart your shell after installation.

## Updating Packer

### Package Manager Updates

#### Windows (Chocolatey)

```powershell
choco upgrade packer
```

#### Linux/macOS (Homebrew)

```bash
brew update
brew upgrade packer
```

#### Linux (APT)

```bash
sudo apt-get update
sudo apt-get upgrade packer
```

### Manual Updates

Download the latest binary from the official website and replace the existing installation following the manual installation steps.

## Troubleshooting Installation Issues

### Command Not Found

- Verify Packer is in your system PATH
- Restart your terminal/command prompt
- Check file permissions (Linux/macOS)

### Version Mismatch

- Ensure you're running the correct Packer binary
- Check for multiple installations: `which packer` (Linux/macOS) or `where packer` (Windows)

### Permission Denied

- Run installation commands with administrator/sudo privileges
- Check file ownership and permissions

### Conflicts with Other Tools

Some systems may have a different `packer` binary (e.g., the cracklib packer). Use the full path or create an alias:

```bash
alias packer='/usr/local/bin/packer'
```

## Next Steps

Now that Packer is installed, proceed to [Creating Your First Packer Template](first-packer-template.md) to build your first machine image.
