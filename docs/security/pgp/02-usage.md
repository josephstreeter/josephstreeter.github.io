---
title: "PGP/GPG Usage Guide"
description: "Complete guide to using PGP/GPG for encryption, decryption, signing, and key management"
tags: ["pgp", "gpg", "encryption", "kleopatra", "gpa", "usage"]
category: "security"
difficulty: "intermediate"
last_updated: "2025-01-20"
---

## PGP/GPG Usage Guide

This comprehensive guide covers practical usage of PGP/GPG across different platforms and applications, including key creation, encryption, decryption, and key management.

## Prerequisites

Before following this guide, ensure you have:

- PGP/GPG software installed ([Installation Guide](03-install-clients.md))
- Basic understanding of PGP concepts ([PGP Overview](index.md))
- Administrative access (for some operations)

---

## Create PGP Key Pair

Creating a secure key pair is the foundation of PGP usage. We recommend using 4096-bit RSA keys for maximum security.

### [Kleopatra (Windows)](#tab/createkeypairkleopatra)

Kleopatra is the recommended tool for Windows as it supports 4096-bit RSA keys.

1. **Launch Kleopatra**
   - Open Kleopatra from Start Menu or desktop shortcut

2. **Start Certificate Creation**
   - Click **File** → **New Certificate...**
   - Select **Create a personal OpenPGP key pair**
   - Click **Next**

3. **Enter Personal Information**

   ```text
   Name: Your Name (or pseudonym for anonymity)
   Email: your.email@example.com (or anonymous email)
   Comment: Optional description
   ```

4. **Configure Advanced Settings**
   - Click **Advanced Settings...**
   - In **Key Material** section:
     - Select **RSA** radio button
     - Choose **4,096 bits** from dropdown
     - Set expiration date (recommended: 2-4 years)
   - Click **OK**

5. **Create the Key**
   - Verify your information is correct
   - Click **Create Key**

6. **Set Passphrase**
   - Enter a strong passphrase (minimum 12 characters)
   - Include uppercase, lowercase, numbers, and symbols
   - Re-enter to confirm
   - Click **OK**

7. **Generate Entropy**
   - Move mouse randomly and type random text
   - This creates randomness for key generation
   - Process completes automatically

8. **Finish Creation**
   - Click **Finish** when generation is complete
   - Your key pair is now ready for use

### [GPA (Windows/Linux)](#tab/createkeygpa)

GNU Privacy Assistant provides an alternative interface for key creation.

1. **Launch GPA**
   - Open GPA application

2. **Create New Key**
   - Click **Keys** → **New Key** (or Ctrl+N)

3. **Enter Key Information**

   ```text
   Name: Your chosen identity
   Email: your.email@example.com
   Comment: Optional description
   ```

   > [!NOTE]
   > For anonymity, use pseudonyms and non-traceable email addresses

4. **Set Key Parameters**
   - Key type: RSA (default)
   - Key size: 2048 bits (GPA limitation)
   - Expiration: Set appropriate date

5. **Create Backup**
   - Choose location for key backup
   - This creates your public key file (.asc)
   - **Important**: Store backup securely

6. **Complete Creation**
   - Follow remaining prompts
   - Enter strong passphrase when requested

### [Command Line](#tab/createkeycli)

Command line interface provides maximum control over key generation.

```bash
# Generate new key pair interactively
gpg --full-generate-key

# Choose options when prompted:
# (1) RSA and RSA (default)
# 4096 (key size)
# 2y (expiration - 2 years recommended)
# y (confirm expiration)
# Enter name, email, comment
# Enter secure passphrase
```

**Advanced Key Generation with Batch Mode:**

```bash
# Create batch file for automated generation
cat > keygen.batch << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Your Name
Name-Email: your.email@example.com
Expire-Date: 2y
Passphrase: YourSecurePassphrase123!
%commit
EOF

# Generate key using batch file
gpg --batch --generate-key keygen.batch

# Clean up batch file (contains passphrase)
shred -vfz -n 3 keygen.batch
```

---

## Export Public Key

Your public key needs to be shared with others for them to send you encrypted messages.

### [Kleopatra](#tab/exportpubkleopatra)

1. **Select Your Key**
   - Open Kleopatra
   - Right-click your key in **My Certificates** tab

