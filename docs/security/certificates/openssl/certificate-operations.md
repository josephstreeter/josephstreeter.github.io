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

Every inspection command below uses `openssl x509`. Two options appear throughout and are worth learning first:

- `-in <file>` names the certificate to read.
- `-noout` suppresses the re-printed PEM blob. Without it, every command dumps the whole encoded certificate after its output. You almost always want it.

#### Read the whole certificate

The catch-all command. Use it when you don't yet know what you're looking for:

```bash
openssl x509 -in certificate.crt -text -noout
```

This prints everything — version, serial, issuer, validity, public key, and all extensions. It is verbose; the targeted commands below are easier to read when you know which field you need.

#### Check who a certificate is for, and who issued it

```bash
openssl x509 -in certificate.crt -subject -issuer -noout
```

```text
subject=C = US, ST = State, L = City, O = Example Corp, CN = example.com
issuer=C = US, ST = State, L = City, O = Example Corp, CN = Example Corp Issuing CA
```

When `subject` and `issuer` are identical, the certificate is self-signed — it is either a root CA or a certificate that no CA vouched for.

#### Check the validity period

```bash
openssl x509 -in certificate.crt -dates -noout
```

```text
notBefore=Aug 18 15:27:36 2026 GMT
notAfter=Aug 18 15:27:36 2027 GMT
```

To test expiry without reading dates yourself, use `-checkend`, which takes a number of seconds and sets the exit status. This is the right building block for monitoring scripts, and unlike date arithmetic it is portable across Linux and macOS:

```bash
# Exit status 0 = still valid in 30 days, 1 = expires within 30 days
openssl x509 -in certificate.crt -noout -checkend 2592000 \
  && echo "OK" || echo "WARNING: expires within 30 days"
```

#### Check which hostnames a certificate covers

Clients match the hostname against the Subject Alternative Name extension, not the Common Name. Read the SANs directly:

```bash
openssl x509 -in certificate.crt -ext subjectAltName -noout
```

```text
X509v3 Subject Alternative Name:
    DNS:example.com, DNS:www.example.com
```

To test one specific name, let OpenSSL apply the matching rules (including wildcards) rather than reading the list yourself:

```bash
openssl x509 -in certificate.crt -noout -checkhost www.example.com
openssl x509 -in certificate.crt -noout -checkhost wrong.example.net
```

```text
Hostname www.example.com does match certificate
Hostname wrong.example.net does NOT match certificate
```

#### Confirm a private key belongs to a certificate

A certificate and key match when their public moduli match. Hash each one so you compare short strings instead of long ones:

```bash
openssl x509 -noout -modulus -in certificate.crt | openssl sha256
openssl rsa  -noout -modulus -in private.key     | openssl sha256
```

```text
SHA2-256(stdin)= beb0e5c3202503ce9a571cbaad4fe7abccad2c1042d09f25edd553988863ccab
SHA2-256(stdin)= beb0e5c3202503ce9a571cbaad4fe7abccad2c1042d09f25edd553988863ccab
```

Identical hashes mean the key belongs to the certificate. Different hashes mean it does not — a common cause of a web server refusing to start after a certificate renewal.

> [!NOTE]
> This modulus comparison works for RSA only. For EC keys, compare the public keys instead: `openssl x509 -in certificate.crt -pubkey -noout` against `openssl ec -in ec_private.key -pubout`.

#### Other useful fields

```bash
# SHA-256 fingerprint — used to pin or identify a certificate
openssl x509 -in certificate.crt -fingerprint -sha256 -noout

# Serial number — the value you need when revoking
openssl x509 -in certificate.crt -serial -noout

# What the certificate is approved for
openssl x509 -in certificate.crt -purpose -noout

# Extract the public key
openssl x509 -in certificate.crt -pubkey -noout > pubkey.pem
```

```text
sha256 Fingerprint=AF:1D:04:28:E6:CA:3F:AC:B7:02:F9:88:C8:9F:27:74:C2:4D:93:9E:91:22:51:21:E0:D6:0E:0B:6E:B8:F9:33
serial=75CD2BFF34E9ED9EBCFEDEE4CD941C994C53228D
```

