# Confirming LDAPS Certificates

The following bash script will validate the SSL certificates on each Domain Controller. Script must be run on a host with openssl installed.

```bash
#! /bin/bash

openssl s_client -showcerts -verify 5 -connect 10.39.0.127:636 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/) {a++}; out="matc-dc-cert"a".pem"; print >out}'

for cert in *.pem; do openssl verify -show_chain $cert ; done
```

Example output 

> [!NOTE]
> The "verification failed" is due to the CA being self-signed.

verify depth is 5

Can't use SSL_get_servername

depth=0 CN = IDMDCPRD05.MATC.Madison.Login

verify error:num=66:EE certificate key too weak

verify return:1

depth=1 DC = Login, DC = Madison, DC = MATC, CN = MCICA01

verify error:num=20:unable to get local issuer certificate

verify return:1

depth=0 CN = IDMDCPRD05.MATC.Madison.Login

verify return:1

DONE

CN = IDMDCPRD05.MATC.Madison.Login

error 20 at 0 depth lookup: unable to get local issuer certificate

error matc-dc-cert1.pem: verification failed

DC = Login, DC = Madison, DC = MATC, CN = MCICA01

error 20 at 0 depth lookup: unable to get local issuer certificate

error matc-dc-cert2.pem: verification failed

**

**

The following PowerShell script will validate the installed SSL cert on each Domain Controller:

```powershell
$DCs=Get-ADDomainController -Filter * | select -ExpandProperty hostname

$ScriptBlock={
    $HostName="{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN
    $Cert=Get-ChildItem -Path cert:LocalMachineMy | ? {$_.Subject -match $HostName}
    $FilePath="c:scripts$HostName.cer"
    certutil -v -urlfetch -verify $FilePath
}

foreach ($DC in $DCs)
{
    Invoke-Command -ComputerName $DC -ScriptBlock $ScriptBlock -Credential $creds
}
```

Example results shown below. Look at the output for errors.

