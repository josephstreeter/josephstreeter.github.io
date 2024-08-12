# SSH Connect

## Authentiction

```text
The authenticity of host 'ssh.github.com (140.82.113.35)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ssh.github.com' (ED25519) to the list of known hosts.
```

## Authenticate with a Specific Key

A specific key can be specified in the SSH command.

```bash
ssh -i ~/.ssh/id_rsa_host username@host.domain.com
```

## Compare Public Key Fingerprint

If you are having trouble logging into a host or a service you can confirm that the fingerprint of your public key matches what was uploaded.

```bash
ssh-keygen -l -E md5 -f ~/.ssh/id_rsa_ado.pub
```

## Test Authentication

The following command will test authentiction to a specific host.

```bash
ssh -T git@ssh.github.com
```

In the case of source control services, you may get the following error. This is simply because the service is not intended for shell access and is completely normal.

```text
remote: Shell access is not supported.
```
