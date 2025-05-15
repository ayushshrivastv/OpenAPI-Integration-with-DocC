# Data Types Reference

This reference guide provides a comprehensive overview of how OpenAPI data types and schemas are mapped to Swift types in the generated DocC documentation. Understanding this mapping is essential for working with the OpenAPI Integration with DocC tool effectively.

## Basic Type Mappings

The following table shows how basic OpenAPI types are mapped to Swift types:

| OpenAPI Type | Format | Swift Type |
|--------------|--------|------------|
| string | none | String |
| string | date | Date |
| string | date-time | Date |
| string | email | String (with email semantics) |
| string | uri | URL |
| string | uuid | UUID |
| string | byte | Data |
| string | binary | Data |
| number | none | Double |
| number | float | Float |
| number | double | Double |
| integer | none | Int |
| integer | int32 | Int32 |
| integer | int64 | Int64 |
| boolean | none | Bool |
| array | none | Array<T> |
| object | none | struct |
| null | none | nil |

## Complex Type Mappings

### Arrays

OpenAPI arrays are mapped to Swift's `Array` type with the appropriate element type:

```json
{
  "type": "array",
  "items": {
    "type": "string"
  }
}
```

Maps to:

```swift
Array<String>
```

### Objects

OpenAPI objects are mapped to Swift `struct` types:

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "age": {
      "type": "integer"
    }
  },
  "required": ["name"]
}
```

Maps to:

```swift
struct Person {
    let name: String
    let age: Int?
}
```

### Dictionaries

Objects with no defined properties but with `additionalProperties` are mapped to Swift's `Dictionary` type:

```json
{
  "type": "object",
  "additionalProperties": {
    "type": "string"
  }
}
```

Maps to:

```swift
Dictionary<String, String>
```

### Enumerations

String schemas with enumerated values are mapped to Swift enums:

```json
{
  "type": "string",
  "enum": ["pending", "approved", "rejected"]
}
```

Maps to:

```swift
enum Status: String {
    case pending
    case approved
    case rejected
}
```

### References

References to components schemas are mapped as type references:

```json
{
  "$ref": "#/components/schemas/Pet"
}
```

Maps to a reference to the `Pet` type.

## Composition Schemas

### allOf (Composition)

The `allOf` schema is mapped to a structure that combines all the properties from the referenced schemas:

```json
{
  "allOf": [
    { "$ref": "#/components/schemas/Pet" },
    {
      "type": "object",
      "properties": {
        "breed": {
          "type": "string"
        }
      }
    }
  ]
}
```

Maps to a composite type that includes all properties from `Pet` plus the `breed` property.

### anyOf (Union)

The `anyOf` schema is mapped to a protocol-like type that could be any of the referenced schemas:

```json
{
  "anyOf": [
    { "$ref": "#/components/schemas/Cat" },
    { "$ref": "#/components/schemas/Dog" }
  ]
}
```

Maps to a type that could be either a `Cat` or a `Dog`.

### oneOf (Exclusive Union)

The `oneOf` schema is mapped to an enum-like type that must be exactly one of the referenced schemas:

```json
{
  "oneOf": [
    { "$ref": "#/components/schemas/Cat" },
    { "$ref": "#/components/schemas/Dog" }
  ]
}
```

Maps to a type that must be either a `Cat` or a `Dog`, but not both.

### not

The `not` schema is mapped to a type that is specifically not the referenced schema:

```json
{
  "not": {
    "type": "string"
  }
}
```

Maps to a type that is not a `String`.

## Extended Types

### Formats with Special Handling

The tool provides special handling for certain string formats:

#### Date and DateTime

```json
{
  "type": "string",
  "format": "date-time"
}
```

Maps to Swift's `Date` type with appropriate documentation.

#### UUID

```json
{
  "type": "string",
  "format": "uuid"
}
```

Maps to Swift's `UUID` type.

#### URL

```json
{
  "type": "string",
  "format": "uri"
}
```

Maps to Swift's `URL` type.

#### Binary Data

```json
{
  "type": "string",
  "format": "binary"
}
```

Maps to Swift's `Data` type.

### Custom Formats

If your OpenAPI specification uses custom formats, the tool will preserve the format information in the documentation but map the type to the base type (e.g., `string` with a custom format still maps to `String`).

## Type Annotations and Documentation

In addition to the basic type mapping, the tool adds rich documentation annotations:

### Required vs. Optional

Properties marked as required in OpenAPI are represented as non-optional in Swift, while optional properties are represented with `?`:

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "integer"
    },
    "name": {
      "type": "string"
    }
  },
  "required": ["id"]
}
```

Maps to:

```swift
struct Example {
    let id: Int
    let name: String?
}
```

### Descriptions

Descriptions from the OpenAPI specification are carried over to the DocC documentation:

```json
{
  "type": "string",
  "description": "The unique identifier for the user."
}
```

Appears in the DocC documentation as:

```
The unique identifier for the user.
```

### Examples

Examples from the OpenAPI specification are included in the documentation when the `--include-examples` flag is used:

```json
{
  "type": "string",
  "example": "john.doe@example.com"
}
```

Appears in the documentation as an example value.

## Symbol Name Transformations

OpenAPI identifiers are transformed to match Swift naming conventions:

### Schema Names

Schema names are preserved as-is, but are typically represented as PascalCase in Swift:

```
User → User
pet_response → PetResponse
```

### Property Names

Property names in objects are converted to camelCase for Swift properties:

```
user_id → userId
first_name → firstName
```

### Operation IDs

Operation IDs are transformed into valid Swift function names:

```
getUserById → getUserById
create-user → createUser
```

If an operation doesn't have an ID, one is generated based on the HTTP method and path:

```
GET /users/{id} → get_users_id
```

## Custom Type Mappings

The tool allows for custom type mappings through code extensions. When you need specific schema formats to be mapped to different Swift types, you can extend the `SymbolMapping` struct:

```swift
extension SymbolMapping {
    static func createCustomTypeSymbol(...) -> SymbolKit.SymbolGraph.Symbol {
        // Custom mapping implementation
    }
}
```

## Type Relationships

The tool also generates relationships between types:

### Inheritance-like Relationships

For `allOf` schemas, the resulting type is documented as containing all properties from the referenced schemas:

```json
{
  "allOf": [
    { "$ref": "#/components/schemas/Pet" },
    { ... }
  ]
}
```

The documentation will show that the type includes all properties from `Pet`.

### References

When a schema property references another schema, the documentation includes links between the types:

```json
{
  "type": "object",
  "properties": {
    "owner": {
      "$ref": "#/components/schemas/User"
    }
  }
}
```

The documentation for this type will include a link to the `User` type.

## Conclusion

Understanding how OpenAPI types map to Swift types is crucial for effectively using the OpenAPI Integration with DocC tool. This mapping ensures that your API documentation accurately represents the data structures used in your API, while aligning with Swift programming conventions.

For complex scenarios or custom requirements, consider extending the tool's symbol mapping functionality as described in the [Advanced Topics](../Guides/AdvancedTopics.md) guide.
