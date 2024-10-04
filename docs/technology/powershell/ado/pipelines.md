# Pipelines

Pipelines can be used to deploy scripts managed in Azure DevOps to Servers where they can be run from scheduled tasks or interactively by an admin.

## Agent Install

[https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/windows-agent?view=azure-devops](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/windows-agent?view=azure-devops)

## Pipeline

The following pipeline contains the following variables configured:

- "EnvironmentName.ResourceName" - The environment and resource created as part of configuring the agent.
- "Destination Directory" - The directory path where the script files will be deployed.

```yml
trigger:
  batch: true
  branches:
    include:
    - main

stages:
- stage: Deploy
  displayName: 'Deploy'
  condition: succeeded()
  jobs:
  - deployment: Deployment
    displayName: 'Deployment'
    environment: '$(EnvironmentName.ResourceName)'
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self

          - task: CopyFiles@2
            displayName: 'Copy Files to: $(Destination Directory)'
            inputs:
              SourceFolder: '$(Pipeline.Workspace)/s/src'
              Contents: '**'
              TargetFolder: '$(Destination Directory)'
              CleanTargetFolder: true
```