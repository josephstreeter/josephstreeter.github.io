---
title: OpenSSL Quick Reference
description: The OpenSSL commands you need most often, in one place
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-08-18
ms.topic: reference
ms.service: security
---

## Quick Reference

The commands on this page cover the great majority of day-to-day OpenSSL work. Each links to the section that explains it in full.

Two options recur almost everywhere and are worth knowing before anything else:

- **`-noout`** suppresses the re-printed PEM blob. Without it, most inspection commands dump the entire encoded certificate after the output you asked for.
- **`</dev/null`** closes standard input on `s_client`. Without it the command appears to hang after the handshake, because it is waiting for data to send to the server.

### Inspect

| Task | Command |
| ---- | ------- |
| Read an entire certificate | `openssl x509 -in certificate.crt -text -noout` |
| Subject and issuer only | `openssl x509 -in certificate.crt -subject -issuer -noout` |
| Validity dates | `openssl x509 -in certificate.crt -dates -noout` |
| Expires within 30 days? (exit status) | `openssl x509 -in certificate.crt -noout -checkend 2592000` |
| Which hostnames it covers | `openssl x509 -in certificate.crt -ext subjectAltName -noout` |
| Does it cover this hostname? | `openssl x509 -in certificate.crt -noout -checkhost www.example.com` |
| SHA-256 fingerprint | `openssl x509 -in certificate.crt -fingerprint -sha256 -noout` |
| Serial number (needed to revoke) | `openssl x509 -in certificate.crt -serial -noout` |
| Read a CSR | `openssl req -in request.csr -text -noout` |
| Read a private key | `openssl pkey -in private.key -text -noout` |

See [Certificate Operations](certificate-operations.md#viewing-certificate-information).

### Verify

| Task | Command |
| ---- | ------- |
| Verify against a root plus intermediates | `openssl verify -CAfile rootca.crt -untrusted intermediate.crt certificate.crt` |
| Verify against a CA bundle | `openssl verify -CAfile ca-chain.crt certificate.crt` |
| Verify against the system trust store | `openssl verify -CApath /etc/ssl/certs certificate.crt` |
| Does this key match this certificate? (1 of 2) | `openssl x509 -noout -modulus -in certificate.crt \| openssl sha256` |
| Does this key match this certificate? (2 of 2) | `openssl rsa -noout -modulus -in private.key \| openssl sha256` |
| Is this key intact? | `openssl rsa -in private.key -noout -check` |
| Is this CSR signature valid? | `openssl req -in request.csr -noout -verify` |

`verify` reports `certificate.crt: OK` on success. For what the failure codes mean, see [Certificate Chain Verification](certificate-operations.md#certificate-chain-verification).

### Create

| Task | Command |
| ---- | ------- |
| RSA private key (2048-bit) | `openssl genrsa -out private.key 2048` |
| EC private key (P-256) | `openssl ecparam -name prime256v1 -genkey -noout -out private.key` |
| Ed25519 private key | `openssl genpkey -algorithm ED25519 -out private.key` |
| Password-protect an existing key | `openssl pkcs8 -topk8 -in private.key -out encrypted.key -v2 aes-256-cbc` |
| Extract the public key | `openssl pkey -in private.key -pubout -out public.key` |
| CSR from an existing key | `openssl req -new -key private.key -out request.csr -sha256 -subj "/CN=example.com"` |
| CSR with SANs, no config file | `openssl req -new -key private.key -out request.csr -sha256 -subj "/CN=example.com" -addext "subjectAltName=DNS:example.com,DNS:www.example.com"` |
| Self-signed certificate with SANs | `openssl req -x509 -newkey rsa:2048 -nodes -keyout private.key -out certificate.crt -days 365 -sha256 -subj "/CN=example.com" -addext "subjectAltName=DNS:example.com"` |
| Random password | `openssl rand -base64 32` |

See [Private Key Management](private-keys.md) and [CSR Creation](csr.md).

### Convert

| Task | Command |
| ---- | ------- |
| PEM to DER | `openssl x509 -in certificate.crt -outform der -out certificate.der` |
| DER to PEM | `openssl x509 -inform der -in certificate.der -out certificate.crt` |
| PEM to PKCS#12 (for Windows/IIS) | `openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -certfile ca-chain.crt` |
| PKCS#12 to PEM | `openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes` |
| Key only, out of a PKCS#12 | `openssl pkcs12 -in certificate.pfx -nocerts -out private.key -nodes` |
| Certificates only, out of a PKCS#12 | `openssl pkcs12 -in certificate.pfx -nokeys -out certificate.crt` |
| PKCS#7 to PEM | `openssl pkcs7 -in certificate.p7b -print_certs -out certificate.crt` |
| Build a server chain file | `cat certificate.crt intermediate.crt > fullchain.pem` |

See [Certificate Conversions](conversions.md).

### Test a live server

Every command here ends in `</dev/null` for the reason given above.

| Task | Command |
| ---- | ------- |
| Connect and show the handshake | `openssl s_client -connect example.com:443 -servername example.com </dev/null` |
| Show the full chain the server sends | `openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null` |
| Certificate dates, from a live server | `openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \| openssl x509 -noout -dates` |
| Save the server's certificate | `openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \| openssl x509 -out certificate.crt` |
| Check hostname validation | `openssl s_client -connect example.com:443 -servername example.com -verify_hostname example.com -verify_return_error </dev/null` |
| Test a specific TLS version | `openssl s_client -connect example.com:443 -tls1_2 </dev/null` |
| Check OCSP stapling | `openssl s_client -connect example.com:443 -status </dev/null` |
| STARTTLS (SMTP, POP3, IMAP) | `openssl s_client -connect mail.example.com:25 -starttls smtp </dev/null` |

In the output, `Verify return code: 0 (ok)` means the chain validated. See [SSL/TLS Testing](tls-testing.md).

> [!TIP]
> For a full assessment of a server's TLS configuration — protocol versions, cipher suites, and known vulnerabilities — use a purpose-built scanner such as `testssl.sh`, `sslyze`, or [SSL Labs](https://www.ssllabs.com/ssltest/). OpenSSL is the right tool for inspecting a single connection, not for surveying a configuration.

### Which file is which?

Example filenames are used consistently across this guide:

| Filename | Contents |
| -------- | -------- |
| `private.key` | The end-entity (leaf) private key |
| `request.csr` | The certificate signing request |
| `certificate.crt` | The end-entity (leaf) certificate |
| `intermediate.crt` | An intermediate CA certificate |
| `rootca.crt` | The root CA certificate — the trust anchor |
| `ca-chain.crt` | Intermediates + root. The **trust input**, for `verify -CAfile` |
| `fullchain.pem` | Leaf + intermediates. The **deployment artifact** a server presents |

## Navigation

[OpenSSL Guide](index.md) · [Installation ►](installation.md)
