---
title: OpenSSL CSR Creation and Management
description: Creating and verifying Certificate Signing Requests (CSRs) with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## CSR Creation and Management

Certificate Signing Requests (CSRs) are essential for requesting certificates from Certificate Authorities (CAs). They contain your public key and identifying information without including your private key.

### Creating a Certificate Signing Request (CSR)

```bash
# Generate a new private key and CSR (interactive mode)
openssl req -new -newkey rsa:4096 -nodes -keyout private.key -out request.csr

# Generate a CSR from an existing private key (interactive mode)
openssl req -new -key private.key -out request.csr

# Generate a CSR with subject information (non-interactive)
openssl req -new -key private.key -out request.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"

# Generate a CSR with SHA-256 signature (recommended)
openssl req -new -key private.key -out request.csr -sha256 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

# Generate a CSR with modern parameters
openssl req -new -key private.key -out request.csr -sha256 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com" \
  -addext "keyUsage=digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth"
```

> [!TIP]
> Important fields in subject information:
>
> - **C**: Country (2-letter code, e.g., US, GB, DE)
> - **ST**: State/Province
> - **L**: Locality/City
> - **O**: Organization
> - **OU**: Organizational Unit (department)
> - **CN**: Common Name (your domain name)
> - **emailAddress**: Administrative contact

### Adding Subject Alternative Names (SANs)

Most certificate authorities require SANs in CSRs for modern TLS certificates:

```bash
# Create a configuration file for SAN
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
DNS.3 = mail.example.com
DNS.4 = *.example.com
IP.1 = 192.168.1.1
EOF

# Generate a CSR with SANs
openssl req -new -key private.key -out san_request.csr -config san.conf

# Generate a CSR and private key in one command with SANs
openssl req -new -newkey rsa:4096 -nodes -keyout private.key \
  -out san_request.csr -config san.conf
```

> [!IMPORTANT]
> Most commercial CAs have specific requirements for CSRs:
>
> - Using strong key sizes (2048 bits minimum, 4096 bits recommended)
> - Including all domains in SANs (even the primary domain)
> - Using business validation information in the Organization field
> - Using SHA-256 signatures (not SHA-1)

### Verifying a CSR

Always verify your CSR before submitting it to a CA:

```bash
# View complete CSR information
openssl req -in request.csr -text -noout

# Verify CSR signature (checks if the CSR is valid)
openssl req -in request.csr -verify -noout

# View CSR subject information
openssl req -in request.csr -subject -noout

# Check SANs in the CSR
openssl req -in request.csr -text -noout | grep -A 1 "Subject Alternative Name"

# Extract the public key from a CSR
openssl req -in request.csr -noout -pubkey > pubkey.pem

# Check key size and algorithm
openssl req -in request.csr -noout -text | grep "Public-Key"
```

### CSR Submission Process

The typical process for obtaining a certificate from a commercial CA:

1. Generate a CSR with appropriate information and SANs
2. Submit the CSR to your chosen Certificate Authority
3. Complete domain validation (DV), organization validation (OV), or extended validation (EV)
4. Receive and install the signed certificate and any intermediate certificates

```bash
# Domain validation methods typically include:
# - Email validation (to admin@, webmaster@, etc.)
# - DNS TXT record validation
# - HTTP file validation (place a file on your web server)

# Example of HTTP file validation
# 1. CA provides you with a token value
# 2. Create a file at http://example.com/.well-known/pki-validation/token.txt
# 3. CA verifies the file to prove domain ownership
```

### CSR Templates for Different Purposes

Different certificate types require different CSR configurations:

#### Web Server (TLS/SSL) Certificate CSR

```bash
cat > web_server.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
EOF
```

#### Email (S/MIME) Certificate CSR

```bash
cat > email.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = John Doe
emailAddress = john.doe@example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = emailProtection, clientAuth
EOF
```

#### Code Signing Certificate CSR

```bash
cat > code_signing.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = Organization Code Signing

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature
extendedKeyUsage = codeSigning
EOF
```

These templates can be used with the standard CSR generation command:

```bash
openssl req -new -newkey rsa:4096 -nodes -keyout private.key -out request.csr -config template.conf
```

## Navigation

[◄ Private Key Management](private-keys.md) · [OpenSSL Guide](index.md) · [Certificate Conversions ►](conversions.md)
