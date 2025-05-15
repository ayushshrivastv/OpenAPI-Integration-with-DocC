# OpenAPI to DocC Integration Tutorial

This tutorial will guide you through the process of using the OpenAPI to DocC integration tool to automatically generate Swift documentation from your OpenAPI specifications.

## Prerequisites

Before you begin, ensure you have the following installed:

- Xcode 15.0 or later
- Swift 6.0 or later
- Git for cloning the repository
- An OpenAPI specification file (YAML or JSON) that you want to document

## Step 1: Clone and Build the Project

First, clone the repository and build the project:

```bash
git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git
cd OpenAPI-Integration-with-DocC
swift build
```

This will compile the executable tools that we'll use to generate documentation.

## Step 2: Understand Your OpenAPI Specification

Before generating documentation, it's helpful to understand the structure of your OpenAPI specification. The tool works best with OpenAPI 3.0 or 3.1 specifications that include:

- Detailed descriptions for endpoints, parameters, and schemas
- Proper tagging of operations to organize them into logical groups
- Examples for request and response payloads
- Authentication information

## Step 3: Generate Documentation Using the All-in-One Script

For most users, the simplest approach is to use the all-in-one script that handles the entire process:

```bash
./scripts/generate-openapi-docc.sh path/to/your/api.yaml
```

This script will:
1. Generate a DocC catalog from your OpenAPI specification
2. Run the DocC compiler to generate HTML documentation
3. Output instructions for viewing the documentation

### Advanced Options

You can customize the documentation generation with additional options:

```bash
./scripts/generate-openapi-docc.sh \
  --module-name "YourAPIName" \
  --base-url "https://api.example.com" \
  --include-examples \
  path/to/your/api.yaml
```

Available options include:
- `--module-name`: Set a custom name for your API module
- `--base-url`: Specify the base URL for your API
- `--include-examples`: Include example request/response in the documentation
- `--output-dir`: Specify a custom output directory
- `--overwrite`: Overwrite existing documentation
- `--theme`: Specify a theme name (requires theme support to be enabled)

## Step 4: Manually Generate Documentation (Advanced)

If you need more control over the process, you can use the individual commands:

### 4.1. Convert OpenAPI to DocC Catalog

```bash
swift run openapi-to-symbolgraph to-docc path/to/your/api.yaml --output-directory ./output
```

This creates a `.docc` catalog in the output directory.

### 4.2. Generate HTML Documentation with DocC

```bash
xcrun docc convert output/YourAPI.docc \
  --fallback-display-name YourAPI \
  --fallback-bundle-identifier com.example.YourAPI \
  --fallback-bundle-version 1.0.0 \
  --output-path ./docs
```

## Step 5: Add Authentication Information

The tool automatically includes authentication information in the generated documentation if your OpenAPI specification contains security schemes.

To ensure your authentication information is properly documented:

1. Define security schemes in the `components.securitySchemes` section of your OpenAPI spec
2. Apply them to operations with the `security` field
3. Use the `--include-authentication` flag (enabled by default) when generating documentation

Example security scheme in OpenAPI:

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Step 6: Customize Templates and Themes

For advanced customization, you can use custom templates and themes:

### Using Custom Templates

1. Create a directory for your custom templates:
   ```bash
   mkdir -p custom-templates
   ```

2. Copy and modify the default templates from the repository

3. Use your custom templates when generating documentation:
   ```bash
   ./scripts/generate-openapi-docc.sh \
     --template-dir ./custom-templates \
     path/to/your/api.yaml
   ```

### Using Custom Themes

You can apply a custom theme to change the look of your documentation:

```bash
./scripts/generate-openapi-docc.sh \
  --theme-primary-color "#FF5733" \
  --theme-secondary-color "#33FF57" \
  --theme-font "Helvetica" \
  path/to/your/api.yaml
```

## Step 7: View and Share Your Documentation

After generating the documentation, you can view it locally or deploy it to a web server.

### Local Viewing

To view the documentation locally:

```bash
python3 -m http.server 8000 --directory ./docs
```

Then open your browser to http://localhost:8000

### Deploying to GitHub Pages

To share your API documentation with others, you can deploy it to GitHub Pages:

1. Push your repository to GitHub
2. Enable GitHub Pages in your repository settings
3. Configure it to use the `docs` folder on the main branch

## Step 8: Integration with Swift OpenAPI Generator

If you're also using Swift OpenAPI Generator to generate client code, you can create integrated documentation:

1. Generate your client code using Swift OpenAPI Generator
2. Generate documentation using this tool
3. Link between them in your project documentation

This provides a seamless experience where developers can see both the API documentation and the Swift client code generated from the same OpenAPI specification.

## Troubleshooting

### Common Issues

**Problem**: Documentation generation fails with schema references errors.
**Solution**: Ensure your OpenAPI specification has valid references. Use a linter or validator to check your spec.

**Problem**: Authentication information is missing in the documentation.
**Solution**: Verify that your OpenAPI spec includes security schemes and that they're properly applied to operations.

**Problem**: Custom themes aren't applying correctly.
**Solution**: Check that you're providing valid color codes and font names.

### Getting Help

If you encounter issues not covered here:

1. Check the project's GitHub repository for existing issues
2. Open a new issue with details about your problem
3. Include your OpenAPI specification and the exact commands you're running

## Next Steps

- Explore the advanced features of DocC for further customizing your documentation
- Set up a CI/CD pipeline to automatically update your documentation when your API changes
- Consider contributing to the OpenAPI to DocC integration project by adding features or fixing bugs

Happy documenting!
