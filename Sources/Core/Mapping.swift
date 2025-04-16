import Foundation
import OpenAPIKit
import SymbolKit

/// Represents the different conceptual kinds of symbols derived from an OpenAPI specification.
///
/// These kinds are used internally to guide the creation of appropriate `SymbolKit.SymbolGraph.Symbol` instances.
public enum OpenAPISymbolKind {
    /// Represents the top-level API module or namespace.
    case namespace
    /// Represents an API operation/endpoint (e.g., GET /users).
    case endpoint
    /// Represents a parameter for an operation.
    case parameter
    /// Represents the request body of an operation.
    case requestBody
    /// Represents a possible response from an operation.
    case response
    /// Represents a reusable schema definition (often maps to a struct or class).
    case schema
    /// Represents a property within a schema (often maps to a variable or constant).
    case property
    /// Represents a security scheme definition.
    case securityScheme
    /// Represents a server definition.
    case server
    /// Represents a tag used to group operations.
    case tag
    /// Represents a specific case within an enumeration (often derived from schema `enum` values).
    case enumCase
    /// Represents a type alias (potentially useful for simple schemas).
    case typeAlias
}

/// A utility struct containing static methods for mapping OpenAPI elements to SymbolKit symbols and types.
public struct SymbolMapper {
    /// Maps an `OpenAPIKit.JSONSchema` to a Swift type representation string and associated documentation details.
    ///
    /// This function attempts to generate a user-friendly Swift type (e.g., `String`, `Int`, `Date`, `[User]`) and
    /// extracts relevant constraints (format, pattern, min/max values, required properties, etc.) into a documentation string.
    ///
    /// - Parameter schema: The `JSONSchema` to map.
    /// - Returns: A tuple containing the mapped Swift `type` string and a `documentation` string detailing constraints.
    public static func mapSchemaType(_ schema: OpenAPIKit.JSONSchema) -> (type: String, documentation: String) {
        var documentation = ""
        
        // Add format information if available - only when non-empty
        if let format = schema.formatString, !format.isEmpty {
            documentation += "Format: \(format)\n"
        }
        
        // Handle specific schema contexts based on jsonType
        if let jsonType = schema.jsonType {
            switch jsonType {
            case .string:
                if let stringSchema = schema.stringContext {
                    if let pattern = stringSchema.pattern {
                        documentation += "Pattern: \(pattern)\n"
                    }
                    // Only add minLength if it's not the default value (0)
                    if stringSchema.minLength > 0 {
                        documentation += "Minimum length: \(stringSchema.minLength)\n"
                    }
                    if let maxLength = stringSchema.maxLength {
                        documentation += "Maximum length: \(maxLength)\n"
                    }
                }
                
            case .number:
                if let numContext = schema.numberContext {
                    if let minimum = numContext.minimum {
                        // Format without decimal points for whole numbers
                        let minValue = minimum.value
                        let formattedMin = minValue.truncatingRemainder(dividingBy: 1) == 0 ? 
                            String(format: "%.0f", minValue) : String(minValue)
                        documentation += "Minimum value: \(formattedMin)\(minimum.exclusive ? " (exclusive)" : "")\n"
                    }
                    if let maximum = numContext.maximum {
                        // Format without decimal points for whole numbers
                        let maxValue = maximum.value
                        let formattedMax = maxValue.truncatingRemainder(dividingBy: 1) == 0 ? 
                            String(format: "%.0f", maxValue) : String(maxValue)
                        documentation += "Maximum value: \(formattedMax)\(maximum.exclusive ? " (exclusive)" : "")\n"
                    }
                    if let multipleOf = numContext.multipleOf {
                        // Format without decimal points for whole numbers
                        let formattedMultiple = multipleOf.truncatingRemainder(dividingBy: 1) == 0 ? 
                            String(format: "%.0f", multipleOf) : String(multipleOf)
                        documentation += "Must be multiple of: \(formattedMultiple)\n"
                    }
                }
                
            case .integer:
                if let intContext = schema.integerContext {
                    if let minimum = intContext.minimum {
                        documentation += "Minimum value: \(minimum.value)\(minimum.exclusive ? " (exclusive)" : "")\n"
                    }
                    if let maximum = intContext.maximum {
                        documentation += "Maximum value: \(maximum.value)\(maximum.exclusive ? " (exclusive)" : "")\n"
                    }
                    if let multipleOf = intContext.multipleOf {
                        documentation += "Must be multiple of: \(multipleOf)\n"
                    }
                }
                
            case .array:
                if let arrayContext = schema.arrayContext {
                    // Only add minItems if it's not the default value (0)
                    if arrayContext.minItems > 0 {
                        documentation += "Minimum items: \(arrayContext.minItems)\n"
                    }
                    if let maxItems = arrayContext.maxItems {
                        documentation += "Maximum items: \(maxItems)\n"
                    }
                    // Format array items documentation to match test expectations
                    if let items = arrayContext.items {
                        let (itemType, itemDocs) = mapSchemaType(items)
                        if !itemDocs.isEmpty {
                            documentation += "Array items:\ntype: \(itemType)\n"
                        }
                    }
                }
                
            case .object:
                if let objectContext = schema.objectContext {
                    let requiredProps = objectContext.requiredProperties
                    if !requiredProps.isEmpty {
                        documentation += "Required properties: \(requiredProps.joined(separator: ", "))\n"
                    }
                }
                
            default:
                break
            }
        }
        
        let type: String
        if let jsonType = schema.jsonType {
            switch jsonType {
            case .string:
                if let format = schema.formatString {
                    switch format {
                    case "date": type = "Date"
                    case "date-time": type = "Date"
                    case "email": type = "String"
                    case "hostname": type = "String"
                    case "ipv4": type = "String"
                    case "ipv6": type = "String"
                    case "uri": type = "URL"
                    case "uuid": type = "UUID"
                    case "password": type = "String"
                    case "byte": type = "Data"
                    case "binary": type = "Data"
                    default: type = "String"
                    }
                } else {
                    type = "String"
                }
                
            case .number:
                if let format = schema.formatString {
                    switch format {
                    case "float": type = "Float"
                    case "double": type = "Double"
                    default: type = "Double"
                    }
                } else {
                    type = "Double"
                }
                
            case .integer:
                if let format = schema.formatString {
                    switch format {
                    case "int32": type = "Int32"
                    case "int64": type = "Int64"
                    default: type = "Int"
                    }
                } else {
                    type = "Int"
                }
                
            case .boolean:
                type = "Bool"
                
            case .array:
                if let arrayContext = schema.arrayContext, let items = arrayContext.items {
                    let (itemType, _) = mapSchemaType(items)
                    type = "[\(itemType)]"
                    // Nothing needed here - array items documentation is handled in the jsonType switch case
                } else {
                    type = "[Any]"
                }
                
            case .object:
                if let objectContext = schema.objectContext {
                    let properties = objectContext.properties
                    if !properties.isEmpty {
                        var propertyTypes: [String] = []
                        for (name, property) in properties {
                            let (propType, propDocs) = mapSchemaType(property)
                            propertyTypes.append("\(name): \(propType)")
                            if !propDocs.isEmpty {
                                documentation += "\(name):\n\(propDocs)"
                            }
                        }
                        type = "(\(propertyTypes.joined(separator: ", ")))"
                    } else {
                        type = "[String: Any]"
                    }
                } else {
                    type = "[String: Any]"
                }
                
            case .null:
                type = "Void?" // Or another appropriate representation for null
                documentation += "Null schema type.\n"
            
            }
        } else {
            type = "Any"
            documentation += "Unknown or unspecified schema type.\n"
        }
        
        // Add enum values if available
        if let allowedValues = schema.allowedValues, !allowedValues.isEmpty {
            let values = allowedValues.compactMap { $0.value as? CustomStringConvertible }
                                    .map { $0.description }
            if !values.isEmpty {
                documentation += "Allowed values: \(values.joined(separator: ", "))\n"
            }
        }
        
        return (type, documentation)
    }

