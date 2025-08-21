---
title: "GitHub"
description: "Comprehensive guide to GitHub's containerization features, CI/CD workflows, GitHub Actions, Container Registry, and development environments for modern containerized applications"
category: "infrastructure"
tags: ["containers", "github", "actions", "registry", "codespaces", "ci-cd", "devops", "automation"]
---

GitHub has evolved into a comprehensive DevOps platform that provides powerful tools for containerized application development, deployment, and management. From GitHub Actions for CI/CD automation to GitHub Container Registry for artifact storage and GitHub Codespaces for cloud development environments, GitHub offers a complete ecosystem for modern containerized workflows.

## Table of Contents

- [Overview](#overview)
- [GitHub Actions](#github-actions)
- [GitHub Container Registry](#github-container-registry)
- [GitHub Codespaces](#github-codespaces)
- [GitHub Packages](#github-packages)
- [Workflow Templates](#workflow-templates)
- [Container Security](#container-security)
- [Environment Management](#environment-management)
- [Multi-Container Applications](#multi-container-applications)
- [Kubernetes Integration](#kubernetes-integration)
- [Docker Integration](#docker-integration)
- [Security Best Practices](#security-best-practices)
- [Monitoring and Observability](#monitoring-and-observability)
- [Cost Optimization](#cost-optimization)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

GitHub's container ecosystem provides integrated tools for the entire container lifecycle, from development to deployment and monitoring. The platform seamlessly integrates with popular container technologies and cloud providers, making it an ideal choice for teams building containerized applications.

### Core Container Features

- **GitHub Actions**: CI/CD automation with container support
- **GitHub Container Registry**: Secure container image storage and distribution
- **GitHub Codespaces**: Cloud-based development environments
- **GitHub Packages**: Package and artifact management
- **Security Scanning**: Vulnerability detection for container images
- **Environment Protection**: Deployment controls and approvals

### Integration Ecosystem

GitHub integrates seamlessly with:

- **Container Platforms**: Docker, Kubernetes, OpenShift
- **Cloud Providers**: AWS, Azure, Google Cloud, DigitalOcean
- **Container Registries**: Docker Hub, Amazon ECR, Azure ACR
- **Monitoring Tools**: Prometheus, Grafana, Datadog, New Relic
- **Security Platforms**: Snyk, Aqua Security, Twistlock

### When to Use GitHub for Containers

GitHub's container features are ideal for:

- **CI/CD Automation**: Automated building, testing, and deployment
- **Multi-Environment Workflows**: Development, staging, and production pipelines
- **Security-First Development**: Integrated security scanning and compliance
- **Team Collaboration**: Code review and deployment approval workflows
- **Microservices Architecture**: Managing multiple containerized services
- **Cloud-Native Applications**: Kubernetes and serverless deployments

## GitHub Actions

GitHub Actions provides powerful CI/CD automation capabilities specifically designed for containerized applications. It offers native Docker support, extensive marketplace of actions, and flexible workflow configurations.

### Container Workflow Basics

#### Simple Docker Build and Push

```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

#### Multi-Stage Build with Testing

```yaml
name: Advanced Docker Workflow

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run tests in container
      run: |
        docker build --target test -t app:test .
        docker run --rm app:test

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build image for scanning
      run: docker build -t app:scan .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'app:scan'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-deploy:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.repository_owner }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:latest
          ghcr.io/${{ github.repository }}:${{ github.sha }}
        platforms: linux/amd64,linux/arm64
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

### Advanced Workflow Patterns

#### Matrix Builds for Multiple Environments

```yaml
name: Matrix Container Builds

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - environment: development
            dockerfile: Dockerfile.dev
            tag-suffix: dev
          - environment: staging  
            dockerfile: Dockerfile.staging
            tag-suffix: staging
          - environment: production
            dockerfile: Dockerfile
            tag-suffix: prod

    steps:
    - uses: actions/checkout@v4
    
    - name: Build ${{ matrix.environment }} image
      run: |
        docker build -f ${{ matrix.dockerfile }} \
          -t ghcr.io/${{ github.repository }}:${{ matrix.tag-suffix }} .
    
    - name: Push to registry
      run: |
        echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
        docker push ghcr.io/${{ github.repository }}:${{ matrix.tag-suffix }}
```

#### Conditional Workflows with Environments

```yaml
name: Environment-Based Deployment

on:
  push:
    branches: [ main, staging, develop ]

jobs:
  determine-environment:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
    steps:
    - name: Set environment
      id: set-env
      run: |
        if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          echo "environment=production" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
          echo "environment=staging" >> $GITHUB_OUTPUT
        else
          echo "environment=development" >> $GITHUB_OUTPUT
        fi

  deploy:
    needs: determine-environment
    runs-on: ubuntu-latest
    environment: ${{ needs.determine-environment.outputs.environment }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Deploy to ${{ needs.determine-environment.outputs.environment }}
      run: |
        echo "Deploying to ${{ needs.determine-environment.outputs.environment }}"
        # Add your deployment logic here
```

### Container Service Integration

#### Docker Compose Services

```yaml
name: Integration Tests with Services

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build application image
      run: docker build -t app:test .
    
    - name: Run integration tests
      run: |
        docker run --rm --network host \
          -e DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb \
          -e REDIS_URL=redis://localhost:6379 \
          app:test npm run test:integration
```

## GitHub Container Registry

GitHub Container Registry (GHCR) provides secure, scalable container image storage with fine-grained access controls and seamless integration with GitHub workflows.

### Registry Configuration

#### Authentication Setup

```bash
# Login with Personal Access Token
echo $PAT | docker login ghcr.io -u USERNAME --password-stdin

# Login with GitHub Actions token (in workflow)
echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Using GitHub CLI
gh auth token | docker login ghcr.io -u USERNAME --password-stdin
```

#### Image Naming Conventions

```bash
# Repository images
ghcr.io/OWNER/REPOSITORY/IMAGE_NAME:TAG

# Examples
ghcr.io/mycompany/web-app:latest
ghcr.io/mycompany/web-app:v1.2.3
ghcr.io/mycompany/web-app:pr-123
ghcr.io/mycompany/api-service:main-abc1234
```

### Advanced Registry Features

#### Multi-Platform Images

```yaml
- name: Build multi-platform images
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64,linux/arm64,linux/arm/v7
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
```

#### Image Signing and Verification

```yaml
- name: Install cosign
  uses: sigstore/cosign-installer@v3
  
- name: Sign container image
  run: |
    cosign sign --yes ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
  env:
    COSIGN_EXPERIMENTAL: 1
```

### Registry Management

#### Lifecycle Policies

```yaml
# .github/workflows/cleanup.yml
name: Registry Cleanup

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly cleanup
  workflow_dispatch:

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
    - name: Delete old images
      uses: actions/delete-package-versions@v4
      with:
        package-name: 'my-app'
        package-type: 'container'
        min-versions-to-keep: 10
        delete-only-untagged-versions: 'true'
```

#### Image Vulnerability Scanning

```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'ghcr.io/${{ github.repository }}:${{ github.sha }}'
    format: 'json'
    output: 'trivy-results.json'

- name: Upload scan results
  uses: github/codeql-action/upload-sarif@v2
  if: always()
  with:
    sarif_file: 'trivy-results.sarif'
```

## GitHub Codespaces

GitHub Codespaces provides cloud-based development environments with full container support, enabling consistent development experiences across teams.

### Codespace Configuration

#### Basic devcontainer.json

```json
{
  "name": "Node.js & TypeScript",
  "image": "mcr.microsoft.com/devcontainers/typescript-node:18-bullseye",
  
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "github.vscode-pull-request-github"
      ]
    }
  },
  
  "postCreateCommand": "npm install",
  "postStartCommand": "docker version",
  
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  
  "forwardPorts": [3000, 8080],
  "portsAttributes": {
    "3000": {
      "label": "Application",
      "protocol": "http"
    }
  }
}
```

#### Custom Development Container

```dockerfile
# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/base:bullseye

# Install additional tools
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    kubectl \
    helm \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh

# Install development tools
RUN npm install -g typescript ts-node nodemon

# Setup user
USER vscode
```

#### Docker Compose Development Environment

```yaml
# .devcontainer/docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspace:cached
      - /var/run/docker.sock:/var/run/docker-host.sock
    command: sleep infinity
    network_mode: service:db
    
  db:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### Advanced Codespace Features

#### Prebuilds Configuration

```json
{
  "$schema": "https://raw.githubusercontent.com/devcontainers/spec/main/schemas/devContainer.schema.json",
  "name": "Full Stack Development",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/devcontainers/features/kubernetes-helm:1": {}
  },
  
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  
  "onCreateCommand": {
    "install-deps": "npm install",
    "setup-db": "docker-compose up -d db && sleep 10 && npm run db:migrate"
  },
  
  "postStartCommand": "npm run dev",
  
  "secrets": {
    "DATABASE_URL": {
      "description": "Database connection string"
    }
  }
}
```

## GitHub Packages

GitHub Packages provides comprehensive package management for containers and other artifacts, with integrated security scanning and access controls.

### Package Configuration

#### Docker Package Publishing

```yaml
name: Publish Package

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.repository_owner }}
        password: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Extract version
      id: version
      run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:latest
          ghcr.io/${{ github.repository }}:${{ steps.version.outputs.VERSION }}
        platforms: linux/amd64,linux/arm64
```

#### Package Metadata

```yaml
- name: Add package metadata
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
    labels: |
      org.opencontainers.image.title=${{ github.event.repository.name }}
      org.opencontainers.image.description=${{ github.event.repository.description }}
      org.opencontainers.image.url=${{ github.event.repository.html_url }}
      org.opencontainers.image.source=${{ github.event.repository.clone_url }}
      org.opencontainers.image.version=${{ steps.version.outputs.VERSION }}
      org.opencontainers.image.created=${{ steps.date.outputs.date }}
      org.opencontainers.image.revision=${{ github.sha }}
      org.opencontainers.image.licenses=${{ github.event.repository.license.spdx_id }}
```

## Workflow Templates

### Comprehensive Application Workflow

```yaml
name: Full Application Workflow

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      app: ${{ steps.filter.outputs.app }}
      docker: ${{ steps.filter.outputs.docker }}
    steps:
    - uses: actions/checkout@v4
    - uses: dorny/paths-filter@v2
      id: filter
      with:
        filters: |
          app:
            - 'src/**'
            - 'package*.json'
          docker:
            - 'Dockerfile*'
            - '.dockerignore'

  test:
    needs: changes
    if: needs.changes.outputs.app == 'true'
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [16, 18, 20]
        
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: npm
    
    - run: npm ci
    - run: npm run test:unit
    - run: npm run test:integration

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run security audit
      run: npm audit --audit-level moderate
      
    - name: Run CodeQL analysis
      uses: github/codeql-action/analyze@v2
      with:
        languages: javascript

  build:
    needs: [changes, test, security]
    if: needs.changes.outputs.app == 'true' || needs.changes.outputs.docker == 'true'
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to registry
      if: github.event_name != 'pull_request'
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: ${{ github.event_name != 'pull_request' }}
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  scan:
    needs: build
    if: needs.build.outputs.image-digest
    runs-on: ubuntu-latest
    
    steps:
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ needs.build.outputs.image-digest }}
        format: sarif
        output: trivy-results.sarif
    
    - name: Upload scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: trivy-results.sarif

  deploy-staging:
    needs: [build, scan]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ needs.build.outputs.image-digest }}"
        # Add your deployment logic

  deploy-production:
    needs: [build, scan]
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ needs.build.outputs.image-digest }}"
        # Add your deployment logic
```

### Microservices Workflow

```yaml
name: Microservices Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.filter.outputs.changes }}
    steps:
    - uses: actions/checkout@v4
    - uses: dorny/paths-filter@v2
      id: filter
      with:
        filters: |
          api: 'services/api/**'
          web: 'services/web/**'
          worker: 'services/worker/**'

  build:
    needs: changes
    if: needs.changes.outputs.services != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson(needs.changes.outputs.services) }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build ${{ matrix.service }}
      uses: docker/build-push-action@v5
      with:
        context: services/${{ matrix.service }}
        push: true
        tags: ghcr.io/${{ github.repository }}/${{ matrix.service }}:${{ github.sha }}
```

## Container Security

### Security Scanning Integration

#### Comprehensive Security Pipeline

```yaml
name: Security Scanning

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * *'  # Daily scans

jobs:
  vulnerability-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build image
      run: docker build -t scan-target .
    
    - name: Trivy vulnerability scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'scan-target'
        format: 'json'
        output: 'trivy-results.json'
        severity: 'CRITICAL,HIGH'
    
    - name: Snyk container scan
      uses: snyk/actions/docker@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        image: scan-target
        args: --severity-threshold=medium

  secrets-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: TruffleHog OSS
      uses: trufflesecurity/trufflehog@main
      with:
        path: ./
        base: main
        head: HEAD
        extra_args: --debug --only-verified

  license-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: License compatibility check
      uses: fossa-contrib/fossa-action@v2
      with:
        api-key: ${{ secrets.FOSSA_API_KEY }}
```

#### Runtime Security

```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    image: ghcr.io/${{ github.repository }}:latest
    format: spdx-json

- name: Sign image with cosign
  uses: sigstore/cosign-installer@v3
- run: |
    cosign sign --yes ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
  env:
    COSIGN_EXPERIMENTAL: 1

- name: Verify signature
  run: |
    cosign verify ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
  env:
    COSIGN_EXPERIMENTAL: 1
```

## Environment Management

### Environment Protection Rules

#### Production Environment Configuration

```yaml
# .github/environments/production.yml
name: production
protection_rules:
  - type: required_reviewers
    required_reviewers:
      - team: platform-team
      - user: lead-developer
  - type: wait_timer
    wait_timer: 300  # 5 minutes
  - type: branch_policy
    branch_policy:
      protected_branches: true
      custom_branch_policies: false

deployment_branch_policy:
  protected_branches: true
  custom_branch_policies: false

environment_variables:
  - name: ENVIRONMENT
    value: production
  - name: LOG_LEVEL
    value: info

secrets:
  - DATABASE_URL
  - API_SECRET_KEY
  - REDIS_URL
```

#### Environment-Specific Deployments

```yaml
name: Environment Deployment

on:
  push:
    branches: [ main, staging, develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.ref_name == 'main' && 'production' || (github.ref_name == 'staging' && 'staging' || 'development') }}
    
    steps:
    - name: Deploy to ${{ vars.ENVIRONMENT }}
      run: |
        echo "Deploying to ${{ vars.ENVIRONMENT }}"
        kubectl set image deployment/app app=ghcr.io/${{ github.repository }}:${{ github.sha }}
        kubectl rollout status deployment/app
