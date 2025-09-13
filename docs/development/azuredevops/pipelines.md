---
title: Azure DevOps Pipelines - CI/CD Automation
description: Comprehensive guide to Azure Pipelines for continuous integration and deployment, including YAML pipeline configuration, multi-stage deployments, and DevOps best practices
author: Joseph Streeter
date: 2025-09-13
tags: [azure-devops, pipelines, ci-cd, yaml, deployment, automation, devops]
---

Azure Pipelines provides enterprise-grade continuous integration and continuous deployment (CI/CD) capabilities, supporting multiple languages, platforms, and deployment targets with infrastructure as code.

## 🎯 **Overview**

Azure Pipelines enables teams to:

- **Automate builds and tests** across multiple languages and platforms
- **Deploy applications** to any cloud provider or on-premises infrastructure
- **Implement DevOps best practices** with infrastructure as code
- **Scale development workflows** from small teams to enterprise organizations
- **Integrate security** throughout the development lifecycle
- **Monitor and optimize** pipeline performance and reliability

### Supported Platforms and Technologies

| Category | Technologies |
|----------|-------------|
| **Languages** | .NET, Java, Python, Node.js, PHP, Ruby, Go, C++, Swift |
| **Platforms** | Windows, Linux, macOS, containers |
| **Source Control** | Azure Repos, GitHub, Bitbucket, Subversion |
| **Deployment Targets** | Azure, AWS, GCP, Kubernetes, on-premises |
| **Package Managers** | NuGet, npm, Maven, pip, Docker |

## 🏗️ **Pipeline Fundamentals**

### Pipeline Types

#### YAML Pipelines

- **Infrastructure as Code**: Version-controlled pipeline definitions
- **Multi-stage support**: Build, test, and deploy in structured stages
- **Template reusability**: Shared templates across projects
- **Branch policies**: Different pipelines for different branches

### Core Concepts

```yaml
# azure-pipelines.yml structure overview
trigger: # When to run the pipeline
pool: # Where to run the pipeline
variables: # Pipeline variables and secrets
stages: # High-level execution phases
  - stage: Build
    jobs: # Units of work within a stage
      - job: BuildJob
        steps: # Individual tasks
          - task: DotNetCoreCLI@2
```

## 📝 **YAML Pipeline Configuration**

### Basic Pipeline Structure

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
    - feature/*
  paths:
    exclude:
    - docs/*
    - README.md

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  solution: '**/*.sln'
  projectPath: 'src/MyProject'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: BuildJob
    displayName: 'Build Job'
    steps:
    - task: UseDotNet@2
      displayName: 'Use .NET 8.0'
      inputs:
        packageType: 'sdk'
        version: '8.0.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet packages'
      inputs:
        command: 'restore'
        projects: '$(solution)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build solution'
      inputs:
        command: 'build'
        projects: '$(solution)'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run unit tests'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build --collect:"XPlat Code Coverage"'
    
    - task: PublishTestResults@2
      displayName: 'Publish test results'
      inputs:
        testResultsFormat: 'VSTest'
        testResultsFiles: '**/*.trx'
        mergeTestResults: true
      condition: succeededOrFailed()
    
    - task: PublishCodeCoverageResults@1
      displayName: 'Publish code coverage'
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'
```

### Multi-Stage Pipeline Example

```yaml
# Complete CI/CD pipeline with multiple environments
trigger:
  branches:
    include:
    - main
    - release/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  azureSubscription: 'production-service-connection'
  webAppName: 'myapp-prod'

stages:
# Build Stage
- stage: Build
  displayName: 'Build Application'
  jobs:
  - job: BuildAndPublish
    displayName: 'Build and Publish Artifacts'
    steps:
    - task: UseDotNet@2
      inputs:
        packageType: 'sdk'
        version: '8.0.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore packages'
      inputs:
        command: 'restore'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build application'
      inputs:
        command: 'build'
        arguments: '--configuration $(buildConfiguration)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run tests'
      inputs:
        command: 'test'
        arguments: '--configuration $(buildConfiguration) --collect:"XPlat Code Coverage"'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'