2. **Export Certificate**
   - Click **Export Certificates...**
   - Choose save location
   - Filename: `yourname-public.asc`
   - Click **Save**

3. **Verify Export**
   - Open the .asc file in text editor
   - Should start with `-----BEGIN PGP PUBLIC KEY BLOCK-----`
   - Should end with `-----END PGP PUBLIC KEY BLOCK-----`

### [GPA](#tab/exportpubgpa)

1. **Access Keys Tab**
   - Open GPA application
   - Navigate to **My Certificates** tab

2. **Export Public Key**
   - Right-click your key
   - Select **Export Certificates...**
   - Choose save location and filename
   - Click **Save**

3. **Share Your Public Key**
   - Open saved file in text editor (Notepad)
   - Copy entire contents including header/footer lines
   - Share this text with others who need to send you encrypted messages

### [Command Line](#tab/exportpubcli)

```bash
# List your keys to find the key ID
gpg --list-keys

# Export public key to file
gpg --armor --export your.email@example.com > public-key.asc

# Or export to stdout for copying
gpg --armor --export your.email@example.com

# Export specific key by ID
gpg --armor --export A1B2C3D4 > public-key.asc
```

---

## Export Private Key

**⚠️ SECURITY WARNING**: Private keys should be exported only for backup purposes and stored securely.

### [Kleopatra](#tab/exportprivkleopatra)

1. **Select Your Key**
   - Right-click your key in **My Certificates** tab

2. **Export Secret Key**
   - Select **Export Secret Keys...**
   - Choose secure location (encrypted drive recommended)
   - Check **ASCII armor** option
   - Enter filename: `yourname-private.asc`
   - Click **OK**

3. **Security Confirmation**
   - Confirm export in dialog box
   - Enter your passphrase when prompted

### [GPA](#tab/exportprivgpa)

1. **Access Key Management**
   - Open GPA application
   - Go to **Keys** menu

2. **Export Private Key**
   - Select **Export Keys...**
   - Choose your private key
   - Select secure save location
   - Ensure **Include secret keys** is checked

### [Command Line](#tab/exportprivcli)

```bash
# Export private key (requires passphrase)
gpg --armor --export-secret-keys your.email@example.com > private-key.asc

# Export with specific output file
gpg --armor --export-secret-keys --output private-backup.asc your.email@example.com

# Export specific subkeys only
gpg --armor --export-secret-subkeys your.email@example.com > subkeys.asc
```

---

## Publish Key to Key Server

Publishing your public key to key servers makes it discoverable by others.

### [Kleopatra](#tab/publishkleopatra)

1. **Select Your Key**
   - Right-click your key in Kleopatra

2. **Publish to Server**
   - Select **Publish on Server...**
   - Choose key server (default is usually fine)
   - Click **OK**

3. **Verify Publication**
   - Search for your key on key server to confirm

### [GPA](#tab/publishgpa)

1. **Access Server Menu**
   - Click **Server** → **Send Keys**

2. **Select Key Server**
   - Choose from available servers
   - Click **Send**

### [Command Line](#tab/publishcli)

```bash
# Send key to default key server
gpg --send-keys your.email@example.com

# Send to specific key server
gpg --keyserver hkps://keys.openpgp.org --send-keys your.email@example.com

# Send to multiple servers
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys your.email@example.com
```

---

## Import Public Keys

Before encrypting messages for others, you need their public keys.

### [Kleopatra](#tab/importpubkleopatra)

1. **Import from File**
   - Click **File** → **Import Certificates...**
   - Browse to .asc file containing public key
   - Click **Open**

2. **Import from Clipboard**
   - Copy public key text to clipboard
   - Click **File** → **Import Certificates from Clipboard**

3. **Verify Import**
   - Check **Other Certificates** tab
   - Imported key should be listed

### [GPA](#tab/importpubgpa)

1. **Prepare Key File**
   - Save public key text to .asc file
   - Or copy key text to clipboard

2. **Import Key**
   - Click **Keys** → **Import Keys**
   - Select the .asc file
   - Click **Open**

3. **Verify Import**
   - Key appears in key list
   - Check key details for accuracy

### [Command Line](#tab/importpubcli)

```bash
# Import from file
gpg --import public-key.asc

# Import from key server by email
gpg --keyserver hkps://keys.openpgp.org --search-keys friend@example.com

# Import specific key by ID
gpg --keyserver hkps://keys.openpgp.org --recv-keys A1B2C3D4

# List imported keys
gpg --list-keys
```

