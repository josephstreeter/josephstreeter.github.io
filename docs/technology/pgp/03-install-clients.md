# Install Clients

---


## [GPG4Win (Windows)](#tab/windows)

Download: [http://gpg4win.org/download.html](http://gpg4win.org/download.html)

Make sure that Kleopatra and GNU Privacy Assistant (GPA) are installed. GPA is not selected as an option by default. Either Kleopatra or GPA can be used to encrypt and decrypt messages.

1. Choose your language, click **Ok**

[![image](RackMultipart20211128-4-dbovmn_html_e53115da50210aaf.png)](http://www.deepdotweb.com/wp-content/uploads/2015/02/SUJ3aT21.png)

1. Click **Next**, then **Next** again. You**ll now be at a screen asking what components you want to install. We&#39;ll be selecting **Kleopatra**, **GpgEX**, and **Gpg4win Compendium**. Then click **Next**

[![image](RackMultipart20211128-4-dbovmn_html_b2b6267a689e4d14.png)](http://www.deepdotweb.com/wp-content/uploads/2015/02/oNLB4Kk1.png)

1. It will ask where to install, just keep the default and click **Next**
2. Now it'll ask where you want to install shortcuts. Select whichever you want, click **Next**
3. You can choose which Start Menu folder you want it installed in, just click **Next**
4. It will now install, when done you should see this. Click **Next**, then **Finish** [![image](RackMultipart20211128-4-dbovmn_html_6e4d881d85af9aa2.png)](http://www.deepdotweb.com/wp-content/uploads/2015/02/RYUfaj41.png)

## [GPG (Redhat/CentOS)](#tab/redhatcentos)

Installing just GnuPG.

```bash
sudo yum install gnupg
```
## [GPG (Debian/Ubuntu)](#tab/debianubuntu)

Installing just GnuPG.

```bash
sudo apt update
sudo apt install gnupg
```
## [GnuPG/Gnu Privacy Assistant (Linux)](#tab/linux)

Installing GnuPG with Gnu Privacy Assistant. I like GPA as a graphical front-end because its layout is really easy to understand and follow.

1. Open a Terminal
2. Enter the following command and press **Enter**

    ```bash
    sudo apt-get install gpa gnupg2
    ```
3. Enter your sudo password, hit **Enter**
4. This will install all dependancies needed for both to work properly, tell you the space needed, and ask you to confirm. Type **Y** then press **Enter** to confirm
5. Wait while everything installs

This should only take a few minutes to complete. See this picture to confirm you're doing the steps correctly:

[![image](RackMultipart20211128-4-dbovmn_html_64f646618718b6c2.png)](https://www.deepdotweb.com/wp-content/uploads/2015/02/TVjAVPp1.png)

## [iPhone (IPGMail)](#tab/iphone)

```<...>```

## [Mac OS (GPG Suite)](#tab/macos)

```<...>```

---
