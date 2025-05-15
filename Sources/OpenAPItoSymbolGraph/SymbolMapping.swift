import Foundation
import OpenAPIKit
import Core
import SymbolKit

/// A mapping between OpenAPI schema and SymbolKit symbols
public struct SymbolMapping {

    /// Maps an OpenAPI schema to a SymbolKit symbol
    public static func mapSchema(_ schema: JSONSchema, name: String, parentUsr: String, moduleName: String) -> SymbolKit.SymbolGraph.Symbol {
        let kindIdentifier: SymbolKit.SymbolGraph.Symbol.KindIdentifier
        let usr = makeUsr(name: name, parentUsr: parentUsr)
        let schemaDescription = schema.coreContext.description // Centralize description access

        switch schema {
        case .string(let strContext, _): // Use schemaContext for format/allowedValues
            kindIdentifier = .struct
            if let format = strContext.format {
                switch format {
                case .date, .dateTime:
                    return createDateTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
                case .uuid:
                    return createUUIDTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
                case .email:
                    return createEmailTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
                case .uri:
                    return createURLTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
                case .binary, .byte:
                    return createBinaryTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
                default:
                    break
                }
            }
            if let anyCodableValues = strContext.allowedValues, !anyCodableValues.isEmpty {
                 let enumValues = anyCodableValues.compactMap { $0.value as? String }
                 if !enumValues.isEmpty {
                    return createEnumTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription, enumValues: enumValues)
                 }
            }

        case .number, .integer: // Covers .number(SchemaContext<NumberFormat>, CoreContext<NumberFormat>) and .integer(SchemaContext<IntegerFormat>, CoreContext<IntegerFormat>)
            kindIdentifier = .struct

        case .boolean: // Covers .boolean(CoreContext<BoolFormat>)
            kindIdentifier = .struct

        case .array(let arrContext, _): // Covers .array(SchemaContext<ArrayFormat>, CoreContext<ArrayFormat>)
            return createArrayTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, itemsSchema: arrContext.items, description: schemaDescription)

