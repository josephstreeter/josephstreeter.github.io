#!/bin/bash

# This script fixes directory-level links in the documentation
# DocFX requires links to directories to point to index.md files within those directories

# Base directory
BASE_DIR="/home/hades/Documents/repos/josephstreeter.github.io"

# Function to fix directory links in a file
fix_directory_links() {
    local file="$1"
    
    echo "Processing file: $file"
    
    # Create a backup of the file if it doesn't exist
    if [ ! -f "${file}.bak" ]; then
        cp "$file" "${file}.bak"
    fi
    
    # Replace directory links with index.md links - specific patterns from warnings
    sed -i 's|(~/docs/\([^)]*\)/)|(\1/index.md)|g' "$file"
    sed -i 's|:(~/docs/\([^)]*\)/)|:\1/index.md|g' "$file"
    sed -i 's|Invalid file link:(~/docs/|Invalid file link:\1/index.md|g' "$file"
}

# List of files with InvalidFileLink warnings
FILES=(
    "$BASE_DIR/docs/development/index.md"
    "$BASE_DIR/docs/development/python/index.md"
    "$BASE_DIR/docs/infrastructure/containers/docker/index.md"
    "$BASE_DIR/docs/infrastructure/containers/index.md"
    "$BASE_DIR/docs/infrastructure/index.md"
    "$BASE_DIR/docs/infrastructure/windows/index.md"
    "$BASE_DIR/docs/introduction.md"
    "$BASE_DIR/docs/misc/index.md"
    "$BASE_DIR/docs/networking/index.md"
    "$BASE_DIR/docs/security/index.md"
    "$BASE_DIR/docs/security/pgp/01-summary.md"
    "$BASE_DIR/docs/security/pgp/03-install-clients.md"
    "$BASE_DIR/docs/services/activedirectory/Directory-Services-Configurat.md"
    "$BASE_DIR/docs/services/index.md"
    "$BASE_DIR/index.md"
)

# Process each file
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        fix_directory_links "$file"
    else
        echo "Warning: File not found: $file"
    fi
done

echo "Fixed directory links in all specified Markdown files"