```

## Multi-Container Applications

### Docker Compose in CI/CD

```yaml
name: Multi-Container Application

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Create environment file
      run: |
        cat << EOF > .env
        POSTGRES_DB=testdb
        POSTGRES_USER=testuser
        POSTGRES_PASSWORD=testpass
        REDIS_URL=redis://redis:6379
        API_URL=http://api:3000
        EOF
    
    - name: Start services
      run: docker-compose -f docker-compose.test.yml up -d
    
    - name: Wait for services
      run: |
        timeout 60 bash -c 'until docker-compose -f docker-compose.test.yml exec -T api curl -f http://localhost:3000/health; do sleep 2; done'
    
    - name: Run integration tests
      run: docker-compose -f docker-compose.test.yml exec -T api npm run test:integration
    
    - name: Collect logs
      if: failure()
      run: docker-compose -f docker-compose.test.yml logs
    
    - name: Cleanup
      if: always()
      run: docker-compose -f docker-compose.test.yml down -v
```

### Helm Chart Testing

```yaml
- name: Install Helm
  uses: azure/setup-helm@v3
  
- name: Add chart dependencies
  run: helm dependency update ./chart
  
- name: Lint Helm chart
  run: helm lint ./chart
  
- name: Test Helm templates
  run: |
    helm template test ./chart \
      --set image.tag=${{ github.sha }} \
      --set environment=test > rendered.yaml
    
