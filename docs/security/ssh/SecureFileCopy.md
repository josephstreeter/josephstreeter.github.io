# Secure File Copy - SCP

SCP uses the SSH protocol to securely copy files between systems. SCP is often included as part of the SSH client application.

## Copy a File from Local to Remote

The SCP command for copying a file from a local path to a remote host:

```bash
scp file host:path
```

For example:

```bash
scp script.sh admin@host.domain.com:/home/admin/
```

## Copy a File from Remote to Local

The SCP command for copying a file from the remote host to a local path:

```bash
scp host:file path
```

For example:

```bash
scp admin@host.domain.com:/home/admin/script.sh script.sh
```

## Notes

- SCP can also copy directories recursively using the `-r` option:

    ```bash
    scp -r myfolder admin@host.domain.com:/home/admin/
    ```

- For improved security and features, consider using SFTP (`sftp`) for file transfers.
