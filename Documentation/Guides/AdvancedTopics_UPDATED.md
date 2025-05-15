# Advanced Topics

This guide covers advanced concepts and techniques for using the OpenAPI Integration with DocC tool. It's intended for users who are already familiar with the basic operation of the tool and want to explore more complex scenarios.

## Custom Symbol Mapping

The default symbol mapping converts OpenAPI schemas to Swift types following standard conventions. However, you might want to customize how schemas are mapped to symbols.

### Custom Type Mappings

You can customize how specific schema formats are mapped to Swift types by extending the `SymbolMapping` struct:

```swift
import OpenAPItoSymbolGraph
import SymbolKit
import OpenAPIKit

extension SymbolMapping {
    static func createCustomTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"),
            name: name,
            usr: usr,
            moduleName: moduleName,
            parentUsr: parentUsr,
            description: description
        )

        // Add custom type information
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            name: "MyCustomType",
            kind: .struct,
            availability: nil,
            generics: nil
        )
        symbol.addMixin(typeInformation)

        return symbol
    }
}
```

To use your custom mapping, you'll need to modify the OpenAPItoSymbolGraph source code to utilize your extended functionality.

## Working with Complex OpenAPI Features

### Authentication and Security Schemes

The tool automatically includes security requirements in the generated documentation. To enhance this further, you can add custom documentation:

1. Locate the generated security-related documentation
2. Add detailed examples of authentication flows
3. Include code samples for obtaining and using authentication tokens

Example of enhanced security documentation:

```markdown
# Authentication

## API Key Authentication

This API uses API key authentication. Include your API key in the header:

```http
GET /pets HTTP/1.1
Host: api.example.com
X-API-Key: your_api_key_here
```

## OAuth 2.0

For endpoints requiring OAuth 2.0:

1. Obtain a token from the authorization server:
   ```http
   POST /oauth/token HTTP/1.1
   Host: auth.example.com
   Content-Type: application/x-www-form-urlencoded

   grant_type=client_credentials&client_id=your_client_id&client_secret=your_client_secret
   ```

2. Use the token in your API requests:
   ```http
   GET /pets HTTP/1.1
   Host: api.example.com
   Authorization: Bearer your_access_token
   ```
```

### Handling Polymorphism

OpenAPI's `oneOf`, `anyOf`, and `allOf` schemas can represent polymorphic types. The tool maps these to appropriate Swift types:

- `oneOf` → Enum-like type
- `anyOf` → Protocol-like type
- `allOf` → Struct with composition

To improve documentation for these complex types, consider adding custom examples that show how to:

- Construct complex objects
- Interpret polymorphic responses
- Handle validation for these types

## Integration with SwiftUI Documentation

If you're building a Swift package that includes an API client for your OpenAPI service, you can combine DocC's SwiftUI documentation capabilities with your API documentation.

### Creating Interactive Tutorials

1. Set up a Swift package with your API client
2. Add the generated DocC catalog to your package
3. Create a tutorial that demonstrates using your API:

```swift
@Tutorial(time: 30) {
    @Intro(title: "Working with the PetStore API") {
        Learn how to use the PetStore API to manage pets in your app.

        @Image(source: pet-store-hero.png, alt: "Pet Store API")
    }

    @Section(title: "Fetching Available Pets") {
        @ContentAndMedia {
            Make a request to the PetStore API to fetch all available pets.

            @Image(source: pets-list.png, alt: "List of pets")
        }

        @Steps {
            @Step {
                Import the PetStore client package.

                @Code(name: "ContentView.swift", file: 01-imports.swift)
            }

            @Step {
                Create a PetStore client instance.

                @Code(name: "ContentView.swift", file: 02-create-client.swift)
            }

            @Step {
                Make a request to fetch available pets.

                @Code(name: "ContentView.swift", file: 03-fetch-pets.swift)
            }

            @Step {
                Display the pets in a list.

                @Code(name: "ContentView.swift", file: 04-display-pets.swift)
            }
        }
    }
}
```

## Performance Optimization

For large OpenAPI specifications, you may encounter performance issues. Here are some strategies to optimize the process:

### Reducing Memory Usage

1. Split large OpenAPI specifications into smaller components
2. Generate documentation for each component separately
3. Combine the results using DocC's multi-catalog support

Example workflow:

```bash
# Split your API into components
openapi-to-symbolgraph pets-component.yaml --output ./PetsComponent.docc
openapi-to-symbolgraph orders-component.yaml --output ./OrdersComponent.docc
openapi-to-symbolgraph users-component.yaml --output ./UsersComponent.docc

# Reference all components in your main documentation package
```

### Incremental Documentation Generation

For CI/CD pipelines, implement incremental generation to avoid processing unchanged parts of your API:

