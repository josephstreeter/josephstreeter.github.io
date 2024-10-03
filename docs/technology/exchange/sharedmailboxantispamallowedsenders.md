# Add Shared Mailboxes to Anti-Spam Allowed Senders List

## Introduction

If a relaxed inbound Anti-Spam policy is required for Shared Mailboxes, they can be added to the Allowed Senders list on the Default policy.

## Process description

The process consists of a PowerShell script that will identify all Shared Mailboxes and add them to the Allowed Senders list for the default Anti-Spam policy. On subsequent runs, the script will add only those mailboxes that are not already in the list.

## Prerequisites

- PowerShell
- The ExchangeOnlineManagement PowerShell module
- Administrative acccess to Microsoft Exchange Online
- Administrative access to the Anti-Spam policy

## Gathering materials/resources

[Provide instructions on gathering the necessary materials, resources, or information needed for the process.]

## Step-by-step instructions

[Offer detailed, step-by-step instructions for executing each stage of the process.]

1. [Insert step]

2. [Insert step]
etc.

```powershell
[cmdletbinding()]
param()

function Add-AntispamAllowedSenders()
{
    <#
    .SYNOPSIS
        Adds all shared mailboxes in the organization to the Allowed Senders list for the default spam policy.
    .DESCRIPTION
        Adds all shared mailboxes in the organization to the Allowed Senders list for the default spam policy 
        to allow them to bypass the daily recipient limit.
    .NOTES
        This script requires an active session with Exchange Online to work.
    .LINK
        None
    .EXAMPLE
        Add-AntispamAllowedSenders
        Returns all shared mailboxes in the organization.
    #>
    
    [CmdletBinding()]
    param ()
    
    try
    {
        Write-Information -Message "Retrieving shared mailboxes in the organization." -InformationAction Continue
        $SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -erroraction Stop

        if ($SharedMailboxes.Count -eq 0)
        {
            Write-Warning "No shared mailboxes found in the organization." -WarningAction Continue
            return $null
        }

        Write-Information -Message "Retrieved $($SharedMailboxes.Count) shared mailboxes returned." -Verbose
    }
    catch
    {
        Write-Error -Message "Failed to retrieve Shared Mailboxes: $($_.Exception.Message)"
        Return $null    
    }

    try
    {
        Write-Information -Message "Retrieving default Anti-Spam Policy." -InformationAction Continue
        $SpamPolicy = Get-HostedContentFilterPolicy -Identity Default -ErrorAction Stop
        $AllowedSenders = $SpamPolicy.AllowedSenders | ForEach-Object {$_.sender.address}
    }
    catch
    {
        Write-Error -Message "Failed to return default Anti-Spam Policy: $($_.Exception.Message)"
        Return $null
    }
    
    try
    {
        Write-Information -Message "Adding shared mailboxes to the Allowed Senders list for the default spam policy." -InformationAction Continue
        $NewAllowedSenders=@()
        ForEach ($mailbox in $SharedMailboxes)
        {
            if ($AllowedSenders -notcontains $Mailbox.PrimarySmtpAddress)
            {
                $NewAllowedSenders += $Mailbox.PrimarySmtpAddress
            }
            else
            {
                Write-Information "The shared mailbox $($Mailbox.PrimarySmtpAddress) is already in the Allowed Senders list for the default spam policy."
            }
        }

        if ($NewAllowedSenders.Count -eq 0)
        {
            Write-Information "No shared mailboxes added to the Allowed Senders list for the default spam policy." -InformationAction Continue
            return $null
        }

        Write-Information -Message "Adding $($NewAllowedSenders.Count) shared mailboxes to the Allowed Senders list for the default spam policy." -InformationAction Continue

        Set-HostedContentFilterPolicy -Identity Default -AllowedSenders @{Add=$NewAllowedSenders} -ErrorAction Stop
        Write-Information -Message "Shared mailboxes added to the Allowed Senders list for the default Anti-Spam policy."
    }
    catch
    {
        Write-Error -Message "Failed to add shared mailboxes to the Allowed Senders list for the default spam policy: $($_.Exception.Message)"
        Return $null
    }
}

. Add-AntispamAllowedSenders
```

## Tips and best practices

[Include any tips, tricks, or best practices that may aid in completing the process efficiently and effectively.]

## Next steps

[Offer guidance on what to do after completing the process, including any follow-up actions or additional resources.]

## Additional information

[Include any supplementary information relevant to the process, such as related documents, templates, or references.]

## Disclaimer

[Include a disclaimer stating any limitations or liabilities associated with following the process guide template, and advise users to use their discretion and seek professional advice if needed.]
