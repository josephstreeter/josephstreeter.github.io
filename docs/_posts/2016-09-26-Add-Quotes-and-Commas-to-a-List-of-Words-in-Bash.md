---

title:  Add Quotes and Commas to a List of Words in Bash
date:   2016-09-26 00:00:00 -0500
categories: IT
---






You have a file with a list of items and you need to put them all in quotes. All but the last line needs to have a comma at the end.

Here is the list:
```powershell
$ cat testfile.txt
apple
pear
grape
orange
```

Use sed to make the change:
```powershell
sed -i 's/^/"/; $!s/$/",/; $s/$/"/' testfile.txt
```

Here is the list after:
```powershell
$ cat testfile.txt
"apple",
"pear",
"grape",
"orange"
```