    /// Creates a `SymbolKit.SymbolGraph.Symbol` and an optional `SymbolKit.SymbolGraph.Relationship` for an OpenAPI element.
    ///
    /// This function centralizes the creation of symbols, mapping the internal `OpenAPISymbolKind` to the appropriate
    /// `SymbolKit.SymbolGraph.Symbol.Kind` and constructing the symbol's properties.
    ///
    /// - Parameters:
    ///   - kind: The conceptual kind of the OpenAPI element (`OpenAPISymbolKind`).
    ///   - identifierPrefix: The prefix for the identifier (e.g., "s", "f").
    ///   - moduleName: The sanitized name of the module (e.g., "PetStoreAPI").
    ///   - localIdentifier: The local part of the identifier (e.g., "User", "getPetById").
    ///   - title: The primary display name for the symbol (e.g., "User").
    ///   - description: The main descriptive text for the symbol.
    ///   - pathComponents: An array of strings representing the navigation path to the symbol (including the module name).
    ///   - parentIdentifier: The full identifier of the parent symbol, if this symbol is a member of another.
    ///   - additionalDocumentation: Any extra documentation strings to append to the main `description`.
    /// - Returns: A tuple containing the created `symbol` and an optional `relationship` (if `parentIdentifier` was provided).
    public static func createSymbol(
        kind: OpenAPISymbolKind,
        identifierPrefix: String, 
        moduleName: String, 
        localIdentifier: String, 
        title: String,
        description: String?,
        pathComponents: [String],
        parentIdentifier: String? = nil,
        additionalDocumentation: String? = nil
    ) -> (symbol: SymbolGraph.Symbol, relationship: SymbolGraph.Relationship?) {
        
        // Construct the full precise identifier
        let preciseIdentifier = "\(identifierPrefix):\(moduleName).\(localIdentifier)"
        
        // Map OpenAPI symbol kind to SymbolKit kind
        let symbolKind: SymbolGraph.Symbol.Kind
        switch kind {
        case .namespace:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.module", displayName: "Module")
        case .endpoint:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.func", displayName: "Function")
        case .parameter:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.var", displayName: "Parameter")
        case .requestBody:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.struct", displayName: "Structure")
        case .response:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.enum", displayName: "Enumeration")
        case .schema:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.struct", displayName: "Structure")
        case .property:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.property", displayName: "Property")
        case .securityScheme:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.protocol", displayName: "Protocol")
        case .server:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.struct", displayName: "Structure")
        case .tag:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.enum", displayName: "Enumeration")
        case .enumCase:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.enum.case", displayName: "Case")
        case .typeAlias:
            symbolKind = SymbolGraph.Symbol.Kind(rawIdentifier: "swift.typealias", displayName: "Type Alias")
        }
        
        // Combine documentation
        var fullDescription = description ?? title
        if let additional = additionalDocumentation {
            fullDescription += "\n\n\(additional)"
        }
        
        // Create the symbol
        let symbol = SymbolGraph.Symbol(
            identifier: SymbolGraph.Symbol.Identifier(
                precise: preciseIdentifier,
                interfaceLanguage: "swift"
            ),
            names: SymbolGraph.Symbol.Names(
                title: title,
                navigator: nil,
                subHeading: nil,
                prose: fullDescription
            ),
            pathComponents: pathComponents,
            docComment: SymbolGraph.LineList([
                SymbolGraph.LineList.Line(text: fullDescription, range: nil)
            ]),
            accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: symbolKind,
            mixins: [:]
        )
        
        // Create relationship if parent is provided
        let relationship = parentIdentifier.map { parentId in
            SymbolGraph.Relationship(
                source: parentId,
                target: preciseIdentifier,
                kind: .memberOf,
                targetFallback: nil
            )
        }
        
        return (symbol, relationship)
    }

