---
title: OpenSSL Advanced Operations
description: Symmetric encryption, OCSP, timestamping, performance testing, HSMs, and ECC with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Advanced Operations

This section covers specialized operations for advanced users and security professionals.

### Symmetric Encryption and Data Protection

OpenSSL provides robust tools for encrypting and protecting sensitive data using symmetric ciphers:

```bash
# Encrypt a file with AES-256-CBC (password-based)
openssl enc -aes-256-cbc -salt -in plaintext.txt -out encrypted.bin -pbkdf2

# Decrypt the file
openssl enc -aes-256-cbc -d -in encrypted.bin -out decrypted.txt -pbkdf2

# Encrypt with specific iteration count (more secure)
openssl enc -aes-256-cbc -salt -in plaintext.txt -out encrypted.bin -pbkdf2 -iter 100000

# Encrypt with a key file instead of password
openssl rand -out key.bin 32  # Generate 256-bit key
openssl enc -aes-256-cbc -in plaintext.txt -out encrypted.bin -kfile key.bin

# Use authenticated encryption (GCM mode) - OpenSSL 1.1.0+
openssl enc -aes-256-gcm -in plaintext.txt -out encrypted.bin -pbkdf2 -iter 100000

# Generate a random key and IV and save them
openssl rand -out key.bin 32
openssl rand -out iv.bin 16
openssl enc -aes-256-cbc -in plaintext.txt -out encrypted.bin -K $(xxd -p -c 64 key.bin) -iv $(xxd -p -c 32 iv.bin)

# List all available encryption algorithms
openssl enc -list

# Calculate message digest (hash)
openssl dgst -sha256 -out hash.txt plaintext.txt

# Create a digital signature of a file using a private key
openssl dgst -sha256 -sign private.key -out signature.bin document.txt

# Verify a signature using the public key
openssl dgst -sha256 -verify public.key -signature signature.bin document.txt
```

> [!TIP]
> Best practices for symmetric encryption:
>
> - Use AES-256-GCM when possible (authenticated encryption)
> - Use PBKDF2 with high iteration counts (100,000+) for password-based encryption
> - Store IVs with ciphertext (they don't need to be secret)
> - Never reuse the same key+IV combination
> - Consider envelope encryption (encrypting data keys with master keys)

### Working with OCSP (Online Certificate Status Protocol)

OCSP provides real-time certificate revocation status checking:

```bash
# Generate an OCSP request
openssl ocsp -issuer ca.crt -cert certificate.crt -reqout ocsp_request.der

# Send an OCSP request to a responder
openssl ocsp -issuer ca.crt -cert certificate.crt -url http://ocsp.example.com -resp_text

# Send OCSP request to a responder and verify the response
openssl ocsp -issuer ca.crt -cert certificate.crt -url http://ocsp.example.com -verify_other ca.crt

# Create a simple OCSP responder (for testing)
openssl ocsp -index ca/index.txt -port 8888 -rsigner ca.crt -rkey ca.key -CA ca.crt -text

# Setup OCSP stapling on a server (embed OCSP response in TLS handshake)
# 1. Get an OCSP response
openssl ocsp -issuer intermediate.crt -cert server.crt -url http://ocsp.example.com -respout ocsp.der
# 2. Configure the web server to use this response (specific to each server type)
```

### Certificate Transparency (CT) Logs

Certificate Transparency is a security framework for monitoring and auditing certificates:

```bash
# Extract SCTs (Signed Certificate Timestamps) from a certificate
openssl x509 -in certificate.crt -noout -text | grep -A 20 "CT Precertificate SCTs"

# Verify SCT data
# Typically requires specialized tools like ct-verifier
```

### Time Stamping

Create cryptographically verifiable timestamps for documents and code:

```bash
# Create a timestamp request
openssl ts -query -data file.txt -no_nonce -out request.tsq

# Send the request to a timestamp server
curl -H "Content-Type: application/timestamp-query" \
     --data-binary @request.tsq \
     https://timestamp.example.com > response.tsr

# Verify a timestamp response
openssl ts -verify -data file.txt -in response.tsr -CAfile tsaca.crt
```

### Cryptographic Performance Testing

Benchmark cryptographic operations to evaluate system performance:

```bash
# Test RSA signing performance
openssl speed rsa

# Test specific RSA key sizes
openssl speed rsa2048 rsa4096

# Test ECC performance
openssl speed ecdsap256

# Test symmetric cipher performance
openssl speed -evp aes-256-gcm aes-256-cbc chacha20-poly1305

# Test hash function performance
openssl speed sha256 sha512

# Test performance on multiple sizes
openssl speed -bytes 16 -bytes 64 -bytes 1024 -bytes 8192 aes-256-gcm
```

### Hardware Security Module (HSM) Integration

For high-security environments, OpenSSL can work with HSMs:

```bash
# Using OpenSSL with PKCS#11 HSM (requires the engine to be installed)
openssl req -new -engine pkcs11 -keyform engine -key slot_0-label_key \
  -out request.csr -config openssl.cnf

# List available engines
openssl engine -t -c

# Use a specific engine
openssl req -engine pkcs11 -new -key id_of_key -keyform engine -out req.pem
```

### Working with Elliptic Curve Cryptography

ECC provides stronger security with smaller key sizes:

```bash
# Generate an EC private key using a named curve
openssl ecparam -name prime256v1 -genkey -noout -out ec_key.pem

# Convert EC key to PKCS#8 format with encryption
openssl pkcs8 -topk8 -in ec_key.pem -out ec_key_pkcs8.pem -encrypt

# List supported EC curves
openssl ecparam -list_curves

# Generate parameters for a specific curve
openssl ecparam -name secp384r1 -out secp384r1.pem

# Generate a CSR using an EC key
openssl req -new -key ec_key.pem -out ec_request.csr

# Create a self-signed cert with EC key
openssl req -new -x509 -key ec_key.pem -out ec_cert.pem -days 365
```

## Navigation

[◄ SSL/TLS Testing](tls-testing.md) · [OpenSSL Guide](index.md) · [Best Practices & Security ►](best-practices.md)
