---
layout: post
title:  PS Script to Manage Groups Based on User Attribute
date:   2012-10-19 00:00:00 -0500
categories: IT
---






We have a security group that is supposed to contain all user objects that are able to log in. Becuse we're doing a passthrough authentication to an MIT Kerberos realm the user objects that can authenticate have the "altSecurityIdentities" attribute populated. However, this could be any attribute like Description or Office.

We also have a lot of objects, somewhere north of a half million, so it takes a long time if the script tries to add everyone each time and error out on the ones that already exist. I know this because that's how I first tried it and just handled the errors.

Below is the final version of the script. It only tries to add users to the group if they belong in the group and are not already a member. I've also added the script as an attachment so that it is easier to read.

---

Import-Module ActiveDirectory
If (-not $?) { "Failed to import AD module!" ; exit }

$i = 0

$users = Get-ADUser -Filter {`
(altSecurityIdentities -like "*") -and (memberof -ne `
"CN=groupname,OU=groups,DC=domain,DC=com")} `
-Pr altSecurityIdentities, memberof `
-searchbase "ou=users,dc=domain,dc=com"

foreach ($user in $users)
{
$user.name; Add-ADGroupMember "groupname" $user.samaccountname
$i++
}

"$i users added to group"

---

To find users that are in the group that are not supposed to be you can change the filter for the Get-ADUser command to look like this:

---

-Filter {(-not(altSecurityIdentities -like "*")) -and (memberof `
-eq "CN=groupname,OU=groups,DC=domain,DC=com"

---

Then you will just have to edit the foreach loop to remove the user insted of adding it.


