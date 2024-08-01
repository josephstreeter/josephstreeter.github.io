---
title:  Javascript and CSS to Show and Hide Div
date:   2013-11-05 00:00:00 -0500
categories: IT
---

I wanted a way to show and hide div elements in a web page by clicking on other elements. Initially I wanted to do it with CSS only and avoid using javascript, but I just couldn't find an easy way to do it.

The code bellow will create a series of radio buttons that correspond to different Windows operating systems. When a radio button is clicked the "showhide()" function is called. The function will hide all the div elements and then show just the div element that was selected with the button click. If a different radio button is clicked the "showhide()" function is called again which hides all the elements and shows the new element that was selected.

```html
<html>
<head>
<script language="JavaScript" type="text/javascript">
function showhide(os) {
document.getElementById("winxp").style.display = 'none';
document.getElementById("win7").style.display = 'none';
document.getElementById("win8").style.display = 'none';
document.getElementById("mac").style.display = 'none';

if (os == "winxp") {
document.getElementById("winxp").style.display = 'block';
} else if (os == "win7") {
document.getElementById("win7").style.display = 'block';
} else if (os == "win8") {
document.getElementById("win8").style.display = 'block';
} else if (os == "mac") {
document.getElementById("mac").style.display = 'block';
} else {
document.getElementById("winxp").style.display = 'none';
document.getElementById("win7").style.display = 'none';
document.getElementById("win8").style.display = 'none';
document.getElementById("mac").style.display = 'none';
}
}
</script>

</head>
<body onload="showhide()">
<p>Select Operating System</p>
<input type="radio" id="os" value="winxp" name="os" onchange="showhide(this.value);"/>- Windows XP<br />
<input type="radio" id="os" value="win7" name="os" onchange="showhide(this.value);"/>- Windows Vista/7<br />
<input type="radio" id="os" value="win8" name="os" onchange="showhide(this.value);"/>- Windows 8<br />
<input type="radio" id="os" value="mac" name="os" onchange="showhide(this.value);"/>- Apple Mac OS X<br />
<br />

<div id="winxp">
<p>This is Windows XP</p>
</div>

<div id="win7">
<p>This is Windows 7</p>
</div>

<div id="win8">
<p>This is Windows 8</p>
</div>

<div id="mac">
<p>This is Apple Mac</p>
</div>
```
