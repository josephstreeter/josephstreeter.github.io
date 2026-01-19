---
uid: infrastructure.packer.builders
title: Packer Builders
description: Comprehensive guide to Packer builders for creating machine images across AWS, Azure, Google Cloud, VMware, VirtualBox, Docker, and other platforms
ms.date: 01/18/2026
---

This section covers Packer builders and how they create machine images across different platforms.

## What are Builders?

Builders are Packer components responsible for creating machine images for specific platforms. Each builder is designed to work with a particular infrastructure provider or virtualization technology, handling the platform-specific details of image creation.

### How Builders Work

The build process follows these steps:

1. **Initialize**: Set up the build environment and validate configuration
2. **Create**: Launch a temporary instance or virtual machine
3. **Provision**: Allow provisioners to configure the instance
4. **Snapshot**: Create an image from the configured instance
5. **Cleanup**: Terminate temporary resources
6. **Output**: Return artifact information (image ID, location, etc.)

### Builder Types

Builders fall into several categories:

- **Cloud Builders**: AWS, Azure, Google Cloud, DigitalOcean, etc.
- **Virtualization Builders**: VMware, VirtualBox, QEMU, Hyper-V
- **Container Builders**: Docker, LXC, LXD
- **Bare Metal Builders**: PXE, custom ISO builders

### Choosing a Builder

Consider these factors when selecting a builder:

- **Target Platform**: Where will the image be deployed?
- **Source Type**: Starting from existing image, ISO, or container?
- **Requirements**: Specific features needed (networking, storage, etc.)
- **Cost**: Cloud resources incur charges during builds
- **Build Time**: Some builders are faster than others

## Common Builder Types

### Cloud Platform Builders

| Builder | Platform | Common Use Cases |
| --- | --- | --- |
| amazon-ebs | AWS | EC2 AMIs, Auto Scaling images |
| amazon-ebssurrogate | AWS | Custom root volumes, encrypted images |
| amazon-instance | AWS | Instance-store backed AMIs |
| azure-arm | Azure | VM images, managed disks |
| googlecompute | GCP | Compute Engine images |
| digitalocean | DigitalOcean | Droplet snapshots |
| oracle-oci | Oracle Cloud | Custom images |

### Virtualization Builders

| Builder | Technology | Common Use Cases |
| --- | --- | --- |
| vmware-iso | VMware | Build from ISO files |
| vmware-vmx | VMware | Modify existing VMs |
| virtualbox-iso | VirtualBox | Build from ISO files |
| virtualbox-ovf | VirtualBox | Modify existing VMs |
| qemu | QEMU/KVM | Linux KVM images |
| hyperv-iso | Hyper-V | Windows Server images |

### Container Builders

| Builder | Technology | Common Use Cases |
| --- | --- | --- |
| docker | Docker | Container images |
| lxc | LXC | System containers |
| lxd | LXD | Ubuntu containers |

## Amazon EC2 Builder

The Amazon EC2 builders create Amazon Machine Images (AMIs) for use with EC2 instances.

### Amazon EC2 Builder Types

#### amazon-ebs

Creates EBS-backed AMIs (most common):

```hcl
source "amazon-ebs" "example" {
  ami_name      = "packer-example-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  
  ssh_username = "ubuntu"
  
  tags = {
    Name        = "PackerBuiltImage"
    Environment = "Development"
  }
}
```

#### amazon-ebssurrogate

Creates AMIs with custom root volumes:

```hcl
source "amazon-ebssurrogate" "example" {
  ami_name               = "packer-custom-root-{{timestamp}}"
  instance_type          = "t2.micro"
  region                 = "us-east-1"
  ssh_username           = "ubuntu"
  
  source_ami = "ami-0c55b159cbfafe1f0"
  
  launch_block_device_mappings {
    device_name           = "/dev/xvdf"
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp3"
  }
  
  ami_root_device {
    source_device_name    = "/dev/xvdf"
    device_name           = "/dev/xvda"
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp3"
  }
}
```

#### amazon-instance

Creates instance-store backed AMIs:

```hcl
source "amazon-instance" "example" {
  ami_name      = "packer-instance-store-{{timestamp}}"
  instance_type = "m3.medium"
  region        = "us-east-1"
  source_ami    = "ami-12345678"
  ssh_username  = "ec2-user"
  
  account_id = "123456789012"
  s3_bucket  = "my-packer-images"
  x509_cert_path      = "/path/to/cert.pem"
  x509_key_path       = "/path/to/key.pem"
  x509_upload_path    = "/tmp"
}
```

### AWS Builder Configuration Options

- **ami_name**: Name for the resulting AMI (must be unique)
- **ami_description**: Description for the AMI
- **instance_type**: EC2 instance type for building
- **region**: AWS region to build in
- **source_ami**: Specific AMI ID to start from
- **source_ami_filter**: Filter to dynamically select source AMI
- **ssh_username**: Username for SSH connection
- **vpc_id**: VPC to launch instance in
- **subnet_id**: Subnet to launch instance in
- **security_group_id**: Security group for the instance
- **iam_instance_profile**: IAM role for the instance
- **tags**: Tags to apply to the AMI
- **snapshot_tags**: Tags to apply to snapshots
- **encrypt_boot**: Encrypt the AMI

