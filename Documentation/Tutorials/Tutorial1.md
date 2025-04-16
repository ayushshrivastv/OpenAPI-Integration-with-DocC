# Tutorial 1: Basic OpenAPI to DocC Conversion

This tutorial will guide you through the process of converting a simple OpenAPI specification to DocC documentation.

## Prerequisites
- Swift 5.7 or later
- Basic understanding of OpenAPI
- The OpenAPI-DocC Integration tool installed

## Step 1: Create a Simple OpenAPI Specification

Create a file named `simple-api.yaml` with the following content:

```yaml
openapi: 3.0.0
info:
  title: Simple API
  version: 1.0.0
  description: A simple API example
paths:
  /users:
    get:
      summary: Get all users
      description: Returns a list of users
      responses:
        '200':
          description: A list of users
          content:
            application/json:
              schema:
                type: array
                items:
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
```

## Step 2: Generate Documentation

Run the following command to generate DocC documentation:

```bash
openapi-to-symbolgraph simple-api.yaml --output docs
```

## Step 3: View the Documentation

The tool will generate a DocC-compatible symbol graph. You can view it in Xcode by:

1. Opening your Xcode project
2. Selecting the generated documentation in the Documentation navigator
3. Building the documentation (⌘B)

## Step 4: Customize the Output

Create a `config.json` file to customize the documentation:

```json
{
    "outputPath": "docs",
    "template": "default",
    "includeExamples": true,
    "theme": {
        "primaryColor": "#007AFF",
        "fontFamily": "system-ui"
    }
}
```

## Step 5: Rebuild with Customizations

Run the command again with the configuration:

```bash
openapi-to-symbolgraph simple-api.yaml --config config.json
```

## Next Steps
- Try adding more complex API endpoints
- Explore custom templates
- Move on to [Tutorial 2](Tutorial2.md) for advanced features 
