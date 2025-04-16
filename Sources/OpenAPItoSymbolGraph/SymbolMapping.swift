import Foundation
import OpenAPI
import DocC
import SymbolKit

public struct SymbolMapper {
    /// Maps OpenAPI schema types to Swift types with enhanced documentation
    static func mapSchemaType(_ schema: JSONSchema) -> (type: String, documentation: String) {
        var documentation = ""

        switch schema {
        case .string(let stringSchema):
            documentation = "A string value"
            if let format = stringSchema.format {
                documentation += " in \(format) format"
            }
            return ("String", documentation)

        case .number(_):
            return ("Double", "A numeric value")

        case .integer(_):
            return ("Int", "An integer value")

        case .boolean(_):
            return ("Bool", "A boolean value")

        case .array(let arraySchema):
            let (itemType, itemDoc) = mapSchemaType(arraySchema.items)
            return ("[\(itemType)]", "An array of \(itemDoc)")

        case .object(let objectSchema):
            var properties = ""
            objectSchema.properties.forEach { name, schema in
                let (type, doc) = mapSchemaType(schema)
                properties += "- \(name): \(type) - \(doc)\n"
            }
            return ("Object", properties)

        case .reference(let ref):
            return (ref.ref.components(separatedBy: "/").last ?? "Unknown", "Reference to type")

        case .anyOf(_), .allOf(_), .oneOf(_), .not(_):
            return ("Any", "A composite type")
        }
    }

    /// Creates a symbol for an OpenAPI element with enhanced documentation
    static func createSymbol(
        kind: SymbolKind,
        identifier: String,
        title: String,
        description: String?,
        pathComponents: [String],
        parentIdentifier: String?,
        additionalDocumentation: String = ""
    ) -> (symbol: SymbolKit.SymbolGraph.Symbol, relationships: [SymbolKit.SymbolGraph.Relationship]) {
        let docComment = description.map { desc in
            var comment = desc
            if !additionalDocumentation.isEmpty {
                comment += "\n\n" + additionalDocumentation
            }
            return comment
        }

        let symbolKind: SymbolKit.SymbolGraph.Symbol.Kind
        switch kind {
        case .module:
            symbolKind = .init(rawIdentifier: "swift.module", displayName: "Module")
        case .group:
            symbolKind = .init(rawIdentifier: "swift.group", displayName: "Group")
        case .endpoint:
            symbolKind = .init(rawIdentifier: "swift.func", displayName: "Function")
        case .structType:
            symbolKind = .init(rawIdentifier: "swift.struct", displayName: "Structure")
        case .parameter:
            symbolKind = .init(rawIdentifier: "swift.var", displayName: "Parameter")
        case .response:
            symbolKind = .init(rawIdentifier: "swift.enum", displayName: "Response")
        }

        let symbol = SymbolKit.SymbolGraph.Symbol(
            identifier: .init(
                precise: identifier,
                interfaceLanguage: "swift"
            ),
            names: .init(
                title: title,
                navigator: [.init(kind: .text, spelling: title, preciseIdentifier: nil)],
                subHeading: [.init(kind: .text, spelling: title, preciseIdentifier: nil)],
                prose: docComment ?? title
            ),
            pathComponents: pathComponents,
            docComment: docComment.map { SymbolKit.SymbolGraph.LineList([
                .init(text: $0, range: nil)
            ]) },
            accessLevel: .init(rawValue: "public"),
            kind: symbolKind,
            mixins: [:]
        )

        var relationships: [SymbolKit.SymbolGraph.Relationship] = []
        if let parentId = parentIdentifier {
            relationships.append(SymbolKit.SymbolGraph.Relationship(
                source: parentId,
                target: identifier,
                kind: .memberOf,
                targetFallback: nil
            ))
        }

        return (symbol: symbol, relationships: relationships)
    }

