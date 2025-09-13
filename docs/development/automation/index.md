---
title: CI/CD Automation
description: Complete guide to continuous integration and deployment automation, pipeline design, and automated testing strategies
author: Joseph Streeter
date: 2024-01-15
tags: [ci-cd, automation, testing, deployment, pipelines, gitlab, github-actions]
---

Continuous Integration and Continuous Deployment (CI/CD) automation is essential for modern software development. This guide covers pipeline design, automated testing, deployment strategies, and best practices for reliable software delivery.

## CI/CD Pipeline Fundamentals

### Pipeline Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Stages                        │
├─────────────────────────────────────────────────────────────────┤
│  Source → Build → Test → Security → Package → Deploy → Monitor  │
│                                                                 │
│  ├─ Git triggers          ├─ Static analysis    ├─ Blue-green   │
│  ├─ Code validation       ├─ Vulnerability scan ├─ Canary       │
│  ├─ Dependency check      ├─ Container build    ├─ Rolling      │
│  └─ Quality gates         └─ Artifact registry  └─ A/B testing  │
└─────────────────────────────────────────────────────────────────┘
```

### Pipeline Design Principles

- **Fast feedback** - Keep build times under 10 minutes
- **Fail fast** - Run cheaper tests first
- **Parallel execution** - Run tests and builds concurrently
- **Idempotent** - Same inputs always produce same outputs
- **Rollback capable** - Easy reversion to previous versions
- **Observable** - Comprehensive logging and monitoring

## GitHub Actions Implementation

### Repository Structure

```text
.github/
├── workflows/
│   ├── ci.yml
│   ├── cd.yml
│   ├── security.yml
│   └── release.yml
├── actions/
│   ├── setup-node/
│   └── deploy-app/
└── CODEOWNERS
```

### Comprehensive CI Pipeline

```yaml
# .github/workflows/ci.yml
name: Continuous Integration

on:
  push:
    branches: [ main, develop, 'feature/*' ]
  pull_request:
    branches: [ main, develop ]

