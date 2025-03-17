# OpenAPI Integration with DocC

This project aims to create a tool that automatically converts OpenAPI specifications into Swift-DocC compatible documentation. By bridging OpenAPI and Swift-DocC through SymbolGraph files, we'll enable seamless documentation generation for REST APIs within the Swift ecosystem.

I’m currently working on the Google Summer of Code @Swift project to integrate OpenAPI Integration with Swift-DocC: Automated API Documentation Generation.

## Technical Details
Problem Statement
Currently, Swift developers maintaining REST APIs need to manually document their APIs in DocC while separately maintaining OpenAPI specifications. This creates duplicate work and potential inconsistencies between API specifications and documentation.

## Proposed Solution
Create a command-line tool that:
Parses OpenAPI specifications (JSON/YAML)
Converts API endpoints and schemas into DocC-compatible SymbolGraph files
Generates comprehensive API documentation using Swift-DocC

## Architecture
OpenAPI Spec → Parser → Intermediate Representation → SymbolGraph Generator → DocC Integration

## Features

- Parses OpenAPI JSON/YAML specifications
- Generates DocC-compatible SymbolGraph files
- Creates documentation structure for API endpoints and schemas

## Installation

```bash
git clone https://github.com/yourusername/OpenAPI-integration-with-DocC.git
cd OpenAPI-integration-with-DocC
swift build
```

## Usage

```bash
swift run openapi-to-symbolgraph path/to/openapi.json
```

This will generate a `symbolgraph.json` file that can be used with DocC for documentation generation.

## Project Structure

- `Sources/`: Contains the main Swift source code
- `test/`: Contains test files and sample OpenAPI specifications
- `API.docc/`: Contains DocC documentation catalog

## Requirements

- Swift 5.7+
- macOS 11.0+

## Dependencies

- [OpenAPIKit](https://github.com/mattpolzin/OpenAPIKit.git)
- [Swift DocC SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit.git)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
