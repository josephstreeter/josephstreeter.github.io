---
layout: post
title:  "Sorry, another account from your organization is already signed in on this computer"
date:   2020-06-02 00:00:00 -0500
categories: IT
---






If you're getting this error you will need to clear out cached credentials in order to resolve.

Step 1: Remove cached identities in HKCU registry

In Registry Editor, locate the following registry: HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Common\Identity\Identities
Remove all identities under the Identities registry entry.

Step 2: Remove the stored credentials in Credential Manager
Open Control Panel > Credential Manager.
Remove all Windows credentials listed for Office16 by selecting the drop-down arrow and Remove.
Remove stored credentials in the Credential Manager

Step 3: Clear persisted locations
Clear the following persisted locations if they exist:

Credential Manager
%appdata%\Microsoft\Credentials
%localappdata%\Microsoft\Credentials
%appdata%\Microsoft\Protect
HKEY_CURRENT_USER\Software\Microsoft\Protected Storage System Provider

Office 365 activation tokens and identities
%localappdata%\Microsoft\Office\16.0\Licensing
%localappdata%\Microsoft\Office\Licenses (Microsoft 365 Apps for enterprise version 1909 or later)
HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Common\Identity
HKEY_USERS\The user's SID\Software\Microsoft\Office\16.0\Common\Identity


