---
title: "YAML Pipeline Reference — GitHub Actions & Azure DevOps"
description: "Reference guide for YAML pipelines in GitHub Actions and Azure DevOps: syntax, triggers, jobs, steps, variables, templates, secrets, deployment strategies and best practices."
keywords: "yaml pipelines, github actions, azure devops, ci cd, pipeline templates, pipeline variables"
author: "Joseph Streeter"
ms.topic: "reference"
ms.date: "2025-11-27"
---

 
This reference provides concise, practical YAML examples and patterns for building CI/CD pipelines in both GitHub Actions and Azure DevOps. It focuses on common pipeline concepts, cross-platform patterns, and direct examples you can copy and adapt.

## Quick comparison

| Feature | GitHub Actions | Azure DevOps YAML |
|---|---:|---:|
| Trigger syntax | `on:` | `trigger:` / `pr:` / `resources:` |
| Job matrix | `strategy.matrix` | `strategy.matrix` |
| Templates | reusable workflows / `workflow_call` | `templates:` includes |
| Secret storage | GitHub Secrets | Variable groups / Azure Key Vault |
| Hosted runners/agents | GitHub-hosted runners | Microsoft-hosted agents / self-hosted agents |

---

## Common concepts

- Workflow / Pipeline: top-level YAML defining when pipelines run and what they do.
- Job / Stage: a unit of work that runs on a runner/agent. Jobs run in parallel by default.
- Step / Task: sequential commands or actions/tasks within a job.
- Runner / Agent: the machine that executes steps.
- Artifact: produced outputs (build artifacts, test results) stored for later download or deployment.
- Secret / Secure variable: secure values injected at runtime kept out of logs.

---

## GitHub Actions: Essentials

### Minimal workflow example

```yaml
name: CI
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Install deps
        run: npm ci
      - name: Run tests
        run: npm test
```

### Triggers

- `on: push` — runs on push to any branch
- `on: push: branches: [main]` — restrict to branches
- `on: pull_request` — runs for PR events
- `on: schedule` — cron style
- `on: workflow_dispatch` — manual trigger with inputs

Example with multiple triggers:

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  schedule:
    - cron: '0 2 * * *'  # daily at 02:00 UTC
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
```

### Jobs, steps and environment

- Use `runs-on` to select runner type (ubuntu-latest, windows-latest, macos-latest)
- `env:` sets environment variables for a job or step
- `uses:` calls an action (official, marketplace, or local)
- `run:` executes shell commands

### Matrix builds

```yaml
strategy:
  matrix:
    node: [16, 18]
    os: [ubuntu-latest, windows-latest]
  fail-fast: false

steps:
  - uses: actions/checkout@v4
  - name: Setup Node
    uses: actions/setup-node@v4
    with:
      node-version: ${{ matrix.node }}
```

### Reusable workflows (templates)

Define a reusable workflow and call it from another workflow.

Reusable workflow (`.github/workflows/build.yml`):

```yaml
on:
  workflow_call:
    inputs:
      repo:
        required: true
        type: string
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Building ${{ inputs.repo }}"
```

Call the reusable workflow:

```yaml
name: Call shared build
on: [push]

jobs:
  call-build:
    uses: ./.github/workflows/build.yml
    with:
      repo: my-service
```

### Secrets and environment

- Store secrets in GitHub repository/settings > Secrets and variables > Actions.
- Access via `${{ secrets.MY_SECRET }}`
- Avoid logging secrets (use `mask` capabilities in custom actions if required)

### Artifacts and caching

- Upload artifacts with `actions/upload-artifact@v4`
- Cache dependencies with `actions/cache@v4`

Example upload:

```yaml
- name: Upload build artifact
  uses: actions/upload-artifact@v4
  with:
    name: my-app
    path: dist/
```

---

## Azure DevOps YAML: Essentials

### Minimal pipeline example

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- checkout: self
- task: NodeTool@0
  inputs:
    versionSpec: '18.x'
- script: npm ci
- script: npm test
  displayName: 'Run tests'
```

### Triggers (Azure DevOps)

