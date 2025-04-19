# Symbol Graph Debug Tool

This tool helps debug and analyze DocC symbol graphs generated from OpenAPI specifications. It provides several commands to help you understand the structure of your symbol graphs and identify issues.

## Usage

```
swift run symbol-graph-debug [command] [options]
```

### Commands

- **analyze**: Performs a comprehensive analysis of a symbol graph
- **validate-relationships**: Validates all relationships in a symbol graph
- **show-symbol**: Shows detailed information about a specific symbol
- **show-http**: Shows HTTP-specific information for API endpoints

## Findings

Through our investigation using this tool, we've identified several insights about the OpenAPI integration with DocC:

1. **Symbol Graph Structure**: The OpenAPI to Symbol Graph conversion is generating valid symbol graphs with correct relationships.

2. **HTTP Mixins**: SymbolKit provides HTTP-specific mixins that can enhance API documentation with endpoint details, parameter sources, and media types. 

3. **DocC Integration Challenges**:
   - DocC doesn't seem to fully render symbols from the OpenAPI interface language
   - Child symbols aren't appearing in the `topicSections` array of the module JSON
   - This suggests DocC may not be properly associating or recognizing these symbols

4. **Module Name Consistency**: It's critical to ensure the module name is consistent between:
   - The symbol graph's `module.name` value
   - The DocC documentation target
   - Path components in symbols

5. **Relationship Structure**: The relationship structure is valid but might need adjustments to be fully recognized by DocC.

## Potential Solutions

1. **Interface Language**: Consider using "swift" as the interface language instead of "openapi" to potentially improve DocC compatibility.

2. **HTTP Mixins**: Fully implement HTTP mixins to enhance REST API documentation.

3. **Symbol Registration**: Implement proper symbol registration for mixins to enable DocC to recognize and utilize HTTP-specific information.

4. **DocC Extensions**: Consider creating DocC extensions specifically for OpenAPI types to improve rendering.

## Example Usage

```bash
# Analyze a symbol graph
.build/debug/symbol-graph-debug analyze registry.symbolgraph.json

# Validate relationships
.build/debug/symbol-graph-debug validate-relationships registry.symbolgraph.json

# Show HTTP endpoints
.build/debug/symbol-graph-debug show-http registry.symbolgraph.json

# Show details of a specific symbol
.build/debug/symbol-graph-debug show-symbol registry.symbolgraph.json "module"
``` 
