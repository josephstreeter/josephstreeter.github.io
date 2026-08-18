---
title: OpenSSL Certificate Validation and Troubleshooting
description: Verifying certificates, checking revocation, and diagnosing common OpenSSL issues
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Certificate Validation and Troubleshooting

Verifying certificates and diagnosing issues is a critical part of certificate management:

```bash
# Verify a certificate against a CA certificate
openssl verify -CAfile ca.crt certificate.crt

# Verify a certificate chain
openssl verify -CAfile ca-chain.crt certificate.crt

# Check if a private key matches a certificate
openssl x509 -noout -modulus -in certificate.crt | openssl md5
openssl rsa -noout -modulus -in private.key | openssl md5
# If the outputs match, the key corresponds to the certificate

# Check the hostname against the certificate presented by a server (OpenSSL 1.1.1+).
# s_client does this itself — its output is not bare PEM, so it cannot be piped into x509.
openssl s_client -connect example.com:443 -servername example.com \
  -verify_hostname example.com -verify_return_error </dev/null

# Check the hostname against a certificate file
openssl x509 -in certificate.crt -noout -checkhost example.com

# Test an HTTPS connection and view the certificate
openssl s_client -connect example.com:443 -servername example.com </dev/null

# Test an HTTPS connection with full certificate chain verification
openssl s_client -connect example.com:443 -servername example.com -CAfile ca-chain.crt -verify_return_error </dev/null

# Check certificate expiration date
openssl x509 -enddate -noout -in certificate.crt

# List all common SSL/TLS problems for a website
openssl s_client -connect example.com:443 -servername example.com -showcerts -tlsextdebug -status </dev/null
```

### Certificate Revocation Status Checking

Certificate revocation is crucial for maintaining PKI security. OpenSSL provides ways to check if certificates have been revoked through CRLs and OCSP:

```bash
# Download a CRL from a distribution point
curl -s http://crl.example.com/ca.crl > ca.crl

# Convert a CRL from DER to PEM format if needed
openssl crl -inform DER -in ca.crl -outform PEM -out ca.crl.pem

# View CRL information
openssl crl -in ca.crl.pem -text -noout

# Verify a certificate against a CRL
openssl verify -crl_check -CAfile ca.crt -CRLfile ca.crl.pem certificate.crt

# Check OCSP status of a certificate
openssl ocsp -issuer ca.crt -cert certificate.crt -url http://ocsp.example.com -text

# Check OCSP stapling during TLS connection
openssl s_client -connect example.com:443 -status -servername example.com </dev/null

# Extract CRL distribution points from a certificate
openssl x509 -in certificate.crt -text -noout | grep -A 3 "CRL Distribution"

# Extract OCSP responder URL from a certificate
openssl x509 -in certificate.crt -text -noout | grep -A 3 "Authority Information Access"
```

> [!IMPORTANT]
> Revocation checking is often overlooked but is essential for complete certificate validation. Both CRL and OCSP have advantages:
>
> - **CRLs**: Work offline once downloaded, but can grow large and become stale
> - **OCSP**: Provides real-time status, more efficient, but requires continuous online access

### Diagnosing Common Issues

When validation or connections fail, these targeted checks help isolate the cause.

#### Certificate Verification Failures

```bash
# Check the entire certificate chain with verbose output
openssl verify -verbose -CAfile ca-chain.crt certificate.crt

# Test whether an intermediate certificate is missing
openssl verify -untrusted intermediate.crt -CAfile rootca.crt certificate.crt

# Validate the certificate against a specific hostname
openssl x509 -in certificate.crt -noout -checkhost example.com

# Check trust against the system CA store
openssl verify -CApath /etc/ssl/certs -verbose certificate.crt
```

#### Private Key Problems

```bash
# Check whether a private key is valid
openssl rsa -check -in private.key

# Check whether a private key is properly formatted
openssl rsa -in private.key -text -noout

# Strip stray comment lines from a text-format key (recovery aid)
grep -v "^#" private.key > fixed_key.pem
```