- name: Validate Kubernetes manifests
  uses: instrumenta/kubeval-action@master
  with:
    files: rendered.yaml
```

## Kubernetes Integration

### GitOps Workflow

```yaml
name: GitOps Deployment

on:
  push:
    branches: [ main ]

jobs:
  update-manifests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        token: ${{ secrets.GITOPS_TOKEN }}
        repository: myorg/gitops-repo
    
    - name: Update image tags
      run: |
        yq eval '.spec.template.spec.containers[0].image = "ghcr.io/${{ github.repository }}:${{ github.sha }}"' \
          -i k8s/production/deployment.yaml
    
    - name: Commit changes
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add k8s/production/deployment.yaml
        git commit -m "Update image to ${{ github.sha }}" || exit 0
        git push
```

### Kubernetes Deployment

```yaml
- name: Deploy to Kubernetes
  uses: azure/k8s-deploy@v1
  with:
    manifests: |
      k8s/deployment.yaml
      k8s/service.yaml
      k8s/ingress.yaml
    images: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
    kubectl-version: 'latest'
```

## Docker Integration

### Advanced Docker Features

#### Multi-Stage Optimization

```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./

FROM base AS deps
RUN npm ci --only=production && npm cache clean --force

FROM base AS build
RUN npm ci
COPY . .
RUN npm run build

