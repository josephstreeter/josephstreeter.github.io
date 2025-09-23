---
title: SSH Port Forwarding and Tunneling - Comprehensive Guide
description: A complete guide to SSH port forwarding techniques, including local, remote, and dynamic forwarding for secure network tunneling
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

SSH port forwarding (also known as SSH tunneling) is a powerful mechanism that creates encrypted connections between a local computer and a remote machine through which services can be relayed. This technique allows you to secure otherwise insecure protocols, bypass firewalls, and access restricted network services.

## Understanding SSH Port Forwarding

SSH port forwarding works by encapsulating traffic from a specified port within the SSH protocol's encrypted connection. This provides several benefits:

- **Security**: Encrypts unencrypted protocols
- **Access Control**: Bypasses network restrictions
- **Privacy**: Hides the actual traffic from network monitoring
- **Simplicity**: Requires no additional software beyond SSH

There are three primary types of SSH port forwarding:

1. **Local Forwarding**: Forwards a local port to a remote destination
2. **Remote Forwarding**: Forwards a remote port to a local destination
3. **Dynamic Forwarding**: Creates a SOCKS proxy for dynamic application-level forwarding

## Local Port Forwarding

Local forwarding connects a port on your local machine to a port on a remote server. Any traffic sent to the local port is forwarded through the SSH connection to the specified remote host and port.

### Use Cases for Local Forwarding

- Access services on a private network through a jump server
- Secure unencrypted protocols like HTTP, SMTP, or database connections
- Bypass network restrictions or firewalls
- Connect to internal services from outside the network
- Access geo-restricted content

### Local Forwarding Syntax

```bash
ssh -L [bind_address:]local_port:destination_host:destination_port ssh_server
```

Where:

- `bind_address`: Optional. Specifies which interface to bind to (default: localhost)
- `local_port`: The port on your local machine to forward
- `destination_host`: The target host to receive the traffic (from the perspective of the SSH server)
- `destination_port`: The port on the destination host
- `ssh_server`: The SSH server that will tunnel the connection

### Local Forwarding Examples

#### Basic Local Forwarding

Forward local port 8080 to a remote web server:

```bash
ssh -L 8080:internal-web.example.com:80 jumphost.example.com
```

This command:

1. Establishes an SSH connection to `jumphost.example.com`
2. Creates a listener on your local machine at port 8080
3. Forwards traffic from your local port 8080 to `internal-web.example.com:80` via the jump host

You can then access the remote web server by browsing to `http://localhost:8080` on your local machine.

#### Restricting Access to Forwarded Ports

By default, forwarded ports are bound to all interfaces (`0.0.0.0`), allowing other machines to connect to the forwarded port. To restrict access to the local machine only:

```bash
ssh -L 127.0.0.1:8080:internal-web.example.com:80 jumphost.example.com
```

#### Forwarding Multiple Ports

You can forward multiple ports in a single SSH command:

```bash
ssh -L 8080:internal-web.example.com:80 -L 3306:db.example.com:3306 jumphost.example.com
```

This forwards both web and database traffic through the same SSH connection.

## Remote Port Forwarding

Remote forwarding is the reverse of local forwarding. It connects a port on the remote SSH server to a service on your local machine or another host accessible from your local machine.

### Use Cases for Remote Forwarding

- Provide external access to services running on your local machine
- Allow access to your development environment from outside
- Share a local web server temporarily with others
- Create a backdoor access to internal networks (security testing)
- Remote support scenarios

### Remote Forwarding Syntax

```bash
ssh -R [bind_address:]remote_port:destination_host:destination_port ssh_server
```

Where:

- `bind_address`: Optional. Interface on the remote server to bind to
- `remote_port`: The port on the remote SSH server to forward
- `destination_host`: The target host to receive the traffic (from your local machine's perspective)
- `destination_port`: The port on the destination host
- `ssh_server`: The SSH server that will tunnel the connection

### Remote Forwarding Examples

#### Basic Remote Forwarding

Share a local web server with someone who has access to the remote server:

```bash
ssh -R 8080:localhost:3000 remote.example.com
```

This command:

1. Establishes an SSH connection to `remote.example.com`
2. Creates a listener on the remote server at port 8080
3. Forwards traffic from the remote port 8080 to your local machine's port 3000

Someone with access to the remote server can now access your local web server by browsing to `http://localhost:8080` on the remote machine.

#### Making Remote Forwarded Ports Publicly Accessible

By default, SSH servers only allow connections to remote forwarded ports from the server itself (`localhost`). To make the forwarded port accessible from other hosts, you need to:

1. Set `GatewayPorts` in the SSH server's configuration file (`/etc/ssh/sshd_config`):

    ```text
    GatewayPorts yes
    ```

2. Then restart the SSH service:

    ```bash
    sudo systemctl restart sshd
    ```

3. Now you can bind to all interfaces on the remote server:

    ```bash
    ssh -R 0.0.0.0:8080:localhost:3000 remote.example.com
    ```

#### Using Client-Specified Binding

If the SSH server has `GatewayPorts clientspecified`, you can specify which external interfaces/addresses can connect:

```bash
ssh -R 192.168.1.10:8080:localhost:3000 remote.example.com
```

This restricts the forwarded port to be accessible only via the specified IP address.

#### Dynamic Port Allocation

If you don't know which port is available on the remote server, you can let SSH dynamically allocate one:

```bash
ssh -R 0:localhost:3000 remote.example.com
```

To see which port was allocated:

```bash
ssh -O forward -R 0:localhost:3000 remote.example.com
```

## Dynamic Port Forwarding (SOCKS Proxy)

Dynamic forwarding creates a SOCKS proxy server that allows dynamic routing of traffic through the SSH connection. This is useful for applications that support SOCKS proxying, such as web browsers.

### Use Cases for Dynamic Forwarding

- Secure browsing on untrusted networks
- Bypass network restrictions and censorship
- Access multiple services through a single tunnel
- Test applications through different geographic locations
- Browse the web through a different IP address

### Dynamic Forwarding Syntax

```bash
ssh -D [bind_address:]port ssh_server
```

Where:

- `bind_address`: Optional. Interface to bind to (default: localhost)
- `port`: The local port to use for the SOCKS proxy
- `ssh_server`: The SSH server that will tunnel the connection

### Dynamic Forwarding Examples

#### Basic Dynamic Forwarding

Create a SOCKS proxy on local port 1080:

```bash
ssh -D 1080 remote.example.com
```

This creates a SOCKS proxy running on your local machine at port 1080. You can configure applications like web browsers to use this proxy:

- Proxy type: SOCKS5
- Proxy server: 127.0.0.1
- Port: 1080

#### Binding to a Specific Interface

```bash
ssh -D 192.168.1.100:1080 remote.example.com
```

This makes the SOCKS proxy available to other machines on your local network.

## Advanced SSH Forwarding Techniques

### Persistent Forwarding with Control Master

You can establish a persistent connection that can be reused for multiple forwarding sessions:

```bash
# Create the control master connection
ssh -M -S ~/.ssh/control-master-%r@%h:%p -fN user@example.com

# Add a new forwarding to the existing connection
ssh -S ~/.ssh/control-master-%r@%h:%p -O forward -L 8080:internal.example.com:80 user@example.com

# Close the connection when done
ssh -S ~/.ssh/control-master-%r@%h:%p -O exit user@example.com
```

### Jump Hosts for Multi-Hop Forwarding

Access services behind multiple SSH servers:

```bash
ssh -L 8080:final-destination.example.com:80 -J jumphost1.example.com,jumphost2.example.com user@jumphost3.example.com
```

### X11 Forwarding

Forward X Window System applications:

```bash
ssh -X user@remote.example.com
```

Then run GUI applications on the remote server, and they'll display on your local machine.

## Port Forwarding in SSH Config File

You can configure persistent port forwarding in your SSH config file (`~/.ssh/config`):

```text
Host jumphost
    HostName jumphost.example.com
    User admin
    LocalForward 8080 internal-web.example.com:80
    LocalForward 3306 db.example.com:3306
    
Host development
    HostName dev.example.com
    User developer
    RemoteForward 8080 localhost:3000
    DynamicForward 1080
```

With this configuration, the port forwarding is automatically set up every time you connect with `ssh jumphost` or `ssh development`.

## Security Considerations

### Potential Risks

- **Unintended Access**: Forwarded ports might allow unauthorized access to services
- **Bypassing Security Controls**: Port forwarding can circumvent firewalls and network policies
- **Data Exposure**: Misconfigured forwarding could expose sensitive services
- **Credential Theft**: Attackers might exploit forwarded connections to steal credentials

### Security Best Practices

1. **Bind to Localhost**: Whenever possible, bind forwarded ports to localhost to prevent external access

2. **Use Specific Source IP Restrictions**: When binding to external interfaces, restrict access to specific IP addresses

3. **Enable SSH Server Restrictions**: Configure `GatewayPorts` appropriately in the SSH server config

4. **Use Temporary Forwarding**: Use the `-N` flag to establish forwarding without executing a remote command, and close the connection when not in use

   ```bash
   ssh -N -L 8080:internal.example.com:80 jumphost.example.com
   ```

5. **Implement Idle Timeout**: Set `ServerAliveInterval` and `ServerAliveCountMax` to automatically close idle connections

   ```text
   Host *
       ServerAliveInterval 300
       ServerAliveCountMax 2
   ```

6. **Use Key-Based Authentication**: Always use SSH keys instead of passwords for forwarded connections

7. **Audit Port Forwarding Usage**: Regularly review who is using port forwarding and for what purpose

## Troubleshooting SSH Forwarding

### Common Issues and Solutions

#### Connection Refused

```text
channel 2: open failed: connect failed: Connection refused
```

**Solutions:**

- Verify the destination service is running
- Check firewall settings
- Ensure the correct host and port were specified

#### Permission Denied

```text
bind: Permission denied
```

**Solutions:**

- Use a port number above 1024 (non-privileged ports) or run with sudo
- Verify you have permissions to bind to the specified interface

#### Address Already in Use

```text
bind: Address already in use
```

**Solutions:**

- Choose a different local port that isn't already in use
- Find and stop the process using the desired port (`lsof -i :port`)

#### Remote Port Forwarding Not Working

**Solutions:**

- Check `GatewayPorts` setting in `/etc/ssh/sshd_config`
- Verify the SSH server allows remote forwarding (`AllowTcpForwarding`)
- Check for firewall rules blocking the forwarded port

## Real-World Examples

### Accessing a Remote Database

```bash
ssh -L 3306:database.internal:3306 jumphost.example.com
```

Then connect your database client to `localhost:3306`.

### Secure Web Browsing via SOCKS Proxy

```bash
ssh -D 1080 user@remote-server.com
```

Configure your browser to use SOCKS proxy at `localhost:1080`.

### Remote Development Environment

```bash
ssh -R 8080:localhost:3000 -R 8081:localhost:8080 dev.example.com
```

This forwards your local development server and debugger to the remote machine.

### Bypassing Network Restrictions

```bash
ssh -N -D 1080 user@unrestricted-server.com
```

Configure applications to use the SOCKS proxy to bypass network restrictions.

## Further Reading

- [OpenSSH Manual: ssh(1)](https://man.openbsd.org/ssh.1#L)
- [OpenSSH Manual: ssh_config(5)](https://man.openbsd.org/ssh_config.5#LocalForward)
- [OpenSSH Manual: sshd_config(5)](https://man.openbsd.org/sshd_config.5#GatewayPorts)
