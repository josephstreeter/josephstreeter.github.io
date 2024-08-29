# Schema Extension Script

Created: 2020-07-15 09:41:42 -0500

Modified: 2020-07-15 09:43:09 -0500

---

PowerShell script to programmatically create schema extensions

function Generate-OID()

{

$Prefix="1.2.840.113556.1.8000.2554"

$GUID=[System.Guid]::NewGuid().ToString()

$Parts=@()

$Parts+=[UInt64]::Parse($guid.SubString(0,4),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(4,4),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(9,4),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(14,4),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(19,4),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(24,6),"AllowHexSpecifier")

$Parts+=[UInt64]::Parse($guid.SubString(30,6),"AllowHexSpecifier")

$OID=[String]::Format("{0}.{1}.{2}.{3}.{4}.{5}.{6}.{7}",$prefix,$Parts[0],$Parts[1],$Parts[2],$Parts[3],$Parts[4],$Parts[5],$Parts[6])

return $oid

}

$Attribs="isRetired",

"isFaculty",

"isContingent",

"costCenter",

"employeeStartDate",

"employeeEndDate",

"jobCode",

"positionID",

"positionTime",

"contractEndDate",

"officeLocationCode",

"entitledO365"

if ($ldif){Clear-Variable LDIF}

Foreach($Attrib in $Attribs)

{

$ldif+="

dn: CN=$Attrib,cn=schema,cn=configuration,dc=x

changetype: add

objectClass: top

objectClass: attributeSchema

cn: $Attrib

distinguishedName: CN=$Attrib,cn=schema,cn=configuration,dc=x

attributeID: $(Generate-OID)

attributeSyntax: 2.5.5.12

isSingleValued: TRUE

showInAdvancedViewOnly: TRUE

adminDisplayName: $Attrib

oMSyntax: 64

lDAPDisplayName: $Attrib

name: $Attrib

objectCategory: CN=Attribute-Schema,cn=schema,cn=configuration,dc=x

"

$ldif | out-file c:schema.ldif

ldifde -i -f .schema.ldif -c "cn=schema,cn=configuration,dc=X" "cn=schema,cn=configuration,dc=madison,dc=login"
