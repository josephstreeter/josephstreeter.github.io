---
title: Self-Signed Certificates
description: Comprehensive guide to creating and managing self-signed certificates with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2024-09-21
ms.topic: conceptual
ms.service: security
---

## Self-Signed Certificates

Self-signed certificates are digital certificates that are signed by the same entity whose identity they certify rather than by a trusted Certificate Authority (CA). They are useful for development environments, internal systems, and testing purposes.

### Understanding Self-Signed Certificates

#### Advantages

- **No Cost**: No need to pay for a certificate from a commercial CA
- **Quick Creation**: Can be generated instantly without waiting for approval
- **Full Control**: Complete control over certificate parameters and lifecycle
- **Independence**: No reliance on external CAs

#### Limitations

- **Trust Issues**: Browsers and clients display security warnings
- **No Validation**: No third-party verification of identity
- **Limited Validity**: Many systems restrict validity periods
- **Manual Trust**: Clients must manually trust the certificate

### Creating Basic Self-Signed Certificates

```bash
# Generate a private key and self-signed certificate in one command
openssl req -x509 -newkey rsa:4096 -keyout selfsigned.key -out selfsigned.crt -days 365 -nodes

# Interactive prompts will ask for certificate information
# Country Name, State, Locality, Organization, Common Name, etc.
```

### Creating Self-Signed Certificates with Non-Interactive Mode

```bash
# Generate with subject information provided on command line
openssl req -x509 -newkey rsa:4096 -keyout selfsigned.key -out selfsigned.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"
```

### Creating Self-Signed Certificates with Subject Alternative Names (SANs)

SANs allow a single certificate to secure multiple domain names or IP addresses.

```bash
# Create a configuration file for SAN
cat > san.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = US
ST = State
L = City
O = Organization
OU = Department
CN = example.com

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = mail.example.com
IP.1 = 192.168.1.1
EOF

# Generate self-signed certificate with SANs
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout san_selfsigned.key -out san_selfsigned.crt \
  -config san.conf
```

### Creating Self-Signed Wildcard Certificates

Wildcard certificates secure a domain and all its subdomains.

```bash
# Generate a wildcard certificate
openssl req -x509 -newkey rsa:4096 -keyout wildcard.key -out wildcard.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=*.example.com"
```

### Creating Self-Signed Certificates with Extended Validity

```bash
# Generate a certificate valid for 10 years (use with caution)
openssl req -x509 -newkey rsa:4096 -keyout longterm.key -out longterm.crt -days 3650 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"
```

### Customizing Key Usage and Extended Key Usage

```bash
# Create a configuration file with custom key usage
cat > keyusage.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = US
ST = State
L = City
O = Organization
OU = Department
CN = example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
EOF

# Generate certificate with custom key usage
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout custom_keyusage.key -out custom_keyusage.crt \
  -config keyusage.conf
```

### Self-Signed Certificate Verification

```bash
# View the contents of a self-signed certificate
openssl x509 -in selfsigned.crt -text -noout

# Verify certificate dates
openssl x509 -in selfsigned.crt -noout -dates

# Verify self-signed status
openssl verify selfsigned.crt
# Will show "self-signed certificate" verification error

# Verify with the certificate as its own trusted CA
openssl verify -CAfile selfsigned.crt selfsigned.crt
# Should show "OK"
```

### Converting Self-Signed Certificates

```bash
# Convert self-signed certificate to PEM format (if not already)
openssl x509 -in selfsigned.crt -out selfsigned.pem -outform PEM

# Create a PKCS#12 file with the certificate and key
openssl pkcs12 -export -out selfsigned.pfx -inkey selfsigned.key -in selfsigned.crt
# Will prompt for export password
```

### Deploying Self-Signed Certificates

#### Web Server Deployment

For Apache:

```bash
# Copy the files to appropriate location
sudo cp selfsigned.crt /etc/ssl/certs/
sudo cp selfsigned.key /etc/ssl/private/

# Update Apache configuration (example)
sudo nano /etc/apache2/sites-available/default-ssl.conf
# Add or modify:
# SSLCertificateFile /etc/ssl/certs/selfsigned.crt
# SSLCertificateKeyFile /etc/ssl/private/selfsigned.key
```

For Nginx:

```bash
# Copy the files to appropriate location
sudo cp selfsigned.crt /etc/nginx/ssl/
sudo cp selfsigned.key /etc/nginx/ssl/

# Update Nginx configuration (example)
sudo nano /etc/nginx/sites-available/default
# Add or modify:
# ssl_certificate /etc/nginx/ssl/selfsigned.crt;
# ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
```

### Best Practices for Self-Signed Certificates

1. **Limit Usage**: Use only in development, testing, or secure internal environments
2. **Strong Keys**: Use at least 2048-bit RSA keys (4096-bit recommended)
3. **Include SANs**: Always include all relevant domain names and IPs as SANs
4. **Proper CN**: Ensure the Common Name matches the primary domain name
5. **Reasonable Validity**: Use appropriate validity periods (1-3 years for internal use)
6. **Secure Storage**: Protect private keys with proper permissions
7. **Documentation**: Document all certificates, including creation date and purpose
8. **Regular Rotation**: Establish a process for regular certificate rotation
