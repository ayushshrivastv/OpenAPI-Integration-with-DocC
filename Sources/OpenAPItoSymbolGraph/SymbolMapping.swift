import Foundation
import OpenAPI
import Core
import SymbolKit

/// A mapping between OpenAPI schema and SymbolKit symbols
public struct SymbolMapping {

    /// Maps an OpenAPI schema to a SymbolKit symbol
    /// - Parameters:
    ///   - schema: The OpenAPI schema to map
    ///   - name: The name to give the symbol
    ///   - parentUsr: The USR of the parent symbol
    ///   - moduleName: The name of the module
    /// - Returns: A SymbolKit symbol representing the schema
    public static func mapSchema(_ schema: JSONSchema, name: String, parentUsr: String, moduleName: String) -> Symbol {
        let kind: SymbolKit.SymbolGraph.Symbol.Kind
        let usr = makeUsr(name: name, parentUsr: parentUsr)

        switch schema {
        case .string(let stringSchema):
            kind = .struct

            // Handle special string formats
            if let format = stringSchema.format {
                switch format {
                case "date", "date-time":
                    return createDateTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description)
                case "uuid":
                    return createUUIDTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description)
                case "email":
                    return createEmailTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description)
                case "uri":
                    return createURLTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description)
                case "binary", "byte":
                    return createBinaryTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description)
                default:
                    break
                }
            }

            // Handle enum strings
            if let enumValues = stringSchema.enum, !enumValues.isEmpty {
                return createEnumTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: stringSchema.description, enumValues: enumValues)
            }

        case .number, .integer:
            kind = .struct

        case .boolean:
            kind = .struct

        case .array(let arraySchema):
            return createArrayTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, itemsSchema: arraySchema.items, description: arraySchema.description)

        case .object(let objectSchema):
            // Handle empty objects or objects with additional properties
            if objectSchema.properties.isEmpty {
                if let additionalProperties = objectSchema.additionalProperties {
                    return createDictionaryTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, valueSchema: additionalProperties, description: objectSchema.description)
                }
            }
            kind = .struct

        case .reference(let reference):
            // Extract the type name from the reference
            let components = reference.ref.components(separatedBy: "/")
            let refTypeName = components.last ?? reference.ref
            kind = .struct
            return createReferenceTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, referenceName: refTypeName, reference: reference.ref)

        case .allOf(let schemas):
            // Composite type
            return createCompositeTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas, isAllOf: true)

        case .anyOf(let schemas):
            // Union type
            return createCompositeTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas, isAllOf: false)

        case .oneOf(let schemas):
            // Enum with associated values
            return createOneOfTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas)

        case .not(let schema):
            // Inverse schema (rare)
            return createNotTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schema: schema)
        }

        return createBasicSymbol(kind: kind, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schema.description)
    }

    /// Creates a basic Symbol with the given properties
    private static func createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind, name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = Symbol(
            identifier: .init(precise: usr, interfaceLanguage: "swift"),
            names: .init(title: name, navigator: nil, subHeading: nil, prose: nil),
            pathComponents: [name],
            docComment: description.map { parseDocComment($0) },
            accessLevel: .public,
            kind: kind,
            mixins: [:]
        )

        // Add module information
        symbol.addMixin(SymbolKit.SymbolGraph.Symbol.Swift.Extension(extendedModule: moduleName))

        // Add location to help with navigation
        symbol.addMixin(SymbolKit.SymbolGraph.Symbol.DeclarationFragments(declarationFragments: [
            .init(kind: .keyword, spelling: kind.rawValue, preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: name, preciseIdentifier: nil)
        ]))

        return symbol
    }

    /// Creates a relationship between a parent and child symbol
    /// - Parameters:
    ///   - source: The USR of the source (parent) symbol
    ///   - target: The USR of the target (child) symbol
    ///   - kind: The kind of relationship
    /// - Returns: A relationship between the two symbols
    public static func createRelationship(source: String, target: String, kind: SymbolKit.SymbolGraph.Relationship.Kind) -> SymbolKit.SymbolGraph.Relationship {
        return .init(source: source, target: target, kind: kind, targetFallback: nil)
    }

    /// Parses a doc comment string into a DocComment mixin
    /// - Parameter comment: The comment string to parse
    /// - Returns: A DocComment mixin
    private static func parseDocComment(_ comment: String) -> SymbolKit.SymbolGraph.Symbol.DocComment {
        let lines = comment.split(separator: "\n").map { String($0) }
        let fragments = lines.map { SymbolKit.SymbolGraph.LineList.Fragment(text: $0, range: nil) }
        return .init(lines: .init(fragments))
    }

    /// Creates a unique USR for a symbol
    /// - Parameters:
    ///   - name: The name of the symbol
    ///   - parentUsr: The USR of the parent symbol
    /// - Returns: A unique USR for the symbol
    private static func makeUsr(name: String, parentUsr: String) -> String {
        return "\(parentUsr)/\(name)"
    }

    // MARK: - Specialized Symbol Creators

    /// Creates a symbol for a Date type
    private static func createDateTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "Date",
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a UUID type
    private static func createUUIDTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "UUID",
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for an Email type
    private static func createEmailTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let enhancedDescription = """
        \(description ?? "")

        This is an email address formatted as a string.
        """

        symbol.docComment = parseDocComment(enhancedDescription)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "String",
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a URL type
    private static func createURLTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "URL",
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a binary data type
    private static func createBinaryTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "Data",
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for an enum type
    private static func createEnumTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?, enumValues: [String]) -> Symbol {
        var symbol = createBasicSymbol(kind: .enum, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let enhancedDescription = """
        \(description ?? "")

        Possible values:
        \(enumValues.map { "- `\($0)`" }.joined(separator: "\n"))
        """

        symbol.docComment = parseDocComment(enhancedDescription)

        return symbol
    }

    /// Creates a symbol for an array type
    private static func createArrayTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, itemsSchema: JSONSchema, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let itemTypeName: String

        switch itemsSchema {
        case .reference(let reference):
            let components = reference.ref.components(separatedBy: "/")
            itemTypeName = components.last ?? reference.ref
        case .string:
            itemTypeName = "String"
        case .integer:
            itemTypeName = "Int"
        case .number:
            itemTypeName = "Double"
        case .boolean:
            itemTypeName = "Bool"
        case .array:
            itemTypeName = "Array"
        case .object:
            itemTypeName = "Object"
        case .allOf, .anyOf, .oneOf, .not:
            itemTypeName = "Any"
        }

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "[\(itemTypeName)]",
            genericParameters: [.init(name: itemTypeName, index: 0, depth: 0)]
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a dictionary type (for additionalProperties schemas)
    private static func createDictionaryTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, valueSchema: JSONSchema, description: String?) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)

        let valueTypeName: String

        switch valueSchema {
        case .reference(let reference):
            let components = reference.ref.components(separatedBy: "/")
            valueTypeName = components.last ?? reference.ref
        case .string:
            valueTypeName = "String"
        case .integer:
            valueTypeName = "Int"
        case .number:
            valueTypeName = "Double"
        case .boolean:
            valueTypeName = "Bool"
        case .array:
            valueTypeName = "Array"
        case .object:
            valueTypeName = "Object"
        case .allOf, .anyOf, .oneOf, .not:
            valueTypeName = "Any"
        }

        let enhancedDescription = """
        \(description ?? "")

        This represents a dictionary with string keys and \(valueTypeName) values.
        """

        symbol.docComment = parseDocComment(enhancedDescription)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: "[String: \(valueTypeName)]",
            genericParameters: [
                .init(name: "String", index: 0, depth: 0),
                .init(name: valueTypeName, index: 1, depth: 0)
            ]
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a reference type
    private static func createReferenceTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, referenceName: String, reference: String) -> Symbol {
        var symbol = createBasicSymbol(kind: .typeAlias, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: nil)

        let description = "Reference to `\(referenceName)`"
        symbol.docComment = parseDocComment(description)

        let typeInfo = SymbolKit.SymbolGraph.Symbol.Swift.TypeInfo(
            name: .struct,
            rawType: referenceName,
            genericParameters: nil
        )

        symbol.addMixin(typeInfo)
        return symbol
    }

    /// Creates a symbol for a composite type (allOf or anyOf)
    private static func createCompositeTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schemas: [JSONSchema], isAllOf: Bool) -> Symbol {
        let kind: SymbolKit.SymbolGraph.Symbol.Kind = isAllOf ? .struct : .protocol
        var symbol = createBasicSymbol(kind: kind, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: nil)

        let typeNames = schemas.compactMap { schema -> String? in
            switch schema {
            case .reference(let reference):
                let components = reference.ref.components(separatedBy: "/")
                return components.last
            case .object:
                return "Object"
            default:
                return nil
            }
        }

        let description = isAllOf
            ? "A composite type that combines properties from: \(typeNames.joined(separator: ", "))"
            : "A type that can be one of: \(typeNames.joined(separator: ", "))"

        symbol.docComment = parseDocComment(description)

        return symbol
    }

    /// Creates a symbol for a oneOf type (modeled as an enum with associated values)
    private static func createOneOfTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schemas: [JSONSchema]) -> Symbol {
        var symbol = createBasicSymbol(kind: .enum, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: nil)

        let typeNames = schemas.compactMap { schema -> String? in
            switch schema {
            case .reference(let reference):
                let components = reference.ref.components(separatedBy: "/")
                return components.last
            case .string:
                return "String"
            case .integer:
                return "Int"
            case .number:
                return "Double"
            case .boolean:
                return "Bool"
            case .object:
                return "Object"
            default:
                return nil
            }
        }

        let description = "A type that must be exactly one of: \(typeNames.joined(separator: ", "))"
        symbol.docComment = parseDocComment(description)

        return symbol
    }

    /// Creates a symbol for a not type
    private static func createNotTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schema: JSONSchema) -> Symbol {
        var symbol = createBasicSymbol(kind: .struct, name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: nil)

        let typeName: String

        switch schema {
        case .reference(let reference):
            let components = reference.ref.components(separatedBy: "/")
            typeName = components.last ?? reference.ref
        case .string:
            typeName = "String"
        case .integer:
            typeName = "Int"
        case .number:
            typeName = "Double"
        case .boolean:
            typeName = "Bool"
        case .array:
            typeName = "Array"
        case .object:
            typeName = "Object"
        case .allOf, .anyOf, .oneOf, .not:
            typeName = "Any"
        }

        let description = "A type that is not a \(typeName)"
        symbol.docComment = parseDocComment(description)

        return symbol
    }
}
