---
title: "Authentik Installation and Deployment"
description: "Deploying Authentik with Docker Compose — single-instance and high-availability"
category: "infrastructure"
author: "Joseph Streeter"
ms.date: 2026-07-17
---

## Installation and Deployment

### Prerequisites and Requirements

#### System Requirements

| Component | Minimum | Recommended | Production |
| --------- | ------- | ----------- | ---------- |
| **CPU** | 2 cores | 4 cores | 8+ cores |
| **Memory** | 4GB RAM | 8GB RAM | 16+ GB RAM |
| **Storage** | 20GB | 100GB | 500+ GB SSD |
| **Network** | 1 Gbps | 1 Gbps | 10 Gbps |

#### Software Dependencies

- **Container Runtime**: Docker 20.10+ or Podman 3.0+
- **Orchestration**: Docker Compose 2.0+ or Kubernetes 1.21+
- **Database**: PostgreSQL 12+ (13+ recommended)
- **Cache**: Redis 6.0+
- **Reverse Proxy**: Nginx, Traefik, or HAProxy
- **TLS Certificates**: Let's Encrypt or corporate CA

### Docker Compose Deployment

#### Production-Ready Configuration

```yaml
# docker-compose.yml - Production configuration
version: '3.8'

services:
  authentik-server:
    image: ghcr.io/goauthentik/server:2024.2.2
    restart: unless-stopped
    command: server
    ports:
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9443:9443"
    environment:
      AUTHENTIK_SECRET_KEY: "${AUTHENTIK_SECRET_KEY}"
      AUTHENTIK_ERROR_REPORTING__ENABLED: "false"
      AUTHENTIK_POSTGRESQL__HOST: postgres
      AUTHENTIK_POSTGRESQL__USER: "${POSTGRES_USER:-authentik}"
      AUTHENTIK_POSTGRESQL__NAME: "${POSTGRES_DB:-authentik}"
      AUTHENTIK_POSTGRESQL__PASSWORD: "${POSTGRES_PASSWORD}"
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_LOG_LEVEL: "${AUTHENTIK_LOG_LEVEL:-info}"
      AUTHENTIK_EMAIL__HOST: "${SMTP_HOST}"
      AUTHENTIK_EMAIL__PORT: "${SMTP_PORT:-587}"
      AUTHENTIK_EMAIL__USERNAME: "${SMTP_USERNAME}"
      AUTHENTIK_EMAIL__PASSWORD: "${SMTP_PASSWORD}"
      AUTHENTIK_EMAIL__USE_TLS: "${SMTP_USE_TLS:-true}"
      AUTHENTIK_EMAIL__FROM: "${SMTP_FROM}"
    volumes:
      - ./media:/media
      - ./custom-templates:/templates
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - authentik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.authentik.rule=Host(`auth.example.com`)"
      - "traefik.http.routers.authentik.tls=true"
      - "traefik.http.routers.authentik.tls.certresolver=letsencrypt"
    healthcheck:
      test: ["CMD", "ak", "healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  authentik-worker:
    image: ghcr.io/goauthentik/server:2024.2.2
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_SECRET_KEY: "${AUTHENTIK_SECRET_KEY}"
      AUTHENTIK_ERROR_REPORTING__ENABLED: "false"
      AUTHENTIK_POSTGRESQL__HOST: postgres
      AUTHENTIK_POSTGRESQL__USER: "${POSTGRES_USER:-authentik}"
      AUTHENTIK_POSTGRESQL__NAME: "${POSTGRES_DB:-authentik}"
      AUTHENTIK_POSTGRESQL__PASSWORD: "${POSTGRES_PASSWORD}"
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_LOG_LEVEL: "${AUTHENTIK_LOG_LEVEL:-info}"
      AUTHENTIK_EMAIL__HOST: "${SMTP_HOST}"
      AUTHENTIK_EMAIL__PORT: "${SMTP_PORT:-587}"
      AUTHENTIK_EMAIL__USERNAME: "${SMTP_USERNAME}"
      AUTHENTIK_EMAIL__PASSWORD: "${SMTP_PASSWORD}"
      AUTHENTIK_EMAIL__USE_TLS: "${SMTP_USE_TLS:-true}"
      AUTHENTIK_EMAIL__FROM: "${SMTP_FROM}"
    volumes:
      - ./media:/media
      - ./custom-templates:/templates
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - authentik

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_USER: "${POSTGRES_USER:-authentik}"
      POSTGRES_DB: "${POSTGRES_DB:-authentik}"
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres-init:/docker-entrypoint-initdb.d:ro
    networks:
      - authentik
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    command: >
      postgres
        -c max_connections=200
        -c shared_buffers=256MB
        -c effective_cache_size=1GB
        -c maintenance_work_mem=64MB
        -c checkpoint_completion_target=0.9
        -c wal_buffers=16MB
        -c default_statistics_target=100
        -c random_page_cost=1.1
        -c effective_io_concurrency=200
        -c work_mem=4MB
        -c min_wal_size=1GB
        -c max_wal_size=4GB

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: >
      redis-server
        --appendonly yes
        --maxmemory 256mb
        --maxmemory-policy allkeys-lru
        --save 900 1
        --save 300 10
        --save 60 10000
    volumes:
      - redis_data:/data
    networks:
      - authentik
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  authentik:
    driver: bridge
```

