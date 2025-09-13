---
title: CI/CD Pipeline Implementation
description: Comprehensive guide to implementing Continuous Integration and Continuous Deployment pipelines using modern DevOps tools and practices
author: Joseph Streeter
date: 2024-01-15
tags: [ci-cd, devops, automation, azure-devops, github-actions, deployment, testing]
---

Continuous Integration and Continuous Deployment (CI/CD) is fundamental to modern software development, enabling teams to deliver high-quality software rapidly and reliably. This guide provides comprehensive implementation strategies for various CI/CD platforms.

Continuous Integration and Continuous Deployment (CI/CD) is fundamental to modern software development, enabling teams to deliver high-quality software rapidly and reliably. This guide provides comprehensive implementation strategies for various CI/CD platforms.

## CI/CD Fundamentals

### Core Principles

```text
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                          │
├─────────────────────────────────────────────────────────────────┤
│  Stage           │ Activities                                   │
│  ├─ Source       │ Code commit, branch policies, code review    │
│  ├─ Build        │ Compile, package, dependency management      │
│  ├─ Test         │ Unit, integration, security, performance     │
│  ├─ Deploy       │ Staging, production, rollback capabilities   │
│  └─ Monitor      │ Health checks, metrics, alerting             │
└─────────────────────────────────────────────────────────────────┘
```

### Pipeline Benefits

- **Faster Time to Market**: Automated processes reduce manual delays
- **Higher Quality**: Consistent testing and validation
- **Reduced Risk**: Smaller, frequent deployments
- **Improved Reliability**: Standardized deployment processes
- **Better Collaboration**: Shared responsibility and visibility

## GitHub Actions Implementation

### Comprehensive Workflow Configuration

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 0'  # Weekly security scan

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.11'
  DOCKER_REGISTRY: 'your-registry.azurecr.io'
  AZURE_WEBAPP_NAME: 'your-webapp'