FROM base AS test
RUN npm ci
COPY . .
RUN npm test

FROM node:18-alpine AS final
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./

EXPOSE 3000
USER node
CMD ["npm", "start"]
```

#### Docker Build Arguments

```yaml
- name: Build with build args
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
    build-args: |
      NODE_ENV=production
      BUILD_VERSION=${{ github.sha }}
      BUILD_DATE=${{ steps.date.outputs.date }}
```

## Security Best Practices

### Secrets Management

#### Secure Secret Usage

```yaml
name: Secure Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        role-session-name: GitHubActions
        aws-region: us-west-2
    
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v2
    
    - name: Deploy with secrets
      run: |
        kubectl create secret generic app-secrets \
          --from-literal=database-url="${{ secrets.DATABASE_URL }}" \
          --from-literal=api-key="${{ secrets.API_KEY }}" \
          --dry-run=client -o yaml | kubectl apply -f -
```

#### Least Privilege Access

```yaml
permissions:
  contents: read
  packages: write
  security-events: write
  id-token: write  # for OIDC
```

### Container Hardening

```dockerfile
# Use non-root user
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set security options
LABEL security.non-root=true
LABEL security.readonly-rootfs=true

# Copy files with proper ownership
COPY --chown=nextjs:nodejs . .

USER nextjs
```

## Monitoring and Observability

### Application Performance Monitoring

```yaml
- name: Deploy with monitoring
  run: |
    kubectl apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app
      labels:
        app: myapp
    spec:
      template:
        spec:
          containers:
          - name: app
            image: ghcr.io/${{ github.repository }}:${{ github.sha }}
            env:
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: OTEL_SERVICE_NAME
              value: "myapp"
            - name: OTEL_SERVICE_VERSION
              value: "${{ github.sha }}"
    EOF
