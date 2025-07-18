#!/bin/bash

# Get the current directory where the script is executed
REPO_ROOT=$(pwd)
CONTAINERS_DIR="${REPO_ROOT}/docs/infrastructure/containers"
PGP_DIR="${REPO_ROOT}/docs/security/pgp"

# Create missing container tool subdirectories and index.md files
create_container_tool_pages() {
    local tools=(
        "conda" "gradle" "podman" "prometheus" "redis" "elk-stack" "mongodb-compass"
        "sealed-secrets" "trivy" "pgadmin" "jaeger" "gitlab" "junit" "regex" "dbeaver"
        "poetry" "grafana" "jest" "make" "jetbrains" "yarn" "fluentd" "prettier"
        "jenkins" "github" "mysql" "vscode" "pip" "terminal" "gitlab-ci" "sonarqube"
        "github-actions" "pnpm" "pulumi" "vim" "git" "loki" "owasp-zap" "pytest"
        "npm" "terraform" "markdown" "snyk" "sops" "vault" "docker-swarm" "eslint"
        "maven" "yaml" "docker/dockercompose"
    )
    
    for tool in "${tools[@]}"; do
        local tool_dir="${CONTAINERS_DIR}/${tool}"
        mkdir -p "$tool_dir"
        
        # Extract tool name for the title
        local tool_name=$(basename "$tool" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        
        # Create a basic index.md file
        cat > "${tool_dir}/index.md" << EOL
---
title: "${tool_name}"
description: "${tool_name} documentation"
category: "infrastructure"
tags: ["containers", "tools"]
---

# ${tool_name}

This is a placeholder page for ${tool_name} documentation.

## Overview

Content will be added soon.

## Resources

- Official documentation
- Tutorials
- Best practices
EOL
        echo "Created ${tool_dir}/index.md"
    done
}

# Create missing PGP documentation files
create_pgp_files() {
    # Array of missing PGP files
    local pgp_files=("04-key-management.md" "05-encryption.md")
    
    for file in "${pgp_files[@]}"; do
        local file_path="${PGP_DIR}/${file}"
        local title=$(echo "$file" | sed 's/^[0-9][0-9]-//' | sed 's/\.md$//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        
        # Create a basic file
        cat > "${file_path}" << EOL
---
title: "PGP ${title}"
description: "Guide to PGP ${title}"
category: "security"
tags: ["pgp", "encryption", "security"]
---

# PGP ${title}

This is a placeholder page for PGP ${title} documentation.

## Overview

Content will be added soon.

## Key Points

- Important information about PGP ${title}
- Step-by-step instructions
- Best practices
EOL
        echo "Created ${file_path}"
    done
}

# Execute the functions
create_container_tool_pages
create_pgp_files

echo "All placeholder files have been created."
