# Getting Started with OpenAPI Integration for DocC

This guide will help you get up and running with the OpenAPI Integration with DocC tool, from installation to generating your first DocC documentation from an OpenAPI specification.

## Prerequisites

Before you begin, ensure you have:

- Swift 5.7 or later
- An OpenAPI specification file (JSON or YAML format)
- Basic familiarity with command-line tools

## Installation

### Option 1: Swift Package Manager Dependency

If you want to integrate the tool into your own Swift package or application, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git", from: "1.0.0")
]
```

Then, add it as a dependency to your targets:

```swift
.target(
    name: "YourTargetName",
    dependencies: [
        .product(name: "OpenAPItoSymbolGraph", package: "openapi-integration-with-docc")
    ]
)
```

### Option 2: Command-Line Tool Installation

To install the command-line tool:

1. Clone the repository:
   ```bash
   git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git
   ```

2. Build and install the tool:
   ```bash
   cd OpenAPI-Integration-with-DocC
   swift build -c release
   cp -f .build/release/openapi-to-symbolgraph /usr/local/bin/openapi-to-symbolgraph
   ```

## Basic Usage

### Converting an OpenAPI Specification to DocC

The basic command to convert an OpenAPI specification to a DocC documentation archive is:

```bash
openapi-to-symbolgraph /path/to/your-spec.yaml --output /path/to/output-directory
```

This will:
1. Parse your OpenAPI specification
2. Generate a SymbolGraph representation
3. Create a DocC catalog in the specified output directory

### Command-Line Options

The tool supports several command-line options:

- `--module-name <name>`: Set a custom module name (defaults to the spec's title)
- `--base-url <url>`: Specify the base URL for the API
- `--include-examples`: Include examples in the documentation
- `--overwrite`: Overwrite existing output files
- `--verbose`: Enable verbose logging

## Example: Converting the PetStore API

Let's walk through a concrete example using the popular PetStore API:

1. Download the PetStore OpenAPI specification:
   ```bash
   curl -O https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml
   ```

2. Convert it to a DocC archive:
   ```bash
   openapi-to-symbolgraph petstore.yaml --output ./PetStore.docc --module-name PetStore
   ```

3. Generate the DocC documentation:
   ```bash
   swift package --allow-writing-to-directory ./docs \
     generate-documentation --target PetStore \
     --output-path ./docs \
     --transform-for-static-hosting \
     --hosting-base-path /PetStore/
   ```

4. Open the generated documentation:
   ```bash
   open ./docs/index.html
   ```

## What's Next?

Once you've successfully generated your first DocC documentation, you might want to:

- Learn how to customize the documentation generation process
- Integrate this into your CI/CD workflow
- Explore the generated SymbolGraph files

Check out the following guides:
- [Advanced Topics](AdvancedTopics.md) - For more configuration options
- [API Reference](../Reference/APIReference.md) - For programmatic usage
- [Tutorials](../Tutorials/OpenAPItoDocCTutorial.md) - For step-by-step walkthroughs

## Troubleshooting

### Common Issues

#### "Error: Cannot find module 'OpenAPIKit'"

This usually indicates that Swift Package Manager hasn't resolved the dependencies. Try running:

```bash
swift package resolve
```

#### "Error parsing OpenAPI specification"

Check that your OpenAPI specification is valid. You can use online validators like [Swagger Editor](https://editor.swagger.io/) to verify its correctness.

#### "Empty DocC archive generated"

Make sure your OpenAPI specification contains proper schemas and operations. The tool needs these to generate meaningful documentation.

### Getting Help

If you encounter issues not covered here:

- Check the [GitHub Issues](https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC/issues) for similar problems
- File a new issue with detailed information about your problem
- Reach out to the maintainers with specific questions
