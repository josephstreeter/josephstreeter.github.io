---
title: Python Deployment - Complete Guide
description: Comprehensive guide to deploying Python applications covering packaging, containerization, CI/CD, configuration management, monitoring, and production best practices
---

Deploying Python applications requires careful consideration of packaging, environment management, infrastructure choices, and operational practices. This comprehensive guide covers the entire deployment lifecycle from local development to production operations.

## Overview

Python deployment encompasses the processes, tools, and practices required to move applications from development environments to production infrastructure reliably and efficiently. Modern Python deployment leverages containerization, infrastructure as code, automated testing, and continuous delivery to ensure applications are delivered quickly while maintaining quality and stability.

### Deployment Lifecycle

1. **Development**: Local development with virtual environments and dependency management
2. **Packaging**: Creating distributable artifacts with proper dependency specifications
3. **Testing**: Automated testing in CI/CD pipelines
4. **Staging**: Deploying to staging environments for validation
5. **Production**: Releasing to production with monitoring and rollback capabilities
6. **Operations**: Ongoing monitoring, scaling, and maintenance

### Key Considerations

- **Environment Consistency**: Ensuring identical behavior across dev, staging, and production
- **Dependency Management**: Pinning versions and managing transitive dependencies
- **Configuration**: Externalizing configuration from code
- **Security**: Protecting secrets, applying updates, and following security best practices
- **Observability**: Logging, metrics, and tracing for troubleshooting
- **Scalability**: Designing for horizontal and vertical scaling
- **Reliability**: Implementing health checks, graceful shutdowns, and error handling
- **Recovery**: Backup strategies and disaster recovery planning

## Application Packaging

Properly packaging Python applications ensures reproducible deployments and simplifies distribution.

### Project Structure

A well-organized project structure facilitates packaging and deployment:

```text
myproject/
├── README.md                 # Project documentation
├── LICENSE                   # Software license
├── setup.py                  # Package configuration (legacy)
├── pyproject.toml           # Modern package configuration
├── requirements.txt         # Production dependencies
├── requirements-dev.txt     # Development dependencies
├── .gitignore              # Git ignore patterns
├── .dockerignore           # Docker ignore patterns
├── Dockerfile              # Container definition
├── docker-compose.yml      # Local development environment
├── .env.example            # Example environment variables
├── myproject/              # Application package
│   ├── __init__.py
│   ├── __main__.py         # Entry point for -m execution
│   ├── config.py           # Configuration management
│   ├── app.py              # Main application code
│   ├── models/             # Data models
│   │   ├── __init__.py
│   │   └── user.py
│   ├── views/              # Views/controllers
│   │   ├── __init__.py
│   │   └── api.py
│   └── utils/              # Utility functions
│       ├── __init__.py
│       └── helpers.py
├── tests/                  # Test suite
│   ├── __init__.py
│   ├── conftest.py         # Pytest configuration
│   ├── test_app.py
│   └── test_models.py
├── docs/                   # Documentation
│   ├── index.md
│   └── api.md
├── scripts/                # Deployment/utility scripts
│   ├── deploy.sh
│   └── migrate.py
└── .github/                # GitHub Actions workflows
    └── workflows/
        ├── ci.yml
        └── deploy.yml
```

### Modern Python Packaging (pyproject.toml)

The modern approach uses `pyproject.toml` following PEP 518 and PEP 621:

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "myproject"
version = "1.0.0"
description = "My Python application"
readme = "README.md"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
requires-python = ">=3.11"
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]
dependencies = [
    "flask>=3.0.0",
    "sqlalchemy>=2.0.0",
    "psycopg2-binary>=2.9.0",
    "redis>=5.0.0",
    "celery>=5.3.0",
    "gunicorn>=21.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.7.0",
]
docs = [
    "sphinx>=7.0.0",
    "sphinx-rtd-theme>=1.3.0",
]

[project.scripts]
myproject = "myproject.__main__:main"
myproject-worker = "myproject.worker:main"

[project.urls]
Homepage = "https://github.com/user/myproject"
Documentation = "https://myproject.readthedocs.io"
Repository = "https://github.com/user/myproject"
"Bug Tracker" = "https://github.com/user/myproject/issues"

