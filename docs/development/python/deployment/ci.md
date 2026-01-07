---
title: Continuous Integration for Python
description: Comprehensive guide to CI/CD pipelines for Python projects using GitHub Actions, Azure DevOps, GitLab CI, and Jenkins with best practices
author: Joseph Streeter
ms.date: 01/05/2026
ms.topic: article
---

Continuous Integration (CI) is the practice of automatically building, testing, and validating code changes as they are committed to version control. For Python projects, CI ensures code quality, catches bugs early, and maintains consistent development workflows.

## Overview

CI/CD (Continuous Integration/Continuous Deployment) automates the software delivery pipeline, from code commits through testing, building, and deployment. Python's ecosystem integrates seamlessly with major CI platforms, enabling teams to maintain high-quality codebases while moving quickly.

This guide covers setting up CI pipelines for Python projects on popular platforms, best practices for testing and deployment, and strategies for optimizing build performance.

## Key Concepts

### Continuous Integration (CI)

Automated testing and validation of code changes:

- **Automated Testing**: Run unit, integration, and end-to-end tests
- **Code Quality**: Lint, format, and security checks
- **Build Verification**: Ensure code compiles and dependencies resolve
- **Fast Feedback**: Developers get immediate results on their changes

### Continuous Deployment (CD)

Automated delivery of code to production:

- **Staging Deployments**: Automated deployment to test environments
- **Production Releases**: Push validated code to production
- **Rollback Capability**: Quickly revert problematic deployments
- **Progressive Delivery**: Canary releases, blue-green deployments

### CI/CD Pipeline Stages

Typical Python CI/CD pipeline:

1. **Trigger**: Code push, pull request, or scheduled run
2. **Setup**: Install Python, dependencies, tools
3. **Lint**: Check code style and quality (ruff, flake8, pylint)
4. **Test**: Run test suites (pytest, unittest)
5. **Coverage**: Measure test coverage (coverage.py)
6. **Security**: Scan for vulnerabilities (bandit, safety)
7. **Build**: Package application (wheel, Docker image)
8. **Deploy**: Push to staging or production

## GitHub Actions

### Basic Python Workflow

Create `.github/workflows/python-ci.yml`:

```yaml
name: Python CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11', '3.12']
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Lint with ruff
      run: |
        pip install ruff
        ruff check .
    
    - name: Test with pytest
      run: |
        pip install pytest pytest-cov
        pytest --cov=./src --cov-report=xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v4
      with:
        file: ./coverage.xml
        fail_ci_if_error: true
```

### Advanced GitHub Actions Workflow

```yaml
name: Advanced Python CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly dependency checks

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12'
        cache: 'pip'
    
    - name: Install linting tools
      run: |
        pip install ruff black isort mypy
    
    - name: Run ruff
      run: ruff check .
    
    - name: Check formatting with black
      run: black --check .
    
    - name: Check import order
      run: isort --check-only .
    
    - name: Type check with mypy
      run: mypy src/ --strict

  test:
    needs: lint
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.9', '3.10', '3.11', '3.12']
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}
        cache: 'pip'
    
    - name: Install dependencies
      run: |
        pip install -e .[dev]
    
    - name: Run tests
      run: |
        pytest -v --cov=src --cov-report=term --cov-report=xml
    
    - name: Upload coverage
      if: matrix.os == 'ubuntu-latest' && matrix.python-version == '3.12'
      uses: codecov/codecov-action@v4

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12'
    
    - name: Install security tools
      run: |
        pip install bandit safety pip-audit
    
    - name: Run bandit
      run: bandit -r src/
    
    - name: Check dependencies with safety
      run: safety check
    
    - name: Audit with pip-audit
      run: pip-audit

  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12'
    
    - name: Build package
      run: |
        pip install build
        python -m build
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: dist
        path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Download artifacts
      uses: actions/download-artifact@v4
      with:
        name: dist
        path: dist/
    
    - name: Publish to PyPI
      uses: pypa/gh-action-pypi-publish@release/v1
      with:
        password: ${{ secrets.PYPI_API_TOKEN }}
```

### GitHub Actions with Docker

