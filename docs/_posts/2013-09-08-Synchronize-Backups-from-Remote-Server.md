---
title:  Synchronize Backups from Remote Server
date:   2013-09-08 00:00:00 -0500
categories: IT
---

This line of code will copy the backups off of a remote server.

```bash
rsync -r -a -v -e "ssh -l <username>" --delete <server>:/backup /backup
```

Create a user account with an ssh key pair so that you can schedule the task as a cron job and have it run without having to enter a username and password.

http://www.cyberciti.biz/tips/linux-use-rsync-transfer-mirror-files-directories.html
