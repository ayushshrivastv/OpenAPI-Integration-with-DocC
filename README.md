# OpenAPI Integration with DocC

This project provides tools and examples for integrating OpenAPI specifications with Apple's DocC documentation system. It allows developers to create beautiful, interactive documentation for REST APIs that matches the style and quality of Swift API documentation.

## Overview

OpenAPI is the industry standard for documenting HTTP services, but Swift developers are already familiar with DocC for their Swift and Objective-C API documentation. This project bridges that gap by converting OpenAPI specifications into a format that DocC can understand and render.

## Key Features

- Convert OpenAPI 3.x specifications to DocC-compatible format
- Generate beautiful API documentation
- Provide a consistent documentation experience for Swift developers
- Support for documenting endpoints, schemas, parameters, and more

## Project Structure

The project is organized into several modules:

- `Sources/OpenAPI` - Core functionality for parsing OpenAPI specifications.
- `Sources/OpenAPItoSymbolGraph` - Main implementation for converting OpenAPI models to SymbolGraph.
- `Sources/Integration` - Integration points, potentially including the CLI tool.
- `Sources/openapi-to-symbolgraph` - The command-line executable target.
- `Tests/OpenAPItoSymbolGraphTests` - Unit and integration tests.

## Getting Started

### Prerequisites

- Xcode 15.0 or later (requires Swift 5.9+ for DocC support)
- Swift command-line tools configured (`xcrun`)

### Installation

```bash
git clone https://github.com/ayushshrivastv/OpenAPI-integration-with-DocC.git
cd OpenAPI-integration-with-DocC
swift build
```

### Usage Steps

1.  **Obtain your OpenAPI Specification:** Ensure you have your API specification in a `.yaml`, `.yml`, or `.json` file (OpenAPI v3.x format).
2.  **Generate SymbolGraph:** Run the command-line tool, providing the path to your OpenAPI file.

    ```bash
    swift run openapi-to-symbolgraph <path_to_your_openapi_spec> --output-path <desired_symbolgraph_name>.symbolgraph.json
    ```

3.  **Prepare SymbolGraph Directory:** Move the generated `.symbolgraph.json` file into a dedicated directory (e.g., `symbolgraphs`).

    ```bash
    mkdir symbolgraphs
    mv <desired_symbolgraph_name>.symbolgraph.json symbolgraphs/
    ```

4.  **Create a DocC Catalog:** Create a basic documentation catalog directory (e.g., `MyAPI.docc`). This needs at least one markdown file to serve as the root landing page.

    ```bash
    mkdir MyAPI.docc
    # Create a root file, e.g., MyAPI.docc/MyAPI.md
    echo "# MyAPI\\n\\nAPI Documentation landing page." > MyAPI.docc/MyAPI.md
    ```

5.  **Generate DocC Archive:** Use `xcrun docc convert` to combine your catalog and symbol graph into a `.doccarchive`.

    ```bash
    xcrun docc convert MyAPI.docc --additional-symbol-graph-dir symbolgraphs --output-path MyAPI.doccarchive
    ```

6.  **View Documentation:** Open the generated `MyAPI.doccarchive` file in Xcode, or host it on a web server.

### Example: Swift Package Registry API

This example demonstrates generating documentation for the official Swift Package Registry API.

1.  **Download the Spec:**

    ```bash
    # Create a directory for test resources if it doesn't exist
    mkdir -p Tests/OpenAPItoSymbolGraphTests/Resources

    # Download the registry spec
    curl -o Tests/OpenAPItoSymbolGraphTests/Resources/registry.openapi.yaml https://raw.githubusercontent.com/swiftlang/swift-package-manager/main/Documentation/PackageRegistry/registry.openapi.yaml
    ```

2.  **Generate SymbolGraph:**

    ```bash
    swift run openapi-to-symbolgraph Tests/OpenAPItoSymbolGraphTests/Resources/registry.openapi.yaml --output-path registry.symbolgraph.json
    ```

3.  **Prepare Directory:**

    ```bash
    mkdir -p symbolgraphs # Ensure directory exists
    mv registry.symbolgraph.json symbolgraphs/
    ```

4.  **Create Catalog:** (We created `RegistryAPI.docc` earlier)

    ```bash
    # Ensure the catalog exists and has a root file
    mkdir -p RegistryAPI.docc
    echo "# RegistryAPI\\n\\nSwift Package Registry API documentation." > RegistryAPI.docc/RegistryAPI.md
    ```

5.  **Generate Archive:**

    ```bash
    xcrun docc convert RegistryAPI.docc --additional-symbol-graph-dir symbolgraphs --output-path RegistryAPI.doccarchive
    ```

    This creates `RegistryAPI.doccarchive`, which contains the generated documentation for the Swift Package Registry API.

## Viewing the Documentation

You can view generated `.doccarchive` files in Xcode or host them online.

### Example Pet Store Documentation (Pre-built)

The `docs/` directory in this repository contains pre-generated DocC website output for the **Swagger Pet Store API**. This was built using `Examples/petstore.yaml` and an example `API.docc` catalog.

**View Online:** [https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/](https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/)

**Serve Locally:**

```bash
# Serve the pre-built Pet Store docs
python3 -m http.server 8000 --directory docs
```

Then open http://localhost:8000 in your browser.

## Testing

The tool includes a comprehensive test suite (`swift test`) covering parsing, conversion, and command-line arguments, using examples like the Pet Store API and the Swift Package Registry API.

## GitHub Pages Deployment

This repository automatically deploys the pre-built Pet Store documentation from the `docs` directory to GitHub Pages via the `.github/workflows/pages.yml` workflow.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
