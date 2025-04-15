# OpenAPI Integration with DocC

This project provides tools and examples for integrating OpenAPI specifications with Apple's DocC documentation system. It allows developers to create beautiful, interactive documentation for REST APIs that matches the style and quality of Swift API documentation.

## Overview

OpenAPI is the industry standard for documenting HTTP services, but Swift developers are already familiar with DocC for their Swift and Objective-C API documentation. This project bridges that gap by converting OpenAPI specifications into a format that DocC can understand and render.

## Key Features

- Convert OpenAPI 3.1.0 specifications to DocC-compatible format
- Generate beautiful API documentation
- Provide a consistent documentation experience for Swift developers
- Support for documenting endpoints, schemas, parameters, and more

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
swift run openapi-to-symbolgraph path/to/your/api.yaml --output-path api.symbolgraph.json
```

2. Create a DocC documentation catalog (see `API.docc` as an example)

3. Generate the documentation:

```bash
xcrun docc convert YourAPI.docc --fallback-display-name YourAPI --fallback-bundle-identifier com.example.YourAPI --fallback-bundle-version 1.0.0 --additional-symbol-graph-dir ./ --output-path ./docs
```

## Viewing the Documentation

### Online Documentation

The latest documentation is automatically deployed to GitHub Pages and can be viewed at:

[https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/](https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/)

### Local Documentation Server

You can serve the documentation locally using one of these methods:

#### Using the helper script:

```bash
./serve-docs.sh
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
2. Takes the contents of the `docs` directory
3. Deploys them to GitHub Pages
4. Makes the documentation available at the URL: [https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/](https://ayushshrivastv.github.io/OpenAPI-integration-with-DocC/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
