# Advanced Topics

## Custom Templates

### Creating Custom Templates
You can create custom documentation templates by extending the base template system:

```swift
struct CustomTemplate: DocumentationTemplate {
    func render(symbol: Symbol) -> String {
        // Custom rendering logic
    }
}
```

### Template Configuration
Configure templates in your `config.json`:

```json
{
    "templates": {
        "default": "path/to/custom/template",
        "custom": {
            "style": "dark",
            "layout": "sidebar"
        }
    }
}
```

## Advanced Symbol Generation

### Custom Symbol Mappings
Override default symbol mappings:

```swift
struct CustomSymbolMapper: SymbolMapper {
    func map(openAPIComponent: OpenAPIComponent) -> Symbol {
        // Custom mapping logic
    }
}
```

### Symbol Relationships
Define custom relationships between symbols:

```swift
struct CustomRelationshipGenerator: RelationshipGenerator {
    func generateRelationships(symbols: [Symbol]) -> [Relationship] {
        // Custom relationship generation
    }
}
```

## Performance Optimization

### Caching
Enable caching for improved performance:

```json
{
    "cache": {
        "enabled": true,
        "directory": ".cache",
        "ttl": 3600
    }
}
```

### Parallel Processing
Configure parallel processing options:

```json
{
    "processing": {
        "maxConcurrent": 4,
        "chunkSize": 100
    }
}
```

## Integration with Build Systems

### Xcode Integration
Add a build phase to your Xcode project:

```bash
openapi-to-symbolgraph "${SRCROOT}/path/to/openapi.yaml" --output "${BUILT_PRODUCTS_DIR}/Documentation"
```

### CI/CD Integration
Example GitHub Actions workflow:

```yaml
name: Generate Documentation
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Generate Docs
        run: |
          swift run openapi-to-symbolgraph api.yaml
```

## Troubleshooting

### Common Issues
- **Memory Usage**: Adjust chunk size for large documents
- **Performance**: Enable caching for repeated builds
- **Template Errors**: Check template syntax and validation

### Debugging
Enable debug logging:

```bash
openapi-to-symbolgraph api.yaml --verbose --debug
```

## Next Steps
- Explore the [API Reference](APIReference.md)
- Check out [Advanced Tutorials](Tutorial2.md)
- Review [Best Practices](../Reference/BestPractices.md) 
