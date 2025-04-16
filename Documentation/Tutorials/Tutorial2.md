# Tutorial 2: Advanced OpenAPI to DocC Conversion

This tutorial explores advanced features of the OpenAPI-DocC Integration tool, including custom templates, symbol mapping, and performance optimization.

## Prerequisites
- Completion of [Tutorial 1](Tutorial1.md)
- Basic understanding of Swift
- Familiarity with OpenAPI 3.0

## Step 1: Create a Complex OpenAPI Specification

Create `complex-api.yaml`:

```yaml
openapi: 3.0.0
info:
  title: Complex API
  version: 1.0.0
  description: An API with advanced features
paths:
  /users:
    get:
      summary: Get users
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
          format: email
    UserList:
      type: object
      properties:
        users:
          type: array
          items:
            $ref: '#/components/schemas/User'
```

## Step 2: Create Custom Templates

Create a custom template file `custom-template.swift`:

```swift
import OpenAPIDocC

struct CustomTemplate: DocumentationTemplate {
    func render(symbol: Symbol) -> String {
        var output = "# \(symbol.title)\n\n"
        if let description = symbol.description {
            output += "\(description)\n\n"
        }
        // Add custom rendering logic
        return output
    }
}
```

## Step 3: Configure Advanced Settings

Create `advanced-config.json`:

```json
{
    "outputPath": "docs",
    "templates": {
        "default": "custom-template.swift",
        "custom": {
            "style": "dark",
            "layout": "sidebar"
        }
    },
    "cache": {
        "enabled": true,
        "directory": ".cache",
        "ttl": 3600
    },
    "processing": {
        "maxConcurrent": 4,
        "chunkSize": 100
    }
}
```

## Step 4: Generate Documentation with Advanced Features

Run the command with advanced configuration:

```bash
openapi-to-symbolgraph complex-api.yaml --config advanced-config.json --verbose
```

## Step 5: Optimize Performance

1. Enable caching:
```bash
openapi-to-symbolgraph complex-api.yaml --cache
```

2. Use parallel processing:
```bash
openapi-to-symbolgraph complex-api.yaml --parallel 4
```

## Step 6: Integrate with Xcode

Add a build phase to your Xcode project:

1. Select your target
2. Go to Build Phases
3. Add a new Run Script phase:
```bash
openapi-to-symbolgraph "${SRCROOT}/complex-api.yaml" --output "${BUILT_PRODUCTS_DIR}/Documentation"
```

## Next Steps
- Explore the [API Reference](../Reference/APIReference.md)
- Review [Advanced Topics](../Guides/AdvancedTopics.md)
- Check out [Best Practices](../Reference/BestPractices.md) 