# Test Environment Deployment
- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy to Dev Environment'
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'webApp'
              appName: 'myapp-dev'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deploymentMethod: 'auto'
          
          - task: AzureAppServiceManage@0
            displayName: 'Restart App Service'
            inputs:
              azureSubscription: '$(azureSubscription)'
              action: 'Restart Azure App Service'
              webAppName: 'myapp-dev'

# Production Deployment with Approval
- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: DeployDev
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy to Production Environment'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Production'
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'webApp'
              appName: '$(webAppName)'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deploymentMethod: 'zipDeploy'
              
          - task: AzureAppServiceManage@0
            displayName: 'Swap to Production Slot'
            inputs:
              azureSubscription: '$(azureSubscription)'
              action: 'Swap Slots'
              webAppName: '$(webAppName)'
              resourceGroupName: 'production-rg'
              sourceSlot: 'staging'
```

## 🐳 **Container and Kubernetes Pipelines**

### Docker Container Pipeline

```yaml
# Docker build and push pipeline
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerRegistryServiceConnection: 'myregistry-connection'
  imageRepository: 'myapp'
  containerRegistry: 'myregistry.azurecr.io'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: 'Build and Push Docker Image'
  jobs:
  - job: Docker
    displayName: 'Build Docker Image'
    steps:
    - task: Docker@2
      displayName: 'Build Docker image'
      inputs:
        command: 'build'
        repository: '$(imageRepository)'
        dockerfile: '$(dockerfilePath)'
        tags: |
          $(tag)
          latest
    
    - task: Docker@2
      displayName: 'Push Docker image'
      inputs:
        command: 'push'
        repository: '$(imageRepository)'
        containerRegistry: '$(dockerRegistryServiceConnection)'
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: 'Deploy to Kubernetes'
  dependsOn: Build
  jobs:
  - deployment: DeployToK8s
    displayName: 'Deploy to AKS'
    environment: 'production-aks'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Deploy to Kubernetes cluster'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'aks-connection'
              namespace: 'default'
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yml
                $(Pipeline.Workspace)/manifests/service.yml
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'
```

### Kubernetes Deployment Manifests

```yaml
# deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: connection-string
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

## 🔧 **Advanced Pipeline Features**

### Pipeline Templates

#### Job Template

```yaml
# templates/build-job.yml
parameters:
- name: projectPath
  type: string
- name: buildConfiguration
  type: string
  default: 'Release'
- name: runTests
  type: boolean
  default: true

jobs:
- job: BuildJob
  displayName: 'Build ${{ parameters.projectPath }}'
  steps:
  - task: UseDotNet@2
    inputs:
      packageType: 'sdk'
      version: '8.0.x'
  
  - task: DotNetCoreCLI@2
    displayName: 'Restore packages'
    inputs:
      command: 'restore'
      projects: '${{ parameters.projectPath }}/**/*.csproj'
  
  - task: DotNetCoreCLI@2
    displayName: 'Build project'
    inputs:
      command: 'build'
      projects: '${{ parameters.projectPath }}/**/*.csproj'
      arguments: '--configuration ${{ parameters.buildConfiguration }} --no-restore'
  
  - ${{ if eq(parameters.runTests, true) }}:
    - task: DotNetCoreCLI@2
      displayName: 'Run tests'
      inputs:
        command: 'test'
        projects: '${{ parameters.projectPath }}/**/*Tests.csproj'
        arguments: '--configuration ${{ parameters.buildConfiguration }} --no-build'
```

#### Stage Template

```yaml
# templates/deploy-stage.yml
parameters:
- name: environment
  type: string
- name: azureSubscription
  type: string
- name: webAppName
  type: string
- name: dependsOn
  type: string
  default: ''

stages:
- stage: Deploy${{ parameters.environment }}
  displayName: 'Deploy to ${{ parameters.environment }}'
  ${{ if ne(parameters.dependsOn, '') }}:
    dependsOn: ${{ parameters.dependsOn }}
  jobs:
  - deployment: Deploy
    displayName: 'Deploy to ${{ parameters.environment }}'
    environment: '${{ parameters.environment }}'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy Azure Web App'
            inputs:
              azureSubscription: '${{ parameters.azureSubscription }}'
              appType: 'webApp'
              appName: '${{ parameters.webAppName }}'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
```

