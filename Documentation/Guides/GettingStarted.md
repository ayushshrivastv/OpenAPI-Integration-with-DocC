# Getting Started with OpenAPI-DocC Integration

## Installation

### Using Swift Package Manager
Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/OpenAPI-DocC-Integration.git", from: "1.0.0")
]
```

### Manual Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/OpenAPI-DocC-Integration.git
```
2. Build the package:
```bash
swift build
```

## Basic Usage

### Command Line Interface
The simplest way to use the tool is through the command line:

```bash
openapi-to-symbolgraph path/to/your/openapi.yaml
```

This will generate a DocC-compatible symbol graph file.

### Programmatic Usage
You can also use the library programmatically:

```swift
import OpenAPIDocC

let converter = OpenAPIDocCConverter()
let symbolGraph = try converter.convert(openAPIFile: "path/to/your/openapi.yaml")
```

## Configuration

### Basic Configuration
Create a `config.json` file in your project root:

```json
{
    "outputPath": "docs",
    "template": "default",
    "includeExamples": true
}
```

### Advanced Configuration
See [Advanced Topics](AdvancedTopics.md) for more configuration options.

## Next Steps
- Try the [Basic Tutorial](Tutorial1.md)
- Explore [Advanced Features](AdvancedTopics.md)
- Check the [API Reference](APIReference.md) 
