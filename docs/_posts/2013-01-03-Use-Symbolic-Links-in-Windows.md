---

title:  Use Symbolic Links in Windows
date:   2013-01-03 00:00:00 -0500
categories: IT
---

On my workstations and servers I like to create a "scripts" folder in the root of the "C:" drive to store all of my production and test scripts. At the same time, I would like to keep all of those same scripts in my Drop Box folder so that I can access them at work, home, on the road, etc. While I could just move them into the Drop Box folder in my profile, the whole reason I create the "scripts" folder where I do is that it gives me a short path to type.

Well, this is where symbolic links come in. You can create them in Windows (Vista and later...I think) just like you can in UNIX, Linux, or Mac/BSD. As a reference, you can read over this page from "How-to-Geek":- <span style="text-decoration: underline;"><a title="Using Symlinks in Windows Vista" href="http://www.howtogeek.com/howto/windows-vista/using-symlinks-in-windows-vista/" rel="bookmark">Using Symlinks in Windows Vista</a></span>

Here is the "MKLINK" command:
```powershellMKLINK [[/D] | [/H] | [/J]] Link Target
/D -  Creates a directory symbolic link. Default is a file- symbolic link.
/H -  Creates a hard link instead of a symbolic link.
/J -  Creates a Directory Junction.
Link -  specifies the new symbolic link name.
Target -  specifies the path (relative or absolute) that the new link- refers to.
```

This is the complete command that I used to link the "C:\Scripts" folder to the "Scripts" folder in my Drop Box synchronized folder: