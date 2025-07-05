# Security Settings Applied for InCommon Silver Compliance

## Summary

The following settings have been applied to Campus Active Directory in order to secure credential secrets in a way that is compliant with InCommon Silver.

## 4.2.3.4 Stored Authentication Secrets

Authentication Secrets shall not be stored as plaintext. Access to encrypted stored Secrets and to decrypted copies shall be protected by discretionary access controls that limit access to administrators and applications that require access (see also §4.2.5.6).

Three alternative methods may be used to protect the stored Secret:

1. Authentication Secrets may be concatenated to a variable salt (variable across a group of Authentication Secrets that are stored together) and then hashed with an industry standard algorithm so that the computations used to conduct a dictionary or exhaustion attack on a stolen Authentication Secret file are not useful to attack other similar Authentication Secret files. The hashed Authentication Secrets are then stored in the Authentication Secret file. The variable salt may be composed using a global salt (common to a group of Authentication Secrets) and the userID (unique per Authentication Secret) or some other technique to ensure uniqueness of the salt within the group of Authentication Secrets; or

2. Store Secrets in encrypted form using industry standard algorithms and decrypt the needed Secret only when immediately required for authentication; or

3. Any method protecting stored Secrets at NIST [SP 800-63] Level 3 or 4 may be used.

- "Network security: Do not store LAN Manager hash value on next password change" - Enabled

## 4.2.3.5 Protected Authentication Secrets

1. Any Credential Store containing Authentication Secrets used by the IdP (or the IdP's Verifier) is subject to the operational constraints in §4.2.3.4 and §4.2.8 (that is, the same constraints as IdMS Operations). When Authentication Secrets are sent from one Credential Store to another Credential Store (for example in an account provisioning operation) Protected Channels must be used.

2. Whenever Authentication Secrets used by the IdP (or the IdP's Verifier) are sent between services for verification purposes (for example, an IdP to a Verifier, or some non-IdP application to a Verifier), Protected Channels should be used, but Protected Channels without client authentication may be used.

3. If Authentication Secrets used by the IdP (or the IdP's Verifier) are exposed in a transient fashion to non-IdP applications (for example, when users sign on to those applications using these Credentials), the IdPO must have appropriate policies and procedures in place to minimize risk from this exposure.

- "Domain Controller: LDAP Server signing requirements" - Enabled
- "Network security: LDAP client signing requirements" - Enabled

## 4.2.5.1 Resist Replay Attack

The authentication process must ensure that it is impractical to achieve successful authentication by recording and replaying a previous authentication message.

- "Domain Controller: LDAP Server signing requirements" - Enabled
- "Network security: LDAP client signing requirements" - Enabled

## 4.2.5.2 Resist Eavesdropper Attack

The authentication protocol must resist an eavesdropper attack. Any eavesdropper who records all the messages passing between a Subject and a Verifier or relying party must find that it is impractical to learn the Authentication Secret or to otherwise obtain information that would allow the eavesdropper to impersonate the Subject.

- "Domain Controller: LDAP Server signing requirements" - Enabled
- "Network security: LDAP client signing requirements" - Enabled
- "Network security: LAN Manager authentication level - Send NTLMv2 response only. Refuse LM & NTLM

## 4.2.5.3 Secure communication

Industry standard cryptographic operations are required between Subject and IdP in order to ensure use of a Protected Channel to communicate.

- "Domain Controller: LDAP Server signing requirements" - Enabled
- "Network security: LDAP client signing requirements" - Enabled

## Additional Tasks

RADIUS clients must use PEAP-MS-CHAPv2 and not only MS-CHAPv2

IDS to detect NTLMv1 authentication and LDAP clear binds

Enable auditing to detect SASL binds that do not require signing and connections that are not SSL/TLS encrypted

## Potential Impact

Network security: Do not store LAN Manager hash value on next password change

- Windows 95 systems will not be able to authenticate
- Samba versions less than 3.0 will not be able to authenticate

Domain Controller: LDAP Server signing requirements

- Clients that do not have the appropriate trusted root certificates installed will be unable to bind to LDAP

Network security: LDAP client signing requirements

- None

Network security: LAN Manager authentication level

- Windows 95/98/ME systems will require the Directory Services Client (DSClient) and NTLMv2 enabled
- Windows NT will require NT4 Service Pack 6a
- Systems using SAMBA must be version 3.0 or higher

## References

Client, service, and program incompatibilities that may occur when you modify security settings and user rights assignments

<http://support.microsoft.com/kb/823659>

How to enable LDAP signing in Windows Server 2008

<http://support.microsoft.com/kb/935834>
