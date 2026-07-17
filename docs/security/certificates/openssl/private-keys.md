---
title: OpenSSL Private Key Management
description: Generating, protecting, analyzing, and converting private keys with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## Private Key Management

Proper management of private keys is critical for security. OpenSSL provides comprehensive tools for generating, protecting, analyzing, and converting private keys for various applications.

### Generating Private Keys

OpenSSL supports multiple key types and encryption algorithms to meet different security requirements:

```bash
# Generate an RSA private key (2048 bits - minimum recommended)
openssl genrsa -out private_key_2048.key 2048

# Generate an RSA private key (4096 bits - higher security)
openssl genrsa -out private_key_4096.key 4096

# Generate an RSA private key with AES-256 encryption (password-protected)
openssl genrsa -aes256 -out encrypted_private.key 4096

# Generate an EC private key (using prime256v1 curve - NIST P-256)
openssl ecparam -name prime256v1 -genkey -noout -out ec_private.key

# Generate an EC private key with encryption
openssl ecparam -name prime256v1 -genkey | openssl ec -aes256 -out ec_encrypted.key

# Generate an EC private key with explicit curve parameters (for specialized applications)
openssl ecparam -name secp384r1 -genkey -param_enc explicit -out ec_explicit.key

# Generate an Ed25519 key (OpenSSL 1.1.1+) - modern, high-performance
openssl genpkey -algorithm ED25519 -out ed25519_private.key

# Generate an Ed25519 key with encryption
openssl genpkey -algorithm ED25519 -out ed25519_encrypted.key -aes-256-cbc
```

### Key Types and Algorithms

When selecting a key type, consider security requirements, performance needs, and compatibility:

| Key Type | Command | Bit Size | Security Level | Use Case | Compatibility |
| -------- | ------- | -------- | -------------- | -------- | ------------- |
| RSA-2048 | genrsa | 2048 | Standard | General purpose | Universal |
| RSA-3072 | genrsa | 3072 | High | Long-term security | Universal |
| RSA-4096 | genrsa | 4096 | Very High | Critical infrastructure | Universal but slower |
| ECC (P-256) | ecparam | 256 | High | Mobile/IoT, limited CPU | Modern systems |
| ECC (P-384) | ecparam | 384 | Very High | Government/Financial | Modern systems |
| Ed25519 | genpkey | 256 | High | High-performance signing | Newer systems only |
| X25519 | genpkey | 256 | High | Key exchange (ECDH) | Modern TLS 1.3 |
| Ed448 | genpkey | 448 | Very High | High-security signing | Newest systems only |
| X448 | genpkey | 448 | Very High | High-security key exchange | Newest systems only |

> [!NOTE]
> Security equivalence: RSA-2048 ≈ ECC-224, RSA-3072 ≈ ECC-256, RSA-7680 ≈ ECC-384, RSA-15360 ≈ ECC-521. ECC provides equivalent security with smaller keys and better performance.

```bash
# Generate Ed25519 key (OpenSSL 1.1.1+)
openssl genpkey -algorithm ED25519 -out ed25519_key.pem

# View Ed25519 key details
openssl pkey -in ed25519_key.pem -text -noout

# Generate X25519 key for ECDH key exchange
openssl genpkey -algorithm X25519 -out x25519_key.pem

# Extract public key from Ed25519 private key
openssl pkey -in ed25519_key.pem -pubout -out ed25519_public.pem

# Generate Ed448 key (OpenSSL 1.1.1+)
openssl genpkey -algorithm ED448 -out ed448_key.pem

# Generate X448 key for high-security key exchange
openssl genpkey -algorithm X448 -out x448_key.pem
```

### Working with Encrypted Keys

Password protection adds an essential security layer to private keys:

```bash
# Encrypt an existing unprotected private key
openssl rsa -in unencrypted.key -aes256 -out encrypted.key

# Decrypt an encrypted private key (removes password protection - use with caution)
openssl rsa -in encrypted.key -out decrypted.key

# Change the password on an already-encrypted key
openssl rsa -in encrypted.key -aes256 -out new_encrypted.key

# Check if a key is encrypted
cat private.key | grep -i "ENCRYPTED"
# Or try to read without password:
openssl rsa -in private.key -noout -check 2>/dev/null || echo "Key is encrypted"

# Create a strong password for key encryption
openssl rand -base64 48

# Create a protected key with PKCS#8 and stronger key derivation (more secure)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 | 
  openssl pkcs8 -topk8 -v2 aes-256-cbc -iter 100000 -out strong_encrypted.key
```

### Verifying and Analyzing Keys

Always verify the integrity and properties of private keys:

