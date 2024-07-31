---
title:  Reverse SSH Tunnel
date:   2013-04-03 00:00:00 -0500
categories: IT
---

I have a new Raspberry Pi that I want to access when it's far away and behind a firewall or NAT device. The solution will be to have it call home to my Linux VPS with a reverse SSH tunnel.

On the remote client enter the following command:

```bash
ssh -qNR 10000:localhost:22 user@home-server
```

"-qNR" - will create the reverse tunnel without and interactive session
"10000" - Will be the local port that you will use when connecting to the remote host
"localhost" - The hostname that you will use when connecting to the remote host
"22" - The port that SSHD is listening to on the server end
"user@home-server" Your user and hostname for the SSH server

Now on the server end enter the following command:

```bash
ssh -p 10000 user@localhost
```

"-p 10000" - The port that was created on the server end by the remote connection
"user@localhost" - Your user and hostname for the remote connection

If the command to connect to the reverse shell hangs and times out you might be blocking the connection with the firewall. Make sure that iptables allows the port that you're creating on the server.
