---
uid: infrastructure.packer.post-processors
title: Packer Post-Processors
description: Comprehensive guide to Packer post-processors for processing, compressing, uploading, and distributing machine images after builds
ms.date: 01/18/2026
---

This section covers Packer post-processors, which process artifacts after image builds to perform tasks like compression, uploading, creating Vagrant boxes, and generating manifests.

## What are Post-Processors?

Post-processors run after builders and provisioners complete, taking the resulting artifacts (machine images) and performing additional operations on them. Common use cases include:

- **Compressing images** to save storage and transfer time
- **Creating manifests** with build metadata and artifact information
- **Uploading artifacts** to cloud storage or artifact repositories
- **Converting formats** like creating Vagrant boxes from images
- **Checksum generation** for artifact verification
- **Notification sending** about completed builds

### Post-Processor Lifecycle

```text
Build Process Flow:
1. Builder creates base instance
2. Provisioners configure the instance
3. Builder creates image/snapshot
4. Post-processors process the artifact
   - Can chain multiple post-processors
   - Each receives output from previous step
5. Final artifacts stored/distributed
```

### Key Characteristics

- **Sequential execution**: Post-processors run in defined order
- **Chaining support**: Output from one becomes input to next
- **Keep artifacts**: Can preserve intermediate artifacts
- **Error handling**: Failed post-processor stops the chain
- **Conditional execution**: Can run based on build success/failure

## Manifest Post-Processor

The manifest post-processor creates a JSON file containing build metadata and artifact information, useful for tracking builds and automation.

### Basic Configuration

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
```

### Generated Manifest Example

```json
{
  "builds": [
    {
      "name": "amazon-ebs.ubuntu",
      "builder_type": "amazon-ebs",
      "build_time": 1705564800,
      "files": null,
      "artifact_id": "us-east-1:ami-0123456789abcdef0",
      "packer_run_uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "custom_data": {
        "version": "1.0.0",
        "environment": "production"
      }
    }
  ],
  "last_run_uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
}
```

### Advanced Manifest Configuration

```hcl
post-processor "manifest" {
  output = "packer-manifest-${formatdate("YYYYMMDD-hhmm", timestamp())}.json"
  
  # Remove file paths from artifact info
  strip_path = true
  
  # Add custom metadata
  custom_data = {
    version        = var.image_version
    git_commit     = var.git_commit
    git_branch     = var.git_branch
    build_number   = var.build_number
    created_by     = "CI/CD Pipeline"
    base_ami       = build.SourceAMI
    instance_type  = var.instance_type
    environment    = var.environment
    team           = "DevOps"
    cost_center    = "Engineering"
  }
}
```

### Using Manifests in CI/CD

```bash
#!/bin/bash
# Parse manifest and deploy image

MANIFEST_FILE="manifest.json"
AMI_ID=$(jq -r '.builds[0].artifact_id | split(":")[1]' $MANIFEST_FILE)
REGION=$(jq -r '.builds[0].artifact_id | split(":")[0]' $MANIFEST_FILE)
VERSION=$(jq -r '.builds[0].custom_data.version' $MANIFEST_FILE)

echo "Deploying AMI: $AMI_ID in $REGION"
echo "Version: $VERSION"

# Update Terraform variables
cat > terraform.tfvars <<EOF
ami_id = "$AMI_ID"
region = "$REGION"
version = "$VERSION"
EOF

# Deploy with Terraform
terraform apply -auto-approve
```

### Append to Existing Manifest

```hcl
post-processor "manifest" {
  output = "manifest.json"
  
  # Don't overwrite, append to existing manifest
  strip_path = false
  
  # Keep artifact history
  custom_data = {
    timestamp = timestamp()
    builder   = "Packer ${packer.version}"
  }
}
```

## Vagrant Post-Processor

The Vagrant post-processor creates Vagrant boxes from built images, enabling easy distribution and local development environments.

### Creating a Vagrant Box

```hcl
source "virtualbox-iso" "ubuntu" {
  iso_url          = "https://releases.ubuntu.com/22.04/ubuntu-22.04-server-amd64.iso"
  iso_checksum     = "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
  
  guest_os_type    = "Ubuntu_64"
  disk_size        = 40960
  vm_name          = "ubuntu-22.04"
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y virtualbox-guest-utils"
    ]
  }
  
  post-processor "vagrant" {
    output = "builds/ubuntu-22.04-{{.Provider}}.box"
    
    # Compression level (0-9)
    compression_level = 9
    
    # Keep original OVF files
    keep_input_artifact = false
  }
}
```

### Multi-Provider Vagrant Boxes

```hcl
build {
  sources = [
    "source.virtualbox-iso.ubuntu",
    "source.vmware-iso.ubuntu"
  ]
  
  post-processor "vagrant" {
    # Template variables available:
    # {{.Provider}} - virtualbox, vmware, etc.
    # {{.BuildName}} - name from source
    output = "builds/{{.BuildName}}-{{.Provider}}.box"
    
    # Provider-specific overrides
    override = {
      virtualbox = {
        compression_level = 9
        vagrantfile_template = "templates/Vagrantfile.virtualbox"
      }
      vmware = {
        compression_level = 6
        vagrantfile_template = "templates/Vagrantfile.vmware"
      }
    }
  }
}
```

### Vagrant Cloud Upload

```hcl
post-processor "vagrant" {
  output = "builds/ubuntu.box"
}

