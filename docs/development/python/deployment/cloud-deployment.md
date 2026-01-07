---
title: Python Cloud Deployment - Comprehensive Guide
description: Complete guide to deploying Python applications on AWS, Azure, Google Cloud, and other cloud platforms with best practices, configuration examples, and optimization strategies
---

Deploying Python applications to cloud platforms enables scalability, reliability, and global reach. This comprehensive guide covers deployment strategies across major cloud providers, containerization approaches, and production best practices for Python applications.

## Overview

Cloud deployment transforms Python applications from local development environments to production-ready services accessible worldwide. Modern cloud platforms offer diverse deployment options ranging from fully managed services (PaaS) to infrastructure-as-code approaches, each suited for different application architectures and operational requirements.

### Key Considerations

- **Application Architecture**: Monolithic, microservices, serverless, or container-based
- **Scalability Requirements**: Horizontal vs vertical scaling needs
- **Cost Optimization**: Pay-per-use vs reserved capacity
- **Operational Complexity**: Managed services vs self-managed infrastructure
- **Geographic Distribution**: Single region vs multi-region deployment
- **Compliance Requirements**: Data residency and regulatory constraints

## AWS Deployment

Amazon Web Services (AWS) provides comprehensive Python deployment options from serverless functions to managed containers and virtual machines.

### AWS Lambda (Serverless)

AWS Lambda enables event-driven, serverless Python execution with automatic scaling and pay-per-request billing.

#### Basic Lambda Function

```python
# lambda_function.py
import json

def lambda_handler(event, context):
    """
    AWS Lambda handler function
    
    Args:
        event: Event data from trigger
        context: Runtime information
    
    Returns:
        Response dictionary with statusCode and body
    """
    try:
        # Extract parameters
        name = event.get('queryStringParameters', {}).get('name', 'World')
        
        # Business logic
        message = f"Hello, {name}!"
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': message,
                'input': event
            })
        }
    except Exception as error:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(error)})
        }
```

#### Lambda with Dependencies

Create deployment package with dependencies:

```bash
# Create package directory
mkdir lambda-package
cd lambda-package

# Install dependencies
pip install requests -t .

# Add your code
cp ../lambda_function.py .

# Create deployment zip
zip -r ../lambda-deployment.zip .
```

#### Using AWS SAM (Serverless Application Model)

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Python Lambda Application

Globals:
  Function:
    Timeout: 30
    Runtime: python3.11
    MemorySize: 256
    Environment:
      Variables:
        ENVIRONMENT: production
        LOG_LEVEL: INFO

Resources:
  ApiFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: src/
      Handler: app.lambda_handler
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /api/{proxy+}
            Method: ANY
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref DataTable
      Layers:
        - !Ref DependenciesLayer
  
  DependenciesLayer:
    Type: AWS::Serverless::LayerVersion
    Properties:
      ContentUri: dependencies/
      CompatibleRuntimes:
        - python3.11
    Metadata:
      BuildMethod: python3.11
  
  DataTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH

Outputs:
  ApiUrl:
    Description: API Gateway endpoint URL
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
```

Deploy with SAM:

```bash
# Build application
sam build

# Deploy with guided prompts
sam deploy --guided

# Or deploy with parameters
sam deploy \
  --template-file template.yaml \
  --stack-name my-python-app \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

#### Lambda Best Practices

- **Cold Start Optimization**: Keep deployment packages small (<50MB)
- **Connection Reuse**: Initialize clients outside handler function
- **Environment Variables**: Use for configuration, not secrets
- **Secrets Management**: Use AWS Secrets Manager or Parameter Store
- **Memory Allocation**: Balance between cost and performance (start with 512MB)
- **Timeout Configuration**: Set appropriate timeouts (default 3s, max 15min)
- **Error Handling**: Implement proper exception handling and logging
- **Idempotency**: Design functions to handle duplicate invocations