> [!TIP]
> To confirm a key matches its certificate, compare their moduli (see the key/certificate match command in the validation block above). Mismatched moduli mean the key and certificate do not belong together.

#### CSR Validation Issues

```bash
# Verify CSR integrity (signature check)
openssl req -verify -in request.csr -noout

# Inspect CSR contents and verify in one pass
openssl req -text -noout -verify -in request.csr

# Strip stray comment lines from a text-format CSR (recovery aid)
grep -v "^#" request.csr > fixed_csr.pem
```

#### Connectivity Problems

```bash
# Test through an HTTP CONNECT proxy (s_client has native support; no nc pipeline needed)
openssl s_client -proxy proxy.example.com:8080 -connect example.com:443 \
  -servername example.com </dev/null

# Test with a specific protocol version
openssl s_client -connect example.com:443 -tls1_2 </dev/null

# Bypass DNS/SNI by connecting to an IP while sending a specific SNI name
openssl s_client -connect IP_ADDRESS:443 -servername example.com </dev/null
```

#### TLS Handshake Failures

TLS handshake failures are common but can be difficult to diagnose:

```bash
# Full debug output of the handshake
openssl s_client -connect example.com:443 -debug -msg -state </dev/null

# Check whether the server accepts a given cipher policy
openssl s_client -connect example.com:443 -cipher 'HIGH' -tls1_2 </dev/null

# Check whether the server requires a client certificate
openssl s_client -connect example.com:443 -cert client.crt -key client.key </dev/null

# Debug output with timing information
openssl s_client -connect example.com:443 -tls1_2 -debug -time -msg -state </dev/null
```

### Common Certificate Problems and Solutions

| Problem | Possible Causes | Solutions |
| ------- | --------------- | --------- |
| Certificate not trusted | Missing CA in trust store | Add CA certificate to system trust store |
| | Incomplete certificate chain | Include intermediate certificates |
| Certificate expired | Not renewed in time | Generate and install new certificate |
| Name mismatch | Wrong hostname in certificate | Use correct hostname or add to SAN |
| | Accessing by IP, not hostname | Use proper DNS name matching certificate |
| Self-signed warning | Certificate not signed by trusted CA | Install certificate from trusted CA |
| Revoked certificate | Certificate compromised | Generate new key pair and certificate |
| Weak signature algorithm | Old certificate using SHA-1 | Generate new certificate using SHA-256 |

### Certificate Expiration, Renewal, and Monitoring

Check expiration, generate a renewal request, and monitor certificates to prevent unexpected outages:

```bash
# Check a certificate's expiration date
openssl x509 -enddate -noout -in certificate.crt

# Calculate days until expiration
echo "(" $(date -d "$(openssl x509 -enddate -noout -in certificate.crt | cut -d= -f2)" +%s) - $(date +%s) ")" / 86400 | bc

# Create a renewal CSR reusing the existing key (keeps the same public key)
openssl x509 -x509toreq -in certificate.crt -signkey private.key -out renewal.csr
```

Regular monitoring helps prevent unexpected expirations:

```bash
# Sample shell script to check certificate expiry
#!/bin/bash
CERT_FILE="certificate.crt"
DAYS_WARNING=30

# Get expiration date in seconds since epoch
EXPIRY=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt $DAYS_WARNING ]; then
  echo "WARNING: Certificate $CERT_FILE expires in $DAYS_LEFT days!"
  exit 1
else
  echo "Certificate $CERT_FILE is valid for $DAYS_LEFT more days."
  exit 0
fi
```

For production environments, consider dedicated certificate monitoring tools or services, or fully automated renewal via the [ACME section](../acme/index.md), which removes manual expiration tracking entirely.

## Navigation

[◄ Certificate Conversions](conversions.md) · [OpenSSL Guide](index.md) · [SSL/TLS Testing ►](tls-testing.md)