```yaml
name: Docker CI

on:
  push:
    branches: [ main ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: myapp:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

### GitHub Actions with UV

Ultra-fast dependency installation:

```yaml
name: Python CI with UV

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install UV
      run: curl -LsSf https://astral.sh/uv/install.sh | sh
    
    - name: Set up Python with UV
      run: |
        uv venv
        source .venv/bin/activate
        uv pip install -r requirements.txt
        uv pip install pytest pytest-cov ruff
    
    - name: Run tests
      run: |
        source .venv/bin/activate
        pytest --cov=src
```

## Azure DevOps

### Basic Azure Pipeline

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

strategy:
  matrix:
    Python39:
      python.version: '3.9'
    Python310:
      python.version: '3.10'
    Python311:
      python.version: '3.11'
    Python312:
      python.version: '3.12'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '$(python.version)'
  displayName: 'Use Python $(python.version)'

- script: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    pip install pytest pytest-cov ruff
  displayName: 'Install dependencies'

- script: |
    ruff check .
  displayName: 'Lint with ruff'

- script: |
    pytest --junitxml=junit/test-results.xml --cov=. --cov-report=xml
  displayName: 'Run tests'

- task: PublishTestResults@2
  condition: succeededOrFailed()
  inputs:
    testResultsFiles: '**/test-*.xml'
    testRunTitle: 'Python $(python.version)'

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: Cobertura
    summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'
```

### Multi-Stage Azure Pipeline

```yaml
stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Test
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      matrix:
        Python311:
          python.version: '3.11'
        Python312:
          python.version: '3.12'
    
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(python.version)'
    
    - script: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
      displayName: 'Install dependencies'
    
    - script: |
        pytest --junitxml=junit/test-results.xml --cov=src
      displayName: 'Test'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFiles: '**/test-*.xml'

- stage: Security
  displayName: 'Security Scanning'
  dependsOn: Build
  jobs:
  - job: SecurityScan
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.12'
    
    - script: |
        pip install bandit safety
        bandit -r src/ -f json -o bandit-report.json
        safety check --json > safety-report.json
      displayName: 'Security checks'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(System.DefaultWorkingDirectory)'
        artifactName: 'security-reports'

- stage: Deploy
  displayName: 'Deploy to Production'
  dependsOn: [Build, Security]
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployWeb
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: |
              echo "Deploying to production"
            displayName: 'Deploy'
```

## GitLab CI

### Basic GitLab Pipeline

Create `.gitlab-ci.yml`:

```yaml
image: python:3.12

stages:
  - lint
  - test
  - security
  - build
  - deploy

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip
    - venv/

before_script:
  - python -m venv venv
  - source venv/bin/activate
  - pip install --upgrade pip
  - pip install -r requirements.txt

lint:
  stage: lint
  script:
    - pip install ruff black mypy
    - ruff check .
    - black --check .
    - mypy src/

test:
  stage: test
  parallel:
    matrix:
      - PYTHON_VERSION: ['3.9', '3.10', '3.11', '3.12']
  image: python:${PYTHON_VERSION}
  script:
    - pip install pytest pytest-cov
    - pytest --cov=src --cov-report=xml --cov-report=term
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

security:
  stage: security
  script:
    - pip install bandit safety pip-audit
    - bandit -r src/
    - safety check
    - pip-audit
  allow_failure: true

build:
  stage: build
  script:
    - pip install build
    - python -m build
  artifacts:
    paths:
      - dist/
  only:
    - main

deploy:
  stage: deploy
  script:
    - pip install twine
    - twine upload dist/*
  only:
    - main
  when: manual
  environment:
    name: production
```

### GitLab CI with Docker

```yaml
docker-build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
```

## Jenkins

### Jenkinsfile for Python

```groovy
pipeline {
    agent any
    
    environment {
        PYTHON_VERSION = '3.12'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                sh '''
                    python${PYTHON_VERSION} -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install -r requirements-dev.txt
                '''
            }
        }
        
        stage('Lint') {
            steps {
                sh '''
                    . venv/bin/activate
                    ruff check .
                    black --check .
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    . venv/bin/activate
                    pytest --junitxml=results.xml --cov=src --cov-report=xml
                '''
            }
            post {
                always {
                    junit 'results.xml'
                    cobertura coberturaReportFile: 'coverage.xml'
                }
            }
        }
        
        stage('Security') {
            steps {
                sh '''
                    . venv/bin/activate
                    bandit -r src/ -f json -o bandit-report.json
                    safety check --json > safety-report.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: '*-report.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Build') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    . venv/bin/activate
                    python -m build
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'dist/*', fingerprint: true
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh '''
                    . venv/bin/activate
                    twine upload dist/*
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### Declarative Pipeline with Docker

```groovy
pipeline {
    agent {
        docker {
            image 'python:3.12'
            args '-v $HOME/.cache/pip:/root/.cache/pip'
        }
    }
    
    stages {
        stage('Install') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }
        
        stage('Test') {
            steps {
                sh 'pytest --junitxml=results.xml'
            }
        }
    }
    
    post {
        always {
            junit 'results.xml'
        }
    }
}
```

## CircleCI

### Basic CircleCI Configuration

Create `.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  python: circleci/python@2.1.1