jobs:
  # Security and Code Quality
  security-scan:
    name: Security & Code Quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  # Build and Test Matrix
  build-test:
    name: Build & Test
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        include:
          - os: ubuntu-latest
            node-version: 18
            coverage: true
            
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linting
        run: npm run lint

      - name: Run type checking
        run: npm run type-check

      - name: Run unit tests
        run: npm run test:unit

      - name: Run integration tests
        run: npm run test:integration
        env:
          CI: true

      - name: Generate coverage report
        if: matrix.coverage
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        if: matrix.coverage
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          file: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

      - name: Build application
        run: npm run build

      - name: Upload build artifacts
        if: matrix.os == 'ubuntu-latest' && matrix.node-version == 18
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            dist/
            package.json
            package-lock.json
          retention-days: 30

  # Docker Build and Push
  docker-build:
    name: Docker Build & Push
    runs-on: ubuntu-latest
    needs: [security-scan, build-test]
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Azure Container Registry
        uses: azure/docker-login@v1
        with:
          login-server: ${{ env.DOCKER_REGISTRY }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.DOCKER_REGISTRY }}/myapp
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
          build-args: |
            NODE_VERSION=${{ env.NODE_VERSION }}
            BUILD_DATE=${{ steps.meta.outputs.labels }}

  # Performance Testing
  performance-test:
    name: Performance Testing
    runs-on: ubuntu-latest
    needs: build-test
    if: github.event_name == 'pull_request'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Start application
        run: |
          npm run build
          npm start &
          sleep 30

      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli@0.12.x
          lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}

      - name: Run load tests
        run: |
          npm install -g artillery
          artillery run tests/performance/load-test.yml

  # Staging Deployment
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [docker-build]
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: https://staging.${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}-staging
          images: ${{ env.DOCKER_REGISTRY }}/myapp:main

      - name: Run smoke tests
        run: |
          curl -f https://staging.${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health || exit 1

  # Production Deployment
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net
    
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Blue-Green Deployment
        run: |
          # Deploy to blue slot
          az webapp deployment slot create \
            --name ${{ env.AZURE_WEBAPP_NAME }} \
            --resource-group myResourceGroup \
            --slot blue

      - name: Deploy to Blue Slot
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}
          slot-name: blue
          images: ${{ env.DOCKER_REGISTRY }}/myapp:main

      - name: Run production smoke tests
        run: |
          curl -f https://${{ env.AZURE_WEBAPP_NAME }}-blue.azurewebsites.net/health || exit 1
          
      - name: Swap to production
        run: |
          az webapp deployment slot swap \
            --name ${{ env.AZURE_WEBAPP_NAME }} \
            --resource-group myResourceGroup \
            --slot blue \
            --target-slot production

      - name: Verify deployment
        run: |
          curl -f https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health || exit 1

  # Notification
  notify:
    name: Notify Team
    runs-on: ubuntu-latest
    needs: [deploy-production]
    if: always()
    
    steps:
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          channel: '#deployments'
          text: |
            Deployment to production completed
            Status: ${{ job.status }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
```

## Azure DevOps Pipelines

### Multi-Stage Pipeline Configuration

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - docs/*
      - README.md

pr:
  branches:
    include:
      - main
  drafts: false

variables:
  # Build Variables
  buildConfiguration: 'Release'
  dotNetFramework: 'net8.0'
  dotNetVersion: '8.0.x'
  
  # Azure Variables
  azureServiceConnection: 'azure-service-connection'
  containerRegistry: 'myregistry.azurecr.io'
  imageRepository: 'myapp'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  
  # Environment Variables
  vmImageName: 'ubuntu-latest'

resources:
  repositories:
    - repository: templates
      type: git
      name: DevOps/pipeline-templates
      ref: refs/heads/main

stages:
  # Continuous Integration
  - stage: CI
    displayName: 'Continuous Integration'
    jobs:
      - job: SecurityScan
        displayName: 'Security and Code Quality'
        pool:
          vmImage: $(vmImageName)
        steps:
          - checkout: self
            fetchDepth: 0
            
          - task: SonarCloudPrepare@1
            displayName: 'Prepare SonarCloud analysis'
            inputs:
              SonarCloud: 'SonarCloud-Connection'
              organization: 'myorg'
              scannerMode: 'MSBuild'
              projectKey: 'myproject'

          - task: UseDotNet@2
            displayName: 'Use .NET SDK'
            inputs:
              packageType: 'sdk'
              version: $(dotNetVersion)

          - task: DotNetCoreCLI@2
            displayName: 'Restore packages'
            inputs:
              command: 'restore'
              projects: '**/*.csproj'

          - task: DotNetCoreCLI@2
            displayName: 'Build solution'
            inputs:
              command: 'build'
              projects: '**/*.csproj'
              arguments: '--configuration $(buildConfiguration) --no-restore'

          - task: SonarCloudAnalyze@1
            displayName: 'Run SonarCloud analysis'

          - task: SonarCloudPublish@1
            displayName: 'Publish SonarCloud results'

          - task: WhiteSource@21
            displayName: 'WhiteSource security scan'
            inputs:
              cwd: '$(System.DefaultWorkingDirectory)'

      - job: BuildAndTest
        displayName: 'Build and Test'
        pool:
          vmImage: $(vmImageName)
        strategy:
          matrix:
            Debug:
              buildConfiguration: 'Debug'
            Release:
              buildConfiguration: 'Release'
        steps:
          - template: templates/dotnet-build-test.yml@templates
            parameters:
              buildConfiguration: $(buildConfiguration)
              publishTestResults: true
              publishCodeCoverage: true

      - job: DockerBuild
        displayName: 'Docker Build'
        dependsOn: [SecurityScan, BuildAndTest]
        condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
        pool:
          vmImage: $(vmImageName)
        steps:
          - task: Docker@2
            displayName: 'Build and push image'
            inputs:
              containerRegistry: $(azureServiceConnection)
              repository: $(imageRepository)
              command: 'buildAndPush'
              Dockerfile: $(dockerfilePath)
              tags: |
                $(Build.BuildId)
                latest

  # Staging Deployment
  - stage: DeployStaging
    displayName: 'Deploy to Staging'
    dependsOn: CI
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    variables:
      environmentName: 'staging'
    jobs:
      - deployment: DeployStaging
        displayName: 'Deploy to Staging Environment'
        pool:
          vmImage: $(vmImageName)
        environment: 'staging'
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/azure-web-app-deploy.yml@templates
                  parameters:
                    azureSubscription: $(azureServiceConnection)
                    appName: 'myapp-staging'
                    containerRegistry: $(containerRegistry)
                    imageRepository: $(imageRepository)
                    tag: $(Build.BuildId)

      - job: StagingTests
        displayName: 'Run Staging Tests'
        dependsOn: DeployStaging
        pool:
          vmImage: $(vmImageName)
        steps:
          - task: PowerShell@2
            displayName: 'Run smoke tests'
            inputs:
              targetType: 'inline'
              script: |
                $response = Invoke-WebRequest -Uri "https://myapp-staging.azurewebsites.net/health" -UseBasicParsing
                if ($response.StatusCode -ne 200) {
                  throw "Health check failed"
                }

  # Production Deployment
  - stage: DeployProduction
    displayName: 'Deploy to Production'
    dependsOn: DeployStaging
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    variables:
      environmentName: 'production'
    jobs:
      - deployment: DeployProduction
        displayName: 'Deploy to Production Environment'
        pool:
          vmImage: $(vmImageName)
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/azure-web-app-deploy.yml@templates
                  parameters:
                    azureSubscription: $(azureServiceConnection)
                    appName: 'myapp-production'
                    containerRegistry: $(containerRegistry)
                    imageRepository: $(imageRepository)
                    tag: $(Build.BuildId)
                    useBlueGreenDeployment: true

                - task: AzureAppServiceManage@0
                  displayName: 'Restart App Service'
                  inputs:
                    azureSubscription: $(azureServiceConnection)
                    WebAppName: 'myapp-production'
                    Action: 'Restart web app'

      - job: ProductionTests
        displayName: 'Run Production Tests'
        dependsOn: DeployProduction
        pool:
          vmImage: $(vmImageName)
        steps:
          - task: PowerShell@2
            displayName: 'Run production health checks'
            inputs:
              targetType: 'inline'
              script: |
                # Multiple health check endpoints
                $endpoints = @(
                  "https://myapp-production.azurewebsites.net/health",
                  "https://myapp-production.azurewebsites.net/ready",
                  "https://myapp-production.azurewebsites.net/api/status"
                )
                
                foreach ($endpoint in $endpoints) {
                  try {
                    $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 30
                    Write-Host "✓ $endpoint - Status: $($response.StatusCode)"
                  }
                  catch {
                    Write-Error "✗ $endpoint - Failed: $($_.Exception.Message)"
                    throw
                  }
                }
```

## Jenkins Pipeline Implementation

### Declarative Pipeline with Advanced Features

```groovy
// Jenkinsfile
pipeline {
    agent {
        kubernetes {
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: docker
                    image: docker:20.10.7-dind
                    securityContext:
                      privileged: true
                  - name: node
                    image: node:18-alpine
                    command:
                    - cat
                    tty: true
                  - name: python
                    image: python:3.11-slim
                    command:
                    - cat
                    tty: true
                  - name: sonar
                    image: sonarqube:9.9-community
                    command:
                    - cat
                    tty: true
            """
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        APP_NAME = 'myapp'
        KUBECONFIG = credentials('kubeconfig')
        SONAR_TOKEN = credentials('sonar-token')
        SLACK_WEBHOOK = credentials('slack-webhook')
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        retry(2)
        skipStagesAfterUnstable()
        parallelsAlwaysFailFast()
    }
    
    triggers {
        cron(env.BRANCH_NAME == 'main' ? 'H 2 * * 0' : '')
        pollSCM(env.BRANCH_NAME == 'main' ? 'H/5 * * * *' : '')
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    // Set dynamic variables
                    env.BUILD_VERSION = sh(
                        script: "echo '${env.BUILD_NUMBER}-${env.GIT_COMMIT[0..7]}'",
                        returnStdout: true
                    ).trim()
                    
                    env.IS_MAIN_BRANCH = env.BRANCH_NAME == 'main'
                    env.IS_PR = env.CHANGE_ID != null
                }
                
                // Checkout with Git LFS support
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    extensions: [
                        [$class: 'GitLFSPull'],
                        [$class: 'CleanCheckout']
                    ],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }
        
        stage('Quality Gates') {
            parallel {
                stage('Security Scan') {
                    steps {
                        container('python') {
                            sh '''
                                pip install safety bandit semgrep
                                
                                # Check for known vulnerabilities
                                safety check --json --output safety-report.json || true
                                
                                # Static security analysis
                                bandit -r . -f json -o bandit-report.json || true
                                
                                # SAST scanning
                                semgrep --config=auto --json --output=semgrep-report.json . || true
                            '''
                        }
                        
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'safety-report.json,bandit-report.json,semgrep-report.json',
                            reportName: 'Security Scan Report'
                        ])
                    }
                }
                
                stage('Code Quality') {
                    steps {
                        container('sonar') {
                            script {
                                def scannerHome = tool 'SonarScanner'
                                withSonarQubeEnv('SonarQube') {
                                    sh """
                                        ${scannerHome}/bin/sonar-scanner \
                                            -Dsonar.projectKey=${env.APP_NAME} \
                                            -Dsonar.projectName=${env.APP_NAME} \
                                            -Dsonar.projectVersion=${env.BUILD_VERSION} \
                                            -Dsonar.sources=. \
                                            -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/*.test.js \
                                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                                    """
                                }
                            }
                        }
                        
                        timeout(time: 10, unit: 'MINUTES') {
                            script {
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    error "Pipeline aborted due to quality gate failure: ${qg.status}"
                                }
                            }
                        }
                    }
                }
                
                stage('License Compliance') {
                    steps {
                        container('node') {
                            sh '''
                                npm install -g license-checker
                                license-checker --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC' \
                                              --excludePrivatePackages \
                                              --json > license-report.json
                            '''
                        }
                        
                        archiveArtifacts artifacts: 'license-report.json', fingerprint: true
                    }
                }
            }
        }
        
        stage('Build & Test') {
            matrix {
                axes {
                    axis {
                        name 'NODE_VERSION'
                        values '16', '18', '20'
                    }
                    axis {
                        name 'ENVIRONMENT'
                        values 'development', 'production'
                    }
                }
                excludes {
                    exclude {
                        axis {
                            name 'NODE_VERSION'
                            values '16'
                        }
                        axis {
                            name 'ENVIRONMENT'
                            values 'production'
                        }
                    }
                }
                stages {
                    stage('Matrix Build') {
                        steps {
                            container('node') {
                                sh """
                                    node --version
                                    npm --version
                                    
                                    # Install dependencies
                                    npm ci
                                    
                                    # Run linting
                                    npm run lint
                                    
                                    # Run tests with coverage
                                    NODE_ENV=${ENVIRONMENT} npm run test:coverage
                                    
                                    # Build application
                                    NODE_ENV=${ENVIRONMENT} npm run build
                                """
                            }
                        }
                        post {
                            always {
                                publishTestResults testResultsPattern: 'test-results.xml'
                                publishHTML([
                                    allowMissing: false,
                                    alwaysLinkToLastBuild: true,
                                    keepAll: true,
                                    reportDir: 'coverage',
                                    reportFiles: 'index.html',
                                    reportName: "Coverage Report - Node ${NODE_VERSION} ${ENVIRONMENT}"
                                ])
                            }
                        }
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    // Start test services
                    sh '''
                        docker-compose -f docker-compose.test.yml up -d
                        sleep 30
                    '''
                    
                    try {
                        container('node') {
                            sh 'npm run test:integration'
                        }
                    } finally {
                        // Cleanup test services
                        sh 'docker-compose -f docker-compose.test.yml down -v'
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    changeRequest()
                }
            }
            steps {
                container('docker') {
                    script {
                        def imageTag = env.IS_MAIN_BRANCH ? 'latest' : env.BUILD_VERSION
                        def image = docker.build("${env.DOCKER_REGISTRY}/${env.APP_NAME}:${imageTag}")
                        
                        // Security scan of Docker image
                        sh """
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                aquasec/trivy image \
                                --format json \
                                --output trivy-image-report.json \
                                ${env.DOCKER_REGISTRY}/${env.APP_NAME}:${imageTag}
                        """
                        
                        if (env.IS_MAIN_BRANCH) {
                            docker.withRegistry("https://${env.DOCKER_REGISTRY}", 'docker-registry-credentials') {
                                image.push()
                                image.push(env.BUILD_VERSION)
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            stages {
                stage('Deploy to Staging') {
                    steps {
                        script {
                            deployToEnvironment('staging', env.BUILD_VERSION)
                        }
                    }
                    post {
                        success {
                            script {
                                runSmokeTests('staging')
                            }
                        }
                    }
                }
                
                stage('Approval Gate') {
                    steps {
                        script {
                            def deployment = input(
                                id: 'productionDeployment',
                                message: 'Deploy to production?',
                                submitter: 'deployment-team',
                                parameters: [
                                    choice(
                                        name: 'DEPLOYMENT_STRATEGY',
                                        choices: ['blue-green', 'rolling', 'canary'],
                                        description: 'Deployment strategy'
                                    ),
                                    booleanParam(
                                        name: 'SKIP_SMOKE_TESTS',
                                        defaultValue: false,
                                        description: 'Skip smoke tests'
                                    )
                                ]
                            )
                            env.DEPLOYMENT_STRATEGY = deployment.DEPLOYMENT_STRATEGY
                            env.SKIP_SMOKE_TESTS = deployment.SKIP_SMOKE_TESTS
                        }
                    }
                }
                
                stage('Deploy to Production') {
                    steps {
                        script {
                            deployToEnvironment('production', env.BUILD_VERSION, env.DEPLOYMENT_STRATEGY)
                        }
                    }
                    post {
                        success {
                            script {
                                if (!env.SKIP_SMOKE_TESTS.toBoolean()) {
                                    runSmokeTests('production')
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Archive artifacts
            archiveArtifacts artifacts: '**/*-report.json,**/coverage/**', allowEmptyArchive: true
            
            // Clean workspace
            cleanWs()
        }
        success {
            script {
                if (env.IS_MAIN_BRANCH) {
                    slackSend(
                        channel: '#deployments',
                        color: 'good',
                        message: """
                            ✅ Deployment Successful
                            Project: ${env.APP_NAME}
                            Version: ${env.BUILD_VERSION}
                            Duration: ${currentBuild.durationString}
                        """
                    )
                }
            }
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: """
                    ❌ Pipeline Failed
                    Project: ${env.APP_NAME}
                    Branch: ${env.BRANCH_NAME}
                    Build: ${env.BUILD_NUMBER}
                    Stage: ${env.STAGE_NAME}
                """
            )
        }
    }
}

// Helper functions
def deployToEnvironment(environment, version, strategy = 'rolling') {
    sh """
        helm upgrade --install ${env.APP_NAME}-${environment} ./helm-chart \
            --namespace ${environment} \
            --set image.tag=${version} \
            --set environment=${environment} \
            --set deployment.strategy=${strategy} \
            --wait --timeout=600s
    """
}

def runSmokeTests(environment) {
    sh """
        curl -f https://${env.APP_NAME}-${environment}.example.com/health || exit 1
        curl -f https://${env.APP_NAME}-${environment}.example.com/ready || exit 1
    """
}
```

## Infrastructure as Code Integration

### Terraform CI/CD Pipeline

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  pull_request:
    branches: [main]
    paths: ['terraform/**']

env:
  TF_VERSION: '1.7.0'
  WORKING_DIR: './terraform'

jobs:
  terraform-validate:
    name: Terraform Validate
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Initialize
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate

      - name: Run TFLint
        uses: terraform-linters/setup-tflint@v4
        with:
          tflint_version: v0.50.0
      
      - name: TFLint
        run: |
          tflint --init
          tflint --format sarif > tflint-results.sarif
        
      - name: Upload TFLint results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: ${{ env.WORKING_DIR }}/tflint-results.sarif

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: ${{ env.WORKING_DIR }}
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif

  terraform-plan:
    name: Terraform Plan
    needs: terraform-validate
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Terraform Initialize
        run: |
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TF_STATE_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TF_STATE_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=main.tfstate"

      - name: Terraform Plan
        run: |
          terraform plan \
            -var-file="environments/staging.tfvars" \
            -out=tfplan \
            -detailed-exitcode
        continue-on-error: true
        id: plan

      - name: Generate Plan Summary
        run: |
          terraform show -no-color tfplan > plan-output.txt
          
          # Create plan summary for PR comment
          echo "## Terraform Plan Summary" > plan-summary.md
          echo "" >> plan-summary.md
          echo "**Plan Result:** ${{ steps.plan.outcome }}" >> plan-summary.md
          echo "" >> plan-summary.md
          echo "<details><summary>Show Plan Details</summary>" >> plan-summary.md
          echo "" >> plan-summary.md
          echo "\`\`\`" >> plan-summary.md
          cat plan-output.txt >> plan-summary.md
          echo "\`\`\`" >> plan-summary.md
          echo "</details>" >> plan-summary.md

      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const planSummary = fs.readFileSync('terraform/plan-summary.md', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: planSummary
            });

  terraform-apply:
    name: Terraform Apply
    needs: terraform-plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Terraform Initialize
        run: |
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TF_STATE_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TF_STATE_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=main.tfstate"

      - name: Terraform Apply
        run: |
          terraform apply \
            -var-file="environments/production.tfvars" \
            -auto-approve

      - name: Output Infrastructure Info
        run: |
          terraform output -json > infrastructure-outputs.json
          
      - name: Upload Infrastructure Outputs
        uses: actions/upload-artifact@v3
        with:
          name: infrastructure-outputs
          path: terraform/infrastructure-outputs.json
```

## Related Topics

- [Azure DevOps Best Practices](../../azuredevops/index.md)
- [Git Workflow Strategies](../../git/index.md)
- [Docker Container Management](../../../infrastructure/containers/docker/index.md)
- [Terraform Infrastructure](../../../infrastructure/terraform/index.md)
- [PowerShell Automation](../../powershell/index.md)
