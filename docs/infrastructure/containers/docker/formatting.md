---
title: "Docker Command Formatting"
description: "Complete guide to customizing Docker command output formatting"
tags: ["docker", "containers", "cli", "formatting"]
category: "infrastructure"
difficulty: "beginner"
last_updated: "2025-01-20"
---

## Docker Command Formatting

Docker provides powerful formatting options for customizing command output using Go template syntax. This allows you to display only the information you need in a clean, readable format.

## Why Use Custom Formatting?

- **Improved readability** - Show only relevant information
- **Better automation** - Extract specific data for scripts
- **Consistent output** - Standardize format across environments
- **Space efficiency** - Reduce terminal clutter
- **Integration friendly** - Easily parse output in CI/CD pipelines

## Format `docker ps` Output

The `docker ps --format` command allows formatting of the command's output by specifying a Go template string.

### Available Template Variables

- **Names**: `{{.Names}}` - Container name
- **ID**: `{{.ID}}` - Container ID (short)
- **Image**: `{{.Image}}` - Image name and tag
- **Command**: `{{.Command}}` - Command being executed
- **Created**: `{{.CreatedAt}}` - Creation timestamp
- **RunningFor**: `{{.RunningFor}}` - Time since creation
- **Status**: `{{.Status}}` - Current container status
- **Ports**: `{{.Ports}}` - Published ports
- **Size**: `{{.Size}}` - Container size
- **Labels**: `{{.Labels}}` - Container labels
- **Mounts**: `{{.Mounts}}` - Volume mounts
- **Networks**: `{{.Networks}}` - Connected networks

### Basic Examples

```bash
# Simple table format
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}"
```

Output:

```text
CONTAINER ID   IMAGE                          NAMES              STATUS
0ebc7a0771fe   immauss/openvas:latest         openvas            Exited (143) 6 weeks ago
676c1497334b   weatherapp:0.0.1               heuristic_panini   Created
81320d86dd52   python_wx:1.0.1                python_wx          Exited (137) 4 months ago
b84ed4fe4739   rabbitmq:3-management-alpine   rabbitmq           Exited (0) 4 months ago
```

### Advanced Examples

```bash
# Show containers with ports and running time
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.RunningFor}}"

# Compact view for scripts
docker ps --format "{{.Names}}:{{.Status}}"

# Detailed view with creation time
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Size}}"

# JSON-like output for parsing
docker ps --format "{{json .}}"

# Custom headers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" --no-trunc
```

### Filtering with Formatting

```bash
# Show only running containers
docker ps --filter "status=running" --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"

# Show containers from specific image
docker ps --filter "ancestor=nginx" --format "{{.Names}}: {{.Ports}}"

# Show containers with specific label
docker ps --filter "label=environment=production" --format "table {{.Names}}\t{{.Status}}"
```

## Format Other Docker Commands

### Docker Images

```bash
# Available template variables for docker images
# {{.Repository}}, {{.Tag}}, {{.ID}}, {{.CreatedAt}}, {{.Size}}

# Custom image listing
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"

# Show only image names and sizes
docker images --format "{{.Repository}}:{{.Tag}} - {{.Size}}"

# JSON output for all image data
docker images --format "{{json .}}"
```

### Docker Networks

```bash
# Available template variables for docker network
# {{.ID}}, {{.Name}}, {{.Driver}}, {{.Scope}}, {{.IPv4}}, {{.IPv6}}

# List networks with driver info
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# Simple network listing
docker network ls --format "{{.Name}}: {{.Driver}}"
```

### Docker Volumes

```bash
# Available template variables for docker volume
# {{.Name}}, {{.Driver}}, {{.Mountpoint}}

# List volumes with mount points
docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"
```

## Configuration Methods

### Method 1: Docker Config File

Create or edit the Docker configuration file:

```bash
# Create config directory if it doesn't exist
mkdir -p ~/.docker

# Edit configuration file
vi ~/.docker/config.json
```

Add the following configuration:

```json
{
  "psFormat": "table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}",
  "imagesFormat": "table {{.Repository}}\\t{{.Tag}}\\t{{.ID}}\\t{{.Size}}",
  "statsFormat": "table {{.Container}}\\t{{.CPUPerc}}\\t{{.MemUsage}}",
  "networksFormat": "table {{.Name}}\\t{{.Driver}}\\t{{.Scope}}"
}
```

### Method 2: Shell Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Docker formatting aliases
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}"'
alias dimages='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"'
alias dnetworks='docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"'
alias dvolumes='docker volume ls --format "table {{.Name}}\t{{.Driver}}"'

# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc
```

### Method 3: Environment Variables

```bash
# Set default format via environment variable
export DOCKER_CLI_EXPERIMENTAL=enabled
export DOCKER_PS_FORMAT="table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# Add to shell profile for persistence
echo 'export DOCKER_PS_FORMAT="table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"' >> ~/.bashrc
```

## Practical Use Cases

### For Monitoring

```bash
# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Quick health check
docker ps --format "{{.Names}}: {{.Status}}" | grep -v "Up"
```

### For Automation/Scripts

```bash
# Get container IDs for cleanup
CONTAINER_IDS=$(docker ps -q --filter "status=exited")

# Extract specific information
docker ps --format "{{.Names}},{{.Ports}}" > containers.csv

# Get running containers as JSON for processing
docker ps --format "{{json .}}" | jq '.Names'
```

### For Development

```bash
# Show development containers only
docker ps --filter "label=env=development" --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# Quick port mapping overview
docker ps --format "{{.Names}}: {{.Ports}}" | grep -E ":[0-9]+"
```

## Advanced Formatting

### Conditional Logic

```bash
# Show status with color indicators (requires additional processing)
docker ps --format "{{.Names}}: {{.Status}}" | sed 's/Up/✅ Up/g; s/Exited/❌ Exited/g'

# Custom date formatting
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}" --no-trunc
```

### Combining with Other Tools

```bash
# Pipe to column for better alignment
docker ps --format "{{.Names}} {{.Image}} {{.Status}}" | column -t

# Use with jq for JSON processing
docker ps --format "{{json .}}" | jq -r '.Names + ": " + .Status'

# Integration with watch for live monitoring
watch 'docker ps --format "table {{.Names}}\t{{.CPUPerc}}\t{{.MemUsage}}"'
```

## Troubleshooting

### Common Issues

1. **Escaping backslashes in config.json**:

   ```json
   // Correct
   {"psFormat": "table {{.Names}}\\t{{.Image}}"}
   
   // Incorrect
   {"psFormat": "table {{.Names}}\t{{.Image}}"}
   ```

2. **Template variable case sensitivity**:

   ```bash
   # Correct
   {{.Names}}
   
   # Incorrect
   {{.names}}
   ```

3. **Missing table keyword**:

   ```bash
   # With headers
   docker ps --format "table {{.Names}}\t{{.Status}}"
   
   # Without headers
   docker ps --format "{{.Names}}\t{{.Status}}"
   ```

### Validation

```bash
# Test configuration syntax
docker ps --format "table {{.Names}}\t{{.Image}}" --limit 1

# Check config file syntax
cat ~/.docker/config.json | jq .

# Verify template variables
docker ps --format "{{json .}}" | jq keys
```

This comprehensive guide provides everything needed to effectively customize Docker command output formatting.