    /// Creates a symbol and relationships for an OpenAPI operation (endpoint).
    ///
    /// Generates a `swift.func` symbol representing the operation and includes details like summary, description,
    /// path, method, tags, and deprecation status in the documentation.
    /// It also creates a `.memberOf` relationship linking the operation to the main API namespace.
    ///
    /// - Parameters:
    ///   - operation: The `OpenAPI.Operation` object.
    ///   - path: The API path string.
    ///   - method: The uppercase HTTP method string.
    ///   - moduleName: The sanitized name of the module.
    /// - Returns: A tuple containing the created operation `symbol` and associated `relationships`.
    public static func createOperationSymbol(
        operation: OpenAPI.Operation,
        path: String,
        method: String,
        moduleName: String
    ) -> (symbol: SymbolGraph.Symbol, relationships: [SymbolGraph.Relationship]) {
        var relationships: [SymbolGraph.Relationship] = []
        let rootIdentifier = "s:\(moduleName)"
        
        // Determine operationId and local identifier
        let operationId = operation.operationId ?? "\(method.lowercased())\(path.replacingOccurrences(of: "/", with: "_"))"
        let localIdentifier = operationId
        
        // Build comprehensive documentation
        var documentation = ""
        if let summary = operation.summary {
            documentation += "\(summary)\n\n"
        }
        if let desc = operation.description {
            documentation += "\(desc)\n\n"
        }
        documentation += "Path: \(path)\n"
        documentation += "Method: \(method)\n"
        
        // Add tags if available
        if let tags = operation.tags, !tags.isEmpty {
            documentation += "\nTags: \(tags.joined(separator: ", "))\n"
        }
        
        // Add deprecated information
        if operation.deprecated {
            documentation += "\n⚠️ This endpoint is deprecated.\n"
        }

        // Use createSymbol helper with new parameters
        let (symbol, _) = createSymbol(
            kind: .endpoint,
            identifierPrefix: "f", 
            moduleName: moduleName, 
            localIdentifier: localIdentifier,
            title: operationId,
            description: documentation,
            pathComponents: [moduleName, operationId],
            parentIdentifier: nil,
            additionalDocumentation: nil
        )
        
        // Add relationship to API namespace
        relationships.append(
            SymbolGraph.Relationship(
                source: rootIdentifier,
                target: symbol.identifier.precise,
                kind: .memberOf,
                targetFallback: nil
            )
        )
        
        return (symbol, relationships)
    }

