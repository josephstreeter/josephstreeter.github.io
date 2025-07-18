#!/bin/bash

# This script creates the needed MD files from the DocFX warnings

# Base directory
BASE_DIR="/home/hades/Documents/repos/josephstreeter.github.io"

# Function to create a basic MD file
create_md_file() {
    local filepath="$1"
    local title="$2"
    
    # Extract directory path from file path
    local dirpath=$(dirname "$filepath")
    
    # Create directory if it doesn't exist
    if [ ! -d "$dirpath" ]; then
        mkdir -p "$dirpath"
        echo "Created directory: $dirpath"
    fi
    
    # Create the MD file if it doesn't exist
    if [ ! -f "$filepath" ]; then
        echo "Creating file: $filepath"
        cat > "$filepath" << EOF
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
        echo "File already exists: $filepath - skipping"
    fi
}

# Create MD files for Python section
echo "Creating Python documentation files..."
create_md_file "$BASE_DIR/docs/development/python/web-development.md" "Python Web Development"
create_md_file "$BASE_DIR/docs/development/python/data-science.md" "Python Data Science"
create_md_file "$BASE_DIR/docs/development/python/best-practices.md" "Python Best Practices"
create_md_file "$BASE_DIR/docs/development/python/package-management.md" "Python Package Management"

# Create files for Docker section
echo "Creating Docker documentation files..."
create_md_file "$BASE_DIR/docs/infrastructure/containers/docker/quickstart.md" "Docker Quickstart"
create_md_file "$BASE_DIR/docs/infrastructure/containers/docker/containers.md" "Working with Docker Containers"
create_md_file "$BASE_DIR/docs/infrastructure/containers/docker/compose.md" "Docker Compose"

# Create Windows configuration file
echo "Creating Windows configuration file..."
create_md_file "$BASE_DIR/docs/infrastructure/windows/configuration.md" "Windows Configuration"

# Create PGP section files
echo "Creating PGP documentation files..."
create_md_file "$BASE_DIR/docs/security/pgp/02-installation.md" "PGP Installation"
create_md_file "$BASE_DIR/docs/security/pgp/03-key-management.md" "PGP Key Management"
create_md_file "$BASE_DIR/docs/security/pgp/04-encryption.md" "PGP Encryption"
create_md_file "$BASE_DIR/docs/security/pgp/05-advanced.md" "Advanced PGP"
create_md_file "$BASE_DIR/docs/security/pgp/06-email-integration.md" "PGP Email Integration"
create_md_file "$BASE_DIR/docs/security/pgp/07-best-practices.md" "PGP Best Practices"

# Create Active Directory documentation files
echo "Creating Active Directory documentation files..."
create_md_file "$BASE_DIR/docs/services/activedirectory/security-best-practices.md" "AD Security Best Practices"
create_md_file "$BASE_DIR/docs/services/activedirectory/group-policy-management.md" "AD Group Policy Management"
create_md_file "$BASE_DIR/docs/services/activedirectory/ad-monitoring.md" "AD Monitoring"
create_md_file "$BASE_DIR/docs/services/activedirectory/disaster-recovery.md" "AD Disaster Recovery"

echo "Files creation complete!"
