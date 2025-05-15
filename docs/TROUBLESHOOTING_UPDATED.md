# Troubleshooting Guide

This guide addresses common issues you may encounter when using the OpenAPI Integration with DocC tool and provides solutions to resolve them.

## Installation Issues

### Error: Cannot Build from Source

**Problem**: You encounter errors when trying to build the tool from source.

**Solution**:
1. Ensure you have Swift 5.7 or later installed:
   ```bash
   swift --version
   ```

2. Check that you have the Xcode command-line tools installed:
   ```bash
   xcode-select --install
   ```

3. Try resolving dependencies explicitly:
   ```bash
   cd OpenAPI-Integration-with-DocC
   swift package resolve
   swift build -c release
   ```

4. If you encounter specific dependency errors, check the [Package.resolved](../Package.resolved) file to verify dependency versions.

### Error: Command Not Found

**Problem**: After installation, the `openapi-to-symbolgraph` command is not found.

**Solution**:
1. Ensure the command is in your PATH:
   ```bash
   export PATH=$PATH:/path/to/OpenAPI-Integration-with-DocC/.build/release
   ```

2. Or create a symbolic link to a location in your PATH:
   ```bash
   ln -s /path/to/OpenAPI-Integration-with-DocC/.build/release/openapi-to-symbolgraph /usr/local/bin/
   ```

## Parsing Issues

### Error: Invalid OpenAPI Specification

**Problem**: The tool reports that your OpenAPI specification is invalid.

