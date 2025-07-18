---
title: "PGP/GPG Glossary"
description: "Comprehensive glossary of PGP/GPG terms, concepts, and related cryptographic terminology"
tags: ["pgp", "gpg", "glossary", "terminology", "cryptography"]
category: "security"
difficulty: "reference"
last_updated: "2025-01-20"
---

## PGP/GPG Glossary

This comprehensive glossary defines key terms, concepts, and terminology related to PGP/GPG encryption and cryptography.

## Core PGP/GPG Terms

**Algorithm**
: A mathematical procedure used for encryption, decryption, digital signing, or key generation. Common PGP algorithms include RSA, DSA, and AES.

**ASCII Armor**
: A method of encoding binary PGP data into printable ASCII text format, making it safe for transmission through email and other text-based systems. Armored data is enclosed in `-----BEGIN PGP MESSAGE-----` and `-----END PGP MESSAGE-----` blocks.

**Asymmetric Cryptography**
: A cryptographic system that uses two mathematically related but different keys (public and private) for encryption and decryption. Also known as public-key cryptography.

**Certificate**
: In PGP context, synonymous with a public key. Contains the public key, user identification information, and digital signatures that validate the key's authenticity.

**Cipher**
: An algorithm for performing encryption and decryption. Examples include AES (Advanced Encryption Standard) and 3DES (Triple Data Encryption Standard).

**Ciphertext**
: Data that has been encrypted and is unreadable without the proper decryption key. The output of an encryption operation on plaintext.

**Digital Signature**
: A cryptographic mechanism that provides authentication, integrity, and non-repudiation. Created by encrypting a message hash with the sender's private key.

**Encryption**
: The process of converting plaintext into ciphertext using a cryptographic algorithm and key, making the data unreadable to unauthorized parties.

**Fingerprint**
: A short, unique identifier derived from a public key, typically displayed as a hexadecimal string. Used to verify key authenticity and prevent key substitution attacks.

**GPG (GNU Privacy Guard)**
: A free, open-source implementation of the OpenPGP standard. The most widely used PGP-compatible software, available for multiple operating systems.

**Hash Function**
: A mathematical function that takes input data of any size and produces a fixed-size output (hash). Used in digital signatures and integrity verification. Common hash functions include SHA-256 and SHA-512.

**Key ID**
: A shorter identifier derived from a public key, used to reference specific keys. Can be 8-character (short) or 16-character (long) hexadecimal strings.

**Key Pair**
: A matched set of cryptographic keys consisting of one public key and one private key, mathematically related but computationally distinct.

**Key Server**
: A publicly accessible repository for storing and distributing PGP public keys. Examples include keys.openpgp.org and keyserver.ubuntu.com.

**Keyring**
: A collection of PGP keys stored together, typically referring to either a public keyring (containing public keys) or a secret keyring (containing private keys).

**OpenPGP**
: The open standard for PGP encryption defined in RFC 4880. Ensures interoperability between different PGP implementations.

**Passphrase**
: A secret phrase used to protect a private key. Similar to a password but typically longer and may include spaces and special characters.

**PGP (Pretty Good Privacy)**
: The original encryption software created by Phil Zimmermann in 1991. Now refers to the general family of PGP-compatible encryption software.

**Plaintext**
: Unencrypted, readable data. The input to an encryption operation or the output of a decryption operation.

**Private Key**
: The secret component of a key pair, used for decrypting messages sent to you and for creating digital signatures. Must be kept confidential and protected with a strong passphrase.

**Public Key**
: The non-secret component of a key pair, used for encrypting messages to send to the key owner and for verifying digital signatures. Can be freely distributed.

**Revocation Certificate**
: A special certificate that invalidates a key pair, typically used when a private key is compromised or no longer needed.

**Subkey**
: Additional keys associated with a master key, typically used for specific purposes like encryption or signing while keeping the master key secure.

**Symmetric Cryptography**
: A cryptographic system where the same key is used for both encryption and decryption. Faster than asymmetric cryptography but requires secure key distribution.

**Trust Level**
: A measure of confidence in a key's authenticity, ranging from unknown to ultimate trust. Affects whether you consider signatures from that key to be valid.

**User ID (UID)**
: Information associated with a PGP key that identifies the key owner, typically including name and email address.

**Web of Trust**
: A decentralized trust model where users validate each other's keys through digital signatures, building a network of trust relationships.

## Software and Applications

**Claws Mail**
: A lightweight email client with built-in PGP support for encrypted email communication.

**Enigmail**
: A legacy Thunderbird extension that provided PGP encryption capabilities (now replaced by built-in OpenPGP support).

**GPA (GNU Privacy Assistant)**
: A graphical user interface for GnuPG, providing an alternative to command-line key management and encryption operations.

**GPG4Win**
: A Windows software package that includes GnuPG, Kleopatra, and other tools for PGP encryption on Windows systems.

