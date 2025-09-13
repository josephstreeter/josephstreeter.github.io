# Microsoft Exchange

Microsoft Exchange Server is a mail server and calendaring server developed by Microsoft. This section covers Exchange on-premises, Exchange Online, and hybrid deployments.

## Exchange Server Administration

### Server Management

#### Installation and Configuration

```powershell
# Exchange Server Prerequisites Check
function Test-ExchangePrerequisites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServerName
    )
    
    $Prerequisites = @{
        'Windows Features' = @(
            'IIS-WebServerRole',
            'IIS-WebServer',
            'IIS-CommonHttpFeatures',
            'IIS-HttpErrors',
            'IIS-HttpRedirect',
            'IIS-ApplicationDevelopment',
            'IIS-NetFxExtensibility45',
            'IIS-ISAPIExtensions',
            'IIS-ISAPIFilter',
            'IIS-ASPNET45',
            'IIS-Security',
            'IIS-RequestFiltering'
        )
        'Software' = @(
            'Visual C++ Redistributable',
            '.NET Framework 4.8',
            'Unified Communications Managed API'
        )
    }
    
    Write-Host "Checking Exchange Prerequisites for $ServerName" -ForegroundColor Green
    
    # Check Windows Features
    foreach ($Feature in $Prerequisites.'Windows Features') {
        $FeatureState = Get-WindowsFeature -Name $Feature
        if ($FeatureState.InstallState -eq 'Installed') {
            Write-Host "✓ $Feature is installed" -ForegroundColor Green
        } else {
            Write-Warning "✗ $Feature is not installed"
        }
    }
}

# Exchange Health Check
function Get-ExchangeHealth {
    [CmdletBinding()]
    param(
        [string[]]$Servers = (Get-ExchangeServer | Where-Object {$_.ServerRole -match "Mailbox"}).Name
    )
    
    foreach ($Server in $Servers) {
        Write-Host "Checking Exchange Health for $Server" -ForegroundColor Cyan
        
        # Test Exchange Services
        $Services = @(
            'MSExchangeServiceHost',
            'MSExchangeIS',
            'MSExchangeMailboxReplication',
            'MSExchangeRPC',
            'MSExchangeTransport'
        )
        
        foreach ($Service in $Services) {
            $ServiceStatus = Get-Service -Name $Service -ComputerName $Server -ErrorAction SilentlyContinue
            if ($ServiceStatus) {
                if ($ServiceStatus.Status -eq 'Running') {
                    Write-Host "✓ $Service is running" -ForegroundColor Green
                } else {
                    Write-Warning "✗ $Service is $($ServiceStatus.Status)"
                }
            }
        }
        
        # Test Mailbox Database Status
        $Databases = Get-MailboxDatabase -Server $Server
        foreach ($Database in $Databases) {
            $DbStatus = Get-MailboxDatabase $Database.Name -Status
            Write-Host "Database: $($Database.Name) - Mounted: $($DbStatus.Mounted)" -ForegroundColor Yellow
        }
    }
}
```

#### Database Management

```powershell
# Mailbox Database Operations
class ExchangeDatabase {
    [string]$Name
    [string]$Server
    [string]$EdbFilePath
    [string]$LogFolderPath
    [bool]$CircularLoggingEnabled
    
    ExchangeDatabase([string]$Name, [string]$Server) {
        $this.Name = $Name
        $this.Server = $Server
        $this.EdbFilePath = "C:\Program Files\Microsoft\Exchange Server\V15\Mailbox\$Name\$Name.edb"
        $this.LogFolderPath = "C:\Program Files\Microsoft\Exchange Server\V15\Mailbox\$Name"
        $this.CircularLoggingEnabled = $false
    }
    
    [void]CreateDatabase() {
        try {
            New-MailboxDatabase -Name $this.Name -Server $this.Server -EdbFilePath $this.EdbFilePath -LogFolderPath $this.LogFolderPath
            Write-Host "Database $($this.Name) created successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create database: $($_.Exception.Message)"
        }
    }
    
    [void]MountDatabase() {
        try {
            Mount-Database $this.Name
            Write-Host "Database $($this.Name) mounted successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to mount database: $($_.Exception.Message)"
        }
    }
    
    [void]EnableCircularLogging() {
        try {
            Set-MailboxDatabase $this.Name -CircularLoggingEnabled $true
            $this.CircularLoggingEnabled = $true
            Write-Host "Circular logging enabled for $($this.Name)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to enable circular logging: $($_.Exception.Message)"
        }
    }
}

# Database Backup Management
function Start-ExchangeBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DatabaseName,
        [Parameter(Mandatory)]
        [string]$BackupPath
    )
    
    $BackupDate = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupFolder = Join-Path $BackupPath "Exchange_Backup_$BackupDate"
    
    try {
        # Create backup directory
        New-Item -Path $BackupFolder -ItemType Directory -Force
        
        # Suspend database copy
        Suspend-MailboxDatabaseCopy -Identity $DatabaseName -SuspendComment "Backup operation"
        
        # Perform backup using Windows Server Backup
        $BackupCommand = "wbadmin start backup -backupTarget:$BackupFolder -include:$DatabaseName -quiet"
        Invoke-Expression $BackupCommand
        
        # Resume database copy
        Resume-MailboxDatabaseCopy -Identity $DatabaseName
        
        Write-Host "Backup completed: $BackupFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Backup failed: $($_.Exception.Message)"
        # Ensure database copy is resumed
        Resume-MailboxDatabaseCopy -Identity $DatabaseName -ErrorAction SilentlyContinue
    }
}
```