post-processor "vagrant-cloud" {
  box_tag     = "mycompany/ubuntu-22.04"
  version     = var.box_version
  
  # Vagrant Cloud credentials
  access_token = var.vagrant_cloud_token
  
  # Upload the box
  version_description = "Ubuntu 22.04 with Docker and Kubernetes tools"
  
  # Make public or private
  box_download_url = "https://vagrantcloud.com/mycompany/boxes/ubuntu-22.04"
  
  # Architecture
  architecture = "amd64"
}
```

### Custom Vagrantfile Template

```ruby
# templates/Vagrantfile.template
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-22.04"
  
  # VM settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  
  # Networking
  config.vm.network "private_network", type: "dhcp"
  
  # Synced folders
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
end
```

```hcl
post-processor "vagrant" {
  output               = "ubuntu.box"
  vagrantfile_template = "templates/Vagrantfile.template"
}
```

## Compress Post-Processor

The compress post-processor creates compressed archives of artifacts, useful for reducing storage and transfer costs.

### Basic Compression

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  post-processor "compress" {
    output = "builds/image-{{.BuildName}}.tar.gz"
    
    # Compression algorithm: pgzip, lz4, xz, or bgzf
    compression_level = 9
    
    # Archive format
    format = "tar.gz"
    
    # Don't keep input artifact
    keep_input_artifact = false
  }
}
```

### Compression Formats

```hcl
# gzip compression (good balance of speed and size)
post-processor "compress" {
  output = "image.tar.gz"
  format = "tar.gz"
  compression_level = 6
}

# xz compression (best compression, slower)
post-processor "compress" {
  output = "image.tar.xz"
  format = "tar.xz"
  compression_level = 9
}

# lz4 compression (fastest, larger files)
post-processor "compress" {
  output = "image.tar.lz4"
  format = "tar.lz4"
}

# zip format (Windows compatibility)
post-processor "compress" {
  output = "image.zip"
  format = "zip"
  compression_level = 9
}
```

### Selective Compression

```hcl
post-processor "compress" {
  output = "builds/artifacts-{{timestamp}}.tar.gz"
  
  # Include specific files only
  files = [
    "*.vmdk",
    "*.ovf",
    "manifest.json"
  ]
  
  # Exclude patterns
  # Note: Use keep_input_artifact to control original files
  keep_input_artifact = true
}
```

### Parallel Compression

```hcl
post-processor "compress" {
  output = "image.tar.gz"
  
  # Use pgzip for parallel compression
  format = "tar.gz"
  compression_level = 6
  
  # pgzip uses multiple CPU cores automatically
}
```

## Docker Post-Processors

Packer includes several post-processors for working with Docker images.

### Docker Import

```hcl
source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx"
    ]
  }
  
  post-processor "docker-import" {
    repository = "mycompany/nginx"
    tag        = "1.0.0"
    
    # Additional tags
    tags = [
      "latest",
      "ubuntu-22.04"
    ]
  }
}
```

### Docker Push

```hcl
build {
  sources = ["source.docker.ubuntu"]
  
  # Create the image
  post-processor "docker-tag" {
    repository = "myregistry.com/myapp"
    tags       = ["1.0.0", "latest"]
  }
  
  # Push to registry
  post-processor "docker-push" {
    # Docker registry credentials
    login          = true
    login_username = var.docker_username
    login_password = var.docker_password
    login_server   = "myregistry.com"
  }
}
```

### Docker Save

```hcl
post-processor "docker-save" {
  path = "builds/myapp-{{.BuildName}}.tar"
}
```

### Complete Docker Workflow

```hcl
source "docker" "alpine" {
  image  = "alpine:3.18"
  commit = true
}

build {
  sources = ["source.docker.alpine"]
  
  provisioner "shell" {
    inline = [
      "apk update",
      "apk add --no-cache python3 py3-pip",
      "pip3 install flask gunicorn"
    ]
  }
  
  # Tag the image
  post-processor "docker-tag" {
    repository = "mycompany/flask-app"
    tags = [
      var.app_version,
      "latest"
    ]
    
    keep_input_artifact = true
  }
  
  # Save to tar file for backup
  post-processor "docker-save" {
    path = "builds/flask-app-${var.app_version}.tar"
  }
  
  # Push to Docker Hub
  post-processor "docker-push" {
    login          = true
    login_username = var.dockerhub_username
    login_password = var.dockerhub_password
  }
}
```

