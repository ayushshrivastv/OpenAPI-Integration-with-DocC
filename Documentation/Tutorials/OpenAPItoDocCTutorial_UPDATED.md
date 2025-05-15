# Tutorial: Generating DocC Documentation from an OpenAPI Specification

This tutorial will guide you through the complete process of converting an OpenAPI specification into a DocC documentation archive. By the end, you'll have created professional-quality API documentation that can be viewed in Xcode or published to the web.

## Introduction

API documentation is essential for developers consuming your services. Swift's DocC documentation system provides rich, interactive documentation experiences. This tutorial shows how to bridge the gap between OpenAPI specifications and DocC documentation.

## Prerequisites

Before you begin, ensure you have:

- macOS Monterey (12.0) or later
- Xcode 14.0 or later
- Swift 5.7 or later
- Basic understanding of OpenAPI specifications
- An OpenAPI specification file (we'll use the PetStore API in this tutorial)

## Step 1: Setting Up Your Environment

First, let's install the OpenAPI Integration with DocC tool:

```bash
# Clone the repository
git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git

# Navigate to the cloned directory
cd OpenAPI-Integration-with-DocC

# Build the tool
swift build -c release

# Make the tool available in your PATH (optional)
cp -f .build/release/openapi-to-symbolgraph /usr/local/bin/openapi-to-symbolgraph
```

## Step 2: Preparing Your OpenAPI Specification

For this tutorial, we'll use the Petstore API, a standard example in the OpenAPI community. If you don't already have it, you can download it:

```bash
curl -o petstore.yaml https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml
```

Take a moment to review this specification in a text editor. This will help you understand how the OpenAPI elements map to the generated documentation.

## Step 3: Generating the SymbolGraph and DocC Catalog

Now, let's convert the OpenAPI specification to a DocC catalog:

```bash
openapi-to-symbolgraph petstore.yaml --output ./PetStore.docc --module-name PetStore
```

This command:
1. Parses the petstore.yaml OpenAPI specification
2. Creates a SymbolGraph representation of the API
3. Generates a DocC catalog in the PetStore.docc directory

Let's examine what's been created:

```bash
ls -l PetStore.docc
```

You should see several files, including:
- PetStore.md - The main module documentation file
- PetStore.symbols.json - The SymbolGraph file for DocC
- Directories for endpoints and schemas

## Step 4: Examining the Generated DocC Catalog

Let's take a look at the generated files to understand how the OpenAPI specification has been transformed:

### 4.1 Module Documentation (PetStore.md)

This file contains the main documentation for your API module, including:
- API title and description from the OpenAPI info object
- Overview of available endpoints
- Links to data models

### 4.2 SymbolGraph File (PetStore.symbols.json)

This JSON file contains the SymbolKit representation of your API. DocC uses this to build the documentation structure, including:
- Symbols for each API endpoint
- Symbols for each data model/schema
- Relationships between symbols (e.g., endpoints that use particular models)

### 4.3 Endpoint Documentation

For each API endpoint in the OpenAPI specification, documentation has been generated with:
- HTTP method and path
- Description and summary from the OpenAPI operation
- Parameters and their descriptions
- Request body schemas
- Response schemas for different status codes
- Security requirements

### 4.4 Schema Documentation

For each schema defined in the components section of the OpenAPI specification, documentation includes:
- Properties and their types
- Required vs. optional fields
- Descriptions from the OpenAPI schema
- References to other schemas that use this schema

## Step 5: Building the DocC Documentation

Now that we have a DocC catalog, we need to process it with DocC to create the final documentation:

### 5.1 Option A: Using Xcode

If you want to view the documentation in Xcode:

1. Create a new Xcode project or open an existing one
2. Copy the PetStore.docc directory into your project
3. Add it to your target
4. Build the project
5. View the documentation in Xcode's documentation window (Product → Build Documentation)

### 5.2 Option B: Generating a Static Website

To create a standalone website for your API documentation:

```bash
# Create a Swift package to host our documentation
mkdir PetStoreDocumentation && cd PetStoreDocumentation
swift package init --type empty

# Copy the DocC catalog into the package
mkdir Sources
cp -R ../PetStore.docc Sources/

# Create a Package.swift file for documentation
cat > Package.swift << EOF
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PetStoreDocumentation",
    products: [
        .library(
            name: "PetStoreDocumentation",
            targets: ["PetStoreDocumentation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "PetStoreDocumentation",
            dependencies: [],
            path: "Sources"),
    ]
)
EOF

# Generate the static website
swift package --allow-writing-to-directory ./docs \
  generate-documentation --target PetStoreDocumentation \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path PetStoreAPI/
```

Now you can view the documentation by opening `./docs/index.html` in your browser.

## Step 6: Customizing the Documentation

The generated documentation is a great starting point, but you might want to customize it further:

### 6.1 Editing the Module Documentation

You can edit the main `PetStore.md` file to add more context, getting started guides, or other information that's not in the OpenAPI specification:

```markdown
# PetStore

The PetStore API enables you to manage pets, orders, and users.

## Overview

This API provides a complete solution for pet store management, including:

- Pet inventory management
- Order processing
- User account management

## Getting Started

To use the PetStore API, you'll need:
1. API credentials
2. Basic understanding of RESTful APIs
3. A tool like curl or Postman for testing

## Authentication

Most endpoints require API key authentication. Include your API key in the `api_key` header.

## Rate Limiting

Please note that the API is rate-limited to 100 requests per minute.

## Topics

### Endpoints

- ``get_pets``
- ``post_pet``
- ``get_pet_id``

### Data Models

- ``Pet``
- ``Order``
- ``User``
```

### 6.2 Adding Custom Examples

You can enhance the generated endpoint and schema documentation with additional examples:

```markdown
# get_pet_id

GET /pet/{petId}

Returns a single pet by ID.

## Examples

### Successful Response

Request:
```http
GET /pet/123 HTTP/1.1
Host: petstore.swagger.io
api_key: your_api_key
```

Response:
```json
{
  "id": 123,
  "name": "Fluffy",
  "category": {
    "id": 1,
    "name": "Dogs"
  },
  "photoUrls": [
    "https://example.com/photos/dog1.jpg"
  ],
  "tags": [
    {
      "id": 1,
      "name": "friendly"
    }
  ],
  "status": "available"
}
```
```

## Step 7: Publishing Your Documentation

Once you're satisfied with your documentation, you can publish it to a web server:

### 7.1 Publishing to GitHub Pages

If you're using GitHub, you can publish your documentation to GitHub Pages:

1. Push your documentation to a GitHub repository
2. Set up GitHub Pages to serve from the `docs` directory
3. Your documentation will be available at `https://username.github.io/repository/`

### 7.2 Publishing to a Custom Web Server

To host on your own web server:

1. Copy the entire `docs` directory to your web server
2. Ensure your web server is configured to serve static files
3. Update any references to the base path as needed

## Step 8: Automating Documentation Updates

To keep your documentation in sync with your OpenAPI specification, consider setting up an automation workflow:

### 8.1 GitHub Actions Example

Create a `.github/workflows/update-docs.yml` file:

```yaml
name: Update API Documentation

on:
  push:
    paths:
      - 'openapi/petstore.yaml'
      - '.github/workflows/update-docs.yml'

jobs:
  update-docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Swift
        uses: swift-actions/setup-swift@v1
        with:
          swift-version: '5.7'

      - name: Install OpenAPI Integration with DocC
        run: |
          git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git
          cd OpenAPI-Integration-with-DocC
          swift build -c release
          cp -f .build/release/openapi-to-symbolgraph /usr/local/bin/

      - name: Generate Documentation
        run: |
          openapi-to-symbolgraph openapi/petstore.yaml --output ./PetStore.docc --module-name PetStore
          mkdir -p PetStoreDocumentation/Sources
          cp -R PetStore.docc PetStoreDocumentation/Sources/
          cd PetStoreDocumentation
          # Create Package.swift (as in step 5.2)
          swift package --allow-writing-to-directory ./docs \
            generate-documentation --target PetStoreDocumentation \
            --output-path ./docs \
            --transform-for-static-hosting \
            --hosting-base-path PetStoreAPI/

      - name: Deploy to GitHub Pages
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: PetStoreDocumentation/docs
          branch: gh-pages
```

This workflow will automatically update your documentation whenever the OpenAPI specification changes.

## Conclusion

Congratulations! You've successfully:

1. Converted an OpenAPI specification to a DocC catalog
2. Generated interactive API documentation
3. Customized the documentation with additional information
4. Set up a workflow for publishing updates

Your API now has professional, interactive documentation that follows Swift's documentation standards, making it easier for developers to understand and use your API.

## Next Steps

- Explore the [Advanced Topics](../Guides/AdvancedTopics.md) guide to learn about more configuration options
- Check out the [API Reference](../Reference/APIReference.md) for programmatic usage
- Try converting a more complex OpenAPI specification to see how different elements are represented
