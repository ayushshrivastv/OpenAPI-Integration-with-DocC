# API Reference

## Core Types

### OpenAPIDocCConverter

The main converter class that handles the conversion from OpenAPI to DocC.

```swift
public class OpenAPIDocCConverter {
    public init(configuration: Configuration = .default)
    public func convert(openAPIFile: String) throws -> SymbolGraph
    public func convert(openAPIData: Data, fileExtension: String) throws -> SymbolGraph
}
```

### Configuration

Configuration options for the converter.

```swift
public struct Configuration {
    public var outputPath: String
    public var template: Template
    public var cache: CacheConfiguration
    public var processing: ProcessingConfiguration
    
    public static var `default`: Configuration
}
```

## Templates

### DocumentationTemplate

Protocol for custom documentation templates.

```swift
public protocol DocumentationTemplate {
    func render(symbol: Symbol) -> String
}
```

### DefaultTemplate

The default template implementation.

```swift
public struct DefaultTemplate: DocumentationTemplate {
    public init()
    public func render(symbol: Symbol) -> String
}
```

## Symbol Mapping

### SymbolMapper

Protocol for custom symbol mapping.

```swift
public protocol SymbolMapper {
    func map(openAPIComponent: OpenAPIComponent) -> Symbol
}
```

### DefaultSymbolMapper

The default symbol mapper implementation.

```swift
public struct DefaultSymbolMapper: SymbolMapper {
    public init()
    public func map(openAPIComponent: OpenAPIComponent) -> Symbol
}
```

## Utilities

### URLTemplate

Utility for handling URL templates in OpenAPI specifications.

```swift
public struct URLTemplate {
    public init(template: String)
    public func expand(parameters: [String: String]) -> String
}
```

### Validation

Utility for validating OpenAPI specifications.

```swift
public struct Validation {
    public static func validate(_ document: OpenAPI.Document) throws
    public static func validate(_ schema: JSONSchema) throws
}
```

## Error Types

### ConversionError

Errors that can occur during conversion.

```swift
public enum ConversionError: Error {
    case invalidFileType(String)
    case parsingError(String)
    case validationError(String)
    case templateError(String)
}
```

## Configuration Types

### CacheConfiguration

Configuration for caching.

```swift
public struct CacheConfiguration {
    public var enabled: Bool
    public var directory: String
    public var ttl: TimeInterval
}
```

### ProcessingConfiguration

Configuration for parallel processing.

```swift
public struct ProcessingConfiguration {
    public var maxConcurrent: Int
    public var chunkSize: Int
}
```

## Usage Examples

### Basic Conversion

```swift
let converter = OpenAPIDocCConverter()
let symbolGraph = try converter.convert(openAPIFile: "api.yaml")
```

### Custom Configuration

```swift
var config = Configuration.default
config.outputPath = "custom/docs"
config.template = CustomTemplate()
let converter = OpenAPIDocCConverter(configuration: config)
```

### Custom Symbol Mapping

```swift
struct CustomMapper: SymbolMapper {
    func map(openAPIComponent: OpenAPIComponent) -> Symbol {
        // Custom mapping logic
    }
}

let converter = OpenAPIDocCConverter()
converter.symbolMapper = CustomMapper()
```

## Related Documentation
- [Data Types](DataTypes.md)
- [Best Practices](BestPractices.md)
- [Advanced Topics](../Guides/AdvancedTopics.md) 