### Best Practices

- Use `source_ami_filter` with `most_recent = true` for latest base images
- Include `{{timestamp}}` in AMI names for uniqueness
- Tag AMIs with metadata for tracking
- Use dedicated VPC/subnet for builds
- Enable encryption for sensitive workloads
- Set appropriate volume sizes and types

## Azure Builder

The Azure builder creates managed images and VM images in Microsoft Azure.

### azure-arm Builder

Creates Azure Resource Manager managed images:

```hcl
source "azure-arm" "example" {
  # Authentication
  subscription_id = "00000000-0000-0000-0000-000000000000"
  
  # Image destination
  managed_image_name                = "PackerImage-{{timestamp}}"
  managed_image_resource_group_name = "packer-images-rg"
  
  # Build VM configuration
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
  
  location = "East US"
  vm_size  = "Standard_DS2_v2"
  
  # Azure resources
  build_resource_group_name = "packer-build-rg"
  
  # Networking
  virtual_network_name                = "packer-vnet"
  virtual_network_subnet_name         = "packer-subnet"
  virtual_network_resource_group_name = "packer-network-rg"
  
  # Tags
  azure_tags = {
    environment = "development"
    created_by  = "packer"
  }
}
```

### Authentication Methods

#### Service Principal

```hcl
source "azure-arm" "example" {
  client_id       = "00000000-0000-0000-0000-000000000000"
  client_secret   = "supersecretpassword"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  # ...
}
```

#### Managed Identity

```hcl
source "azure-arm" "example" {
  use_azure_cli_auth = true
  subscription_id    = "00000000-0000-0000-0000-000000000000"
  # ...
}
```

### Azure Builder Configuration Options

- **managed_image_name**: Name for the managed image
- **managed_image_resource_group_name**: Resource group for the image
- **os_type**: Operating system type (Linux or Windows)
- **image_publisher**: Source image publisher
- **image_offer**: Source image offer
- **image_sku**: Source image SKU
- **location**: Azure region
- **vm_size**: VM size for building
- **os_disk_size_gb**: OS disk size
- **azure_tags**: Tags for Azure resources

### Shared Image Gallery

Create images in Shared Image Gallery:

```hcl
source "azure-arm" "example" {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  
  shared_image_gallery_destination {
    subscription         = "00000000-0000-0000-0000-000000000000"
    resource_group       = "shared-images-rg"
    gallery_name         = "MySharedGallery"
    image_name           = "MyImageDefinition"
    image_version        = "1.0.0"
    replication_regions  = ["East US", "West US"]
  }
  
  # Source image
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
  
  location = "East US"
  vm_size  = "Standard_DS2_v2"
}
```

## Google Cloud Builder

The Google Compute builder creates images for Google Cloud Platform.

### googlecompute Builder

```hcl
source "googlecompute" "example" {
  # Project configuration
  project_id = "my-project-id"
  
  # Image configuration
  image_name        = "packer-image-{{timestamp}}"
  image_description = "Built with Packer"
  image_family      = "my-app-images"
  
  # Source image
  source_image_family = "ubuntu-2204-lts"
  
  # Build instance
  zone         = "us-central1-a"
  machine_type = "n1-standard-1"
  disk_size    = 20
  disk_type    = "pd-ssd"
  
  # Networking
  network    = "default"
  subnetwork = "default"
  
  # SSH configuration
  ssh_username = "packer"
  
  # Labels
  labels = {
    environment = "development"
    created_by  = "packer"
  }
}
```

### Authentication

Use service account JSON key:

```hcl
source "googlecompute" "example" {
  account_file = "/path/to/service-account-key.json"
  project_id   = "my-project-id"
  # ...
}
```

Or set environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

### Google Cloud Builder Configuration Options

- **project_id**: GCP project ID
- **image_name**: Name for the resulting image
- **image_family**: Image family for versioning
- **source_image**: Specific source image
- **source_image_family**: Source image family
- **zone**: GCP zone for build instance
- **machine_type**: Instance type
- **disk_size**: Boot disk size in GB
- **network**: VPC network
- **labels**: Resource labels
- **image_licenses**: Licenses for the image

## VMware Builder

VMware builders create virtual machine images for VMware platforms.

### vmware-iso Builder

Builds VM from ISO file:

```hcl
source "vmware-iso" "example" {
  # ISO configuration
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
  iso_checksum = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
  
  # VM configuration
  vm_name       = "ubuntu-22.04"
  guest_os_type = "ubuntu-64"
  
  # Hardware
  memory            = 2048
  cpus              = 2
  disk_size         = 20480
  disk_type_id      = "0"
  network           = "nat"
  network_adapter_type = "vmxnet3"
  
  # Output
  output_directory = "output-vmware"
  
  # SSH configuration
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "30m"
  
  # Boot configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/modelcode=SKIP <wait>",
    "netcfg/get_hostname=ubuntu <wait>",
    "netcfg/get_domain=local <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]
  
  http_directory = "http"
}
```

### vmware-vmx Builder

