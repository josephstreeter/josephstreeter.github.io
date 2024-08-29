# Firewall and Network Information

Created: 2015-03-20 09:30:41 -0500

Modified: 2015-03-20 09:31:51 -0500

---

**Keywords:** campus active directory ad microsoft ad.wisc.edu adtest.wisc.edu firewall port rule rules exception ip address hostname

**Summary:** Firewalls should be configured to allow traffic to and from the Campus Active Directory domain controllers. Body:

**Domain Controller Information**

The Campus Active directory has two domains: ad.wisc.edu and adtest.wisc.edu. Each domain has three domain controllers. The domain controller IP addresses for each domain are:

<table>
<colgroup>
<col style="width: 27%" />
<col style="width: 44%" />
<col style="width: 28%" />
</colgroup>
<thead>
<tr>
<th style="text-align: right;"><strong>ad.wisc.edu</strong></th>
<th></th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: right;"><p></p>
<p></p>
<p><strong></strong></p></td>
<td>CADSDC-CSSC-01.ad.wisc.edu</td>
<td>144.92.104.16</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>CADSDC-CSSC-02.ad.wisc.edu</td>
<td>144.92.104.17</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>CADSDC-CSSC-03.ad.wisc.edu</td>
<td>144.92.104.18</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>CADSDC-WARF-01.ad.wisc.edu</td>
<td>144.92.104.62</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>CADSDC-WARF-02.ad.wisc.edu</td>
<td>144.92.104.63</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>CADSDC-WARF-03.ad.wisc.edu</td>
<td>144.92.104.69</td>
</tr>
<tr>
<td style="text-align: right;"></td>
<td></td>
<td></td>
</tr>
<tr>
<td style="text-align: right;"><strong>adtest.wisc.edu</strong></td>
<td>TNADS1.adtest.wisc.edu</td>
<td>144.92.104.51</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>TNADS2.adtest.wisc.edu</td>
<td>144.92.104.67</td>
</tr>
<tr>
<td style="text-align: right;"><strong></strong></td>
<td>TNADS3.adtest.wisc.edu</td>
<td>144.92.104.69</td>
</tr>
</tbody>
</table>

**Common Ports Used by Active Directory**

Active Directory makes use of several ports, so it is easier to allow all traffic from the domain controllers, which should not pose a significant security risk (especially considering that the service can only be accessed via the campus network). However, if you want to restrict communication to specific ports, here is a list of commonly used ports in Active Directory:

| **Service Name**                         | **Ports**        |
|------------------------------------------|------------------|
| RPC endpoint mapper                      | 135/TCP, 135/UDP |
| RPC dynamic assignment                   | 1024-65535/TCP   |
| IKE, Internet Key Exchange               | 500/UDP          |
| IPSec over TCP                           | 4500/TCP         |
| IPSec ESP, Encapsulated Security Payload | IP protocol 50   |
| SMB over IP (Microsoft-DS)               | 445/TCP, 445/UDP |
| LDAP                                     | 389/TCP          |
| LDAP over SSL                            | 636/TCP          |
| Global catalog LDAP over SSL             | 3269/TCP         |
| Kerberos                                 | 88/TCP, 88/UDP   |
| Kpassd                                   | 464/TCP, 464/UDP |
| Domain Name Service (DNS)                | 53/TCP, 53/UDP   |
| AD Web Service                           | 9389/TCP         |

**Network Connectivity**

The Campus Active Directory service can only be accessed within the campus network or the [WiscVPN](http://www.doit.wisc.edu/network/vpn/) service. Exceptions to this rule cannot be made.
