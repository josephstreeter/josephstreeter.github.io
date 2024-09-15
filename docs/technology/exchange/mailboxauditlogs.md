# Search Exchange Online Mailbox Audit Logs

## Introduction

Search the audit logs for a mailbox in Microsoft Exchange Online.

## Process description

User PowerShell to connect to Microsoft Exchange Online and retrieve a mailbox's audit logs.

## Prerequisites

In order to perform this task you will need:

- PowerShell
- The ExchangeOnlineManagement PowerShell module
- Administrative acccess to Microsoft Exchange Online

## Step-by-step instructions

[Offer detailed, step-by-step instructions for executing each stage of the process.]

1. Open PowerShell and connect to Exchange Online

2. Set the ```$mailbox``` variable and run the following command:

    ```powershell
    $Mailbox = "<mailbox>"
    $Start = (Get-Date).AddDays(-90); $End = (Get-Date); $AuditData = New-Object System.Collections.ArrayList;

    $Params = @{
        StartDate = $Start 
        EndDate = $End 
        LogonTypes = @("Owner", "Admin", "Delegate")
        resultsize = 50000
    }

    Search-MailboxAuditLog $Mailbox -ShowDetails @Params -OutVariable +AuditData | Out-Null
    ```

3. Check the $AuditData variable for data.

    ```powershell
    $AuditData | select LastAccessed, LogonUserDisplayName, sourceitemsubjectslist, FolderPathName, Operation, OperationResult | format-Table -AutoSize
    ```

## Tips and best practices

[Include any tips, tricks, or best practices that may aid in completing the process efficiently and effectively.]

## Next steps

[Offer guidance on what to do after completing the process, including any follow-up actions or additional resources.]

## Additional information

[Include any supplementary information relevant to the process, such as related documents, templates, or references.]

## Disclaimer

[Include a disclaimer stating any limitations or liabilities associated with following the process guide template, and advise users to use their discretion and seek professional advice if needed.]
