#!/bin/bash

# This script creates minimal placeholder files for missing directories
# referenced in DocFX warnings

# Base directory
BASE_DIR="/home/hades/Documents/repos/josephstreeter.github.io"
DOCS_DIR="$BASE_DIR/docs"

# Function to create minimal directory structure and index.md file
create_directory_and_index() {
    local dir_path="$1"
    local title="$2"
    
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        
        local index_file="$dir_path/index.md"
        echo "Creating index file: $index_file"
        cat > "$index_file" << EOF
---
title: "$title"
description: "Documentation for $title"
author: "Joseph Streeter"
ms.date: "$(date +'%Y-%m-%d')"
ms.topic: "article"
---

# $title

This is a placeholder for $title content.

## Overview

Content will be added here soon.

## Topics

Add topics here.
EOF
    else
        echo "Directory already exists: $dir_path - skipping"
    fi
}

# Function to create a toc.yml file
create_toc_yml() {
    local dir_path="$1"
    local title="$2"
    
    if [ ! -d "$dir_path" ]; then
        echo "Directory doesn't exist: $dir_path - skipping toc.yml creation"
        return
    fi
    
    local toc_file="$dir_path/toc.yml"
    if [ ! -f "$toc_file" ]; then
        echo "Creating toc file: $toc_file"
        cat > "$toc_file" << EOF
- name: $title
  href: index.md
EOF
    else
        echo "toc.yml already exists: $toc_file - skipping"
    fi
}

# Development section
echo "Creating Development directories..."
create_directory_and_index "$DOCS_DIR/development/git" "Git"
create_directory_and_index "$DOCS_DIR/development/vscode" "Visual Studio Code"
create_directory_and_index "$DOCS_DIR/development/regex" "Regular Expressions"

create_toc_yml "$DOCS_DIR/development/git" "Git"
create_toc_yml "$DOCS_DIR/development/vscode" "VS Code"
create_toc_yml "$DOCS_DIR/development/regex" "Regex"

# Python development section
echo "Creating Python development directories..."
create_directory_and_index "$DOCS_DIR/development/python/web-development" "Python Web Development"
create_directory_and_index "$DOCS_DIR/development/python/data-science" "Python for Data Science"
create_directory_and_index "$DOCS_DIR/development/python/best-practices" "Python Best Practices"
create_directory_and_index "$DOCS_DIR/development/python/package-management" "Python Package Management"

# Create files for Docker section
echo "Creating Docker documentation files..."
create_directory_and_index "$DOCS_DIR/infrastructure/containers/docker/quickstart" "Docker Quickstart"
create_directory_and_index "$DOCS_DIR/infrastructure/containers/docker/containers" "Working with Containers"
create_directory_and_index "$DOCS_DIR/infrastructure/containers/docker/compose" "Docker Compose"

# Create files for infrastructure sections
echo "Creating Infrastructure directories..."
create_directory_and_index "$DOCS_DIR/infrastructure/containers" "Containers"
create_directory_and_index "$DOCS_DIR/infrastructure/homelab" "Home Lab"
create_directory_and_index "$DOCS_DIR/infrastructure/proxmox" "Proxmox"

# Create files for network/services sections
echo "Creating Networking directories..."
create_directory_and_index "$DOCS_DIR/networking/unifi" "UniFi"
create_directory_and_index "$DOCS_DIR/services/containers" "Service Containers"
create_directory_and_index "$DOCS_DIR/services/homelab" "Service Home Lab" 
create_directory_and_index "$DOCS_DIR/services/proxmox" "Service Proxmox"

# Create files for security section
echo "Creating Security directories..."
create_directory_and_index "$DOCS_DIR/security/git" "Security with Git"
create_directory_and_index "$DOCS_DIR/security/vscode" "Security in VS Code"
create_directory_and_index "$DOCS_DIR/security/regex" "Security with Regex"
create_directory_and_index "$DOCS_DIR/security/ssh" "SSH"

# Create files for misc section
echo "Creating Miscellaneous directories..."
create_directory_and_index "$DOCS_DIR/misc/git" "Miscellaneous Git"
create_directory_and_index "$DOCS_DIR/misc/vscode" "Miscellaneous VS Code"
create_directory_and_index "$DOCS_DIR/misc/regex" "Miscellaneous Regex"

# Create personal section
create_directory_and_index "$DOCS_DIR/personal" "Personal"

# Create files for PGP section
echo "Creating PGP documentation files..."
create_directory_and_index "$DOCS_DIR/security/pgp/02-installation" "PGP Installation"
create_directory_and_index "$DOCS_DIR/security/pgp/03-key-management" "PGP Key Management"
create_directory_and_index "$DOCS_DIR/security/pgp/04-encryption" "PGP Encryption"
create_directory_and_index "$DOCS_DIR/security/pgp/05-advanced" "Advanced PGP Usage"
create_directory_and_index "$DOCS_DIR/security/pgp/06-email-integration" "PGP Email Integration"
create_directory_and_index "$DOCS_DIR/security/pgp/07-best-practices" "PGP Best Practices"

# Create files for Active Directory section
echo "Creating Active Directory documentation files..."
create_directory_and_index "$DOCS_DIR/services/activedirectory/security-best-practices" "AD Security Best Practices"
create_directory_and_index "$DOCS_DIR/services/activedirectory/group-policy-management" "Group Policy Management"
create_directory_and_index "$DOCS_DIR/services/activedirectory/ad-monitoring" "Active Directory Monitoring"
create_directory_and_index "$DOCS_DIR/services/activedirectory/disaster-recovery" "AD Disaster Recovery"

# Create directories for AD Security
create_directory_and_index "$DOCS_DIR/services/activedirectory/Security" "AD Security"
create_directory_and_index "$DOCS_DIR/services/activedirectory/Backup" "AD Backup"
create_directory_and_index "$DOCS_DIR/services/activedirectory/GroupPolicy" "Group Policy"
create_directory_and_index "$DOCS_DIR/services/activedirectory/DomainControllers" "Domain Controllers"
create_directory_and_index "$DOCS_DIR/services/activedirectory/PAM" "Privileged Access Management"
create_directory_and_index "$DOCS_DIR/services/identity" "Identity Management"
create_directory_and_index "$DOCS_DIR/services/identity/governance" "Identity Governance"
create_directory_and_index "$DOCS_DIR/services/infrastructure/disaster-recovery" "Disaster Recovery"

# Windows configuration files
create_directory_and_index "$DOCS_DIR/infrastructure/windows/configuration" "Windows Configuration"

echo "Placeholder files creation complete!"
