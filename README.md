# OpenAPI Integration with DocC

The project aims to bridge the gap between OpenAPI specifications and Swift's DocC documentation framework by developing a tool that automates the generation of DocC documentation from OpenAPI files.

## Overview

OpenAPI is the industry standard for documenting HTTP services, but Swift developers are already familiar with DocC for their Swift and Objective-C API documentation. This project bridges that gap by converting OpenAPI specifications into a format that DocC can understand and render.

![2048](https://github.com/user-attachments/assets/f9a751be-9d2f-43f0-8346-04af7edaea57)

## Project Structure

The project is organized into several modules:

- `Sources/Core` - Core functionality and data models
- `Sources/CLI` - Command-line interface
- `Sources/OpenAPItoSymbolGraph` - Main implementation with submodules:
  - `Mapping` - Mappers between OpenAPI and SymbolGraph
  - `Utils/DocC` - DocC integration utilities
- `Sources/SymbolGraphDebug` - Debugging tools for symbol graphs (see [Symbol Graph Debug Tool](#symbol-graph-debug-tool))

## Key Features

- Convert OpenAPI 3.1.0 specifications to DocC compatible format
- Generate API documentation
- Provide a consistent documentation experience for Swift developers
- Support for documenting endpoints, schemas, parameters, and more
- Debug and analyze symbol graphs for troubleshooting

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- Swift 6.0 or later
- Python 3 (for local documentation serving)

### Installation

```bash
git clone https://github.com/ayushshrivastv/OpenAPI-integration-with-DocC.git
cd OpenAPI-integration-with-DocC
swift build
```

### Usage

1. Convert your OpenAPI specification to a SymbolGraph:

```bash
swift run openapi-to-symbolgraph Examples/api.yaml --output-path api.symbolgraph.json
```

2. Generate the documentation using our helper script:

```bash
./scripts/build-docs.sh
```

Or manually with DocC:

```bash
xcrun docc convert YourAPI.docc --fallback-display-name YourAPI --fallback-bundle-identifier com.example.YourAPI --fallback-bundle-version 1.0.0 --additional-symbol-graph-dir ./ --output-path ./docs
```

## Symbol Graph Debug Tool

This project includes a specialized debugging tool for analyzing and troubleshooting DocC symbol graphs, particularly those generated from OpenAPI specifications.

### Debug Tool Features

- Analyze symbol graph structure and relationships
- Validate relationships between symbols
- Detect common issues like missing source/target symbols or invalid path hierarchies
- Debug OpenAPI-specific conversion issues
- Analyze HTTP endpoints and associated metadata
- Combine and analyze multiple symbol graph files

### Using the Debug Tool

```bash
# Basic analysis of a symbol graph
swift run symbol-graph-debug analyze registry.symbolgraph.json

# Debug OpenAPI-specific conversion issues
swift run symbol-graph-debug openapi-debug registry.symbolgraph.json

# Analyze a directory of symbol graphs
swift run symbol-graph-debug unified .build/symbolgraphs/ -o combined-analysis.json
```

For more information, see the [Symbol Graph Debug Tool README](Sources/SymbolGraphDebug/README.md).

## Viewing the Documentation

The `docs/` directory in this repository contains the pre-generated DocC documentation website output for the **Swift Package Registry API**, which was built using the `registry.symbolgraph.json` generated by this tool and the `RegistryAPI.docc` catalog.

### Documentation

The latest documentation is automatically deployed to GitHub Pages and can be viewed at:

[https://ayushshrivastv.github.io/OpenAPI-Integration-with-DocC/](https://ayushshrivastv.github.io/OpenAPI-Integration-with-DocC/)

### Local Documentation Server

You can serve the documentation locally using one of these methods:

#### Using the local preview script (recommended):

```bash
./scripts/local-preview.sh
```

This script serves the documentation directory and opens it in your browser. You will be automatically redirected to the API documentation.

#### Using the server script:

```bash
./scripts/serve-docs.sh
```

#### Using Python 3 directly:

```bash
python3 -m http.server 8000 --directory docs
```

Then open your browser to http://localhost:8000

## Example

Check out the `DocsExample` directory for a working example of a REST API documented with DocC. It showcases how endpoints, schemas, and examples appear in the DocC format.

## How It Works

1. The OpenAPI specification is parsed using `OpenAPIKit`
2. The specification is converted to a SymbolGraph, which is the format DocC uses for documentation
3. DocC processes the SymbolGraph and generates the documentation
4. The documentation can be served as a static website or deployed to GitHub Pages

## GitHub Pages Deployment

This repository is configured to automatically deploy documentation to GitHub Pages whenever changes are pushed to the main branch. The deployment process:

1. Uses the GitHub Actions workflow defined in `.github/workflows/pages.yml`
2. Builds the documentation from the OpenAPI specification
3. Takes the contents of the `docs` directory
4. Deploys them to GitHub Pages
5. Makes the documentation available at the URL: [https://ayushshrivastv.github.io/OpenAPI-Integration-with-DocC/](https://ayushshrivastv.github.io/OpenAPI-Integration-with-DocC/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