- `trigger:` controls CI triggers for pushes
- `pr:` controls pull-request validation triggers
- `schedules` are defined under `schedules` or via pipeline UI
- `resources:` lets you trigger pipelines on other pipelines, repos, containers

Example: separate push and PR triggers

```yaml
trigger:
  branches:
    include: [main, release/*]
pr:
  branches:
    include: [main]
```

### Jobs, stages and dependencies

- `stages:` contain `jobs:` which contain `steps:`. Stages run sequentially by default.
- Use `dependsOn:` to control cross-stage dependencies.
- `deployment` jobs support environments and strategies (rolling, canary)

Example multi-stage skeleton:

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildJob
    pool: { vmImage: 'ubuntu-latest' }
    steps:
      - script: npm ci
      - script: npm run build

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployWeb
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
            - script: echo Deploying
```

### Templates

- `templates:` allow reuse of steps, jobs, or stages across pipelines
- Use `parameters:` to make templates configurable

Template usage example:

`templates/steps-node.yml`:

```yaml
parameters:
  node-version: '18'
steps:
- task: NodeTool@0
  inputs:
    versionSpec: '${{ parameters.node-version }}'
- script: npm ci
```

Include template in pipeline:

```yaml
steps:
- template: templates/steps-node.yml
  parameters:
    node-version: '16'
```

### Variables and variable groups

- Define variables at pipeline level with `variables:` block
- Use variable groups to share between pipelines and link to Azure Key Vault
- Runtime variables can be set via pipeline UI or pipeline triggers

Example variables:

```yaml
variables:
  nodeVersion: '18'
  buildConfiguration: 'Release'

steps:
- script: echo $(nodeVersion)
```

Access secret variables via pipeline library or Key Vault; secrets are referenced the same way but masked: `$(mySecret)`

### Artifacts

- Use `PublishBuildArtifacts@1` or `publish` keyword to produce artifacts

Example:

```yaml
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'drop'
```

---

## Cross-platform and common patterns

### Handling secrets securely

- Store secrets in GitHub Secrets or Azure Key Vault + variable groups
- Use least-privilege principals and service connections
- Rotate secrets regularly and avoid embedding them in code

### Environment promotion strategies

- Blue/Green: deploy to green, switch router
- Canary: percentage-based rollout
- Rolling: incremental node updates

### Deployment jobs and approvals

- Azure DevOps supports environment approvals and gates
- GitHub supports environments with protection rules and required reviewers

### Caching and speed optimization

- Cache dependencies per-OS and per-toolchain to avoid repeated downloads
- Restore caches keyed by lockfiles and OS
- Parallelize independent jobs and use matrix builds where appropriate

---

## Examples & Recipes

### GitHub Actions: Build + Publish Docker image (on push to main)

```yaml
name: Build and publish
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Login to registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_PAT }}
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}/my-app:latest
```

### Azure DevOps: Build + Publish Docker image

```yaml
trigger:
  branches:
    include: [ main ]

pool:
  vmImage: 'ubuntu-latest'

variables:
  imageName: 'myapp'

steps:
- task: Docker@2
  inputs:
    command: buildAndPush
    repository: '$(imageName)'
    containerRegistry: 'myCRServiceConnection'
    dockerfile: Dockerfile
    tags: |
      $(Build.BuildId)
```

---

## Troubleshooting & Debugging

- Increase log verbosity: `ACTIONS_STEP_DEBUG` for GitHub Actions (enable in repo secrets), and set system.debug=true in Azure DevOps pipeline variables
- Re-run with `--no-cache` for Docker or `npm ci --prefer-offline` to isolate dependency issues
- Use job/step `outputs` and `upload-artifact` to inspect intermediate files

---

## Best practices checklist

- Keep pipelines small and focused (single responsibility)
- Prefer templates and reusable workflows over copy/paste
- Store secrets in secure stores and limit access
- Use branch policies and required checks for PRs
- Version and pin actions/tasks to specific versions
- Add meaningful pipeline names and descriptions

---

## Further reading

- [GitHub Actions docs](https://docs.github.com/en/actions)
- [Azure Pipelines docs](https://learn.microsoft.com/azure/devops/pipelines/)

---

*This page is intended as a quick reference. Adapt the examples to your organization's security and compliance requirements.*
