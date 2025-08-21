---
title: "GitHub Actions"
description: "Comprehensive guide to GitHub Actions for container workflows, CI/CD automation, and DevOps pipeline orchestration"
category: "infrastructure"
tags: ["containers", "github-actions", "ci-cd", "automation", "devops", "workflows", "pipelines"]
---

GitHub Actions is a powerful CI/CD and automation platform integrated directly into GitHub repositories. It enables you to automate software workflows, build and test code, deploy applications, and orchestrate complex DevOps processes using containerized environments and cloud-native technologies.

## Table of Contents

- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Workflow Syntax](#workflow-syntax)
- [Container Workflows](#container-workflows)
- [Docker Integration](#docker-integration)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Security and Secrets](#security-and-secrets)
- [Matrix Strategies](#matrix-strategies)
- [Conditional Workflows](#conditional-workflows)
- [Reusable Workflows](#reusable-workflows)
- [Custom Actions](#custom-actions)
- [Performance Optimization](#performance-optimization)
- [Monitoring and Debugging](#monitoring-and-debugging)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

GitHub Actions transforms your GitHub repository into a comprehensive DevOps platform, enabling automation across the entire software development lifecycle. It's particularly powerful for container-based workflows, offering native Docker support, extensive marketplace integrations, and seamless cloud provider connectivity.

### Key Features

- **Event-Driven Automation**: Trigger workflows on push, pull requests, releases, and more
- **Native Container Support**: Built-in Docker and container orchestration capabilities
- **Extensive Marketplace**: Thousands of pre-built actions for common tasks
- **Matrix Builds**: Test across multiple environments, platforms, and configurations
- **Secrets Management**: Secure handling of sensitive data and credentials
- **Self-Hosted Runners**: Run workflows on your own infrastructure
- **Parallel Execution**: Optimize build times with concurrent job execution

### Architecture Components

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GitHub Actions Architecture                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Events    │───►│  Workflows  │───►│    Jobs     │───►│    Steps    │  │
│  │             │    │             │    │             │    │             │  │
│  │ • push      │    │ • YAML      │    │ • Runners   │    │ • Actions   │  │
│  │ • pr        │    │ • triggers  │    │ • Matrix    │    │ • Commands  │  │
│  │ • schedule  │    │ • env vars  │    │ • Services  │    │ • Scripts   │  │
│  │ • manual    │    │ • secrets   │    │ • Outputs   │    │             │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### When to Use GitHub Actions

GitHub Actions is ideal for:

- **Container CI/CD**: Build, test, and deploy containerized applications
- **Multi-Environment Deployments**: Automate deployments across dev, staging, production
- **Security Automation**: Vulnerability scanning and compliance checks
- **Infrastructure as Code**: Provision and manage cloud resources
- **Quality Gates**: Automated testing, code quality, and approval workflows
- **Release Automation**: Semantic versioning and automated releases

## Core Concepts

### Workflows

Workflows are automated processes defined in YAML files stored in `.github/workflows/`. Each workflow consists of one or more jobs that run in parallel or sequentially.

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
```

### Jobs and Steps

Jobs are collections of steps that run on the same runner. Steps are individual tasks within a job.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build application
      run: npm run build
```

### Runners

Runners are the compute environments where jobs execute. GitHub provides hosted runners or you can use self-hosted runners.

- **GitHub-hosted runners**: `ubuntu-latest`, `windows-latest`, `macos-latest`
- **Self-hosted runners**: Your own infrastructure with custom configurations
- **Larger runners**: More CPU, memory, and storage for intensive workloads

## Workflow Syntax

### Basic Workflow Structure

```yaml
name: Workflow Name
on:
  # Trigger events
  push:
    branches: [ main ]
    paths:
      - 'src/**'
      - 'Dockerfile'
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

env:
  # Global environment variables
  NODE_VERSION: 18
  DOCKER_REGISTRY: ghcr.io

jobs:
  job-id:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    env:
      # Job-specific environment variables
      BUILD_ENV: production
      
    steps:
    - name: Step name
      uses: action@version
      with:
        parameter: value
      env:
        # Step-specific environment variables
        CUSTOM_VAR: value
```

### Advanced Triggers

```yaml
on:
  push:
    branches: [ main, 'release/*' ]
    tags: [ 'v*' ]
    paths-ignore:
      - 'docs/**'
      - '*.md'
  
  pull_request:
    types: [ opened, synchronize, reopened, ready_for_review ]
    branches: [ main ]
  
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  
  workflow_dispatch:
    inputs:
      logLevel:
        description: 'Log level'
        required: true
        default: 'warning'
        type: choice
        options:
        - info
        - warning
        - debug
  
  repository_dispatch:
    types: [deploy-prod]
```

## Container Workflows

### Basic Docker Build and Push

```yaml
name: Container Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

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
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
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
        build-args: |
          BUILD_DATE=${{ steps.meta.outputs.created }}
          BUILD_VERSION=${{ steps.meta.outputs.version }}
          BUILD_REVISION=${{ github.sha }}
```

### Multi-Stage Build with Testing

```yaml
name: Advanced Container Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
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

    steps:
    - uses: actions/checkout@v4
    
    - name: Build test image
      run: |
        docker build --target test -t app:test .
    
    - name: Run unit tests
      run: |
        docker run --rm --network host \
          -e DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb \
          app:test npm run test:unit
    
    - name: Run integration tests
      run: |
        docker run --rm --network host \
          -e DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb \
          app:test npm run test:integration

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
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v3
      if: always()
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
    
    - name: Build and push production image
      uses: docker/build-push-action@v5
      with:
        context: .
        target: production
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:latest
          ghcr.io/${{ github.repository }}:${{ github.sha }}
        platforms: linux/amd64,linux/arm64
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

## Docker Integration

### Docker Compose Services

```yaml
name: Integration Tests with Docker Compose

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Create test environment file
      run: |
        cat << EOF > .env.test
        NODE_ENV=test
        DATABASE_URL=postgresql://testuser:testpass@postgres:5432/testdb
        REDIS_URL=redis://redis:6379
        EOF
    
    - name: Start services
      run: docker-compose -f docker-compose.test.yml up -d
    
    - name: Wait for services to be ready
      run: |
        timeout 60 bash -c 'until docker-compose -f docker-compose.test.yml exec -T api curl -f http://localhost:3000/health; do sleep 2; done'
    
    - name: Run integration tests
      run: |
        docker-compose -f docker-compose.test.yml exec -T api npm run test:integration
    
    - name: Generate test report
      if: always()
      run: |
        docker-compose -f docker-compose.test.yml exec -T api npm run test:report
    
    - name: Upload test results
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: test-results
        path: test-results/
    
    - name: Collect service logs
      if: failure()
      run: |
        docker-compose -f docker-compose.test.yml logs > service-logs.txt
    
    - name: Upload service logs
      uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: service-logs
        path: service-logs.txt
    
    - name: Clean up
      if: always()
      run: docker-compose -f docker-compose.test.yml down -v
```

### Multi-Registry Push

```yaml
name: Multi-Registry Container Build

on:
  push:
    tags: [ 'v*' ]

jobs:
  multi-registry-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v2
      with:
        registry-type: public
    
    - name: Extract version
      id: version
      run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
    
    - name: Build and push to multiple registries
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:${{ steps.version.outputs.VERSION }}
          ghcr.io/${{ github.repository }}:latest
          ${{ secrets.DOCKERHUB_USERNAME }}/myapp:${{ steps.version.outputs.VERSION }}
          ${{ secrets.DOCKERHUB_USERNAME }}/myapp:latest
          public.ecr.aws/myregistry/myapp:${{ steps.version.outputs.VERSION }}
          public.ecr.aws/myregistry/myapp:latest
```

## Kubernetes Deployment

### Basic Kubernetes Deployment

```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        role-session-name: GitHubActions
        aws-region: ${{ vars.AWS_REGION }}
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --name ${{ vars.EKS_CLUSTER_NAME }} --region ${{ vars.AWS_REGION }}
    
    - name: Deploy to Kubernetes
      run: |
        # Update image in deployment
        kubectl set image deployment/myapp \
          myapp=ghcr.io/${{ github.repository }}:${{ github.sha }} \
          --namespace=${{ vars.NAMESPACE }}
        
        # Wait for rollout to complete
        kubectl rollout status deployment/myapp \
          --namespace=${{ vars.NAMESPACE }} \
          --timeout=600s
    
    - name: Verify deployment
      run: |
        # Get deployment status
        kubectl get deployment myapp --namespace=${{ vars.NAMESPACE }}
        
        # Check pod status
        kubectl get pods -l app=myapp --namespace=${{ vars.NAMESPACE }}
        
        # Verify service endpoints
        kubectl get service myapp --namespace=${{ vars.NAMESPACE }}
```

### Helm Chart Deployment

```yaml
name: Helm Deployment

on:
  push:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, production]
        
    environment: ${{ matrix.environment }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install Helm
      uses: azure/setup-helm@v3
      with:
        version: '3.13.0'
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v3
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG_DATA }}
    
    - name: Add Helm repositories
      run: |
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update
    
    - name: Deploy with Helm
      run: |
        helm upgrade --install myapp ./chart \
          --namespace ${{ vars.NAMESPACE }} \
          --create-namespace \
          --values ./chart/values-${{ matrix.environment }}.yaml \
          --set image.tag=${{ github.sha }} \
          --set environment=${{ matrix.environment }} \
          --wait \
          --timeout 10m
    
    - name: Run smoke tests
      run: |
        # Wait for service to be ready
        kubectl wait --for=condition=ready pod \
          -l app.kubernetes.io/name=myapp \
          --namespace=${{ vars.NAMESPACE }} \
          --timeout=300s
        
        # Run health check
        ENDPOINT=$(kubectl get service myapp \
          --namespace=${{ vars.NAMESPACE }} \
          -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        curl -f http://$ENDPOINT/health || exit 1
```

### GitOps Workflow

```yaml
name: GitOps Deployment

on:
  push:
    branches: [ main ]

jobs:
  update-gitops-repo:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout GitOps repository
      uses: actions/checkout@v4
      with:
        repository: myorg/gitops-manifests
        token: ${{ secrets.GITOPS_TOKEN }}
        path: gitops
    
    - name: Update image tags in manifests
      run: |
        cd gitops
        
        # Update staging environment
        yq eval '.spec.template.spec.containers[0].image = "ghcr.io/${{ github.repository }}:${{ github.sha }}"' \
          -i environments/staging/deployment.yaml
        
        # Update production environment (only for tagged releases)
        if [[ "${{ github.ref }}" == refs/tags/* ]]; then
          yq eval '.spec.template.spec.containers[0].image = "ghcr.io/${{ github.repository }}:${{ github.sha }}"' \
            -i environments/production/deployment.yaml
        fi
    
    - name: Commit and push changes
      run: |
        cd gitops
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add .
        git diff --staged --quiet || git commit -m "Update image to ${{ github.sha }}"
        git push
```

## Security and Secrets

### Secrets Management

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
    
    - name: Configure AWS credentials using OIDC
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        role-session-name: GitHubActions-${{ github.run_id }}
        aws-region: us-west-2
    
    - name: Retrieve secrets from AWS Secrets Manager
      uses: aws-actions/aws-secretsmanager-get-secrets@v1
      with:
        secret-ids: |
          prod/myapp/database
          prod/myapp/api-keys
        parse-json-secrets: true
    
    - name: Deploy with secrets
      env:
        DATABASE_URL: ${{ env.PROD_MYAPP_DATABASE_URL }}
        API_KEY: ${{ env.PROD_MYAPP_API_KEYS_API_KEY }}
      run: |
        # Deploy application with retrieved secrets
        kubectl create secret generic app-secrets \
          --from-literal=database-url="${DATABASE_URL}" \
          --from-literal=api-key="${API_KEY}" \
          --dry-run=client -o yaml | kubectl apply -f -
```

### Security Scanning Pipeline

```yaml
name: Security Scanning

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday

jobs:
  code-security:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
      
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: javascript, python
    
    - name: Autobuild
      uses: github/codeql-action/autobuild@v3
    
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3

  dependency-security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run npm audit
      run: |
        npm audit --audit-level moderate
        npm audit --json > audit-results.json
      continue-on-error: true
    
    - name: Upload audit results
      uses: actions/upload-artifact@v4
      with:
        name: npm-audit-results
        path: audit-results.json

  container-security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build image for scanning
      run: docker build -t scan-target .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'scan-target'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v3
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Run Snyk to check Docker image for vulnerabilities
      uses: snyk/actions/docker@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        image: scan-target
        args: --severity-threshold=medium --file=Dockerfile

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
        base: ${{ github.event.repository.default_branch }}
        head: HEAD
        extra_args: --debug --only-verified
```

## Matrix Strategies

### Multi-Platform Testing

```yaml
name: Cross-Platform Testing

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        include:
          - os: ubuntu-latest
            platform: linux/amd64
          - os: windows-latest
            platform: windows/amd64
          - os: macos-latest
            platform: darwin/amd64
        exclude:
          - os: windows-latest
            node-version: 16
            
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
      env:
        PLATFORM: ${{ matrix.platform }}
        NODE_VERSION: ${{ matrix.node-version }}
    
    - name: Upload coverage to Codecov
      if: matrix.os == 'ubuntu-latest' && matrix.node-version == '18'
      uses: codecov/codecov-action@v3

  container-build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform:
          - linux/amd64
          - linux/arm64
          - linux/arm/v7
        include:
          - platform: linux/amd64
            arch: amd64
          - platform: linux/arm64
            arch: arm64
          - platform: linux/arm/v7
            arch: armv7
            
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Build for ${{ matrix.platform }}
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: ${{ matrix.platform }}
        push: false
        tags: myapp:${{ matrix.arch }}
        cache-from: type=gha,scope=${{ matrix.arch }}
        cache-to: type=gha,mode=max,scope=${{ matrix.arch }}
```

### Environment Matrix

```yaml
name: Multi-Environment Deployment

on:
  workflow_dispatch:
    inputs:
      environments:
        description: 'Environments to deploy (JSON array)'
        default: '["staging"]'
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: ${{ fromJson(github.event.inputs.environments) }}
        include:
          - environment: staging
            namespace: myapp-staging
            replicas: 2
            resources_requests_cpu: "100m"
            resources_requests_memory: "128Mi"
          - environment: production
            namespace: myapp-prod
            replicas: 5
            resources_requests_cpu: "500m"
            resources_requests_memory: "512Mi"
          - environment: development
            namespace: myapp-dev
            replicas: 1
            resources_requests_cpu: "50m"
            resources_requests_memory: "64Mi"
            
    environment: ${{ matrix.environment }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Deploy to ${{ matrix.environment }}
      run: |
        echo "Deploying to ${{ matrix.environment }}"
        echo "Namespace: ${{ matrix.namespace }}"
        echo "Replicas: ${{ matrix.replicas }}"
        echo "CPU: ${{ matrix.resources_requests_cpu }}"
        echo "Memory: ${{ matrix.resources_requests_memory }}"
        
        # Actual deployment commands would go here
        kubectl apply -f k8s/ \
          --namespace=${{ matrix.namespace }} \
          --dry-run=client -o yaml | \
          sed "s/replicas: 1/replicas: ${{ matrix.replicas }}/g" | \
          kubectl apply -f -
```

## Conditional Workflows

### Path-Based Conditions

```yaml
name: Conditional Build

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
      infrastructure: ${{ steps.filter.outputs.infrastructure }}
    steps:
    - uses: actions/checkout@v4
    
    - uses: dorny/paths-filter@v2
      id: filter
      with:
        filters: |
          frontend:
            - 'frontend/**'
            - 'package.json'
            - 'package-lock.json'
          backend:
            - 'backend/**'
            - 'requirements.txt'
            - 'Dockerfile'
          infrastructure:
            - 'infrastructure/**'
            - 'k8s/**'
            - '.github/workflows/**'

  frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build frontend
      run: |
        cd frontend
        npm ci
        npm run build
        npm test

  backend:
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build backend
      run: |
        cd backend
        docker build -t backend:test .
        docker run --rm backend:test python -m pytest

  infrastructure:
    needs: changes
    if: needs.changes.outputs.infrastructure == 'true'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Validate infrastructure
      run: |
        # Validate Kubernetes manifests
        kubectl apply --dry-run=client -f k8s/
        
        # Terraform validation
        cd infrastructure
        terraform init
        terraform validate
        terraform plan
```

### Environment-Based Conditions

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
      should-deploy: ${{ steps.set-env.outputs.should-deploy }}
    steps:
    - name: Determine environment and deployment
      id: set-env
      run: |
        if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          echo "environment=production" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
          echo "environment=staging" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
          echo "environment=development" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        else
          echo "environment=none" >> $GITHUB_OUTPUT
          echo "should-deploy=false" >> $GITHUB_OUTPUT
        fi

  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build application
      run: |
        docker build -t myapp:${{ github.sha }} .

  deploy:
    needs: [determine-environment, build]
    if: needs.determine-environment.outputs.should-deploy == 'true'
    runs-on: ubuntu-latest
    environment: ${{ needs.determine-environment.outputs.environment }}
    
    steps:
    - name: Deploy to ${{ needs.determine-environment.outputs.environment }}
      run: |
        echo "Deploying to ${{ needs.determine-environment.outputs.environment }}"
        # Deployment logic here
```

## Reusable Workflows

### Reusable Container Build Workflow

Create `.github/workflows/reusable-container-build.yml`:

```yaml
name: Reusable Container Build

on:
  workflow_call:
    inputs:
      image-name:
        required: true
        type: string
      dockerfile-path:
        required: false
        type: string
        default: './Dockerfile'
      context-path:
        required: false
        type: string
        default: '.'
      platforms:
        required: false
        type: string
        default: 'linux/amd64,linux/arm64'
      push-image:
        required: false
        type: boolean
        default: true
    outputs:
      image-digest:
        description: "Image digest"
        value: ${{ jobs.build.outputs.digest }}
      image-tags:
        description: "Image tags"
        value: ${{ jobs.build.outputs.tags }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
      tags: ${{ steps.meta.outputs.tags }}
      
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Login to GitHub Container Registry
      if: inputs.push-image
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ghcr.io/${{ inputs.image-name }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: ${{ inputs.context-path }}
        file: ${{ inputs.dockerfile-path }}
        platforms: ${{ inputs.platforms }}
        push: ${{ inputs.push-image }}
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

### Using Reusable Workflows

```yaml
name: Application CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-api:
    uses: ./.github/workflows/reusable-container-build.yml
    with:
      image-name: ${{ github.repository }}/api
      dockerfile-path: './api/Dockerfile'
      context-path: './api'
      push-image: ${{ github.ref == 'refs/heads/main' }}

  build-frontend:
    uses: ./.github/workflows/reusable-container-build.yml
    with:
      image-name: ${{ github.repository }}/frontend
      dockerfile-path: './frontend/Dockerfile'
      context-path: './frontend'
      push-image: ${{ github.ref == 'refs/heads/main' }}

  deploy:
    needs: [build-api, build-frontend]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Deploy services
      run: |
        echo "Deploying API: ${{ needs.build-api.outputs.image-tags }}"
        echo "API Digest: ${{ needs.build-api.outputs.image-digest }}"
        echo "Deploying Frontend: ${{ needs.build-frontend.outputs.image-tags }}"
        echo "Frontend Digest: ${{ needs.build-frontend.outputs.image-digest }}"
        
        # Actual deployment commands would go here
```

## Custom Actions

### JavaScript Action

Create `action.yml`:

```yaml
name: 'Container Security Scan'
description: 'Comprehensive security scanning for container images'
inputs:
  image-ref:
    description: 'Container image reference to scan'
    required: true
  severity-threshold:
    description: 'Minimum severity level to report'
    required: false
    default: 'MEDIUM'
  output-format:
    description: 'Output format (sarif, json, table)'
    required: false
    default: 'sarif'
outputs:
  scan-results:
    description: 'Path to scan results file'
    value: ${{ steps.scan.outputs.results-file }}
runs:
  using: 'composite'
  steps:
  - name: Install Trivy
    shell: bash
    run: |
      sudo apt-get update
      sudo apt-get install wget apt-transport-https gnupg lsb-release
      wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
      echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
      sudo apt-get update
      sudo apt-get install trivy

  - name: Run Trivy scan
    id: scan
    shell: bash
    run: |
      RESULTS_FILE="trivy-results-$(date +%s).${{ inputs.output-format }}"
      
      trivy image \
        --format ${{ inputs.output-format }} \
        --output "${RESULTS_FILE}" \
        --severity ${{ inputs.severity-threshold }} \
        --no-progress \
        ${{ inputs.image-ref }}
      
      echo "results-file=${RESULTS_FILE}" >> $GITHUB_OUTPUT

  - name: Upload scan results
    if: inputs.output-format == 'sarif'
    uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: ${{ steps.scan.outputs.results-file }}
```

### Docker Action

Create `action.yml`:

```yaml
name: 'Kubernetes Deploy'
description: 'Deploy application to Kubernetes cluster'
inputs:
  kubeconfig:
    description: 'Kubernetes configuration'
    required: true
  namespace:
    description: 'Target namespace'
    required: true
  manifest-path:
    description: 'Path to Kubernetes manifests'
    required: true
  image-tag:
    description: 'Container image tag to deploy'
    required: true
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.namespace }}
    - ${{ inputs.manifest-path }}
    - ${{ inputs.image-tag }}
  env:
    KUBECONFIG_DATA: ${{ inputs.kubeconfig }}
```

Create `Dockerfile`:

```dockerfile
FROM alpine:3.18

RUN apk add --no-cache kubectl yq bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

Create `entrypoint.sh`:

```bash
#!/bin/bash
set -e

NAMESPACE=$1
MANIFEST_PATH=$2
IMAGE_TAG=$3

# Setup kubeconfig
echo "${KUBECONFIG_DATA}" | base64 -d > /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig

# Update image tags in manifests
find "${MANIFEST_PATH}" -name "*.yaml" -o -name "*.yml" | while read -r file; do
  yq eval '.spec.template.spec.containers[].image |= sub(":[^:]*$"; ":'"${IMAGE_TAG}"'")' -i "${file}"
done

# Apply manifests
kubectl apply -f "${MANIFEST_PATH}" --namespace="${NAMESPACE}"

# Wait for deployment to complete
kubectl rollout status deployment --all --namespace="${NAMESPACE}" --timeout=600s

echo "Deployment completed successfully"
```

## Performance Optimization

### Build Optimization

```yaml
name: Optimized Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
      with:
        driver-opts: |
          image=moby/buildkit:buildx-stable-1
          network=host
    
    - name: Build with advanced caching
      uses: docker/build-push-action@v5
      with:
        context: .
        push: false
        tags: myapp:latest
        cache-from: |
          type=gha
          type=registry,ref=ghcr.io/${{ github.repository }}:buildcache
        cache-to: |
          type=gha,mode=max
          type=registry,ref=ghcr.io/${{ github.repository }}:buildcache,mode=max
        build-args: |
          BUILDKIT_INLINE_CACHE=1

  parallel-jobs:
    strategy:
      matrix:
        job: [lint, test, security-scan]
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js with cache
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci --prefer-offline --no-audit
    
    - name: Run ${{ matrix.job }}
      run: npm run ${{ matrix.job }}
```

### Resource Management

```yaml
name: Resource Optimized Workflow

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest-4-cores  # Use larger runner for CPU-intensive tasks
    timeout-minutes: 15  # Prevent hanging jobs
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 1  # Shallow clone for faster checkout
    
    - name: Free disk space
      run: |
        sudo rm -rf /usr/share/dotnet
        sudo rm -rf /opt/ghc
        sudo rm -rf "/usr/local/share/boost"
        sudo rm -rf "$AGENT_TOOLSDIRECTORY"
        
    - name: Setup Node.js with caching
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: '**/package-lock.json'
    
    - name: Install dependencies with cache
      run: |
        # Use npm ci with cache for faster installs
        npm ci --prefer-offline --no-audit --no-fund
    
    - name: Run tests with coverage
      run: |
        # Run tests in parallel
        npm run test:parallel -- --maxWorkers=4
```

## Monitoring and Debugging

### Workflow Debugging

```yaml
name: Debug Workflow

on:
  workflow_dispatch:
    inputs:
      debug_enabled:
        description: 'Enable debug logging'
        required: false
        default: 'false'
        type: boolean

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Enable debug logging
      if: inputs.debug_enabled
      run: |
        echo "ACTIONS_STEP_DEBUG=true" >> $GITHUB_ENV
        echo "RUNNER_DEBUG=1" >> $GITHUB_ENV
    
    - name: Debug information
      run: |
        echo "Runner information:"
        echo "OS: $(uname -a)"
        echo "Architecture: $(uname -m)"
        echo "Available space:"
        df -h
        echo "Memory:"
        free -h
        echo "CPU info:"
        nproc
        echo "Environment variables:"
        env | sort
        echo "GitHub context:"
        echo '${{ toJson(github) }}'
        echo "Job context:"
        echo '${{ toJson(job) }}'
        echo "Steps context:"
        echo '${{ toJson(steps) }}'
    
    - name: Setup tmate session
      if: failure() && inputs.debug_enabled
      uses: mxschmitt/action-tmate@v3
      with:
        limit-access-to-actor: true
        timeout-minutes: 30
```

### Performance Monitoring

```yaml
name: Performance Monitoring

on: [push, pull_request]

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Start monitoring
      run: |
        # Start system monitoring in background
        (
          while true; do
            echo "$(date): CPU: $(cat /proc/loadavg), Memory: $(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')"
            sleep 30
          done
        ) > system-monitor.log &
        echo $! > monitor.pid
    
    - name: Build application
      run: |
        # Your build commands here
        docker build -t myapp .
    
    - name: Stop monitoring and collect stats
      if: always()
      run: |
        if [ -f monitor.pid ]; then
          kill $(cat monitor.pid) || true
          rm monitor.pid
        fi
        echo "System monitoring results:"
        cat system-monitor.log || echo "No monitoring data available"
    
    - name: Upload performance data
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: performance-data
        path: system-monitor.log
        retention-days: 7
```

## Best Practices

### Workflow Organization

1. **Modular Structure**: Break complex workflows into smaller, reusable components
2. **Clear Naming**: Use descriptive names for workflows, jobs, and steps
3. **Documentation**: Include comments and descriptions for complex logic
4. **Version Pinning**: Pin action versions to specific tags or SHAs
5. **Error Handling**: Use conditional execution and proper error handling

### Security Guidelines

```yaml
name: Security Best Practices

on: [push, pull_request]

permissions:
  contents: read
  packages: write
  security-events: write
  id-token: write  # For OIDC token

jobs:
  secure-build:
    runs-on: ubuntu-latest
    steps:
    - name: Harden Runner
      uses: step-security/harden-runner@v2
      with:
        egress-policy: audit
        
    - uses: actions/checkout@v4
    
    - name: Use OIDC for AWS authentication
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        role-session-name: GitHubActions
        aws-region: us-west-2
    
    - name: Build with security scanning
      run: |
        docker build -t app:secure .
        
        # Scan for vulnerabilities
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
          -v "$(pwd):/workspace" \
          aquasec/trivy image --exit-code 1 app:secure
```

### Performance Best Practices

1. **Efficient Caching**: Use appropriate caching strategies for dependencies and builds
2. **Parallel Execution**: Run independent jobs in parallel
3. **Resource Optimization**: Choose appropriate runner sizes and timeouts
4. **Minimal Context**: Use shallow clones and minimal checkout when possible
5. **Conditional Execution**: Skip unnecessary work with path filters and conditions

## Troubleshooting

### Common Issues and Solutions

#### Build Failures

```yaml
- name: Debug build failure
  if: failure()
  run: |
    echo "Build context information:"
    find . -name "Dockerfile" -exec echo "Found Dockerfile: {}" \;
    echo "Docker version:"
    docker --version
    echo "Available space:"
    df -h
    echo "Docker system info:"
    docker system df
```

#### Network Issues

```yaml
- name: Debug network connectivity
  run: |
    echo "Testing connectivity:"
    ping -c 3 github.com
    curl -I https://api.github.com
    
    echo "DNS resolution:"
    nslookup github.com
    
    echo "Network configuration:"
    ip route show
```

#### Permission Issues

```yaml
- name: Fix Docker permissions
  run: |
    sudo chmod 666 /var/run/docker.sock
    sudo usermod -aG docker $USER
    # Note: Group changes require a new shell session
```

### Debugging Techniques

```bash
# Enable debug logging
export ACTIONS_STEP_DEBUG=true
export RUNNER_DEBUG=1

# View workflow run logs
gh run view $RUN_ID --log

# Download artifacts
gh run download $RUN_ID

# Monitor workflow execution
gh run watch $RUN_ID
```

## Resources

### Official Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions) - Complete reference and guides
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) - YAML syntax reference
- [Actions Marketplace](https://github.com/marketplace?type=actions) - Pre-built actions library
- [Runner Images](https://github.com/actions/runner-images) - Available runner environments

### Container Integration

- [Docker Build and Push Action](https://github.com/docker/build-push-action) - Official Docker build action
- [Container Registry Authentication](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Kubernetes Actions](https://github.com/marketplace?query=kubernetes) - K8s deployment actions
- [Helm Actions](https://github.com/marketplace?query=helm) - Helm deployment actions

### Security Resources

- [Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OpenID Connect (OIDC)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Security Best Practices](https://docs.github.com/en/actions/security-guides)

### Community Resources

- [Awesome Actions](https://github.com/sdras/awesome-actions) - Curated list of actions
- [GitHub Actions Community](https://github.community/c/code-to-cloud/github-actions) - Community forum
- [Action Examples](https://github.com/actions/starter-workflows) - Starter workflow templates
- [GitHub Actions Toolkit](https://github.com/actions/toolkit) - Building custom actions

### Learning Resources

- [GitHub Learning Lab](https://github.com/apps/github-learning-lab) - Interactive learning
- [GitHub Actions Training](https://github.com/skills) - Hands-on courses
- [CI/CD Best Practices](https://docs.github.com/en/actions/guides) - Implementation guides
- [Container CI/CD Patterns](https://docs.docker.com/ci-cd/github-actions/) - Docker integration patterns

This comprehensive guide covers everything needed to implement sophisticated CI/CD pipelines and automation workflows using GitHub Actions, with special focus on containerized applications and modern DevOps practices.
