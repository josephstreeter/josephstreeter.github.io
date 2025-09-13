---
title: Docker Quickstart
description: Complete guide to getting started with Docker, from installation to running your first containers
author: Joseph Streeter
date: 2024-01-15
tags: [docker, containers, quickstart, installation, tutorial]
---

Docker is a platform that enables developers to package applications and their dependencies into lightweight, portable containers. This quickstart guide will get you up and running with Docker in minutes.

## What is Docker?

Docker containers are lightweight, standalone packages that include everything needed to run an application: code, runtime, system tools, libraries, and settings. Unlike virtual machines, containers share the host OS kernel, making them more efficient.

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Architecture                          │
├─────────────────────────────────────────────────────────────────┤
│  Docker Client  │ Commands (docker run, build, pull, push)     │
│  Docker Daemon  │ Manages containers, images, networks         │
│  Docker Images  │ Read-only templates for creating containers  │
│  Docker Containers │ Running instances of images              │
│  Docker Registry │ Repository for storing and sharing images   │
└─────────────────────────────────────────────────────────────────┘
```

## Installation

### Linux Installation

#### Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

#### CentOS/RHEL/Fedora

```bash
# Install required packages
sudo dnf install -y dnf-plugins-core

# Add Docker repository
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker Engine
sudo dnf install docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

### Windows Installation

1. Download Docker Desktop for Windows from [docker.com](https://www.docker.com/products/docker-desktop)
2. Run the installer and follow the setup wizard
3. Restart your computer when prompted
4. Launch Docker Desktop from the Start menu

### macOS Installation

1. Download Docker Desktop for Mac from [docker.com](https://www.docker.com/products/docker-desktop)
2. Drag Docker.app to the Applications folder
3. Launch Docker from Applications
4. Complete the setup process

## Verify Installation

```bash
# Check Docker version
docker --version

# Check Docker info
docker info

# Run hello-world container
docker run hello-world
```

Expected output:

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

## Essential Docker Commands

### Image Management

```bash
# Search for images
docker search nginx

# Pull an image from Docker Hub
docker pull nginx:latest

# List local images
docker images

# Remove an image
docker rmi nginx:latest

# Build image from Dockerfile
docker build -t myapp:latest .
```

### Container Management

```bash
# Run a container
docker run nginx

# Run container in background
docker run -d nginx

# Run container with port mapping
docker run -d -p 8080:80 nginx

# Run container with name
docker run -d --name webserver nginx

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop webserver

# Start a stopped container
docker start webserver

# Remove a container
docker rm webserver

# Remove all stopped containers
docker container prune
```

### Interactive Containers

```bash
# Run container interactively
docker run -it ubuntu:latest /bin/bash

# Execute command in running container
docker exec -it webserver /bin/bash

# Copy files to/from container
docker cp localfile.txt webserver:/app/
docker cp webserver:/app/logfile.txt ./
```

## Your First Container

### Running a Web Server

```bash
# Run Nginx web server
docker run -d -p 8080:80 --name my-nginx nginx:latest

# Check if container is running
docker ps

# Test the web server
curl http://localhost:8080

# View container logs
docker logs my-nginx

# Stop and remove the container
docker stop my-nginx
docker rm my-nginx
```

### Running a Database

```bash
# Run MySQL database
docker run -d \
  --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=mypassword \
  -e MYSQL_DATABASE=testdb \
  -p 3306:3306 \
  mysql:8.0

# Connect to MySQL
docker exec -it mysql-db mysql -u root -p

# Run PostgreSQL database
docker run -d \
  --name postgres-db \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=testdb \
  -p 5432:5432 \
  postgres:13
```

## Working with Dockerfiles

### Basic Dockerfile

Create a file named `Dockerfile`:

```dockerfile
# Use official Node.js runtime as base image
FROM node:16-alpine

# Set working directory in container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Define command to run application
CMD ["npm", "start"]
```

### Build and Run Custom Image

```bash
# Build the image
docker build -t my-node-app:latest .

# Run the container
docker run -d -p 3000:3000 --name node-app my-node-app:latest

# View application
curl http://localhost:3000
```

### Multi-stage Dockerfile Example

```dockerfile
# Build stage
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:16-alpine AS production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

## Container Networking

### Basic Networking

```bash
# Create custom network
docker network create mynetwork

# Run containers on same network
docker run -d --name web --network mynetwork nginx
docker run -d --name db --network mynetwork mysql:8.0

# List networks
docker network ls

# Inspect network
docker network inspect mynetwork
```

### Port Mapping Examples

```bash
# Map single port
docker run -p 8080:80 nginx

# Map multiple ports
docker run -p 8080:80 -p 8443:443 nginx

# Map to specific interface
docker run -p 127.0.0.1:8080:80 nginx

# Map random port
docker run -P nginx
```

## Volume Management

### Types of Volumes

#### Named Volumes

```bash
# Create named volume
docker volume create mydata

# Use named volume
docker run -d -v mydata:/data alpine

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata
```

#### Bind Mounts

```bash
# Mount host directory
docker run -d -v /host/path:/container/path nginx

# Mount current directory
docker run -d -v $(pwd):/app node:16-alpine

# Read-only mount
docker run -d -v /host/path:/container/path:ro nginx
```

#### tmpfs Mounts

```bash
# Create temporary filesystem in memory
docker run -d --tmpfs /tmp nginx
```

## Docker Compose Quick Start

### Install Docker Compose

```bash
# Linux installation
sudo curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Basic docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: webapp
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### Docker Compose Commands

```bash
# Start services
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build
```

## Best Practices

### Security

- **Run as non-root user** in containers
- **Use specific image tags** instead of `latest`
- **Scan images for vulnerabilities** regularly
- **Keep images updated** with security patches
- **Use multi-stage builds** to reduce image size

```dockerfile
# Create non-root user
FROM node:16-alpine
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs
```

### Performance

- **Minimize layers** in Dockerfile
- **Use .dockerignore** to exclude unnecessary files
- **Optimize image size** by removing unnecessary packages
- **Use appropriate base images** (alpine for smaller size)

```dockerfile
# .dockerignore example
node_modules
npm-debug.log
.git
.DS_Store
*.md
```

### Resource Management

```bash
# Limit memory usage
docker run -m 512m nginx

# Limit CPU usage
docker run --cpus="1.5" nginx

# Set restart policy
docker run --restart=unless-stopped nginx
```

## Troubleshooting Common Issues

### Container Won't Start

```bash
# Check container logs
docker logs container-name

# Check container status
docker inspect container-name

# Run container interactively for debugging
docker run -it image-name /bin/bash
```

### Port Already in Use

```bash
# Find process using port
sudo netstat -tulpn | grep :8080

# Kill process using port
sudo kill -9 PID
```

### Out of Disk Space

```bash
# Clean up unused resources
docker system prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

## Next Steps

After completing this quickstart:

1. **Learn Docker Compose** for multi-container applications
2. **Explore container orchestration** with Kubernetes
3. **Set up CI/CD pipelines** with Docker
4. **Study container security** best practices
5. **Learn about container monitoring** and logging

## Related Topics

- [Working with Docker Containers](containers.md)
- [Container Security](../security/index.md)
- [Container Orchestration](../orchestration/index.md)
- [DevOps Best Practices](../../../development/devops/index.md)

## Topics

Add topics here.
