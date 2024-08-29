# Install Server Certificate for Domain Controllers

Created: 2015-03-20 09:41:11 -0500

Modified: 2015-03-20 09:45:13 -0500

---

**Keywords:** Campus active directory server certificate domain controller trust pki

**Summary:** By default, Active Directory LDAP traffic is transmitted unsecured. Clear and unsigned LDAP traffic is susceptible to sniffing and replay attacks. LDAP traffic can be secured using Secure Sockets Layer (SSL) / Transport Layer Security (TLS) technology. LDAP over SSL (LDAPS)is enabled by installing a properly formatted server certificate.

The InCommon/Comodo server certificates requested from OCIS are trusted by most operating systems natively without requiring the installation of additional root certificates.

Information about the OCIS Server Certificate request process

[Server Certificate Request Information](https://www.cio.wisc.edu/security-certificates.aspx)

**IMPORTANT NOTE:**

Before begining, verify that Active Directory Certificate Services are not installed on any of the domain controllers. If a third-party certificate is required for LDAP SSL connections, then it is important that the Microsoft Enterprise Certificate Authority not be installed on the LDAP server; this sets the Enterprise CA certificate as the default certificate for SSL validation. How to decommision a Windows Ent. CA: <http://support.microsoft.com/kb/889250>

**Submit certificate request to the Office of Campus Information Security**

- - On the target server, create the "request.inf" file by opening Notepad and copying the example below. Be sure to edit the "Subject" line so that "CN=yourservername.wisc.edu" matches the fully qualified domain name of the target server.

**Example "request.inf"**

;----------------- request.inf -----------------

[Version]
Signature="$Windows NT$"

[NewRequest]
;Change to your,country code, company name and common name
Subject = "C=US, O=University of Wisconsin-Madison, CN=yourservername.wisc.edu"

KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication / Token Signing
;-----------------------------------------------

- Save the "request.inf" file to the root of "C:".
- Open an elevated command prompt and change directory to "C:".
- Run the following command:"

C: > certreq -new request.inf request.csr

- Open a browser and navigate to the OCIS Server Certificate Request page [Server Certificate Request](https://www.cio.wisc.edu/restricted/request.aspx)
- In the OCIS Server Certificate Request enter your contact information
- Select "a first time request for the certificate" or "a request to renew a certificate that is nearing expiration" if an existing certificate is being replaced
- Select "Other" from the "Web Server Type" drop-down menu and enter "LDAPS for AD Domain Controller" in the text box that appears below
- Leave "Certificate Type" and "Validity Period" as the default "Single Domain" and "3 Years"
- Copy the contents of the "request.csr" file that was created earlier
- Enter "LDAPS for AD Domain Controller *<yourservername.wisc.edu>*
- Check the box for "I am responsible for running a service which uses this fully qualified domain name..." at the bottom of the form and click "Submit"

**IMPORTANT NOTE:**

Be careful to close out this page each time before using the above link again to request additional certificates otherwise it refreshes creating a duplicate request!

- After submitting the request a confirmation email will be sent to the contact provided in the request from OCIS
- An enrollment email will be sent from Comodo Certificate Services Manager (<support@cert-manager.com>) with links to download the certificate in different formats
- Click the link for "PKCS#7 Base64 encoded" to download the certificate
- Other available formats:
    as PKCS#7 Base64 encoded: <https://cert-manager.com/customer/InCommon/ssl?action=download&sslId=156346&format=base64>

(* Cryptographic Message Syntax Standard (PKCS #7) .p7b The PKCS #7 format supports storage of certificates and all certificates in the certification path. Does not include private key.)
When downloaded the file ends with .crt however if you open it you will notice that the certificate contains "-----BEGIN PKCS7-----" and "-----END PKCS7-----" statements.

- Upload the certificate file that was downloaded to the root of "C:" on the target server

**Install the Certificate**

- Open an elevated command prompt and change directory to "C:".
- Run the following command:

C: > certreq -accept <yourservername_wisc_edu>.crt

- Installation of the server certificate will enable LDAP over SSL which can be verified with the following steps:
  - Start the Active Directory Administration Tool (Ldp.exe)
  - On the Connection menu, click Connect
  - Type the name of the domain controller to which you want to connect
  - Type 636 as the port number
  - Click OK

**Enable LDAP Interface Events Debugging**

The domain controller will log Event ID 2887 each every 24 hours that will provide a summery of clients that used clear or unsigned binds. Enabling debugging for LDAP Interface Events will log an Event ID 2889 each time a client uses a clear or unsigned bind to the domain controller.

[Event ID 2889 LDAP signing](http://technet.microsoft.com/en-us/library/dd941849(v=ws.10).aspx)

[Event ID 2888 LDAP signing](http://technet.microsoft.com/en-us/library/dd941863(v=ws.10).aspx)

To enable diagnostic logging for LDAP Interface Events:

- Open an elevated command prompt
- Enter the following command
    Reg Add HKLMSYSTEMCurrentControlSetServicesNTDSDiagnostics /v "16 LDAP Interface Events" /t REG_DWORD /d 2

- When prompted to overwrite, type "Y" and press ENTER

To disable the diagnostic logging for LDAP Interface Events:

- Open an elevated command prompt
- Enter the following command
    Reg Add HKLMSYSTEMCurrentControlSetServicesNTDSDiagnostics /v "16 LDAP Interface Events" /t REG_DWORD /d 0

- When prompted to overwrite, type "Y" and press ENTER

**Additional Steps for Domain Controllers that require multiple server certificates**

If there are multiple valid certificates available in the local computer store, Schannel the Microsoft SSL provider, selects the first valid certificate that it finds store. The LDAP bind may fail if Schannel selects the wrong certificate.

Loading the requested server certificate into the NTDS/Personal certificate store will ensure that the correct server certificate is used for LDAPS

**IMPORTANT NOTE:**

- Automatic certificate enrollment (auto-enrollment) cannot be utilized to populate NTDSPersonal certificate store
- Command line tools are not able to manage certificates in the NTDSPersonal certificate store
- Certificates should be imported into the NTDSPersonal store and not moved through drag-and-drop in the Certificates snap-in
- The import process must be conducted on each domain controller

[LDAP over SSL (LDAPS) Certificate (MS TechNet)](http://social.technet.microsoft.com/wiki/contents/articles/2980.ldap-over-ssl-ldaps-certificate.aspx#Exporting_and_Importing_the_LDAPS_Certificate)

When exporting the certificate:

- When prompted, select "Yes, export the private key"
- Select the "Personal Information Exchange - PKCS #12(.pfx)" format
- Do not select "Include all certificates in the certificate path" or "Delete the private key if the export is successful"
- Select "Export all extended properties"

Publish the Comodo root certificate (AddTrustedExternalCaRoot.crt) to the NTAuthCA certificate store
