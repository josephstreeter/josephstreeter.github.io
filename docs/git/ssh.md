# SSH

In most cases SSH will have to be used to authenticate to services such as Github, GitLab, and Azure DevOps. It is possible that more than one of these services could be used and each one may require a different SSH key or a configuration that is different than the others.

Configuration files can be used to allow the setting of separate configurations without having to constantly change them when switching between services.

VS Code works best with SSH for cloning.

## Config File

The following config file will allow you to specify a specific SSH key for authenticating to Azure DevOps:

```text
Host vs-ssh.visualstudio.com
    HostName vs-ssh.visualstudio.com
    IdentityFile ~/.ssh/id_rsa_ado
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    IdentitiesOnly yes
```
