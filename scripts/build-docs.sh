#!/bin/bash
# Script to generate API documentation

# Create output directory if it doesn't exist
mkdir -p docs

# Convert OpenAPI specification to symbol graph
echo "Converting OpenAPI spec to SymbolGraph..."
swift run openapi-to-symbolgraph registry.openapi.yaml --output-path registry.symbolgraph.json --module-name "RegistryAPI" --base-url "https://api.example.com"

# Generate DocC documentation
echo "Generating DocC documentation..."
xcrun docc convert RegistryAPI.docc \
    --fallback-display-name "Registry API" \
    --fallback-bundle-identifier com.example.RegistryAPI \
    --fallback-bundle-version 1.0.0 \
    --additional-symbol-graph-dir ./ \
    --output-path ./docs

# Create a root index.html to redirect to the API docs
cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=documentation/registryapi/">
    <title>Redirecting to API Documentation</title>
</head>
<body>
    <p>If you are not redirected automatically, <a href="documentation/registryapi/">click here</a>.</p>
</body>
</html>
EOF

# Fix paths in generated HTML files
chmod +x scripts/fix-paths.sh
./scripts/fix-paths.sh

# Make sure .nojekyll file exists
touch docs/.nojekyll

echo "Documentation generated successfully in ./docs directory"
echo "You can preview it using: ./scripts/local-preview.sh" 
