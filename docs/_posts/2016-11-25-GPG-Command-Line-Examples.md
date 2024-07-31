---

title:  GPG Command Line Examples
date:   2016-11-25 00:00:00 -0500
categories: IT
---






Here are some GPG examples for creating symmetric and asymmetric encrypted messages. The code used below is written for PowerShell.

Download keys from a key server
```powershell
gpg --keyserver pgp.mit.edu --search-keys streeter76@gmail.com
gpg --keyserver pgp.mit.edu --recv-keys 88488596
```

Import private key
```powershell
gpg --import ./private.asc
```

Put the contents of a file into a variable to be encrypted
```powershell
$a = gc /etc/passwd
```

Symmetric encryption of the variable contents
```powershell
$a | gpg --symmetric --armor
# Decrypt the message
$a | gpg --decrypt
```

Symmetric encryption of the variable contents with the passphrase provided
```powershell
$a | gpg --symmetric --armor --passphrase password
# Decrypt the message with the passphrase provided
$a | gpg --decrypt --passphrase password
```

Encrypt the variable contents for a recipient
```powershell
$a | gpg -e -r first.last@gmail.com --armor
```

Decrypt the message sent to recipient
```powershell
$b | gpg -d
```


