---
title: Private Keys and CSRs
description: Generating, protecting, and validating private keys and certificate signing requests
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

## Private Keys and CSRs

### Generate private keys

```bash
# RSA 2048-bit
openssl genrsa -out private_key_2048.key 2048

# RSA 4096-bit with password protection
openssl genrsa -aes256 -out encrypted_private.key 4096

# EC key using P-256
openssl ecparam -name prime256v1 -genkey -noout -out ec_private.key

# Ed25519 key (OpenSSL 1.1.1+)
openssl genpkey -algorithm ED25519 -out ed25519_private.key
```

### Protect and inspect keys

```bash
# Encrypt an existing private key
openssl rsa -in unencrypted.key -aes256 -out encrypted.key

# Check if a key is valid
openssl rsa -in private.key -check -noout

# View key details
openssl rsa -in private.key -text -noout
```

### Extract public keys

```bash
openssl rsa -in private.key -pubout -out public.key
openssl ec -in ec_private.key -pubout -out ec_public.key
openssl pkey -in ed25519_private.key -pubout -out ed25519_public.key
```

### Create a CSR

```bash
openssl req -new -newkey rsa:4096 -nodes -keyout private.key -out request.csr
```

Non-interactive options are useful in automation:

```bash
openssl req -new -key private.key -out request.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"
```

### Add SANs to a CSR

```bash
cat > san.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
OU = Department
CN = example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
EOF

openssl req -new -key private.key -out san_request.csr -config san.conf
```

### Verify and submit a CSR

```bash
openssl req -in request.csr -text -noout
openssl req -in request.csr -verify -noout
openssl req -in request.csr -subject -noout
```

### Key security practices

- Use strong encryption for private keys and set restrictive file permissions.
- Prefer AES-256 or modern algorithms such as Ed25519 when supported.
- Store backups securely and rotate keys on a defined schedule.
- Use hardware-backed keys or HSMs for critical infrastructure.
