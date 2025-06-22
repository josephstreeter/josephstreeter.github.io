# Port Forwarding

SSH can be used to create secure tunnels for access to applications and services.

## Local Forwarding

Local forwarding is used to forward a port from the client host to a remote host. The user creates a local port on the client host which listens for connections. SSH then tunnels that traffic to the remote host.

Local forwarding is used for:

- Bypassing a firewall that prevents a protocol or to bypass web content filtering
- Tunneling sessions or copying files to a remote host through a jump server or bastion host
- Remote access to an internal host or service from an external host
- Connecting to a private resource over a public network

Local port forwarding is configured using the `-L` option:

```bash
ssh -L 80:host.local-domain.com:80 host.remote-domain.com
```

This example opens a connection to the `host.remote-domain.com` bastion host and forwards all connections to port 80 on the local machine to port 80 on `host.local-domain.com` via `host.remote-domain.com`.

By default, anyone (even on different machines) can connect to the specified port on the SSH client machine. However, this can be restricted to programs on the same host by supplying a bind address:

```bash
ssh -L 127.0.0.1:80:host.local-domain.com:80 host.remote-domain.com
```

The `LocalForward` option can also be used in your SSH config file to configure forwarding without specifying it on the command line.

## Remote Forwarding

Remote forwarding is similar to local forwarding, except that it is initiated from the remote host.

Remote SSH port forwarding is specified by using the `-R` option. For example:

```bash
ssh -R 8080:localhost:80 host.domain.com
```

This example allows someone remote access to a private service, such as a web server. Remote forwarding could be performed by an employee working from home or by an attacker (sometimes called "shoveling shell") who has established persistent access to the private environment.

By default, OpenSSH only allows connecting to remote forwarded ports from the server host. However, the `GatewayPorts` option in the server configuration file (`sshd_config`) can be used to control this. The following alternatives are possible:

```text
GatewayPorts no
```

This prevents connecting to forwarded ports from outside the server computer.

```text
GatewayPorts yes
```

This allows anyone to connect to the forwarded ports. If the server is on the public Internet, anyone on the Internet can connect to the port.

```text
GatewayPorts clientspecified
```

This means that the client can specify an IP address from which connections to the port are allowed. The syntax for this is:

```bash
ssh -R 52.194.1.73:8080:localhost:80 host147.aws.example.com
```

In this example, only connections from the IP address `52.194.1.73` to port `8080` are allowed.

OpenSSH also allows the forwarded remote port to be specified as `0`. In this case, the server will dynamically allocate a port and report it to the client. When used with the `-O forward` option, the client will print the allocated port number to standard output.