```python
# Optimized Lambda with connection reuse
import boto3
import os
import json

# Initialize outside handler (connection reuse)
DYNAMODB = boto3.resource('dynamodb')
TABLE = DYNAMODB.Table(os.environ['TABLE_NAME'])
S3_CLIENT = boto3.client('s3')

def lambda_handler(event, context):
    """Optimized Lambda handler with connection reuse"""
    try:
        # Use pre-initialized connections
        response = TABLE.get_item(Key={'id': event['id']})
        
        return {
            'statusCode': 200,
            'body': json.dumps(response.get('Item', {}))
        }
    except Exception as error:
        print(f"Error: {error}")
        raise
```

### AWS Elastic Beanstalk

Elastic Beanstalk provides managed platform for deploying Python web applications with automatic capacity provisioning, load balancing, and health monitoring.

#### Application Structure

```text
my-flask-app/
├── application.py          # Main application file
├── requirements.txt        # Python dependencies
├── .ebextensions/         # Beanstalk configuration
│   ├── 01_packages.config
│   └── 02_python.config
├── .ebignore              # Files to exclude
└── .platform/             # Platform hooks
    └── hooks/
        └── postdeploy/
            └── 01_migrate.sh
```

#### Flask Application

```python
# application.py
from flask import Flask, jsonify, request
import os

application = Flask(__name__)

@application.route('/')
def index():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'environment': os.environ.get('ENVIRONMENT', 'development')
    })

@application.route('/api/data', methods=['GET', 'POST'])
def api_data():
    """API endpoint"""
    if request.method == 'POST':
        data = request.get_json()
        # Process data
        return jsonify({'success': True, 'data': data}), 201
    else:
        return jsonify({'message': 'GET request received'})

if __name__ == '__main__':
    # Development server
    application.run(host='0.0.0.0', port=5000, debug=False)
```

#### Elastic Beanstalk Configuration

```yaml
# .ebextensions/01_packages.config
packages:
  yum:
    git: []
    postgresql-devel: []

# .ebextensions/02_python.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: "/var/app/current:$PYTHONPATH"
    DJANGO_SETTINGS_MODULE: "config.settings.production"
  
  aws:elasticbeanstalk:container:python:
    WSGIPath: "application:application"
  
  aws:autoscaling:launchconfiguration:
    InstanceType: t3.small
  
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  
  aws:elasticbeanstalk:environment:
    LoadBalancerType: application
    ServiceRole: aws-elasticbeanstalk-service-role

container_commands:
  01_migrate:
    command: "source /var/app/venv/*/bin/activate && python manage.py migrate --noinput"
    leader_only: true
  02_collectstatic:
    command: "source /var/app/venv/*/bin/activate && python manage.py collectstatic --noinput"
```

#### Deployment Commands

```bash
# Initialize Elastic Beanstalk application
eb init -p python-3.11 my-python-app --region us-east-1

# Create environment
eb create production-env \
  --instance-type t3.small \
  --envvars "ENVIRONMENT=production,DEBUG=False"

# Deploy new version
eb deploy

# View logs
eb logs

# SSH into instance
eb ssh

# Check environment health
eb health

# Scale environment
eb scale 4

# Terminate environment
eb terminate production-env
```

### AWS ECS (Elastic Container Service)

Deploy containerized Python applications with ECS Fargate for serverless container orchestration.

#### Dockerfile

```dockerfile
# Multi-stage build for Python application
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . .

# Set Python path
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Non-root user for security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "app:application"]
```

#### ECS Task Definition

```json
{
  "family": "python-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "python-app",
      "image": "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/python-app:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:db-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/python-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

#### Deploy to ECS

```bash
# Build and push Docker image
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker build -t python-app .
docker tag python-app:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/python-app:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/python-app:latest

# Create ECS cluster
aws ecs create-cluster --cluster-name production-cluster

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create service
aws ecs create-service \
  --cluster production-cluster \
  --service-name python-app-service \
  --task-definition python-app:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-abc,subnet-def],securityGroups=[sg-123],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=python-app,containerPort=8000"
```

### AWS EC2 (Virtual Machines)

Deploy Python applications on EC2 instances with full control over the environment.

#### User Data Script

```bash
#!/bin/bash
# EC2 User Data for Python application deployment

set -e

# Update system
yum update -y

# Install Python 3.11
yum install python3.11 python3.11-pip git -y

# Create application directory
mkdir -p /opt/myapp
cd /opt/myapp

# Clone application
git clone https://github.com/myuser/myapp.git .

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn supervisor

