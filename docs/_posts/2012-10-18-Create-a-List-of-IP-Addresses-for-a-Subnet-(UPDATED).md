---

title:  Create a List of IP Addresses for a Subnet (**UPDATED**)
date:   2012-10-18 00:00:00 -0500
categories: IT
---

I needed a complete list of all the IP addresses for the 192.168.0.0/16 network. The list was to be used to populate a table in the network management database I was creating.

Rather than sit and type all those IP addresses out I wrote a script in VBScript to do it instead.

Here is the script:

```batch
for i = 0 to 255
for x = 0 to 255
wscript.echo "192.168." & i & "." & x
next
next
```

Change the first two octets for whatever network you need.

run the following command:

```batch
cscript ip-address.vbs > ip-address.txt
```

Make sure you don't execute the script with wscript or you'll be clicking 'ok' a lot!

---

**Update**
Here is the same script written to write the information directly to a text file in the root of C:\.

```vbscript
set fso = CreateObject("Scripting.FileSystemObject")
set ts = fso.CreateTextFile("c:\ip-address.txt", true)

for i = 0 to 255
for x = 0 to 255
ts.writeline("192.168." & i & "." & x)
next
next
```
