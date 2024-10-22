# Exchange

Table of Contents

- [Search Mailbox Audit Logs](#search-mailbox-audit-logs)
- [Restore Recoverable Mail Items](#restore-recoverable-mail-items)

## Search Mailbox Audit Logs

- Make sure that mailbox auditing is enabled.
- Make sure that you have sufficient rights (PIM roles activated if necessary).
- ExchangeOnlineManagement module installed.
- Session to Exchange Online.

```powershell
get-mailbox diningservices | select audit*
```

Output:

```text
AuditEnabled     : True
AuditLogAgeLimit : 90.00:00:00
AuditAdmin       : {Update, MoveToDeletedItems, SoftDelete, HardDelete…}
AuditDelegate    : {Update, MoveToDeletedItems, SoftDelete, HardDelete…}
AuditOwner       : {Update, MoveToDeletedItems, SoftDelete, HardDelete…}
```

Execute the following PowerShell to get the audit logs. Adjust the dates as needed.

```powershell
$Mailbox = "<Mailbox Name>"
$start = (Get-Date).AddDays(-90); $end = (Get-Date); $auditData = New-Object System.Collections.ArrayList;

$Params = @{
    Identity = $Mailbox
    StartDate = $Start
    EndDate = $End
    LogonTypes = "Owner", "Admin", "Delegate"
    ResultSize = 50000
}

search-mailboxAuditLog @Params -ShowDetails -OutVariable +auditdata | out-null
```

## Restore Recoverable Mail Items

Get a list of the recoverable items

```powershell
Get-RecoverableItems $Mailbox -ResultSize unlimited
```

Restore all recoverable items

```powershell
(Get-RecoverableItems $Mailbox -ResultSize unlimited) | Restore-RecoverableItems
```

Restore recoverable items that have been deleted from the Inbox folder.

```powershell
(Get-RecoverableItems $Mailbox -ResultSize unlimited) | ? {$_.lastparentpath -eq "Inbox"} | Restore-RecoverableItems
```
