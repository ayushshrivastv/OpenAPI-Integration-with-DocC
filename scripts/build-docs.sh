#!/bin/bash
# Script to convert an OpenAPI specification to DocC documentation

# Path to the OpenAPI specification file
OPENAPI_SPEC="registry.openapi.yaml"
# Output directory for the DocC documentation
DOCC_OUTPUT_DIR="docs"
# Symbol graph output directory
SYMBOL_GRAPH_DIR="./symbolgraphs"

# Create output directories if they don't exist
mkdir -p $DOCC_OUTPUT_DIR
mkdir -p $SYMBOL_GRAPH_DIR

echo "Converting OpenAPI spec to SymbolGraph..."
# Run the OpenAPI to SymbolGraph converter
swift run openapi-to-symbolgraph $OPENAPI_SPEC --output $SYMBOL_GRAPH_DIR --module-name "RegistryAPI" --base-url "https://api.example.com"

echo "Generating DocC documentation..."
# Generate DocC documentation
xcrun docc convert RegistryAPI.docc \
    --fallback-display-name "Registry API" \
    --fallback-bundle-identifier com.example.RegistryAPI \
    --fallback-bundle-version 1.0.0 \
    --additional-symbol-graph-dir $SYMBOL_GRAPH_DIR \
    --output-path $DOCC_OUTPUT_DIR

# Create a root index.html to redirect to the API docs
cat > $DOCC_OUTPUT_DIR/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=./documentation/registryapi/">
    <title>Redirecting to API Documentation</title>
</head>
<body>
    <p>If you are not redirected automatically, <a href="./documentation/registryapi/">click here</a>.</p>
</body>
</html>
EOF

# Fix paths in generated HTML files
./scripts/fix-paths.sh

# Make sure .nojekyll file exists
touch $DOCC_OUTPUT_DIR/.nojekyll

echo "Documentation generated successfully in $DOCC_OUTPUT_DIR directory"
echo "You can preview it using: ./scripts/local-preview.sh" 
