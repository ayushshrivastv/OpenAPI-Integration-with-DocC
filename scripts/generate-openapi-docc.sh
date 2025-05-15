#!/bin/bash
# Script to generate DocC documentation from an OpenAPI file

set -e

# Display help information
show_help() {
    echo "Usage: $0 [options] <openapi-file>"
    echo ""
    echo "Options:"
    echo "  -o, --output-dir DIR      Output directory for DocC catalog (default: current directory)"
    echo "  -m, --module-name NAME    Module name to use (default: derived from API title)"
    echo "  -b, --base-url URL        Base URL for API endpoints"
    echo "  -f, --force               Overwrite existing files"
    echo "  -e, --no-examples         Do not include examples in the documentation"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 specs/petstore.yaml"
    echo "  $0 --module-name PetStoreAPI --base-url https://petstore.swagger.io/v2 specs/petstore.yaml"
    echo ""
}

# Parse command line arguments
OUTPUT_DIR="."
MODULE_NAME=""
BASE_URL=""
FORCE=false
INCLUDE_EXAMPLES=true

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift
            shift
            ;;
        -m|--module-name)
            MODULE_NAME="$2"
            shift
            shift
            ;;
        -b|--base-url)
            BASE_URL="$2"
            shift
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -e|--no-examples)
            INCLUDE_EXAMPLES=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # Last argument should be the OpenAPI file
            OPENAPI_FILE="$1"
            shift
            ;;
    esac
done

# Check if the OpenAPI file is provided
if [ -z "$OPENAPI_FILE" ]; then
    echo "Error: OpenAPI file not specified"
    show_help
    exit 1
fi

# Check if the OpenAPI file exists
if [ ! -f "$OPENAPI_FILE" ]; then
    echo "Error: OpenAPI file '$OPENAPI_FILE' does not exist"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build the options string
OPTIONS=""
if [ ! -z "$MODULE_NAME" ]; then
    OPTIONS="$OPTIONS --module-name \"$MODULE_NAME\""
fi

if [ ! -z "$BASE_URL" ]; then
    OPTIONS="$OPTIONS --base-url \"$BASE_URL\""
fi

if [ "$FORCE" = true ]; then
    OPTIONS="$OPTIONS --overwrite"
fi

if [ "$INCLUDE_EXAMPLES" = false ]; then
    OPTIONS="$OPTIONS --no-include-examples"
fi

# Run the openapi-tool to-docc command
echo "Generating DocC catalog from $OPENAPI_FILE..."
eval "swift run openapi-tool to-docc $OPTIONS --output-directory \"$OUTPUT_DIR\" \"$OPENAPI_FILE\""

# Get the catalog name based on the output of the previous command
CATALOG_NAME=$(basename "$OPENAPI_FILE" | sed 's/\.[^.]*$//')
if [ ! -z "$MODULE_NAME" ]; then
    CATALOG_NAME="$MODULE_NAME"
fi
CATALOG_NAME="${CATALOG_NAME}.docc"
CATALOG_PATH="$OUTPUT_DIR/$CATALOG_NAME"

# Verify that the catalog was created
if [ ! -d "$CATALOG_PATH" ]; then
    echo "Error: Failed to create DocC catalog at $CATALOG_PATH"
    exit 1
fi

# Use DocC to convert the catalog to documentation
echo "Converting DocC catalog to documentation..."
DOCS_OUTPUT="$OUTPUT_DIR/docs"
mkdir -p "$DOCS_OUTPUT"

xcrun docc convert "$CATALOG_PATH" \
    --fallback-display-name "${MODULE_NAME:-$CATALOG_NAME}" \
    --fallback-bundle-identifier "com.example.${MODULE_NAME:-$CATALOG_NAME}" \
    --fallback-bundle-version "1.0.0" \
    --additional-symbol-graph-dir "$OUTPUT_DIR" \
    --output-path "$DOCS_OUTPUT"

# Check if the documentation was generated
if [ ! -d "$DOCS_OUTPUT" ]; then
    echo "Error: Failed to generate documentation at $DOCS_OUTPUT"
    exit 1
fi

echo "✅ Successfully generated documentation at $DOCS_OUTPUT"
echo ""
echo "To preview the documentation, run:"
echo "  python3 -m http.server 8000 --directory \"$DOCS_OUTPUT\""
echo "Then open your browser to http://localhost:8000"