[tool.setuptools.packages.find]
where = ["."]
include = ["myproject*"]
exclude = ["tests*", "docs*"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = [
    "--cov=myproject",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--strict-markers",
    "-v"
]

[tool.black]
line-length = 100
target-version = ['py311']
include = '\.pyi?$'
exclude = '''
/(
    \.git
  | \.venv
  | build
  | dist
)/
'''

[tool.ruff]
line-length = 100
target-version = "py311"
select = ["E", "F", "I", "N", "W", "B", "C4", "UP"]
ignore = []
exclude = [
    ".git",
    ".venv",
    "build",
    "dist",
]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### Building Distribution Packages

```bash
# Install build tools
pip install build twine

# Build source distribution and wheel
python -m build

# Output:
# dist/
#   myproject-1.0.0.tar.gz
#   myproject-1.0.0-py3-none-any.whl

# Check distribution
twine check dist/*

# Upload to PyPI (production)
twine upload dist/*

# Upload to TestPyPI (testing)
twine upload --repository testpypi dist/*
```

### Entry Points

Define application entry points for easy execution:

```python
# myproject/__main__.py
import sys
from myproject.app import create_app

def main():
    """Main entry point for the application"""
    app = create_app()
    app.run(host='0.0.0.0', port=8000)

if __name__ == '__main__':
    sys.exit(main())
```

After installation, users can run:

```bash
# Via entry point script
myproject

# Or via module execution
python -m myproject
```

### Requirements Files

Maintain separate requirements files for different environments:

```text
# requirements.txt (production)
flask==3.0.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
celery==5.3.4
gunicorn==21.2.0
python-dotenv==1.0.0
prometheus-flask-exporter==0.22.4

# requirements-dev.txt (development)
-r requirements.txt
pytest==7.4.3
pytest-cov==4.1.0
black==23.12.0
ruff==0.1.8
mypy==1.7.1
ipython==8.18.1
ipdb==0.13.13

# requirements-test.txt (testing)
-r requirements.txt
pytest==7.4.3
pytest-cov==4.1.0
pytest-mock==3.12.0
factory-boy==3.3.0
faker==20.1.0
```

### Using UV for Fast Dependency Management

```bash
# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create requirements.in
cat > requirements.in <<EOF
flask>=3.0
sqlalchemy>=2.0
psycopg2-binary
redis
celery
gunicorn
EOF

# Compile locked requirements.txt (10-100x faster than pip-compile)
uv pip compile requirements.in -o requirements.txt

# Install dependencies (10-100x faster than pip)
uv pip sync requirements.txt

# Update dependencies
uv pip compile requirements.in --upgrade -o requirements.txt
```

## Containerization

Containerization provides consistent, portable, and reproducible deployment environments.

### Production-Ready Dockerfile

```dockerfile
# Multi-stage build for optimized Python container
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast dependency installation
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN uv venv && uv pip sync requirements.txt

# Final stage - minimal runtime image
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY . .

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    ENVIRONMENT=production

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Use exec form for proper signal handling
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--worker-class", "gthread", \
     "--threads", "2", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "myproject.app:create_app()"]
```

### Docker Compose for Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: python -m flask run --host=0.0.0.0 --port=8000 --reload
    volumes:
      - .:/app
      - /app/.venv  # Don't mount venv
    ports:
      - "8000:8000"
    environment:
      - FLASK_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/0
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - app-network

  worker:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A myproject.celery worker --loglevel=info --concurrency=4
    volumes:
      - .:/app
      - /app/.venv
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - app-network

  beat:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A myproject.celery beat --loglevel=info
    volumes:
      - .:/app
      - /app/.venv
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Docker Best Practices

```dockerfile
# .dockerignore
__pycache__
*.pyc
*.pyo
*.pyd
.Python
.venv
venv/
ENV/
env/
.git
.github
.gitignore
.dockerignore
.pytest_cache
.coverage
htmlcov/
dist/
build/
*.egg-info/
*.md
!README.md
docs/
tests/
.vscode/
.idea/
*.log
.DS_Store
```

```bash
# Build optimized image
docker build -t myproject:latest .

# Build with build args
docker build \
  --build-arg PYTHON_VERSION=3.11 \
  --build-arg ENVIRONMENT=production \
  -t myproject:1.0.0 .

# Run container
docker run -d \
  --name myproject \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://..." \
  -e SECRET_KEY="..." \
  --restart unless-stopped \
  myproject:latest

# View logs
docker logs -f myproject

# Execute commands in container
docker exec -it myproject python manage.py migrate

# Clean up
docker-compose down -v
docker system prune -a
```

## Configuration Management

Proper configuration management separates code from environment-specific settings.

### Twelve-Factor App Configuration

```python
# config.py - Environment-based configuration following 12-factor principles
import os
from typing import Any
from pathlib import Path

class Config:
    """Base configuration class"""
    
    # Application
    APP_NAME: str = os.environ.get('APP_NAME', 'MyProject')
    SECRET_KEY: str = os.environ.get('SECRET_KEY', 'dev-secret-change-in-production')
    DEBUG: bool = os.environ.get('DEBUG', 'False').lower() == 'true'
    TESTING: bool = False
    
    # Server
    HOST: str = os.environ.get('HOST', '0.0.0.0')
    PORT: int = int(os.environ.get('PORT', 8000))
    WORKERS: int = int(os.environ.get('WORKERS', 4))
    
    # Database
    DATABASE_URL: str = os.environ.get(
        'DATABASE_URL',
        'postgresql://postgres:password@localhost:5432/myapp'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False
    SQLALCHEMY_ECHO: bool = False
    SQLALCHEMY_ENGINE_OPTIONS: dict[str, Any] = {
        'pool_size': int(os.environ.get('DB_POOL_SIZE', 10)),
        'pool_recycle': int(os.environ.get('DB_POOL_RECYCLE', 3600)),
        'pool_pre_ping': True,
        'max_overflow': int(os.environ.get('DB_MAX_OVERFLOW', 20)),
        'pool_timeout': int(os.environ.get('DB_POOL_TIMEOUT', 30)),
    }
    
    # Redis
    REDIS_URL: str = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
    REDIS_MAX_CONNECTIONS: int = int(os.environ.get('REDIS_MAX_CONNECTIONS', 50))
    
    # Celery
    CELERY_BROKER_URL: str = os.environ.get('CELERY_BROKER_URL', REDIS_URL)
    CELERY_RESULT_BACKEND: str = os.environ.get('CELERY_RESULT_BACKEND', REDIS_URL)
    CELERY_TASK_SERIALIZER: str = 'json'
    CELERY_RESULT_SERIALIZER: str = 'json'
    CELERY_ACCEPT_CONTENT: list[str] = ['json']
    CELERY_TIMEZONE: str = 'UTC'
    CELERY_ENABLE_UTC: bool = True
    
    # Logging
    LOG_LEVEL: str = os.environ.get('LOG_LEVEL', 'INFO').upper()
    LOG_FORMAT: str = os.environ.get(
        'LOG_FORMAT',
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Security
    SESSION_COOKIE_SECURE: bool = True
    SESSION_COOKIE_HTTPONLY: bool = True
    SESSION_COOKIE_SAMESITE: str = 'Lax'
    PERMANENT_SESSION_LIFETIME: int = 3600  # 1 hour
    
    # CORS
    CORS_ORIGINS: list[str] = os.environ.get('CORS_ORIGINS', '*').split(',')
    
    # File Upload
    MAX_CONTENT_LENGTH: int = 16 * 1024 * 1024  # 16MB
    UPLOAD_FOLDER: Path = Path(os.environ.get('UPLOAD_FOLDER', '/tmp/uploads'))
    
    # API Rate Limiting
    RATELIMIT_ENABLED: bool = os.environ.get('RATELIMIT_ENABLED', 'True').lower() == 'true'
    RATELIMIT_STORAGE_URL: str = REDIS_URL
    RATELIMIT_DEFAULT: str = os.environ.get('RATELIMIT_DEFAULT', '100/hour')
    
    # Feature Flags
    FEATURE_NEW_UI: bool = os.environ.get('FEATURE_NEW_UI', 'False').lower() == 'true'
    FEATURE_ANALYTICS: bool = os.environ.get('FEATURE_ANALYTICS', 'True').lower() == 'true'
    
    @classmethod
    def validate(cls) -> None:
        """Validate required configuration"""
        if cls.SECRET_KEY == 'dev-secret-change-in-production':
            raise ValueError('SECRET_KEY must be set in production')
        
        if not cls.DATABASE_URL:
            raise ValueError('DATABASE_URL must be set')

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SQLALCHEMY_ECHO = True
    SESSION_COOKIE_SECURE = False
    LOG_LEVEL = 'DEBUG'

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DATABASE_URL = 'postgresql://postgres:password@localhost:5432/myapp_test'
    REDIS_URL = 'redis://localhost:6379/1'
    CELERY_TASK_ALWAYS_EAGER = True
    CELERY_TASK_EAGER_PROPAGATES = True
    WTF_CSRF_ENABLED = False

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    
    # Stricter settings for production
    SQLALCHEMY_ENGINE_OPTIONS = {
        **Config.SQLALCHEMY_ENGINE_OPTIONS,
        'pool_size': 20,
        'max_overflow': 40,
    }
    
    @classmethod
    def validate(cls) -> None:
        """Additional production validation"""
        super().validate()
        
        if cls.DEBUG:
            raise ValueError('DEBUG must be False in production')
        
        if not cls.DATABASE_URL.startswith('postgresql://'):
            raise ValueError('Production requires PostgreSQL database')

# Configuration dictionary
config_map = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

def get_config() -> Config:
    """Get configuration based on ENVIRONMENT variable"""
    env = os.environ.get('ENVIRONMENT', 'development').lower()
    config_class = config_map.get(env, config_map['default'])
    return config_class()
```

### Environment Variables

```bash
# .env.example - Template for environment variables
# Copy to .env and fill in actual values

# Application
APP_NAME=MyProject
ENVIRONMENT=development
DEBUG=True
SECRET_KEY=generate-a-secure-random-key

# Server
HOST=0.0.0.0
PORT=8000
WORKERS=4

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/myapp
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20

# Redis
REDIS_URL=redis://localhost:6379/0

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Logging
LOG_LEVEL=INFO

# CORS
CORS_ORIGINS=http://localhost:3000,https://example.com

# Rate Limiting
RATELIMIT_ENABLED=True
RATELIMIT_DEFAULT=100/hour

# Feature Flags
FEATURE_NEW_UI=False
FEATURE_ANALYTICS=True

# External Services
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
S3_BUCKET=my-bucket

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_PASSWORD=password

SENTRY_DSN=https://key@sentry.io/project
```

### Loading Environment Variables

```python
# app.py - Loading configuration
from dotenv import load_dotenv
from pathlib import Path

def create_app():
    """Application factory"""
    # Load environment variables from .env file
    env_path = Path('.') / '.env'
    load_dotenv(env_path)
    
    # Get configuration
    config = get_config()
    config.validate()
    
    # Initialize application
    app = Flask(__name__)
    app.config.from_object(config)
    
    return app
```

## Continuous Integration and Deployment

Automated CI/CD pipelines ensure code quality and streamline deployments.

### GitHub Actions Workflow

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  release:
    types: [published]

env:
  PYTHON_VERSION: '3.11'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Code quality and testing
  test:
    name: Test and Quality Checks
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install UV
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
      
      - name: Install dependencies
        run: |
          uv venv
          uv pip sync requirements-dev.txt
          source .venv/bin/activate
      
      - name: Lint with Ruff
        run: |
          source .venv/bin/activate
          ruff check .
      
      - name: Format check with Black
        run: |
          source .venv/bin/activate
          black --check .
      
      - name: Type check with MyPy
        run: |
          source .venv/bin/activate
          mypy myproject/
      
      - name: Run tests with coverage
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379/0
          ENVIRONMENT: testing
        run: |
          source .venv/bin/activate
          pytest --cov=myproject --cov-report=xml --cov-report=html -v
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella
      
      - name: Security check with Bandit
        run: |
          source .venv/bin/activate
          pip install bandit
          bandit -r myproject/ -f json -o bandit-report.json
      
      - name: Dependency vulnerability check
        run: |
          source .venv/bin/activate
          pip install safety
          safety check --json

  # Build and push Docker image
  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' || github.event_name == 'release'
    
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout code
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
            type=sha,prefix={{branch}}-
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # Deploy to staging
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Deploy to Kubernetes
        run: |
          # Install kubectl
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          
          # Configure kubectl
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > kubeconfig
          export KUBECONFIG=./kubeconfig
          
          # Deploy
          kubectl set image deployment/myproject \
            myproject=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:develop \
            -n staging
          
          kubectl rollout status deployment/myproject -n staging

  # Deploy to production
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'release'
    environment:
      name: production
      url: https://example.com
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Deploy to production
        run: |
          # Production deployment logic
          echo "Deploying to production..."
```

### GitLab CI/CD Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  PYTHON_VERSION: "3.11"
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

# Test stage
test:
  stage: test
  image: python:${PYTHON_VERSION}
  
  services:
    - postgres:16
    - redis:7-alpine
  
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test_db
    REDIS_URL: redis://redis:6379/0
  
  before_script:
    - curl -LsSf https://astral.sh/uv/install.sh | sh
    - export PATH="$HOME/.cargo/bin:$PATH"
    - uv venv
    - uv pip sync requirements-dev.txt
  
  script:
    - source .venv/bin/activate
    - ruff check .
    - black --check .
    - mypy myproject/
    - pytest --cov=myproject --cov-report=term --cov-report=html
  
  coverage: '/^TOTAL.+?(\d+\%)$/'
  
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - htmlcov/
    expire_in: 30 days

# Build stage
build:
  stage: build
  image: docker:24
  
  services:
    - docker:24-dind
  
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  
  only:
    - main
    - develop

# Deploy to staging
deploy:staging:
  stage: deploy
  image: bitnami/kubectl:latest
  
  script:
    - kubectl config use-context staging
    - kubectl set image deployment/myproject myproject=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - kubectl rollout status deployment/myproject
  
  environment:
    name: staging
    url: https://staging.example.com
  
  only:
    - develop

# Deploy to production
deploy:production:
  stage: deploy
  image: bitnami/kubectl:latest
  
  script:
    - kubectl config use-context production
    - kubectl set image deployment/myproject myproject=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - kubectl rollout status deployment/myproject
  
  environment:
    name: production
    url: https://example.com
  
  only:
    - main
  
  when: manual
```

## Monitoring and Observability

Production applications require comprehensive monitoring, logging, and tracing.

### Application Logging

```python
# logging_config.py
import logging
import sys
from pythonjsonlogger import jsonlogger
from config import get_config

def configure_logging() -> None:
    """Configure structured logging for production"""
    config = get_config()
    
    # Create root logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, config.LOG_LEVEL))
    logger.handlers = []
    
    # JSON formatter for structured logging
    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s %(pathname)s %(lineno)d',
        datefmt='%Y-%m-%dT%H:%M:%SZ'
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # Set levels for noisy third-party libraries
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('botocore').setLevel(logging.WARNING)
    logging.getLogger('werkzeug').setLevel(logging.INFO)
    
    logger.info('Logging configured', extra={
        'environment': config.ENVIRONMENT,
        'log_level': config.LOG_LEVEL
    })
```

### Prometheus Metrics

```python
# metrics.py
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Histogram, Gauge
import time

# Initialize Prometheus metrics
metrics = PrometheusMetrics(None)  # Pass app in init_app()

# Custom metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

active_users = Gauge(
    'active_users_total',
    'Number of active users'
)

celery_task_duration = Histogram(
    'celery_task_duration_seconds',
    'Celery task duration',
    ['task_name']
)

def init_metrics(app):
    """Initialize metrics with Flask app"""
    metrics.init_app(app)
    
    @app.before_request
    def before_request():
        request.start_time = time.time()
    
    @app.after_request
    def after_request(response):
        duration = time.time() - request.start_time
        
        request_count.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown',
            status=response.status_code
        ).inc()
        
        request_duration.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown'
        ).observe(duration)
        
        return response
```

### Health Check Endpoints

```python
# health.py
from flask import Blueprint, jsonify
import psycopg2
import redis
from datetime import datetime

health_bp = Blueprint('health', __name__)

@health_bp.route('/health')
def health():
    """Basic health check - is the application running?"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@health_bp.route('/ready')
def readiness():
    """Readiness check - can the application serve traffic?"""
    checks = {
        'database': check_database(),
        'redis': check_redis(),
    }
    
    all_healthy = all(check['status'] == 'healthy' for check in checks.values())
    status_code = 200 if all_healthy else 503
    
    return jsonify({
        'ready': all_healthy,
        'checks': checks,
        'timestamp': datetime.utcnow().isoformat()
    }), status_code

@health_bp.route('/live')
def liveness():
    """Liveness check - should the application be restarted?"""
    return jsonify({
        'alive': True,
        'timestamp': datetime.utcnow().isoformat()
    }), 200

def check_database():
    """Check database connectivity"""
    try:
        conn = psycopg2.connect(os.environ['DATABASE_URL'])
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        conn.close()
        return {'status': 'healthy'}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}

def check_redis():
    """Check Redis connectivity"""
    try:
        r = redis.from_url(os.environ['REDIS_URL'])
        r.ping()
        return {'status': 'healthy'}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}
```

### Error Tracking with Sentry

```python
# error_tracking.py
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from sentry_sdk.integrations.celery import CeleryIntegration
from sentry_sdk.integrations.redis import RedisIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

def init_sentry(app):
    """Initialize Sentry error tracking"""
    if app.config.get('SENTRY_DSN'):
        sentry_sdk.init(
            dsn=app.config['SENTRY_DSN'],
            integrations=[
                FlaskIntegration(),
                CeleryIntegration(),
                RedisIntegration(),
                SqlalchemyIntegration(),
            ],
            environment=app.config['ENVIRONMENT'],
            release=app.config.get('VERSION', 'unknown'),
            traces_sample_rate=0.1,  # 10% of transactions
            profiles_sample_rate=0.1,  # 10% of transactions
            send_default_pii=False,
            attach_stacktrace=True,
            before_send=before_send,
        )

def before_send(event, hint):
    """Filter events before sending to Sentry"""
    # Don't send health check errors
    if 'request' in event and event['request']['url'].endswith('/health'):
        return None
    return event
```

## Deployment Best Practices

### Pre-Deployment Checklist

- ✅ **Environment Variables**: All required variables configured
- ✅ **Database Migrations**: Migrations tested and ready
- ✅ **Dependencies**: All dependencies pinned to specific versions
- ✅ **Security**: Secrets properly managed, not in code
- ✅ **Tests**: All tests passing in CI/CD
- ✅ **Health Checks**: Health endpoints responding correctly
- ✅ **Monitoring**: Logging, metrics, and error tracking configured
- ✅ **Backup**: Database backup strategy in place
- ✅ **Rollback Plan**: Documented rollback procedure
- ✅ **Documentation**: Deployment docs updated

### Zero-Downtime Deployments

```yaml
# kubernetes deployment with rolling update
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myproject
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: app
        image: myproject:latest
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /live
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
```

### Database Migrations

```python
# migrations/script.py.mako - Alembic migration template
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}
"""
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}

def upgrade():
    """Upgrade schema"""
    ${upgrades if upgrades else "pass"}

def downgrade():
    """Downgrade schema"""
    ${downgrades if downgrades else "pass"}
```

```bash
# Run migrations in deployment
# 1. Generate migration
alembic revision --autogenerate -m "Add user table"

# 2. Review migration
cat migrations/versions/xxx_add_user_table.py

# 3. Test migration locally
alembic upgrade head

# 4. Deploy migration
kubectl exec -it deployment/myproject -- alembic upgrade head
```

### Graceful Shutdown

```python
# app.py - Handle shutdown signals
import signal
import sys

def create_app():
    app = Flask(__name__)
    
    def shutdown_handler(signum, frame):
        """Handle shutdown gracefully"""
        logger.info('Received signal %s, shutting down gracefully...', signum)
        
        # Stop accepting new requests
        # Close database connections
        # Finish processing current requests
        # Shut down background workers
        
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, shutdown_handler)
    signal.signal(signal.SIGINT, shutdown_handler)
    
    return app
```

## Security Considerations

### Secrets Management

```python
# secrets_manager.py - AWS Secrets Manager integration
import boto3
import json
from functools import lru_cache

class SecretsManager:
    """Manage secrets from AWS Secrets Manager"""
    
    def __init__(self, region_name='us-east-1'):
        self.client = boto3.client('secretsmanager', region_name=region_name)
    
    @lru_cache(maxsize=128)
    def get_secret(self, secret_name: str) -> dict:
        """Retrieve and cache secret"""
        try:
            response = self.client.get_secret_value(SecretId=secret_name)
            return json.loads(response['SecretString'])
        except Exception as e:
            logger.error(f'Error retrieving secret {secret_name}: {e}')
            raise

# Usage
secrets = SecretsManager()
db_creds = secrets.get_secret('production/database')
DATABASE_URL = db_creds['connection_string']
```

### Security Headers

```python
# security.py
from flask_talisman import Talisman

def configure_security(app):
    """Configure security headers"""
    
    csp = {
        'default-src': "'self'",
        'script-src': ["'self'", "'unsafe-inline'", 'cdn.example.com'],
        'style-src': ["'self'", "'unsafe-inline'"],
        'img-src': ["'self'", 'data:', 'https:'],
        'font-src': ["'self'", 'data:'],
    }
    
    Talisman(
        app,
        force_https=True,
        strict_transport_security=True,
        content_security_policy=csp,
        session_cookie_secure=True,
        session_cookie_http_only=True,
    )
```

## Performance Optimization

### Application Performance

```python
# performance.py
from flask_caching import Cache
from redis import Redis

# Initialize cache
cache = Cache(config={
    'CACHE_TYPE': 'redis',
    'CACHE_REDIS_URL': os.environ['REDIS_URL'],
    'CACHE_DEFAULT_TIMEOUT': 300
})

@app.route('/api/data')
@cache.cached(timeout=60, query_string=True)
def get_data():
    """Cached API endpoint"""
    return expensive_query()

# Connection pooling
redis_pool = Redis.from_url(
    os.environ['REDIS_URL'],
    max_connections=50,
    socket_connect_timeout=5,
    socket_timeout=5,
)
```

### Database Optimization

```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)
```

## Cloud Platform Deployment

For detailed cloud-specific deployment instructions, see:

- [Cloud Deployment Guide](cloud-deployment.md) - AWS, Azure, GCP, Heroku
- [CI/CD Pipeline Setup](ci.md) - Automated testing and deployment
- [Packaging Guide](packaging.md) - Distribution and deployment packages

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Find process using port
lsof -i :8000
netstat -tulpn | grep 8000

# Kill process
kill -9 <PID>
```

#### Memory Leaks

```python
# Use memory profiling
from memory_profiler import profile

@profile
def memory_intensive_function():
    # Function code
    pass
```

#### Database Connection Issues

```python
# Test database connectivity
import psycopg2

try:
    conn = psycopg2.connect(DATABASE_URL)
    print("Connection successful!")
except Exception as e:
    print(f"Connection failed: {e}")
```

## See Also

- [Cloud Deployment](cloud-deployment.md)
- [Python Packaging Guide](https://packaging.python.org/)
- [Twelve-Factor App](https://12factor.net/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Additional Resources

### Tools

- [UV](https://github.com/astral-sh/uv) - Fast Python package installer
- [Gunicorn](https://gunicorn.org/) - Python WSGI HTTP Server
- [Nginx](https://nginx.org/) - Reverse proxy and load balancer
- [Docker](https://www.docker.com/) - Containerization platform
- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [Prometheus](https://prometheus.io/) - Monitoring system
- [Grafana](https://grafana.com/) - Observability platform
- [Sentry](https://sentry.io/) - Error tracking

### Best Practices

- [Python Application Layouts](https://realpython.com/python-application-layouts/)
- [Production Best Practices](https://docs.python-guide.org/shipping/packaging/)
- [Security Best Practices](https://owasp.org/www-project-top-ten/)
- [CI/CD Best Practices](https://www.atlassian.com/continuous-delivery/principles/best-practices)
