# OpenAPI Integration with DocC

An open-source tool for converting OpenAPI specifications into Swift DocC documentation.

## Overview

OpenAPI Integration with DocC is a command-line tool that translates OpenAPI (v2 and v3) specifications in YAML or JSON format into DocC documentation archives. This allows API developers to generate rich, navigable documentation for their web services that can be viewed in Xcode or published to the web.

The tool maps OpenAPI schemas to SymbolKit symbols, making API endpoints and data models accessible through Swift's native documentation system.

## Features

- Convert OpenAPI specifications to DocC documentation archives
- Support for both OpenAPI v2 and v3 formats
- Convert REST API endpoints to navigable API references
- Generate documentation for data models/schemas
- Support for examples, descriptions, and other OpenAPI metadata
- Fully compatible with Swift's DocC documentation system

## Installation

### Via Swift Package Manager

Add the package dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git", from: "1.0.0")
]
```

### Building from Source

To build from source, clone the repository and run the Swift build command:

```bash
git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git
cd OpenAPI-Integration-with-DocC
swift build -c release
```

## Quick Start

To convert an OpenAPI specification to a DocC archive:

```bash
swift run openapi-to-symbolgraph /path/to/your/openapi.yaml --output /path/to/output
```

This will generate a DocC catalog that can be processed by DocC.

## Documentation

- [Getting Started Guide](Documentation/Guides/GettingStarted.md)
- [API Reference](Documentation/Reference/APIReference.md)
- [Tutorials](Documentation/Tutorials/OpenAPItoDocCTutorial.md)
- [Advanced Topics](Documentation/Guides/AdvancedTopics.md)

## Examples

Check out example DocC catalogs generated from common OpenAPI specifications:

- [PetStore API Example](Examples/PetStoreAPI)
- [Registry API Example](Examples/RegistryAPI)

## Project Structure

The project is organized into several key components:

- **CLI**: Command-line interface for the tool
- **Core**: Core mapping and conversion functionality
- **OpenAPI**: OpenAPI parsing and representation
- **OpenAPItoSymbolGraph**: Conversion from OpenAPI to SymbolKit symbols
- **SymbolGraphDebug**: Debugging utilities for SymbolGraph output

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
