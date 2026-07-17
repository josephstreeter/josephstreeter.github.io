---
title: OpenSSL Certificate Conversions
description: Converting certificates and keys between PEM, DER, PKCS#7, PKCS#12, and JKS formats
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Certificate Conversions

Understanding certificate formats and conversion between them is essential for compatibility with different systems and applications.

### Common Certificate Formats Overview

| Format | File Extensions | Description | Typical Use Cases |
| ------ | --------------- | ----------- | ----------------- |
| PEM | .pem, .crt, .cer, .key | Base64 encoded with header/footer | Web servers, OpenSSL |
| DER | .der, .cer | Binary format | Java applications, Windows |
| PKCS#7 | .p7b, .p7c | Certificate collection | Windows, Java Keystores |
| PKCS#12 | .pfx, .p12 | Private key & certificates | Windows, macOS, browsers |
| JKS | .jks | Java KeyStore | Java applications |

### Converting Between Formats

```bash
# PEM to DER format
openssl x509 -in certificate.pem -outform der -out certificate.der

# DER to PEM format
openssl x509 -in certificate.der -inform der -outform pem -out certificate.pem

# PEM to PKCS#12 (PFX) format (includes private key and chain)
openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -certfile ca-chain.crt -name "Friendly Name"

# PEM to PKCS#12 without encryption (for automated processes)
openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -certfile ca-chain.crt -nodes -passout pass:

# PKCS#12 (PFX) to PEM format (extracts all certificates and private key)
openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes

# Extract only the private key from PKCS#12
openssl pkcs12 -in certificate.pfx -nocerts -out private.key -nodes

# Extract only the certificates from PKCS#12
openssl pkcs12 -in certificate.pfx -nokeys -out certificate.crt

# Extract specific certificate from PKCS#12 by friendly name
openssl pkcs12 -in certificate.pfx -nokeys -out certificate.crt -name "Friendly Name"

# Convert PEM certificate and key to Java KeyStore (JKS)
# (requires keytool from Java JDK)
# First convert to PKCS#12
openssl pkcs12 -export -out temp.p12 -inkey private.key -in certificate.crt -name "server-cert"
# Then convert PKCS#12 to JKS
keytool -importkeystore -srckeystore temp.p12 -srcstoretype PKCS12 -destkeystore keystore.jks -deststoretype JKS
```

> [!NOTE]
> The `-nodes` parameter (stands for "no DES") prevents encryption of the output. For security, use encryption when storing private keys.

### Working with PKCS#7 and Certificate Bundles

PKCS#7 files typically contain certificates without private keys and are often used for certificate chains:

```bash
# Create a PKCS#7 file from certificates
openssl crl2pkcs7 -nocrl -certfile certificate.crt -certfile intermediate.crt -out certificate.p7b

# Extract certificates from PKCS#7 to PEM
openssl pkcs7 -in certificate.p7b -print_certs -out certificate.pem

# Create a certificate bundle/chain (concatenation)
cat certificate.crt intermediate.crt rootca.crt > fullchain.pem

# Split a PEM file containing multiple certificates
awk 'BEGIN {c=0} /BEGIN CERT/{c++} {print > "cert." c ".pem"}' < combined.pem

# Check how many certificates are in a bundle
grep -c "BEGIN CERTIFICATE" fullchain.pem

# View all certificates in a bundle
openssl crl2pkcs7 -nocrl -certfile fullchain.pem | openssl pkcs7 -print_certs -noout
```

### Platform-Specific Formats and Conversions

Different platforms and applications may require specific certificate formats:

```bash
# For Apache: PEM format with separate key and certificate files
# certificate.crt - The server certificate
# private.key - The private key
# ca-chain.crt - The CA certificate chain

# For Nginx: PEM format with separate key and certificate files
# certificate.crt - The server certificate
# private.key - The private key
# ca-chain.crt - The CA certificate chain

# For HAProxy: PEM format with combined key and certificates
cat private.key certificate.crt ca-chain.crt > haproxy.pem

# For IIS: PKCS#12 (PFX) format
openssl pkcs12 -export -out iis.pfx -inkey private.key -in certificate.crt -certfile ca-chain.crt

# For Tomcat: PKCS#12 or JKS format
keytool -importkeystore -srckeystore certificate.pfx -srcstoretype PKCS12 -destkeystore tomcat.jks -deststoretype JKS
```

## Navigation

[◄ CSR Creation and Management](csr.md) · [OpenSSL Guide](index.md) · [Validation and Troubleshooting ►](validation-troubleshooting.md)
