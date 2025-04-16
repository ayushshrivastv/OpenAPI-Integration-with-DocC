# Data Types Reference

## OpenAPI Types

### Document

Represents an OpenAPI document.

```swift
public struct Document {
    public var openapi: String
    public var info: Info
    public var paths: [String: PathItem]
    public var components: Components?
}
```

### Info

Metadata about the API.

```swift
public struct Info {
    public var title: String
    public var version: String
    public var description: String?
}
```

### PathItem

Represents a path in the API.

```swift
public struct PathItem {
    public var get: Operation?
    public var post: Operation?
    public var put: Operation?
    public var delete: Operation?
    public var parameters: [Parameter]?
}
```

### Operation

Represents an API operation.

```swift
public struct Operation {
    public var summary: String?
    public var description: String?
    public var parameters: [Parameter]?
    public var requestBody: RequestBody?
    public var responses: [String: Response]
}
```

## DocC Types

### SymbolGraph

The main output format for DocC documentation.

```swift
public struct SymbolGraph {
    public var metadata: Metadata
    public var module: Module
    public var symbols: [Symbol]
    public var relationships: [Relationship]
}
```

### Symbol

Represents a documented symbol.

```swift
public struct Symbol {
    public var identifier: Identifier
    public var names: Names
    public var pathComponents: [String]
    public var docComment: String?
    public var kind: Kind
}
```

### Relationship

Represents relationships between symbols.

```swift
public struct Relationship {
    public var source: String
    public var target: String
    public var kind: RelationshipKind
}
```

## Configuration Types

### Template

Configuration for documentation templates.

```swift
public struct Template {
    public var name: String
    public var path: String?
    public var options: [String: Any]
}
```

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

## Utility Types

### URLTemplate

Handles URL template expansion.

```swift
public struct URLTemplate {
    public var template: String
    public func expand(parameters: [String: String]) -> String
}
```

### ValidationResult

Result of validation operations.

```swift
public struct ValidationResult {
    public var isValid: Bool
    public var errors: [ValidationError]
}
```

## Enums

### HTTPMethod

```swift
public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    case patch
    case head
    case options
}
```

### SymbolKind

```swift
public enum SymbolKind {
    case namespace
    case endpoint
    case schema
    case parameter
    case response
}
```

### RelationshipKind

```swift
public enum RelationshipKind {
    case memberOf
    case inheritsFrom
    case conformsTo
    case references
}
```

## Type Aliases

```swift
public typealias Parameters = [Parameter]
public typealias Responses = [String: Response]
public typealias Schemas = [String: JSONSchema]
```

## Related Documentation
- [API Reference](APIReference.md)
- [Best Practices](BestPractices.md)
- [Advanced Topics](../Guides/AdvancedTopics.md) 