#### Environment Configuration

```bash
# .env file for production deployment
# Generate secret key: openssl rand -base64 32
AUTHENTIK_SECRET_KEY=your-generated-secret-key-here

# Database configuration
POSTGRES_USER=authentik
POSTGRES_DB=authentik
POSTGRES_PASSWORD=your-secure-database-password

# Logging
AUTHENTIK_LOG_LEVEL=info

# Email configuration
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=authentik@example.com
SMTP_PASSWORD=your-smtp-password
SMTP_USE_TLS=true
SMTP_FROM=Authentik <authentik@example.com>

# Domain configuration
AUTHENTIK_DOMAIN=auth.example.com
```

### Kubernetes Deployment

#### Helm Chart Configuration

```yaml
# values.yaml for Helm deployment
authentik:
  secret_key: "your-secret-key"
  log_level: info
  error_reporting:
    enabled: false

server:
  replicas: 3
  image:
    repository: ghcr.io/goauthentik/server
    tag: "2024.2.2"
  
  ingress:
    enabled: true
    hosts:
      - host: auth.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: authentik-tls
        hosts:
          - auth.example.com

worker:
  replicas: 2
  image:
    repository: ghcr.io/goauthentik/server
    tag: "2024.2.2"

postgresql:
  enabled: true
  auth:
    username: authentik
    database: authentik
    password: "your-database-password"
  primary:
    persistence:
      size: 100Gi
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"

redis:
  enabled: true
  auth:
    enabled: false
  master:
    persistence:
      size: 10Gi
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### Installation Scripts

#### Automated Deployment Script

```powershell
function Deploy-Authentik
{
    param(
        [Parameter(Mandatory)]
        [string]$Domain,
        [Parameter(Mandatory)]
        [string]$Email,
        [string]$Environment = "production",
        [string]$DatabasePassword,
        [string]$SecretKey,
        [switch]$UseSSL = $true,
        [switch]$EnableBackups = $true
    )
    
    Write-Host "Deploying Authentik Identity Provider" -ForegroundColor Cyan
    Write-Host "Domain: $Domain" -ForegroundColor Yellow
    Write-Host "Environment: $Environment" -ForegroundColor Yellow
    
    try
    {
        # Generate secure passwords if not provided
        if (-not $DatabasePassword)
        {
            $DatabasePassword = -join ((1..32) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) })
            Write-Host "Generated database password" -ForegroundColor Green
        }
        
        if (-not $SecretKey)
        {
            $SecretKey = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
            Write-Host "Generated secret key" -ForegroundColor Green
        }
        
        # Create deployment directory
        $deployPath = "./authentik-deployment"
        if (-not (Test-Path $deployPath))
        {
            New-Item -ItemType Directory -Path $deployPath -Force | Out-Null
            Write-Host "Created deployment directory: $deployPath" -ForegroundColor Green
        }
        
        # Create environment file
        $envContent = @"