Modifies existing VMware VM:

```hcl
source "vmware-vmx" "example" {
  source_path = "/path/to/existing/vm.vmx"
  
  # SSH configuration
  ssh_username = "packer"
  ssh_password = "packer"
  
  # Output
  output_directory = "output-vmware-modified"
  
  # Shutdown
  shutdown_command = "sudo shutdown -P now"
}
```

### VMware Builder Configuration Options

- **iso_url**: URL to ISO file
- **iso_checksum**: ISO checksum for verification
- **guest_os_type**: VMware guest OS type
- **memory**: RAM in MB
- **cpus**: Number of CPUs
- **disk_size**: Disk size in MB
- **network_adapter_type**: Network adapter type
- **boot_command**: Commands to automate installation
- **http_directory**: Directory for HTTP server (preseed/kickstart files)

## VirtualBox Builder

VirtualBox builders create virtual machine images for Oracle VirtualBox.

### virtualbox-iso Builder

Builds VM from ISO file:

```hcl
source "virtualbox-iso" "example" {
  # ISO configuration
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
  iso_checksum = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
  
  # VM configuration
  vm_name       = "ubuntu-22.04-vbox"
  guest_os_type = "Ubuntu_64"
  
  # Hardware
  memory = 2048
  cpus   = 2
  
  # Disk
  disk_size         = 20480
  hard_drive_interface = "sata"
  
  # Output
  output_directory = "output-virtualbox"
  format           = "ova"
  
  # SSH configuration
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "30m"
  
  # Boot configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "install preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US.UTF-8 auto locale=en_US.UTF-8 kbd-chooser/method=us ",
    "keyboard-configuration/modelcode=SKIP netcfg/get_hostname=ubuntu ",
    "fb=false debconf/frontend=noninteractive ",
    "<enter><wait>"
  ]
  
  http_directory = "http"
  
  # VirtualBox settings
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--audio", "none"]
  ]
}
```

### virtualbox-ovf Builder

Modifies existing VirtualBox VM:

```hcl
source "virtualbox-ovf" "example" {
  source_path = "/path/to/existing/vm.ovf"
  
  ssh_username = "packer"
  ssh_password = "packer"
  
  output_directory = "output-virtualbox-modified"
  
  shutdown_command = "sudo shutdown -P now"
  
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "4096"]
  ]
}
```

### VirtualBox Builder Configuration Options

- **guest_os_type**: VirtualBox guest OS type
- **format**: Export format (ova, ovf, vdi)
- **hard_drive_interface**: Disk interface (ide, sata, scsi)
- **vboxmanage**: Array of VBoxManage commands
- **vboxmanage_post**: Commands after provisioning
- **guest_additions_mode**: How to handle Guest Additions (upload, attach, disable)

## Docker Builder

The Docker builder creates container images.

### docker Builder

```hcl
source "docker" "example" {
  image  = "ubuntu:22.04"
  commit = true
  
  changes = [
    "USER www-data",
    "WORKDIR /var/www",
    "ENV DEBIAN_FRONTEND=noninteractive",
    "EXPOSE 80",
    "VOLUME /var/www/html",
    "ENTRYPOINT [\"/usr/sbin/apache2\"]",
    "CMD [\"-D\", \"FOREGROUND\"]"
  ]
}

build {
  sources = ["source.docker.example"]
  
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y apache2",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }
  
  post-processor "docker-tag" {
    repository = "myapp"
    tags       = ["latest", "1.0.0"]
  }
}
```

### Key Configuration Options

- **image**: Base Docker image
- **commit**: Commit container to image
- **pull**: Pull base image before building
- **changes**: Dockerfile-like changes to apply
- **run_command**: Override default run command
- **volumes**: Mount volumes during build
- **privileged**: Run container in privileged mode

### Docker Post-Processors

#### docker-tag

Tag the resulting image:

```hcl
post-processor "docker-tag" {
  repository = "myregistry.com/myapp"
  tags       = ["latest", "v1.0.0", "production"]
}
```

#### docker-push

Push image to registry:

```hcl
post-processor "docker-push" {
  login          = true
  login_username = "username"
  login_password = "password"
}
```

#### docker-save

Save image to tar file:

```hcl
post-processor "docker-save" {
  path = "output/myapp.tar"
}
```

## Builder Comparison

| Feature | AWS | Azure | GCP | VMware | VirtualBox | Docker |
| --- | --- | --- | --- | --- | --- | --- |
| Cloud Native | Yes | Yes | Yes | No | No | No |
| On-Premises | No | No | No | Yes | Yes | Yes |
| Build Speed | Fast | Medium | Fast | Slow | Slow | Very Fast |
| Cost | Pay per use | Pay per use | Pay per use | Free | Free | Free |
| Automation | Excellent | Excellent | Excellent | Good | Good | Excellent |
| ISO Support | No | No | No | Yes | Yes | No |

## Next Steps

Now that you understand builders, learn about:

- [Packer Provisioners](packer-provisioners.md) - Configure your images
- [Packer Post-Processors](packer-post-processors.md) - Handle build artifacts
- [Best Practices](packer-best-practices.md) - Professional template development
