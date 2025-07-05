# Summary

---

The purpose of this information is to explain what PGP/GPG is and how to use it to secure communications. While frequently PGP is used together with other tools for anonymity, like Tor or I2P, that is not the purpose of this guide. The PGP encrypted messages do not have to be sent over email. Messages can be easily sent over SMS, Facebook, or any application that will allow you to paste in the encrypted message. The message could also be contained in an encrypted file and sent as an attachment or stored in a shared file system. This guide you will cover the basic tasks required to install a PGP application, create a PGP keypair, encrypt, decrypt, sign, and verify messages, as well as how store, share, and retrieve keys using a public key server.

Applications to enable the use of PGP are available for Windows, Mac, Linux, and mobile devices. This guide will use Kleopatra and GPA as part of the GPG4Win application, or GPG4Win portable, to enable this capability on Windows hosts. The GPG4Win Portable application will allow you to store the application and your keys on a USB device so that it can be used without having to install the application. It can also be run from the local file system for situations when you can&#39;t install applications and are prevented from mounting removable media.

One thing to keep in mind is that PGP cannot protect your messages from situations where the plaintext message may be captured before it is encrypted. For example, a key logger installed on the host used to create the message before it is encrypted will capture the keystrokes used when crafting the message. Also, do not create your messages in a service like Gmail, as the text that you entered could be saved automatically as a &quot;draft&quot; within your account by the service. Instead, craft the message in notepad and only paste the message into Gmail once it is encrypted.

## PGP Background (Wikipedia)

[**https://en.wikipedia.org/wiki/Pretty\_Good\_Privacy**](https://en.wikipedia.org/wiki/Pretty_Good_Privacy)

Pretty Good Privacy is a data encryption and decryption computer program that provides cryptographic privacy and authentication for data communication. PGP is often used for signing, encrypting, and decrypting texts, e-mails, files, directories, and whole disk partitions and to increase the security of e-mail communications.

To the best of publicly available information, there is no known method which will allow a person or group to break PGP encryption by cryptographic or computational means. Indeed, in 1995, [cryptographer](https://en.wikipedia.org/wiki/Cryptographer)[Bruce Schneier](https://en.wikipedia.org/wiki/Bruce_Schneier) characterized an early version as being &quot;the closest you&#39;re likely to get to military-grade encryption.&quot;[[](https://en.wikipedia.org/wiki/Pretty_Good_Privacy#cite_note-2)

## Concepts

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

## Conclusion

This should provide you with enough information to get started with PGP/GPG. While PGP can seem complicated at first it is actually pretty simple. With this technology you can secure nearly all of your electronic communications.