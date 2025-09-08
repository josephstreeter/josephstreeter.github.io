---
title: DevOps Best Practices
description: Comprehensive guide to DevOps methodologies, CI/CD pipelines, infrastructure as code, and modern software delivery practices
author: Joseph Streeter
date: 2024-01-15
tags: [devops, ci-cd, infrastructure-as-code, automation, deployment, monitoring]
---

DevOps represents a set of practices that combines software development (Dev) and IT operations (Ops) to shorten the systems development life cycle and provide continuous delivery with high software quality. This guide covers essential DevOps practices and implementation strategies.

## DevOps Fundamentals

### Core Principles

#### Culture and Collaboration

- **Shared responsibility** for the entire application lifecycle
- **Cross-functional teams** working together
- **Breaking down silos** between development and operations
- **Continuous learning** and improvement mindset

#### Automation

- **Infrastructure as Code** (IaC)
- **Automated testing** at all levels
- **Continuous integration** and deployment
- **Configuration management**

#### Measurement and Monitoring

- **Application performance monitoring** (APM)
- **Infrastructure monitoring**
- **Business metrics** and KPIs
- **Feedback loops** for continuous improvement

```text
┌─────────────────────────────────────────────────────────────────┐
│                    DevOps Lifecycle                             │
├─────────────────────────────────────────────────────────────────┤
│  Plan → Code → Build → Test → Release → Deploy → Operate → Monitor │
│    ↑                                                         ↓    │
│    └─────────────────── Feedback ──────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Continuous Integration/Continuous Deployment (CI/CD)

### CI/CD Pipeline Design

#### Basic Pipeline Structure

```yaml
# .github/workflows/ci-cd.yml (GitHub Actions)
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run unit tests
      run: npm test -- --coverage
    
    - name: Run integration tests
      run: npm run test:integration
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run security audit
      run: npm audit --audit-level=high
    
    - name: SAST with Semgrep
      uses: returntocorp/semgrep-action@v1
      with:
        config: auto

  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    outputs:
      image: ${{ steps.image.outputs.image }}
      digest: ${{ steps.build.outputs.digest }}
    
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

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying ${{ needs.build.outputs.image }} to staging"
        # Add deployment commands here

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying ${{ needs.build.outputs.image }} to production"
        # Add deployment commands here
```

### Advanced Pipeline Features

#### Multi-Environment Deployment

```yaml
# Advanced deployment with approvals
deploy:
  strategy:
    matrix:
      environment: [staging, production]
  runs-on: ubuntu-latest
  environment: ${{ matrix.environment }}
  
  steps:
  - name: Configure environment
    run: |
      case "${{ matrix.environment }}" in
        staging)
          echo "CLUSTER_NAME=staging-cluster" >> $GITHUB_ENV
          echo "NAMESPACE=staging" >> $GITHUB_ENV
          ;;
        production)
          echo "CLUSTER_NAME=prod-cluster" >> $GITHUB_ENV
          echo "NAMESPACE=production" >> $GITHUB_ENV
          ;;
      esac
  
  - name: Deploy with Helm
    run: |
      helm upgrade --install myapp ./helm-chart \
        --namespace ${{ env.NAMESPACE }} \
        --set image.tag=${{ github.sha }} \
        --set environment=${{ matrix.environment }} \
        --wait --timeout=300s
```

#### Blue-Green Deployment

```bash
#!/bin/bash
# Blue-Green deployment script

CLUSTER="production"
APP_NAME="myapp"
NEW_VERSION=$1
CURRENT_SLOT=$(kubectl get service $APP_NAME -o jsonpath='{.spec.selector.slot}')

if [ "$CURRENT_SLOT" = "blue" ]; then
    DEPLOY_SLOT="green"
else
    DEPLOY_SLOT="blue"
fi

echo "Current slot: $CURRENT_SLOT"
echo "Deploying to slot: $DEPLOY_SLOT"

# Deploy to inactive slot
kubectl set image deployment/$APP_NAME-$DEPLOY_SLOT app=$APP_NAME:$NEW_VERSION
kubectl rollout status deployment/$APP_NAME-$DEPLOY_SLOT --timeout=300s

# Health check
kubectl wait --for=condition=ready pod -l app=$APP_NAME,slot=$DEPLOY_SLOT --timeout=300s

# Run smoke tests
curl -f http://$APP_NAME-$DEPLOY_SLOT.staging.svc.cluster.local/health

