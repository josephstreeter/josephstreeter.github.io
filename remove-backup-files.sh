#!/bin/bash

# Script to remove all .bk, .bak, and .original files
echo "Removing backup files..."

# Find and remove .bk, .bak, and .original files
find . -type f \( -name "*.bk" -o -name "*.bak" -o -name "*.original" \) -print -delete

echo "Backup files removed."
