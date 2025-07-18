#!/bin/bash

# This script fixes all the links to include index.md in the path
# It specifically targets the remaining link issues in DocFX warnings

# Base directory
BASE_DIR="/home/hades/Documents/repos/josephstreeter.github.io"

# Process a single file
process_file() {
    local file="$1"
    echo "Processing file: $file"
    
    # Create backup if it doesn't exist
    if [ ! -f "${file}.original" ]; then
        cp "$file" "${file}.original"
    fi
    
    # Fix links of the format: [Text](dir/) -> [Text](dir/index.md)
    sed -i 's|\(\[[^]]*\]\)(\([^)]*\)/)|\1(\2/index.md)|g' "$file"
    
    # Fix links with tilde format: [Text](~/docs/dir/) -> [Text](~/docs/dir/index.md)
    sed -i 's|\(\[[^]]*\]\)(~/docs/\([^)]*\)/)|\1(~/docs/\2/index.md)|g' "$file"
    
    echo "Completed processing: $file"
}

# Find and process all markdown files
echo "Searching for Markdown files..."
find "$BASE_DIR" -name "*.md" | while read -r file; do
    process_file "$file"
done

echo "Link fixing completed!"
