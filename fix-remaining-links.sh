#!/bin/bash

# This script fixes all the remaining directory-level links in the documentation
# by reformatting the links to match DocFX's expected format

# Base directory
BASE_DIR="/home/hades/Documents/repos/josephstreeter.github.io"

# List of files with known InvalidFileLink warnings
declare -a FILES=(
  "$BASE_DIR/docs/development/index.md"
  "$BASE_DIR/docs/infrastructure/containers/index.md"
  "$BASE_DIR/docs/infrastructure/index.md"
  "$BASE_DIR/docs/introduction.md"
  "$BASE_DIR/docs/misc/index.md"
  "$BASE_DIR/docs/networking/index.md"
  "$BASE_DIR/docs/security/index.md"
  "$BASE_DIR/docs/services/index.md"
  "$BASE_DIR/index.md"
)

# Function to fix directory-level links in a file
fix_directory_links() {
  local file="$1"
  
  echo "Processing file: $file"
  
  # Create a backup of the original file
  if [ ! -f "${file}.original" ]; then
    cp "$file" "${file}.original"
  fi
  
  # Replace links of the form (~/docs/dir/) with (~/docs/dir/index.md)
  sed -i 's|(~/docs/\([^)]*\)/)|(\1/index.md)|g' "$file"
  
  # Fix specific link formats found in warnings
  sed -i 's|(~/docs/\([^)]*\))|(\1)|g' "$file"
  
  echo "Fixed links in: $file"
}

# Process each file
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    fix_directory_links "$file"
  else
    echo "Warning: File not found: $file"
  fi
done

echo "Link fixes completed!"
