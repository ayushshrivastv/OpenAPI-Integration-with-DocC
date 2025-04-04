# OpenAPI Integration with DocC

This project aims to create a tool that automatically converts OpenAPI specifications into Swift-DocC compatible documentation. By bridging OpenAPI and Swift-DocC through SymbolGraph files, we'll enable seamless documentation generation for REST APIs within the Swift ecosystem.

The project is still in its very early stage, and I’m actively working on improving it.

Google Summer of Code @Swift project to integrate OpenAPI Integration with Swift-DocC: Automated API Documentation Generation.

## Technical Details
**Problem Statement**


Currently, Swift developers maintaining REST APIs need to manually document their APIs in DocC while separately maintaining OpenAPI specifications. This creates duplicate work and potential inconsistencies between API specifications and documentation.

## Project Status
The project is in active development, with a working Proof of Concept (PoC) generating DocC documentation. Check out the live example below!

![Screenshot 2025-04-05 at 4 55 57 AM](https://github.com/user-attachments/assets/3b5bfca6-7e6f-42a6-981a-039daeee0538)

## Live Documentation
View the generated DocC documentation for a sample User API at:

[https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/docs](https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/)


![Screenshot 2025-04-05 at 4 57 22 AM](https://github.com/user-attachments/assets/9ee9e418-45da-478e-a15e-80d6605a3d30)
![Screenshot 2025-04-05 at 5 03 39 AM](https://github.com/user-attachments/assets/b590979f-8a44-4a95-a7be-a416166a5305)
![Screenshot 2025-04-05 at 5 07 27 AM](https://github.com/user-attachments/assets/35e1be6d-154e-4ad8-86a0-2724fd742fba)


## Proposed Solution
Command line tool to simplify API documentation for Swift developers. It parses OpenAPI JSON/YAML files using OpenAPIKit Swift Library, transforms schemas and endpoints into DocC ready SymbolGraph files with createSymbolGraph, and outputs “symbolgraph.json.” Users then execute docc convert symbolgraph.json --output-path docs to create HTML docs, enhanced by a static “API.docc/” catalog for custom pages. For GSoC, I’ll extend support for complex schemas like nested objects and arrays, automate DocC conversion, and add live previews, ensuring effortless, consistent API documentation from OpenAPI specs.

`swift run openapi-to-symbolgraph <path-to-openapi.json>`: Runs your tool to parse and generate “symbolgraph.json.”


`docc convert symbolgraph.json --output-path docs`: Converts the SymbolGraph into HTML documentation.

## Benefits to the Swift Ecosystem  Improved 

Consistency: By generating DocC documentation directly from OpenAPI specs, the tool eliminates discrepancies between API definitions and code documentation. 

Reduced Workload: Developers will save a lot of time that they would have spent manually documenting APIs in DocC. This is a problem that I’ve seen mentioned in industry reports, like Chase’s March 2024 Medium post (Using Apple’s OpenAPI Generator to Make and Mock Network Calls in SwiftUI). This tool directly addresses this issue. 


Parses OpenAPI specifications (JSON/YAML)
Converts API endpoints and schemas into DocC-compatible SymbolGraph files
Generates comprehensive API documentation using Swift-DocC

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

## Project Structure

- `Sources/`: Contains the main Swift source code
- `test/`: Contains test files and sample OpenAPI specifications
- `API.docc/`: Contains DocC documentation catalog

## Requirements

- Swift 5.7+
- macOS 11.0+

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

## Dependencies

- [OpenAPIKit](https://github.com/mattpolzin/OpenAPIKit.git)
- [Swift DocC SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit.git)

## Contributing
I welcome feedback and contributions! Please open an issue or pull request on GitHub. For GSoC, I’m collaborating with mentors Sofia Rodríguez, Si Beaumont, and Honza Dvorsky.

## Acknowledgements
Special thanks to the Swift.org community and my GSoC mentors for their guidance.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
