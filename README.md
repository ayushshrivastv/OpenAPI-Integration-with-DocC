# OpenAPI Integration with DocC

The project aims to bridge the gap between OpenAPI specifications and Swift's DocC documentation framework by developing a tool that automates the generation of DocC documentation from OpenAPI files.

![Screenshot 2025-04-20 at 8 42 01 PM](https://github.com/user-attachments/assets/453e95be-141e-422b-b53d-67834d3413aa)

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
- Automatically generate DocC catalogs (.docc) from OpenAPI specifications

## Getting Started

### Prerequisites

- Xcode 15.0 or later (macOS) or Swift 5.9+ (all platforms)
- Git (for cloning the repository)
- Python 3 (for local documentation serving)
- Internet connection (for downloading dependencies)

### Installation

First, make sure you have Swift installed. If not, you can use our installation script:

```bash
# Clone the repository
git clone https://github.com/ayushshrivastv/OpenAPI-integration-with-DocC.git
cd OpenAPI-integration-with-DocC

# Install Swift (if needed)
./scripts/install-swift.sh

# Build the project
swift build
```

For detailed installation instructions and troubleshooting, see:
- [BUILD.md](BUILD.md) - Complete build instructions for all platforms
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Solutions for common issues

### Usage

This tool provides multiple ways to work with OpenAPI and DocC:

#### Option 1: Quick Start with All-in-One Script

For the easiest experience, use our all-in-one script to generate DocC documentation from an OpenAPI specification:

```bash
./scripts/generate-openapi-docc.sh path/to/your/api.yaml
```

This script:
1. Generates a DocC catalog from your OpenAPI specification
2. Runs the DocC compiler to generate HTML documentation
3. Gives you instructions for viewing the documentation

Advanced options:

```bash
./scripts/generate-openapi-docc.sh --module-name YourAPIName --base-url https://api.example.com path/to/your/api.yaml
```

Run with `--help` to see all available options.

#### Option 2: Step-by-Step Process

If you prefer more control, you can use the individual commands:

1. Convert your OpenAPI specification to a DocC catalog:

```bash
swift run openapi-tool to-docc path/to/your/api.yaml --output-directory ./output
```

2. Generate the documentation using DocC:

```bash
xcrun docc convert output/YourAPI.docc --fallback-display-name YourAPI --fallback-bundle-identifier com.example.YourAPI --fallback-bundle-version 1.0.0 --output-path ./docs
```

#### Option 3: SymbolGraph Generation Only

If you only need the SymbolGraph file (for use with other tools):

```bash
swift run openapi-tool to-symbolgraph path/to/your/api.yaml --output-path api.symbolgraph.json
```

## Generated Documentation Structure

The tool generates a DocC catalog with the following structure:

```
YourAPI.docc/
├── YourAPI.md                  # Root documentation file
├── YourAPI.symbols.json        # Symbol graph file
├── Endpoints/                  # Documentation for each API endpoint
│   ├── endpointA.md
│   ├── endpointB.md
│   └── ...
└── Schemas/                    # Documentation for data models
    ├── SchemaA.md
    ├── SchemaB.md
    └── ...
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
3. A DocC catalog (.docc) is generated with Markdown files for each endpoint and schema
4. DocC processes the catalog and generates the documentation
5. The documentation can be served as a static website or deployed to GitHub Pages

## Integration with Swift OpenAPI Generator (Stretch Goal)

We're working on integrating this tool with [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator) to automatically generate documentation during code generation.

## VS Code Extension for Live Preview (Stretch Goal)

We're developing a Visual Studio Code extension that will:
1. Watch for changes to OpenAPI files
2. Automatically convert them to DocC documentation
3. Provide a live preview of the documentation in VS Code

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
