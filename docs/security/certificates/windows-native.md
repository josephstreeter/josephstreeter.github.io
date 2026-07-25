---
title: Managing Certificates in Windows with Native Tools
description: Guide to managing X.509 certificates on Windows using built-in tools — Certificate Manager (MMC), certutil, certreq, PowerShell, and netsh
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-25
ms.topic: how-to
ms.service: security
---

## Managing Certificates in Windows with Native Tools

Windows ships with a complete set of built-in tools for managing X.509 certificates without installing OpenSSL or third-party utilities. This guide covers the Windows certificate store model and the native tools used to view, request, import, export, and bind certificates: the **Certificate Manager** MMC snap-ins, **certutil**, **certreq**, the **PowerShell PKI** cmdlets, and **netsh** for service bindings.

> [!NOTE]
> These tools operate on the Windows certificate stores rather than on loose `.crt`/`.key` files. For file-based cross-platform work (PEM manipulation, format conversion, CSR inspection on non-Windows systems), see the [OpenSSL Guide](openssl/index.md). The two approaches interoperate — you can import OpenSSL-generated `.pfx` files into Windows and export from Windows for use elsewhere.

### Table of Contents

- [The Windows Certificate Store Model](#the-windows-certificate-store-model)
- [Certificate Manager (MMC)](#certificate-manager-mmc)
- [certutil](#certutil)
- [certreq — Requesting Certificates](#certreq--requesting-certificates)
- [PowerShell PKI Cmdlets](#powershell-pki-cmdlets)
- [Binding Certificates to Services](#binding-certificates-to-services)
- [Trusting Certificates](#trusting-certificates)
- [Common Tasks Quick Reference](#common-tasks-quick-reference)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## The Windows Certificate Store Model

Windows organizes certificates into **stores**, each scoped to a **location**. Understanding this hierarchy is essential before using any of the tools.

### Store Locations

- **Current User** (`Cert:\CurrentUser` / `certmgr.msc`): Certificates available only to the logged-on user. Ideal for personal S/MIME, client authentication, and per-user code signing.
- **Local Machine** (`Cert:\LocalMachine` / `certlm.msc`): Certificates available to all users and services on the computer. Used for web server (IIS), RDP, and service certificates. Requires administrative privileges to modify.

### Common Store Names

| Store name | `Cert:` path | Purpose |
|------------|--------------|---------|
| Personal | `My` | End-entity certificates you own (usually with private keys) |
| Trusted Root Certification Authorities | `Root` | Self-signed root CA certificates that anchor trust |
| Intermediate Certification Authorities | `CA` | Intermediate/issuing CA certificates that complete chains |
| Trusted Publishers | `TrustedPublisher` | Publishers trusted for code signing |
| Trusted People | `TrustedPeople` | Explicitly trusted end-entity certificates |
| Third-Party Root CAs | `AuthRoot` | Publicly trusted roots distributed by Microsoft |

> [!IMPORTANT]
> Placing a certificate in **Trusted Root Certification Authorities** tells Windows to trust everything that certificate signs. Only add roots you genuinely control or trust, and prefer the **Local Machine** location so the trust decision is deliberate and auditable.

## Certificate Manager (MMC)

The graphical Certificate Manager is the quickest way to inspect and manually manage certificates.

### Opening the Certificate Manager

```text
certmgr.msc     # Current User store
certlm.msc      # Local Machine store (requires elevation)
```

To manage both locations (and remote computers) from a single console, launch a custom MMC:

1. Run `mmc.exe`.
2. **File → Add/Remove Snap-in → Certificates → Add**.
3. Choose **My user account**, **Service account**, or **Computer account** as needed.
4. For **Computer account**, select **Local computer** or a remote machine.

### Common GUI Tasks

- **Import**: Right-click a store → **All Tasks → Import** to launch the Certificate Import Wizard (`.cer`, `.crt`, `.pfx`, `.p7b`).
- **Export**: Right-click a certificate → **All Tasks → Export**. Choose whether to include the private key (produces a password-protected `.pfx`) or export the public certificate only (`.cer`).
- **View details**: Double-click a certificate to inspect its subject, SANs, validity, thumbprint, key usage, and certification path.
- **Request** (domain-joined machines): Right-click **Personal → All Tasks → Request New Certificate** to enroll against an Active Directory Certificate Services (AD CS) CA.

## certutil

`certutil.exe` is the primary command-line certificate utility on Windows. It works against both the certificate stores and certificate files.

### Inspecting Certificates

```cmd
:: Dump a certificate file (equivalent to openssl x509 -text)
certutil -dump certificate.cer

:: Display the hash/thumbprint of a certificate
certutil -hashfile certificate.cer SHA256

:: Verify a certificate chain and revocation status
certutil -verify -urlfetch certificate.cer

:: List certificates in the Local Machine Personal store
certutil -store My

:: List certificates in the Current User Personal store
certutil -user -store My
```

### Importing and Exporting

```cmd
:: Import a PFX (with private key) into the Local Machine Personal store
certutil -f -p "PfxPassword" -importpfx My certificate.pfx

:: Import a public certificate into the Trusted Root store
certutil -addstore -f Root rootca.cer

:: Export a certificate from a store to a file (by thumbprint or serial)
certutil -store My "<thumbprint>" exported.cer

:: Delete a certificate from a store by thumbprint
certutil -delstore My "<thumbprint>"
```

### Format Conversion

```cmd
:: Convert DER (binary) to Base64 (PEM-style)
certutil -encode input.der output.pem

:: Convert Base64 back to DER (binary)
certutil -decode input.pem output.der
```

### CA and Template Operations

```cmd
:: List available certificate templates (domain-joined)
certutil -template

:: Display the CA configuration and issued-certificate details
certutil -config "CAServer\CAName" -ping

:: Retrieve a certificate revocation list
certutil -getreg CA\CRLPublicationURLs
```

## certreq — Requesting Certificates

`certreq.exe` generates certificate signing requests (CSRs) and submits them to a CA. It is the native equivalent of `openssl req` and is driven by an INF policy file.

### 1. Create a Request Policy (INF) File

```ini
[Version]
Signature = "$Windows NT$"

[NewRequest]
Subject = "CN=www.example.com, O=Example Org, L=City, S=State, C=US"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
HashAlgorithm = SHA256

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=www.example.com&"
_continue_ = "dns=example.com&"

[EnhancedKeyUsageExtension]
OID = 1.3.6.1.5.5.7.3.1  ; Server Authentication
```

### 2. Generate the CSR

```cmd
:: Create the CSR and store the private key in the machine key store
certreq -new request.inf request.csr
```

### 3. Submit and Retrieve

```cmd
:: Submit to an enterprise CA and retrieve the issued certificate
certreq -submit -config "CAServer\CAName" request.csr certificate.cer

:: Accept (install) the issued certificate, binding it to the stored key
certreq -accept certificate.cer
```

> [!TIP]
> For public CAs that do not accept `certreq -submit`, use `certreq -new` to produce the CSR, submit that CSR through the CA's web portal or ACME client, then run `certreq -accept` on the returned certificate to reunite it with its private key. For fully automated public issuance on IIS, see [win-acme](acme/win-acme.md).

## PowerShell PKI Cmdlets

PowerShell exposes certificate stores as the `Cert:` PSDrive and provides purpose-built cmdlets. This is the most script-friendly native option.

### Browsing the Certificate Store

```powershell
# List certificates in the Local Machine Personal store
Get-ChildItem -Path Cert:\LocalMachine\My

# List Current User personal certificates
Get-ChildItem -Path Cert:\CurrentUser\My

# Find certificates expiring within 30 days
Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object { $_.NotAfter -lt (Get-Date).AddDays(30) } |
    Select-Object Subject, Thumbprint, NotAfter

# Retrieve a specific certificate by thumbprint
Get-Item -Path Cert:\LocalMachine\My\<thumbprint>
```

### Creating a Self-Signed Certificate

```powershell
# Create a SAN certificate in the Local Machine Personal store
$Certificate = New-SelfSignedCertificate `
    -Subject "CN=www.example.com" `
    -DnsName "www.example.com", "example.com" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -Type SSLServerAuthentication `
    -NotAfter (Get-Date).AddYears(1)

Write-Output "Created certificate with thumbprint: $($Certificate.Thumbprint)"
```

> [!NOTE]
> `New-SelfSignedCertificate` is convenient for development and internal testing. For public-facing services, obtain a certificate from a trusted CA — see [Self-Signed Certificates](self-signed.md) for the trade-offs and the [ACME section](acme/index.md) for automated public issuance.

### Importing and Exporting

```powershell
# Export the public certificate only (.cer)
Export-Certificate -Cert $Certificate -FilePath "C:\certs\www.cer"

# Export with the private key to a password-protected PFX
$Password = ConvertTo-SecureString -String "P@ssw0rd!" -AsPlainText -Force
Export-PfxCertificate -Cert $Certificate -FilePath "C:\certs\www.pfx" -Password $Password

# Import a public certificate into the Trusted Root store
Import-Certificate -FilePath "C:\certs\rootca.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

# Import a PFX (with private key) into the Personal store
Import-PfxCertificate -FilePath "C:\certs\www.pfx" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -Password $Password
```

### Inspecting and Validating

```powershell
# View full certificate details
Get-Item -Path Cert:\LocalMachine\My\<thumbprint> | Format-List *

# Read a PFX/certificate file without importing it
Get-PfxCertificate -FilePath "C:\certs\www.pfx"

# Build and validate the certificate chain
$Cert = Get-Item -Path Cert:\LocalMachine\My\<thumbprint>
$Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$Chain.ChainPolicy.RevocationMode = "Online"
if (-not $Chain.Build($Cert))
{
    $Chain.ChainStatus | Format-Table Status, StatusInformation
}
```

### Removing a Certificate

```powershell
# Remove a certificate from a store by thumbprint
Remove-Item -Path Cert:\LocalMachine\My\<thumbprint> -DeleteKey
```

> [!WARNING]
> `-DeleteKey` also removes the associated private key material. Ensure you have a secure backup (an exported PFX) before deleting any certificate whose key you may need again.

## Binding Certificates to Services

Installing a certificate into a store does not make a service use it — you must bind it.

### IIS

```powershell
# Bind an existing certificate to an HTTPS site binding (IIS)
Import-Module WebAdministration
$Thumbprint = "<thumbprint>"
New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "www.example.com" -SslFlags 1
$Binding = Get-WebBinding -Name "Default Web Site" -Protocol https
$Binding.AddSslCertificate($Thumbprint, "My")
```

### netsh (non-IIS HTTPS services)

Services built on `http.sys` (e.g. custom Kestrel/HttpListener apps, WinRM) are bound with `netsh`:

```cmd
:: Bind a certificate to a port for all IP addresses
netsh http add sslcert ipport=0.0.0.0:443 certhash=<thumbprint> appid={<guid>}

:: List existing SSL bindings
netsh http show sslcert

:: Remove a binding
netsh http delete sslcert ipport=0.0.0.0:443
```

> [!NOTE]
> The `appid` is any GUID that identifies the owning application; generate one with `[guid]::NewGuid()` in PowerShell. The certificate must already exist in the **Local Machine** Personal store.

## Trusting Certificates

To trust a self-signed or private-CA certificate machine-wide, import the CA (or the self-signed certificate itself) into the appropriate trust store:

```powershell
# Trust a root CA for the whole machine
Import-Certificate -FilePath "C:\certs\rootca.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

# Trust an intermediate CA so chains resolve
Import-Certificate -FilePath "C:\certs\intermediate.cer" -CertStoreLocation "Cert:\LocalMachine\CA"
```

In an Active Directory environment, distribute trusted roots to all domain members via **Group Policy**: *Computer Configuration → Policies → Windows Settings → Security Settings → Public Key Policies → Trusted Root Certification Authorities*.

## Common Tasks Quick Reference

| Task | PowerShell | certutil |
|------|-----------|----------|
| List store contents | `Get-ChildItem Cert:\LocalMachine\My` | `certutil -store My` |
| Import PFX | `Import-PfxCertificate` | `certutil -importpfx My cert.pfx` |
| Import public cert to Root | `Import-Certificate ... -CertStoreLocation Cert:\LocalMachine\Root` | `certutil -addstore Root ca.cer` |
| Export PFX | `Export-PfxCertificate` | (use MMC or PowerShell) |
| Export public cert | `Export-Certificate` | `certutil -store My "<thumb>" out.cer` |
| Inspect a file | `Get-PfxCertificate` | `certutil -dump cert.cer` |
| Verify chain | `X509Chain.Build()` | `certutil -verify -urlfetch cert.cer` |
| Delete from store | `Remove-Item Cert:\... -DeleteKey` | `certutil -delstore My "<thumb>"` |
| Create CSR | (see certreq) | `certreq -new request.inf request.csr` |

## Best Practices

- **Prefer Local Machine for services**: Web servers and services run under service accounts and need certificates (and keys) in the Local Machine store, not per-user stores.
- **Protect exported PFX files**: Always set a strong password on PFX exports and delete the files once imported. The PFX contains the private key.
- **Mark keys non-exportable when appropriate**: For production service certificates that should never leave the host, import without the exportable flag (omit `-Exportable` / use the wizard's "do not mark as exportable" option) to reduce key-theft risk.
- **Use thumbprints as identifiers**: Thumbprints uniquely identify certificates across every native tool — prefer them over subject names in scripts and bindings.
- **Automate renewal**: Manual store management does not scale. For public certificates on IIS, use [win-acme](acme/win-acme.md); for AD CS, enable certificate autoenrollment via Group Policy.
- **Audit trust stores**: Periodically review the Trusted Root and Trusted Publishers stores for unexpected entries — an unauthorized root is a serious compromise.

## Troubleshooting

- **"A certificate chain could not be built to a trusted root authority"**: The intermediate or root CA is missing. Import the intermediate into `Cert:\LocalMachine\CA` and the root into `Cert:\LocalMachine\Root`, then re-run `certutil -verify -urlfetch`.
- **Service ignores the new certificate**: Installing to a store is not enough — rebind the service (IIS binding, `netsh http add sslcert`) and restart it. Confirm with `netsh http show sslcert`.
- **"Cannot find the certificate and private key for decryption"**: The private key is missing or you imported a public-only `.cer` where a `.pfx` was needed. Re-import from the PFX, or repair the key association with `certutil -repairstore My "<thumbprint>"`.
- **Access denied modifying the Local Machine store**: Run the console or shell **as Administrator**. `certlm.msc` and Local Machine operations require elevation.
- **Wrong store or location**: Remember Current User (`certmgr.msc` / `Cert:\CurrentUser`) and Local Machine (`certlm.msc` / `Cert:\LocalMachine`) are separate. A certificate imported for your user is invisible to services running as other accounts.

## Related Topics

- [Certificate Management and PKI](index.md)
- [Self-Signed Certificates](self-signed.md)
- [OpenSSL Guide](openssl/index.md) — the cross-platform, file-based alternative
- [ACME (Automated Certificates)](acme/index.md) — automated public issuance and renewal
- [win-acme Guide](acme/win-acme.md) — ACME client for Windows/IIS

## Additional Resources

- [certutil reference (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil)
- [certreq reference (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1)
- [PKI PowerShell module (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/pki/)
- [Manage certificates (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/manage-certificates)