    /// Creates a symbol for an OpenAPI operation
    static func createOperationSymbol(
        operation: OpenAPI.Operation,
        path: String,
        method: String
    ) -> (symbol: SymbolKit.SymbolGraph.Symbol, relationships: [SymbolKit.SymbolGraph.Relationship]) {
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []

        // Create operation symbol
        let operationId = "\(method.lowercased())\(path.replacingOccurrences(of: "/", with: "_"))"
        let identifier = "f:API.\(operationId)"

        var additionalDocs = ""

        // Add parameters documentation
        if let parameters = operation.parameters, !parameters.isEmpty {
            additionalDocs += "### Parameters\n"
            for param in parameters {
                let (type, _) = mapSchemaType(param.schema)
                additionalDocs += "- \(param.name): \(type) (\(param.in))\n"
            }
        }

        // Add request body documentation
        if let requestBody = operation.requestBody {
            additionalDocs += "\n### Request Body\n"
            for (contentType, mediaType) in requestBody.content {
                let (type, _) = mapSchemaType(mediaType.schema)
                additionalDocs += "- Content-Type: \(contentType)\n"
                additionalDocs += "- Type: \(type)\n"
            }
        }

        // Add responses documentation
        additionalDocs += "\n### Responses\n"
        for (status, response) in operation.responses {
            additionalDocs += "#### \(status)\n"
            additionalDocs += response.description + "\n"
            if let content = response.content?.first {
                let (type, _) = mapSchemaType(content.value.schema)
                additionalDocs += "- Content-Type: \(content.key)\n"
                additionalDocs += "- Type: \(type)\n"
            }
        }

        let (symbol, _) = createSymbol(
            kind: .endpoint,
            identifier: identifier,
            title: "\(method.uppercased()) \(path)",
            description: operation.summary ?? operation.description,
            pathComponents: ["API", operationId],
            parentIdentifier: "s:API",
            additionalDocumentation: additionalDocs
        )

        // Add relationship to API namespace
        let relationship = SymbolKit.SymbolGraph.Relationship(
            source: identifier,
            target: "s:API",
            kind: .memberOf,
            targetFallback: nil
        )
        relationships.append(relationship)

        return (symbol, relationships)
    }

    /// Creates symbols for an OpenAPI schema
    static func createSchemaSymbol(
        name: String,
        schema: JSONSchema
    ) -> (symbols: [SymbolKit.SymbolGraph.Symbol], relationships: [SymbolKit.SymbolGraph.Relationship]) {
        var symbols: [SymbolKit.SymbolGraph.Symbol] = []
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []

        // Create schema symbol
        let identifier = "s:API.\(name)"
        let (_, documentation) = mapSchemaType(schema)

        let (schemaSymbol, schemaRels) = createSymbol(
            kind: .structType,
            identifier: identifier,
            title: name,
            description: documentation,
            pathComponents: ["API", name],
            parentIdentifier: "s:API",
            additionalDocumentation: ""
        )

        symbols.append(schemaSymbol)
        relationships.append(contentsOf: schemaRels)

        // If it's an object schema, create symbols for its properties
        if case .object(let objectSchema) = schema {
            for (propName, propSchema) in objectSchema.properties {
                let (propSymbols, propRelationships) = createSchemaSymbol(
                    name: "\(name).\(propName)",
                    schema: propSchema
                )
                symbols.append(contentsOf: propSymbols)
                relationships.append(contentsOf: propRelationships)
            }
        }

        return (symbols, relationships)
    }
}

/// The kind of a symbol
public enum SymbolKind {
    case module
    case group
    case endpoint
    case structType
    case parameter
    case response
}

// Using SymbolKit's RelationshipKind directly 
extension SymbolKit.SymbolGraph.Relationship {
    static var memberOf: Kind { Kind(rawValue: "memberOf") }
    static var contains: Kind { Kind(rawValue: "contains") }
    static var hasParameter: Kind { Kind(rawValue: "hasParameter") }
    static var returnsType: Kind { Kind(rawValue: "returnsType") }
}