if [ $? -eq 0 ]; then
    echo "Health check passed. Switching traffic to $DEPLOY_SLOT"
    kubectl patch service $APP_NAME -p '{"spec":{"selector":{"slot":"'$DEPLOY_SLOT'"}}}'
    echo "Traffic switched successfully"
else
    echo "Health check failed. Rolling back"
    exit 1
fi
```

## Infrastructure as Code (IaC)

### Terraform Best Practices

#### Project Structure

```text
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── production/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   └── rds/
└── shared/
    ├── variables.tf
    └── outputs.tf
```

#### Infrastructure Module Example

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "private"
  })
}

# NAT Gateways for private subnet internet access
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-${count.index + 1}"
  })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  })
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

#### Environment Configuration

```hcl
# environments/production/main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  common_tags = {
    Environment = "production"
    Project     = var.project_name
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name     = "${var.project_name}-prod"
  cluster_version  = "1.27"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids

  node_groups = {
    main = {
      instance_types = ["t3.large"]
      min_size       = 1
      max_size       = 10
      desired_size   = 3
    }
  }
}
```

### Ansible for Configuration Management

#### Playbook Structure

```yaml
# site.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    app_name: mywebapp
    app_port: 3000
    
  roles:
    - common
    - nginx
    - nodejs
    - application

- name: Configure database servers  
  hosts: dbservers
  become: yes
  vars:
    postgres_version: 13
    
  roles:
    - common
    - postgresql
    - monitoring
```

#### Application Deployment Role

```yaml
# roles/application/tasks/main.yml
---
- name: Create application user
  user:
    name: "{{ app_user }}"
    system: yes
    shell: /bin/false
    home: "{{ app_home }}"
    create_home: yes

- name: Create application directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    mode: '0755'
  loop:
    - "{{ app_home }}"
    - "{{ app_home }}/releases"
    - "{{ app_home }}/shared"
    - "{{ app_home }}/shared/logs"

- name: Download application artifact
  get_url:
    url: "{{ artifact_url }}"
    dest: "{{ app_home }}/releases/{{ app_version }}.tar.gz"
    owner: "{{ app_user }}"
    group: "{{ app_user }}"

- name: Extract application
  unarchive:
    src: "{{ app_home }}/releases/{{ app_version }}.tar.gz"
    dest: "{{ app_home }}/releases/"
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    remote_src: yes
    creates: "{{ app_home }}/releases/{{ app_version }}"

- name: Install dependencies
  npm:
    path: "{{ app_home }}/releases/{{ app_version }}"
    production: yes
  become_user: "{{ app_user }}"

- name: Create current symlink
  file:
    src: "{{ app_home }}/releases/{{ app_version }}"
    dest: "{{ app_home }}/current"
    state: link
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
  notify: restart application

- name: Template systemd service
  template:
    src: app.service.j2
    dest: "/etc/systemd/system/{{ app_name }}.service"
  notify:
    - reload systemd
    - restart application

- name: Start and enable application service
  systemd:
    name: "{{ app_name }}"
    state: started
    enabled: yes
    daemon_reload: yes
```

## Testing Strategies

### Testing Pyramid

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Testing Pyramid                              │
├─────────────────────────────────────────────────────────────────┤
│                    Manual Tests                                 │
│                ┌─────────────────────┐                         │
│                │   E2E Tests         │                         │
│            ┌───┴─────────────────────┴───┐                     │
│            │   Integration Tests         │                     │
│        ┌───┴─────────────────────────────┴───┐                 │
│        │        Unit Tests                   │                 │
│        └─────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Unit Testing Example

```javascript
// test/user.test.js
const { expect } = require('chai');
const sinon = require('sinon');
const User = require('../src/models/User');
const userService = require('../src/services/userService');

describe('User Service', () => {
  let userStub;
  
  beforeEach(() => {
    userStub = sinon.stub(User, 'findById');
  });
  
  afterEach(() => {
    userStub.restore();
  });

  describe('getUserById', () => {
    it('should return user when found', async () => {
      const mockUser = { id: 1, name: 'John Doe', email: 'john@example.com' };
      userStub.resolves(mockUser);

      const result = await userService.getUserById(1);

      expect(result).to.deep.equal(mockUser);
      expect(userStub.calledOnceWith(1)).to.be.true;
    });

    it('should throw error when user not found', async () => {
      userStub.resolves(null);

      try {
        await userService.getUserById(999);
        expect.fail('Expected error to be thrown');
      } catch (error) {
        expect(error.message).to.equal('User not found');
      }
    });
  });
});
```

#### Integration Testing

```javascript
// test/integration/api.test.js
const request = require('supertest');
const app = require('../../src/app');
const db = require('../../src/database');

