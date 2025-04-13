// The Swift Programming Language
// https://docs.swift.org/swift-book
// Mit licence Copyright (c) 2024 Ayush Srivastava

import Foundation
import OpenAPIKit
import SymbolKit

//function to parse OpenAPI file
func parseOpenAPI(from filePath: String) throws -> OpenAPI.Document {
    let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
    let document = try JSONDecoder().decode(OpenAPI.Document.self, from: data)
    return document
}
//function to create SymbolGraph from OpenAPI document
func createSymbolGraph(from document: OpenAPI.Document) -> SymbolGraph {
    var symbols: [SymbolGraph.Symbol] = []
    var relationships: [SymbolGraph.Relationship] = []

    // Create API namespace symbol
    let apiIdentifier = "s:API"
    let apiSymbol = SymbolGraph.Symbol(
        identifier: SymbolGraph.Symbol.Identifier(
            precise: apiIdentifier,
            interfaceLanguage: "swift"
        ),
        names: SymbolGraph.Symbol.Names(
            title: "API",
            navigator: nil,
            subHeading: nil,
            prose: "API namespace containing all endpoints and models"
        ),
        pathComponents: ["API"],
        docComment: SymbolGraph.LineList([
            SymbolGraph.LineList.Line(text: "A sample API for testing OpenAPI to SymbolGraph conversion.", range: nil)
        ]),
        accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
        kind: SymbolGraph.Symbol.Kind(
            rawIdentifier: "swift.module",
            displayName: "Module"
        ),
        mixins: [:]
    )
    symbols.append(apiSymbol)

    // Map schemas
    for (schemaName, schema) in document.components.schemas {
        let structIdentifier = "s:API.\(schemaName.rawValue)"

        // Create struct symbol for the schema
        let structSymbol = SymbolGraph.Symbol(
            identifier: SymbolGraph.Symbol.Identifier(
                precise: structIdentifier,
                interfaceLanguage: "swift"
            ),
            names: SymbolGraph.Symbol.Names(
                title: schemaName.rawValue,
                navigator: nil,
                subHeading: nil,
                prose: "Schema for \(schemaName.rawValue)"
            ),
            pathComponents: ["API", schemaName.rawValue],
            docComment: nil,
            accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: SymbolGraph.Symbol.Kind(
                rawIdentifier: "swift.struct",
                displayName: "Structure"
            ),
            mixins: [:]
        )
        symbols.append(structSymbol)

        // Add relationship to API namespace
        relationships.append(
            SymbolGraph.Relationship(
                source: apiIdentifier,
                target: structIdentifier,
                kind: .memberOf,
                targetFallback: nil
            ))

        // Extract properties from the schema
        if let properties = schema.objectContext?.properties {
            for (propertyName, property) in properties {
                let propertyIdentifier = "\(structIdentifier).\(propertyName)"

                let propertySymbol = SymbolGraph.Symbol(
                    identifier: SymbolGraph.Symbol.Identifier(
                        precise: propertyIdentifier,
                        interfaceLanguage: "swift"
                    ),
                    names: SymbolGraph.Symbol.Names(
                        title: propertyName,
                        navigator: nil,
                        subHeading: nil,
                        prose: property.description ?? "Property \(propertyName)"
                    ),
                    pathComponents: ["API", schemaName.rawValue, propertyName],
                    docComment: nil,
                    accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
                    kind: SymbolGraph.Symbol.Kind(
                        rawIdentifier: "swift.property",
                        displayName: "Property"
                    ),
                    mixins: [:]
                )
                symbols.append(propertySymbol)

                relationships.append(
                    SymbolGraph.Relationship(
                        source: structIdentifier,
                        target: propertyIdentifier,
                        kind: .memberOf,
                        targetFallback: nil
                    ))
            }
        }
    }

    // Map operations
    for (path, pathItem) in document.paths {
        guard let pathItemValue = pathItem.value as? OpenAPI.PathItem else { continue }
        
        // Handle GET operation
        if let getOp = pathItemValue.get {
            let operationId = getOp.operationId ?? "get\(path.rawValue.replacingOccurrences(of: "/", with: "_"))"
            let functionIdentifier = "f:API.\(operationId)"
            
            // Create function symbol for the operation
            let functionSymbol = SymbolGraph.Symbol(
                identifier: SymbolGraph.Symbol.Identifier(
                    precise: functionIdentifier,
                    interfaceLanguage: "swift"
                ),
                names: SymbolGraph.Symbol.Names(
                    title: operationId,
                    navigator: nil,
                    subHeading: nil,
                    prose: getOp.summary ?? "GET operation for \(path.rawValue)"
                ),
                pathComponents: ["API", operationId],
                docComment: nil,
                accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
                kind: SymbolGraph.Symbol.Kind(
                    rawIdentifier: "swift.func",
                    displayName: "Function"
                ),
                mixins: [:]
            )
            symbols.append(functionSymbol)

            // Add relationship to API namespace
            relationships.append(
                SymbolGraph.Relationship(
                    source: apiIdentifier,
                    target: functionIdentifier,
                    kind: .memberOf,
                    targetFallback: nil
                ))

            // Create parameters
            for parameter in getOp.parameters {
                let paramName: String
                let paramDescription: String?
                
                switch parameter {
                case .a(let param):
                    paramName = param.name ?? "unknown"
                    paramDescription = param.description
                case .b(let ref):
                    paramName = ref.name
                    paramDescription = nil
                }
                
                let paramIdentifier = "v:API.\(operationId).\(paramName)"

                let paramSymbol = SymbolGraph.Symbol(
                    identifier: SymbolGraph.Symbol.Identifier(
                        precise: paramIdentifier,
                        interfaceLanguage: "swift"
                    ),
                    names: SymbolGraph.Symbol.Names(
                        title: paramName,
                        navigator: nil,
                        subHeading: nil,
                        prose: paramDescription ?? "Parameter \(paramName)"
                    ),
                    pathComponents: ["API", operationId, paramName],
                    docComment: nil,
                    accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
                    kind: SymbolGraph.Symbol.Kind(
                        rawIdentifier: "swift.var",
                        displayName: "Parameter"
                    ),
                    mixins: [:]
                )
                symbols.append(paramSymbol)

                relationships.append(
                    SymbolGraph.Relationship(
                        source: functionIdentifier,
                        target: paramIdentifier,
                        kind: .memberOf,
                        targetFallback: nil
                    ))
            }

            // Create response types
            for (statusCode, _) in getOp.responses {
                let responseTypeIdentifier = "e:API.\(operationId).Response\(statusCode)"
                let responseTypeSymbol = SymbolGraph.Symbol(
                    identifier: SymbolGraph.Symbol.Identifier(
                        precise: responseTypeIdentifier,
                        interfaceLanguage: "swift"
                    ),
                    names: SymbolGraph.Symbol.Names(
                        title: "Response\(statusCode)",
                        navigator: nil,
                        subHeading: nil,
                        prose: "Response for status code \(statusCode)"
                    ),
                    pathComponents: ["API", operationId, "Response\(statusCode)"],
                    docComment: nil,
                    accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
                    kind: SymbolGraph.Symbol.Kind(
                        rawIdentifier: "swift.enum",
                        displayName: "Enumeration"
                    ),
                    mixins: [:]
                )
                symbols.append(responseTypeSymbol)

                relationships.append(
                    SymbolGraph.Relationship(
                        source: functionIdentifier,
                        target: responseTypeIdentifier,
                        kind: .defaultImplementationOf,
                        targetFallback: nil
                    ))
            }
        }
        
        // Similar blocks for POST, PUT, DELETE etc. can be added here
    }

    // Create the SymbolGraph
    let metadata = SymbolGraph.Metadata(
        formatVersion: SymbolGraph.SemanticVersion(major: 1, minor: 0, patch: 0),
        generator: "OpenAPItoSymbolGraph"
    )

    let module = SymbolGraph.Module(
        name: "API",
        platform: SymbolGraph.Platform(
            architecture: "x86_64",
            vendor: "apple",
            operatingSystem: .init(name: "macosx")
        )
    )

    let graph = SymbolGraph(
        metadata: metadata,
        module: module,
        symbols: symbols,
        relationships: relationships
    )

    return graph
}

//main execution
guard CommandLine.arguments.count > 1 else {
    print("Usage: openapi-to-symbolgraph <path-to-openapi.json>")
    exit(1)
}

let openAPIFilePath = CommandLine.arguments[1]

do {
    let openAPIDocument = try parseOpenAPI(from: openAPIFilePath)
    print("Successfully parsed OpenAPI file: \(openAPIFilePath)")

    let symbolGraph = createSymbolGraph(from: openAPIDocument)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted  
    let jsonData = try encoder.encode(symbolGraph)
    try jsonData.write(to: URL(fileURLWithPath: "symbolgraph.json"))
    print("SymbolGraph saved to symbolgraph.json")
} catch {
    print("Error: \(error)")
    exit(1)
}
