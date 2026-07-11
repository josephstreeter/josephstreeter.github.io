---
title: Certificate Operations
description: Creating, inspecting, verifying, and converting certificates with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

## Certificate Operations

### Create a self-signed certificate

```bash
openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 365 -nodes
```

For modern deployments, include SANs and SHA-256:

```bash
openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com" \
  -sha256
```

### View certificate details

```bash
openssl x509 -in certificate.crt -text -noout
openssl x509 -in certificate.crt -issuer -noout
openssl x509 -in certificate.crt -subject -noout
openssl x509 -in certificate.crt -dates -noout
```

### Verify certificate chains

```bash
openssl verify -CAfile rootca.crt certificate.crt
openssl verify -CAfile rootca.crt -untrusted intermediate.crt certificate.crt
```

### Certificate formats and conversions

| Format | Description |
| ------ | ----------- |
| PEM | Text format used by most web servers and OpenSSL |
| DER | Binary format common in Java and Windows environments |
| PKCS#7 | Certificate container without private keys |
| PKCS#12 | Container for certificates and private keys |

```bash
# PEM to DER
openssl x509 -in certificate.pem -outform der -out certificate.der

# DER to PEM
openssl x509 -inform der -in certificate.der -out certificate.pem

# PEM to PKCS#12
openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -certfile ca-chain.pem
```

### Create a simple certificate authority

```bash
mkdir -p ca/{certs,crl,newcerts,private}
touch ca/index.txt
echo 1000 > ca/serial
```

```bash
openssl genrsa -aes256 -out ca/private/ca.key 4096
openssl req -config ca.conf -key ca/private/ca.key -new -x509 -days 3650 -sha256 \
  -extensions v3_ca -out ca/certs/ca.crt
```

### Sign a CSR with your CA

```bash
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"
openssl ca -config ca.conf -extensions server_cert -days 365 -notext -md sha256 -in server.csr -out server.crt
```

### SANs and wildcard certificates

Modern browsers require SANs for hostnames beyond the Common Name.

```bash
openssl req -new -nodes -newkey rsa:2048 -keyout server_san.key -out server_san.csr -config san.conf
openssl x509 -req -in server_san.csr -signkey server_san.key -out server_san.crt -days 365 -sha256 -extfile san.conf -extensions v3_req
```

Wildcard certificates cover `*.example.com` and its first-level subdomains, but they also enlarge the impact of compromise. In high-security environments, explicit SANs are often preferred.

### CRLs and revocation

```bash
openssl ca -config ca.conf -revoke server.crt -crl_reason keyCompromise
openssl ca -config crl.conf -gencrl -out ca/crl/ca.crl
openssl crl -in ca/crl/ca.crl -text -noout
```