workflows:
  main:
    jobs:
      - test:
          matrix:
            parameters:
              version: ["3.9", "3.10", "3.11", "3.12"]

jobs:
  test:
    parameters:
      version:
        type: string
    docker:
      - image: cimg/python:<< parameters.version >>
    steps:
      - checkout
      - restore_cache:
          keys:
            - deps-{{ checksum "requirements.txt" }}
      - run:
          name: Install dependencies
          command: |
            pip install -r requirements.txt
            pip install pytest pytest-cov ruff
      - save_cache:
          key: deps-{{ checksum "requirements.txt" }}
          paths:
            - ~/.cache/pip
      - run:
          name: Lint
          command: ruff check .
      - run:
          name: Test
          command: pytest --junitxml=test-results/junit.xml --cov=src
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: test-results
```

## Testing Strategies

### Test Matrix

Test across multiple Python versions and dependencies:

```yaml
# GitHub Actions
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11', '3.12']
    django-version: ['3.2', '4.0', '4.2']
    exclude:
      - python-version: '3.9'
        django-version: '4.2'
```

### Parallel Testing

```yaml
# GitLab CI
test:
  parallel: 4
  script:
    - pytest --splits 4 --group $CI_NODE_INDEX
```

### Test Coverage Requirements

```yaml
# GitHub Actions
- name: Check coverage threshold
  run: |
    coverage report --fail-under=80
```

### Integration Tests

```yaml
# Docker Compose for integration tests
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: testpass
  redis:
    image: redis:7

jobs:
  integration-test:
    services:
      postgres: postgres
      redis: redis
    steps:
      - name: Run integration tests
        run: pytest tests/integration/
        env:
          DATABASE_URL: postgresql://postgres:testpass@postgres/testdb
          REDIS_URL: redis://redis:6379
```

## Caching Strategies

### Caching Dependencies

**GitHub Actions**:

```yaml
- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'
```

**GitLab CI**:

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .cache/pip
    - venv/
```

**Azure DevOps**:

```yaml
- task: Cache@2
  inputs:
    key: 'pip | "$(Agent.OS)" | requirements.txt'
    path: $(PIP_CACHE_DIR)
```

### Docker Layer Caching

```dockerfile
# Multi-stage build with layer caching
FROM python:3.12-slim as base

WORKDIR /app

# Cache dependencies layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application layer
COPY . .

CMD ["python", "app.py"]
```

## Security Scanning

### Dependency Scanning

```yaml
security:
  steps:
    - name: Check dependencies
      run: |
        pip install safety pip-audit
        safety check --json
        pip-audit --format json
```

### Code Security Analysis

```yaml
- name: Bandit security scan
  run: |
    pip install bandit
    bandit -r src/ -f json -o bandit-report.json
```

### Secret Detection

```yaml
- name: Detect secrets
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: ${{ github.event.repository.default_branch }}
    head: HEAD
```

## Best Practices

### Pipeline Structure

✅ **Do**:

- Keep pipelines fast (< 10 minutes ideal)
- Run lint checks before tests
- Use matrix builds for multiple versions
- Cache dependencies aggressively
- Fail fast on critical errors
- Separate build and deploy stages
- Use artifacts for build outputs

❌ **Don't**:

- Run all tests on every commit (use test selection)
- Install dependencies without caching
- Deploy without manual approval for production
- Ignore security warnings
- Skip linting to save time

### Performance Optimization

```yaml
# Run quick checks first
stages:
  - quick-check    # < 1 minute
  - test          # < 5 minutes
  - integration   # < 10 minutes
  - deploy        # manual trigger
```

### Environment Variables

