# Concepts

---

PGP allows us to perform one or more of the following tasks; encrypt, decrypt, sign, or verify. This section will describe each of these tasks. It is important to understand how the pubic and private keys are used and by whom for each of these tasks.

- Creating Keypairs
- Managing KeyPairs
- Encryption takes the recipient's ***public key*** and scrambles a message. This scrambled text is only able to be unscrambled by the recipient's ***private key***. The sender always ***encrypts*** with the recipient's ***public_ key_***.
- Decryption takes a message that has been ***encrypted*** using the recipient's ***public key*** and descrambles it using the recipient's ***private key*** and the passphrase associated with that ***private_ key***. The recipient always decrypts with the recipient's ***private_ key***.
- Signing a message authenticates the author the message and provides cryptographic integrity. In other words, it ensures that the message was authored by the owner of the keypair that it was signed with and that it was not tampered with in transit. The sender always signs a message with the sender's ***private_ key*** and the passphrase associated with it.
- Verifying_ a message is the process of analyzing a signed message, to determine if the signing is true.

Signing and verifying can be thought of as opposites.

> [!WARNING]
> Signing a message does not obscure the contents of the message; it only authenticates the sender and verifies that the message
> hasn't been altered. However, an encrypted message can also be signed by the author.

## Putting It All Together

The sender of the message must retrieve the recipient's public key. The sender can aquire the public key in a number of ways; sent via email, copied off the recipient's web page or business card, downloaded from a key server, or any other method. The key point to remember is that the public key is "public", so it doesn't really matter how the the sender gets the public key.

The message is composed by the sender and encrypted with the recipient's public key resulting.

The resulting cyphertext is copied and pasted into an email, SMS message, Facebook post, chat message, etc. and sends it. It is important to note that only the encrypted text is secured. In the case of email, the sender and recipient's email addresses, subject, and message headers, and other information is still sent in plaintext.

The recipient uses his own private key, unlocked with the private key's password, to decrypt the cyphertext message. This is what makes the private key so important. Only someone with the private key and password, that is from the same key pair as the public key used to perform the encryption, can decrypt the message.

## When Should I Sign? When Should I Encrypt?

It is not necessary to sign and encrypt every outgoing email. Understanding how the signing and encrypting of messages achieves confidentiality and authentication will help you choose which method, if any, should be used.

- Confidentiality - Ensuring that the message can only be read by its intended audiance
- Authentication - Validating that the message was sent why who it appears sent it (non-repudiation) and that it was not tampered with in transit (integrity)

The three available choices are:

- Do nothing: The contents of the message is not confidential and authentication is not important, the message can be sent in plain text.
- Sign (not encrypted):  Message authentication is important, but the contects of the message are not confidential, sign the message, but do not encrypt.
- Sign and Encrypt: If the contents of the email are confidential, sign and encrypt. While possible to encrypt a message without signing, if the message is important enough to encrypt, it is important enough to be be signed

For 90% of messages most people send, signing and encrypting is not necessary. The remaining 10% of the time may require signing and encrypting confidential information (i.e. Personally Identifiable Information (PII), credit card information, bank numbers, social security numbers, corporate strategies, etc.
The need for signing only will likely be rare.

### Sending PGP Encrypted Attachments (a.k.a., PGP MIME type) vs Sending Cyphertext (a.k.a., PGP INLINE)

Nothing is gained from sending the message as an attachments, so it ends up being extra steps for no reason. Inline text works places where attachments don't (the shell, Facebook, iMessage, etc.). Many applications and email clients do not have built in PGP capabilities or available plugins requiring sedning inline anyway.

### Using Mail Client PGP Plugins (i.e., Mail.app PGP plugin)

Relying on mail client plugins can result in a false sense of security. Unless you have access to the source code and are willing to review it, users have no idea what the plugins may be doing. When a plugin generates an attachment and sends it before you can see what is going on, you have no idea what is happening or if it is working.