**GPG4Win Portable**
: A portable version of GPG4Win designed to run from removable media without installation, useful for secure computing on untrusted systems.

**GPG Suite**
: A collection of PGP tools for macOS, including Mail.app integration and key management utilities.

**I2P (Invisible Internet Project)**
: An anonymous network layer that allows for censorship-resistant, peer-to-peer communication, sometimes used with PGP for enhanced privacy.

**iPGMail**
: A PGP-enabled email application for iOS devices, providing mobile PGP encryption capabilities.

**Kleopatra**
: A certificate management application included with GPG4Win, providing a graphical interface for key management, encryption, and signing operations.

**Mailvelope**
: A browser extension that adds PGP encryption capabilities to webmail interfaces like Gmail and Yahoo Mail.

**Mutt**
: A text-based email client with excellent PGP integration, popular among technical users who prefer command-line interfaces.

**OpenKeychain**
: An open-source PGP implementation for Android devices, providing mobile PGP encryption and key management.

**Pidgin OTR (Off The Record)**
: An encryption plugin for the Pidgin instant messaging client that provides encrypted chat with forward secrecy (different from PGP).

**Seahorse**
: The GNOME desktop environment's key management application, providing a graphical interface for GnuPG operations.

**Tails (The Amnesic Incognito Live System)**
: A privacy-focused Linux distribution that includes Tor, PGP, and other privacy tools, designed to leave no traces on the host computer.

**Thunderbird**
: Mozilla's email client with built-in OpenPGP support for encrypted email communication.

**Tor (The Onion Router)**
: An anonymity network that routes internet traffic through multiple servers to protect user privacy, often used with PGP for enhanced security.

## Cryptographic Concepts

**AES (Advanced Encryption Standard)**
: A symmetric encryption algorithm widely used for securing data. Available in 128-bit, 192-bit, and 256-bit key sizes.

**Block Cipher**
: A symmetric encryption algorithm that processes data in fixed-size blocks, typically 128 bits for modern ciphers like AES.

**Compression**
: The process of reducing data size before encryption. PGP typically uses ZIP or ZLIB compression to reduce message size.

**DSA (Digital Signature Algorithm)**
: A public-key algorithm used for creating digital signatures, part of the Digital Signature Standard (DSS).

**ECC (Elliptic Curve Cryptography)**
: A public-key cryptographic approach based on elliptic curves, offering equivalent security to RSA with smaller key sizes.

**Forward Secrecy**
: A security property ensuring that compromise of long-term keys doesn't compromise past session keys. Traditional PGP does not provide forward secrecy.

**ECDH (Elliptic Curve Diffie-Hellman)**
: A key agreement protocol using elliptic curve cryptography, used in modern PGP implementations for key exchange.

**ECDSA (Elliptic Curve Digital Signature Algorithm)**
: A digital signature algorithm using elliptic curve cryptography, offering smaller signatures than traditional DSA.

**ElGamal**
: A public-key cryptographic algorithm used for encryption and digital signatures, commonly used in PGP implementations.

**Entropy**
: A measure of randomness or unpredictability, crucial for generating secure cryptographic keys and random numbers.

**HMAC (Hash-based Message Authentication Code)**
: A type of message authentication code involving a cryptographic hash function and a secret key, used to verify data integrity and authenticity.

**Key Derivation Function (KDF)**
: A function that derives cryptographic keys from a password or other input material, often using algorithms like PBKDF2 or Argon2.

**Key Exchange**
: The process of securely sharing cryptographic keys between parties, often using protocols like Diffie-Hellman.

**Key Length**
: The size of a cryptographic key measured in bits. Longer keys generally provide stronger security but require more computational resources.

**MDC (Modification Detection Code)**
: A cryptographic integrity check used in OpenPGP to detect unauthorized modifications to encrypted data.

**PBKDF2 (Password-Based Key Derivation Function 2)**
: A key derivation function that applies a hash function multiple times to derive keys from passwords, providing resistance to brute-force attacks.

**RSA**
: A widely-used public-key cryptographic algorithm named after Rivest, Shamir, and Adleman. Commonly used in PGP for both encryption and digital signatures.

**Salt**
: Random data added to a password before hashing to prevent rainbow table attacks and ensure unique hashes for identical passwords.

**SHA (Secure Hash Algorithm)**
: A family of cryptographic hash functions including SHA-1, SHA-256, and SHA-512, used for integrity verification and digital signatures.

**Stream Cipher**
: A symmetric encryption algorithm that encrypts data one bit or byte at a time, as opposed to block ciphers that process fixed-size blocks.

## Security and Operational Terms

**Attack Vector**
: A method or pathway used by attackers to gain unauthorized access to a system or to launch an attack.

**Brute Force Attack**
: An attack method that involves systematically trying all possible keys or passwords until the correct one is found.

