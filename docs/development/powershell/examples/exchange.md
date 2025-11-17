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

## Rename Mailbox

Renaming a shared mailbox and updating all associated attributes including aliases and proxy addresses.

```powershell
function Rename-Mailbox
{
    <#
    .SYNOPSIS
        Renames a shared mailbox and updates all associated attributes including aliases and proxy addresses.

    .DESCRIPTION
        This function renames a shared mailbox by updating all identity-related attributes including:
        - Alias, Name, DisplayName
        - PrimarySmtpAddress, WindowsEmailAddress, MicrosoftOnlineServicesID
        - All proxy addresses to match the new naming convention
        It handles both primary and secondary proxy addresses, maintains existing domain configurations,
        and provides comprehensive error handling for complete mailbox identity consistency.

    .PARAMETER Identity
        The current identity of the shared mailbox (email address or alias).

    .PARAMETER NewAlias
        The new alias for the shared mailbox.

    .PARAMETER NewDisplayName
        The new display name for the shared mailbox. If not provided, it will be generated from the NewAlias.

    .PARAMETER Domain
        The domain to use for the primary email address. If not provided, uses the existing primary domain.

    .PARAMETER UpdateAllProxyAddresses
        Switch to update all proxy addresses with the new alias while maintaining the existing domains.

    .PARAMETER WhatIf
        Shows what would happen if the function runs without actually making changes.

    .PARAMETER Confirm
        Prompts for confirmation before making changes.

    .EXAMPLE
        Rename-SharedMailbox -Identity "old-mailbox@contoso.com" -NewAlias "new-mailbox"
        Renames the shared mailbox to use "new-mailbox" as the alias.

    .EXAMPLE
        Rename-SharedMailbox -Identity "finance@contoso.com" -NewAlias "accounting" -NewDisplayName "Accounting Department" -UpdateAllProxyAddresses
        Renames the mailbox and updates all proxy addresses with the new alias.

    .NOTES
        Author: Joseph Streeter
        Requires: Exchange Online PowerShell Module (ExchangeOnlineManagement)
        Prerequisites: Must be connected to Exchange Online using Connect-ExchangeOnline
        Version: 1.1
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [string]$NewAlias,

        [Parameter(Mandatory = $false)]
        [string]$NewDisplayName,

        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateAllProxyAddresses
    )

    begin
    {
        Write-Verbose "Starting Rename-SharedMailbox function"

        # Check if Exchange Online module is available and connected
        try
        {
            # First check if the Exchange Online module commands are available
            if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue))
            {
                Write-Error "Exchange Online PowerShell module is not loaded. Please install and import the ExchangeOnlineManagement module first."
                return
            }

            # Test actual connection by trying to get connection info
            $connectionInfo = Get-ConnectionInformation -ErrorAction SilentlyContinue
            if (-not $connectionInfo -or $connectionInfo.Count -eq 0)
            {
                Write-Error "Not connected to Exchange Online. Please run 'Connect-ExchangeOnline' first."
                return
            }

            # Verify we can actually query Exchange Online
            $null = Get-OrganizationConfig -ErrorAction Stop
            Write-Verbose "Successfully verified Exchange Online connection"
        }
        catch
        {
            Write-Error "Failed to verify Exchange Online connectivity: $($_.Exception.Message). Please ensure you are connected to Exchange Online."
            return
        }
    }

    process
    {
        try
        {
            Write-Verbose "Processing mailbox: $Identity"

            # Get the current mailbox
            $currentMailbox = Get-Mailbox -Identity $Identity -ErrorAction Stop

            if ($currentMailbox.RecipientTypeDetails -ne 'SharedMailbox')
            {
                throw "The specified mailbox '$Identity' is not a shared mailbox. Current type: $($currentMailbox.RecipientTypeDetails)"
            }

            Write-Information "Found shared mailbox: $($currentMailbox.DisplayName) [$($currentMailbox.PrimarySmtpAddress)]"

            # Set default values if not provided
            if (-not $NewDisplayName)
            {
                $NewDisplayName = $NewAlias -replace '[._-]', ' ' |
                    ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_.ToLower()) }
            }

            if (-not $Domain)
            {
                $Domain = ($currentMailbox.PrimarySmtpAddress -split '@')[1]
            }

            # Build new proxy addresses
            $newPrimaryEmail = "$NewAlias@$Domain"
            $newProxyAddresses = @()

            # Add the new primary SMTP address
            $newProxyAddresses += "SMTP:$newPrimaryEmail"

            if ($UpdateAllProxyAddresses)
            {
                # Update all existing proxy addresses with new alias while preserving domains
                foreach ($proxyAddress in $currentMailbox.EmailAddresses)
                {
                    if ($proxyAddress -like 'smtp:*')
                    {
                        $addressDomain = ($proxyAddress -split '@')[1]
                        if ($addressDomain -ne $Domain)
                        {
                            $newProxyAddresses += "smtp:$NewAlias@$addressDomain"
                        }
                    }
                    elseif ($proxyAddress -notlike 'SMTP:*')
                    {
                        # Preserve non-SMTP addresses (like X400)
                        $newProxyAddresses += $proxyAddress
                    }
                }
            }
            else
            {
                # Keep existing proxy addresses except the old primary
                foreach ($proxyAddress in $currentMailbox.EmailAddresses)
                {
                    if ($proxyAddress -like 'smtp:*')
                    {
                        $newProxyAddresses += $proxyAddress
                    }
                    elseif ($proxyAddress -notlike 'SMTP:*')
                    {
                        $newProxyAddresses += $proxyAddress
                    }
                }
            }

            # Remove duplicates
            $newProxyAddresses = $newProxyAddresses | Select-Object -Unique

            # Display what will be changed
            Write-Information "Proposed changes:"
            Write-Information "  Current Alias: $($currentMailbox.Alias) -> New Alias: $NewAlias"
            Write-Information "  Current Name: $($currentMailbox.Name) -> New Name: $NewAlias"
            Write-Information "  Current Display Name: $($currentMailbox.DisplayName) -> New Display Name: $NewDisplayName"
            Write-Information "  Current Primary Email: $($currentMailbox.PrimarySmtpAddress) -> New Primary Email: $newPrimaryEmail"
            Write-Information "  Current Windows Email: $($currentMailbox.WindowsEmailAddress) -> New Windows Email: $newPrimaryEmail"
            Write-Information "  Current MicrosoftOnlineServicesID: $($currentMailbox.MicrosoftOnlineServicesID) -> New MicrosoftOnlineServicesID: $newPrimaryEmail"
            Write-Information "  New Proxy Addresses: $($newProxyAddresses -join ', ')"

            # Apply changes if not in WhatIf mode
            if ($PSCmdlet.ShouldProcess($Identity, "Rename shared mailbox to '$NewAlias'"))
            {
                # Update the mailbox properties
                $setMailboxParams = @{
                    Identity                    = $Identity
                    Alias                      = $NewAlias
                    Name                       = $NewAlias
                    DisplayName                = $NewDisplayName
                    MicrosoftOnlineServicesID  = $newPrimaryEmail
                    EmailAddresses             = $newProxyAddresses
                    ErrorAction                = 'Stop'
                }

                Set-Mailbox @setMailboxParams

                # Update the user properties (WindowsEmailAddress)
                $setUserParams = @{
                    Identity            = $NewAlias
                    WindowsEmailAddress = $newPrimaryEmail
                    ErrorAction         = 'Stop'
                }

                Set-User @setUserParams

                Write-Information "Successfully renamed shared mailbox '$Identity' to '$NewAlias'" -InformationAction Continue

                # Return the updated mailbox object
                return Get-Mailbox -Identity $NewAlias
            }
        }
        catch
        {
            $errorMessage = "Failed to rename shared mailbox '$Identity': $($_.Exception.Message)"
            Write-Error $errorMessage
            throw $_
        }
    }

    end
    {
        Write-Verbose "Completed Rename-SharedMailbox function"
    }
}

# Example usage (commented out)
<#
# Connect to Exchange Online first
# Connect-ExchangeOnline

# Example 1: Basic rename
# Rename-SharedMailbox -Identity "oldname@contoso.com" -NewAlias "newname"

# Example 2: Full rename with proxy address updates
# Rename-SharedMailbox -Identity "finance@contoso.com" -NewAlias "accounting" -NewDisplayName "Accounting Department" -UpdateAllProxyAddresses -Verbose

# Example 3: What-if scenario
# Rename-SharedMailbox -Identity "test@contoso.com" -NewAlias "testing" -WhatIf
#>
```