```yaml
# GitHub Actions
env:
  PYTHONUNBUFFERED: 1
  PYTHONDONTWRITEBYTECODE: 1
  PIP_NO_CACHE_DIR: off
  PIP_DISABLE_PIP_VERSION_CHECK: on
  PIP_DEFAULT_TIMEOUT: 100
```

### Dependency Management

```yaml
# Use lock files for reproducible builds
- name: Install dependencies
  run: |
    pip install -r requirements.txt --require-hashes
```

### Test Reporting

```yaml
# Store test results and coverage
- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    fail_ci_if_error: true
    token: ${{ secrets.CODECOV_TOKEN }}
```

## Common Patterns

### Monorepo Testing

```yaml
# Only test changed services
- name: Detect changes
  uses: dorny/paths-filter@v2
  id: changes
  with:
    filters: |
      api:
        - 'services/api/**'
      worker:
        - 'services/worker/**'

- name: Test API
  if: steps.changes.outputs.api == 'true'
  run: pytest services/api/tests/
```

### Conditional Deployment

```yaml
# Deploy to staging on develop, production on main
deploy:
  script:
    - |
      if [ "$CI_COMMIT_BRANCH" == "main" ]; then
        deploy_to_production
      elif [ "$CI_COMMIT_BRANCH" == "develop" ]; then
        deploy_to_staging
      fi
```

### Matrix Builds with Exclusions

```yaml
strategy:
  matrix:
    python: ['3.9', '3.10', '3.11', '3.12']
    os: [ubuntu-latest, windows-latest, macos-latest]
    exclude:
      # Skip Windows + Python 3.9
      - python: '3.9'
        os: windows-latest
```

### Nightly Builds

```yaml
# Run comprehensive tests nightly
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:     # Manual trigger

jobs:
  extended-tests:
    steps:
      - name: Run all tests including slow ones
        run: pytest --slow
```

## Troubleshooting

### Common Issues

**Flaky Tests**:

```yaml
# Retry flaky tests
- name: Run tests with retries
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: pytest
```

**Timeout Issues**:

```yaml
# Set appropriate timeouts
jobs:
  test:
    timeout-minutes: 30
```

**Dependency Conflicts**:

```yaml
# Use constraint files
- name: Install with constraints
  run: pip install -r requirements.txt -c constraints.txt
```

**Cache Invalidation**:

```yaml
# Cache with multiple keys
- uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

### Debug Mode

```yaml
# Enable verbose logging
- name: Run with debug
  run: |
    set -x  # Bash debug mode
    pytest -vv --log-cli-level=DEBUG
  env:
    CI_DEBUG: true
```

## Advanced Workflows

### Semantic Versioning

```yaml
- name: Semantic release
  uses: cycjimmy/semantic-release-action@v3
  with:
    semantic_version: 19
    extra_plugins: |
      @semantic-release/changelog
      @semantic-release/git
```

### Automated Dependency Updates

```yaml
# Dependabot configuration
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "team-reviewers"
    labels:
      - "dependencies"
```

### Performance Testing

```yaml
- name: Run performance benchmarks
  run: |
    pytest tests/performance/ --benchmark-only
    pytest-benchmark compare
```

## See Also

- [Python Testing Guide](../testing/index.md)
- [Deployment Overview](index.md)
- [Cloud Deployment](cloud-deployment.md)
- [Package Management](../package-management/index.md)
- [Packaging Guide](packaging.md)

## Additional Resources

### Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [CircleCI Documentation](https://circleci.com/docs/)

### Tools

- [pytest](https://docs.pytest.org/) - Testing framework
- [coverage.py](https://coverage.readthedocs.io/) - Code coverage
- [ruff](https://github.com/astral-sh/ruff) - Fast Python linter
- [bandit](https://bandit.readthedocs.io/) - Security linter
- [safety](https://github.com/pyupio/safety) - Dependency vulnerability scanner
- [tox](https://tox.wiki/) - Test automation
- [pre-commit](https://pre-commit.com/) - Git hook management

### Learning Resources

- [Python CI/CD Best Practices](https://realpython.com/python-continuous-integration/)
- [GitHub Actions for Python](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-python)
- [Testing Python Applications](https://testdriven.io/)

### Community

- [r/Python on Reddit](https://www.reddit.com/r/Python/)
- [Python Discord](https://discord.gg/python)
- [Stack Overflow - CI/CD Tag](https://stackoverflow.com/questions/tagged/continuous-integration+python)