## Shell-Local Post-Processor

Execute commands on the local machine after the build completes.

### Basic Usage

```hcl
post-processor "shell-local" {
  inline = [
    "echo 'Build completed successfully'",
    "echo 'AMI ID: ${build.ID}'",
    "echo 'Region: ${build.Region}'"
  ]
}
```

### Upload to S3

```hcl
post-processor "shell-local" {
  inline = [
    "aws s3 cp manifest.json s3://my-bucket/manifests/manifest-${local.timestamp}.json",
    "aws s3 cp packer.log s3://my-bucket/logs/build-${local.timestamp}.log"
  ]
  
  environment_vars = [
    "AWS_DEFAULT_REGION=us-east-1",
    "AMI_ID=${build.ID}"
  ]
}
```

### Notification Integration

```hcl
post-processor "shell-local" {
  script = "scripts/notify-build-complete.sh"
  
  environment_vars = [
    "BUILD_STATUS=success",
    "AMI_ID=${build.ID}",
    "BUILD_TIME=${local.timestamp}",
    "SLACK_WEBHOOK=${var.slack_webhook_url}"
  ]
}
```

```bash
#!/bin/bash
# scripts/notify-build-complete.sh

curl -X POST "$SLACK_WEBHOOK" \
  -H 'Content-Type: application/json' \
  -d "{
    \"text\": \"Packer build completed\",
    \"attachments\": [{
      \"color\": \"good\",
      \"fields\": [
        {\"title\": \"Status\", \"value\": \"$BUILD_STATUS\", \"short\": true},
        {\"title\": \"AMI ID\", \"value\": \"$AMI_ID\", \"short\": true},
        {\"title\": \"Build Time\", \"value\": \"$BUILD_TIME\", \"short\": true}
      ]
    }]
  }"
```

### Update Infrastructure as Code

```hcl
post-processor "shell-local" {
  inline = [
    "cd terraform/",
    "sed -i 's/ami-[0-9a-f]*/ami-${build.ID}/g' variables.tf",
    "git add variables.tf",
    "git commit -m 'Update AMI to ${build.ID}'",
    "git push origin main"
  ]
  
  # Only run on successful build
  only = ["amazon-ebs.ubuntu"]
}
```

## Artifice Post-Processor

The artifice post-processor allows you to override the artifact from previous post-processors, useful for chaining custom workflows.

### Basic Artifice Usage

```hcl
post-processor "compress" {
  output = "image.tar.gz"
}

post-processor "artifice" {
  files = ["image.tar.gz"]
}

post-processor "shell-local" {
  inline = [
    "echo 'Processing ${build.ID}'",
    "md5sum image.tar.gz > image.tar.gz.md5"
  ]
}
```

### Custom Artifact Pipeline

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Create manifest
  post-processor "manifest" {
    output = "manifest.json"
  }
  
  # Override artifact to manifest file
  post-processor "artifice" {
    files = ["manifest.json"]
  }
  
  # Upload manifest to S3
  post-processor "shell-local" {
    inline = [
      "aws s3 cp manifest.json s3://my-bucket/manifests/${var.version}/manifest.json"
    ]
  }
}
```

## Checksum Post-Processor

Generate checksums for artifacts to verify integrity.

### Basic Checksum Generation

```hcl
post-processor "checksum" {
  checksum_types = ["md5", "sha256", "sha512"]
  output         = "builds/{{.BuildName}}_{{.ChecksumType}}.checksum"
  
  # Keep the original artifact
  keep_input_artifact = true
}
```

### Example Output

```text
# ubuntu_sha256.checksum
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ubuntu-22.04.tar.gz
```

### Verify Checksums

```bash
#!/bin/bash
# Verify artifact integrity

ARTIFACT="ubuntu-22.04.tar.gz"
EXPECTED=$(cat ubuntu_sha256.checksum | awk '{print $1}')
ACTUAL=$(sha256sum $ARTIFACT | awk '{print $1}')

if [ "$EXPECTED" = "$ACTUAL" ]; then
  echo "Checksum verification passed"
  exit 0
else
  echo "Checksum verification failed!"
  exit 1
fi
```

## Chaining Post-Processors

Chain multiple post-processors to create complex workflows.

### Sequential Processing

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Post-processors run in sequence
  post-processors {
    # Step 1: Create manifest
    post-processor "manifest" {
      output = "manifest.json"
      custom_data = {
        version = var.image_version
      }
    }
    
    # Step 2: Compress artifacts
    post-processor "compress" {
      output = "builds/image-${var.image_version}.tar.gz"
    }
    
    # Step 3: Generate checksum
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "builds/image-${var.image_version}.sha256"
    }
    
    # Step 4: Upload to S3
    post-processor "shell-local" {
      inline = [
        "aws s3 sync builds/ s3://my-bucket/images/${var.image_version}/"
      ]
    }
  }
}
```