# Create systemd service
cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=Python Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/myapp
Environment="PATH=/opt/myapp/venv/bin"
ExecStart=/opt/myapp/venv/bin/gunicorn --bind 0.0.0.0:8000 --workers 4 app:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable myapp
systemctl start myapp

# Install and configure nginx
amazon-linux-extras install nginx1 -y

cat > /etc/nginx/conf.d/myapp.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

systemctl enable nginx
systemctl start nginx
```

## Azure Deployment

Microsoft Azure provides robust Python deployment options with strong integration with Visual Studio Code and Azure DevOps.

### Azure App Service

Fully managed platform for web applications with built-in CI/CD, scaling, and monitoring.

#### Deploy with Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name python-app-rg --location eastus

# Create App Service plan
az appservice plan create \
  --name python-app-plan \
  --resource-group python-app-rg \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group python-app-rg \
  --plan python-app-plan \
  --name my-python-app \
  --runtime "PYTHON:3.11"

# Configure deployment
az webapp deployment source config-zip \
  --resource-group python-app-rg \
  --name my-python-app \
  --src app.zip

# Set environment variables
az webapp config appsettings set \
  --resource-group python-app-rg \
  --name my-python-app \
  --settings ENVIRONMENT=production DEBUG=False

# Enable logging
az webapp log config \
  --resource-group python-app-rg \
  --name my-python-app \
  --application-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true

# Stream logs
az webapp log tail \
  --resource-group python-app-rg \
  --name my-python-app
```

#### Application Configuration

```python
# app.py for Azure App Service
from flask import Flask
import os

app = Flask(__name__)

# Azure App Service configuration
app.config['DEBUG'] = os.environ.get('DEBUG', 'False') == 'True'
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-key')

@app.route('/')
def index():
    """Root endpoint"""
    return {
        'message': 'Application running on Azure App Service',
        'python_version': os.environ.get('PYTHON_VERSION'),
        'website_site_name': os.environ.get('WEBSITE_SITE_NAME')
    }

if __name__ == '__main__':
    # Azure uses PORT environment variable
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port)
```

#### Startup Command Configuration

```bash
# In Azure Portal or via CLI, set startup command:
gunicorn --bind=0.0.0.0 --timeout 600 --workers=4 app:app
```

### Azure Functions

Serverless compute service for event-driven Python applications.

#### Function App Structure

```text
my-function-app/
├── host.json               # Function host configuration
├── local.settings.json     # Local development settings
├── requirements.txt        # Python dependencies
├── HttpTrigger/           # HTTP triggered function
│   ├── __init__.py
│   └── function.json
├── TimerTrigger/          # Timer triggered function
│   ├── __init__.py
│   └── function.json
└── BlobTrigger/           # Blob storage triggered function
    ├── __init__.py
    └── function.json
```

#### HTTP Trigger Function

```python
# HttpTrigger/__init__.py
import logging
import json
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP triggered Azure Function
    
    Args:
        req: HTTP request object
    
    Returns:
        HTTP response object
    """
    logging.info('Python HTTP trigger function processed a request.')
    
    # Get parameters
    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
            name = req_body.get('name')
        except ValueError:
            pass
    
    if name:
        return func.HttpResponse(
            json.dumps({'message': f'Hello, {name}!'}),
            mimetype='application/json',
            status_code=200
        )
    else:
        return func.HttpResponse(
            json.dumps({'error': 'Please pass a name parameter'}),
            mimetype='application/json',
            status_code=400
        )
```

```json
// HttpTrigger/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}
```

#### Timer Trigger Function

```python
# TimerTrigger/__init__.py
import logging
import datetime
import azure.functions as func

def main(timer: func.TimerRequest) -> None:
    """
    Timer triggered Azure Function (runs on schedule)
    
    Args:
        timer: Timer trigger object with schedule info
    """
    timestamp = datetime.datetime.utcnow().isoformat()
    
    if timer.past_due:
        logging.warning('The timer is past due!')
    
    logging.info(f'Python timer trigger function executed at {timestamp}')
    
    # Perform scheduled tasks
    # Example: data processing, cleanup, notifications
```

