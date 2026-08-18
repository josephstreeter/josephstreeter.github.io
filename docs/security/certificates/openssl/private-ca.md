---
title: Running a Private OpenSSL CA
description: Building a two-tier certificate authority, issuing certificates, and managing revocation with OpenSSL
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-08-18
ms.topic: how-to
ms.service: security
---

## Running a Private CA

Operating your own certificate authority lets you issue certificates for internal services, lab environments, and systems a public CA will never be able to validate. This page builds a working CA, issues a server certificate from it, and revokes one.

> [!NOTE]
> A private CA is trusted only by machines you have explicitly configured to trust it. For anything reachable from the public internet, use a publicly trusted CA — see the [ACME section](../acme/index.md) for automated issuance.

### Choosing a CA Structure

How many tiers you need depends on how much you would lose if the top-level key were compromised.

| Structure | Shape | Use when |
| --------- | ----- | -------- |
| Single-tier | Root signs leaf certificates directly | Short-lived labs and throwaway test environments only |
| **Two-tier** | Offline root → issuing CA → leaf certificates | **The normal choice for organizations.** What this page builds |
| Three-tier | Offline root → policy CA → issuing CA → leaf | Large deployments needing separate issuance policies per region or business unit |

The reason to prefer two tiers is containment. The root's private key is used exactly once — to sign the issuing CA — and then goes offline, ideally on removable media or in an HSM. Day-to-day signing happens with the issuing CA key, which is online and therefore exposed. If that key is compromised, you revoke the issuing CA and rebuild it from the still-safe root, rather than reinstalling a new trust anchor on every machine in the estate.

A single-tier CA offers no such recovery: the key that signs certificates every day is the same key every client trusts.

> [!TIP]
> Three tiers are rarely justified outside large Microsoft ADCS deployments. The extra policy CA layer exists to enforce different issuance rules per subordinate, not to add security. If you cannot name the policies it would separate, build two tiers.

### Directory Layout

Each CA needs its own key, certificate, and the state files `openssl ca` uses to track what it has issued:

```bash
mkdir -p root/{private,certs,newcerts,crl} issuing/{private,certs,newcerts,crl}
chmod 700 root/private issuing/private

# The certificate database, and the counters for serials and CRL numbers
touch root/index.txt issuing/index.txt
echo 1000 > root/serial;    echo 1000 > issuing/serial
echo 1000 > root/crlnumber; echo 1000 > issuing/crlnumber
```

`index.txt` is the CA database — `openssl ca` appends a line per issued certificate and rewrites it on revocation. It is the authoritative record of what your CA has issued, so back it up alongside the keys. Losing it means you can no longer generate an accurate CRL.

### Step 1: Configure the Root CA

Save this as `root-ca.conf`. Adjust the DN under `[ req_distinguished_name ]` for your organization:

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./root
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
crlnumber         = $dir/crlnumber

private_key       = $dir/private/rootca.key
certificate       = $dir/certs/rootca.crt

crl               = $dir/crl/rootca.crl
crl_extensions    = crl_ext
default_crl_days  = 180

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 3650
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
prompt              = no
x509_extensions     = v3_root_ca

[ req_distinguished_name ]
C  = US
ST = State
O  = Example Corp
CN = Example Corp Root CA

