# Certificate Management

## Certificate Services on Linux (Admins Only)**

Verify SSL Certificate

1. Create a directory to store the certificate:
    $ mkdir -p ~/.cert/ad.wisc.edu/
    $ cd ~/.cert/ad.wisc.edu/

2. Retrieve the ad.wisc.edu certificate provided by the Campus httpd server:
    $ openssl s_client -showcerts -connect ad.wisc.edu:443

3. From the output of the showcert parameter copy from ----BEGIN CERTIFICATE---- to ---END CERTIFICATE--- and save it in your ~/.cert/ad.wisc.edu/ directory as **ad.wisc.edu.pem**
4. Retrieve the Certificate of the Issuer:

## Certificate Services on PC

Certutil.exe is a command-line utility for managing a Windows CA. In Windows Server 2003, you can use Certutil.exe to publish certificates to Active Directory. Certutil.exe is installed with Windows Server 2003. It is also available as part of the Microsoft Windows Server 2003 Administration Tools Pack. To download this tools pack, visit the following Microsoft Web site: [http://www.microsoft.com/downloads/certutil.exe](http://www.microsoft.com/downloads/details.aspx?FamilyID=c16ae515-c8f4-47ef-a1e4-a8dcbacff8e3&DisplayLang=en)

## Viewing/Verifying Certificates

### 3rd Party Certificate

Adding

- Open Certificate Manager by clicking **Start** button, typing **certmgr.msc** into the **Search** box, and then pressing **Enter**. If you are prompted for an administrator password or confirmation, type the password or provide confirmation
- Click the **Personal** folder (for a personal certificate which is most likely what you have), click the **Action** menu, point to **All Tasks**, and then click **Import**
- Follow the wizard to import your certificate to the specified folder you selected in the preceding step

Deleting

- Open up the cmd prompt by clicking **Start**, then in the search bar right above the Start button enter **cmd.exe** and hit enter
- Can use MMC gui or certutil.exe utility to get to the Certificate Store by entering the below command in the cmd prompt or look for the mmc plugin in you installed applications.
  - certutil -viewstore -enterprise NTAuth

NTAuth is an Active Directory directory service object that is located in the Configuration container of the forest

- To Verify NTAuth enter the following in cmd prompt: certutil -verifystore -enterprise NTAuth
- To Delete the Certificate enter the command
    certutil -delstore -enterprise -user My **certificate_name**
    or in the MMC find your certificate and either click the delete button or right click the certificate and select the delete option.

If the certutil -deletestore command above does not work then try: certutil -delstore MY **certificatename**

## Certificate Services on Mac

Verification

- Open the Keychain Access program in Applications -> Utitlities folder in Finder
- Once the application is running you can then select *Certificates* in the bottom left
- Search for your certificate in the window on the right

```bash
openssl verify -verbose -CAfile cacert.pem server.crt
```

Where the -CAfile argument is a path to your certificate

Adding

- Obtain your certificate before proceeding
- Locate the certificate file you wish to add
- Double-click the desired certificate to store
- Then the Keychain Access program will ask if you will trust this certificate. Click **Always Trust**
- Now the certificate is in the Keychain Access program

Deleting

- Navigate to *Utilities* folder in the *Applications* section of the Mac hard drive
- Double-click the **Keychain Access** icon to open the certificate application
- Select *Certificates* fron the list of categories in the lower left corner of the window
- Right Click on the virtual certificate you wish to delete and select *Delete*
- A confirmation dialog box will appear
- Click **Delete** to confirm the decision
