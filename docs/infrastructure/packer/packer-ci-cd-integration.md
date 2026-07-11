---
uid: infrastructure.packer.ci-cd-integration
title: Integrating Packer with CI/CD Pipelines
description: Complete guide to integrating Packer into CI/CD workflows with GitHub Actions, Azure DevOps, Jenkins, GitLab CI, automated testing, and image versioning strategies
ms.date: 01/18/2026
---

This section covers integration of Packer builds into CI/CD workflows, enabling automated, consistent, and repeatable machine image creation as part of your deployment pipeline.

## Overview

### Benefits of CI/CD Integration

Integrating Packer into CI/CD pipelines provides:

- **Automation**: Eliminate manual image building processes
- **Consistency**: Every image built from the same source is identical
- **Traceability**: Track which code commits produced which images
- **Validation**: Automated testing ensures image quality
- **Speed**: Parallel builds reduce time to deployment
- **Governance**: Enforce policies and standards automatically
- **Versioning**: Systematic image version management

### CI/CD Integration Patterns

```text
Common Integration Workflow:
1. Code commit triggers pipeline
2. Validate Packer templates
3. Build images in parallel
4. Run automated tests on images
5. Tag and version images
6. Store artifacts and manifests
7. Deploy to target environments
8. Send notifications
```

### Pipeline Requirements

- **Credentials Management**: Secure storage of cloud provider credentials
- **Artifact Storage**: Repository for manifests and logs
- **Testing Infrastructure**: Environment for image validation
- **Notification System**: Alert team of build status
- **Version Control**: Integration with Git workflows

## GitHub Actions Integration

GitHub Actions provides powerful, flexible CI/CD automation directly integrated with GitHub repositories.

### Basic Packer Workflow

```yaml
# .github/workflows/packer.yml
name: Packer Build

on:
  push:
    branches:
      - main
    paths:
      - 'packer/**'
      - '.github/workflows/packer.yml'
  pull_request:
    branches:
      - main

env:
  PACKER_VERSION: "1.10.0"

jobs:
  validate:
    name: Validate Templates
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Initialize Packer
        run: |
          cd packer
          packer init .

      - name: Validate templates
        run: |
          cd packer
          packer validate -var-file=variables/prod.pkrvars.hcl template.pkr.hcl

      - name: Format check
        run: |
          cd packer
          packer fmt -check -recursive .

  build:
    name: Build Images
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Build images
        run: |
          cd packer
          packer init .
          packer build \
            -var-file=variables/prod.pkrvars.hcl \
            -var="git_commit=${{ github.sha }}" \
            -var="git_branch=${{ github.ref_name }}" \
            -var="build_number=${{ github.run_number }}" \
            template.pkr.hcl

      - name: Upload manifest
        uses: actions/upload-artifact@v3
        with:
          name: packer-manifest
          path: packer/manifest.json

      - name: Comment PR with AMI ID
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const manifest = JSON.parse(fs.readFileSync('packer/manifest.json', 'utf8'));
            const amiId = manifest.builds[0].artifact_id.split(':')[1];
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ Packer build successful!\n\nAMI ID: \`${amiId}\``
            });
```

### Multi-Environment Workflow

```yaml
# .github/workflows/packer-multi-env.yml
name: Multi-Environment Packer Build

on:
  push:
    branches:
      - main
      - develop

jobs:
  build:
    name: Build ${{ matrix.environment }} Images
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, production]
        include:
          - environment: dev
            aws_region: us-east-1
            instance_type: t3.micro
          - environment: staging
            aws_region: us-west-2
            instance_type: t3.small
          - environment: production
            aws_region: us-east-1
            instance_type: t3.medium

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Packer
        uses: hashicorp/setup-packer@main

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets[format('AWS_ACCESS_KEY_ID_{0}', matrix.environment)] }}
          aws-secret-access-key: ${{ secrets[format('AWS_SECRET_ACCESS_KEY_{0}', matrix.environment)] }}
          aws-region: ${{ matrix.aws_region }}

      - name: Build image
        run: |
          packer init packer/
          packer build \
            -var="environment=${{ matrix.environment }}" \
            -var="aws_region=${{ matrix.aws_region }}" \
            -var="instance_type=${{ matrix.instance_type }}" \
            packer/template.pkr.hcl

      - name: Store manifest
        run: |
          aws s3 cp packer/manifest.json \
            s3://my-artifacts/packer/${{ matrix.environment }}/manifest-${{ github.sha }}.json
