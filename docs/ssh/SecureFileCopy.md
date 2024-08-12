# Secure File Copy - SCP

SCP uses the SSH protocol to securly copy files between systems. SCP is often included as part of the SSH client application.

## Copy a file

The SCP command for copying a file from a local path to a remote host

```bash
scp file host:path
```

For example:

```bash
scp script.sh admin@host.domain.com:/home/admin/
```

The SCP command for copying a file from the remote host to a local path.

```bash
scp host:file path
```

For example:

```bash
scp admin@host.domain.com:/home/admin/script.sh script.sh
```