### Transport Management

#### Message Flow Configuration

```powershell
# Transport Rules Management
function New-ExchangeTransportRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$FromScope = "InOrganization",
        [string[]]$MessageContains,
        [string]$Action = "RejectMessage",
        [string]$RejectReason = "Message blocked by transport rule"
    )
    
    $RuleParameters = @{
        Name = $Name
        FromScope = $FromScope
        Enabled = $true
    }
    
    if ($MessageContains) {
        $RuleParameters.Add('SubjectOrBodyContainsWords', $MessageContains)
    }
    
    switch ($Action) {
        'RejectMessage' {
            $RuleParameters.Add('RejectMessageReasonText', $RejectReason)
        }
        'Quarantine' {
            $RuleParameters.Add('Quarantine', $true)
        }
        'AddDisclaimer' {
            $RuleParameters.Add('ApplyHtmlDisclaimerText', $RejectReason)
        }
    }
    
    try {
        New-TransportRule @RuleParameters
        Write-Host "Transport rule '$Name' created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create transport rule: $($_.Exception.Message)"
    }
}

# SMTP Connector Configuration
function New-ExchangeSMTPConnector {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string[]]$SourceTransportServers,
        [Parameter(Mandatory)]
        [string[]]$RemoteIPRanges,
        [string]$Banner = "220 SMTP Server Ready",
        [bool]$AnonymousUsers = $false,
        [bool]$ExchangeUsers = $true
    )
    
    try {
        $ConnectorParams = @{
            Name = $Name
            Usage = 'Custom'
            TransportRole = 'HubTransport'
            RemoteIPRanges = $RemoteIPRanges
            SourceTransportServers = $SourceTransportServers
            Banner = $Banner
            AnonymousUsers = $AnonymousUsers
            ExchangeUsers = $ExchangeUsers
        }
        
        New-ReceiveConnector @ConnectorParams
        Write-Host "SMTP Connector '$Name' created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create SMTP connector: $($_.Exception.Message)"
    }
}
```

### Security Configuration

#### Exchange Security Hardening

```powershell
# Exchange Security Assessment
function Test-ExchangeSecurity {
    [CmdletBinding()]
    param(
        [string[]]$Servers = (Get-ExchangeServer).Name
    )
    
    $SecurityChecks = @()
    
    foreach ($Server in $Servers) {
        Write-Host "Checking security for $Server" -ForegroundColor Cyan
        
        # Check SSL/TLS Configuration
        $VirtualDirectories = @(
            'OWA', 'ECP', 'ActiveSync', 'OAB', 'EWS', 'MAPI', 'PowerShell'
        )
        
        foreach ($VDir in $VirtualDirectories) {
            try {
                $VDirConfig = & "Get-$VDir`VirtualDirectory" -Server $Server
                foreach ($Config in $VDirConfig) {
                    $SecurityCheck = [PSCustomObject]@{
                        Server = $Server
                        VirtualDirectory = $VDir
                        Name = $Config.Name
                        SSLRequired = $Config.SSLOffloading -eq $false
                        InternalAuth = $Config.InternalAuthenticationMethods
                        ExternalAuth = $Config.ExternalAuthenticationMethods
                    }
                    $SecurityChecks += $SecurityCheck
                }
            }
            catch {
                Write-Warning "Could not check $VDir on $Server"
            }
        }
        
        # Check Message Hygiene
        $TransportConfig = Get-TransportConfig
        $SecurityCheck = [PSCustomObject]@{
            Server = 'Organization'
            Setting = 'Anti-Spam'
            MaxRecipientEnvelopeLimit = $TransportConfig.MaxRecipientEnvelopeLimit
            MaxReceiveSize = $TransportConfig.MaxReceiveSize
            MaxSendSize = $TransportConfig.MaxSendSize
        }
        $SecurityChecks += $SecurityCheck
    }
    
    return $SecurityChecks | Format-Table -AutoSize
}