```

### Scheduled Builds

```yaml
# .github/workflows/packer-scheduled.yml
name: Scheduled Image Updates

on:
  schedule:
    # Run every Sunday at 2 AM UTC
    - cron: '0 2 * * 0'
  workflow_dispatch:  # Allow manual trigger

jobs:
  build-weekly:
    name: Weekly Security Updates
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Packer
        uses: hashicorp/setup-packer@main

      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Build updated images
        run: |
          packer init packer/
          packer build \
            -var="image_version=$(date +%Y.%m.%d)" \
            -var="build_type=scheduled" \
            packer/template.pkr.hcl

      - name: Notify team
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Weekly Packer build completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()
```

## Azure DevOps Integration

Azure DevOps provides comprehensive CI/CD capabilities with Azure Pipelines.

### Basic Azure Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - packer/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  PACKER_VERSION: '1.10.0'

stages:
  - stage: Validate
    displayName: 'Validate Packer Templates'
    jobs:
      - job: ValidateTemplates
        displayName: 'Validate and Format Check'
        steps:
          - task: PackerTool@0
            inputs:
              version: $(PACKER_VERSION)

          - script: |
              cd packer
              packer init .
              packer validate -var-file=variables/prod.pkrvars.hcl template.pkr.hcl
            displayName: 'Validate templates'

          - script: |
              cd packer
              packer fmt -check -recursive .
            displayName: 'Format check'

  - stage: Build
    displayName: 'Build Images'
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: BuildAMI
        displayName: 'Build Amazon AMI'
        steps:
          - task: PackerTool@0
            inputs:
              version: $(PACKER_VERSION)

          - task: AzureCLI@2
            displayName: 'Configure AWS Credentials'
            inputs:
              azureSubscription: 'MyAzureSubscription'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Retrieve credentials from Key Vault
                AWS_ACCESS_KEY=$(az keyvault secret show --name aws-access-key --vault-name my-keyvault --query value -o tsv)
                AWS_SECRET_KEY=$(az keyvault secret show --name aws-secret-key --vault-name my-keyvault --query value -o tsv)
                
                echo "##vso[task.setvariable variable=AWS_ACCESS_KEY_ID;issecret=true]$AWS_ACCESS_KEY"
                echo "##vso[task.setvariable variable=AWS_SECRET_ACCESS_KEY;issecret=true]$AWS_SECRET_KEY"

          - script: |
              cd packer
              packer init .
              packer build \
                -var-file=variables/prod.pkrvars.hcl \
                -var="git_commit=$(Build.SourceVersion)" \
                -var="build_number=$(Build.BuildNumber)" \
                template.pkr.hcl
            displayName: 'Build image'
            env:
              AWS_ACCESS_KEY_ID: $(AWS_ACCESS_KEY_ID)
              AWS_SECRET_ACCESS_KEY: $(AWS_SECRET_ACCESS_KEY)

          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'packer/manifest.json'
              artifactName: 'packer-manifest'
            displayName: 'Publish manifest'
```

### Multi-Stage with Approval

```yaml
# azure-pipelines-approval.yml
stages:
  - stage: Build
    displayName: 'Build Images'
    jobs:
      - job: BuildImages
        steps:
          - script: |
              packer build packer/template.pkr.hcl
            displayName: 'Build test images'

          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'packer/manifest.json'
              artifactName: 'packer-manifest'

  - stage: TestImages
    displayName: 'Test Images'
    dependsOn: Build
    jobs:
      - job: RunTests
        steps:
          - script: |
              # Run automated tests
              ./scripts/test-ami.sh
            displayName: 'Test AMI'

  - stage: PromoteToProduction
    displayName: 'Promote to Production'
    dependsOn: TestImages
    condition: succeeded()
    jobs:
      - deployment: PromoteImages
        displayName: 'Promote Images'
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: |
                    # Tag AMI for production
                    aws ec2 create-tags \
                      --resources $(AMI_ID) \
                      --tags Key=Environment,Value=production \
                             Key=Promoted,Value=true
                  displayName: 'Tag production AMI'
```

## Jenkins Integration

Jenkins provides flexible, plugin-based CI/CD automation.

