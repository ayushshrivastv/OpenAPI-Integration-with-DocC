# API Documentation Examples

This directory contains example OpenAPI specifications and their corresponding generated SymbolGraph files and DocC archives produced by the `openapi-to-symbolgraph` tool.

## Contents

- **RegistryAPI/**: Contains files related to the Swift Package Registry API.
  - `registry.openapi.yaml`: The original OpenAPI specification.
  - `registry.symbolgraph.json`: The generated SymbolGraph file.
  - `RegistryAPI.doccarchive`: The generated DocC documentation archive.

- **PetStoreAPI/**: Contains files related to the Swagger Pet Store API.
  - `petstore.yaml`: The original OpenAPI specification.
  - `petstore.symbolgraph.json`: The generated SymbolGraph file.
  - `PetStore.doccarchive`: The generated DocC documentation archive.

## Usage

These examples demonstrate the input and output of the conversion process. You can inspect the `.yaml` files as input examples and the `.symbolgraph.json` files to see the intermediate representation used by DocC. The `.doccarchive` files can be opened in Xcode or hosted to view the final rendered documentation.

Refer to the main project `README.md` for instructions on how to run the tool and generate these files yourself.

## Petstore API Example

The Petstore API is a common example used to demonstrate OpenAPI functionality. Here's how to convert it to DocC documentation:

1. First, convert the OpenAPI spec to a symbol graph:

```bash
swift run openapi-to-symbolgraph Examples/petstore.yaml --output-path petstore.symbolgraph.json
```

2. Then, generate the DocC documentation:

```bash
xcrun docc convert PetstoreAPI.docc \
    --fallback-display-name "Petstore API" \
    --fallback-bundle-identifier com.example.PetstoreAPI \
    --fallback-bundle-version 1.0.0 \
    --additional-symbol-graph-dir ./ \
    --output-path ./docs
```

## Directory Structure

```
Examples/
├── README.md
├── petstore.yaml        # OpenAPI specification for the Petstore API
└── PetstoreAPI.docc/   # DocC documentation bundle
    ├── PetstoreAPI.md  # Main documentation page
    └── Resources/      # Additional documentation resources
```

## Generated Documentation

The generated documentation will include:

- API Overview
- Endpoints
  - List pets
  - Create pet
  - Get pet by ID
  - Update pet
  - Delete pet
- Data Types
  - Pet
  - Category
  - Tag
  - Order
  - User

## Customization

You can customize the documentation by:

1. Adding additional markdown files in the `.docc` directory
2. Including custom tutorials and articles
3. Adding images and other resources in the `Resources` directory

## Notes

- Make sure you have the latest version of Xcode installed
- The DocC documentation can be hosted on GitHub Pages or any static web server
- You can preview the documentation using Xcode's documentation viewer 
