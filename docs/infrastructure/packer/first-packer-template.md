---
uid: infrastructure.packer.first-template
title: Creating Your First Packer Template
description: Step-by-step tutorial for creating and running your first Packer template to build machine images
ms.date: 01/18/2026
---

This section walks through creating your first Packer template to build a simple machine image.

## Understanding Template Structure

Packer templates define the entire image build process. Modern Packer templates use HCL2 (HashiCorp Configuration Language), which provides better structure, validation, and features compared to legacy JSON templates.

### Template Components

A Packer template consists of:

- **Packer Block**: Specifies required Packer version and plugins
- **Source Blocks**: Define the builder configuration and base image
- **Build Blocks**: Orchestrate the build process
- **Variable Blocks**: Allow parameterization
- **Locals Blocks**: Define computed values
- **Provisioner Blocks**: Configure the image
- **Post-Processor Blocks**: Handle artifacts after build

### Template File Extensions

- `.pkr.hcl` - HCL2 template (recommended)
- `.json` - Legacy JSON template (deprecated)

## Creating a Basic Template

Let's create a simple template to build an Amazon Linux 2 AMI with basic configuration.

### Step 1: Create Template File

Create a file named `aws-amazon-linux.pkr.hcl`:

```hcl
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.0"
    }
  }
}

source "amazon-ebs" "amazon-linux" {
  ami_name      = "my-first-packer-image-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  name = "amazon-linux-build"
  sources = [
    "source.amazon-ebs.amazon-linux"
  ]

  provisioner "shell" {
    inline = [
      "echo 'Hello from Packer!'",
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl enable httpd"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

### Step 2: Understanding the Template

#### Packer Block

```hcl
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.0"
    }
  }
}
```

Declares required plugins and their versions. Packer will automatically download them.

#### Source Block

```hcl
source "amazon-ebs" "amazon-linux" {
  ami_name      = "my-first-packer-image-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  # ...
}
```

Defines the builder type (`amazon-ebs`) and configuration:

- `ami_name`: Name for the resulting AMI (timestamp ensures uniqueness)
- `instance_type`: EC2 instance type for building
- `region`: AWS region
- `source_ami_filter`: Selects the base AMI

#### Build Block

```hcl
build {
  name = "amazon-linux-build"
  sources = ["source.amazon-ebs.amazon-linux"]
  # provisioners and post-processors
}
```

Orchestrates the build process by combining sources, provisioners, and post-processors.

## Template Variables

Variables make templates reusable and configurable. Let's enhance our template with variables.

### Adding Variables

Create `variables.pkr.hcl`:

```hcl
variable "aws_region" {
  type        = string
  description = "AWS region to build in"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for AMI name"
  default     = "my-packer-image"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}
```

### Using Variables in Template

Update `aws-amazon-linux.pkr.hcl`:

```hcl
source "amazon-ebs" "amazon-linux" {
  ami_name      = "${var.ami_name_prefix}-${var.environment}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  ssh_username = "ec2-user"
  
  tags = {
    Name        = "${var.ami_name_prefix}-${var.environment}"
    Environment = var.environment
    Created_by  = "Packer"
    Timestamp   = "{{timestamp}}"
  }
}
```

### Variable Input Methods

You can provide variable values through:

1. **Command line**:

   ```bash
   packer build -var="aws_region=us-west-2" -var="environment=prod" .
   ```

2. **Variable file** (`terraform.auto.pkrvars.hcl`):

   ```hcl
   aws_region      = "us-west-2"
   instance_type   = "t2.small"
   ami_name_prefix = "production-app"
   environment     = "prod"
   ```

3. **Environment variables**:

   ```bash
   export PKR_VAR_aws_region="us-west-2"
   export PKR_VAR_environment="prod"
   ```

## Validating Templates

Before building, always validate your template to catch syntax and configuration errors.

### Template Validation

```bash
packer validate .
```

Expected output:

```text
The configuration is valid.
```

### Common Validation Errors

#### Missing Required Fields

```text
Error: Missing required argument
```

Solution: Add the missing required field to your configuration.

#### Invalid Variable Type

```text
Error: Invalid value for variable
```

Solution: Ensure variable values match the declared type.

#### Plugin Not Found

```text
Error: Could not load plugin
```

Solution: Run `packer init` to download required plugins.

### Format Template

Format your template to follow HCL style conventions:

```bash
packer fmt .
```

This automatically formats all `.pkr.hcl` files in the directory.

## Running Your First Build

Now let's build the image!

### Step 1: Initialize Packer

Download required plugins:

```bash
packer init .
```

Output:

```text
Installed plugin github.com/hashicorp/amazon v1.2.1 in...
```

### Step 2: Validate Template

```bash
packer validate .
```

### Step 3: Run the Build

```bash
packer build .
```

### Build Process

Packer will:

1. **Initialize**: Set up the build environment
2. **Launch**: Create a temporary EC2 instance
3. **Provision**: Execute provisioning steps
4. **Create AMI**: Snapshot the configured instance
5. **Cleanup**: Terminate the temporary instance
6. **Output**: Display the new AMI ID

### Expected Output

```text
amazon-ebs.amazon-linux: output will be in this color.

