# OpenAPI Integration with DocC

This project develops a command line tool, openapi-to-symbolgraph, to automatically convert OpenAPI specifications into Swift-DocC compatible documentation. By generating SymbolGraph files, it bridges REST API specs with the Swift ecosystem, reducing duplicate work and ensuring consistency for Swift developers. This is part of the Google Summer of Code 2025 @Swift project: Automated API Documentation Generation.

## Project Status
The project is in active development, with a working Proof of Concept (PoC) generating DocC documentation. Check out the live example below!

## Live Documentation
View the generated DocC documentation for a sample User API at:

https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/docs

## Technical Details
**Problem Statement**

Swift developers maintaining REST APIs currently face the challenge of manually documenting APIs in DocC while separately maintaining OpenAPI specifications. This leads to duplicate effort and potential inconsistencies.

## Proposed Solution
Command line tool to simplify API documentation for Swift developers. It parses OpenAPI JSON/YAML files using OpenAPIKit Swift Library, transforms schemas and endpoints into DocC ready SymbolGraph files with createSymbolGraph, and outputs “symbolgraph.json.” Users then execute docc convert symbolgraph.json --output-path docs to create HTML docs, enhanced by a static “API.docc/” catalog for custom pages. For GSoC, I’ll extend support for complex schemas like nested objects and arrays, automate DocC conversion, and add live previews, ensuring effortless, consistent API documentation from OpenAPI specs.

`swift run openapi-to-symbolgraph <path-to-openapi.json>`: Runs your tool to parse and generate “symbolgraph.json.”


`docc convert symbolgraph.json --output-path docs`: Converts the SymbolGraph into HTML documentation.

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

## Contributing
I welcome feedback and contributions! Please open an issue or pull request on GitHub. For GSoC, I’m collaborating with mentors Sofia Rodríguez, Si Beaumont, and Honza Dvorsky.

## Acknowledgements
Special thanks to the Swift.org community and my GSoC mentors for their guidance.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