#### Using Templates

```yaml
# azure-pipelines.yml using templates
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Build
  jobs:
  - template: templates/build-job.yml
    parameters:
      projectPath: 'src/WebApp'
      buildConfiguration: 'Release'
      runTests: true

- template: templates/deploy-stage.yml
  parameters:
    environment: 'development'
    azureSubscription: 'dev-subscription'
    webAppName: 'myapp-dev'
    dependsOn: 'Build'

- template: templates/deploy-stage.yml
  parameters:
    environment: 'production'
    azureSubscription: 'prod-subscription'
    webAppName: 'myapp-prod'
    dependsOn: 'DeployDevelopment'
```

### Variables and Secrets

#### Variable Groups

```yaml
# Pipeline with variable groups
variables:
- group: 'common-variables'
- group: 'environment-secrets'
- name: buildConfiguration
  value: 'Release'

steps:
- task: AzureKeyVault@2
  displayName: 'Get secrets from Key Vault'
  inputs:
    azureSubscription: '$(azureSubscription)'
    KeyVaultName: '$(keyVaultName)'
    SecretsFilter: 'ConnectionString,ApiKey'
    RunAsPreJob: true

- script: |
    echo "Using connection string: $(ConnectionString)"
    echo "API Key length: $(echo $(ApiKey) | wc -c)"
  displayName: 'Use secrets securely'
  env:
    CONNECTION_STRING: $(ConnectionString)
    API_KEY: $(ApiKey)
```

#### Runtime Variables

```yaml
# Dynamic variable creation
steps:
- script: |
    BUILD_DATE=$(date +%Y%m%d)
    BUILD_TIME=$(date +%H%M%S)
    VERSION_NUMBER="1.0.$(Build.BuildId)"
    
    echo "##vso[task.setvariable variable=buildDate]$BUILD_DATE"
    echo "##vso[task.setvariable variable=buildTime]$BUILD_TIME"
    echo "##vso[task.setvariable variable=versionNumber;isOutput=true]$VERSION_NUMBER"
  name: setVariables
  displayName: 'Set dynamic variables'

- script: |
    echo "Build Date: $(buildDate)"
    echo "Build Time: $(buildTime)"
    echo "Version: $(setVariables.versionNumber)"
  displayName: 'Use dynamic variables'
```

### Conditional Execution

```yaml
# Conditional steps and stages
stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - script: echo "Always runs"
    
    - script: echo "Only on main branch"
      condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    
    - script: echo "Only on PR"
      condition: eq(variables['Build.Reason'], 'PullRequest')
    
    - script: echo "Only if previous step succeeded"
      condition: succeeded()
    
    - script: echo "Always runs even if pipeline fails"
      condition: always()

- stage: DeployProd
  condition: |
    and(
      succeeded(),
      eq(variables['Build.SourceBranch'], 'refs/heads/main'),
      not(eq(variables['Build.Reason'], 'PullRequest'))
    )
  jobs:
  - deployment: Production
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to production"
```

## 📱 **Multi-Platform Pipelines**

### Matrix Strategy

```yaml
# Multi-platform build matrix
strategy:
  matrix:
    Linux:
      imageName: 'ubuntu-latest'
      dotnetVersion: '8.0.x'
    Windows:
      imageName: 'windows-latest'
      dotnetVersion: '8.0.x'
    MacOS:
      imageName: 'macOS-latest'
      dotnetVersion: '8.0.x'

pool:
  vmImage: $(imageName)

steps:
- task: UseDotNet@2
  inputs:
    packageType: 'sdk'
    version: $(dotnetVersion)

- script: |
    dotnet build --configuration Release
    dotnet test --configuration Release --logger trx
  displayName: 'Build and test on $(imageName)'

- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'VSTest'
    testResultsFiles: '**/*.trx'
  condition: succeededOrFailed()
```

