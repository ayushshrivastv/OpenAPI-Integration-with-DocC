import Foundation
import OpenAPIKit
import Core
import SymbolKit

/// A mapping between OpenAPI schema and SymbolKit symbols
public struct SymbolMapping {

    /// Maps an OpenAPI schema to a SymbolKit symbol
    public static func map(_ schema: JSONSchema, name: String, usr: String, moduleName: String, parentUsr: String? = nil) -> SymbolKit.SymbolGraph.Symbol {
        let schemaDescription = schema.coreContext?.description

        switch schema.value {
        case .string(_, let coreContext):
            if let enumValues = coreContext.allowedValues?.compactMap({ $0.value as? String }), !enumValues.isEmpty {
                return createEnumTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description, enumValues: enumValues)
            }
            return createStringTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description)

        case .integer(_, let coreContext):
            if let enumValues = coreContext.allowedValues?.compactMap({ String(describing: $0.value) }), !enumValues.isEmpty {
                 return createEnumTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description, enumValues: enumValues)
            }
            return createIntegerTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description)

        case .number(_, let coreContext):
            if let enumValues = coreContext.allowedValues?.compactMap({ String(describing: $0.value) }), !enumValues.isEmpty {
                return createEnumTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description, enumValues: enumValues)
            }
            return createNumberTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description)

        case .boolean(let coreContext): 
            return createBooleanTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: coreContext.description)

        case .object(let objectContext, let coreContext):
            return createObjectTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, properties: objectContext.properties, requiredProperties: objectContext.requiredProperties, description: coreContext.description)

        case .array(let arrayContext, let coreContext):
            return createArrayTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, itemsSchema: arrayContext.items, description: coreContext.description)

        case .reference(let jsonReference, let coreContext): 
            let refTypeName = jsonReference.name ?? "UnknownReference"
            return createReferenceTypeSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, referenceName: refTypeName, reference: jsonReference.absoluteString, description: coreContext?.description)
            
        default:
            // Handle any other schema types with a generic struct symbol
            return createGenericStructSymbol(name: name, usr: usr, moduleName: moduleName, parentUsr: parentUsr ?? moduleName, description: schemaDescription)
        }
    }

    // MARK: - Basic Symbol Creation
    
    private static func createBasicSymbol(kind: SymbolGraph.Symbol.Kind, name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = SymbolGraph.Symbol(
            identifier: SymbolGraph.Symbol.Identifier(precise: usr, interfaceLanguage: "swift"),
            names: SymbolGraph.Symbol.Names(title: name, navigator: nil, subHeading: nil, prose: nil),
            pathComponents: [name],
            docComment: description.flatMap { parseDocComment($0) },
            accessLevel: .public, 
            kind: kind,
            mixins: [:]
        )
        
        let swiftExtension = SymbolGraph.Symbol.Swift.Extension(extendedModule: moduleName)
        symbol.mixins[SymbolGraph.Symbol.Swift.Extension.mixinKey] = swiftExtension

        if let definiteParentUsr = parentUsr {
            // Create a memberOf relationship
            let relationship = SymbolGraph.Relationship(
                source: usr,
                target: definiteParentUsr,
                kind: .memberOf,
                targetFallback: nil
            )
            // Store the relationship for later retrieval
            // Note: SymbolKit doesn't directly add relationships to symbols
            // They're typically collected and added to the graph separately
        }
        return symbol
    }

    private static func parseDocComment(_ comment: String) -> SymbolGraph.DocumentationComment? {
        let lines = comment.split(separator: "\n").map { String($0) }
        let docLines = lines.map { line -> SymbolGraph.LineList.Line in
            let fragment = SymbolGraph.LineList.Line.Fragment(kind: .text, spelling: line, preciseIdentifier: nil)
            return SymbolGraph.LineList.Line(fragments: [fragment])
        }
        return SymbolGraph.DocumentationComment(lines: docLines)
    }
    
    // MARK: - Type-Specific Symbol Creation
    
    private static func createStringTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: "String",
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createIntegerTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: "Int",
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createNumberTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: "Double",
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createBooleanTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: "Bool",
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createObjectTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, properties: [String: JSONSchema], requiredProperties: [String]?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: name,
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createArrayTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, itemsSchema: JSONSchema?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: "Array<Any>", // A better implementation would determine the element type
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createEnumTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?, enumValues: [String]) -> SymbolGraph.Symbol {
        // Create basic symbol
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.enum", displayName: "Enumeration"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add enum values to description
        let enhancedDescription = (description ?? "") + "\n\nPossible values:\n" + 
            enumValues.map { "- `\($0)`" }.joined(separator: "\n")
        symbol.docComment = parseDocComment(enhancedDescription)
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .enum,
            name: name,
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createReferenceTypeSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, referenceName: String, reference: String, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.typealias", displayName: "Type Alias"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description ?? "Reference to `\(referenceName)`"
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .typealias,
            name: referenceName,
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
    
    private static func createGenericStructSymbol(name: String, usr: String, moduleName: String, parentUsr: String?, description: String?) -> SymbolGraph.Symbol {
        var symbol = createBasicSymbol(
            kind: SymbolGraph.Symbol.Kind(parsedIdentifier: "swift.struct", displayName: "Structure"),
            name: name, 
            usr: usr, 
            moduleName: moduleName, 
            parentUsr: parentUsr, 
            description: description
        )
        
        // Add Swift type information mixin
        let typeInfo = SymbolGraph.Symbol.Swift.TypeInformation(
            kind: .struct,
            name: name,
            swiftGenerics: nil
        )
        symbol.mixins[SymbolGraph.Symbol.Swift.TypeInformation.mixinKey] = typeInfo
        
        return symbol
    }
}
