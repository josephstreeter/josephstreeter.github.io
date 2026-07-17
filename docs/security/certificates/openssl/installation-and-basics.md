---
title: Installation and Basics
description: Installation guidance, version awareness, and foundational OpenSSL concepts
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

## Installation and Basics

### Installation

OpenSSL is usually available by default on Linux and macOS, but you should verify that the installed version is current and supported.

#### Linux

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install openssl libssl-dev

# Red Hat/CentOS/Fedora
sudo dnf install openssl openssl-devel

# Arch Linux
sudo pacman -S openssl
```

#### Windows

```powershell
# Chocolatey
choco install openssl

# Scoop
scoop install openssl

# winget
winget install ShiningLight.OpenSSL
```

#### macOS

```bash
brew install openssl@3
```

### Verify the installation

```bash
openssl version -a
openssl help
openssl ciphers -v | head -10
```

### OpenSSL versions and security notes

| Version | Release Date | Support Status | Notes |
| ------- | ------------ | -------------- | ----- |
| 3.2.x | 2023-present | Active development | Modern provider architecture and improved TLS support |
| 3.0.x | 2021-present | Active development | Stronger FIPS support and security hardening |
| 1.1.1 | 2018-2023 | Extended support | TLS 1.3 support and significant hardening |
| 1.0.2 | 2014-2019 | End of life | Deprecated for modern deployments |
| 1.0.1 | 2012-2017 | End of life | Vulnerable to Heartbleed |

> [!IMPORTANT]
> Use OpenSSL 1.1.1 or later and prefer OpenSSL 3.x for production environments.

### Key concepts

- Public key cryptography
- X.509 certificates and PKI trust chains
- Certificate authorities and trust anchors
- Symmetric vs. asymmetric encryption
- Hash functions and digital signatures

### Common command structure

```bash
openssl command [command_options] [command_arguments]
```

Typical commands include:

```bash
openssl x509 -help
openssl req -help
openssl genrsa -help
openssl s_client -help
```

### Configuration file considerations

OpenSSL uses configuration files such as `openssl.cnf`. The location varies by platform, but you can override it with `-config` or the `OPENSSL_CONF` environment variable.
