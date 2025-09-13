---
title: PowerShell Azure Examples
description: Comprehensive PowerShell examples for Azure resource management, automation, and cloud operations
author: Joseph Streeter
date: 2024-01-15
tags: [powershell, azure, cloud, automation, resource-management]
---

This collection demonstrates PowerShell's capabilities for Azure resource management, automation, and cloud operations. These examples use the Azure PowerShell module and follow Azure best practices for security and resource management.

## Azure Resource Management

### Virtual Machine Management

```powershell
<#
.SYNOPSIS
    Comprehensive Azure Virtual Machine management functions
.DESCRIPTION
    Provides functions for creating, managing, and monitoring Azure VMs
    with proper error handling and security configurations
.EXAMPLE
    New-AzureVM -ResourceGroupName "MyRG" -VMName "WebServer01" -Location "East US"
#>

function New-AzureVM
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("East US", "West US", "Central US", "North Europe", "West Europe")]
        [string]$Location,
        
        [Parameter()]
        [ValidateSet("Standard_B2s", "Standard_D2s_v3", "Standard_D4s_v3", "Standard_E2s_v3")]
        [string]$VMSize = "Standard_B2s",
        
        [Parameter()]
        [ValidateSet("Windows Server 2019", "Windows Server 2022", "Ubuntu 20.04", "Ubuntu 22.04")]
        [string]$OperatingSystem = "Windows Server 2022",
        
        [Parameter()]
        [string]$AdminUsername = "azureuser",
        
        [Parameter()]
        [securestring]$AdminPassword,
        
        [Parameter()]
        [string]$VNetName,
        
        [Parameter()]
        [string]$SubnetName = "default",
        
        [Parameter()]
        [hashtable]$Tags = @{}
    )
    
    try
    {
        Write-Verbose "Starting Azure VM deployment: $VMName"
        
        # Ensure Azure PowerShell module is loaded
        if (-not (Get-Module -Name Az.Compute -ListAvailable))
        {
            throw "Azure PowerShell module (Az.Compute) is not installed. Install with: Install-Module -Name Az"
        }
        
        # Check if already connected to Azure
        $Context = Get-AzContext
        if (-not $Context)
        {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
        }
        
        # Verify resource group exists
        $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $ResourceGroup)
        {
            Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
            $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        }
        
        # Generate secure password if not provided
        if (-not $AdminPassword)
        {
            $PasswordString = -join ((1..16) | ForEach-Object { Get-Random -Input @('abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '0123456789', '!@#$%^&*')[Get-Random -Minimum 0 -Maximum 4] })
            $AdminPassword = ConvertTo-SecureString -String $PasswordString -AsPlainText -Force
            Write-Host "Generated secure password for VM. Please save securely." -ForegroundColor Yellow
        }
        
        # Create credential object
        $Credential = New-Object System.Management.Automation.PSCredential($AdminUsername, $AdminPassword)
        
        # Configure VM based on operating system
        $VMConfig = switch ($OperatingSystem)
        {
            "Windows Server 2019" {
                @{
                    PublisherName = "MicrosoftWindowsServer"
                    Offer = "WindowsServer"
                    Skus = "2019-Datacenter"
                    Version = "latest"
                }
            }
            "Windows Server 2022" {
                @{
                    PublisherName = "MicrosoftWindowsServer"
                    Offer = "WindowsServer"
                    Skus = "2022-Datacenter"
                    Version = "latest"
                }
            }
            "Ubuntu 20.04" {
                @{
                    PublisherName = "Canonical"
                    Offer = "0001-com-ubuntu-server-focal"
                    Skus = "20_04-lts-gen2"
                    Version = "latest"
                }
            }
            "Ubuntu 22.04" {
                @{
                    PublisherName = "Canonical"
                    Offer = "0001-com-ubuntu-server-jammy"
                    Skus = "22_04-lts-gen2"
                    Version = "latest"
                }
            }
        }
        
        # Create or get virtual network
        if ($VNetName)
        {
            $VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $VNet)
            {
                Write-Host "Creating virtual network: $VNetName" -ForegroundColor Green
                $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
                $VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $SubnetConfig
            }
        }
        else
        {
            $VNetName = "$VMName-vnet"
            Write-Host "Creating virtual network: $VNetName" -ForegroundColor Green
            $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
            $VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $SubnetConfig
        }
        
        # Create Network Security Group with basic rules
        $NSGName = "$VMName-nsg"
        Write-Host "Creating network security group: $NSGName" -ForegroundColor Green
        
        $NSGRules = @()
        if ($OperatingSystem -like "*Windows*")
        {
            $NSGRules += New-AzNetworkSecurityRuleConfig -Name "RDP" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3389" -Access "Allow"
        }
        else
        {
            $NSGRules += New-AzNetworkSecurityRuleConfig -Name "SSH" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "22" -Access "Allow"
        }
        
        $NSG = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $NSGRules
        
        # Create public IP
        $PublicIPName = "$VMName-pip"
        Write-Host "Creating public IP: $PublicIPName" -ForegroundColor Green
        $PublicIP = New-AzPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod "Static" -Sku "Standard"
        
        # Create network interface
        $NICName = "$VMName-nic"
        Write-Host "Creating network interface: $NICName" -ForegroundColor Green
        $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet
        $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $NSG.Id
        
        # Create VM configuration
        Write-Host "Creating VM configuration..." -ForegroundColor Green
        $VM = New-AzVMConfig -VMName $VMName -VMSize $VMSize
        
        if ($OperatingSystem -like "*Windows*")
        {
            $VM = Set-AzVMOperatingSystem -VM $VM -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
        }
        else
        {
            $VM = Set-AzVMOperatingSystem -VM $VM -Linux -ComputerName $VMName -Credential $Credential
        }
        
        $VM = Set-AzVMSourceImage -VM $VM -PublisherName $VMConfig.PublisherName -Offer $VMConfig.Offer -Skus $VMConfig.Skus -Version $VMConfig.Version
        $VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id
        
        # Set OS disk configuration
        $VM = Set-AzVMOSDisk -VM $VM -CreateOption "FromImage" -StorageAccountType "Premium_LRS"
        
        # Add tags
        $DefaultTags = @{
            "CreatedBy" = "PowerShell"
            "CreatedDate" = (Get-Date -Format "yyyy-MM-dd")
            "Environment" = "Development"
        }
        $AllTags = $DefaultTags + $Tags
        
        # Create the virtual machine
        Write-Host "Creating virtual machine: $VMName" -ForegroundColor Green
        Write-Host "This may take several minutes..." -ForegroundColor Yellow
        
        $VMResult = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM -Tag $AllTags
        
        if ($VMResult.IsSuccessStatusCode)
        {
            Write-Host "VM created successfully!" -ForegroundColor Green
            
            # Get VM details
            $CreatedVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
            $VMPublicIP = Get-AzPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName
            
            # Return VM information
            $VMInfo = [PSCustomObject]@{
                VMName = $VMName
                ResourceGroup = $ResourceGroupName
                Location = $Location
                Size = $VMSize
                OperatingSystem = $OperatingSystem
                PublicIPAddress = $VMPublicIP.IpAddress
                AdminUsername = $AdminUsername
                Status = "Created"
                CreatedDate = Get-Date
                Tags = $AllTags
            }
            
            Write-Host "VM Details:" -ForegroundColor Cyan
            Write-Host "Name: $($VMInfo.VMName)" -ForegroundColor White
            Write-Host "Public IP: $($VMInfo.PublicIPAddress)" -ForegroundColor White
            Write-Host "Username: $($VMInfo.AdminUsername)" -ForegroundColor White
            
            if ($OperatingSystem -like "*Windows*")
            {
                Write-Host "RDP Connection: mstsc /v:$($VMInfo.PublicIPAddress)" -ForegroundColor Yellow
            }
            else
            {
                Write-Host "SSH Connection: ssh $($VMInfo.AdminUsername)@$($VMInfo.PublicIPAddress)" -ForegroundColor Yellow
            }
            
            return $VMInfo
        }
        else
        {
            throw "VM creation failed"
        }
    }
    catch
    {
        Write-Error "VM creation failed: $($_.Exception.Message)"
        throw
    }
}

function Get-AzureVMStatus
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ResourceGroupName,
        
        [Parameter()]
        [string[]]$VMName,
        
        [Parameter()]
        [switch]$IncludeMetrics
    )
    
    begin
    {
        $VMStatusList = [System.Collections.Generic.List[object]]@()
    }
    
    process
    {
        foreach ($RGName in $ResourceGroupName)
        {
            try
            {
                if ($VMName)
                {
                    $VMs = $VMName | ForEach-Object { Get-AzVM -ResourceGroupName $RGName -Name $_ -Status }
                }
                else
                {
                    $VMs = Get-AzVM -ResourceGroupName $RGName -Status
                }
                
                foreach ($VM in $VMs)
                {
                    $PowerState = ($VM.Statuses | Where-Object Code -like "PowerState/*").DisplayStatus
                    $ProvisioningState = ($VM.Statuses | Where-Object Code -like "ProvisioningState/*").DisplayStatus
                    
                    $VMStatus = [PSCustomObject]@{
                        VMName = $VM.Name
                        ResourceGroup = $VM.ResourceGroupName
                        Location = $VM.Location
                        Size = $VM.HardwareProfile.VmSize
                        PowerState = $PowerState
                        ProvisioningState = $ProvisioningState
                        OSType = $VM.StorageProfile.OsDisk.OsType
                        LastModified = $VM.TimeCreated
                    }
                    
                    if ($IncludeMetrics)
                    {
                        try
                        {
                            # Get basic metrics for the VM
                            $EndTime = Get-Date
                            $StartTime = $EndTime.AddHours(-1)
                            
                            $CPUMetric = Get-AzMetric -ResourceId $VM.Id -MetricName "Percentage CPU" -StartTime $StartTime -EndTime $EndTime -TimeGrain "00:05:00" -ErrorAction SilentlyContinue
                            $NetworkInMetric = Get-AzMetric -ResourceId $VM.Id -MetricName "Network In Total" -StartTime $StartTime -EndTime $EndTime -TimeGrain "00:05:00" -ErrorAction SilentlyContinue
                            
                            $VMStatus | Add-Member -NotePropertyName "AvgCPUPercent" -NotePropertyValue (($CPUMetric.Data | Measure-Object Average -Average).Average)
                            $VMStatus | Add-Member -NotePropertyName "NetworkInBytes" -NotePropertyValue (($NetworkInMetric.Data | Measure-Object Total -Sum).Sum)
                        }
                        catch
                        {
                            $VMStatus | Add-Member -NotePropertyName "MetricsError" -NotePropertyValue $_.Exception.Message
                        }
                    }
                    
                    $VMStatusList.Add($VMStatus)
                }
            }
            catch
            {
                Write-Error "Failed to get VM status for resource group $RGName`: $($_.Exception.Message)"
            }
        }
    }
    
    end
    {
        return $VMStatusList
    }
}
```

## Azure Storage Management

### Storage Account Operations

```powershell
function New-AzureStorageAccountSecure
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-z0-9]{3,24}$')]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter()]
        [ValidateSet("Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Premium_LRS")]
        [string]$SkuName = "Standard_LRS",
        
        [Parameter()]
        [ValidateSet("BlobStorage", "Storage", "StorageV2")]
        [string]$Kind = "StorageV2",
        
        [Parameter()]
        [switch]$EnableHttpsTrafficOnly = $true,
        
        [Parameter()]
        [hashtable]$Tags = @{}
    )
    
    try
    {
        Write-Verbose "Creating secure storage account: $StorageAccountName"
        
        # Check if storage account name is available
        $NameAvailability = Get-AzStorageAccountNameAvailability -Name $StorageAccountName
        if (-not $NameAvailability.NameAvailable)
        {
            throw "Storage account name '$StorageAccountName' is not available: $($NameAvailability.Reason)"
        }
        
        # Create storage account with security best practices
        $StorageAccount = New-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName $SkuName `
            -Kind $Kind `
            -EnableHttpsTrafficOnly:$EnableHttpsTrafficOnly `
            -Tag $Tags
        
        # Configure additional security settings
        Write-Host "Configuring security settings..." -ForegroundColor Green
        
        # Disable blob public access
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -AllowBlobPublicAccess $false
        
        # Enable secure transfer
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -EnableHttpsTrafficOnly $true
        
        # Set minimum TLS version
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -MinimumTlsVersion TLS1_2
        
        # Get storage account keys
        $StorageKeys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKeys[0].Value
        
        # Create default containers with private access
        $DefaultContainers = @("logs", "backups", "uploads")
        foreach ($ContainerName in $DefaultContainers)
        {
            try
            {
                New-AzStorageContainer -Name $ContainerName -Context $Context -Permission Off
                Write-Host "Created container: $ContainerName" -ForegroundColor Green
            }
            catch
            {
                Write-Warning "Failed to create container $ContainerName`: $($_.Exception.Message)"
            }
        }
        
        # Return storage account information
        $StorageInfo = [PSCustomObject]@{
            StorageAccountName = $StorageAccountName
            ResourceGroup = $ResourceGroupName
            Location = $Location
            Sku = $SkuName
            Kind = $Kind
            PrimaryEndpoint = $StorageAccount.PrimaryEndpoints.Blob
            HttpsOnly = $EnableHttpsTrafficOnly
            CreatedContainers = $DefaultContainers
            ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($StorageKeys[0].Value);EndpointSuffix=core.windows.net"
        }
        
        Write-Host "Storage account created successfully!" -ForegroundColor Green
        Write-Host "Primary endpoint: $($StorageInfo.PrimaryEndpoint)" -ForegroundColor Cyan
        
        return $StorageInfo
    }
    catch
    {
        Write-Error "Storage account creation failed: $($_.Exception.Message)"
        throw
    }
}