**Solution**:
1. Validate your OpenAPI specification using an online validator like [Swagger Editor](https://editor.swagger.io/).

2. Check for common issues:
   - Missing required fields
   - Incorrect indentation (in YAML files)
   - Invalid references
   - Incorrectly formatted data types

3. If your specification is large, try validating smaller portions to isolate the issue.

### Error: Unsupported OpenAPI Version

**Problem**: The tool reports that your OpenAPI version is unsupported.

**Solution**:
1. Verify that your OpenAPI specification declares a supported version (2.0, 3.0.x, 3.1.x).

2. If you're using a newer version, consider converting it to a supported version.

3. For OpenAPI 3.1 specific features, check if there are workarounds to express them in OpenAPI 3.0 syntax.

### Error: References Cannot Be Resolved

**Problem**: The tool cannot resolve references in your OpenAPI specification.

**Solution**:
1. Ensure all references use the correct format:
   ```
   #/components/schemas/YourSchema
   ```

2. Check for circular references, which may cause issues.

3. Verify that all referenced components actually exist in your specification.

4. For external references, ensure they are accessible and valid.

## Generation Issues

### Error: Cannot Create Output Directory

**Problem**: The tool fails to create the output directory.

**Solution**:
1. Check that you have write permissions for the specified directory.

2. Ensure the parent directory exists.

3. If you're trying to overwrite an existing directory, use the `--overwrite` flag:
   ```bash
   openapi-to-symbolgraph your-api.yaml --output ./existing-dir --overwrite
   ```

### Warning: Missing Operation IDs

**Problem**: You receive warnings about missing operation IDs.

**Solution**:
1. Add `operationId` fields to your OpenAPI operations:
   ```yaml
   paths:
     /pets:
       get:
         operationId: listPets
         # ...
   ```

2. If you cannot modify the specification, the tool will generate IDs based on the HTTP method and path.

3. To customize the generated IDs, you may need to modify your specification or post-process the generated documentation.

### Warning: Missing Descriptions

**Problem**: You receive warnings about missing descriptions.

**Solution**:
1. Add descriptions to your API components:
   ```yaml
   components:
     schemas:
       Pet:
         description: "A pet in the system."
         # ...
   ```

2. Add descriptions to operations:
   ```yaml
   paths:
     /pets:
       get:
         description: "Returns a list of pets."
         # ...
   ```

3. Add descriptions to parameters:
   ```yaml
   parameters:
     - name: id
       description: "The unique identifier of the pet."
       # ...
   ```

## DocC Integration Issues

### Error: Cannot Process SymbolGraph

**Problem**: DocC cannot process the generated SymbolGraph.

**Solution**:
1. Ensure you're using a compatible version of DocC.

2. Check the JSON format of the generated SymbolGraph:
   ```bash
   cat path/to/output.symbols.json | jq
   ```

3. Look for any validation errors reported by DocC.

4. Try using the latest version of the tool, which may have fixes for SymbolGraph compatibility.

### Error: Documentation Not Appearing in Xcode

**Problem**: The generated documentation doesn't appear in Xcode's documentation viewer.

**Solution**:
1. Make sure the DocC catalog is added to your Xcode project and included in your target.

2. Build the documentation explicitly:
   ```
   Product → Build Documentation
   ```

3. Check Xcode's documentation viewer settings to ensure the documentation category is visible.

4. If building a Swift package, ensure the DocC catalog is correctly referenced in your Package.swift.

### Error: Documentation Links Don't Work

**Problem**: Links between documentation pages don't work.

**Solution**:
1. Check that symbol references use the correct format:
   ```
   ``SymbolName``
   ```

2. Ensure the referenced symbols actually exist in your documentation.

3. Check for case sensitivity issues in symbol references.

4. If using custom topics, ensure they are properly formatted.

## Content Issues

### Problem: Generated Documentation Is Missing Elements

**Problem**: Some parts of your API are missing from the generated documentation.

**Solution**:
1. Check that your OpenAPI specification includes all the necessary components.

2. Verify that schemas referenced in responses are defined in the `components/schemas` section.

3. Ensure operations have the necessary metadata for proper documentation.

4. Check for validation errors in your OpenAPI specification.

### Problem: Incorrect Type Mappings

**Problem**: The tool maps OpenAPI types to Swift types incorrectly.

**Solution**:
1. Review the [Data Types Reference](../Documentation/Reference/DataTypes.md) to understand the expected mappings.

2. For special formats, ensure they are correctly specified in your OpenAPI definition.

3. For complex scenarios, you may need to create custom type mappings as described in the [Advanced Topics](../Documentation/Guides/AdvancedTopics.md) guide.

### Problem: Examples Not Showing

**Problem**: Examples from your OpenAPI specification don't appear in the documentation.

**Solution**:
1. Ensure you're using the `--include-examples` flag:
   ```bash
   openapi-to-symbolgraph your-api.yaml --output ./output --include-examples
   ```

2. Check that examples are correctly defined in your OpenAPI specification:
   ```yaml
   components:
     schemas:
       Pet:
         example:
           id: 1
           name: "Fluffy"
           status: "available"
   ```

3. For media type examples, ensure they are defined in the correct format.

## Performance Issues

### Problem: Processing Large Specifications Takes Too Long

**Problem**: Processing a large OpenAPI specification is very slow.

**Solution**:
1. Split your specification into smaller components.

2. Process each component separately and combine the documentation.

3. Optimize your OpenAPI specification by removing unnecessary verbose elements.

4. Increase available memory for the process:
   ```bash
   export SWIFT_MEMORY_LIMIT=4G
   ```

### Problem: Generated Documentation Is Too Large

**Problem**: The generated documentation is too large.

**Solution**:
1. Consider splitting your API into logical domains.

2. Generate separate documentation for each domain.

3. Use DocC's catalog reference features to link between documentation sets.

4. Remove excessive examples or limit their size.

## Customization Issues

### Problem: Need to Customize Documentation Format

**Problem**: You need to customize the format of the generated documentation.

**Solution**:
1. Generate the DocC catalog first.

2. Manually modify the generated markdown files.

3. For more systematic customization, modify the tool's source code to change the documentation templates.

4. Consider creating a post-processing script to modify the generated files.

### Problem: Need to Add Content Not in OpenAPI

**Problem**: You want to add content that isn't part of your OpenAPI specification.

**Solution**:
1. Generate the DocC catalog.

2. Add additional markdown files to the catalog:
   ```
   YourAPI.docc/
   ├── YourAPI.md
   ├── GettingStarted.md
   ├── Authentication.md
   └── ...
   ```

3. Update the main documentation file to link to these additional pages.

4. Regenerate the documentation using DocC.

## Environment-Specific Issues

### Problem: CI/CD Integration

**Problem**: You're having trouble integrating the tool into a CI/CD pipeline.

**Solution**:
1. Create a Docker image with Swift and the tool pre-installed:
   ```dockerfile
   FROM swift:5.9

   # Install dependencies
   RUN apt-get update && apt-get install -y git

   # Install the tool
   RUN git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git && \
       cd OpenAPI-Integration-with-DocC && \
       swift build -c release && \
       cp .build/release/openapi-to-symbolgraph /usr/local/bin/

   # Set up a working directory
   WORKDIR /app

   # Default command
   ENTRYPOINT ["openapi-to-symbolgraph"]
   ```

2. Create a CI/CD script that uses this image:
   ```yaml
   # GitHub Actions example
   jobs:
     generate-docs:
       runs-on: ubuntu-latest
       container: your-docker-image
       steps:
         - uses: actions/checkout@v3
         - name: Generate Documentation
           run: openapi-to-symbolgraph api.yaml --output ./output
         # Further steps to process the output
   ```

3. Consider caching dependencies to speed up builds.

### Problem: macOS vs. Linux Compatibility

**Problem**: The tool behaves differently on macOS and Linux.

**Solution**:
1. Ensure you're using the same version of Swift on both platforms.

2. Check for filesystem path differences (macOS uses case-insensitive paths by default).

3. Verify that all dependencies are properly resolved on both platforms.

4. If possible, standardize on a single platform for documentation generation.

## Contributing Solutions

If you encounter an issue not covered in this guide:

1. Check the [GitHub Issues](https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC/issues) for similar problems.

2. If you find a solution, consider contributing it back to the project:
   - Submit a pull request with a fix
   - Update the documentation
   - Share your workaround in a GitHub issue

3. For complex issues or feature requests, start a discussion in the project's discussion forum.

## Getting Additional Help

If you're still experiencing issues:

1. Open an issue on the [GitHub repository](https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC/issues) with:
   - A detailed description of the problem
   - The OpenAPI specification (or a simplified version that demonstrates the issue)
   - The exact command you're running
   - Any error messages or unexpected results

2. Reach out to the project maintainers with specific questions.

3. Consider contributing to the project's development if you have expertise in Swift, OpenAPI, or DocC.