### Keep Intermediate Artifacts

```hcl
post-processors {
  post-processor "compress" {
    output              = "image.tar.gz"
    keep_input_artifact = true  # Keep original image
  }
  
  post-processor "checksum" {
    checksum_types      = ["sha256"]
    keep_input_artifact = true  # Keep compressed file
  }
  
  post-processor "shell-local" {
    inline = [
      "echo 'All artifacts preserved for distribution'"
    ]
  }
}
```

### Parallel Post-Processing

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # First post-processor chain
  post-processors {
    post-processor "vagrant" {
      output = "ubuntu.box"
    }
    
    post-processor "vagrant-cloud" {
      box_tag = "mycompany/ubuntu"
      version = var.box_version
    }
  }
  
  # Second independent post-processor chain
  post-processors {
    post-processor "compress" {
      output = "ubuntu.tar.gz"
    }
    
    post-processor "shell-local" {
      inline = [
        "aws s3 cp ubuntu.tar.gz s3://my-bucket/archives/"
      ]
    }
  }
}
```

### Conditional Post-Processing

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Production workflow
  post-processors {
    post-processor "manifest" {
      output = "prod-manifest.json"
      only   = ["amazon-ebs.ubuntu"]
    }
    
    post-processor "shell-local" {
      inline = [
        "aws s3 cp prod-manifest.json s3://prod-bucket/manifests/"
      ]
      only = ["amazon-ebs.ubuntu"]
    }
  }
  
  # Development workflow
  post-processors {
    post-processor "manifest" {
      output = "dev-manifest.json"
      except = ["amazon-ebs.ubuntu"]
    }
  }
}
```

## Advanced Patterns

### Complete CI/CD Integration

```hcl
locals {
  timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
  version   = var.image_version
}

build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  post-processors {
    # Generate manifest with metadata
    post-processor "manifest" {
      output = "manifest-${local.version}.json"
      custom_data = {
        version      = local.version
        git_commit   = var.git_commit
        git_branch   = var.git_branch
        build_number = var.build_number
        build_date   = local.timestamp
      }
    }
    
    # Generate checksums for verification
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "ami-${local.version}.sha256"
    }
    
    # Upload to artifact repository
    post-processor "shell-local" {
      inline = [
        "aws s3 cp manifest-${local.version}.json s3://artifacts/manifests/",
        "aws s3 cp ami-${local.version}.sha256 s3://artifacts/checksums/",
        
        # Update parameter store
        "aws ssm put-parameter --name '/ami/latest' --value '${build.ID}' --overwrite",
        "aws ssm put-parameter --name '/ami/version' --value '${local.version}' --overwrite"
      ]
    }
    
    # Send notification
    post-processor "shell-local" {
      script = "scripts/notify-teams.sh"
      environment_vars = [
        "AMI_ID=${build.ID}",
        "VERSION=${local.version}",
        "WEBHOOK_URL=${var.teams_webhook}"
      ]
    }
  }
}
```

### Multi-Region Deployment

```hcl
post-processors {
  post-processor "manifest" {
    output = "manifest.json"
  }
  
  post-processor "shell-local" {
    inline = [
      "AMI_ID=${build.ID}",
      "SOURCE_REGION=${build.Region}",
      
      # Copy to additional regions
      "aws ec2 copy-image --source-region $SOURCE_REGION --source-image-id $AMI_ID --region us-west-2 --name ${var.ami_name}",
      "aws ec2 copy-image --source-region $SOURCE_REGION --source-image-id $AMI_ID --region eu-west-1 --name ${var.ami_name}",
      "aws ec2 copy-image --source-region $SOURCE_REGION --source-image-id $AMI_ID --region ap-southeast-1 --name ${var.ami_name}"
    ]
  }
}
```

## Summary

Post-processors provide powerful capabilities for:

- **Artifact management**: Compressing, archiving, and organizing build outputs
- **Distribution**: Uploading to cloud storage, registries, and repositories
- **Integration**: Connecting with CI/CD pipelines and automation tools
- **Documentation**: Generating manifests and metadata for tracking
- **Verification**: Creating checksums and validation artifacts
- **Notification**: Alerting teams about build completion and status

Key best practices:

- **Chain logically**: Order post-processors by dependency
- **Preserve artifacts**: Use `keep_input_artifact` when needed
- **Error handling**: Plan for failures in the chain
- **Security**: Protect credentials used in post-processors
- **Automation**: Integrate with existing tools and workflows
- **Documentation**: Record what each post-processor does and why

Post-processors transform Packer from a build tool into a complete image management and distribution platform
