# OpenAPI Integration with DocC Example

This example demonstrates how to document a REST API using DocC, Apple's Documentation Compiler.

## Overview

The example showcases:
1. Converting OpenAPI specifications to Swift DocC compatible documentation
2. Generating developer-friendly API documentation
3. Creating a consistent experience between Swift API docs and REST API docs

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- Swift 6.0 or later

### Running the Example

1. Clone this repository:
   ```bash
   git clone https://github.com/ayushshrivastv/OpenAPI-integration-with-DocC.git
   cd OpenAPI-integration-with-DocC
   ```

2. Build the tool:
   ```bash
   swift build
   ```

3. Convert an OpenAPI specification to a SymbolGraph:
   ```bash
   swift run openapi-to-symbolgraph api.yaml --output-path api.symbolgraph.json
   ```

4. Generate DocC documentation:
   ```bash
   xcrun docc convert API.docc --fallback-display-name API --fallback-bundle-identifier com.example.API --fallback-bundle-version 1.0.0 --additional-symbol-graph-dir ./ --output-path ./docs
   ```

5. View the documentation:
   ```bash
   python -m http.server 8000 --directory docs
   ```
   
   Then open your browser to http://localhost:8000

## Example Documentation

For a quick preview, you can view the `index.html` file in this directory, which shows a sample of what the generated documentation looks like.

## Structure

- `api.yaml`: Sample OpenAPI specification
- `API.docc`: DocC documentation catalog
- `Sources`: Implementation of the OpenAPI to SymbolGraph converter
- `DocsExample`: Example of the generated documentation

## How It Works

1. The OpenAPI specification is parsed and converted to a SymbolGraph JSON format
2. DocC uses the SymbolGraph to generate documentation
3. The documentation is served as a static website

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
