﻿---
title:  Installing the Web Service for Active Directory PowerShell Modules
date:   2012-10-19 00:00:00 -0500
categories: IT
---

If you install RSAT in Windows 7 the Active Directory PowerShell modules are available for use. However, you may get an error like **WARNING: Error initializing default drive: 'Unable to find a default server with Active Directory Web Services running.'.**

In order to use the AD PowerShell modules you will have to install the Active Directory Web Services (Windows Server 2008 R2 Domain Controllers) or the Active Directory Management Gateway Service (Windows Server 2008 SP2, Windows Server 2003, Windows Server 2003 R2).

[Mike Pfeiffer's Blog]("http://www.mikepfeiffer.net") has instructions on how to make this happen:
[How to Install the Active Directory Module for Windows PowerShell]("http://www.mikepfeiffer.net/2010/01/how-to-install-the-active-directory-module-for-windows-powershell/")