# Authentik Environment Configuration
AUTHENTIK_SECRET_KEY=$SecretKey
POSTGRES_USER=authentik
POSTGRES_DB=authentik
POSTGRES_PASSWORD=$DatabasePassword
AUTHENTIK_LOG_LEVEL=info
SMTP_HOST=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_USE_TLS=true
SMTP_FROM=Authentik <$Email>
AUTHENTIK_DOMAIN=$Domain
"@
        
        $envContent | Out-File -FilePath "$deployPath/.env" -Encoding UTF8
        Write-Host "Created environment configuration" -ForegroundColor Green
        
        # Download docker-compose.yml
        $composeUrl = "https://raw.githubusercontent.com/goauthentik/authentik/main/docker-compose.yml"
        try
        {
            Invoke-WebRequest -Uri $composeUrl -OutFile "$deployPath/docker-compose.yml"
            Write-Host "Downloaded docker-compose.yml" -ForegroundColor Green
        }
        catch
        {
            Write-Warning "Failed to download compose file. Creating basic configuration."
            
            # Create basic compose file
            $composeContent = @"
version: '3.8'
services:
  authentik-server:
    image: ghcr.io/goauthentik/server:latest
    restart: unless-stopped
    command: server
    ports:
      - "9000:9000"
      - "9443:9443"
    environment:
      AUTHENTIK_SECRET_KEY: `${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_POSTGRESQL__HOST: postgres
      AUTHENTIK_POSTGRESQL__USER: `${POSTGRES_USER}
      AUTHENTIK_POSTGRESQL__NAME: `${POSTGRES_DB}
      AUTHENTIK_POSTGRESQL__PASSWORD: `${POSTGRES_PASSWORD}
      AUTHENTIK_REDIS__HOST: redis
    volumes:
      - ./media:/media
    depends_on:
      - postgres
      - redis

  authentik-worker:
    image: ghcr.io/goauthentik/server:latest
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_SECRET_KEY: `${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_POSTGRESQL__HOST: postgres
      AUTHENTIK_POSTGRESQL__USER: `${POSTGRES_USER}
      AUTHENTIK_POSTGRESQL__NAME: `${POSTGRES_DB}
      AUTHENTIK_POSTGRESQL__PASSWORD: `${POSTGRES_PASSWORD}
      AUTHENTIK_REDIS__HOST: redis
    volumes:
      - ./media:/media
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: `${POSTGRES_PASSWORD}
      POSTGRES_USER: `${POSTGRES_USER}
      POSTGRES_DB: `${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    restart: unless-stopped
    command: --save 60 1 --loglevel warning
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
"@
            
            $composeContent | Out-File -FilePath "$deployPath/docker-compose.yml" -Encoding UTF8
            Write-Host "Created basic docker-compose.yml" -ForegroundColor Yellow
        }
        
        # Create media directory
        New-Item -ItemType Directory -Path "$deployPath/media" -Force | Out-Null
        
        # Set directory to deployment path
        Push-Location $deployPath
        
        try
        {
            # Pull images
            Write-Host "Pulling Docker images..." -ForegroundColor Yellow
            & docker-compose pull
            
            # Start services
            Write-Host "Starting Authentik services..." -ForegroundColor Yellow
            & docker-compose up -d
            
            # Wait for services to be ready
            Write-Host "Waiting for services to start..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            
            # Check service status
            $services = & docker-compose ps --services
            $runningServices = & docker-compose ps --services --filter "status=running"
            
            Write-Host "`nDeployment Status:" -ForegroundColor Green
            Write-Host "  Total services: $($services.Count)" -ForegroundColor White
            Write-Host "  Running services: $($runningServices.Count)" -ForegroundColor White
            
            if ($services.Count -eq $runningServices.Count)
            {
                Write-Host "✓ All services started successfully" -ForegroundColor Green
                
                # Display access information
                Write-Host "`nAuthentik Access Information:" -ForegroundColor Cyan
                Write-Host "  Web Interface: http://localhost:9000" -ForegroundColor White
                Write-Host "  HTTPS Interface: https://localhost:9443" -ForegroundColor White
                
                if ($UseSSL)
                {
                    Write-Host "  Production URL: https://$Domain" -ForegroundColor White
                }
                else
                {
                    Write-Host "  Production URL: http://$Domain" -ForegroundColor White
                }
                
                Write-Host "`nNext Steps:" -ForegroundColor Yellow
                Write-Host "  1. Configure reverse proxy for $Domain" -ForegroundColor White
                Write-Host "  2. Set up SSL certificates" -ForegroundColor White
                Write-Host "  3. Access the web interface and complete initial setup" -ForegroundColor White
                Write-Host "  4. Configure SMTP settings for email" -ForegroundColor White
                Write-Host "  5. Set up your first authentication flow" -ForegroundColor White
                
                if ($EnableBackups)
                {
                    Write-Host "`nBackup Configuration:" -ForegroundColor Cyan
                    Write-Host "  Database backup recommended - configure PostgreSQL backups" -ForegroundColor White
                    Write-Host "  Media folder backup: $deployPath/media" -ForegroundColor White
                }
            }
            else
            {
                Write-Warning "Some services failed to start. Check logs with: docker-compose logs"
                return $false
            }
        }
        finally
        {
            Pop-Location
        }
        
        # Store deployment info
        $deploymentInfo = @{
            Domain = $Domain
            DeploymentPath = $deployPath
            Environment = $Environment
            DatabasePassword = $DatabasePassword
            SecretKey = $SecretKey
            DeploymentTime = Get-Date
        }
        
        return $deploymentInfo
    }
    catch
    {
        Write-Error "Authentik deployment failed: $($_.Exception.Message)"
        return $null
    }
}
```

---

## Navigation

[◄ Architecture and Components](architecture.md) · [Authentik Overview](index.md) · [Configuration and Flows ►](configuration.md)
