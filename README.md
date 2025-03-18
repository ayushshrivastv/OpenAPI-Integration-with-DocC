# OpenAPI Integration with DocC

This project aims to create a tool that automatically converts OpenAPI specifications into Swift-DocC compatible documentation. By bridging OpenAPI and Swift-DocC through SymbolGraph files, we'll enable seamless documentation generation for REST APIs within the Swift ecosystem.

The project is still in its very early stage, and I’m actively working on improving it.

Google Summer of Code @Swift project to integrate OpenAPI Integration with Swift-DocC: Automated API Documentation Generation.

## Technical Details
**Problem Statement**


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

### Prerequisites
- Xcode 14.0 or later
- Swift 5.7+
- macOS 11.0+

### Steps

1. Clone the repository:
```bash
git clone https://github.com/yourusername/OpenAPI-integration-with-DocC.git
```

2. Navigate to the project directory:
```bash
cd OpenAPI-integration-with-DocC
```

3. Build the project:
```bash
swift build
```

4. (Optional) Run tests:
```bash
swift test
```
### Converting to DocC

1. Generate the SymbolGraph file:
```bash
swift run openapi-to-symbolgraph test/sample-api.json --output
```

2. Convert to DocC documentation:
```bash
swift run docc convert symbols/symbolgraph.json --output-path ./docs
```

![2e8f1a628c69dcaafc08ad6f8bad785ceae2cc02_2_1380x300](https://github.com/user-attachments/assets/5649425f-6b4c-4417-9f3e-342edbabc4ae)


### Examples

#### Basic Usage
```bash
# Convert a simple API specification
swift run openapi-to-symbolgraph api.json --output ./symbols
```


![Screenshot 2025-03-17 at 1 57 27 PM](https://github.com/user-attachments/assets/dbb60011-201a-4b72-bbdb-d9b91e11489f)


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
