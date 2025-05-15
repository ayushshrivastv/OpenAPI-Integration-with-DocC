# API Reference

This reference documentation covers the key classes, structures, and functions available in the OpenAPI Integration with DocC library. Use this guide as a reference when integrating the library programmatically into your projects.

## Core Components

### OpenAPIDocCConverter

The main converter that transforms an OpenAPI document into a SymbolGraph.

```swift
public struct OpenAPIDocCConverter {
    public init(moduleName: String? = nil, baseURL: URL? = nil)
    public func convert(_ document: Document) -> SymbolGraph
}
```

#### Parameters

- `moduleName`: Optional name for the module. If not provided, the title from the OpenAPI info object is used.
- `baseURL`: Optional base URL for the API.

#### Usage Example

```swift
import Integration
import OpenAPI

// Parse your OpenAPI document
let openAPIData = try Data(contentsOf: URL(fileURLWithPath: "path/to/openapi.yaml"))
let parser = JSONParser() // or YAMLParser()
let document = try parser.parse(openAPIData)

// Create and use the converter
let converter = OpenAPIDocCConverter(moduleName: "MyAPI")
let symbolGraph = converter.convert(document)

// Now use the symbolGraph with DocC or save it
```

### DocCCatalogGenerator

Generates a DocC catalog from an OpenAPI document.

```swift
public struct DocCCatalogGenerator {
    public init(moduleName: String? = nil,
                baseURL: URL? = nil,
                outputDirectory: URL,
                includeExamples: Bool = false)

    public func generateCatalog(from document: Document,
                                overwrite: Bool = false) throws -> URL
}
```

#### Parameters

- `moduleName`: Optional name for the module.
- `baseURL`: Optional base URL for the API.
- `outputDirectory`: The directory where the DocC catalog will be generated.
- `includeExamples`: Whether to include examples in the documentation.
- `overwrite`: Whether to overwrite an existing catalog.

#### Usage Example

```swift
import OpenAPItoSymbolGraph
import OpenAPI

// Parse your OpenAPI document
let parser = YAMLParser()
let document = try parser.parse(fileURL: URL(fileURLWithPath: "path/to/openapi.yaml"))

// Generate the catalog
let outputDir = URL(fileURLWithPath: "path/to/output")
let generator = DocCCatalogGenerator(
    moduleName: "MyAPI",
    outputDirectory: outputDir,
    includeExamples: true
)

let catalogURL = try generator.generateCatalog(from: document, overwrite: true)
print("Generated catalog at: \(catalogURL.path)")
```

### SymbolMapping

Maps OpenAPI schemas to SymbolKit symbols.

```swift
public struct SymbolMapping {
    public static func mapSchema(_ schema: JSONSchema,
                                name: String,
                                parentUsr: String,
                                moduleName: String) -> SymbolKit.SymbolGraph.Symbol

    public static func createRelationship(source: String,
                                         target: String,
                                         kind: SymbolKit.SymbolGraph.Relationship.Kind) -> SymbolKit.SymbolGraph.Relationship
}
```

This utility class is responsible for mapping OpenAPI schemas to Swift symbols. It handles various schema types like:
- String with formats (date, UUID, email, etc.)
- Numbers and integers
- Booleans
- Arrays
- Objects
- References to other schemas
- Composition schemas (allOf, anyOf, oneOf, not)

## OpenAPI Parsing

### YAMLParser and JSONParser

Parse OpenAPI specifications from YAML or JSON.

```swift
public struct YAMLParser {
    public init()
    public func parse(_ data: Data) throws -> Document
    public func parse(fileURL: URL) throws -> Document
}

public struct JSONParser {
    public init()
    public func parse(_ data: Data) throws -> Document
    public func parse(fileURL: URL) throws -> Document
}
```

#### Usage Example

```swift
import OpenAPI

// Parse YAML
let yamlParser = YAMLParser()
let yamlDocument = try yamlParser.parse(fileURL: URL(fileURLWithPath: "path/to/openapi.yaml"))

// Parse JSON
let jsonParser = JSONParser()
let jsonDocument = try jsonParser.parse(fileURL: URL(fileURLWithPath: "path/to/openapi.json"))
```

## Command Line Interface

The library includes a command-line interface through the `openapi-to-symbolgraph` executable:

```swift
public struct OpenAPItoDocCCommand: ParsableCommand {
    @Argument(help: "The path to the OpenAPI specification file (YAML or JSON)")
    var inputFile: String

    @Option(name: .shortAndLong, help: "The output directory")
    var output: String

    @Option(name: .longAndShort, help: "The module name to use")
    var moduleName: String?

    @Option(help: "The base URL for the API")
    var baseURL: String?

    @Flag(name: .long, help: "Include examples in the documentation")
    var includeExamples: Bool = false

    @Flag(name: .long, help: "Overwrite existing files")
    var overwrite: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    public init()
    public func run() throws
}
```

## Data Models

### Document

Represents an OpenAPI document.

```swift
public struct Document {
    public let openapi: String
    public let info: Info
    public let servers: [Server]?
    public let paths: [String: PathItem]
    public let components: Components?
    public let security: [SecurityRequirement]?
    public let tags: [Tag]?
    public let externalDocs: ExternalDocumentation?
}
```

### JSONSchema

Represents schema information in an OpenAPI specification.

```swift
public enum JSONSchema {
    case string(SchemaContext<StringFormat>, CoreContext<StringFormat>)
    case number(SchemaContext<NumberFormat>, CoreContext<NumberFormat>)
    case integer(SchemaContext<IntegerFormat>, CoreContext<IntegerFormat>)
    case boolean(CoreContext<BoolFormat>)
    case array(SchemaContext<ArrayFormat>, CoreContext<ArrayFormat>)
    case object(SchemaContext<ObjectFormat>, CoreContext<ObjectFormat>)
    case reference(JSONReference<JSONSchema>, CoreContext<JSONTypeFormat>)
    case allOf(CompositionContext, CoreContext<AllOfFormat>)
    case anyOf(CompositionContext, CoreContext<AnyOfFormat>)
    case oneOf(CompositionContext, CoreContext<OneOfFormat>)
    case not(NotContext, CoreContext<NotFormat>)
    case fragment(CoreContext<Never>)
}
```

## Error Handling

The library includes several error types for handling different failure scenarios:

```swift
public enum ParserError: Error {
    case invalidData
    case unsupportedVersion(String)
    case decodingError(DecodingError)
    case invalidYAML(String)
    case invalidJSON(String)
    case other(Error)
}

public enum CatalogGenerationError: Error {
    case catalogAlreadyExists(String)
    case failedToCreateDirectory(String)
    case failedToWriteFile(String)
}
```

## Extensions and Utilities

The library includes various extensions to standardize interactions between OpenAPIKit and SymbolKit:

```swift
// OpenAPIKitExtensions.swift provides compatibility with different versions of OpenAPIKit
extension OpenAPIKit.OpenAPI.Operation {
    var operationId: String?
    var security: [OpenAPIKit.OpenAPI.SecurityRequirement]?
}

extension OpenAPIKit.OpenAPI.Parameter {
    var description: String?
}

extension OpenAPIKit.OpenAPI.Document.Info {
    var contact: Contact?
}
```

## Advanced Usage

### Custom Symbol Creation

You can create custom symbols using the `SymbolMapping` utilities:

```swift
import OpenAPItoSymbolGraph
import SymbolKit

let schema = ... // Your JSONSchema instance
let symbol = SymbolMapping.mapSchema(
    schema,
    name: "MyCustomType",
    parentUsr: "s:MyModule",
    moduleName: "MyModule"
)

// Add relationships
let relationship = SymbolMapping.createRelationship(
    source: "s:MyModule/MyCustomType",
    target: "s:MyModule/RelatedType",
    kind: .conformsTo
)
```

### Integration with Custom DocC Workflows

To integrate with a custom DocC workflow:

```swift
import OpenAPItoSymbolGraph
import DocC

// Generate the SymbolGraph
let converter = OpenAPIDocCConverter(moduleName: "MyAPI")
let symbolGraph = converter.convert(myDocument)

// Save the SymbolGraph
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let jsonData = try encoder.encode(symbolGraph)
try jsonData.write(to: URL(fileURLWithPath: "myapi.symbols.json"))

// Now use DocC to process this SymbolGraph
// (This is typically done via swift-docc-plugin or DocC command-line tools)
```

## Performance Considerations

For large OpenAPI specifications, be aware of:

- Memory usage (large specs may consume significant memory)
- Processing time (set expectations for larger APIs)
- Output size (resulting DocC catalogs may be large)