env:
  NODE_VERSION: '18.x'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      backend: ${{ steps.changes.outputs.backend }}
      frontend: ${{ steps.changes.outputs.frontend }}
      infrastructure: ${{ steps.changes.outputs.infrastructure }}
    steps:
      - uses: actions/checkout@v3
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            backend:
              - 'backend/**'
              - 'package.json'
              - 'package-lock.json'
            frontend:
              - 'frontend/**'
              - 'frontend/package.json'
            infrastructure:
              - 'infrastructure/**'
              - 'docker/**'

  lint:
    runs-on: ubuntu-latest
    needs: changes
    if: needs.changes.outputs.backend == 'true' || needs.changes.outputs.frontend == 'true'
    
    strategy:
      matrix:
        component: [backend, frontend]
        include:
          - component: backend
            path: ./backend
          - component: frontend
            path: ./frontend
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: ${{ matrix.path }}/package-lock.json
      
      - name: Install dependencies
        run: npm ci
        working-directory: ${{ matrix.path }}
      
      - name: Run ESLint
        run: npm run lint
        working-directory: ${{ matrix.path }}
      
      - name: Run Prettier
        run: npm run format:check
        working-directory: ${{ matrix.path }}
      
      - name: Type checking
        run: npm run type-check
        working-directory: ${{ matrix.path }}

  test:
    runs-on: ubuntu-latest
    needs: [changes, lint]
    if: needs.changes.outputs.backend == 'true' || needs.changes.outputs.frontend == 'true'
    
    strategy:
      matrix:
        component: [backend, frontend]
        node-version: [16.x, 18.x, 20.x]
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
          cache-dependency-path: ${{ matrix.component }}/package-lock.json
      
      - name: Install dependencies
        run: npm ci
        working-directory: ${{ matrix.component }}
      
      - name: Run unit tests
        run: npm run test:unit -- --coverage
        working-directory: ${{ matrix.component }}
        env:
          NODE_ENV: test
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
      
      - name: Run integration tests
        run: npm run test:integration
        working-directory: ${{ matrix.component }}
        env:
          NODE_ENV: test
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ${{ matrix.component }}/coverage/lcov.info
          flags: ${{ matrix.component }}

  e2e:
    runs-on: ubuntu-latest
    needs: [changes, test]
    if: needs.changes.outputs.backend == 'true' || needs.changes.outputs.frontend == 'true'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: |
          npm ci --prefix backend
          npm ci --prefix frontend
      
      - name: Build application
        run: |
          npm run build --prefix backend
          npm run build --prefix frontend
      
      - name: Start application
        run: |
          npm run start --prefix backend &
          npm run start --prefix frontend &
          sleep 30
        env:
          NODE_ENV: test
          PORT: 3000
          FRONTEND_PORT: 3001
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          BASE_URL: http://localhost:3001
          API_URL: http://localhost:3000
      
      - name: Upload E2E artifacts
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: e2e-artifacts
          path: |
            cypress/screenshots
            cypress/videos

  security:
    runs-on: ubuntu-latest
    needs: changes
    if: needs.changes.outputs.backend == 'true' || needs.changes.outputs.frontend == 'true'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install dependencies
        run: |
          npm ci --prefix backend
          npm ci --prefix frontend
      
      - name: Run npm audit
        run: |
          npm audit --audit-level=high --prefix backend
          npm audit --audit-level=high --prefix frontend
      
      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --all-projects --severity-threshold=high
      
      - name: SAST with Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: auto

  build:
    runs-on: ubuntu-latest
    needs: [lint, test, security]
    if: github.event_name == 'push'
    
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      image-url: ${{ steps.build.outputs.image-url }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
          labels: |
            org.opencontainers.image.title=${{ github.repository }}
            org.opencontainers.image.description=Application container
            org.opencontainers.image.vendor=${{ github.repository_owner }}
      
      - name: Build and push
        id: build
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
      
      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: spdx-json
          output-file: sbom.spdx.json
      
      - name: Upload SBOM
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: sbom.spdx.json

  quality-gate:
    runs-on: ubuntu-latest
    needs: [lint, test, e2e, security, build]
    if: always()
    
    steps:
      - name: Check quality gate
        run: |
          if [[ "${{ needs.lint.result }}" != "success" ]]; then
            echo "Lint check failed"
            exit 1
          fi
          
          if [[ "${{ needs.test.result }}" != "success" ]]; then
            echo "Tests failed"
            exit 1
          fi
          
          if [[ "${{ needs.e2e.result }}" != "success" ]]; then
            echo "E2E tests failed"
            exit 1
          fi
          
          if [[ "${{ needs.security.result }}" != "success" ]]; then
            echo "Security checks failed"
            exit 1
          fi
          
          if [[ "${{ needs.build.result }}" != "success" && "${{ github.event_name }}" == "push" ]]; then
            echo "Build failed"
            exit 1
          fi
          
          echo "All quality gates passed!"
```

### Deployment Pipeline

```yaml
# .github/workflows/cd.yml
name: Continuous Deployment

on:
  workflow_run:
    workflows: ["Continuous Integration"]
    types:
      - completed
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    if: github.event.workflow_run.conclusion == 'success' && github.event.workflow_run.head_branch == 'develop'
    environment: staging
    
    steps:
      - uses: actions/checkout@v3
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.27.0'
      
      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name staging-cluster --region us-west-2
      
      - name: Deploy to staging
        run: |
          IMAGE_TAG="${{ github.event.workflow_run.head_sha }}"
          helm upgrade --install myapp ./helm-chart \
            --namespace staging \
            --create-namespace \
            --set image.tag=$IMAGE_TAG \
            --set environment=staging \
            --set replicas=2 \
            --wait --timeout=600s
      
      - name: Run smoke tests
        run: |
          kubectl wait --for=condition=ready pod -l app=myapp -n staging --timeout=300s
          
          # Get service endpoint
          ENDPOINT=$(kubectl get service myapp -n staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
          
          # Wait for endpoint to be ready
          timeout 300 bash -c 'until curl -f http://'$ENDPOINT'/health; do sleep 5; done'
          
          # Run smoke tests
          curl -f http://$ENDPOINT/health
          curl -f http://$ENDPOINT/api/v1/status
      
      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          fields: repo,message,commit,author,action,eventName,ref,workflow

  deploy-production:
    runs-on: ubuntu-latest
    if: github.event.workflow_run.conclusion == 'success' && github.event.workflow_run.head_branch == 'main'
    environment: production
    needs: []
    
    strategy:
      matrix:
        deployment-type: [blue-green]
    
    steps:
      - uses: actions/checkout@v3
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.27.0'
      
      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name production-cluster --region us-west-2
      
      - name: Blue-Green Deployment
        run: |
          IMAGE_TAG="${{ github.event.workflow_run.head_sha }}"
          
          # Determine current and target slots
          CURRENT_SLOT=$(kubectl get service myapp -n production -o jsonpath='{.spec.selector.slot}' || echo "blue")
          if [ "$CURRENT_SLOT" = "blue" ]; then
            TARGET_SLOT="green"
          else
            TARGET_SLOT="blue"
          fi
          
          echo "Current slot: $CURRENT_SLOT"
          echo "Target slot: $TARGET_SLOT"
          
          # Deploy to target slot
          helm upgrade --install myapp-$TARGET_SLOT ./helm-chart \
            --namespace production \
            --create-namespace \
            --set image.tag=$IMAGE_TAG \
            --set environment=production \
            --set slot=$TARGET_SLOT \
            --set replicas=3 \
            --wait --timeout=600s
          
          # Health check
          kubectl wait --for=condition=ready pod -l app=myapp,slot=$TARGET_SLOT -n production --timeout=300s
          
          # Run production tests
          ENDPOINT=$(kubectl get service myapp-$TARGET_SLOT -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
          timeout 300 bash -c 'until curl -f http://'$ENDPOINT'/health; do sleep 5; done'
          
          # Switch traffic
          kubectl patch service myapp -n production -p '{"spec":{"selector":{"slot":"'$TARGET_SLOT'"}}}'
          
          # Wait and verify
          sleep 30
          curl -f http://$(kubectl get service myapp -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/health
          
          # Scale down old slot after successful switch
          helm uninstall myapp-$CURRENT_SLOT -n production || true
```

## GitLab CI/CD Implementation

### GitLab CI Configuration

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test
  - security
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  REGISTRY: $CI_REGISTRY
  IMAGE_NAME: $CI_PROJECT_PATH

# Global before_script
before_script:
  - docker info

# Templates
.node_template: &node_template
  image: node:18-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline

.docker_template: &docker_template
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY

# Validation stage
lint:
  <<: *node_template
  stage: validate
  script:
    - npm run lint
    - npm run format:check
    - npm run type-check
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Test stage
unit-tests:
  <<: *node_template
  stage: test
  services:
    - postgres:13-alpine
    - redis:6-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    POSTGRES_HOST_AUTH_METHOD: trust
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test_db
    REDIS_URL: redis://redis:6379
  script:
    - npm run test:unit -- --coverage
    - npm run test:integration
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/
    expire_in: 1 week

e2e-tests:
  <<: *node_template
  stage: test
  script:
    - npm run build
    - npm run start &
    - sleep 30
    - npm run test:e2e
  artifacts:
    when: on_failure
    paths:
      - cypress/screenshots
      - cypress/videos
    expire_in: 1 week

# Security stage
security-scan:
  image: securecodewarrior/docker-security-scanner:latest
  stage: security
  script:
    - npm audit --audit-level=high
    - docker run --rm -v $PWD:/app securecodewarrior/security-scanner /app
  allow_failure: true

sast:
  stage: security
  script:
    - echo "Running SAST scan"
  include:
    - template: Security/SAST.gitlab-ci.yml

dependency_scanning:
  stage: security
  script:
    - echo "Running dependency scan"
  include:
    - template: Security/Dependency-Scanning.gitlab-ci.yml

# Build stage
build:
  <<: *docker_template
  stage: build
  script:
    - docker build --pull -t $REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA .
    - docker push $REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]; then
        docker tag $REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA $REGISTRY/$IMAGE_NAME:latest
        docker push $REGISTRY/$IMAGE_NAME:latest
      fi
  only:
    - main
    - develop

# Deployment stages
deploy-staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  environment:
    name: staging
    url: https://staging.myapp.com
  script:
    - kubectl config use-context staging-cluster
    - |
      helm upgrade --install myapp ./helm-chart \
        --namespace staging \
        --create-namespace \
        --set image.tag=$CI_COMMIT_SHA \
        --set environment=staging \
        --wait --timeout=600s
    - kubectl rollout status deployment/myapp -n staging
  only:
    - develop

deploy-production:
  stage: deploy-production
  image: bitnami/kubectl:latest
  environment:
    name: production
    url: https://myapp.com
  when: manual
  script:
    - kubectl config use-context production-cluster
    - |
      helm upgrade --install myapp ./helm-chart \
        --namespace production \
        --create-namespace \
        --set image.tag=$CI_COMMIT_SHA \
        --set environment=production \
        --set replicas=5 \
        --wait --timeout=600s
    - kubectl rollout status deployment/myapp -n production
    # Run smoke tests
    - curl -f https://myapp.com/health
  only:
    - main
```

## Jenkins Pipeline as Code

### Jenkinsfile Example

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        REGISTRY = 'harbor.company.com'
        IMAGE_NAME = 'myapp'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm ci'
                        sh 'npm run test:unit -- --coverage'
                        publishTestResults testResultsPattern: 'test-results.xml'
                        publishCoverage adapters: [
                            cobertura('coverage/cobertura-coverage.xml')
                        ]
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        script {
                            docker.image('postgres:13').withRun('-e POSTGRES_DB=test') { c ->
                                docker.image('redis:6').withRun() { r ->
                                    sh '''
                                        export DATABASE_URL=postgresql://postgres@postgres:5432/test
                                        export REDIS_URL=redis://redis:6379
                                        npm run test:integration
                                    '''
                                }
                            }
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh 'npm audit --audit-level=high'
                        script {
                            def scanResult = sh(
                                script: 'snyk test --severity-threshold=high',
                                returnStatus: true
                            )
                            if (scanResult != 0) {
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    }
                }
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
                script {
                    def image = docker.build("${REGISTRY}/${IMAGE_NAME}:${env.GIT_COMMIT_SHORT}")
                    docker.withRegistry("https://${REGISTRY}", 'harbor-credentials') {
                        image.push()
                        if (env.BRANCH_NAME == 'main') {
                            image.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when { branch 'develop' }
            steps {
                script {
                    kubernetesDeploy(
                        configs: 'k8s/staging/*.yaml',
                        kubeconfigId: 'kubeconfig'
                    )
                    
                    // Wait for deployment
                    sh '''
                        kubectl rollout status deployment/myapp -n staging --timeout=300s
                        kubectl wait --for=condition=ready pod -l app=myapp -n staging --timeout=300s
                    '''
                    
                    // Smoke tests
                    sh '''
                        ENDPOINT=$(kubectl get service myapp -n staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                        curl -f http://$ENDPOINT/health
                    '''
                }
            }
        }
        
        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                script {
                    // Blue-green deployment
                    sh '''
                        CURRENT_SLOT=$(kubectl get service myapp -n production -o jsonpath='{.spec.selector.slot}' || echo "blue")
                        if [ "$CURRENT_SLOT" = "blue" ]; then
                            TARGET_SLOT="green"
                        else
                            TARGET_SLOT="blue"
                        fi
                        
                        # Deploy to target slot
                        helm upgrade --install myapp-$TARGET_SLOT ./helm-chart \
                            --namespace production \
                            --set image.tag=${GIT_COMMIT_SHORT} \
                            --set slot=$TARGET_SLOT \
                            --wait --timeout=600s
                        
                        # Health check and switch traffic
                        kubectl wait --for=condition=ready pod -l app=myapp,slot=$TARGET_SLOT -n production --timeout=300s
                        kubectl patch service myapp -n production -p '{"spec":{"selector":{"slot":"'$TARGET_SLOT'"}}}'
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Pipeline succeeded for ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Pipeline failed for ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

## Testing Automation

### Test Pyramid Implementation

```javascript
// jest.config.js
module.exports = {
  projects: [
    {
      displayName: 'unit',
      testMatch: ['<rootDir>/src/**/*.test.js'],
      testEnvironment: 'node',
      collectCoverageFrom: [
        'src/**/*.js',
        '!src/**/*.test.js',
        '!src/test/**'
      ],
      coverageThreshold: {
        global: {
          branches: 80,
          functions: 80,
          lines: 80,
          statements: 80
        }
      }
    },
    {
      displayName: 'integration',
      testMatch: ['<rootDir>/test/integration/**/*.test.js'],
      testEnvironment: 'node',
      setupFilesAfterEnv: ['<rootDir>/test/setup/integration.js']
    }
  ]
};
```

### Automated API Testing

```javascript
// test/integration/api.test.js
const request = require('supertest');
const app = require('../../src/app');
const { setupTestDb, teardownTestDb } = require('../setup/database');

describe('API Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDb();
  });

  afterAll(async () => {
    await teardownTestDb();
  });

  describe('Authentication', () => {
    test('POST /auth/login should return JWT token', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user).not.toHaveProperty('password');
    });

    test('POST /auth/login should return 401 for invalid credentials', async () => {
      await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'wrongpassword'
        })
        .expect(401);
    });
  });

  describe('Protected Routes', () => {
    let authToken;

    beforeEach(async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      authToken = response.body.token;
    });

    test('GET /api/users should require authentication', async () => {
      await request(app)
        .get('/api/users')
        .expect(401);
    });

    test('GET /api/users should return users with valid token', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });
  });
});
```

### Load Testing with Artillery

```yaml
# load-test.yml
config:
  target: "https://api.myapp.com"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"
  processor: "./test-functions.js"

scenarios:
  - name: "User journey"
    weight: 70
    flow:
      - post:
          url: "/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
          capture:
            - json: "$.token"
              as: "authToken"
      - get:
          url: "/api/users"
          headers:
            Authorization: "Bearer {{ authToken }}"
      - get:
          url: "/api/users/{{ $randomInt(1, 100) }}"
          headers:
            Authorization: "Bearer {{ authToken }}"

  - name: "Health check"
    weight: 30
    flow:
      - get:
          url: "/health"
```

## Related Topics

- [DevOps Best Practices](../devops/index.md)
- [Container Orchestration](../../infrastructure/containers/orchestration/index.md)
- [Infrastructure Monitoring](../../infrastructure/monitoring/index.md)
- [Container Security](../../infrastructure/containers/security/index.md)
