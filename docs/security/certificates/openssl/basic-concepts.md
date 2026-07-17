---
title: OpenSSL Basic Concepts
description: Core PKI and cryptographic concepts, OpenSSL architecture, configuration, and command structure
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: conceptual
ms.service: security
---

## Basic Concepts

### Key Concepts in Public Key Infrastructure (PKI)

- **Public Key Cryptography**: Asymmetric encryption using key pairs where data encrypted with a public key can only be decrypted with the corresponding private key. This forms the foundation of secure communications on the internet.

- **X.509 Certificates**: Standardized digital document format that binds a public key to an identity. Contains information about the key, the identity of its owner (called the subject), the digital signature of the entity that verified the certificate's contents (the issuer), and a validity period.

- **Certificate Authorities (CAs)**: Trusted entities that issue and sign certificates after verifying the identity of the certificate applicant. Examples include commercial CAs like DigiCert, Let's Encrypt, and Sectigo, as well as private CAs established within organizations.

- **Certificate Chains**: A hierarchical trust structure consisting of a root CA certificate, zero or more intermediate CA certificates, and end-entity certificates. This chain establishes a path of trust from end-entity certificates to trusted root CAs.

- **Root Certificates**: Self-signed certificates at the top of trust chains, representing the ultimate trust anchor in PKI. Operating systems and browsers come pre-installed with a set of trusted root certificates.

- **Certificate Revocation**: The process of invalidating certificates before their expiration date using Certificate Revocation Lists (CRLs) or Online Certificate Status Protocol (OCSP).

### Cryptographic Concepts

- **Symmetric Encryption**: Uses the same key for both encryption and decryption (e.g., AES, 3DES).

- **Asymmetric Encryption**: Uses key pairs - a public key for encryption and a private key for decryption (e.g., RSA, ECC).

- **Hash Functions**: One-way functions that convert data of any size to a fixed-size output (e.g., SHA-256, SHA-3).

- **Digital Signatures**: Created by encrypting a hash of the message with the sender's private key, providing authentication, non-repudiation, and integrity.

### OpenSSL Architecture

OpenSSL consists of three main components:

1. **SSL/TLS Library**: Implements the SSL and TLS protocols for secure communications
2. **Cryptographic Library**: Provides general-purpose cryptographic functions
3. **Command-Line Interface (CLI)**: Offers tools for various cryptographic operations

### OpenSSL Configuration File

The OpenSSL configuration file (`openssl.cnf`) defines default settings used by OpenSSL commands. Its location varies by system:

- Linux: `/etc/ssl/openssl.cnf` or `/usr/lib/ssl/openssl.cnf`
- macOS: `/usr/local/etc/openssl/openssl.cnf` or `/opt/homebrew/etc/openssl@3/openssl.cnf`
- Windows: `C:\Program Files\OpenSSL-Win64\bin\openssl.cfg`

You can specify a different configuration file using the `-config` flag or by setting the `OPENSSL_CONF` environment variable.

### Common OpenSSL Commands

OpenSSL provides a rich set of commands for different cryptographic operations:

```bash
# Display OpenSSL version
openssl version -a

# Display all available commands
openssl help

# Display help for a specific command
openssl x509 -help

# List available ciphers
openssl ciphers -v

# List available elliptic curves
openssl ecparam -list_curves

# Generate a random sequence of bytes
openssl rand -base64 32

# Encrypt a file with AES-256
openssl enc -aes-256-cbc -salt -in plaintext.txt -out encrypted.bin

# Decrypt an encrypted file
openssl enc -aes-256-cbc -d -in encrypted.bin -out decrypted.txt
```

### Command Structure

Most OpenSSL commands follow this general structure:

```bash
openssl command [command_options] [command_arguments]
```

Where:

- `command`: The primary operation (e.g., `x509`, `req`, `genrsa`)
- `command_options`: Flags that modify the command's behavior
- `command_arguments`: Input/output files and other parameters

## Navigation

[◄ Installation](installation.md) · [OpenSSL Guide](index.md) · [Certificate Operations ►](certificate-operations.md)
