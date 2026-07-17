---
title: OpenSSL Certificate Operations
description: Creating, viewing, and managing X.509 certificates, CAs, SANs, wildcards, and CRLs with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Certificate Operations

OpenSSL provides a robust set of tools for creating, inspecting, and managing X.509 certificates. This section covers the most common certificate operations and recommended practices.

### Creating Self-Signed Certificates

Self-signed certificates are useful for development environments, internal services, and testing. They are not suitable for production public-facing services as they generate browser warnings.

```bash
# Generate a self-signed certificate valid for 365 days
openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 365 -nodes

# Generate a self-signed certificate with subject information
openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"

# Generate a self-signed certificate with modern extensions and SHA-256
openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com" \
  -addext "extendedKeyUsage=serverAuth" \
  -sha256
```

> [!NOTE]
> Modern browsers require Subject Alternative Names (SANs) for proper certificate validation. The `-addext` option is available in OpenSSL 1.1.1 and later.

Best practices for self-signed certificates:

1. Use RSA 2048 bits or higher (4096 recommended) or ECC (Elliptic Curve) keys
2. Always include Subject Alternative Names (SANs)
3. Limit validity period (1 year maximum for development)
4. Store private keys securely with appropriate permissions

For a comprehensive guide on self-signed certificates, see the [Self-Signed Certificates](../self-signed.md) page.

### Viewing Certificate Information

Inspect certificate details to verify content and configuration:

```bash
# View complete certificate information in text format
openssl x509 -in certificate.crt -text -noout

# View certificate issuer
openssl x509 -in certificate.crt -issuer -noout

# View certificate subject
openssl x509 -in certificate.crt -subject -noout

# View certificate validity dates
openssl x509 -in certificate.crt -dates -noout

# View certificate validity dates in human-readable format
openssl x509 -in certificate.crt -noout -enddate | sed 's/notAfter=/Expires: /'
openssl x509 -in certificate.crt -noout -startdate | sed 's/notBefore=/Valid from: /'

# Calculate days until certificate expiration
openssl x509 -in certificate.crt -noout -enddate | cut -d= -f2 | xargs -I{} bash -c 'echo $(( ($(date -d "{}" +%s) - $(date +%s)) / 86400 )) days until expiration'

# View certificate fingerprint (SHA-256)
openssl x509 -in certificate.crt -fingerprint -sha256 -noout

# Check the certificate's purpose
openssl x509 -in certificate.crt -purpose -noout

# Extract the public key from a certificate
openssl x509 -in certificate.crt -pubkey -noout > pubkey.pem

# Check extensions (including SANs)
openssl x509 -in certificate.crt -text -noout | grep -A 10 "X509v3 Subject Alternative Name"

# Show the serial number (useful for certificate revocation)
openssl x509 -in certificate.crt -noout -serial

# Display the certificate in a human-readable format without header/footer
openssl x509 -in certificate.crt -noout -text -nameopt oneline,utf8,-esc_msb

# Check certificate chain
openssl verify -CAfile ca-chain.pem certificate.crt

# Checking certificate expiration date in human-readable format
openssl x509 -enddate -noout -in certificate.crt | sed 's/notAfter=/Expires: /'
```

> [!TIP]
> For routine certificate monitoring, create a simple shell script that checks expiration dates and alerts when certificates are nearing expiration (e.g., 30 days before).

### Certificate Chain Verification

Validating certificate chains is crucial for ensuring trust in the PKI infrastructure. A proper certificate chain connects an end-entity certificate to a trusted root CA through zero or more intermediate certificates.

```bash
# Verify a certificate against a trusted CA certificate
openssl verify -CAfile rootca.crt certificate.crt

# Verify a certificate with intermediate certificates
openssl verify -CAfile rootca.crt -untrusted intermediate.crt certificate.crt

# Alternative approach using a certificate bundle
cat intermediate.crt rootca.crt > ca-bundle.crt
openssl verify -CAfile ca-bundle.crt certificate.crt

# Verify a certificate with a complete chain (for web servers)
cat certificate.crt intermediate.crt rootca.crt > fullchain.pem
openssl verify -CAfile rootca.crt -untrusted intermediate.crt certificate.crt

# Display the full certificate chain from a remote server
openssl s_client -connect example.com:443 -showcerts

# Extract and verify individual certificates from a chain
openssl s_client -connect example.com:443 -showcerts </dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
```

Common certificate chain issues include:

