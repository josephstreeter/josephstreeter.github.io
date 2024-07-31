# Advanced
---

## Securely Composing Email

### Metadata

Metadata provides the context to the content of the email. Protecting the email content (with PGP) will significantly enhance the security of the communication. Frequently, the context (the metadata) is sufficient to learn a great deal about the communication even without the content. Unfortunately, even PGP encrypted email leaves communications metadata exposed, this includes:

- Subject
- To
- From
- Dates and times
- IP addresses
- email application

Minimizing the contextual information leakage from the email starts with knowing what metadata will be exposed. Where possible, and relevant, take control over that information and unlink it from data linked to you. For example, you can control the From field by creating a new email account. The IP address of the sending email client can be changed by using a VPN, Tor, or a public Internet connection. One option to consider is the use of Tor. The usual caveats about Tor apply: do not rely exclusively on Tor, if you need to protect your IP address then use an IP address that is not attributable to you.

### The Subject

There is little else you can do about the To, From, and IP, as those are controlled by the infrastructure. However, you have complete control over the Subject. All acceptable subjects are listed below:

- ...
- xxx
- ;;;
- :::
- \&lt;space\&gt;

The Subject must never ever refer to the content of the email, even obliquely. For example, &quot;Subject: Your cocaine has shipped!&quot; is a total email security failure.

- **Subjects should be empty**!
  - Disable the _Warn about empty subject_ setting on your email client

### Writing

There are fundamentally two options when composing an email: you can either write the email in a text editor, or in an email client. For security, that is, control over the process, a text editor is safer. For convenience most people will use their email client.

- Safest
  - Write in a text editor
  - Encrypt on the command line
  - Only expose already-encrypted data to the email client
- Realistic
  - At least restrict the plaintext to the local system you control

### Drafts

- Don&#39;t save Drafts in plaintext

Drafts can be a significant source of risk. The storage and handling of drafts must be approached with care. Make sure that they are encrypted (never stored in plaintext), that they are stored locally (where you can be sure of deleting them) and that they are deleted after use. Make sure to configure your email client to store drafts locally and to encrypt them before writing them to disk.

- Don&#39;t store on server
- Ensure they are encrypted
- Ensure they are deleted after use

### Composition

- Delete the content in a reply, only quote the relevant parts if necessary

Mitigate against the potential threat of any single email being compromised by limiting the information within any single email. The more information is stored in the mental context of the correspondents, the less useful the information in the email is to an adversary. Wherever possible minimize the amount of irrelevant contextual information within the email body. Keep it short, simple, and clean.

### Attachments

- PGP has all the capability of tar or zip.

It is possible to include all the files you need to include as a pure PGP messages without having an attachment called secret-leaked-nsa-docs.tar.gz.gpg.asc. The program to use is gpg-zip and it takes both --tar= command line options and gpgcommand line options. Use this to bundle your files and send them as an opaque encrypted blob.

### Encrypting

- use --throw-keys to prevent leaking more metadata

PGP encryption stores metadata about the decryption keys in the encrypted data. This is a simple optimization to allow the recipient to rapidly determine whether the email can be decrypted by a private key they possess. This information also allows an attacker to determine who can read the email. If the email is intended to be truly anonymous, this metadata must be discarded. Fortunately, there is a gpg command line flag for this: --throw-keys.

Ensure that --throw-keys is added to the command line when encrypting data.

- PGP/MIME and inline PGP -ear aren&#39;t the same.

For more control and compatibility, use inline PGP.

### Sending

Ensure you encrypt by default

Accidentally sending an unencrypted email is a potentially fatal error. Configure your email client to always encrypt by default. If you want to send a plaintext email, then deliberately set that option.

Think about signing

Signing an email provides guarantees that the content was written by someone that possess the private key. That it is, it positively identifies at least one person involved in the email exchange. Think carefully about whether you want to be positively identified as the author of the email. Set your email client to not sign messages by default.

Sign messages explicitly.

Store sent messages locally, then delete them

After the email has been sent and is no longer operationally useful, delete it. To make sure that you can do this, configure your email client to store your _Sent_ messages locally. When in doubt, store locally. At least you will have some control over whether it is thoroughly deleted.

### Receiving

- Delete emails after they are no longer necessary
- INBOX ZERO
- OUTBOX ZERO
- DRAFTS ZERO
- TRASH ZERO
- Regularly delete all emails. Easiest way is to set the Trash to erase everything after 30 days, and then delete every email after it has been processed.

### Riseup.net PGP Configuration Guide

There is a PGP configuration guide from riseup.net. If you want to incorporate their best practice recommendations without any of their terrible advice about using key servers etc, then simply install this gpg.conf into your ~/.gnupg.

- [gpg.conf](https://github.com/stribika/duraconf/blob/master/configs/gnupg/gpg.conf)

### Outreach

- Remind your correspondents to practice the same PGP hygiene