```json
// TimerTrigger/function.json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "name": "timer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */5 * * * *"
    }
  ]
}
```

#### Deploy Azure Functions

```bash
# Create Function App
az functionapp create \
  --resource-group python-app-rg \
  --consumption-plan-location eastus \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --name my-python-functions \
  --storage-account mystorageaccount

# Deploy using Azure Functions Core Tools
func azure functionapp publish my-python-functions

# Configure application settings
az functionapp config appsettings set \
  --name my-python-functions \
  --resource-group python-app-rg \
  --settings "CUSTOM_SETTING=value" "API_KEY=secret"
```

### Azure Container Instances (ACI)

Deploy containers without managing virtual machines.

```bash
# Create container instance
az container create \
  --resource-group python-app-rg \
  --name python-container \
  --image myregistry.azurecr.io/python-app:latest \
  --cpu 2 \
  --memory 4 \
  --registry-login-server myregistry.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --dns-name-label python-app \
  --ports 80 443 \
  --environment-variables ENVIRONMENT=production \
  --secure-environment-variables API_KEY=secret123

# View logs
az container logs --resource-group python-app-rg --name python-container

# Get container details
az container show --resource-group python-app-rg --name python-container
```

## Google Cloud Platform Deployment

Google Cloud Platform (GCP) offers diverse Python deployment options with strong Kubernetes support.

### Google Cloud Run

Fully managed serverless platform for containerized applications.

#### Prepare Application

```python
# main.py for Cloud Run
from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/')
def hello():
    """Cloud Run requires PORT environment variable"""
    target = request.args.get('target', 'World')
    return f'Hello {target}!'

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    # Cloud Run sets PORT environment variable
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

#### Dockerfile for Cloud Run

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Cloud Run requires non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
```

#### Deploy to Cloud Run

```bash
# Build and submit to Container Registry
gcloud builds submit --tag gcr.io/PROJECT_ID/python-app

# Deploy to Cloud Run
gcloud run deploy python-app \
  --image gcr.io/PROJECT_ID/python-app \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 100 \
  --set-env-vars ENVIRONMENT=production \
  --set-secrets DATABASE_URL=database-url:latest

# Update service
gcloud run services update python-app \
  --region us-central1 \
  --concurrency 80 \
  --timeout 300

# View logs
gcloud run logs read python-app --region us-central1
```

### Google App Engine

Platform-as-a-Service for Python applications with automatic scaling.

#### app.yaml Configuration

```yaml
runtime: python311
entrypoint: gunicorn -b :$PORT main:app

instance_class: F2

automatic_scaling:
  target_cpu_utilization: 0.65
  target_throughput_utilization: 0.65
  min_instances: 2
  max_instances: 20
  min_idle_instances: 1
  max_idle_instances: automatic
  min_pending_latency: 30ms
  max_pending_latency: automatic

env_variables:
  ENVIRONMENT: 'production'
  DEBUG: 'False'

handlers:
- url: /static
  static_dir: static/
  secure: always

- url: /.*
  script: auto
  secure: always
```

#### Deploy App Engine

```bash
# Deploy application
gcloud app deploy

# Deploy with specific version
gcloud app deploy --version v1 --no-promote

# View logs
gcloud app logs tail -s default

# Open application in browser
gcloud app browse
```

### Google Kubernetes Engine (GKE)

Managed Kubernetes service for containerized applications.

#### Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
  labels:
    app: python-app
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
      - name: python-app
        image: gcr.io/PROJECT_ID/python-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
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
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: python-app-service
spec:
  type: LoadBalancer
  selector:
    app: python-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

#### Deploy to GKE

```bash
# Create GKE cluster
gcloud container clusters create python-cluster \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --region us-central1

# Get credentials
gcloud container clusters get-credentials python-cluster --region us-central1

# Deploy application
kubectl apply -f deployment.yaml

# Check status
kubectl get deployments
kubectl get pods
kubectl get services

# Scale deployment
kubectl scale deployment python-app --replicas=5

# Update image
kubectl set image deployment/python-app python-app=gcr.io/PROJECT_ID/python-app:v2
```

## Heroku Deployment

Heroku provides developer-friendly platform for deploying Python applications with minimal configuration.

### Heroku Application Structure