1. **Missing Intermediate Certificates**: The chain is incomplete, causing trust failures
2. **Incorrect Chain Order**: Certificates not in proper sequence from end-entity to root
3. **Expired Certificates in Chain**: Any certificate in the chain has expired
4. **Cross-Signed Certificates**: Complex chains with cross-signed intermediate certificates

> [!IMPORTANT]
> Always include the complete certificate chain in server configurations. Missing intermediate certificates are one of the most common causes of certificate validation failures in client applications.

### Certificate Formats and Conversions

X.509 certificates can be stored in different formats depending on the application requirements:

```bash
# Convert PEM to DER format
openssl x509 -in certificate.pem -outform der -out certificate.der

# Convert DER to PEM format
openssl x509 -inform der -in certificate.der -out certificate.pem

# Convert PEM certificate to PKCS#12 (PFX) format including private key
openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt -certfile ca-chain.pem

# Extract certificate and key from PKCS#12 (PFX) file
openssl pkcs12 -in certificate.pfx -nocerts -out private.key -nodes
openssl pkcs12 -in certificate.pfx -nokeys -out certificate.crt

# Create a full chain certificate by concatenating certificates
cat certificate.crt intermediate.crt rootca.crt > fullchain.pem
```

Common certificate formats:

| Format | Description | Common Usage |
| ------- | ----------- | ------------ |
| PEM (.pem, .crt, .cer) | Base64 encoded with header/footer | Most web servers, OpenSSL |
| DER (.der, .cer) | Binary format | Java applications, Windows |
| PKCS#7 (.p7b, .p7c) | Certificate containers, no private key | Windows, Java Keystores |
| PKCS#12 (.pfx, .p12) | Contains certificates and private keys | Windows, macOS, mobile devices |

### Creating a Certificate Authority (CA)

Setting up your own CA is useful for managing certificates within an organization or for development environments. This example creates a complete CA structure:

```bash
# 1. Create a directory structure for your CA
mkdir -p ca/{certs,crl,newcerts,private}
touch ca/index.txt
echo 1000 > ca/serial

# 2. Create a CA configuration file
cat > ca.conf << EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./ca
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

private_key       = \$dir/private/ca.key
certificate       = \$dir/certs/ca.crt

crl               = \$dir/crl/ca.crl
crlnumber         = \$dir/crlnumber
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

# 3. Create a private key for the CA
openssl genrsa -aes256 -out ca/private/ca.key 4096
chmod 400 ca/private/ca.key

# 4. Create a self-signed CA certificate
openssl req -config ca.conf -key ca/private/ca.key -new -x509 -days 3650 -sha256 \
  -extensions v3_ca -out ca/certs/ca.crt

# 5. Verify the CA certificate
openssl x509 -noout -text -in ca/certs/ca.crt
```

> [!IMPORTANT]
> Best practices for managing a Certificate Authority:
>
> 1. Keep the CA private key extremely secure, preferably offline
> 2. Use strong passphrases for CA keys
> 3. Set appropriate validity periods (root CAs can be valid for 10+ years)
> 4. Implement strict issuance policies
> 5. Maintain proper revocation mechanisms (CRLs and/or OCSP)
> 6. Consider a two-tier CA hierarchy with root and intermediate CAs for added security

### Signing Certificates with Your CA

Once your CA is set up, you can sign certificate requests. This is the typical workflow for issuing certificates from your CA:

```bash
# 1. Create a server key and CSR
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

# 2. Create a configuration file for the server certificate
cat > server.conf << EOF
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
EOF

# 3. Sign the CSR with the CA
openssl ca -config ca.conf -extensions server_cert -days 365 -notext \
  -md sha256 -in server.csr -out server.crt -extfile server.conf

# 4. Verify the signed certificate
openssl verify -CAfile ca/certs/ca.crt server.crt

# 5. Create a certificate chain file (if needed)
cat server.crt ca/certs/ca.crt > server-chain.crt
```

Certificate validity periods should follow industry best practices:

| Certificate Type | Recommended Validity | Notes |
| ---------------- | -------------------- | ----- |
| Root CA | 10-20 years | Keep offline, used only to sign intermediates |
| Intermediate CA | 5-10 years | Used for routine certificate signing |
| Server/Client | 1 year or less | Public CAs now limit to 398 days |
| Code Signing | 1-3 years | Often requires hardware security |
| Email (S/MIME) | 1-3 years | Tied to individual identity |

> [!NOTE]
> Starting September 2020, major browsers limit the maximum validity period of publicly trusted TLS certificates to 398 days.

### Creating Certificates with Subject Alternative Names (SANs)

Modern browsers require Subject Alternative Names (SANs) for proper certificate validation. Here's a comprehensive approach:

```bash
# 1. Create a configuration file for SANs
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
CN = example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = api.example.com
DNS.4 = admin.example.com
IP.1 = 192.168.1.1
EOF

# 2. Generate key and CSR with SANs
openssl req -new -nodes -newkey rsa:2048 -keyout server_san.key \
  -out server_san.csr -config san.conf

# 3. Verify the SANs in the CSR
openssl req -in server_san.csr -noout -text | grep -A 1 "Subject Alternative Name"

# 4. Sign the CSR with your CA (if you have one)
# openssl ca -config ca.conf -extensions v3_req -days 365 -notext \
#   -md sha256 -in server_san.csr -out server_san.crt -extfile san.conf

# For self-signed certificate with SANs:
openssl x509 -req -in server_san.csr -signkey server_san.key \
  -out server_san.crt -days 365 -sha256 -extfile san.conf -extensions v3_req

# 5. Verify SANs in the final certificate
openssl x509 -in server_san.crt -text -noout | grep -A 1 "Subject Alternative Name"
```

> [!WARNING]
> If SANs are not included in a certificate, modern browsers will show security warnings regardless of whether the Common Name (CN) matches the domain. Always include all domain names that will be used with the certificate.

SANs can include:

- Multiple domain names (DNS.x entries)
- IP addresses (IP.x entries)
- Email addresses (email.x entries)
- URI entries (URI.x entries)

### Wildcard Certificates

Wildcard certificates secure a domain and all its first-level subdomains. They provide flexibility but have security tradeoffs:

```bash
# Create a wildcard certificate configuration
cat > wildcard.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = *.example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.example.com
DNS.2 = example.com
EOF

# Generate a wildcard certificate (self-signed for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout wildcard.key -out wildcard.crt -config wildcard.conf

# Verify the wildcard certificate
openssl x509 -in wildcard.crt -text -noout | grep -A 1 "Subject Alternative Name"
```

> [!NOTE]
> Wildcard certificates have important limitations:
>
> - They only cover one level of subdomains (*.example.com covers test.example.com but not sub.test.example.com)
> - Compromise of a wildcard certificate affects all subdomains
> - Some security standards (like PCI DSS) restrict wildcard certificate usage
> - They expose a larger attack surface if the private key is compromised

Consider using multi-domain certificates with explicit SANs as a more secure alternative to wildcards in high-security environments.

### Managing Certificate Revocation Lists (CRLs)

When certificates need to be invalidated before expiry, CRLs provide a way to notify clients:

```bash
# 1. Ensure CRL number file exists
echo 01 > ca/crlnumber

# 2. Create a CRL configuration file
cat > crl.conf << EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir = ./ca
database = \$dir/index.txt
crlnumber = \$dir/crlnumber

default_days = 30
default_crl_days = 30
default_md = sha256

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF

# 3. Generate an initial CRL
openssl ca -config crl.conf -gencrl -out ca/crl/ca.crl

# 4. View CRL information
openssl crl -in ca/crl/ca.crl -text -noout

# 5. Revoke a certificate (specify a reason)
openssl ca -config ca.conf -revoke server.crt -crl_reason keyCompromise
# Valid reasons: unspecified, keyCompromise, CACompromise, affiliationChanged,
#                superseded, cessationOfOperation, certificateHold, removeFromCRL

# 6. Generate updated CRL after revocation
openssl ca -config crl.conf -gencrl -out ca/crl/ca.crl

# 7. Configure web server to serve the CRL at a well-known URL
# Example for nginx:
# location /crl/ {
#   types { } default_type "application/pkix-crl";
#   alias /path/to/ca/crl/;
# }

# 8. Update certificates to include CRL distribution point
# Add to the [v3_req] section in your certificate config:
# crlDistributionPoints = URI:http://example.com/crl/ca.crl
```

#### CRL vs. OCSP

Certificate revocation status can be checked through two main methods:

| Method | Advantages | Disadvantages |
| ------ | ---------- | ------------- |
| CRL | Simple implementation | Can grow large over time |
| | Works offline once downloaded | Potentially stale data |
| | Single file for many certificates | Full list must be downloaded |
| OCSP | Real-time status | Requires online verification |
| | Smaller network footprint | Privacy concerns |
| | More current information | Single point of failure |
| | Only queries needed certificates | More complex to implement |

For high-security environments, consider implementing both CRL and OCSP for redundancy.

## Navigation

[◄ Basic Concepts](basic-concepts.md) · [OpenSSL Guide](index.md) · [Private Key Management ►](private-keys.md)
