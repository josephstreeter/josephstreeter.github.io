# Windows (GPG4Win)

---

## Install

Download: <http://gpg4win.org/download.html>
Make sure that Kleopatra and GNU Privacy Assistant (GPA) are installed. GPA is not selected as an option by default. Either Kleopatra or GPA can be used to encrypt and decrypt messages.

1. Choose your language, click “Ok”
  
2. Click “Next”, then “Next” again. You”ll now be at a screen asking what components you want to install. We’ll be selecting “Kleopatra”, “GpgEX”, and “Gpg4win Compendium”. Then click “Next”
  
3. It will ask where to install, just keep the default and click “Next”
4. Now it’ll ask where you want to install shortcuts. Select whichever you want, click “Next”
5. You can choose which Start Menu folder you want it installed in, just click “Next”
6. It will now install, when done you should see this. Click “Next”, then “Finish”  

## Create PGP Key Pair

## [Kleopatra](#tab/createkeypairkleopatra)

The next step is to generate your keypair so you can encrypt/decrypt messages. Like always, we’ll be going with 4096 bit RSA. You will create a Public and Private key pair with information related to your identity and email address or addresses. This is important to help others locate your public key on the key server.
If we were concerned with anonymity, we would make sure that none of the information used in the key pair could be used to reveal our true identity. The e-mail could be a valid alias for an anonymous email service on the DarkNet or complete gibberish.
Kleopatra should be used to create your key pairs instead of GPA because it will allow you to create a 4096 bit RSA key where GPA will only allow you to create a 2048 bit RSA key.

1. Open up Kleopatra application
  
2. Click “File”, then “New Certificate…”
  
3. In the Certificate Creation Wizard click “Create a personal OpenPGP key pair”
  
4. Enter your personal information, but do not click Next yet.

5. Click “Advanced Settings…”, and in the Advanced Settings dialog box in the “Key Material” section select the “RSA” radio button, select “4,096 bits” from the drop-down menu, and click “Ok”
  
6. Verify that the information you entered your information correctly and click “Create Key”  
7. Enter a secure passphrase in the “pinentry” dialog box and click “Ok”
  
8. Kleopatra will now generate the key pair. The random entry of data is used to create entropy. Enter text, move the mouse, etc.
  
9. Once the key is created, click “Finish”

## [GPA](#tab/createkeygpa)

Next, you want to make a PGP key. Remember, none of the details need to be valid. I'd use your online name or a different alias when making your key. Something that isn't your gamertag for online games, or anything that may tie to you. A completely new alias. The e-mail doesn't need to be valid at all. Here are some pictures to help you through the process. Also, make a backup of your key!!!
First, click the keys in the menu at the top. Alternatively, you can click CTRL+N to begin the process of creating a key. Shown here:

1. You will go through a set-up, where you make a name for your key, which I suggest you use an alias. Shown here:

2. After selecting your alias, it asks for an e-mail address. This e-mail should be non-existent, and be linked to a website that also doesn't exist. Shown here:

3. Then you're asked to make a backup of your key. I highly suggest you do this! Although you can make a back up at any time, you should just do it now. This is where your public key will be that you give to others to contact you. Shown here:

4. Find where you put the back up of your key. It will be an .asc file but no worries, when asked to open the file just tell windows or whatever OS to open it using Notepad. Here you will find a public key similar to this.

5. When sharing your key with others, you want to copy and paste from the beginning dashes to the end dashes. Exactly how I have copied and pasted above.
## [CLI](#tab/cli)

The following command creates a new key pair.

``` bash
gpg --gen-key
```

---

## Publish the Public Key to a Key Server

Add your public key to a public key server so people can find your public key in order to send you secure messages.

## [Kleopatra](#tab/publishkeypairkleopatra)

Add your public key to a public key server so people can find your public key in order to send you secure messages. A public key can be published to a key server from GPA by clicking on the “Server” menu and selecting “Send Keys.”

## [GPA](#tab/publishkeypairgpa)

## [CLI](#tab/publishkeypairCLI)

``` bash
gpg --armor --output public.asc --export <Your Name>;
```

``` bash
gpg --send-keys <Your Name> --keyserver hkp://subkeys.pgp.net
```

``` bash
gpg --search-keys <myfriend@his.isp.com> --keyserver hkp://subkeys.pgp.net
```
---


## Retrieve Public Keys

In this step we are going to retrieve the public key from the key pair that was just created. By doing this we are able to make the public key available to those that wish to communicate with you securely. Without it, they will not be able to encrypt messages that you are able to decrypt.
## [Kleopatra](#tab/retrevekeypairkleopatra)


## [GPA](#tab/retrevekeypairgpa)