```bash
# Check a private key's validity
openssl rsa -in private.key -check -noout

# Display detailed private key components (modulus, exponents, etc.)
openssl rsa -in private.key -text -noout

# Show just the key's modulus (useful for key matching)
openssl rsa -in private.key -noout -modulus

# Get key size in bits
openssl rsa -in private.key -text -noout | grep "Private-Key"

# Verify an EC key
openssl ec -in ec_private.key -check -noout

# Check EC key details and curve
openssl ec -in ec_private.key -text -noout | grep "ASN1 OID"

# Verify if a private key matches a certificate (hashes should match)
echo "Certificate: $(openssl x509 -noout -modulus -in certificate.crt | openssl md5)"
echo "Private Key: $(openssl rsa -noout -modulus -in private.key | openssl md5)"

# Verify if a private key matches a CSR
echo "CSR: $(openssl req -noout -modulus -in request.csr | openssl md5)"
echo "Private Key: $(openssl rsa -noout -modulus -in private.key | openssl md5)"
```

### Extracting Public Keys

Extract public keys for various purposes:

```bash
# Extract public key from private RSA key
openssl rsa -in private.key -pubout -out public.key

# Extract public key from private EC key
openssl ec -in ec_private.key -pubout -out ec_public.key

# Extract public key from private Ed25519 key
openssl pkey -in ed25519_private.key -pubout -out ed25519_public.key

# Extract public key from certificate
openssl x509 -in certificate.crt -pubkey -noout > public_from_cert.key

# Extract public key from CSR
openssl req -in request.csr -pubkey -noout > public_from_csr.key

# View public key details
openssl pkey -in public.key -pubin -text -noout

# Calculate public key fingerprint (for SSH or verification)
openssl pkey -in public.key -pubin -outform DER | openssl dgst -sha256 -binary | openssl base64
```

### Secure Random Number Generation

Cryptographic operations rely on strong random number generation. OpenSSL provides tools for generating and working with random data:

```bash
# Generate random bytes (binary output)
openssl rand 32

# Generate random bytes (base64 encoded)
openssl rand -base64 32

# Generate random bytes (hex encoded)
openssl rand -hex 32

# Generate random password with specific character set
openssl rand -base64 15 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+?><~'

# Create a random symmetric key (e.g., for AES-256)
openssl rand -out aes_key.bin 32

# Generate a random initialization vector (IV)
openssl rand -out iv.bin 16

# Test randomness quality
openssl rand 1000000 | openssl dgst -sha256

# Use pseudorandom data for testing (NOT for production)
openssl rand -engine rdrand -out test_random.bin 32
```

> [!IMPORTANT]
> Secure random number generation is critical for cryptographic security. Always ensure:
>
> - Your system has sufficient entropy sources
> - Use hardware-based random number generators when available
> - Never use predictable seeds or weak PRNGs for key generation
> - For virtual machines, consider entropy augmentation solutions
> - Test your random number generator quality with tools like `rngtest` or `ent`

### Converting Between Key Formats

Convert keys between formats for compatibility with different systems:

```bash
# Convert traditional RSA key to PKCS#8 format (modern standard)
openssl pkcs8 -topk8 -nocrypt -in private.key -out private.p8

# Convert to PKCS#8 with strong encryption (recommended for storage)
openssl pkcs8 -topk8 -in private.key -out encrypted.p8 -v2 aes-256-cbc -iter 100000

# Convert PKCS#8 back to traditional format
openssl rsa -in private.p8 -out traditional.key

# Convert PEM to DER format (binary)
openssl rsa -in private.key -outform DER -out private.der

# Convert DER to PEM format (text)
openssl rsa -in private.der -inform DER -out private.pem

# Convert private key to PKCS#12 format (with certificate)
openssl pkcs12 -export -out certificate.p12 -inkey private.key -in certificate.crt -certfile ca-chain.crt

# Extract private key from PKCS#12 
openssl pkcs12 -in certificate.p12 -nocerts -out private_from_p12.key

# Convert EC key to traditional PEM format
openssl ec -in ec_key.pem -out ec_traditional.pem

# Convert SSH public key to OpenSSL format (if you have the SSH public key)
ssh-keygen -e -m PKCS8 -f id_rsa.pub > ssh_key_openssl.pem
```

### Enhanced Key Security Practices

Implement these additional measures for sensitive key material:

```bash
# Set proper file permissions
chmod 600 private.key  # Owner read/write only
chmod 400 encrypted.key  # Owner read only (good for backup copies)

# Verify file permissions
stat -c "%a %n" private.key

# Create a secure backup of critical keys
tar -cz -f keys-backup.tar.gz *.key
openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in keys-backup.tar.gz -out keys-backup.enc

# Create key usage audit log
echo "$(date) - $(whoami) - Generated key: $(openssl rsa -in private.key -noout -modulus | openssl md5)" >> key_audit.log

# Use hardware security if available (example for YubiKey)
yubico-piv-tool -s 9c -a generate -o public.pem

# Securely delete key material when no longer needed
shred -u -z -n 3 unneeded_key.pem
```

> [!IMPORTANT]
> For critical infrastructure and high-security environments:
>
> 1. Consider hardware security modules (HSMs) instead of file-based keys
> 2. Implement key custodian procedures with multi-person access controls
> 3. Establish formal key management policies including rotation schedules
> 4. Maintain an inventory of all cryptographic keys with owners and purposes
> 5. Perform regular key security audits

## Navigation

[◄ Certificate Operations](certificate-operations.md) · [OpenSSL Guide](index.md) · [CSR Creation and Management ►](csr.md)