==> amazon-ebs.amazon-linux: Prevalidating any provided VPC information
==> amazon-ebs.amazon-linux: Prevalidating AMI Name: my-first-packer-image-1642512345
==> amazon-ebs.amazon-linux: Creating temporary keypair: packer_63c1f2a1
==> amazon-ebs.amazon-linux: Creating temporary security group for this instance: packer_63c1f2a3
==> amazon-ebs.amazon-linux: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.amazon-linux: Launching a source AWS instance...
==> amazon-ebs.amazon-linux: Adding tags to source instance
==> amazon-ebs.amazon-linux: Waiting for instance (i-0abcd1234) to become ready...
==> amazon-ebs.amazon-linux: Using ssh communicator to connect: 1.2.3.4
==> amazon-ebs.amazon-linux: Waiting for SSH to become available...
==> amazon-ebs.amazon-linux: Connected to SSH!
==> amazon-ebs.amazon-linux: Provisioning with shell script: /tmp/packer-shell123
    amazon-ebs.amazon-linux: Hello from Packer!
    amazon-ebs.amazon-linux: Loaded plugins: langpacks, priorities, update-motd
    amazon-ebs.amazon-linux: No packages marked for update
    amazon-ebs.amazon-linux: Package httpd-2.4.54 already installed
==> amazon-ebs.amazon-linux: Stopping the source instance...
==> amazon-ebs.amazon-linux: Waiting for the instance to stop...
==> amazon-ebs.amazon-linux: Creating AMI my-first-packer-image-1642512345 from instance i-0abcd1234
==> amazon-ebs.amazon-linux: Waiting for AMI to become ready...
==> amazon-ebs.amazon-linux: Terminating the source AWS instance...
==> amazon-ebs.amazon-linux: Cleaning up any extra volumes...
==> amazon-ebs.amazon-linux: No volumes to clean up, skipping
==> amazon-ebs.amazon-linux: Deleting temporary security group...
==> amazon-ebs.amazon-linux: Deleting temporary keypair...
Build 'amazon-ebs.amazon-linux' finished after 5 minutes 23 seconds.

==> Wait completed after 5 minutes 23 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.amazon-linux: AMIs were created:
us-east-1: ami-0123456789abcdef0
```

### Step 4: Verify the Image

Check the manifest file:

```bash
cat manifest.json
```

Verify in AWS Console or CLI:

```bash
aws ec2 describe-images --image-ids ami-0123456789abcdef0
```

## Additional Build Options

### Debug Mode

Run with debug output for troubleshooting:

```bash
packer build -debug .
```

Debug mode pauses between steps, allowing inspection.

### Specific Builds

If your template has multiple builds:

```bash
packer build -only='amazon-ebs.amazon-linux' .
```

### Parallel Builds

Build multiple targets simultaneously:

```bash
packer build -parallel-builds=2 .
```

### Force Build

Overwrite existing images:

```bash
packer build -force .
```

## Best Practices for First Templates

1. **Start Simple**: Begin with minimal configuration and add complexity gradually
2. **Use Variables**: Parameterize values that might change
3. **Validate Often**: Run `packer validate` frequently during development
4. **Version Control**: Store templates in Git from the start
5. **Document**: Add comments explaining complex configurations
6. **Test Incrementally**: Test each provisioner step individually
7. **Use Manifest**: Include manifest post-processor to track artifacts

## Troubleshooting Common Issues

### Authentication Errors

Ensure AWS credentials are configured:

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

Or use AWS CLI configuration:

```bash
aws configure
```

### SSH Timeout

If SSH connection fails:

- Check security group allows SSH (port 22)
- Verify correct SSH username for AMI
- Ensure VPC has internet gateway (if using public subnet)

### AMI Already Exists

If AMI name conflict occurs:

- Use `{{timestamp}}` in AMI name for uniqueness
- Use `-force` flag to overwrite
- Clean up old AMIs manually

## Next Steps

Congratulations! You've created and run your first Packer template. Next, learn about:

- [Packer Builders](packer-builders.md) - Explore different builder types
- [Packer Provisioners](packer-provisioners.md) - Advanced image configuration
- [Best Practices](packer-best-practices.md) - Professional template development