### Mobile App Pipeline

```yaml
# Xamarin/MAUI mobile app pipeline
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'macOS-latest'

variables:
  buildConfiguration: 'Release'
  outputDirectory: '$(agent.buildDirectory)/output'

steps:
- task: UseDotNet@2
  displayName: 'Use .NET 8.0'
  inputs:
    packageType: 'sdk'
    version: '8.0.x'

- task: InstallAppleCertificate@2
  displayName: 'Install Apple Certificate'
  inputs:
    certSecureFile: 'ios-cert.p12'
    certPwd: '$(appleCertPassword)'

- task: InstallAppleProvisioningProfile@1
  displayName: 'Install Provisioning Profile'
  inputs:
    provisioningProfileLocation: 'secureFiles'
    provProFile: 'ios-profile.mobileprovision'

- task: DotNetCoreCLI@2
  displayName: 'Build iOS App'
  inputs:
    command: 'build'
    projects: '**/MyApp.csproj'
    arguments: '--configuration $(buildConfiguration) --framework net8.0-ios'

- task: DotNetCoreCLI@2
  displayName: 'Build Android App'
  inputs:
    command: 'build'
    projects: '**/MyApp.csproj'
    arguments: '--configuration $(buildConfiguration) --framework net8.0-android'

- task: CopyFiles@2
  displayName: 'Copy IPA files'
  inputs:
    Contents: '**/*.ipa'
    TargetFolder: '$(outputDirectory)'

- task: CopyFiles@2
  displayName: 'Copy APK files'
  inputs:
    Contents: '**/*.apk'
    TargetFolder: '$(outputDirectory)'

- task: PublishBuildArtifacts@1
  displayName: 'Publish mobile artifacts'
  inputs:
    PathtoPublish: '$(outputDirectory)'
    ArtifactName: 'mobile-apps'
```

## 🔒 **Security and Compliance**

### Security Scanning

```yaml
# Security scanning pipeline
stages:
- stage: SecurityScan
  displayName: 'Security Analysis'
  jobs:
  - job: StaticAnalysis
    displayName: 'Static Code Analysis'
    steps:
    - task: SonarCloudPrepare@1
      displayName: 'Prepare SonarCloud analysis'
      inputs:
        SonarCloud: 'sonarcloud-connection'
        organization: 'myorg'
        scannerMode: 'MSBuild'
        projectKey: 'myproject'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build with SonarCloud'
      inputs:
        command: 'build'
        arguments: '--configuration Release'
    
    - task: SonarCloudAnalyze@1
      displayName: 'Run SonarCloud analysis'
    
    - task: SonarCloudPublish@1
      displayName: 'Publish SonarCloud results'
    
    - task: WhiteSource@21
      displayName: 'WhiteSource Security Scan'
      inputs:
        cwd: '$(System.DefaultWorkingDirectory)'
        projectName: '$(Build.Repository.Name)'
    
    - task: dependency-check-build-task@6
      displayName: 'OWASP Dependency Check'
      inputs:
        projectName: '$(Build.Repository.Name)'
        scanPath: '$(Build.SourcesDirectory)'
        format: 'ALL'
```

### Compliance and Governance

```yaml
# Compliance pipeline with approvals
stages:
- stage: Build
  jobs:
  - job: ComplianceBuild
    steps:
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'VSTest'
        testResultsFiles: '**/*.trx'
    
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'

- stage: ComplianceGate
  displayName: 'Compliance Gate'
  dependsOn: Build
  jobs:
  - job: ComplianceCheck
    displayName: 'Compliance Validation'
    steps:
    - task: BuildQualityChecks@8
      displayName: 'Build Quality Checks'
      inputs:
        checkWarnings: true
        warningFailOption: 'build'
        checkCoverage: true
        coverageFailOption: 'build'
        coverageType: 'lines'
        coverageThreshold: '80'
    
    - task: securedevelopmentteam.vss-secure-development-tools.build-task-credscan.CredScan@3
      displayName: 'Credential Scanner'
      inputs:
        toolMajorVersion: 'V2'
        outputFormat: 'sarif'
        debugMode: false

- stage: Production
  displayName: 'Production Deployment'
  dependsOn: ComplianceGate
  jobs:
  - deployment: ProductionDeploy
    environment: 'production-with-approvals'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to production with compliance approval"
```

