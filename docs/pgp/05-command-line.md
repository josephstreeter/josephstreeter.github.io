# Command Line (gpg.exe)

---

## Install

## Create PGP Keypair

Before you can encrypt or sign files with GPG you must have a key.

``` bash
gpg --gen-key
```

## Retrieve the Public Key

Post the public, ascii side of your key to the web

``` bash
gpg --import key.asc
```

``` bash
gpg --list-keys
```

## Publish the Public Key

``` bash
gpg --armor --output public.asc --export <Your Name>;
```

``` bash
gpg --send-keys <Your Name> --keyserver hkp://subkeys.pgp.net
```

``` bash
gpg --search-keys <myfriend@his.isp.com> --keyserver hkp://subkeys.pgp.net
```

## Obtain the Private Key

``` bash
gpg --armor --export-secret-key --output private.asc --export <Your Name>
```

## Importing a Private Key

``` bash
gpg
```

## Encrypting a Message

Here we encrypt/decrypt a file that is just for our own use.

``` bash
gpg --encrypt --recipient <Your Name> foo.txt
```

## Encrypting for Recipient

``` bash
gpg --encrypt --recipient <myfriend@his.isp.net> foo.txt
```

## Decrypting a Message

``` bash
gpg --output foo.txt --decrypt foo.txt.gpg
```

## Revoke a key

``` bash
gpg --gen-revoke --output revoke.txt --export <Your Name>
```

## Signatures

``` bash
gpg --verify crucial.tar.gz.asc crucial.tar.gz
```

``` bash
gpg --armor --detach-sign your-file.zip
```