[ v3_root_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true
keyUsage               = critical, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, cRLSign, keyCertSign

[ crl_ext ]
authorityKeyIdentifier = keyid:always
```

Two settings carry most of the weight here:

- **`policy = policy_strict`** forces any CA signed by this root to share its country, state, and organization. It is a guard against the root signing a subordinate for an unrelated organization.
- **`pathlen:0`** in `v3_intermediate_ca` means the issuing CA may sign leaf certificates but **cannot** sign further CAs. Without it, a compromised issuing CA could mint its own subordinates. This single constraint is the most commonly omitted part of a two-tier build.

### Step 2: Create the Root CA

```bash
# Generate the root key, encrypted with AES-256 (you will be prompted for a passphrase)
openssl genrsa -aes256 -out root/private/rootca.key 4096
chmod 400 root/private/rootca.key

# Self-sign the root certificate, valid for 20 years
openssl req -config root-ca.conf -key root/private/rootca.key \
  -new -x509 -days 7300 -sha256 -extensions v3_root_ca -out root/certs/rootca.crt
```

Confirm it came out as a CA:

```bash
openssl x509 -in root/certs/rootca.crt -noout -subject -ext basicConstraints,keyUsage
```

```text
subject=C = US, ST = State, O = Example Corp, CN = Example Corp Root CA
X509v3 Basic Constraints: critical
    CA:TRUE
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
```

`CA:TRUE` with `Certificate Sign` is what makes this usable as a trust anchor. A certificate without both cannot sign anything.

### Step 3: Configure the Issuing CA

Save this as `issuing-ca.conf`:

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./issuing
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
crlnumber         = $dir/crlnumber

private_key       = $dir/private/issuingca.key
certificate       = $dir/certs/issuingca.crt

crl               = $dir/crl/issuingca.crl
crl_extensions    = crl_ext
default_crl_days  = 7

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_loose
copy_extensions   = copy

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
prompt              = no

[ req_distinguished_name ]
C  = US
ST = State
O  = Example Corp
CN = Example Corp Issuing CA

[ server_cert ]
basicConstraints       = critical, CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth

[ crl_ext ]
authorityKeyIdentifier = keyid:always
```

The issuing CA uses `policy_loose` because it issues to many teams whose organization fields may legitimately differ. It also sets `copy_extensions = copy`, which matters more than it looks — see the warning in Step 5.

### Step 4: Create and Sign the Issuing CA

The issuing CA is created like any other certificate holder: it generates a key and a CSR, and the root signs it.

```bash
# 1. Generate the issuing CA key
openssl genrsa -aes256 -out issuing/private/issuingca.key 4096
chmod 400 issuing/private/issuingca.key

# 2. Create a CSR for it
openssl req -config issuing-ca.conf -key issuing/private/issuingca.key \
  -new -sha256 -out issuing/issuingca.csr

# 3. Sign it with the ROOT CA, applying the pathlen:0 constraint
openssl ca -config root-ca.conf -extensions v3_intermediate_ca \
  -days 3650 -notext -md sha256 \
  -in issuing/issuingca.csr -out issuing/certs/issuingca.crt
```

`openssl ca` shows you what it is about to sign and asks for confirmation:

```text
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Aug 18 15:38:55 2026 GMT
            Not After : Aug 15 15:38:55 2036 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = State
            organizationName          = Example Corp
            commonName                = Example Corp Issuing CA
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
Certificate is to be certified until Aug 15 15:38:55 2036 GMT (3650 days)
Sign the certificate? [y/n]:y

Write out database with 1 new entries
Database updated
```

Read `CA:TRUE, pathlen:0` before answering — that line confirms the constraint took effect. Then verify the issuing CA chains to the root:

```bash
openssl verify -CAfile root/certs/rootca.crt issuing/certs/issuingca.crt
```

```text
issuing/certs/issuingca.crt: OK
```

> [!IMPORTANT]
> The root has now done its only job. Move `root/private/rootca.key` offline — removable media held in a safe, or an HSM — and keep it there until you need to issue another subordinate or a new CRL. A root key that stays on a networked machine gives you a single-tier CA with extra steps.

### Step 5: Issue a Server Certificate

Certificates are now issued by the **issuing** CA, not the root:

```bash
# 1. The requester generates a key and CSR, including the hostnames as SANs
openssl req -new -newkey rsa:2048 -nodes -keyout private.key -out request.csr -sha256 \
  -subj "/C=US/ST=State/O=Example Corp/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com"

# 2. The issuing CA signs it
openssl ca -config issuing-ca.conf -extensions server_cert \
  -days 365 -notext -md sha256 \
  -in request.csr -out certificate.crt
```

Confirm the hostnames survived into the issued certificate:

```bash
openssl x509 -in certificate.crt -noout -ext subjectAltName
```

```text
X509v3 Subject Alternative Name:
    DNS:example.com, DNS:www.example.com
```

> [!WARNING]
> **`openssl ca` discards CSR extensions unless `copy_extensions = copy` is set.** This is the most common failure in a hand-built CA, and it fails quietly: signing succeeds, the certificate looks fine, and only the SANs are missing. Browsers then reject it with a name mismatch, because they match on SAN and ignore the Common Name entirely.
>
> The check above is how you catch it. If the output is `No extensions in certificate` or omits the SAN, add `copy_extensions = copy` to the `[ CA_default ]` section and re-issue.
>
> The setting carries a real trade-off: it lets a CSR request *any* extension, including `basicConstraints = CA:true`. Naming `-extensions server_cert` on the command line, as above, overrides the dangerous ones — the profile always wins over the CSR. Never enable `copy_extensions` without also pinning an extension profile, and review CSRs you did not generate yourself.

### Step 6: Distribute the Chain

Two different files come out of a two-tier CA, and they are not interchangeable:

```bash
# Trust bundle — install on clients that must trust your CA. No leaf.
cat issuing/certs/issuingca.crt root/certs/rootca.crt > ca-chain.crt

# Server chain — what a web server presents. Leaf first, no root.
cat certificate.crt issuing/certs/issuingca.crt > fullchain.pem
```

Verify the leaf against the chain before deploying:

```bash
openssl verify -CAfile root/certs/rootca.crt -untrusted issuing/certs/issuingca.crt certificate.crt
```

```text
certificate.crt: OK
```

If you omit the issuing CA from what the server sends, clients report this:

```text
C = US, ST = State, O = Example Corp, CN = Example Corp Issuing CA
error 2 at 1 depth lookup: unable to get issuer certificate
error certificate.crt: verification failed
```

See [Certificate Chain Verification](certificate-operations.md#certificate-chain-verification) for how to read these errors in general.

### Certificate Validity Periods

| Certificate Type | Recommended Validity | Notes |
| ---------------- | -------------------- | ----- |
| Root CA | 10-20 years | Keep offline; used only to sign issuing CAs and its own CRL |
| Issuing CA | 5-10 years | Online; performs routine signing |
| Server/Client | 1 year or less | Public CAs are limited to 398 days |
| Code Signing | 1-3 years | Often requires hardware-backed keys |
| Email (S/MIME) | 1-3 years | Tied to individual identity |

> [!NOTE]
> An issuing CA must expire well before the root that signed it, and every certificate it issues must expire before the issuing CA does. OpenSSL will happily issue a certificate that outlives its CA; clients will reject it once the CA expires.

### Managing Certificate Revocation Lists (CRLs)

Revocation is handled by whichever CA issued the certificate — for server certificates, that is the issuing CA. The root maintains its own separate CRL, used only to revoke issuing CAs.

```bash
# 1. Revoke a certificate, recording a reason
openssl ca -config issuing-ca.conf -revoke certificate.crt -crl_reason keyCompromise

# 2. Regenerate the CRL so the revocation takes effect
openssl ca -config issuing-ca.conf -gencrl -out issuing/crl/issuingca.crl
```

```text
Revoking Certificate 1001.
Database updated
```

Valid reasons are `unspecified`, `keyCompromise`, `CACompromise`, `affiliationChanged`, `superseded`, `cessationOfOperation`, `certificateHold`, and `removeFromCRL`.

Inspect the result:

```bash
openssl crl -in issuing/crl/issuingca.crl -noout -text
```

```text
Certificate Revocation List (CRL):
        Version 2 (0x1)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = State, O = Example Corp, CN = Example Corp Issuing CA
        Last Update: Aug 18 15:40:08 2026 GMT
        Next Update: Aug 25 15:40:08 2026 GMT
        CRL extensions:
            X509v3 CRL Number:
                4096
Revoked Certificates:
    Serial Number: 1001
        Revocation Date: Aug 18 15:40:08 2026 GMT
```

Confirm that verification now rejects the certificate:

```bash
openssl verify -crl_check -CAfile ca-chain.crt -CRLfile issuing/crl/issuingca.crl certificate.crt
```

```text
C = US, ST = State, O = Example Corp, CN = example.com
error 23 at 0 depth lookup: certificate revoked
error certificate.crt: verification failed
```

> [!IMPORTANT]
> **A CRL expires.** `Next Update` above is seven days out, set by `default_crl_days`. Once that passes, clients performing revocation checks treat the CRL as invalid — and many then fail the connection outright, taking down services whose certificates are perfectly valid. Regenerate and publish the CRL on a schedule comfortably shorter than its lifetime, whether or not anything has been revoked.

To let clients find the CRL, publish it over HTTP and point certificates at it by adding this to the `[ server_cert ]` section before issuing:

```ini
crlDistributionPoints = URI:http://pki.example.com/crl/issuingca.crl
```

Certificates already issued cannot be updated — the URL is baked in at signing time, so set this up before you issue anything you intend to keep.

#### CRL vs. OCSP

| Method | Advantages | Disadvantages |
| ------ | ---------- | ------------- |
| CRL | Simple to implement | Grows as revocations accumulate |
| | Works offline once downloaded | Data is stale between updates |
| | One file covers every certificate | Whole list must be downloaded |
| OCSP | Real-time status | Requires the responder to be reachable |
| | Small responses | Leaks which sites a client visits |
| | Only queries the certificate in hand | More infrastructure to operate |

OCSP stapling gets most of OCSP's benefit without the privacy cost or the availability risk: the server fetches its own status and delivers it during the handshake. See [Working with OCSP](advanced.md#working-with-ocsp-online-certificate-status-protocol).

### Operating the CA

> [!IMPORTANT]
> Practices worth adopting from the start, because retrofitting them is painful:
>
> 1. Keep the root key offline and passphrase-protected; bring it out only to sign an issuing CA or refresh the root CRL
> 2. Back up `index.txt`, `serial`, and `crlnumber` with the keys — without the database you cannot produce an accurate CRL
> 3. Restrict key file permissions (`chmod 400`) and the directories holding them (`chmod 700`)
> 4. Publish CRLs on a schedule shorter than `default_crl_days`, regardless of activity
> 5. Record who requested each certificate and why; `index.txt` records what was issued, not the authorization behind it
> 6. Rehearse issuing-CA compromise before it happens — revoke, rebuild from the root, re-issue, and confirm how long redistribution takes

## Navigation

[◄ Certificate Operations](certificate-operations.md) · [OpenSSL Guide](index.md) · [Private Key Management ►](private-keys.md)