# Enable Exchange Security Features
function Enable-ExchangeSecurityFeatures {
    [CmdletBinding()]
    param(
        [switch]$EnableAntispam,
        [switch]$EnableAuditLogging,
        [switch]$EnableTLS,
        [string[]]$Servers = (Get-ExchangeServer | Where-Object {$_.ServerRole -match "Mailbox"}).Name
    )
    
    if ($EnableAntispam) {
        Write-Host "Enabling Anti-spam features..." -ForegroundColor Yellow
        foreach ($Server in $Servers) {
            & "$env:ExchangeInstallPath\Scripts\Install-AntiSpamAgents.ps1"
            Restart-Service MSExchangeTransport
        }
    }
    
    if ($EnableAuditLogging) {
        Write-Host "Enabling Audit Logging..." -ForegroundColor Yellow
        Set-AdminAuditLogConfig -AdminAuditLogEnabled $true -AdminAuditLogCmdlets * -AdminAuditLogParameters *
        
        # Enable mailbox audit logging for all mailboxes
        Get-Mailbox | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 90.00:00:00
    }
    
    if ($EnableTLS) {
        Write-Host "Configuring TLS..." -ForegroundColor Yellow
        foreach ($Server in $Servers) {
            # Force TLS on receive connectors
            Get-ReceiveConnector -Server $Server | Set-ReceiveConnector -RequireTLS $true
            
            # Configure send connectors for TLS
            Get-SendConnector | Set-SendConnector -RequireTLS $true -TlsDomain *
        }
    }
}
```

## Exchange Online Administration

### PowerShell Connection

```powershell
# Connect to Exchange Online
function Connect-ExchangeOnlineCustom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserPrincipalName,
        [switch]$UseModernAuth
    )
    
    try {
        if ($UseModernAuth) {
            Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowProgress $true
        } else {
            $Credential = Get-Credential -UserName $UserPrincipalName -Message "Enter Exchange Online credentials"
            Connect-ExchangeOnline -Credential $Credential -ShowProgress $true
        }
        Write-Host "Connected to Exchange Online successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Exchange Online: $($_.Exception.Message)"
    }
}

# Exchange Online Health Check
function Get-ExchangeOnlineHealth {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Exchange Online Health Report" -ForegroundColor Cyan
        Write-Host "================================" -ForegroundColor Cyan
        
        # Organization Info
        $OrgConfig = Get-OrganizationConfig
        Write-Host "Organization: $($OrgConfig.DisplayName)" -ForegroundColor Yellow
        
        # Mailbox Statistics
        $MailboxCount = (Get-Mailbox -ResultSize Unlimited).Count
        Write-Host "Total Mailboxes: $MailboxCount" -ForegroundColor Yellow
        
        # Transport Rules
        $TransportRules = Get-TransportRule
        Write-Host "Transport Rules: $($TransportRules.Count)" -ForegroundColor Yellow
        
        # DLP Policies
        $DLPPolicies = Get-DlpPolicy
        Write-Host "DLP Policies: $($DLPPolicies.Count)" -ForegroundColor Yellow
        
        # ATP Policies
        $SafeAttachmentPolicies = Get-SafeAttachmentPolicy
        $SafeLinksPolicies = Get-SafeLinksPolicy
        Write-Host "Safe Attachment Policies: $($SafeAttachmentPolicies.Count)" -ForegroundColor Yellow
        Write-Host "Safe Links Policies: $($SafeLinksPolicies.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to get Exchange Online health: $($_.Exception.Message)"
    }
}
```

### Migration Tools

```powershell
# Exchange Migration Helper
class ExchangeMigration {
    [string]$SourceEnvironment
    [string]$TargetEnvironment
    [string]$MigrationEndpoint
    [string[]]$UserList
    