```text
Issuer:
CN=MCICA01
DC=MATC
DC=Madison
DC=Login
[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)
0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD06.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD06.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 36 2e 4d 41 54 43 2e IDMDCPRD06.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 36 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.6...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): 728d2dbde8343b2658abc38f11bb4d4ac26fd5cc

Name Hash(md5): a1746256349a6bd75fbc1429b0d83df5

Cert Serial Number: 1d0001d8ec61dacb7425ceb8a800000001d8ec

0000 ec d8 01 00 00 00 a8 b8 ce 25 74 cb da 61 ec d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 33 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 33 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 4:36 AM

NotAfter: 11/27/2023 4:36 AM

Subject: CN=IDMDCPRD06.MATC.Madison.Login

Serial: 1d0001d8ec61dacb7425ceb8a800000001d8ec

SubjectAltName: Other Name:DS Object Guid=04 10 0d 59 76 7d bf 8e c1 46 bb 07 80 e4 67 66 5b 05, DNS Name=IDMDCPRD06.MATC.Madison.Login

Template: DomainController

Cert: efdd3818e8e4fe8dc2b2b8694a7270555d82cc8f

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

OK "Delta CRL (0680)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

OK "Delta CRL (0680)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/5/2023 4:05 PM

NextUpdate: 9/13/2023 4:25 AM

CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3

Delta CRL 0680:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/7/2023 4:05 PM

NextUpdate: 9/9/2023 4:25 AM

CRL: 4203206d8432188dae986ab21d319375d9f24823

Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication

Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication

CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 11:45 AM

NotAfter: 2/20/2029 11:55 AM

Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

Serial: 61000000022fcc148140855cf0000000000002

Template: SubCA

Cert: f8b246170aababcdb629e1a65cfda395d78c4746

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Expired "Base CRL (03)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>

Expired "Base CRL (03)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:

Issuer: CN=MCRCA

ThisUpdate: 2/1/2023 2:42 PM

NextUpdate: 2/22/2024 3:02 AM

CRL: 95bd64510f142a48195b6b8d7053066ec1617bed

CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 10:15 AM

NotAfter: 2/20/2039 10:25 AM

Subject: CN=MCRCA

Serial: 46ec1044f89f81aa401aad4340a7767f

Cert: 15681660643728508078bac9a48d95b9778d42d1

Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)

Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:

Chain: b5c88c49ba27e91ef3e0b361b2ba15176ecebff4

Full chain:

Chain: 89350a2bf63781ae5899c84dc5bef0cba1d22418

------------------------------------

Verified Issuance Policies: None

Verified Application Policies:

1.3.6.1.5.5.7.3.2 Client Authentication

1.3.6.1.5.5.7.3.1 Server Authentication

Leaf certificate revocation check passed

CertUtil: -verify command completed successfully.

Issuer:

CN=MCICA01

DC=MATC

DC=Madison

DC=Login

[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD07.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD07.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 37 2e 4d 41 54 43 2e IDMDCPRD07.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 37 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.7...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): b2283a197289a44a7f04054f1fb8bdb8c53301ac

Name Hash(md5): 4b8b37d30cbe24434bc26faf4b2019f8

Cert Serial Number: 1d0001d8ed5934f230f36107d400000001d8ed

0000 ed d8 01 00 00 00 d4 07 61 f3 30 f2 34 59 ed d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 35 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 35 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 5:36 AM

NotAfter: 11/27/2023 5:36 AM

Subject: CN=IDMDCPRD07.MATC.Madison.Login

Serial: 1d0001d8ed5934f230f36107d400000001d8ed

SubjectAltName: Other Name:DS Object Guid=04 10 f7 c9 4e 21 f2 1b 64 44 b6 81 02 16 4b 3f 0b 11, DNS Name=IDMDCPRD07.MATC.Madison.Login

Template: DomainController

Cert: 2c881217dec461466be25257e19d6c0d32b1831b

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0

[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

OK "Delta CRL (0680)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

OK "Delta CRL (0680)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/5/2023 4:05 PM

NextUpdate: 9/13/2023 4:25 AM

CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3

Delta CRL 0680:

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

ThisUpdate: 9/7/2023 4:05 PM

NextUpdate: 9/9/2023 4:25 AM

CRL: 4203206d8432188dae986ab21d319375d9f24823

Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication

Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication

CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 11:45 AM

NotAfter: 2/20/2029 11:55 AM

Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

Serial: 61000000022fcc148140855cf0000000000002

Template: SubCA

Cert: f8b246170aababcdb629e1a65cfda395d78c4746

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0

[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint

Expired "Base CRL (03)" Time: 0

[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>

Expired "Base CRL (03)" Time: 0

[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:

Issuer: CN=MCRCA

ThisUpdate: 2/1/2023 2:42 PM

NextUpdate: 2/22/2024 3:02 AM

CRL: 95bd64510f142a48195b6b8d7053066ec1617bed

CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0

Issuer: CN=MCRCA

NotBefore: 2/20/2019 10:15 AM

NotAfter: 2/20/2039 10:25 AM

Subject: CN=MCRCA

Serial: 46ec1044f89f81aa401aad4340a7767f

Cert: 15681660643728508078bac9a48d95b9778d42d1

Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)

Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:

Chain: b7e55f737dece5fbe5eb89297d7d723b417c204f

Full chain:

Chain: e3f847c9a0c65cca23edd248b66fbc377bce7783

------------------------------------

Verified Issuance Policies: None

Verified Application Policies:

1.3.6.1.5.5.7.3.2 Client Authentication

1.3.6.1.5.5.7.3.1 Server Authentication

Leaf certificate revocation check passed

CertUtil: -verify command completed successfully.

Issuer:

CN=MCICA01

DC=MATC

DC=Madison

DC=Login

[0,0]: CERT_RDN_IA5_STRING, Length = 5 (5/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Login"

4c 6f 67 69 6e Login

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

[1,0]: CERT_RDN_IA5_STRING, Length = 7 (7/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="Madison"

4d 61 64 69 73 6f 6e Madison

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 M.a.d.i.s.o.n.

[2,0]: CERT_RDN_IA5_STRING, Length = 4 (4/128 Characters)

0.9.2342.19200300.100.1.25 Domain Component (DC)="MATC"

4d 41 54 43 MATC

4d 00 41 00 54 00 43 00 M.A.T.C.

[3,0]: CERT_RDN_PRINTABLE_STRING, Length = 7 (7/64 Characters)

2.5.4.3 Common Name (CN)="MCICA01"

4d 43 49 43 41 30 31 MCICA01

4d 00 43 00 49 00 43 00 41 00 30 00 31 00 M.C.I.C.A.0.1.

Name Hash(sha1): 7672a36cabec49156ffbbe39748e56cb1cd8f574

Name Hash(md5): 905ec15fa540c03f65215bf444aceadc

Subject:

CN=IDMDCPRD05.MATC.Madison.Login

[0,0]: CERT_RDN_PRINTABLE_STRING, Length = 29 (29/64 Characters)

2.5.4.3 Common Name (CN)="IDMDCPRD05.MATC.Madison.Login"

49 44 4d 44 43 50 52 44 30 35 2e 4d 41 54 43 2e IDMDCPRD05.MATC.

4d 61 64 69 73 6f 6e 2e 4c 6f 67 69 6e Madison.Login

49 00 44 00 4d 00 44 00 43 00 50 00 52 00 44 00 I.D.M.D.C.P.R.D.

30 00 35 00 2e 00 4d 00 41 00 54 00 43 00 2e 00 0.5...M.A.T.C...

4d 00 61 00 64 00 69 00 73 00 6f 00 6e 00 2e 00 M.a.d.i.s.o.n...

4c 00 6f 00 67 00 69 00 6e 00 L.o.g.i.n.

Name Hash(sha1): 2c0ea41f62ac2c31b54460a27c8c288379be22db

Name Hash(md5): 11ac3051bd85043a2bef847fdaaf258d

Cert Serial Number: 1d0001d8ee8b21ecc717b0446500000001d8ee

0000 ee d8 01 00 00 00 65 44 b0 17 c7 ec 21 8b ee d8

0010 01 00 1d

dwFlags = CA_VERIFY_FLAGS_CONSOLE_TRACE (0x20000000)

dwFlags = CA_VERIFY_FLAGS_DUMP_CHAIN (0x40000000)

ChainFlags = CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT (0x40000000)

HCCE_LOCAL_MACHINE

CERT_CHAIN_POLICY_BASE

-------- CERT_CHAIN_CONTEXT --------

ChainContext.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

ChainContext.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 38 Seconds

SimpleChain.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

SimpleChain.dwRevocationFreshnessTime: 218 Days, 21 Hours, 47 Minutes, 38 Seconds

CertContext[0][0]: dwInfoStatus=102 dwErrorStatus=0

Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login

NotBefore: 11/27/2022 5:37 AM

NotAfter: 11/27/2023 5:37 AM

Subject: CN=IDMDCPRD05.MATC.Madison.Login

Serial: 1d0001d8ee8b21ecc717b0446500000001d8ee

SubjectAltName: Other Name:DS Object Guid=04 10 de fb e1 6c 12 75 12 4d 85 ae 6e 84 94 3d 50 7a, DNS Name=IDMDCPRD05.MATC.Madison.Login

Template: DomainController

Cert: 3a532f19113ca84ec7fb925ce086057b29dea022

Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)

Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0

[0.0] ldap:///CN=MCICA01,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority

Verified "Certificate (0)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

Verified "Certificate (0)" Time: 0

[2.0] <http://cert02.matc.madison.login/Certs/CAPRD02.MATC.Madison.Login_MCICA01.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (067e)" Time: 0
[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint
Verified "Delta CRL (067e)" Time: 0

[0.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint
Verified "Delta CRL (067e)" Time: 0

[0.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>
Verified "Delta CRL (067e)" Time: 0

[0.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>
Verified "Base CRL (067e)" Time: 0

[1.0] <http://cert01.matc.madison.login/Certs/MCICA01.crl>
Verified "Delta CRL (067e)" Time: 0

[1.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0
[1.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0
[1.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

Verified "Base CRL (067e)" Time: 0
[2.0] <http://cert02.matc.madison.login/Certs/MCICA01.crl>

Verified "Delta CRL (067e)" Time: 0

[2.0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint

Verified "Delta CRL (067e)" Time: 0
[2.0.1] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>

Verified "Delta CRL (067e)" Time: 0
[2.0.2] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Base CRL CDP ----------------

OK "Delta CRL (0680)" Time: 0
[0.0] ldap:///CN=MCICA01,CN=CAPRD02,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?deltaRevocationList?base?objectClass=cRLDistributionPoint
OK "Delta CRL (0680)" Time: 0
[1.0] <http://cert01.matc.madison.login/Certs/MCICA01+.crl>
OK "Delta CRL (0680)" Time: 0
[2.0] <http://cert02.matc.madison.login/Certs/MCICA01+.crl>

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 067e:
Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
ThisUpdate: 9/5/2023 4:05 PM
NextUpdate: 9/13/2023 4:25 AM
CRL: 148ac780f70a135d6ee29fb97e687b84e3ccafc3
Delta CRL 0680:
Issuer: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
ThisUpdate: 9/7/2023 4:05 PM
NextUpdate: 9/9/2023 4:25 AM
CRL: 4203206d8432188dae986ab21d319375d9f24823
Application[0] = 1.3.6.1.5.5.7.3.2 Client Authentication
Application[1] = 1.3.6.1.5.5.7.3.1 Server Authentication
CertContext[0][1]: dwInfoStatus=102 dwErrorStatus=0
Issuer: CN=MCRCA
NotBefore: 2/20/2019 11:45 AM
NotAfter: 2/20/2029 11:55 AM
Subject: CN=MCICA01, DC=MATC, DC=Madison, DC=Login
Serial: 61000000022fcc148140855cf0000000000002
Template: SubCA
Cert: f8b246170aababcdb629e1a65cfda395d78c4746
Element.dwInfoStatus = CERT_TRUST_HAS_KEY_MATCH_ISSUER (0x2)
Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

Verified "Certificate (0)" Time: 0
[0.0] ldap:///CN=MCRCA,CN=AIA,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?cACertificate?base?objectClass=certificationAuthority
Verified "Certificate (0)" Time: 0
[1.0] <http://Cert01.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>
Verified "Certificate (0)" Time: 0
[2.0] <http://Cert02.MATC.Madison.Login/Certs/CAPRD01_MCRCA.crt>

---------------- Certificate CDP ----------------

Verified "Base CRL (0c)" Time: 0
[0.0] ldap:///CN=MCRCA,CN=CAPRD01,CN=CDP,CN=Public%20Key%20Services,CN=Services,CN=Configuration,DC=Madison,DC=Login?certificateRevocationList?base?objectClass=cRLDistributionPoint
Expired "Base CRL (03)" Time: 0
[1.0] <http://Cert01.MATC.Madison.Login/Certs/MCRCA.crl>
Expired "Base CRL (03)" Time: 0
[2.0] <http://Cert02.MATC.Madison.Login/Certs/MCRCA.crl>

---------------- Base CRL CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

CRL 0c:
Issuer: CN=MCRCA
ThisUpdate: 2/1/2023 2:42 PM
NextUpdate: 2/22/2024 3:02 AM
CRL: 95bd64510f142a48195b6b8d7053066ec1617bed
CertContext[0][2]: dwInfoStatus=10c dwErrorStatus=0
Issuer: CN=MCRCA
NotBefore: 2/20/2019 10:15 AM
NotAfter: 2/20/2039 10:25 AM
Subject: CN=MCRCA
Serial: 46ec1044f89f81aa401aad4340a7767f
Cert: 15681660643728508078bac9a48d95b9778d42d1
Element.dwInfoStatus = CERT_TRUST_HAS_NAME_MATCH_ISSUER (0x4)
Element.dwInfoStatus = CERT_TRUST_IS_SELF_SIGNED (0x8)
Element.dwInfoStatus = CERT_TRUST_HAS_PREFERRED_ISSUER (0x100)

---------------- Certificate AIA ----------------

No URLs "None" Time: 0

---------------- Certificate CDP ----------------

No URLs "None" Time: 0

---------------- Certificate OCSP ----------------

No URLs "None" Time: 0

--------------------------------

Exclude leaf cert:
Chain: ff271dee5771bf249cac826a7f417f35f3345178
Full chain:
Chain: 145ded082019de1d35fb16c7048659978b508cc9

------------------------------------

Verified Issuance Policies: None
Verified Application Policies:
1.3.6.1.5.5.7.3.2 Client Authenticatio
1.3.6.1.5.5.7.3.1 Server Authentication
Leaf certificate revocation check passed
CertUtil: -verify command completed successfully.
```

## References

[How to test the CA certificate and LDAP connection over SSL/TLS (ibm.com)](https://www.ibm.com/support/pages/how-test-ca-certificate-and-ldap-connection-over-ssltls)