        case .object(let objContext, _): // Covers .object(SchemaContext<ObjectFormat>, CoreContext<ObjectFormat>)
            if objContext.properties.isEmpty {
                if case .schema(let additionalPropertiesSchema) = objContext.additionalProperties {
                    return createDictionaryTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, valueSchema: additionalPropertiesSchema, description: schemaDescription)
                }
            }
            kindIdentifier = .struct

        case .reference(let ref, _): // Covers .reference(JSONReference<JSONSchema>, CoreContext<JSONTypeFormat>)
            let components = ref.absoluteString.components(separatedBy: "/")
            let refTypeName = components.last ?? ref.absoluteString
            return createReferenceTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, referenceName: refTypeName, reference: ref.absoluteString)

        case .allOf(let schemas, _): // Covers .allOf([JSONSchema], CoreContext<AllOfFormat>)
            return createCompositeTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas, isAllOf: true, description: schemaDescription)

        case .anyOf(let schemas, _): // Covers .anyOf([JSONSchema], CoreContext<AnyOfFormat>)
            return createCompositeTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas, isAllOf: false, description: schemaDescription)

        case .oneOf(let schemas, _): // Covers .oneOf([JSONSchema], CoreContext<OneOfFormat>)
            return createOneOfTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schemas: schemas, description: schemaDescription)

        case .not(let notSchema, _): // Covers .not(JSONSchema, CoreContext<NotFormat>)
            return createNotTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, schema: notSchema, description: schemaDescription)
        
        case .fragment: // Covers .fragment(CoreContext<Never>)
             kindIdentifier = .struct
        
        @unknown default:
            kindIdentifier = .struct // Default for unknown cases
        }

        let displayName: String
        switch kindIdentifier {
            case .struct: displayName = "Structure"
            case .class: displayName = "Class"
            case .enum: displayName = "Enumeration"
            case .protocol: displayName = "Protocol"
            case .typealias: displayName = "Type Alias"
            default: displayName = kindIdentifier.identifier.capitalized
        }
        return createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: kindIdentifier, displayName: displayName), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: schemaDescription)
    }

    private static func createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind, name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = SymbolKit.SymbolGraph.Symbol(
            identifier: .init(precise: usr, interfaceLanguage: "swift"),
            names: .init(title: name, navigator: nil, subHeading: nil, prose: nil),
            pathComponents: [name],
            docComment: description.map { parseDocComment($0) },
            accessLevel: SymbolKit.SymbolGraph.AccessLevel.public, // Corrected AccessLevel
            kind: kind,
            mixins: [:]
        )

        symbol.addMixin(SymbolKit.SymbolGraph.Symbol.Swift.Extension(extendedModule: moduleName))

        symbol.addMixin(SymbolKit.SymbolGraph.Symbol.DeclarationFragments(declarationFragments: [
            .init(kind: .keyword, spelling: kind.identifier.identifier, preciseIdentifier: nil), // Used .identifier
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: name, preciseIdentifier: nil)
        ]))

        return symbol
    }

    public static func createRelationship(source: String, target: String, kind: SymbolKit.SymbolGraph.Relationship.Kind) -> SymbolKit.SymbolGraph.Relationship {
        return .init(source: source, target: target, kind: kind, targetFallback: nil)
    }

    private static func parseDocComment(_ comment: String) -> SymbolKit.SymbolGraph.DocumentationComment { // Corrected type
        let lines = comment.split(separator: "\n").map { String($0) }
        let fragments = lines.map { SymbolKit.SymbolGraph.LineList.Line.Fragment(text: $0, range: nil) } // Corrected type
        return .init(lines: .init(fragments))
    }

    private static func makeUsr(name: String, parentUsr: String) -> String {
        return "\(parentUsr)/\(name)"
    }

    // MARK: - Specialized Symbol Creators

    private static func createDateTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "Date",
            generics: []
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createUUIDTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "UUID",
            generics: []
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createEmailTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let enhancedDescription = """
        \(description ?? "")

        This is an email address formatted as a string.
        """
        symbol.docComment = parseDocComment(enhancedDescription)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "String",
            generics: []
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createURLTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "URL",
            generics: []
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createBinaryTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "Data",
            generics: []
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createEnumTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, description: String?, enumValues: [String]) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .enum, displayName: "Enumeration"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let enhancedDescription = """
        \(description ?? "")

        Possible values:
        \(enumValues.map { "- `\($0)`" }.joined(separator: "\n"))
        """
        symbol.docComment = parseDocComment(enhancedDescription)
        return symbol
    }

    private static func createArrayTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, itemsSchema: JSONSchema?, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let elementTypeName: String
        if let items = itemsSchema {
            switch items {
            case .reference(let reference, _): elementTypeName = reference.absoluteString.components(separatedBy: "/").last ?? "Any"
            case .string: elementTypeName = "String"
            case .integer: elementTypeName = "Int"
            case .number: elementTypeName = "Double"
            case .boolean: elementTypeName = "Bool"
            case .array: elementTypeName = "Array" 
            case .object: elementTypeName = "Object"
            case .allOf, .anyOf, .oneOf, .not, .fragment: elementTypeName = "Any"
            @unknown default: elementTypeName = "Any"
            }
        } else {
            elementTypeName = "Any"
        }
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "Array",
            generics: [
                SymbolKit.SymbolGraph.Symbol.Swift.GenericParameter(index: 0, depth: 0, name: elementTypeName)
            ]
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createDictionaryTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, valueSchema: JSONSchema, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let valueTypeName: String
        switch valueSchema {
        case .reference(let reference, _): valueTypeName = reference.absoluteString.components(separatedBy: "/").last ?? "Any"
        case .string: valueTypeName = "String"
        case .integer: valueTypeName = "Int"
        case .number: valueTypeName = "Double"
        case .boolean: valueTypeName = "Bool"
        case .array: valueTypeName = "Array"
        case .object: valueTypeName = "Object"
        case .allOf, .anyOf, .oneOf, .not, .fragment: valueTypeName = "Any"
        @unknown default: valueTypeName = "Any"
        }
        let enhancedDescription = """
        \(description ?? "")

        A dictionary with String keys and `\(valueTypeName)` values.
        """
        symbol.docComment = parseDocComment(enhancedDescription)
        let typeInformation = SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation(
            kind: SymbolKit.SymbolGraph.Symbol.Swift.TypeInformation.Kind.struct, // Fully qualified
            name: "Dictionary",
            generics: [
                SymbolKit.SymbolGraph.Symbol.Swift.GenericParameter(index: 0, depth: 0, name: "String"),
                SymbolKit.SymbolGraph.Symbol.Swift.GenericParameter(index: 1, depth: 0, name: valueTypeName)
            ]
        )
        symbol.addMixin(typeInformation)
        return symbol
    }

    private static func createReferenceTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, referenceName: String, reference: String) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .typealias, displayName: "Type Alias"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: nil) // Description for ref usually comes from referenced type
        let descriptionText = "Reference to `\(referenceName)`"
        symbol.docComment = parseDocComment(descriptionText)
        return symbol
    }

    private static func createCompositeTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schemas: [JSONSchema], isAllOf: Bool, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        let kindIdentifier: SymbolKit.SymbolGraph.Symbol.KindIdentifier = isAllOf ? .struct : .protocol
        let displayName = isAllOf ? "Structure" : "Protocol"
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: kindIdentifier, displayName: displayName), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeNames = schemas.compactMap { schema -> String? in
            switch schema {
            case .reference(let reference, _): return reference.absoluteString.components(separatedBy: "/").last
            default: return schema.coreContext.title // Fallback to title if not a direct reference name
            }
        }
        let typeList = typeNames.filter { !$0.isEmpty }.isEmpty ? "other types" : typeNames.joined(separator: ", ")
        let composition = isAllOf ? "all of" : "any of"
        let currentDescription = symbol.docComment?.lines.map { $0.map { $0.text }.joined() }.joined(separator: "\n") ?? description ?? ""
        let descriptionText = "\(currentDescription.isEmpty ? "" : "\(currentDescription)\n\n")A composite type that is \(composition) \(typeList)."
        symbol.docComment = parseDocComment(descriptionText)
        return symbol
    }

    private static func createOneOfTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schemas: [JSONSchema], description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .enum, displayName: "Enumeration"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeNames = schemas.compactMap { schema -> String? in
            switch schema {
            case .reference(let reference, _): return reference.absoluteString.components(separatedBy: "/").last
            default: return schema.coreContext.title
            }
        }
        let currentDescription = symbol.docComment?.lines.map { $0.map { $0.text }.joined() }.joined(separator: "\n") ?? description ?? ""
        let descriptionText = "\(currentDescription.isEmpty ? "" : "\(currentDescription)\n\n")A type that must be exactly one of: \(typeNames.filter { !$0.isEmpty }.joined(separator: ", "))."
        symbol.docComment = parseDocComment(descriptionText)
        return symbol
    }

    private static func createNotTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String, schema: JSONSchema, description: String?) -> SymbolKit.SymbolGraph.Symbol {
        var symbol = createBasicSymbol(kind: SymbolKit.SymbolGraph.Symbol.Kind(identifier: .struct, displayName: "Structure"), name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr, description: description)
        let typeName: String
        switch schema {
        case .reference(let reference, _): typeName = reference.absoluteString.components(separatedBy: "/").last ?? "UnknownType"
        case .string: typeName = "String"
        case .integer: typeName = "Int"
        case .number: typeName = "Double"
        case .boolean: typeName = "Bool"
        case .array: typeName = "Array"
        case .object: typeName = "Object"
        case .fragment: typeName = "Fragment"
        default: typeName = "the specified type" // Includes .allOf, .anyOf, .oneOf, .not
        }
        let currentDescription = symbol.docComment?.lines.map { $0.map { $0.text }.joined() }.joined(separator: "\n") ?? description ?? ""
        let descriptionText = "\(currentDescription.isEmpty ? "" : "\(currentDescription)\n\n")A type that is not a \(typeName)."
        symbol.docComment = parseDocComment(descriptionText)
        return symbol
    }
}