describe('User API Integration Tests', () => {
  before(async () => {
    await db.migrate.latest();
  });

  beforeEach(async () => {
    await db.seed.run();
  });

  after(async () => {
    await db.migrate.rollback();
    await db.destroy();
  });

  describe('GET /api/users/:id', () => {
    it('should return user details', async () => {
      const response = await request(app)
        .get('/api/users/1')
        .expect(200);

      expect(response.body).to.have.property('id', 1);
      expect(response.body).to.have.property('name');
      expect(response.body).to.have.property('email');
    });

    it('should return 404 for non-existent user', async () => {
      await request(app)
        .get('/api/users/999')
        .expect(404);
    });
  });
});
```

#### End-to-End Testing with Cypress

```javascript
// cypress/e2e/user-journey.cy.js
describe('User Journey', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should allow user to register, login, and access dashboard', () => {
    // Registration
    cy.get('[data-testid="register-link"]').click();
    cy.get('[data-testid="email-input"]').type('test@example.com');
    cy.get('[data-testid="password-input"]').type('password123');
    cy.get('[data-testid="register-button"]').click();

    cy.url().should('include', '/dashboard');
    cy.get('[data-testid="welcome-message"]').should('contain', 'Welcome');

    // Logout
    cy.get('[data-testid="logout-button"]').click();
    cy.url().should('eq', Cypress.config().baseUrl + '/');

    // Login
    cy.get('[data-testid="login-link"]').click();
    cy.get('[data-testid="email-input"]').type('test@example.com');
    cy.get('[data-testid="password-input"]').type('password123');
    cy.get('[data-testid="login-button"]').click();

    cy.url().should('include', '/dashboard');
  });
});
```

## Monitoring and Observability

### Application Performance Monitoring

#### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'application'
    static_configs:
      - targets: ['app:3000']
    metrics_path: /metrics
    scrape_interval: 5s
```

#### Application Metrics Example

```javascript
// src/middleware/metrics.js
const prometheus = require('prom-client');

// Create metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new prometheus.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

// Middleware to collect metrics
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  
  next();
}

module.exports = {
  metricsMiddleware,
  register: prometheus.register
};
```

### Logging Best Practices

#### Structured Logging

```javascript
// src/utils/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'myapp',
    version: process.env.APP_VERSION || '1.0.0'
  },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    })
  ]
});

// Add request ID to all logs
logger.addRequestId = (req, res, next) => {
  req.logger = logger.child({ requestId: req.id });
  next();
};

module.exports = logger;
```

#### ELK Stack Configuration

```yaml
# docker-compose.elk.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logstash/config:/usr/share/logstash/config
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:
```

## Security in DevOps (DevSecOps)

### Security Scanning in CI/CD

```yaml
# Security scanning job
security-scan:
  runs-on: ubuntu-latest
  steps:
  - uses: actions/checkout@v3
  
  - name: Run Trivy vulnerability scanner
    uses: aquasecurity/trivy-action@master
    with:
      image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
      format: 'sarif'
      output: 'trivy-results.sarif'
  
  - name: Upload Trivy scan results
    uses: github/codeql-action/upload-sarif@v2
    with:
      sarif_file: 'trivy-results.sarif'
  
  - name: Run Snyk security scan
    uses: snyk/actions/node@master
    env:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    with:
      args: --severity-threshold=high
```

### Secrets Management

```bash
#!/bin/bash
# secrets-management.sh

# Using HashiCorp Vault
vault kv put secret/myapp \
  database_password="$(openssl rand -base64 32)" \
  api_key="$(openssl rand -hex 32)" \
  jwt_secret="$(openssl rand -base64 64)"

# Kubernetes secrets from Vault
vault auth -method=kubernetes role=myapp-role

vault kv get -field=database_password secret/myapp | \
  kubectl create secret generic app-secrets \
  --from-literal=database_password="$(cat -)"
```

## Performance and Scalability

### Auto-scaling Configuration

```yaml
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 50
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

---
# Vertical Pod Autoscaler
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

## Related Topics

- [Container Orchestration](~/docs/infrastructure/containers/orchestration/index.md)
- [Infrastructure Monitoring](~/docs/infrastructure/monitoring/index.md)
- [Container Security](~/docs/infrastructure/containers/security/index.md)
- [CI/CD Automation](~/docs/development/automation/index.md)
