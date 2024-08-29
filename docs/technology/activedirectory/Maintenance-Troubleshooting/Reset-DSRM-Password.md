# Reset DSRM Password

The Directory Service Restore Mode password is set on each Domain Controller during the dcpromo process and is not replicated. If a DSRM password for a domain controller is not known, it could be reset using the following procedure. Body:

In WS 2003 and later the Domain Controller does not have to be booted into Restore Mode to change the DSRM password when using the ntdsutil command. This allows you to run the command against remote Domain Controllers as well.

```console
> ntdsutil
> set dsrm password
> reset password on server null
> <Enter New DSRM Password>
> <Confirm New DSRM Password>
> q
> q
```