## 📊 **Monitoring and Analytics**

### Pipeline Analytics

```yaml
# Pipeline with comprehensive logging
variables:
  Agent.Source.Git.ShallowFetchDepth: 1

stages:
- stage: Build
  jobs:
  - job: BuildWithMetrics
    steps:
    - script: |
        echo "##vso[task.logissue type=error]Build started at $(date)"
        echo "##vso[task.setvariable variable=buildStartTime]$(date +%s)"
      displayName: 'Log build start'
    
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
      continueOnError: true
    
    - script: |
        BUILD_END_TIME=$(date +%s)
        BUILD_DURATION=$((BUILD_END_TIME - $(buildStartTime)))
        echo "##vso[task.logissue type=warning]Build duration: $BUILD_DURATION seconds"
        echo "##vso[task.setvariable variable=buildDuration]$BUILD_DURATION"
      displayName: 'Calculate build metrics'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'BuildMetrics'
```

### Custom Dashboards

```json
{
  "dashboardName": "CI/CD Pipeline Analytics",
  "widgets": [
    {
      "name": "Build Success Rate",
      "type": "chart",
      "configuration": {
        "chartType": "line",
        "dataSource": "Builds",
        "groupBy": "Date",
        "aggregation": "Percentage",
        "filter": "Result=Succeeded"
      }
    },
    {
      "name": "Deployment Frequency",
      "type": "metric",
      "configuration": {
        "dataSource": "Releases",
        "metric": "Count",
        "timeRange": "Last 30 days",
        "target": "Daily"
      }
    },
    {
      "name": "Lead Time",
      "type": "chart",
      "configuration": {
        "chartType": "bar",
        "dataSource": "WorkItems",
        "metric": "AverageTime",
        "states": ["New", "Resolved"]
      }
    }
  ]
}
```

## 🛠️ **Troubleshooting and Optimization**

### Performance Optimization

```yaml
# Optimized pipeline configuration
pool:
  vmImage: 'ubuntu-latest'

variables:
  # Optimize git operations
  Agent.Source.Git.ShallowFetchDepth: 1
  # Enable build caching
  DOTNET_SKIP_FIRST_TIME_EXPERIENCE: true
  NUGET_PACKAGES: $(Pipeline.Workspace)/.nuget/packages

steps:
- task: Cache@2
  displayName: 'Cache NuGet packages'
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/packages.lock.json,!**/bin/**,!**/obj/**'
    restoreKeys: |
      nuget | "$(Agent.OS)"
      nuget
    path: $(NUGET_PACKAGES)

- task: Cache@2
  displayName: 'Cache npm packages'
  inputs:
    key: 'npm | "$(Agent.OS)" | package-lock.json'
    restoreKeys: |
      npm | "$(Agent.OS)"
    path: $(npm_config_cache)

- script: |
    # Parallel restore operations
    dotnet restore --parallel &
    npm ci &
    wait
  displayName: 'Parallel package restore'
```

### Common Issues and Solutions