**Cold Storage**
: Keeping cryptographic keys offline and disconnected from networks to protect them from online attacks.

**Cryptanalysis**
: The study of breaking cryptographic systems and codes, analyzing their security and finding weaknesses.

**Dictionary Attack**
: A type of brute force attack that uses a list of commonly used passwords or passphrases rather than trying all possible combinations.

**Key Compromise**
: A security incident where a private key becomes known to unauthorized parties, requiring key revocation and replacement.

**Key Escrow**
: A system where cryptographic keys are held by a trusted third party, potentially allowing authorized access to encrypted data.

**Key Rotation**
: The practice of regularly replacing cryptographic keys to limit the impact of potential key compromise.

**Man-in-the-Middle Attack**
: An attack where an adversary intercepts and potentially modifies communications between two parties who believe they are communicating directly.

**Metadata**
: Data about data, such as email headers, timestamps, and recipient information, which may reveal sensitive information even when message content is encrypted.

**MITM**
: Abbreviation for Man-in-the-Middle attack.

**OPSEC (Operational Security)**
: Practices and procedures designed to protect sensitive information and operations from adversaries.

**Perfect Forward Secrecy**
: A security property ensuring that compromise of long-term keys doesn't compromise past communications that used ephemeral session keys.

**Quantum Resistance**
: The ability of a cryptographic algorithm to remain secure against attacks by quantum computers.

**Rainbow Table**
: A precomputed table of hash values used to speed up password cracking attacks.

**Replay Attack**
: An attack where valid encrypted data is intercepted and retransmitted to gain unauthorized access.

**Side-Channel Attack**
: An attack that exploits information leaked through the physical implementation of a cryptographic system, such as timing, power consumption, or electromagnetic emissions.

**Social Engineering**
: The use of psychological manipulation to trick people into revealing confidential information or performing actions that compromise security.

**Threat Model**
: An analysis of potential threats, vulnerabilities, and risks to a system or organization, used to guide security decisions.

**Zero-Day**
: A security vulnerability that is unknown to software vendors and for which no patch exists.

## File Formats and Standards

**.asc**
: File extension typically used for ASCII-armored PGP data, making binary PGP data safe for text-based transmission.

**.gpg**
: File extension for binary PGP encrypted or signed files.

**.sig**
: File extension for detached PGP signature files.

**MIME (Multipurpose Internet Mail Extensions)**
: Internet standard for email formatting that includes specifications for PGP-encrypted email (PGP/MIME).

**PGP/MIME**
: A standard for integrating PGP encryption with email MIME formatting, allowing encrypted emails with proper attachment handling.

**RFC 4880**
: The Internet standard document that defines the OpenPGP message format and protocols.

**S/MIME (Secure/Multipurpose Internet Mail Extensions)**
: An alternative email encryption standard that uses X.509 certificates instead of PGP's web of trust model.

## Historical and Contextual Terms

**Crypto Wars**
: Ongoing political and legal conflicts over government attempts to regulate or restrict cryptographic technologies.

**Cypherpunk**
: A movement advocating widespread use of strong cryptography and privacy-enhancing technologies as a route to social and political change.

**Export Controls**
: Government regulations restricting the export of cryptographic software and technology, historically limiting PGP distribution.

**ITAR (International Traffic in Arms Regulations)**
: U.S. regulations that once classified cryptographic software as munitions, affecting early PGP distribution.

**Phil Zimmermann**
: Creator of the original Pretty Good Privacy software in 1991, pioneering widely available public-key cryptography.

**Wassenaar Arrangement**
: International agreement on export controls for conventional arms and dual-use goods and technologies, including cryptographic software.

## Modern Alternatives and Related Technologies

**Signal Protocol**
: A modern cryptographic protocol providing end-to-end encryption with forward secrecy, used by Signal, WhatsApp, and other messaging applications.

**Age**
: A simple, modern file encryption tool designed as an alternative to PGP for file encryption use cases.

**Keybase**
: A platform that combines key management with identity verification and secure communication, now owned by Zoom.

**Matrix/Element**
: A federated communication protocol and client that provides end-to-end encryption for instant messaging and file sharing.

**ProtonMail**
: An encrypted email service that uses PGP encryption with a simplified user interface.

**Session**
: A privacy-focused messaging application that combines the Signal protocol with onion routing for enhanced anonymity.

---

## Cross-References

For more detailed information about these terms and concepts, refer to:

- **[PGP Overview](index.md)** - Introduction to core concepts
- **[Usage Guide](02-usage.md)** - Practical implementation
- **[Advanced Security](04-advanced.md)** - Advanced cryptographic concepts
- **[References](06-references.md)** - Additional resources and documentation

This glossary is regularly updated to reflect current terminology and practices in the PGP/GPG ecosystem.