---

## Encrypt Messages

Encryption ensures only the intended recipient can read your message.

### [Kleopatra](#tab/encryptkleopatra)

1. **Prepare Your Message**
   - Open Notepad or text editor
   - Type your message
   - Select all text and copy (Ctrl+C)

2. **Encrypt via System Tray**
   - Right-click Kleopatra icon in system tray
   - Navigate to **Clipboard** → **Encrypt...**

3. **Select Recipients**
   - Click **Add Recipient...**
   - Switch to **Other Certificates** tab
   - Select recipient's public key
   - Click **OK**

4. **Complete Encryption**
   - Verify recipient is listed
   - Click **Next**
   - Encryption completes automatically

5. **Send Encrypted Message**
   - Encrypted text is now in clipboard
   - Paste (Ctrl+V) into email, chat, or any application
   - Send to recipient

### [GPA](#tab/encryptgpa)

1. **Open Clipboard Manager**
   - Click **Windows** → **Clipboard**

2. **Enter Message**
   - Type or paste your message in the text area

3. **Encrypt Message**
   - Click **Encrypt** button
   - Select recipient's public key from list
   - Click **OK**

4. **Copy Encrypted Text**
   - Encrypted message appears in clipboard window
   - Copy all text including PGP headers
   - Paste into your communication method

### [Command Line](#tab/encryptcli)

```bash
# Encrypt file for specific recipient
gpg --encrypt --recipient friend@example.com message.txt

# Encrypt with ASCII armor (for email/text)
gpg --armor --encrypt --recipient friend@example.com message.txt

# Encrypt for multiple recipients
gpg --armor --encrypt --recipient alice@example.com --recipient bob@example.com message.txt

# Encrypt from stdin to stdout
echo "Secret message" | gpg --armor --encrypt --recipient friend@example.com
```

---

## Decrypt Messages

Decryption requires your private key and passphrase.

### [Kleopatra](#tab/decryptkleopatra)

1. **Copy Encrypted Message**
   - Select entire encrypted message block
   - Include `-----BEGIN PGP MESSAGE-----` and `-----END PGP MESSAGE-----`
   - Copy to clipboard (Ctrl+C)

2. **Decrypt via System Tray**
   - Right-click Kleopatra icon in system tray
   - Navigate to **Clipboard** → **Decrypt/Verify...**

3. **Enter Passphrase**
   - Enter your private key passphrase
   - Click **OK**

4. **View Decrypted Message**
   - Decrypted text is copied to clipboard
   - Paste into text editor to read
   - Message is also displayed in verification window

### [GPA](#tab/decryptgpa)

1. **Open Clipboard Manager**
   - Access **Windows** → **Clipboard**

2. **Paste Encrypted Message**
   - Copy encrypted message to clipboard first
   - Paste into GPA clipboard window

3. **Decrypt**
   - Click **Decrypt** button
   - Enter your passphrase when prompted
   - Click **OK**

4. **Read Message**
   - Decrypted message appears in window
   - Copy to save or forward as needed

### [Command Line](#tab/decryptcli)

```bash
# Decrypt file (creates .txt file from .txt.gpg)
gpg --decrypt message.txt.gpg > decrypted-message.txt

# Decrypt and display on screen
gpg --decrypt message.txt.gpg

# Decrypt from stdin
cat encrypted-message.asc | gpg --decrypt
```

---

## Sign Messages

Digital signatures provide authentication and integrity verification.

### [Kleopatra](#tab/signkleopatra)

1. **Prepare Message**
   - Create message in text editor
   - Copy message to clipboard

2. **Sign Message**
   - Right-click Kleopatra system tray icon
   - Select **Clipboard** → **Sign...**
   - Choose your signing key
   - Enter passphrase
   - Click **OK**

3. **Send Signed Message**
   - Signed message is in clipboard
   - Paste into email or communication method

### [GPA](#tab/signgpa)

1. **Open Clipboard**
   - Access **Windows** → **Clipboard**
   - Enter your message

2. **Create Signature**
   - Click **Sign** button
   - Select your private key
   - Enter passphrase
   - Click **OK**

3. **Share Signed Message**
   - Copy complete signed message
   - Include all PGP signature blocks

### [Command Line](#tab/signcli)