```powershell
# Pipeline diagnostic script
function Test-PipelineHealth {
    param(
        [string]$Organization,
        [string]$Project,
        [string]$PipelineId,
        [string]$Pat
    )
    
    $headers = @{
        Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat")))"
    }
    
    # Get recent builds
    $uri = "$Organization/$Project/_apis/build/builds?definitions=$PipelineId&maxBuildsPerDefinition=10&api-version=6.0"
    $builds = Invoke-RestMethod -Uri $uri -Headers $headers
    
    # Analyze build patterns
    $analysis = $builds.value | ForEach-Object {
        [PSCustomObject]@{
            BuildId = $_.id
            Result = $_.result
            Duration = if ($_.finishTime -and $_.startTime) {
                ([datetime]$_.finishTime - [datetime]$_.startTime).TotalMinutes
            } else { "Running" }
            QueueTime = if ($_.queueTime -and $_.startTime) {
                ([datetime]$_.startTime - [datetime]$_.queueTime).TotalMinutes
            } else { 0 }
            Reason = $_.reason
        }
    }
    
    # Generate report
    Write-Host "Pipeline Health Report:" -ForegroundColor Cyan
    Write-Host "Recent Builds: $($builds.count)" -ForegroundColor Green
    
    $successRate = ($analysis | Where-Object Result -eq "succeeded").Count / $analysis.Count * 100
    Write-Host "Success Rate: $([math]::Round($successRate, 2))%" -ForegroundColor $(if($successRate -gt 80) {"Green"} else {"Red"})
    
    $avgDuration = ($analysis | Where-Object Duration -ne "Running" | Measure-Object Duration -Average).Average
    Write-Host "Average Duration: $([math]::Round($avgDuration, 2)) minutes" -ForegroundColor Yellow
    
    return $analysis
}
```

### Error Resolution Guide

| Error Type | Symptoms | Resolution |
|------------|----------|------------|
| **Agent Pool Shortage** | Jobs queued for long time | Scale agent pools or use Microsoft-hosted agents |
| **Package Restore Failure** | NuGet/npm restore fails | Check package sources and authentication |
| **Test Failures** | Random test failures | Implement test isolation and retry logic |
| **Deployment Timeout** | Deployment steps time out | Increase timeout values and optimize deployment |
| **Permission Denied** | Access denied errors | Review service connection permissions |

## 📚 **Best Practices**

### Pipeline Design Principles

```markdown
### Design Guidelines

**1. Fail Fast Principle**
- Run fastest tests first
- Validate syntax and basic checks early
- Use parallel jobs for independent tasks

**2. Immutable Artifacts**
- Build once, deploy many times
- Version all artifacts consistently
- Store artifacts in secure, accessible locations

**3. Environment Parity**
- Use identical deployment processes across environments
- Infrastructure as Code for environment consistency
- Configuration management through variables

**4. Security by Default**
- Scan code for vulnerabilities early
- Use secure variable groups for secrets
- Implement least-privilege access

**5. Observability**
- Comprehensive logging and monitoring
- Performance metrics collection
- Alerting for failures and anomalies
```

### Pipeline Templates Library

```yaml
# templates/security-scan.yml
parameters:
- name: scanType
  type: string
  values:
  - 'sast'
  - 'dast'
  - 'dependencies'
- name: projectPath
  type: string

steps:
- ${{ if eq(parameters.scanType, 'sast') }}:
  - task: SonarCloudAnalyze@1
    inputs:
      projectPath: ${{ parameters.projectPath }}

- ${{ if eq(parameters.scanType, 'dast') }}:
  - task: OWASP-ZAP@1
    inputs:
      targetUrl: '$(applicationUrl)'

- ${{ if eq(parameters.scanType, 'dependencies') }}:
  - task: dependency-check-build-task@6
    inputs:
      projectName: '$(Build.Repository.Name)'
      scanPath: ${{ parameters.projectPath }}
```

### Governance and Compliance

```yaml
# Pipeline with governance controls
resources:
  pipelines:
  - pipeline: security-baseline
    source: security-baseline-pipeline
    trigger:
      branches:
        include:
        - main

extends:
  template: templates/governance-pipeline.yml
  parameters:
    complianceChecks:
    - codeQuality
    - securityScan
    - licenseScan
    approvalGates:
    - environment: 'staging'
      approvers: ['security-team', 'architecture-team']
    - environment: 'production'
      approvers: ['release-manager', 'business-owner']
```

---

## 📖 **Additional Resources**

- [Azure Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [YAML Schema Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/)
- [Pipeline Templates](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates/)
- [DevOps Best Practices](https://docs.microsoft.com/en-us/azure/devops/learn/)

[Back to Azure DevOps Getting Started](getting-started.md) | [Back to Development Home](../index.md)
