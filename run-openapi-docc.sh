#!/bin/bash
# Helper script for running OpenAPI-to-DocC tool and serving documentation locally

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="/tmp/openapi-docs"
PORT=8000

# Print help
function show_help {
    echo "Usage: ./run-openapi-docc.sh [options] <openapi-file>"
    echo ""
    echo "Options:"
    echo "  -o, --output-dir DIR    Set the output directory (default: /tmp/openapi-docs)"
    echo "  -m, --module NAME       Set the module name (default: derives from filename)"
    echo "  -p, --port PORT         Set the HTTP server port (default: 8000)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  ./run-openapi-docc.sh path/to/petstore.yaml"
    echo "  ./run-openapi-docc.sh -m PetStoreAPI -p 8080 path/to/petstore.yaml"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -m|--module)
            MODULE_NAME="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            # First non-option argument is the OpenAPI file
            if [ -z "$OPENAPI_FILE" ]; then
                OPENAPI_FILE="$1"
            else
                echo "Error: Multiple input files specified" >&2
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if an OpenAPI file was provided
if [ -z "$OPENAPI_FILE" ]; then
    echo "Error: No OpenAPI file specified" >&2
    show_help
    exit 1
fi

# Check if the OpenAPI file exists
if [ ! -f "$OPENAPI_FILE" ]; then
    echo "Error: OpenAPI file not found: $OPENAPI_FILE" >&2
    exit 1
fi

# If no module name was provided, derive it from the filename
if [ -z "$MODULE_NAME" ]; then
    # Get the basename without extension and convert to CamelCase
    MODULE_NAME=$(basename "$OPENAPI_FILE" | sed -E 's/\.[^.]+$//' | sed -E 's/(^|_)([a-z])/\U\2/g')API
    echo "No module name provided, using: $MODULE_NAME"
fi

# Ensure the executable is built
echo "Building the OpenAPI-to-DocC tool..."
cd "$SCRIPT_DIR"
swift build

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get the absolute path of the output directory
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
SYMBOLS_FILE="$OUTPUT_DIR/$MODULE_NAME.symbols.json"
DOCC_DIR="$OUTPUT_DIR/$MODULE_NAME.docc"
DOCS_DIR="$OUTPUT_DIR/docs"

# Run the OpenAPI-to-DocC tool
echo "Converting OpenAPI file to symbol graph..."
./.build/debug/openapi-to-symbolgraph "$OPENAPI_FILE" --output "$SYMBOLS_FILE" --module-name "$MODULE_NAME"

# Create a DocC catalog structure
echo "Creating DocC catalog structure..."
mkdir -p "$DOCC_DIR"

# Create the main documentation page
cat > "$DOCC_DIR/$MODULE_NAME.md" << EOF
# ``$MODULE_NAME``

Documentation generated from OpenAPI specification.

## Overview

This documentation was automatically generated from an OpenAPI specification using the OpenAPI-to-DocC tool.

## Topics

### All Endpoints

- <doc:endpoints>
EOF

# Create the endpoints documentation page
cat > "$DOCC_DIR/endpoints.md" << EOF
# API Endpoints

API endpoints available in this service.

## Topics

### Endpoints

EOF

# Create DocC catalog configuration file
cat > "$DOCC_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$MODULE_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$MODULE_NAME Documentation</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$MODULE_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CDDefaultModuleKind</key>
    <string>SwiftFramework</string>
</dict>
</plist>
EOF

# Generate the documentation
echo "Generating documentation from symbol graph..."
mkdir -p "$DOCS_DIR"

xcrun docc convert "$DOCC_DIR" \
    --output-path "$DOCS_DIR" \
    --additional-symbol-graph-dir "$(dirname "$SYMBOLS_FILE")" \
    --fallback-display-name "$MODULE_NAME" \
    --fallback-bundle-identifier "com.example.$MODULE_NAME" \
    --fallback-bundle-version "1.0.0"

# Set up a simple HTTP server to serve the documentation
echo "Starting HTTP server on port $PORT..."
echo "Open your browser and navigate to http://localhost:$PORT/documentation/$(echo "$MODULE_NAME" | tr '[:upper:]' '[:lower:]')/"

cd "$DOCS_DIR"
python -m http.server $PORT