> [!TIP]
> For ongoing monitoring, build on `-checkend` rather than parsing dates. A worked example is in [Certificate Expiration, Renewal, and Monitoring](validation-troubleshooting.md#certificate-expiration-renewal-and-monitoring).

### Certificate Chain Verification

A certificate is trusted only if it links back to a trusted root, through however many intermediate CAs sit between them. `openssl verify` walks that path and tells you whether it completes.

The command takes trust material through two separate options, and mixing them up is the usual reason verification fails when the certificate is fine:

- `-CAfile` supplies the **trust anchor** — the root you have decided to trust.
- `-untrusted` supplies **intermediates**, which help build the path but are not themselves trusted.

#### Verify a certificate

```bash
openssl verify -CAfile rootca.crt -untrusted intermediate.crt certificate.crt
```

```text
certificate.crt: OK
```

`OK` means a complete path was built to the trust anchor and every signature and validity period along it checked out.

If you keep intermediates and the root together in one bundle, pass the bundle as the trust anchor instead — the result is the same:

```bash
cat intermediate.crt rootca.crt > ca-chain.crt
openssl verify -CAfile ca-chain.crt certificate.crt
```

#### Read the failure messages

The two most common failures look similar but mean different things. Both name the certificate at which the path broke, and the `depth` tells you how far up the chain that was:

```bash
# Root supplied, but the intermediate that links to it is missing
openssl verify -CAfile rootca.crt certificate.crt
```

```text
C = US, ST = State, L = City, O = Example Corp, CN = example.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error certificate.crt: verification failed
```

**Error 20 at depth 0** — OpenSSL could not find the issuer of the leaf certificate itself. The intermediate is missing. This is by far the most common chain problem, and the same root cause behind browsers trusting a site on one machine but not another.

```bash
# Intermediate supplied as the anchor, but the root behind it is missing
openssl verify -CAfile intermediate.crt certificate.crt
```

```text
C = US, ST = State, L = City, O = Example Corp, CN = Example Corp Issuing CA
error 2 at 1 depth lookup: unable to get issuer certificate
error certificate.crt: verification failed
```

**Error 2 at depth 1** — the path got as far as the intermediate, then ran out. Note the subject line names the *intermediate*, not the leaf: the depth number tells you which certificate in the chain is the problem.

To check against the operating system's trust store rather than a file you supply, drop `-CAfile` and use `-CApath`:

```bash
openssl verify -CApath /etc/ssl/certs certificate.crt
```

#### Build the chain a server sends

`fullchain.pem` is a deployment artifact, not a verification input. It holds the leaf first, then intermediates — and it omits the root, which clients already have:

```bash
cat certificate.crt intermediate.crt > fullchain.pem
```

Getting the order wrong, or omitting the intermediate, produces exactly the error 20 shown above on the client side.

#### Inspect a live server's chain

```bash
# Show every certificate the server sends
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null

# Split them into separate files for inspection
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
```

> [!IMPORTANT]
> A server must send its intermediates. Browsers often paper over a missing one by fetching it or reusing a cached copy, so a site can appear fine in your browser and fail for API clients, mobile apps, and `curl`. Always confirm with `s_client` rather than trusting a green padlock.

Other chain problems worth knowing: certificates in the wrong order, an expired certificate anywhere in the path (not just the leaf), and cross-signed intermediates, where more than one valid path exists and clients may not all pick the same one.

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

# 4. To sign this CSR with your own CA instead, see "Running a Private CA":
# openssl ca -config ca.conf -extensions server_cert -days 365 -notext \
#   -md sha256 -in server_san.csr -out server_san.crt -extfile san.conf

# For a self-signed certificate with SANs:
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

### Related Pages

- [Certificate Conversions](conversions.md) — moving certificates between PEM, DER, PKCS#7, PKCS#12, and JKS
- [Running a Private CA](private-ca.md) — issuing and revoking certificates from your own CA
- [Validation and Troubleshooting](validation-troubleshooting.md) — diagnosing verification failures in depth

## Navigation

[◄ Basic Concepts](basic-concepts.md) · [OpenSSL Guide](index.md) · [Running a Private CA ►](private-ca.md)
