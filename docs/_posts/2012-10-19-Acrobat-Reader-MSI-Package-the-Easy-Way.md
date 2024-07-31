---

title:  Acrobat Reader MSI Package the Easy Way
date:   2012-10-19 00:00:00 -0500
categories: IT
---

It's nice to be able to deploy applications through Active Directory, but you need to have an MSI package. There are a lot of applications that cause you to take a couple extra steps to pull the MSI package out of the .exe that they give you.

The site <a href="www.appdeploy.com">AppDeploy</a> has a pretty good knowledge base for deploying many common applications through a variety of methods. Usually it's a case of running the installer and then grabbing the MSI package and any MST files out of the temp cache. Some work and some don't.

Fortunatly Adobe makes it easier for your Acrobat Reader deployments. Just go to their FTP site(ftp://ftp.adobe.com/pub/adobe/) and download the MSI. You can get the updates there as well. Just slipstream the updates with the MSI to update it. Then create a new software deployment policy to send it out to your clients.

Too easy.

Get the Flash Player MSI <a href="http://www.adobe.com/go/full_flashplayer_win_msi">here</a>.
<a href="http://www.adobe.com/products/flashplayer/fp_distribution3.html">Download AdobeÂ® FlashÂ® Player</a>
