---
title: "Authentik Backup and Recovery"
description: "Backup and disaster-recovery procedures for Authentik"
category: "infrastructure"
author: "Joseph Streeter"
ms.date: 2026-07-17
---

## Backup and Recovery

### Database Backup Strategy

```powershell
function Backup-AuthentikDatabase
{
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,
        [string]$DatabaseHost = "localhost",
        [string]$DatabaseName = "authentik",
        [string]$DatabaseUser = "authentik",
        [switch]$Compress,
        [int]$RetentionDays = 30
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$BackupPath/authentik_backup_$timestamp.sql"
    
    try
    {
        Write-Host "Starting Authentik database backup..." -ForegroundColor Cyan
        
        # Create PostgreSQL dump
        $pgDumpCmd = "pg_dump -h $DatabaseHost -U $DatabaseUser -d $DatabaseName -f $backupFile --verbose"
        
        if ($Compress)
        {
            $backupFile = "$backupFile.gz"
            $pgDumpCmd += " | gzip"
        }
        
        Invoke-Expression $pgDumpCmd
        
        if (Test-Path $backupFile)
        {
            $fileSize = (Get-Item $backupFile).Length / 1MB
            Write-Host "Backup completed: $backupFile ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
            
            # Cleanup old backups
            Get-ChildItem -Path $BackupPath -Filter "authentik_backup_*.sql*" | 
                Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$RetentionDays) } |
                Remove-Item -Force
            
            Write-Host "Old backups cleaned up (retention: $RetentionDays days)" -ForegroundColor Yellow
            
            return @{
                BackupFile = $backupFile
                Size = $fileSize
                Success = $true
            }
        }
        else
        {
            throw "Backup file not created"
        }
    }
    catch
    {
        Write-Error "Backup failed: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
```

### Configuration Backup

```powershell
function Export-AuthentikConfiguration
{
    param(
        [Parameter(Mandatory)]
        [string]$AuthentikUrl,
        [Parameter(Mandatory)]
        [string]$ApiToken,
        [Parameter(Mandatory)]
        [string]$ExportPath
    )
    
    $headers = @{
        'Authorization' = "Bearer $ApiToken"
        'Accept' = 'application/json'
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $configBackup = @{
        exported_at = Get-Date
        version = "2024.2.2"
        components = @{}
    }
    
    try
    {
        Write-Host "Exporting Authentik configuration..." -ForegroundColor Cyan
        
        # Export core configuration
        $endpoints = @{
            "applications" = "/api/v3/core/applications/"
            "groups" = "/api/v3/core/groups/"
            "users" = "/api/v3/core/users/"
            "flows" = "/api/v3/flows/instances/"
            "stages" = "/api/v3/stages/all/"
            "policies" = "/api/v3/policies/all/"
            "sources" = "/api/v3/sources/all/"
            "providers" = "/api/v3/providers/all/"
        }
        
        foreach ($component in $endpoints.Keys)
        {
            Write-Host "Exporting $component..." -ForegroundColor Yellow
            
            $response = Invoke-RestMethod -Uri "$AuthentikUrl$($endpoints[$component])" -Headers $headers
            $configBackup.components[$component] = $response.results
            
            Write-Host "  Exported $($response.results.Count) $component" -ForegroundColor Green
        }
        
        # Save configuration backup
        $backupFile = "$ExportPath/authentik_config_$timestamp.json"
        $configBackup | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFile -Encoding UTF8
        
        Write-Host "Configuration exported to: $backupFile" -ForegroundColor Green
        
        return @{
            BackupFile = $backupFile
            ComponentCount = $configBackup.components.Keys.Count
            Success = $true
        }
    }
    catch
    {
        Write-Error "Configuration export failed: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
```

---

## Navigation

[◄ Security and Monitoring](security.md) · [Authentik Overview](index.md) · [Troubleshooting ►](troubleshooting.md)
