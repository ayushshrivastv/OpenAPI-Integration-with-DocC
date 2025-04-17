#!/bin/bash
# Script to generate API documentation

# Create output directory if it doesn't exist
mkdir -p docs

# Convert OpenAPI specification to symbol graph
echo "Converting OpenAPI spec to SymbolGraph..."
swift run openapi-to-symbolgraph registry.openapi.yaml --output-path registry.symbolgraph.json

# Generate DocC documentation
echo "Generating DocC documentation..."
xcrun docc convert RegistryAPI.docc \
    --fallback-display-name "Registry API" \
    --fallback-bundle-identifier com.example.RegistryAPI \
    --fallback-bundle-version 1.0.0 \
    --additional-symbol-graph-dir ./ \
    --output-path ./docs \
    --hosting-base-path OpenAPI-Integration-with-DocC

# Make sure .nojekyll file exists
touch docs/.nojekyll

echo "Documentation generated successfully in ./docs directory"
echo "You can preview it using: ./scripts/serve-docs.sh" 
