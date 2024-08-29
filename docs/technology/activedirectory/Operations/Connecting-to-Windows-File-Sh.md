# Connecting to Windows File Shares

## Microsoft Windows 8

Graphical User Interface

- Open an Explorer window
- On the tool bar click "Computer"
- Click "Map Drive"
- In the "Map Network Drive" dialog box select a drive letter
- Enter the UNC path to a file share (e.g. [deptfs-server-01share](file://deptfs-server-01/share))
- You may optionally check the "Reconnect at Logon" box if you want the drive mapping to persist
- You may optionally check the "Connect using different credentials" if necessary
- Click "Finished"

Command Line

- From a command prompt the following command willcreate a persistent drive mapping
  - net use K: [deptfs-server-01share](file://deptfs-server-01/share) /persistant:yes
- From a command prompt the following command willcreate a persistent drive mapping using alternate credentials
  - net use K: [deptfs-server-01share](file://deptfs-server-01/share) /persistant:yes /user:netid@wisc.edu

PowerShell

- From PowerShell the following command willcreate a persistent drive mapping
  - New-PSDrive â€"Name â€œKâ€ â€"PSProvider FileSystem â€"Root â€œdeptfs-server-01shareâ€ â€"Persist
- From PowerShell the following command willcreate a persistent drive mapping using alternate credentials
  - New-PSDrive â€"Name â€œKâ€ â€"PSProvider FileSystem â€"Root â€œdeptfs-server-01shareâ€ â€"Persist -Credential $(Get-Credential)

## Apple Mac (10.7 and later)

Use the Connect To Server feature of the Finder:

- Select "Go"and "Connect To"
- EnterIP address or DNS name of the file server
  - smb://10.0.1.1/share
  - smb://deptfs-server-01.dept.wisc.edu/share
- Enter username (<netid@wisc.edu>) and password if prompted

## Linux

- The Linux host must be configured for Kerberos authentication prior to executing the following command (Directions [here](file:///C:/Users/jstreeter/OneDrive/Documents/AD%20Docs/CADS%20Documents/KB%20Docs/page.php?id=38436)[)](mailto:netid@doit.wisc.edu)
  - mount -t cifs -o user=<netid@ad.wisc.edu> //deptfs-server-01/share share
- Notice the username is <netid@ad.wisc.edu> and not <netid@wisc.edu>
