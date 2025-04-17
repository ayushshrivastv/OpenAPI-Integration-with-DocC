#!/bin/bash
# Script to fix absolute paths in generated DocC HTML files

echo "Fixing absolute paths in HTML files..."

# Find all HTML files
find docs -name "*.html" | while read file; do
    echo "Processing $file"
    # Replace absolute paths with relative ones
    sed -i '' 's|href="/|href="../../../|g' "$file"
    sed -i '' 's|src="/|src="../../../|g' "$file"
    sed -i '' 's|baseUrl = "/"|baseUrl = "../../../"|g' "$file"
done

echo "Path fixing completed. Documentation should now work with both local serving and GitHub Pages." 
