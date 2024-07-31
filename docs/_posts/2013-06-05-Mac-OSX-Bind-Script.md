---

title:  Mac OSX Bind Script
date:   2013-06-05 00:00:00 -0500
categories: IT
---






We worked for some time on getting Mac OSX hosts to bind to Active Directory in such a way that we could require LDAP digital signing. As it turns out, 10.7 and 10.8 seem to work just fine. The issue was more with getting the certificates just-  right on the Domain Controllers. It sounds as though the 10.6 hosts will have to be upgraded or replaced though.

This is a script that was used in testing. Your mileage may vary. Test, test, test.
```powershell
#! /bin/bash
# Active Directory Bind script for Mac OSX Snow Leopard/Lion/Mountain Lion
# Author: Joseph A Streeter
# Modified date: 06 FEB 2013
clear# Gather Computer and Domain User information
printf "\nEnter Computer Name: "
read computerid
printf "\nEnter Domain Name: "
read domain
printf "\nEnter Domain User: "
read domainuser
stty -echo
printf "\nEnter Domain User Password: "
read domainpwd
stty echo

# Advanced Options - User Experience
localhome="enable"
mobile="enable"
mobileconfirm="disable"
protocol="smb"
shell="/bin/bash"

# Advanced Options - Administrative
groups="Domain Admins,Enterprise Admins"
alldomains="disable"
passinterval="30"

# Review user entered information and choose to contine or abort
printf "\nComputer Name = $computerid"
printf "\nDomain Name = $domain"
printf "\nDomain User = $domainuser"

printf "\nWould you like to continue? [y/n] "
read continue
if [ $continue == "n" ]; then exit 1; fi

# Determin OS Version
case $(sw_vers -productVersion) in
10.7.[1-9])
ver="10.7"
;;
10.6.[1-9])
ver="10.6"
;;
*)
echo "Version unsupported"
exit 1
esac

if [ $ver == "10.6" ]; then

# Remove Existing Directory Services Config
printf "\nCleaning up any old Active Directory information"

if [ ! -d "/Library/Preferences/DirectoryService/ActiveDirectory" ]; then
rm -R /Library/Preferences/DirectoryService/ActiveDirectory*
fi

if [ ! -d "/Library/Preferences/DirectoryService/DSLDAPv3PlugInConfig" ]; then
rm -R /Library/Preferences/DirectoryService/DSLDAPv3PlugInConfig*
fi

if [ ! -d "/Library/Preferences/DirectoryService/SearchNode" ]; then
rm -R /Library/Preferences/DirectoryService/SearchNode*
fi

if [ ! -d "/Library/Preferences/DirectoryService/ContactsNode" ]; then
rm -R /Library/Preferences/DirectoryService/ContactsNode*
fi

if [ ! -d "/Library/Preferences/edu.mit.Kerberos" ]; then
rm -R /Library/Preferences/edu.mit.Kerberos
fi

if [ ! -d "/etc/krb5.keytab" ]; then
rm -R /etc/krb5.keytab
fi

# Clean up the DirectoryService configuration files
rm -vfR "/Library/Preferences/DirectoryService/*"
rm -vfR "/Library/Preferences/DirectoryService/.*"

# Enable Active Directory Plugin
defaults write /Library/Preferences/DirectoryService/DirectoryService "Active Directory" Active
fi

echo ""
echo "check Computer Name"
if [ $computerid == $(scutil --get ComputerName) ]; then echo "Computer Name good";else scutil --set ComputerName $computerid;fi
if [ $computerid.$domain == $(scutil --get HostName) ]; then echo "Host Name good";else scutil --set HostName $computerid.$domain;fi
if [ $computerid == $(scutil --get LocalHostName) ]; then echo "Local Host Name good";else scutil --set LocalHostName $computerid;fi
echo ""

echo "Bind computer to AD"
dsconfigad -a $computerid -domain $domain -u $domainuser -p $domainpwd -packetencrypt ssl -packetsign require
if [ $? -ne 0 ];then exit 1;fi
echo ""
echo "Configure Advanced User Experience Options"
dsconfigad -localhome $localhome -mobile $mobile -mobileconfirm $mobileconfirm -protocol $protocol -shell $shell
echo ""
echo "Configure Advanced Administrative Options"
dsconfigad -nopreferred -groups "$groups" -alldomains $alldomains -passinterval $passinterval
echo ""
echo "Configuration Complete!"
exit 0
```