```text
my-app/
├── app.py                 # Main application
├── requirements.txt       # Python dependencies
├── Procfile              # Process types
├── runtime.txt           # Python version
└── .gitignore            # Git ignore patterns
```

### Procfile Configuration

```text
web: gunicorn app:app --log-file -
worker: python worker.py
release: python manage.py migrate
```

### Runtime Specification

```text
python-3.11.7
```

### Deploy to Heroku

```bash
# Login to Heroku
heroku login

# Create Heroku application
heroku create my-python-app

# Add PostgreSQL database
heroku addons:create heroku-postgresql:hobby-dev

# Set environment variables
heroku config:set ENVIRONMENT=production
heroku config:set SECRET_KEY=your-secret-key

# Deploy via Git
git push heroku main

# Run one-off commands
heroku run python manage.py migrate

# Scale dynos
heroku ps:scale web=2 worker=1

# View logs
heroku logs --tail

# Open application
heroku open
```

### Heroku Configuration

```python
# app.py with Heroku configuration
from flask import Flask
import os

app = Flask(__name__)

# Heroku provides DATABASE_URL
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
# Heroku uses dyno port
port = int(os.environ.get('PORT', 5000))

@app.route('/')
def index():
    return {'status': 'running on Heroku'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=port)
```

## Docker and Kubernetes

Containerization provides consistent deployment across any cloud platform or on-premises infrastructure.

### Production Dockerfile

```dockerfile
# Multi-stage build for optimized Python container
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . .

# Set environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Use exec form for proper signal handling
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--worker-class", "gthread", "--threads", "2", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "app:application"]
```

### Docker Compose for Local Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - ENVIRONMENT=development
    volumes:
      - .:/app
      - static_volume:/app/static
    depends_on:
      - db
      - redis
    command: python manage.py runserver 0.0.0.0:8000

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  worker:
    build: .
    command: celery -A app.celery worker --loglevel=info
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
  redis_data:
  static_volume:
```

### Kubernetes Deployment Best Practices

```yaml
# Complete Kubernetes deployment with best practices
apiVersion: v1
kind: Namespace
metadata:
  name: python-app
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: python-app
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: python-app
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@db:5432/myapp"
  SECRET_KEY: "your-secret-key"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
  namespace: python-app
  labels:
    app: python-app
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: python-app
        image: myregistry.io/python-app:v1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
          name: http
          protocol: TCP
        env:
        - name: PORT
          value: "8000"
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
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
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/.cache
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - python-app
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: python-app-service
  namespace: python-app
spec:
  type: LoadBalancer
  selector:
    app: python-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
    name: http
  sessionAffinity: None
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: python-app-hpa
  namespace: python-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: python-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max
```

## CI/CD Pipeline Examples

### GitHub Actions for AWS

```yaml
# .github/workflows/deploy-aws.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: python-app
  ECS_SERVICE: python-app-service
  ECS_CLUSTER: production-cluster
  ECS_TASK_DEFINITION: task-definition.json
  CONTAINER_NAME: python-app

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Run tests
      run: |
        pip install pytest pytest-cov
        pip install -r requirements.txt
        pytest --cov=app tests/
    
    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
    
    - name: Fill in the new image ID in the Amazon ECS task definition
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.ECS_TASK_DEFINITION }}
        container-name: ${{ env.CONTAINER_NAME }}
        image: ${{ steps.build-image.outputs.image }}
    
    - name: Deploy Amazon ECS task definition
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.task-def.outputs.task-definition }}
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true
```

### GitLab CI for Google Cloud

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  GCP_PROJECT_ID: my-project
  GCP_REGION: us-central1
  SERVICE_NAME: python-app
  IMAGE: gcr.io/$GCP_PROJECT_ID/$SERVICE_NAME

test:
  stage: test
  image: python:3.11
  before_script:
    - pip install pytest pytest-cov
    - pip install -r requirements.txt
  script:
    - pytest --cov=app tests/
    - coverage report
  coverage: '/^TOTAL.+?(\d+\%)$/'

build:
  stage: build
  image: google/cloud-sdk
  services:
    - docker:dind
  before_script:
    - echo $GCP_SERVICE_KEY | base64 -d > ${HOME}/gcloud-service-key.json
    - gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
    - gcloud config set project $GCP_PROJECT_ID
  script:
    - gcloud builds submit --tag $IMAGE:$CI_COMMIT_SHA
    - gcloud builds submit --tag $IMAGE:latest
  only:
    - main

deploy:
  stage: deploy
  image: google/cloud-sdk
  before_script:
    - echo $GCP_SERVICE_KEY | base64 -d > ${HOME}/gcloud-service-key.json
    - gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
    - gcloud config set project $GCP_PROJECT_ID
  script:
    - |
      gcloud run deploy $SERVICE_NAME \
        --image $IMAGE:$CI_COMMIT_SHA \
        --platform managed \
        --region $GCP_REGION \
        --allow-unauthenticated \
        --memory 512Mi \
        --set-env-vars ENVIRONMENT=production
  only:
    - main
  when: manual
```

### Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureSubscription: 'azure-connection'
  webAppName: 'python-app'
  resourceGroupName: 'python-app-rg'
  pythonVersion: '3.11'

stages:
- stage: Test
  jobs:
  - job: RunTests
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(pythonVersion)'
      displayName: 'Use Python $(pythonVersion)'
    
    - script: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov
      displayName: 'Install dependencies'
    
    - script: |
        pytest --cov=app --cov-report=xml --cov-report=html tests/
      displayName: 'Run tests'
    
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(System.DefaultWorkingDirectory)/coverage.xml'

- stage: Build
  dependsOn: Test
  jobs:
  - job: BuildApplication
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(pythonVersion)'
    
    - script: |
        pip install -r requirements.txt -t .
      displayName: 'Install application dependencies'
    
    - task: ArchiveFiles@2
      inputs:
        rootFolderOrFile: '$(System.DefaultWorkingDirectory)'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'
    
    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployWeb
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'webAppLinux'
              appName: '$(webAppName)'
              package: '$(Pipeline.Workspace)/drop/$(Build.BuildId).zip'
              runtimeStack: 'PYTHON|$(pythonVersion)'
              startUpCommand: 'gunicorn --bind=0.0.0.0 --timeout 600 app:app'
```

## Production Best Practices

### Configuration Management

```python
# config.py - Environment-based configuration
import os
from typing import Any

