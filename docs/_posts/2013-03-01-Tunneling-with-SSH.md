---
title:  Tunneling with SSH
date:   2013-03-01 00:00:00 -0500
categories: IT
---

You're in a coffee shop and want to access your bank over public wifi or you're stuck behind a firewall/content filter that keeps you from getting to the sites you desire. In order to connect securely or get around those restrictions you can use SSH to tunnel your way out.

NOTE: Use SSH to bypass technical controls put in place for security (i.e. firewalls or content filters) at your own risk. Only do what you think your career can handle!

You will need SSH on your computer. There are SSH clients for almost any operating system in existence. You will also need a host running a SSH server. This can be a rented VPS or your home server if you know the public IP and can access it.

First we will cover basic tunneling. We will tunnel specific traffic to services located on our remote host. In the first example we will tunnel out web- traffic to our remote Squid proxy server.

```bash
ssh -L 8080:localhost:3129 proxy.server.com
```

8080 - Client port
localhost - local hostname
3129 - Remote port
In this example we will forward POP3 traffic to our remote mail server

```bash
ssh -L 8110:localhost:110 pop.server.com
```

8080 - Client port
localhost - local hostname
3129 - Remote port
You can simplify things by creating a dynamic tunnel for any application able to use SOCKS proxies. Browsers, games, etc can use this tunnel to get traffic out of whatever hole you're stuck in. If you use the example below to create the tunnel and configure your browser to use the local listener as a SOCKS proxy you do not require Squid on the remote server.

```bash
ssh -D 8080 socks.server.com
```
