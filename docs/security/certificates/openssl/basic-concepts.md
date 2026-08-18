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

### Anatomy of an X.509 Certificate

A certificate is a short structured document that a CA has signed. It makes exactly one claim — *this public key belongs to this identity* — and the CA's signature is what makes that claim worth anything.

Every X.509 certificate has three top-level parts:

1. **The body** (formally `tbsCertificate`, "to be signed") — identity, public key, validity period, and extensions
2. **The signature algorithm** — which algorithm the CA used to sign the body
3. **The signature** — the CA's signature over the body

Alter one byte of the body and the signature no longer matches. That is what makes a certificate tamper-evident: anyone holding the CA's public key can detect a modified certificate, which is why certificates can travel over untrusted networks safely.

Read a certificate with:

```bash
openssl x509 -in certificate.crt -noout -text
```

```text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            35:2e:e2:47:24:79:8e:04:a7:8c:92:fd:85:26:c6:2d:d6:05:2d:55
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = State, O = Example Corp, CN = Example Corp Issuing CA
        Validity
            Not Before: Aug 18 16:15:00 2026 GMT
            Not After : Aug 18 16:15:00 2027 GMT
        Subject: C = US, ST = State, L = City, O = Example Corp, CN = example.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c4:9f:2a:...          <- truncated here for brevity
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Subject Alternative Name:
                DNS:example.com, DNS:www.example.com, IP Address:192.0.2.10
            X509v3 Subject Key Identifier:
                7F:28:C0:0D:B4:44:D3:96:D6:4E:00:0B:B6:A8:19:AA:90:97:A7:61
            X509v3 Authority Key Identifier:
                12:9C:84:84:44:D6:FC:FF:9A:40:60:0F:7A:66:88:76:36:33:39:91
            X509v3 CRL Distribution Points:
                Full Name:
                  URI:http://pki.example.com/crl/issuingca.crl
            Authority Information Access:
                OCSP - URI:http://ocsp.example.com
                CA Issuers - URI:http://pki.example.com/issuingca.crt
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        14:60:ac:42:...                      <- truncated here for brevity
```

The rest of this section walks through each of those fields.

#### Core fields

| Field | Example | What it means |
| ----- | ------- | ------------- |
| **Version** | `3 (0x2)` | The X.509 version. Version 3 added extensions and is effectively universal today. The `0x2` is not a typo — the encoded value is one less than the version number. |
| **Serial Number** | `35:2e:e2:47:…` | A unique identifier assigned by the issuing CA. It is the value you supply when revoking. Public CAs must include at least 64 bits of randomness here, which is why real serials look like this rather than counting 1, 2, 3. |
| **Signature Algorithm** | `sha256WithRSAEncryption` | The hash and signature algorithms the CA used. Anything naming `md5` or `sha1` should be treated as untrustworthy — both are broken for signatures. |
| **Issuer** | `CN = Example Corp Issuing CA` | The Distinguished Name of the CA that signed this certificate. It must exactly match the *Subject* of the CA's own certificate; that is how a chain is assembled. |
| **Not Before / Not After** | `Aug 18 2026` – `Aug 18 2027` | The validity window, always in UTC. A certificate is invalid outside it, including before it starts — a real cause of failures on machines with a wrong clock. |
| **Subject** | `CN = example.com` | The Distinguished Name of the entity the certificate is issued to. When Subject and Issuer are identical, the certificate is self-signed. |
| **Subject Public Key Info** | `rsaEncryption, 2048 bit` | The public key itself, plus its algorithm and size. This is the payload the whole certificate exists to vouch for. |

#### Distinguished Name attributes

Both Subject and Issuer are Distinguished Names — an ordered set of attributes rather than a single string:

| Attribute | Name | Example |
| --------- | ---- | ------- |
| `CN` | Common Name | `example.com` |
| `O` | Organization | `Example Corp` |
| `OU` | Organizational Unit | `IT Operations` |
| `L` | Locality (city) | `Madison` |
| `ST` | State or Province | `Wisconsin` |
| `C` | Country (two-letter ISO code) | `US` |

> [!IMPORTANT]
> The Common Name is **not** used for hostname matching any more. Browsers and modern TLS libraries match the hostname against the Subject Alternative Name extension and ignore CN entirely; a certificate with a correct CN and no SAN is rejected. Treat CN as a human-readable label, and put every hostname in the SAN.

#### Extensions

Extensions carry nearly everything that governs how a certificate may be used. These are the ones you will encounter routinely.

**Basic Constraints** — whether this certificate is a CA. `CA:FALSE` marks an end-entity certificate that cannot sign anything. `CA:TRUE` marks a CA, and may add `pathlen`, which caps how many further CAs may appear below it. This is the extension that stops an ordinary server certificate from being used to mint others.