### Jenkinsfile Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment'
        )
        string(
            name: 'IMAGE_VERSION',
            defaultValue: '1.0.0',
            description: 'Image version'
        )
    }
    
    environment {
        PACKER_VERSION = '1.10.0'
        AWS_DEFAULT_REGION = 'us-east-1'
        PACKER_HOME = "${WORKSPACE}/packer"
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Install Packer
                    sh '''
                        wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
                        unzip packer_${PACKER_VERSION}_linux_amd64.zip
                        chmod +x packer
                        ./packer version
                    '''
                }
            }
        }
        
        stage('Validate') {
            steps {
                dir('packer') {
                    sh '''
                        ../packer init .
                        ../packer validate \
                            -var-file=variables/${ENVIRONMENT}.pkrvars.hcl \
                            template.pkr.hcl
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('packer') {
                        sh """
                            ../packer build \
                                -var-file=variables/\${ENVIRONMENT}.pkrvars.hcl \
                                -var='image_version=\${IMAGE_VERSION}' \
                                -var='git_commit=\${GIT_COMMIT}' \
                                -var='build_number=\${BUILD_NUMBER}' \
                                template.pkr.hcl
                        """
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    def manifest = readJSON file: 'packer/manifest.json'
                    def amiId = manifest.builds[0].artifact_id.split(':')[1]
                    
                    sh """
                        ./scripts/test-ami.sh ${amiId}
                    """
                }
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'packer/manifest.json', fingerprint: true
                
                script {
                    def manifest = readJSON file: 'packer/manifest.json'
                    def amiId = manifest.builds[0].artifact_id.split(':')[1]
                    
                    currentBuild.description = "AMI: ${amiId}"
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: "Packer build successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Packer build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            )
        }
        always {
            cleanWs()
        }
    }
}
```

### Multibranch Pipeline

```groovy
// Jenkinsfile.multibranch
@Library('shared-library') _

pipeline {
    agent any
    
    environment {
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'dev'}"
    }
    
    stages {
        stage('Validate') {
            steps {
                validatePackerTemplate()
            }
        }
        
        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                buildPackerImage(
                    environment: env.ENVIRONMENT,
                    varFile: "variables/${env.ENVIRONMENT}.pkrvars.hcl"
                )
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                deployImage(environment: 'production')
            }
        }
    }
}
```

## GitLab CI/CD Integration

GitLab CI/CD provides integrated DevOps capabilities within GitLab.

### Basic GitLab CI Configuration

```yaml
# .gitlab-ci.yml
variables:
  PACKER_VERSION: "1.10.0"
  AWS_DEFAULT_REGION: "us-east-1"

stages:
  - validate
  - build
  - test
  - deploy

before_script:
  - apt-get update -qq
  - apt-get install -y wget unzip
  - wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
  - unzip packer_${PACKER_VERSION}_linux_amd64.zip
  - chmod +x packer
  - mv packer /usr/local/bin/
  - packer version

validate:
  stage: validate
  script:
    - cd packer
    - packer init .
    - packer validate -var-file=variables/prod.pkrvars.hcl template.pkr.hcl
    - packer fmt -check -recursive .
  only:
    changes:
      - packer/**/*

build:dev:
  stage: build
  script:
    - cd packer
    - packer init .
    - packer build
        -var-file=variables/dev.pkrvars.hcl
        -var="git_commit=$CI_COMMIT_SHA"
        -var="build_number=$CI_PIPELINE_ID"
        template.pkr.hcl
  artifacts:
    paths:
      - packer/manifest.json
    expire_in: 1 week
  only:
    - develop
  except:
    - main

build:production:
  stage: build
  script:
    - cd packer
    - packer init .
    - packer build
        -var-file=variables/prod.pkrvars.hcl
        -var="git_commit=$CI_COMMIT_SHA"
        -var="build_number=$CI_PIPELINE_ID"
        template.pkr.hcl
  artifacts:
    paths:
      - packer/manifest.json
    expire_in: 1 month
  only:
    - main

test:image:
  stage: test
  script:
    - AMI_ID=$(jq -r '.builds[0].artifact_id' packer/manifest.json | cut -d':' -f2)
    - echo "Testing AMI $AMI_ID"
    - ./scripts/test-ami.sh $AMI_ID
  dependencies:
    - build:production

deploy:production:
  stage: deploy
  script:
    - AMI_ID=$(jq -r '.builds[0].artifact_id' packer/manifest.json | cut -d':' -f2)
    - echo "Deploying AMI $AMI_ID to production"
    - cd terraform
    - terraform init
    - terraform apply -var="ami_id=$AMI_ID" -auto-approve
  dependencies:
    - build:production
  when: manual
  only:
    - main
  environment:
    name: production
```

### Multi-Region Build

```yaml
# .gitlab-ci.yml
.build_template: &build_definition
  stage: build
  script:
    - cd packer
    - packer init .
    - packer build
        -var-file=variables/prod.pkrvars.hcl
        -var="aws_region=$AWS_REGION"
        -var="git_commit=$CI_COMMIT_SHA"
        template.pkr.hcl
  artifacts:
    paths:
      - packer/manifest-$AWS_REGION.json
    expire_in: 1 month

build:us-east-1:
  <<: *build_definition
  variables:
    AWS_REGION: "us-east-1"

build:us-west-2:
  <<: *build_definition
  variables:
    AWS_REGION: "us-west-2"

build:eu-west-1:
  <<: *build_definition
  variables:
    AWS_REGION: "eu-west-1"
```

## Automated Testing

Implement automated testing to validate images before deployment.

### Test Script Example

```bash
#!/bin/bash
# scripts/test-ami.sh

set -e

AMI_ID=$1
REGION=${2:-us-east-1}

echo "Testing AMI: $AMI_ID in region $REGION"

# Launch test instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --region "$REGION" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=packer-test},{Key=Purpose,Value=testing}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Launched test instance: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

echo "Instance is running"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Public IP: $PUBLIC_IP"

# Wait for SSH to be available
echo "Waiting for SSH..."
for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@"$PUBLIC_IP" 'exit' 2>/dev/null; then
        echo "SSH is available"
        break
    fi
    sleep 10
done

# Run tests
echo "Running tests..."

# Test 1: Check required packages
ssh ubuntu@"$PUBLIC_IP" 'command -v nginx' || {
    echo "ERROR: nginx not installed"
    exit 1
}

# Test 2: Check services
ssh ubuntu@"$PUBLIC_IP" 'systemctl is-enabled nginx' || {
    echo "ERROR: nginx not enabled"
    exit 1
}

# Test 3: Check security configurations
ssh ubuntu@"$PUBLIC_IP" 'sudo ufw status' | grep -q "Status: active" || {
    echo "ERROR: firewall not active"
    exit 1
}

echo "All tests passed!"

# Cleanup
echo "Terminating test instance..."
aws ec2 terminate-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

echo "Test completed successfully"
```

### Automated Testing with Terratest

```go
// test/ami_test.go
package test

import (
    "testing"
    "time"

    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/packer"
    "github.com/gruntwork-io/terratest/modules/ssh"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestPackerAMI(t *testing.T) {
    t.Parallel()

    // Build the AMI
    packerOptions := &packer.Options{
        Template: "../packer/template.pkr.hcl",
        Vars: map[string]string{
            "aws_region": "us-east-1",
        },
    }

    amiID := packer.BuildArtifact(t, packerOptions)

    // Test the AMI
    awsRegion := "us-east-1"
    keyPair := aws.CreateAndImportEC2KeyPair(t, awsRegion, "test-keypair")
    defer aws.DeleteEC2KeyPair(t, keyPair)

    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform",
        Vars: map[string]interface{}{
            "ami_id":     amiID,
            "key_name":   keyPair.Name,
            "aws_region": awsRegion,
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    instanceIP := terraform.Output(t, terraformOptions, "public_ip")
    host := ssh.Host{
        Hostname:    instanceIP,
        SshUserName: "ubuntu",
        SshKeyPair:  keyPair.KeyPair,
    }

    // Wait for instance to be ready
    maxRetries := 30
    timeBetweenRetries := 10 * time.Second

    // Test nginx is installed
    ssh.CheckSshCommandE(t, host, "command -v nginx")

    // Test nginx is running
    output := ssh.CheckSshCommand(t, host, "systemctl is-active nginx")
    assert.Equal(t, "active", output)

    // Test HTTP response
    time.Sleep(5 * time.Second)
    http_helper.HttpGetWithRetry(
        t,
        "http://"+instanceIP,
        nil,
        200,
        "nginx",
        maxRetries,
        timeBetweenRetries,
    )
}
```

### Integration with Packer

```hcl
# Include test validation in build
build {
    sources = ["source.amazon-ebs.ubuntu"]

    provisioner "shell" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y nginx"
        ]
    }

    # Run inline tests
    provisioner "shell" {
        inline = [
            "command -v nginx || exit 1",
            "systemctl is-enabled nginx || exit 1",
            "nginx -t || exit 1"
        ]
    }

    post-processor "manifest" {
        output = "manifest.json"
    }

    # Run external test script
    post-processor "shell-local" {
        inline = [
            "AMI_ID=$(jq -r '.builds[0].artifact_id' manifest.json | cut -d':' -f2)",
            "./scripts/test-ami.sh $AMI_ID"
        ]
    }
}
```

## Image Versioning

Implement systematic versioning strategies for machine images.

### Semantic Versioning

```hcl
# Semantic versioning: MAJOR.MINOR.PATCH
locals {
    version_major = "1"
    version_minor = "2"
    version_patch = "3"
    version       = "${local.version_major}.${local.version_minor}.${local.version_patch}"
    timestamp     = formatdate("YYYYMMDD-hhmm", timestamp())
    
    ami_name = "${var.project}-${local.version}-${local.timestamp}"
}

source "amazon-ebs" "versioned" {
    ami_name = local.ami_name
    
    tags = {
        Name         = local.ami_name
        Version      = local.version
        VersionMajor = local.version_major
        VersionMinor = local.version_minor
        VersionPatch = local.version_patch
        BuildDate    = local.timestamp
    }
}
```

### Git-Based Versioning

```hcl
# Use git commit and tags for versioning
variable "git_commit" {
    type        = string
    description = "Git commit SHA"
    default     = env("CI_COMMIT_SHA")
}

variable "git_tag" {
    type        = string
    description = "Git tag"
    default     = env("CI_COMMIT_TAG")
}

locals {
    # Use git tag if available, otherwise use commit SHA
    version = var.git_tag != "" ? var.git_tag : substr(var.git_commit, 0, 8)
    
    ami_name = "${var.project}-${local.version}"
}

source "amazon-ebs" "git-versioned" {
    ami_name = local.ami_name
    
    tags = {
        Name       = local.ami_name
        Version    = local.version
        GitCommit  = var.git_commit
        GitTag     = var.git_tag
        Repository = var.git_repository
    }
}
```

### CalVer (Calendar Versioning)

```hcl
# Calendar-based versioning: YYYY.MM.DD.BUILD
locals {
    year  = formatdate("YYYY", timestamp())
    month = formatdate("MM", timestamp())
    day   = formatdate("DD", timestamp())
    
    version = "${local.year}.${local.month}.${local.day}.${var.build_number}"
    
    ami_name = "${var.project}-${local.version}"
}

source "amazon-ebs" "calver" {
    ami_name = local.ami_name
    
    tags = {
        Name        = local.ami_name
        Version     = local.version
        BuildDate   = formatdate("YYYY-MM-DD", timestamp())
        BuildNumber = var.build_number
    }
}
```

### Version Management Script

```bash
#!/bin/bash
# scripts/manage-versions.sh

ACTION=$1
VERSION=$2

case $ACTION in
    list)
        # List all AMI versions
        aws ec2 describe-images \
            --owners self \
            --filters "Name=tag:Project,Values=myproject" \
            --query 'Images[*].[Name,ImageId,Tags[?Key==`Version`].Value|[0],CreationDate]' \
            --output table
        ;;
    
    promote)
        # Promote version to latest
        AMI_ID=$(aws ec2 describe-images \
            --owners self \
            --filters "Name=tag:Version,Values=$VERSION" \
            --query 'Images[0].ImageId' \
            --output text)
        
        aws ec2 create-tags \
            --resources "$AMI_ID" \
            --tags Key=Latest,Value=true Key=Promoted,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        
        echo "Promoted $VERSION (AMI: $AMI_ID) to latest"
        ;;
    
    cleanup)
        # Remove old versions (keep last 5)
        OLD_AMIS=$(aws ec2 describe-images \
            --owners self \
            --filters "Name=tag:Project,Values=myproject" \
            --query 'reverse(sort_by(Images,&CreationDate))[5:].ImageId' \
            --output text)
        
        for AMI in $OLD_AMIS; do
            echo "Deregistering old AMI: $AMI"
            aws ec2 deregister-image --image-id "$AMI"
        done
        ;;
    
    *)
        echo "Usage: $0 {list|promote VERSION|cleanup}"
        exit 1
        ;;
esac
```

## Summary

Successful CI/CD integration requires:

- **Automation**: Eliminate manual processes with pipeline automation
- **Validation**: Automated template validation and testing
- **Security**: Secure credential management and access control
- **Consistency**: Standardized build processes across environments
- **Versioning**: Systematic version management and tracking
- **Testing**: Comprehensive automated testing before deployment
- **Monitoring**: Build status tracking and notifications
- **Documentation**: Clear pipeline documentation and runbooks

By integrating Packer into your CI/CD pipelines, you create a robust, automated infrastructure that delivers consistent, tested machine images with full traceability and version control
