# Directory Services Configuration

Created: 2019-05-13 11:29:47 -0500

Modified: 2019-05-13 11:30:23 -0500

---

## Security

### Password and Lockout Policies

| Max Password Age: | 365 days |
|--------------------|----------------------------------------------------|
| Min Password Age: | 0 days |
| Min Password Length: | 10 |
| Passwords Remembered: | 4 |
| Password Complexity: | Passwords must be complex and the administrator account cannot be locked out |

### DS-Heuristics attribute

To view the DS-Heuristics value with PowerShell use the following code:

```powershell
(Get-ADObject -identity "cn=Directory Service,cn=Windows NT,cn=Services,cn=Configuration,dc=<forest_name>,dc=com" -pr dSHeuristics).dSHeuristics
```

Output:

```text
0010000
```

<http://msdn.microsoft.com/en-us/library/ms675656%28VS.85%29.aspx>

| **Position** | **Recommended Value** | **Description** |
|---------|-------------|---------------------------------------------------|
| 1 | 0 | Adjusts the behavior of Ambiguous Name Resolution (ANR) search filters. Characters 1, 2 and 4 are used for this purpose |
| 2 | 0 | Adjusts the behavior of Ambiguous Name Resolution (ANR) search filters. Characters 1, 2 and 4 are used for this purpose |
| 3 | 1 | Enforces the list object rights. If this character is '0', a user must have the ADS_RIGHT_ACTRL_DS_LIST right on the parent object to list any child objects. If the user does not have this right on the parent, none of the child objects can be listed. If this character is set to '1' then Active Directory will honor the ADS_RIGHT_ACTRL_DS_LIST right for specific child objects even if the user does not have this right on the parent. Setting this character to '1' can greatly increase the number of access check calls that are made, and can have a significant negative effect on performance. |
| 4 | 0 | Adjusts the behavior of Ambiguous Name Resolution (ANR) search filters. Characters 1, 2, and 4 are used for this purpose |
| 5 | 0 | Reserved for internal use |
| 6 | 0 | Reserved for internal use |
| 7 | 0 | Controls whether anonymous operations other than a rootDSE search will be allowed through LDAP. If this character is set to '2', anonymous clients will be able to perform any operation that is permitted by the ACL. If this character is set to any other value, anonymous clients are only allowed to perform rootDSE searches and binds. |
| 8 | 0 | Used internally |
| 9 | 1 | Controls the behavior of the[User-Password](http://msdn.microsoft.com/en-us/library/ms680851%28v=vs.85%29.aspx)attribute. In Windows2000, the[User-Password](http://msdn.microsoft.com/en-us/library/ms680851%28v=vs.85%29.aspx)attribute acted like a normal string attribute that could be read and updated normally. If this character is set to '1' then Windows Server2003 servers will treat the[User-Password](http://msdn.microsoft.com/en-us/library/ms680851%28v=vs.85%29.aspx)attribute as a real password attribute. This means that updates to the attribute will require the appropriate change-password permissions and the attribute will not be readable. In Active Directory Application Mode (ADAM), the default is to treat[User-Password](http://msdn.microsoft.com/en-us/library/ms680851%28v=vs.85%29.aspx)as a real password attribute. If this character is set to '2', the Windows Server2003 servers will revert to the Windows2000 behavior. |
| 10 | 0 | Always '1' for data validation |
| 11 | 0 | Reserved for internal use |
| 12 | 0 | Reserved for internal use |
| 13 | 0 | ADAM/AD LDS only. If this character is set to anything but '0', then password operations are allowed over a non-secure LDAP connection |

## List Object Mode

List object mode will allow for the protection of FERPA related information by applying Access Control Lists that selectively allow or prevent access to objects or attributes of objects.

## Cleanup of stale/orphaned/conflict objects

The following objects should be periodically removed from Active Directory:

- User objects that have a last logon date greater than 180 days
- Computer objects that have a last logon date greater than 180 days
- Group objects that do not have members, are not members of any other groups, and have not been modified in more than 180 days
- Organizational Unit objects that do not contain leaf objects and have not been modified in more than 180 days
- All orphaned objects
- All conflict objects
