---
title: OpenSSL Installation
description: Installing and verifying OpenSSL on Linux, Windows, macOS, and Docker
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Installation

OpenSSL is included in most Linux distributions and macOS by default, but it's essential to ensure you're using a current version with all security patches applied. This section covers installation and verification across major platforms.

### Linux

Most Linux distributions include OpenSSL packages in their standard repositories, but these may not always be the latest version:

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install openssl libssl-dev

# Red Hat/CentOS/Fedora
sudo dnf install openssl openssl-devel

# Arch Linux
sudo pacman -S openssl

# Alpine Linux
apk add openssl

# Verify installation
openssl version -a
```

For the latest version (especially on older distributions), consider building from source:

```bash
# Install build dependencies
sudo apt install build-essential checkinstall zlib1g-dev

# Download source (always check https://openssl-library.org/source/ for the
# current LTS release; 3.5.x is the latest LTS as of 2026)
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.1/openssl-3.5.1.tar.gz
tar -zxf openssl-3.5.1.tar.gz
cd openssl-3.5.1

# Configure, build, and install
./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared
make
make test
sudo make install

# Update system links and configuration
sudo ln -sf /usr/local/ssl/bin/openssl /usr/bin/openssl
sudo ldconfig
```

### Windows

Windows does not include OpenSSL by default. Several installation options are available:

```powershell
# Using Chocolatey (recommended method)
choco install openssl

# Using Scoop
scoop install openssl

# Using winget
winget install ShiningLight.OpenSSL
```

You can also download pre-compiled binaries from:

- [Official OpenSSL website](https://www.openssl.org/source/)
- [Win32/Win64 OpenSSL Installer](https://slproweb.com/products/Win32OpenSSL.html)

> [!TIP]
> For Windows installations:
>
> 1. Ensure OpenSSL is added to your PATH environment variable
> 2. Verify with `where openssl` in Command Prompt or `Get-Command openssl` in PowerShell
> 3. If you need to run multiple versions, use full paths to the specific executables

### macOS

macOS includes OpenSSL by default, but Apple has deprecated it in favor of LibreSSL. For the most current OpenSSL version, use Homebrew:

```bash
# Install using Homebrew
brew install openssl@3

# For OpenSSL 3.x, the installation path is typically:
# /usr/local/opt/openssl@3/ or /opt/homebrew/opt/openssl@3/

# Add to your PATH (add to your .bash_profile, .zshrc, etc.)
echo 'export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation and path
which openssl
openssl version -a
```

### Docker Containers

For isolated testing or deployment, consider using Docker:

```bash
# Pull official OpenSSL container
docker pull alpine/openssl

# Run OpenSSL commands in container
docker run -it --rm alpine/openssl version -a

# Use volumes to access local files
docker run -it --rm -v $(pwd):/work -w /work alpine/openssl req -new -x509 -nodes -out cert.pem -keyout key.pem
```

### Environment Variables

Configure these environment variables for easier OpenSSL usage:

```bash
# For Linux/macOS (add to shell profile)
export OPENSSL_CONF=/path/to/openssl.cnf
export SSL_CERT_DIR=/path/to/certs
export SSL_CERT_FILE=/path/to/cert.pem

# For Windows (PowerShell)
$env:OPENSSL_CONF = "C:\path\to\openssl.cnf"
$env:SSL_CERT_DIR = "C:\path\to\certs"
$env:SSL_CERT_FILE = "C:\path\to\cert.pem"
```

### Verifying a Proper Installation

Ensure your installation is working correctly with this comprehensive test:

```bash
# 1. Check version and compilation details
openssl version -a

# 2. View available commands
openssl help

# 3. List supported ciphers
openssl ciphers -v | head -10

# 4. Test key generation
openssl genrsa -out test.key 2048

# 5. Generate a self-signed certificate
openssl req -new -key test.key -x509 -days 1 -out test.crt -subj "/CN=test"

# 6. Verify the certificate
openssl x509 -in test.crt -text -noout

# 7. Test encryption/decryption
echo "Test data" > testfile.txt
openssl enc -aes-256-cbc -salt -in testfile.txt -out testfile.enc -k testpassword
openssl enc -d -aes-256-cbc -in testfile.enc -out testfile.dec -k testpassword
diff testfile.txt testfile.dec

# 8. Clean up test files
rm test.key test.crt testfile.txt testfile.enc testfile.dec

# If all commands complete without errors, your installation is working properly
```

> [!NOTE]
> If you encounter any issues during verification, ensure your path is correctly set and that any required libraries are installed. For OpenSSL errors, include the `-d` flag (e.g., `openssl req -d ...`) to enable debug output.

## Navigation

[◄ OpenSSL Guide](index.md) · [OpenSSL Guide](index.md) · [Basic Concepts ►](basic-concepts.md)
