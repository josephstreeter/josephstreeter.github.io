---
title: Cloud Deployment for Python Applications
description: Guide to deploying Python applications to cloud platforms
author: Joseph Streeter
date: 2026-01-04
tags: [python, cloud, deployment, aws, azure, gcp, docker, kubernetes]
---

## Overview

Cloud deployment enables Python applications to scale globally with high availability. This guide covers deployment strategies for major cloud platforms and containerization technologies.

## Cloud Platforms

### AWS (Amazon Web Services)

#### AWS Lambda (Serverless)

```python
# lambda_function.py
def lambda_handler(event, context):
    """AWS Lambda handler function."""
    return {
        'statusCode': 200,
        'body': 'Hello from Lambda!'
    }
```

#### Elastic Beanstalk

```bash
# Install EB CLI
pip install awsebcli

# Initialize application
eb init -p python-3.11 my-app

# Create environment and deploy
eb create my-env
eb deploy
```

#### ECS (Elastic Container Service)

Create task definition and deploy containers.

### Azure

#### Azure Functions

```python
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    """Azure Function handler."""
    return func.HttpResponse("Hello from Azure!", status_code=200)
```

#### Azure App Service

```bash
# Deploy to App Service
az webapp up --name my-app --runtime "PYTHON:3.11"
```

### Google Cloud Platform

#### Cloud Functions

```python
def hello_http(request):
    """HTTP Cloud Function."""
    return 'Hello from GCP!'
```

#### Cloud Run

```bash
# Deploy containerized app
gcloud run deploy my-app --source . --platform managed
```

## Containerization

### Docker

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://db:5432/mydb
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
```

## Kubernetes Deployment

### Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
    spec:
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8000
```

## See Also

- [Continuous Integration](deployment/ci.md)
- [Packaging](deployment/packaging.md)
- [Testing](testing/index.md)
