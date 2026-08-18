---
title: Running a Private OpenSSL CA
description: Creating a certificate authority, signing certificates, and managing revocation with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-08-18
ms.topic: how-to
ms.service: security
---

## Running a Private CA

Operating your own certificate authority lets you issue certificates for internal services, lab environments, and systems that will never be reachable by a public CA. This page covers standing up a CA, signing certificates with it, and revoking them.

> [!NOTE]
> A private CA is only trusted by machines you have explicitly configured to trust it. For anything reachable from the public internet, use a publicly trusted CA — see the [ACME section](../acme/index.md) for automated issuance.

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
basicConstraints = critical, CA:FALSE
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
basicConstraints = critical, CA:FALSE
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

[◄ Certificate Operations](certificate-operations.md) · [OpenSSL Guide](index.md) · [Private Key Management ►](private-keys.md)
