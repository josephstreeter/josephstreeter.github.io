# SSH

SSH (Secure Shell) is commonly used to authenticate with services such as GitHub, GitLab, and Azure DevOps. You may need different SSH keys or configurations for each service, especially if you use multiple accounts or organizations.

Using an SSH configuration file (`~/.ssh/config`) allows you to manage multiple keys and host settings easily, so you don't have to manually switch keys when working with different services.

VS Code works well with SSH for cloning and working with repositories.

## Generating a New SSH Key

To generate a new SSH key, use:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

*For older systems, use `-t rsa -b 4096` instead of `-t ed25519`.*

This will create a private key (e.g., `~/.ssh/id_ed25519`) and a public key (e.g., `~/.ssh/id_ed25519.pub`).

## Adding Your SSH Key to an Agent

Start the SSH agent and add your key:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

If you have multiple keys, add each one as needed:

```bash
ssh-add ~/.ssh/id_ed25519_github
ssh-add ~/.ssh/id_ed25519_gitlab
```

## Example SSH Config File

The following config file allows you to specify a specific SSH key for authenticating to different services:

```text
Host vs-ssh.visualstudio.com
    HostName vs-ssh.visualstudio.com
    IdentityFile ~/.ssh/id_rsa_ado
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    IdentitiesOnly yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes
```

**Tip:** The `IdentitiesOnly yes` option ensures that only the specified key is used for that host.

## Adding Your Public Key to Git Services

- **GitHub:** Go to Settings > SSH and GPG keys > New SSH key.
- **GitLab:** Go to Preferences > SSH Keys.
- **Azure DevOps:** Go to User Settings > SSH Public Keys.

Copy the contents of your public key file (e.g., `~/.ssh/id_ed25519.pub`) and paste it into the appropriate field.

## Testing Your SSH Connection

Test your connection with:

```bash
ssh -T git@github.com
ssh -T git@gitlab.com
ssh -T vs-ssh.visualstudio.com
```

If successful, you should see a welcome message from the service.

## Troubleshooting Tips

- Ensure your SSH agent is running and your key is added.
- Check file permissions: your private key should be readable only by you (`chmod 600 ~/.ssh/id_ed25519`).
- Use `ssh -v` for verbose output if you encounter connection issues.
- If you have multiple keys, make sure your SSH config file (`~/.ssh/config`) is set up correctly.
- If you see "Permission denied (publickey)", double-check that your public key is added to the service and that you are using the correct key.

## References

- [GitHub: Connecting to GitHub with SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitLab: SSH Keys](https://docs.gitlab.com/ee/ssh/index.md)
- [Azure DevOps: SSH Keys](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops)