1. Hash each component of your OpenAPI specification
2. Store the hashes and associated output
3. Only regenerate documentation for components that have changed

## Localization

DocC supports localization, and you can extend this to your OpenAPI documentation:

1. Generate the base DocC catalog using the OpenAPI Integration tool
2. Create localized versions of the documentation files
3. Organize them according to DocC's localization structure:

```
MyAPI.docc/
├── en.lproj/
│   └── Documentation/
│       └── MyAPI.md
├── es.lproj/
│   └── Documentation/
│       └── MyAPI.md
└── ja.lproj/
    └── Documentation/
        └── MyAPI.md
```

## Custom Templates

If you need to customize the output format beyond what's available through direct editing, you can modify the templates used by the tool:

1. Clone the repository
2. Locate the template-generating code in the `DocCCatalogGenerator.swift` file
3. Modify the templates to suit your needs
4. Build a custom version of the tool

Example of customizing the endpoint documentation template:

```swift
// Custom endpoint documentation generator
private func generateCustomEndpointDocumentation(operation: Operation, path: String, method: HttpMethod) -> String {
    var content = "# \(method.rawValue.uppercased()) \(path)\n\n"

    if let summary = operation.summary {
        content += "## Summary\n\n\(summary)\n\n"
    }

    if let description = operation.description {
        content += "## Description\n\n\(description)\n\n"
    }

    // Add your custom sections here
    content += "## Usage Guide\n\n"
    content += "Here's how to use this endpoint effectively...\n\n"

    // Add standard parameter and response documentation
    // ...

    return content
}
```

## Programmatic Usage in Build Systems

To integrate the OpenAPI documentation generation into a build system:

### Using Swift Package Manager Plugins

Create a custom build tool plugin that generates documentation during the build process:

```swift
import PackagePlugin

@main
struct OpenAPIDocCPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let openAPIFiles = target.sourceFiles.filter { $0.path.extension == "yaml" || $0.path.extension == "json" }

        return openAPIFiles.map { file in
            let outputName = file.path.stem
            let outputDir = context.pluginWorkDirectory.appending(outputName + ".docc")

            return .buildCommand(
                displayName: "Generating DocC for \(file.path.lastComponent)",
                executable: try context.tool(named: "openapi-to-symbolgraph").path,
                arguments: [
                    file.path.string,
                    "--output", outputDir.string,
                    "--module-name", outputName
                ],
                inputFiles: [file.path],
                outputFiles: [outputDir]
            )
        }
    }
}
```

### Integrating with Other Build Systems

For non-Swift build systems, you can create wrapper scripts:

```bash
#!/bin/bash
# openapi-docc-generator.sh

set -e

OPENAPI_FILE=$1
OUTPUT_DIR=$2
MODULE_NAME=$3

if [ -z "$OPENAPI_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <openapi-file> <output-dir> [module-name]"
    exit 1
fi

if [ -z "$MODULE_NAME" ]; then
    MODULE_NAME=$(basename "$OPENAPI_FILE" | sed 's/\.[^.]*$//')
fi

# Generate DocC catalog
openapi-to-symbolgraph "$OPENAPI_FILE" --output "$OUTPUT_DIR" --module-name "$MODULE_NAME"

# Process with DocC if needed
# ...

echo "Documentation generated at $OUTPUT_DIR"
```

## Extending with Custom DocC Features

DocC supports various custom directives that you can leverage:

### Adding Article Collections

Create article collections to organize related API endpoints:

```markdown
# Payment API

This collection covers all payment-related endpoints.

## Overview

The Payment API allows you to process payments, manage refunds, and handle subscriptions.

## Topics

### Processing Payments

- ``create_payment``
- ``get_payment``
- ``refund_payment``

### Managing Subscriptions

- ``create_subscription``
- ``update_subscription``
- ``cancel_subscription``
```

### Custom Metadata and Tags

Add custom metadata to enhance search and filtering:

```markdown
# get_user

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
    @CallToAction(purpose: reference)
    @SupportedLanguage(swift)
    @Available(iOS, introduced: "12.0")
    @Available(macOS, introduced: "10.15")
    @Tag(name: "user management")
    @Tag(name: "authentication required")
}

GET /user/{userId}

Retrieves user information by ID.
```

## Conclusion

These advanced techniques allow you to customize and extend the OpenAPI Integration with DocC tool to fit your specific documentation needs. By leveraging the full capabilities of DocC and the flexibility of the integration tool, you can create comprehensive, interactive API documentation that provides an excellent developer experience.

Remember that many advanced customizations require modifications to the tool's source code or the generated DocC catalog. Always back up your work before making significant changes, and consider contributing useful enhancements back to the main project.