    ExchangeMigration([string]$Source, [string]$Target) {
        $this.SourceEnvironment = $Source
        $this.TargetEnvironment = $Target
    }
    
    [void]CreateMigrationEndpoint([string]$EndpointName, [string]$ExchangeServer, [string]$Username, [securestring]$Password) {
        try {
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
            New-MigrationEndpoint -Name $EndpointName -ExchangeRemoteMove -RemoteServer $ExchangeServer -Credentials $Credential
            $this.MigrationEndpoint = $EndpointName
            Write-Host "Migration endpoint '$EndpointName' created" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create migration endpoint: $($_.Exception.Message)"
        }
    }
    
    [void]StartMigrationBatch([string]$BatchName, [string[]]$Users) {
        try {
            $this.UserList = $Users
            New-MigrationBatch -Name $BatchName -Users $Users -TargetDeliveryDomain "$($this.TargetEnvironment).mail.onmicrosoft.com"
            Start-MigrationBatch -Identity $BatchName
            Write-Host "Migration batch '$BatchName' started for $($Users.Count) users" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to start migration batch: $($_.Exception.Message)"
        }
    }
    
    [PSCustomObject]GetMigrationStatus([string]$BatchName) {
        try {
            $BatchStatus = Get-MigrationBatch -Identity $BatchName
            $UserStatistics = Get-MigrationUser -BatchId $BatchName | Get-MigrationUserStatistics
            
            return [PSCustomObject]@{
                BatchName = $BatchName
                Status = $BatchStatus.Status
                TotalUsers = $UserStatistics.Count
                Completed = ($UserStatistics | Where-Object {$_.Status -eq 'Completed'}).Count
                InProgress = ($UserStatistics | Where-Object {$_.Status -eq 'Syncing'}).Count
                Failed = ($UserStatistics | Where-Object {$_.Status -eq 'Failed'}).Count
            }
        }
        catch {
            Write-Error "Failed to get migration status: $($_.Exception.Message)"
            return $null
        }
    }
}
```

## Best Practices

### Performance Optimization

1. **Database Maintenance**
   - Regular defragmentation
   - Monitor database sizes
   - Implement proper backup strategies

2. **Transport Optimization**
   - Configure message limits appropriately
   - Implement proper connector sizing
   - Monitor queue health

3. **Security Hardening**
   - Enable audit logging
   - Implement DLP policies
   - Configure ATP features

### Monitoring and Alerting

```powershell
# Exchange Monitoring Script
function Start-ExchangeMonitoring {
    [CmdletBinding()]
    param(
        [int]$CheckIntervalMinutes = 15,
        [string]$LogPath = "C:\ExchangeLogs\Monitoring.log"
    )
    
    while ($true) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Check Exchange Services
        $ServiceStatus = Get-ExchangeHealth
        
        # Check Database Health
        $DatabaseHealth = Get-MailboxDatabase -Status | Select-Object Name, Mounted, DatabaseSize
        
        # Check Queue Health
        $QueueHealth = Get-Queue | Where-Object {$_.MessageCount -gt 0}
        
        # Log results
        $LogEntry = "$Timestamp - Services: OK, Databases: $($DatabaseHealth.Count), Queues with messages: $($QueueHealth.Count)"
        Add-Content -Path $LogPath -Value $LogEntry
        
        Start-Sleep -Seconds ($CheckIntervalMinutes * 60)
    }
}
```

## Troubleshooting

### Common Issues

1. **Database Mount Issues**
   - Check event logs
   - Verify disk space
   - Check database corruption

2. **Mail Flow Problems**
   - Analyze message tracking logs
   - Check transport rules
   - Verify connector configuration

3. **Performance Issues**
   - Monitor performance counters
   - Check database lag
   - Analyze RPC latency

## References

- [Exchange Server Documentation](https://docs.microsoft.com/en-us/exchange/exchange-server)
- [Exchange Online Documentation](https://docs.microsoft.com/en-us/exchange/exchange-online)
- [SMTP Relay Configuration](https://practical365.com/configure-exchange-server-2019-smtp-anonymous-relay/)
- [Exchange 2016 SMTP Relay](https://practical365.com/exchange-2016-smtp-relay-connector/)
- [Exchange Online SMTP Relay](https://practical365.com/practical-exchange-understanding-smtp-relay-in-exchange-online/)
- [Updated SMTP Relay Requirements](https://techcommunity.microsoft.com/t5/exchange-team-blog/updated-requirements-for-smtp-relay-through-exchange-online/ba-p/3851357)