```

### Health Check Integration

```yaml
- name: Wait for deployment
  run: |
    kubectl rollout status deployment/app --timeout=300s
    
- name: Health check
  run: |
    ENDPOINT=$(kubectl get service app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    curl -f http://$ENDPOINT/health || exit 1
    
- name: Smoke tests
  run: |
    npm run test:smoke -- --endpoint=http://$ENDPOINT
```

## Cost Optimization

### Efficient Resource Usage

#### Optimized Builds

```yaml
- name: Build with cache optimization
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
    cache-from: |
      type=gha
      type=registry,ref=ghcr.io/${{ github.repository }}:buildcache
    cache-to: |
      type=gha,mode=max
      type=registry,ref=ghcr.io/${{ github.repository }}:buildcache,mode=max
```

#### Conditional Workflows

```yaml
- name: Check for changes
  uses: dorny/paths-filter@v2
  id: changes
  with:
    filters: |
      src:
        - 'src/**'
        - 'Dockerfile'
        - 'package*.json'

- name: Skip build if no changes
  if: steps.changes.outputs.src != 'true'
  run: echo "No changes detected, skipping build"
```

### Resource Management

```yaml
# Cleanup old images
- name: Delete old container images
  uses: actions/delete-package-versions@v4
  with:
    package-name: ${{ env.IMAGE_NAME }}
    package-type: container
    min-versions-to-keep: 5
    delete-only-untagged-versions: true
```

## Best Practices

### Workflow Organization

1. **Modular Workflows**: Break complex workflows into reusable components
2. **Matrix Strategies**: Use matrix builds for multiple environments/versions
3. **Conditional Execution**: Use path filters and conditions to optimize builds
4. **Caching Strategies**: Implement effective caching for dependencies and builds
5. **Parallel Execution**: Run independent jobs in parallel for faster execution

### Security Guidelines

1. **Least Privilege**: Use minimal required permissions
2. **Secret Management**: Store sensitive data in GitHub Secrets
3. **Image Scanning**: Always scan container images for vulnerabilities
4. **Dependency Updates**: Keep dependencies and base images updated
5. **Access Controls**: Use branch protection and environment protection rules

### Performance Optimization

1. **Build Optimization**: Use multi-stage builds and build caches
2. **Resource Efficiency**: Right-size runners and containers
3. **Network Optimization**: Use registry caching and proximity
4. **Monitoring**: Track workflow performance and resource usage
5. **Cleanup**: Regularly clean up old artifacts and images

### Code Quality

```yaml
- name: Code quality checks
  run: |
    npm run lint
    npm run type-check
    npm run format-check
    
- name: Test coverage
  run: |
    npm run test:coverage
    npx codecov
```

## Troubleshooting

### Common Issues and Solutions

#### Build Failures

```yaml
- name: Debug build failure
  if: failure()
  run: |
    docker system df
    docker buildx ls
    docker buildx inspect
    
- name: Build with verbose output
  uses: docker/build-push-action@v5
  with:
    context: .
    push: false
    tags: debug:latest
    build-args: |
      BUILDKIT_PROGRESS=plain
```

#### Registry Authentication

```bash
# Debug registry login
echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Check token permissions
curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
  https://api.github.com/user/packages?package_type=container
```

#### Performance Issues

```yaml
- name: Monitor resource usage
  run: |
    free -h
    df -h
    docker system df
    
- name: Optimize build context
  run: |
    echo "Build context size:"
    tar -czf - . | wc -c
```

### Debugging Workflows

```yaml
- name: Debug information
  run: |
    echo "Runner OS: ${{ runner.os }}"
    echo "GitHub Context: ${{ toJson(github) }}"
    echo "Environment: ${{ env.ENVIRONMENT }}"
    docker version
    kubectl version --client
```

### Log Analysis

```bash
# View workflow logs
gh run view $RUN_ID --log

# Download logs
gh run download $RUN_ID

# Monitor live logs
gh run watch $RUN_ID
```

## Resources

### Official Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Codespaces](https://docs.github.com/en/codespaces)
- [GitHub Packages](https://docs.github.com/en/packages)

### Container Integration Guides

- [Docker and GitHub Actions](https://docs.docker.com/ci-cd/github-actions/)
- [Kubernetes Deployment](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-kubernetes)
- [AWS Integration](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-amazon-elastic-container-service)
- [Azure Integration](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)

### Security Resources

- [GitHub Security Best Practices](https://docs.github.com/en/actions/security-guides)
- [Container Security](https://docs.github.com/en/code-security/supply-chain-security)
- [Dependency Management](https://docs.github.com/en/code-security/dependabot)
- [Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)

### Community Resources

- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Awesome Actions](https://github.com/sdras/awesome-actions)
- [GitHub Community Forum](https://github.community/)
- [GitHub Actions Runner Images](https://github.com/actions/runner-images)

### Learning Resources

- [GitHub Learning Lab](https://github.com/apps/github-learning-lab)
- [GitHub Actions Workflow Examples](https://github.com/actions/starter-workflows)
- [Container CI/CD Patterns](https://github.com/docker/awesome-compose)
- [Kubernetes CI/CD Examples](https://github.com/kubernetes/examples)

### Integration Examples

- [Multi-Platform Builds](https://github.com/docker/build-push-action/blob/master/docs/advanced/multi-platform.md)
- [Cache Optimization](https://github.com/docker/build-push-action/blob/master/docs/advanced/cache.md)
- [Security Scanning](https://github.com/marketplace/actions/aqua-security-trivy)
- [GitOps Workflows](https://github.com/fluxcd/flux2-kustomize-helm-example)