```bash
# Create detached signature
gpg --armor --detach-sign message.txt

# Create inline signature
gpg --armor --sign message.txt

# Clear-sign (readable text with signature)
gpg --armor --clearsign message.txt
```

---

## Verify Signatures

Signature verification confirms message authenticity and integrity.

### [Kleopatra](#tab/verifykleopatra)

1. **Copy Signed Message**
   - Include entire message with signature blocks
   - Copy to clipboard

2. **Verify Signature**
   - Right-click Kleopatra system tray icon
   - Select **Clipboard** → **Decrypt/Verify...**

3. **Review Results**
   - Verification window shows signature status
   - Green checkmark indicates valid signature
   - Red X indicates invalid or missing signature

### [GPA](#tab/verifygpa)

1. **Import Message**
   - Paste signed message into GPA clipboard

2. **Verify**
   - Click **Verify** button
   - Results show signature validity

### [Command Line](#tab/verifycli)

```bash
# Verify detached signature
gpg --verify message.txt.asc message.txt

# Verify inline signed message
gpg --verify signed-message.asc

# Verify and extract clear-signed message
gpg --verify clear-signed-message.asc
```

---

## Key Management

### Trust Levels

Understanding and setting appropriate trust levels is crucial for PGP security.

**Trust Levels Explained:**

- **Unknown**: No trust information
- **None**: Explicitly marked as not trusted
- **Marginal**: Some confidence in key ownership
- **Full**: High confidence in key ownership
- **Ultimate**: Your own keys

### [Set Key Trust - Kleopatra](#tab/trustkleopatra)

1. **Access Key Properties**
   - Right-click on key
   - Select **Details...**

2. **Change Trust Level**
   - Click **Change Owner Trust...**
   - Select appropriate trust level
   - Click **OK**

### [Set Key Trust - Command Line](#tab/trustcli)

```bash
# Edit key trust
gpg --edit-key friend@example.com

# In GPG prompt:
gpg> trust
# Select trust level (1-5)
# 5 = Ultimate trust
# 4 = Full trust
# 3 = Marginal trust

gpg> save
```

### Key Maintenance

```bash
# Refresh keys from keyserver
gpg --refresh-keys

# Check key expiration
gpg --list-keys

# Extend key expiration
gpg --edit-key your.email@example.com
gpg> expire
# Set new expiration
gpg> save

# Generate revocation certificate
gpg --output revoke.asc --gen-revoke your.email@example.com
```

---

## Best Practices

### Security Recommendations

1. **Strong Passphrases**
   - Minimum 12 characters
   - Include uppercase, lowercase, numbers, symbols
   - Consider using passphrases instead of passwords

2. **Key Size**
   - Use 4096-bit RSA keys minimum
   - Consider Ed25519 for new keys (newer algorithm)

3. **Key Expiration**
   - Set expiration dates (2-4 years recommended)
   - Regularly extend or replace keys

4. **Backup Strategy**
   - Create secure backups of private keys
   - Store revocation certificates safely
   - Test backup restoration periodically

### Operational Security

1. **Key Verification**
   - Always verify key fingerprints through secure channels
   - Use multiple verification methods when possible

2. **Software Updates**
   - Keep PGP software updated
   - Monitor security advisories

3. **Environment Security**
   - Use secure, updated operating systems
   - Avoid public/shared computers for key operations
   - Consider using dedicated hardware for key generation

### Common Mistakes to Avoid

1. **Weak Passphrases**: Using dictionary words or personal information
2. **Unverified Keys**: Trusting keys without proper verification
3. **Insecure Backups**: Storing private keys without encryption
4. **Key Reuse**: Using same keys across multiple identities
5. **Outdated Software**: Using vulnerable PGP implementations

## Troubleshooting

### Common Issues

#### Error: "No public key"

```bash
# Solution: Import recipient's public key
gpg --keyserver hkps://keys.openpgp.org --search-keys recipient@example.com
```

#### Error: "Bad passphrase"

- Verify caps lock status
- Try typing passphrase in text editor first
- Check for special character issues

#### Error: "Key expired"

```bash
# Check key expiration
gpg --list-keys

# Extend expiration if it's your key
gpg --edit-key your.email@example.com
```

#### GPG Agent Issues

```bash
# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

This comprehensive usage guide should cover all essential PGP/GPG operations across different platforms and interfaces.