function Backup-AzureVMToBlobStorage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VMResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$VMName,
        
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $true)]
        [string]$StorageResourceGroupName,
        
        [Parameter()]
        [string]$ContainerName = "vm-backups",
        
        [Parameter()]
        [int]$RetentionDays = 30
    )
    
    try
    {
        Write-Host "Starting VM backup process..." -ForegroundColor Green
        
        # Get VM information
        $VM = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName
        if (-not $VM)
        {
            throw "VM '$VMName' not found in resource group '$VMResourceGroupName'"
        }
        
        # Get storage context
        $StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageResourceGroupName -Name $StorageAccountName
        $StorageKeys = Get-AzStorageAccountKey -ResourceGroupName $StorageResourceGroupName -Name $StorageAccountName
        $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKeys[0].Value
        
        # Ensure backup container exists
        $Container = Get-AzStorageContainer -Name $ContainerName -Context $Context -ErrorAction SilentlyContinue
        if (-not $Container)
        {
            New-AzStorageContainer -Name $ContainerName -Context $Context -Permission Off
            Write-Host "Created backup container: $ContainerName" -ForegroundColor Green
        }
        
        # Create snapshot of OS disk
        $OSDisk = Get-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $VM.StorageProfile.OsDisk.Name
        $SnapshotName = "$($VM.Name)-os-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        Write-Host "Creating OS disk snapshot: $SnapshotName" -ForegroundColor Yellow
        
        $SnapshotConfig = New-AzSnapshotConfig -SourceUri $OSDisk.Id -CreateOption Copy -Location $VM.Location
        $Snapshot = New-AzSnapshot -ResourceGroupName $VM.ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig
        
        # Export snapshot to storage account
        $BlobName = "$($VM.Name)/$SnapshotName.vhd"
        $SASUri = Grant-AzSnapshotAccess -ResourceGroupName $VM.ResourceGroupName -SnapshotName $SnapshotName -Access Read -DurationInSecond 3600
        
        Write-Host "Copying snapshot to blob storage..." -ForegroundColor Yellow
        
        # Start async copy operation
        $CopyBlob = Start-AzStorageBlobCopy -AbsoluteUri $SASUri.AccessSAS -DestContainer $ContainerName -DestBlob $BlobName -Context $Context
        
        # Monitor copy progress
        do
        {
            Start-Sleep -Seconds 30
            $CopyStatus = $CopyBlob | Get-AzStorageBlobCopyState
            $PercentComplete = if ($CopyStatus.TotalBytes -gt 0) { [math]::Round(($CopyStatus.BytesCopied / $CopyStatus.TotalBytes) * 100, 2) } else { 0 }
            Write-Host "Copy progress: $PercentComplete%" -ForegroundColor Cyan
        }
        while ($CopyStatus.Status -eq "Pending")
        
        if ($CopyStatus.Status -eq "Success")
        {
            Write-Host "Backup completed successfully!" -ForegroundColor Green
            
            # Clean up snapshot
            Remove-AzSnapshot -ResourceGroupName $VM.ResourceGroupName -SnapshotName $SnapshotName -Force
            Revoke-AzSnapshotAccess -ResourceGroupName $VM.ResourceGroupName -SnapshotName $SnapshotName
            
            # Set metadata on blob
            $Blob = Get-AzStorageBlob -Container $ContainerName -Blob $BlobName -Context $Context
            $Metadata = @{
                "VMName" = $VM.Name
                "ResourceGroup" = $VM.ResourceGroupName
                "BackupDate" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                "OSType" = $VM.StorageProfile.OsDisk.OsType
                "VMSize" = $VM.HardwareProfile.VmSize
            }
            $Blob.ICloudBlob.SetMetadata($Metadata)
            
            # Clean up old backups
            Write-Host "Cleaning up old backups..." -ForegroundColor Yellow
            $OldBlobs = Get-AzStorageBlob -Container $ContainerName -Context $Context -Prefix "$($VM.Name)/" | 
                Where-Object { $_.LastModified -lt (Get-Date).AddDays(-$RetentionDays) }
            
            foreach ($OldBlob in $OldBlobs)
            {
                Remove-AzStorageBlob -Container $ContainerName -Blob $OldBlob.Name -Context $Context -Force
                Write-Host "Removed old backup: $($OldBlob.Name)" -ForegroundColor Gray
            }
            
            $BackupInfo = [PSCustomObject]@{
                VMName = $VM.Name
                BackupDate = Get-Date
                SnapshotName = $SnapshotName
                BlobName = $BlobName
                StorageAccount = $StorageAccountName
                Container = $ContainerName
                SizeGB = [math]::Round($CopyStatus.TotalBytes / 1GB, 2)
                Status = "Success"
            }
            
            return $BackupInfo
        }
        else
        {
            throw "Backup copy failed: $($CopyStatus.Status)"
        }
    }
    catch
    {
        Write-Error "VM backup failed: $($_.Exception.Message)"
        throw
    }
}
```

## Azure Monitoring and Automation

### Resource Health Monitoring

```powershell
function Get-AzureResourceHealth
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ResourceGroupName,
        
        [Parameter()]
        [string[]]$ResourceType,
        
        [Parameter()]
        [switch]$IncludeMetrics,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try
    {
        Write-Host "Gathering Azure resource health information..." -ForegroundColor Green
        
        $HealthResults = [System.Collections.Generic.List[object]]@()
        
        # Get all resources or filter by resource group
        if ($ResourceGroupName)
        {
            $Resources = $ResourceGroupName | ForEach-Object { Get-AzResource -ResourceGroupName $_ }
        }
        else
        {
            $Resources = Get-AzResource
        }
        
        # Filter by resource type if specified
        if ($ResourceType)
        {
            $Resources = $Resources | Where-Object ResourceType -in $ResourceType
        }
        
        foreach ($Resource in $Resources)
        {
            try
            {
                Write-Progress -Activity "Checking Resource Health" -Status "Processing $($Resource.Name)" -PercentComplete (($Resources.IndexOf($Resource) / $Resources.Count) * 100)
                
                $HealthInfo = [PSCustomObject]@{
                    ResourceName = $Resource.Name
                    ResourceType = $Resource.ResourceType
                    ResourceGroup = $Resource.ResourceGroupName
                    Location = $Resource.Location
                    Status = "Unknown"
                    LastChecked = Get-Date
                    Issues = @()
                    Metrics = @{}
                }
                
                # Check specific resource types
                switch ($Resource.ResourceType)
                {
                    "Microsoft.Compute/virtualMachines"
                    {
                        $VM = Get-AzVM -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -Status
                        $PowerState = ($VM.Statuses | Where-Object Code -like "PowerState/*").DisplayStatus
                        $ProvisioningState = ($VM.Statuses | Where-Object Code -like "ProvisioningState/*").DisplayStatus
                        
                        $HealthInfo.Status = if ($PowerState -eq "VM running" -and $ProvisioningState -eq "Provisioning succeeded") { "Healthy" } else { "Unhealthy" }
                        
                        if ($PowerState -ne "VM running")
                        {
                            $HealthInfo.Issues += "VM not running: $PowerState"
                        }
                        
                        if ($IncludeMetrics)
                        {
                            try
                            {
                                $EndTime = Get-Date
                                $StartTime = $EndTime.AddHours(-1)
                                $CPUMetric = Get-AzMetric -ResourceId $Resource.ResourceId -MetricName "Percentage CPU" -StartTime $StartTime -EndTime $EndTime -TimeGrain "00:15:00"
                                $HealthInfo.Metrics["AvgCPU"] = [math]::Round(($CPUMetric.Data | Measure-Object Average -Average).Average, 2)
                            }
                            catch
                            {
                                $HealthInfo.Issues += "Unable to retrieve metrics"
                            }
                        }
                    }
                    
                    "Microsoft.Storage/storageAccounts"
                    {
                        $StorageAccount = Get-AzStorageAccount -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name
                        $HealthInfo.Status = if ($StorageAccount.ProvisioningState -eq "Succeeded") { "Healthy" } else { "Unhealthy" }
                        
                        if ($StorageAccount.ProvisioningState -ne "Succeeded")
                        {
                            $HealthInfo.Issues += "Storage account provisioning state: $($StorageAccount.ProvisioningState)"
                        }
                        
                        # Check if HTTPS is enforced
                        if (-not $StorageAccount.EnableHttpsTrafficOnly)
                        {
                            $HealthInfo.Issues += "HTTPS traffic not enforced"
                        }
                    }
                    
                    "Microsoft.Web/sites"
                    {
                        $WebApp = Get-AzWebApp -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name
                        $HealthInfo.Status = if ($WebApp.State -eq "Running") { "Healthy" } else { "Unhealthy" }
                        
                        if ($WebApp.State -ne "Running")
                        {
                            $HealthInfo.Issues += "Web app not running: $($WebApp.State)"
                        }
                        
                        # Check if HTTPS is enforced
                        if (-not $WebApp.HttpsOnly)
                        {
                            $HealthInfo.Issues += "HTTPS not enforced"
                        }
                        
                        if ($IncludeMetrics)
                        {
                            try
                            {
                                $EndTime = Get-Date
                                $StartTime = $EndTime.AddHours(-1)
                                $RequestMetric = Get-AzMetric -ResourceId $Resource.ResourceId -MetricName "Requests" -StartTime $StartTime -EndTime $EndTime -TimeGrain "00:15:00"
                                $HealthInfo.Metrics["TotalRequests"] = ($RequestMetric.Data | Measure-Object Total -Sum).Sum
                            }
                            catch
                            {
                                $HealthInfo.Issues += "Unable to retrieve metrics"
                            }
                        }
                    }
                    
                    default
                    {
                        # Generic resource check
                        try
                        {
                            $GenericResource = Get-AzResource -ResourceId $Resource.ResourceId
                            $HealthInfo.Status = if ($GenericResource.Properties.provisioningState -eq "Succeeded") { "Healthy" } else { "Unknown" }
                        }
                        catch
                        {
                            $HealthInfo.Status = "Error"
                            $HealthInfo.Issues += "Unable to retrieve resource details"
                        }
                    }
                }
                
                $HealthResults.Add($HealthInfo)
            }
            catch
            {
                Write-Warning "Failed to check health for resource $($Resource.Name): $($_.Exception.Message)"
            }
        }
        
        Write-Progress -Activity "Checking Resource Health" -Completed
        
        # Generate summary
        $Summary = @{
            TotalResources = $HealthResults.Count
            HealthyResources = ($HealthResults | Where-Object Status -eq "Healthy").Count
            UnhealthyResources = ($HealthResults | Where-Object Status -eq "Unhealthy").Count
            UnknownResources = ($HealthResults | Where-Object Status -eq "Unknown").Count
            ResourcesWithIssues = ($HealthResults | Where-Object { $_.Issues.Count -gt 0 }).Count
        }
        
        Write-Host "`nResource Health Summary:" -ForegroundColor Cyan
        Write-Host "Total Resources: $($Summary.TotalResources)" -ForegroundColor White
        Write-Host "Healthy: $($Summary.HealthyResources)" -ForegroundColor Green
        Write-Host "Unhealthy: $($Summary.UnhealthyResources)" -ForegroundColor Red
        Write-Host "Unknown: $($Summary.UnknownResources)" -ForegroundColor Yellow
        Write-Host "With Issues: $($Summary.ResourcesWithIssues)" -ForegroundColor Orange
        
        # Export results if path specified
        if ($OutputPath)
        {
            $ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $ReportFile = Join-Path $OutputPath "AzureResourceHealth_$ReportDate.csv"
            $HealthResults | Export-Csv -Path $ReportFile -NoTypeInformation
            Write-Host "Report saved to: $ReportFile" -ForegroundColor Cyan
        }
        
        return $HealthResults
    }
    catch
    {
        Write-Error "Resource health check failed: $($_.Exception.Message)"
        throw
    }
}

# Usage Examples
Write-Host @"

AZURE POWERSHELL EXAMPLES

1. Create Secure VM:
   New-AzureVM -ResourceGroupName "MyRG" -VMName "WebServer01" -Location "East US"

2. Get VM Status:
   Get-AzureVMStatus -ResourceGroupName "MyRG" -IncludeMetrics

3. Create Secure Storage:
   New-AzureStorageAccountSecure -StorageAccountName "mystorageacct123" -ResourceGroupName "MyRG" -Location "East US"

4. Backup VM:
   Backup-AzureVMToBlobStorage -VMResourceGroupName "MyRG" -VMName "WebServer01" -StorageAccountName "backupstorageacct" -StorageResourceGroupName "BackupRG"

5. Check Resource Health:
   Get-AzureResourceHealth -ResourceGroupName "MyRG" -IncludeMetrics -OutputPath "C:\Reports"

These examples demonstrate Azure PowerShell capabilities for:
- Virtual machine management with security best practices
- Storage account creation with security configurations
- Automated VM backup to blob storage
- Comprehensive resource health monitoring
- Metrics collection and reporting

All functions include proper error handling, progress reporting,
and security best practices for Azure resource management.

"@ -ForegroundColor Green
```