1. In the “My Certificates” tab, right click on your key and click “Export Certificates…”
2. Browse to the location where you want to save the public key and click “Save” (Note: you may want to give it a name that distinguishes this file as your public key)
3. The public key can be viewed in a text editor, like notepad. Browse to the location where you saved the key and open it. (Note: The key will have a “.asc” extension, you may have to select “All files” from the dropdown menu.
4. The text you see in the file is your public key. This is the text that you will send to others so they can import it into their PGP application.
  
## [CLI](#tab/retrevekeypairCLI)

``` bash
gpg --import key.asc
```

``` bash
gpg --list-keys
```
---

## Obtaining the Private Key

## [Kleopatra](#tab/obtainprikeykleopatra)

Similar to obtaining your public key

1. Right click on your key in the “My Certificates tab and select “Export Secret Keys…”
  
2. Select the location to save your private key, give it a name, check “ASCII armor”, and click “Ok”  
The following dialog box confirms the export of your private key. (Remember to keep the private key safe and never share it!)
3.

## [GPA](#tab/obtainprikeygpa)

## [CLI](#tab/obtainprikeycli)

``` bash
gpg --armor --export-secret-key --output private.asc --export <Your Name>
```

---

## Importing a Public Key

It’s impossible to send a vendor an encrypted message without their public key. 

The public key could be sent to you in an email as an attachment or included in the signature block, downloaded from a key server, shared from removable storage, etc.

## [Kleopatra](#tab/importprikeykleopatra)

The private key that you will be importing is from a key pair that you have previously created. This private key is used to sign outgoing messages and to decrypt incoming messages. Any host or device that contains your private key should be considered “sensitive” because loss or theft could lead to the compromise of your private key.

1. Click “File”, “Import Certificates…”
  
2. Browse to the location where the private key is saved, select it, and click “Open”  
3. A window will be displayed confirming the import of the private key. Click “Ok” to contintue.
4. The key information should now be displayed in the “My Certificates” tab

## [GPA](#tab/importprikeygpa)

You see people giving their public keys away so others can contact them. Simply open a notepad file, copy and paste their key and import it using the GPA program. I will show you how to do this.
First make a blank text file and copy the users pubic key to it. Shown here:

Then, in the Keys menu where you made your key, select import keys. Shown here:

## [CLI](#tab/importprikeycli)

``` bash
gpg
```

---

## Encrypting a Message


## [Kleopatra](#tab/encryptmessagekleopatra)

To create a message and encrypt it:

1. Open Notepad and create your message
2. Copy the entire message to the clipboard

3. In your task bar, right click on the Kleopatra icon, go to “Clipboard”, then click “Encrypt…”  
4. This gorgeous window will open. Click “Add Recipient…”
  
5. Another window will appear. Click the “Other Certificates” tab, then select who you want to send your message to, then click “Ok”.

6. You should be back at the previous window with the recipient listed. Click “Next”  
7. If all went well, you should see this window. Click “Ok”
  
8. Your encrypted message will be in your clipboard, all you need to do is paste it into the message box and send
  
## [GPA](#tab/encryptmessagegpa)

## [CLI](#tab/encryptmessagecli)

Here we encrypt/decrypt a file that is just for our own use.

``` bash
gpg --encrypt --recipient <Your Name> foo.txt
```

Encrypting for another recipient

``` bash
gpg --encrypt --recipient <myfriend@his.isp.net> foo.txt
```

---

## Decrypting a Message

## [Kleopatra](#tab/decryptmessagekleopatra)
This is just as easy as encrypting.

1. Copy everything that was sent
  
2. In your task bar, right click on the Kleopatra icon, go to “Clipboard”, then click “Decrypt/Verify…”
  
3. A window will pop up asking for your passphrase, enter that then click “Ok”
  
4. A window should pop up verifying it was decrypted, and copied to your clipboard. Click “Finish”

5. Open your text editor of choice, and paste your message
## [GPA](#tab/decryptmessagegpa)
## [CLI](#tab/decryptmessagecli)
``` bash
gpg --output foo.txt --decrypt foo.txt.gpg
```

---

## Revoke a Key

## [Kleopatra](#tab/revokekeykleopatra)
## [GPA](#tab/revokeprikeygpa)
## [CLI](#tab/revokeprikeycli)

``` bash
gpg --gen-revoke --output revoke.txt --export <Your Name>
```

---

## Verify Signature

## [Kleopatra](#tab/verifysigkleopatra)
## [GPA](#tab/verifysiggpa)
## [CLI](#tab/verifysigcli)

``` bash
gpg --verify crucial.tar.gz.asc crucial.tar.gz
```

``` bash
gpg --armor --detach-sign your-file.zip
```
---