class Config:
    """Base configuration"""
    SECRET_KEY: str = os.environ.get('SECRET_KEY', 'dev-secret-key')
    DEBUG: bool = False
    TESTING: bool = False
    
    # Database
    SQLALCHEMY_DATABASE_URI: str = os.environ.get('DATABASE_URL', 'sqlite:///app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False
    SQLALCHEMY_ENGINE_OPTIONS: dict[str, Any] = {
        'pool_size': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True
    }
    
    # Redis
    REDIS_URL: str = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
    
    # Celery
    CELERY_BROKER_URL: str = os.environ.get('CELERY_BROKER_URL', REDIS_URL)
    CELERY_RESULT_BACKEND: str = os.environ.get('CELERY_RESULT_BACKEND', REDIS_URL)
    
    # Logging
    LOG_LEVEL: str = os.environ.get('LOG_LEVEL', 'INFO')
    
    # Security
    SESSION_COOKIE_SECURE: bool = True
    SESSION_COOKIE_HTTPONLY: bool = True
    SESSION_COOKIE_SAMESITE: str = 'Lax'
    
    # CORS
    CORS_ORIGINS: list[str] = os.environ.get('CORS_ORIGINS', '*').split(',')

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SESSION_COOKIE_SECURE = False

class ProductionConfig(Config):
    """Production configuration"""
    # Additional production settings
    SQLALCHEMY_ENGINE_OPTIONS = {
        **Config.SQLALCHEMY_ENGINE_OPTIONS,
        'pool_size': 20,
        'max_overflow': 10
    }

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

def get_config() -> Config:
    """Get configuration based on environment"""
    env = os.environ.get('ENVIRONMENT', 'development')
    return config.get(env, config['default'])()
```

### Logging Configuration

```python
# logging_config.py
import logging
import sys
from pythonjsonlogger import jsonlogger

def setup_logging(log_level: str = 'INFO') -> None:
    """
    Configure structured logging for production
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    """
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    logger.handlers = []
    
    # JSON formatter for structured logging
    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%S'
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # Set levels for third-party loggers
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('botocore').setLevel(logging.WARNING)
    logging.getLogger('werkzeug').setLevel(logging.INFO)

# Usage in application
import logging
from logging_config import setup_logging

setup_logging(os.environ.get('LOG_LEVEL', 'INFO'))
logger = logging.getLogger(__name__)

logger.info('Application started', extra={'environment': os.environ.get('ENVIRONMENT')})
```

### Health Check Endpoints

```python
# health.py - Comprehensive health checks
from flask import Blueprint, jsonify
import psycopg2
import redis
import time
from typing import Dict, Any

health_bp = Blueprint('health', __name__)

def check_database() -> Dict[str, Any]:
    """Check database connectivity"""
    try:
        conn = psycopg2.connect(os.environ.get('DATABASE_URL'))
        conn.close()
        return {'status': 'healthy', 'latency_ms': 0}
    except Exception as error:
        return {'status': 'unhealthy', 'error': str(error)}

def check_redis() -> Dict[str, Any]:
    """Check Redis connectivity"""
    try:
        start = time.time()
        r = redis.from_url(os.environ.get('REDIS_URL'))
        r.ping()
        latency = (time.time() - start) * 1000
        return {'status': 'healthy', 'latency_ms': round(latency, 2)}
    except Exception as error:
        return {'status': 'unhealthy', 'error': str(error)}

@health_bp.route('/health')
def health():
    """Basic health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

@health_bp.route('/ready')
def readiness():
    """Readiness check with dependency verification"""
    checks = {
        'database': check_database(),
        'redis': check_redis()
    }
    
    # Determine overall status
    is_ready = all(check['status'] == 'healthy' for check in checks.values())
    status_code = 200 if is_ready else 503
    
    return jsonify({
        'ready': is_ready,
        'checks': checks,
        'timestamp': time.time()
    }), status_code

@health_bp.route('/live')
def liveness():
    """Liveness probe - application is running"""
    return jsonify({
        'alive': True,
        'timestamp': time.time()
    }), 200
```

### Graceful Shutdown

```python
# app.py - Graceful shutdown handling
import signal
import sys
import logging
from flask import Flask

logger = logging.getLogger(__name__)

app = Flask(__name__)

# Track shutdown state
shutdown = False

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown
    logger.info(f'Received signal {signum}, initiating graceful shutdown...')
    shutdown = True
    
    # Close database connections
    # Close Redis connections
    # Stop background tasks
    
    logger.info('Graceful shutdown complete')
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

@app.before_request
def check_shutdown():
    """Reject new requests during shutdown"""
    if shutdown:
        return jsonify({'error': 'Server is shutting down'}), 503

if __name__ == '__main__':
    app.run()
```

### Security Headers

```python
# security.py - Security headers middleware
from flask import Flask
from flask_talisman import Talisman

def configure_security(app: Flask) -> None:
    """Configure security headers and policies"""
    
    # Content Security Policy
    csp = {
        'default-src': "'self'",
        'script-src': ["'self'", "'unsafe-inline'", 'cdn.example.com'],
        'style-src': ["'self'", "'unsafe-inline'"],
        'img-src': ["'self'", 'data:', 'https:'],
        'font-src': ["'self'", 'data:'],
        'connect-src': "'self'",
        'frame-ancestors': "'none'"
    }
    
    # Configure Talisman
    Talisman(
        app,
        force_https=True,
        strict_transport_security=True,
        strict_transport_security_max_age=31536000,
        content_security_policy=csp,
        content_security_policy_nonce_in=['script-src'],
        referrer_policy='strict-origin-when-cross-origin',
        feature_policy={
            'geolocation': "'none'",
            'microphone': "'none'",
            'camera': "'none'"
        }
    )
    
    @app.after_request
    def set_security_headers(response):
        """Add additional security headers"""
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
        return response
```

### Performance Monitoring

```python
# monitoring.py - Application performance monitoring
from prometheus_flask_exporter import PrometheusMetrics
from flask import Flask, request
import time
import logging

logger = logging.getLogger(__name__)

def configure_monitoring(app: Flask) -> PrometheusMetrics:
    """Configure Prometheus metrics"""
    
    metrics = PrometheusMetrics(app)
    
    # Custom metrics
    metrics.info('app_info', 'Application info', version='1.0.0')
    
    @app.before_request
    def before_request():
        """Track request start time"""
        request.start_time = time.time()
    
    @app.after_request
    def after_request(response):
        """Log request details"""
        request_latency = time.time() - request.start_time
        
        logger.info('Request completed', extra={
            'method': request.method,
            'path': request.path,
            'status': response.status_code,
            'latency_ms': round(request_latency * 1000, 2),
            'ip': request.remote_addr
        })
        
        return response
    
    return metrics

# Usage
app = Flask(__name__)
metrics = configure_monitoring(app)
```

## Cost Optimization Strategies

### Reserved Capacity

- **AWS Reserved Instances**: Save up to 72% for EC2, RDS
- **Azure Reserved VM Instances**: Save up to 72% for compute
- **Google Committed Use Discounts**: Save up to 57% for Compute Engine

### Serverless Optimization

```python
# Lambda optimization - reduce cold starts
import json

# Initialize connections outside handler
import boto3
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """Optimized Lambda with connection reuse"""
    # Handler code here
    pass
```

### Container Cost Reduction

- Use **multi-stage builds** to reduce image size
- Implement **horizontal pod autoscaling** based on metrics
- Use **spot instances** for non-critical workloads (save 70-90%)
- Configure **resource requests and limits** appropriately

### Database Optimization

- Use **connection pooling** to reduce database load
- Implement **caching** with Redis or Memcached
- Use **read replicas** for read-heavy workloads
- Enable **automatic scaling** for managed databases

## Troubleshooting

### Common Deployment Issues

#### Application Won't Start

```bash
# Check logs
kubectl logs -f deployment/python-app
aws logs tail /ecs/python-app --follow
gcloud run logs read python-app --tail

# Common causes:
# 1. Missing environment variables
# 2. Port mismatch (app vs container)
# 3. Database connection failure
# 4. Missing dependencies in requirements.txt
```

#### High Memory Usage

```python
# Memory profiling
import tracemalloc

tracemalloc.start()

# Your code here

current, peak = tracemalloc.get_traced_memory()
print(f"Current memory usage: {current / 10**6}MB")
print(f"Peak memory usage: {peak / 10**6}MB")

tracemalloc.stop()
```

#### Connection Timeouts

```python
# Configure connection timeouts
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

session = requests.Session()
retry = Retry(total=3, backoff_factor=0.3)
adapter = HTTPAdapter(max_retries=retry)
session.mount('http://', adapter)
session.mount('https://', adapter)

response = session.get('https://api.example.com', timeout=10)
```

#### Database Connection Pool Exhaustion

```python
# SQLAlchemy connection pooling
from sqlalchemy import create_engine

engine = create_engine(
    database_url,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=3600
)
```

## See Also

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Python SDK (Boto3)](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
- [Azure SDK for Python](https://learn.microsoft.com/en-us/azure/developer/python/)
- [Google Cloud Python Client Libraries](https://cloud.google.com/python/docs/reference)
- [Heroku Python Support](https://devcenter.heroku.com/articles/python-support)
- [Python Deployment Best Practices](https://12factor.net/)

## Additional Resources

### Official Documentation

- [AWS Lambda Python](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [Azure Functions Python Developer Guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
- [Google Cloud Run Python Quickstart](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/python)
- [Kubernetes Python Client](https://github.com/kubernetes-client/python)

### Tools and Libraries

- [Gunicorn](https://gunicorn.org/) - Python WSGI HTTP Server
- [uWSGI](https://uwsgi-docs.readthedocs.io/) - Application server
- [Nginx](https://nginx.org/) - Reverse proxy and load balancer
- [Prometheus](https://prometheus.io/) - Monitoring and alerting
- [Grafana](https://grafana.com/) - Observability platform

### Best Practices Guides

- [The Twelve-Factor App](https://12factor.net/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)
- [Python Packaging User Guide](https://packaging.python.org/)
- [Production Best Practices: Security](https://expressjs.com/en/advanced/best-practice-security.html)