    /// Creates symbols and relationships for an OpenAPI schema definition.
    ///
    /// Generates a primary symbol for the schema itself (often a `swift.struct`) and, if it's an object schema,
    /// generates symbols for each of its properties (`swift.property`). Includes schema and property descriptions
    /// and type information derived from `mapSchemaType`.
    /// Creates `.memberOf` relationships linking the schema to the API namespace and properties to the schema.
    ///
    /// - Parameters:
    ///   - name: The name of the schema.
    ///   - schema: The `OpenAPIKit.JSONSchema` object.
    ///   - moduleName: The sanitized name of the module.
    /// - Returns: A tuple containing an array of all created `symbols` (schema + properties) and an array of associated `relationships`.
    public static func createSchemaSymbol(
        name: String,
        schema: OpenAPIKit.JSONSchema,
        moduleName: String
    ) -> (symbols: [SymbolGraph.Symbol], relationships: [SymbolGraph.Relationship]) {
        var symbols: [SymbolGraph.Symbol] = []
        var relationships: [SymbolGraph.Relationship] = []
        let rootIdentifier = "s:\(moduleName)"
        let schemaLocalIdentifier = name
        let schemaFullIdentifier = "s:\(moduleName).\(schemaLocalIdentifier)"

        // Build documentation
        let (_, typeDocs) = mapSchemaType(schema)
        var documentation = schema.description ?? "Schema for \(name)"
        if !typeDocs.isEmpty {
            documentation += "\n\nType Information:\n\(typeDocs)"
        }

        // Create the main schema symbol
        let (schemaSymbol, schemaRelationship) = createSymbol(
            kind: .schema,
            identifierPrefix: "s", 
            moduleName: moduleName, 
            localIdentifier: schemaLocalIdentifier,
            title: name,
            description: documentation,
            pathComponents: [moduleName, name],
            parentIdentifier: rootIdentifier,
            additionalDocumentation: nil
        )
        
        symbols.append(schemaSymbol)
        if let relationship = schemaRelationship { relationships.append(relationship) }
        
        // Create property symbols if this is an object schema
        if schema.jsonType == .object, let objectContext = schema.objectContext {
            for (propertyName, property) in objectContext.properties {
                let propertyLocalIdentifier = "\(schemaLocalIdentifier).\(propertyName)"
                let (_, propertyDocs) = mapSchemaType(property)

                var propertyDocumentation = property.description ?? "Property \(propertyName)"
                if !propertyDocs.isEmpty {
                    propertyDocumentation += "\n\nType Information:\n\(propertyDocs)"
                }
                
                // Special handling for array properties to include type information
                if property.jsonType == .array {
                    if let arrayContext = property.arrayContext, let items = arrayContext.items {
                        let (itemType, _) = mapSchemaType(items)
                        propertyDocumentation += "\nArray items:\ntype: \(itemType)\n"
                    }
                }

                let (propertySymbol, propertyRelationship) = createSymbol(
                    kind: .property,
                    identifierPrefix: "s",
                    moduleName: moduleName, 
                    localIdentifier: propertyLocalIdentifier,
                    title: propertyName,
                    description: propertyDocumentation,
                    pathComponents: [moduleName, name, propertyName],
                    parentIdentifier: schemaFullIdentifier,
                    additionalDocumentation: nil
                )

                symbols.append(propertySymbol)
                if let relationship = propertyRelationship { relationships.append(relationship) }
            }
        }
        
        return (symbols, relationships)
    }
} 
