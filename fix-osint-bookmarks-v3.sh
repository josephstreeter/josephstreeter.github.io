#!/bin/bash

# This script fixes bookmark links in the OSINT index document by adding emoji to match the heading formats
# The file uses emoji in headings which affects the ID generation

# File to modify
file="/home/hades/Documents/repos/josephstreeter.github.io/docs/security/osint/index.md"

# Make a backup of the original file
cp "$file" "${file}.bak"

# Fix the links to include the emoji
sed -i 's/#people--phone-number-lookup/#-people--phone-number-lookup/g' "$file"
sed -i 's/#username--email-enumeration/#-username--email-enumeration/g' "$file"
sed -i 's/#image--location-analysis/#-image--location-analysis/g' "$file"
sed -i 's/#vehicle--vin-lookup/#-vehicle--vin-lookup/g' "$file"
sed -i 's/#metadata-extraction/#-metadata-extraction/g' "$file"
sed -i 's/#breach-data--credential-leaks/#-breach-data--credential-leaks/g' "$file"
sed -i 's/#automation--api-tools/#-automation--api-tools/g' "$file"
sed -i 's/#domain--dns-intelligence/#-domain--dns-intelligence/g' "$file"

echo "Fixed bookmark links in $file"