**Key Usage** — the cryptographic operations the key is allowed to perform, at a low level: `Digital Signature`, `Key Encipherment`, `Certificate Sign`, `CRL Sign`, and others. A CA certificate needs `Certificate Sign`; a TLS server certificate needs `Digital Signature` (and `Key Encipherment` for RSA key exchange).

**Extended Key Usage (EKU)** — the purposes the certificate is approved for, at the application level: `TLS Web Server Authentication`, `TLS Web Client Authentication`, `Code Signing`, `E-mail Protection`, `Time Stamping`. A certificate presented for a purpose absent from its EKU is rejected. Key Usage and EKU are often confused: Key Usage constrains the *cryptographic operation*, EKU constrains the *application*.

**Subject Alternative Name (SAN)** — the identities the certificate actually covers. Entries may be `DNS` names, `IP` addresses, `email` addresses, or `URI` values. This is the field clients check when validating a hostname, so it must list every name the service is reached by, including the one already in the CN.

**Subject Key Identifier (SKI)** and **Authority Key Identifier (AKI)** — a fingerprint of this certificate's own public key, and a pointer to the key that signed it. Chain-building software matches a certificate's AKI to its issuer's SKI to find the next link quickly, which matters when a CA has re-issued its certificate and several candidates share a Subject name.

**CRL Distribution Points** — where to fetch the revocation list covering this certificate. Baked in at signing time and not changeable afterwards.

**Authority Information Access (AIA)** — two URLs: `OCSP` gives the responder for live revocation status, and `CA Issuers` points at the issuing CA's own certificate. Clients use the latter to repair a chain when a server neglects to send its intermediates.

Others you may meet: **Certificate Policies** (an OID naming the issuance policy the CA followed) and **CT Precertificate SCTs** (proof the certificate was logged to Certificate Transparency, required by browsers for publicly trusted certificates).

#### Critical vs. non-critical

Several extensions above print as `critical`. The flag decides what happens when software meets an extension it does not understand:

- **Critical** — software that cannot interpret the extension must reject the certificate.
- **Non-critical** — software that cannot interpret it may safely ignore it and continue.

The point is fail-safe behaviour. Marking Basic Constraints critical means an old client that does not understand CA constraints refuses the certificate rather than silently accepting a server certificate as a CA. Constraints that must never be bypassed — Basic Constraints, Key Usage — are marked critical; informational ones such as SKI and CRL Distribution Points are not.

#### The signature

The final two fields are the CA's signature over everything above, and the algorithm used to produce it. Verification recomputes the hash of the body and checks it against this signature using the issuer's public key — which is why validating a certificate always requires the issuer's certificate as well, and why a chain must be complete to be trusted.

#### What a certificate does not contain

A certificate holds only the **public** key. The matching private key never appears in it and never leaves the system that generated it — that separation is the whole basis of the security model. Certificates are public documents, safe to send to anyone.

This is also why a `.pfx`/PKCS#12 file needs a password while a `.crt` does not: PKCS#12 bundles the private key alongside the certificate. See [Certificate Conversions](conversions.md) for handling those safely.

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

# Encrypt a file with AES-256 (always pass -pbkdf2; see Advanced Operations)
openssl enc -aes-256-cbc -salt -pbkdf2 -in plaintext.txt -out encrypted.bin

# Decrypt an encrypted file
openssl enc -aes-256-cbc -d -pbkdf2 -in encrypted.bin -out decrypted.txt
```

### File Naming Conventions Used in This Guide

Examples throughout this section use a consistent set of placeholder filenames. Knowing what each one holds makes the commands easier to read and adapt:

| Filename | Contents |
| -------- | -------- |
| `private.key` | The end-entity (leaf) private key |
| `request.csr` | The certificate signing request for that key |
| `certificate.crt` | The end-entity (leaf) certificate |
| `intermediate.crt` | A single intermediate CA certificate |
| `rootca.crt` | The root CA certificate — the trust anchor |
| `ca.crt` | The issuing CA's certificate, in single-tier examples where there is no intermediate |
| `ca-chain.crt` | Intermediate(s) + root concatenated. This is the **trust input**, passed to `openssl verify -CAfile` |
| `fullchain.pem` | Leaf + intermediate(s) concatenated. This is the **deployment artifact** a web server presents to clients |

> [!NOTE]
> `ca-chain.crt` and `fullchain.pem` are frequently confused. The distinction is whether the leaf certificate is included: a trust bundle never contains the leaf, while the chain a server sends always starts with it. Sending the wrong file is a common cause of validation failures.
>
> The `.crt` and `.pem` extensions carry no technical meaning — both files are PEM-encoded either way. The extensions here are only conventional labels.

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
