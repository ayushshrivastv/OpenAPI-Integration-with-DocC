import Foundation
import Core
import SymbolKit
import OpenAPIKit
import Yams

/// Main integration point for converting OpenAPI specifications to SymbolGraph format
public struct OpenAPItoSymbolGraph {
    /// Converts an OpenAPI specification to a SymbolGraph
    /// - Parameters:
    ///   - openAPIData: The raw data of the OpenAPI specification
    ///   - fileExtension: The file extension of the OpenAPI file (json, yaml, or yml)
    ///   - outputPath: The path to write the SymbolGraph to
    /// - Returns: The generated SymbolGraph
    /// - Throws: Errors that occur during parsing or conversion
    public static func convert(
        openAPIData: Data, 
        fileExtension: String,
        outputPath: String
    ) throws -> SymbolKit.SymbolGraph {
        // Parse the OpenAPI document based on file extension
        let rawDict: [String: Any]
        
        if fileExtension == "json" {
            print("Parsing JSON...")
            guard let jsonDict = try JSONSerialization.jsonObject(with: openAPIData) as? [String: Any] else {
                throw ConversionError.parsingError("Failed to parse JSON as dictionary")
            }
            rawDict = jsonDict
        } else if fileExtension == "yaml" || fileExtension == "yml" {
            print("Parsing YAML...")
            guard let yamlString = String(data: openAPIData, encoding: .utf8),
                  let yamlDict = try Yams.load(yaml: yamlString) as? [String: Any] else {
                throw ConversionError.parsingError("Failed to parse YAML as dictionary")
            }
            rawDict = yamlDict
        } else {
            throw ConversionError.invalidFileType("Unsupported file type: \(fileExtension). Please use .json or .yaml/.yml")
        }
        
        // Extract key information from the OpenAPI spec
        let infoDict = rawDict["info"] as? [String: Any] ?? [:]
        let title = infoDict["title"] as? String ?? "API"
        let description = infoDict["description"] as? String
        
        // Sanitize the title for use as a module name
        let moduleName = title.replacingOccurrences(of: " ", with: "")
                              .replacingOccurrences(of: "-", with: "")
                              .replacingOccurrences(of: ".", with: "")
        
        print("Using module name: \(moduleName)")
        
        // Extract paths and components
        let pathsDict = rawDict["paths"] as? [String: Any] ?? [:]
        let componentsDict = rawDict["components"] as? [String: Any] ?? [:]
        let schemasDict = componentsDict["schemas"] as? [String: Any] ?? [:]
        
        // Generate symbols and relationships
        let (symbols, relationships) = generateSymbolsAndRelationships(
            moduleName: moduleName,
            title: title,
            description: description,
            pathsDict: pathsDict,
            schemasDict: schemasDict
        )
        
        // Create the SymbolGraph
        let symbolGraph = SymbolKit.SymbolGraph(
            metadata: SymbolKit.SymbolGraph.Metadata(
                formatVersion: SymbolKit.SymbolGraph.SemanticVersion(major: 1, minor: 0, patch: 0),
                generator: "OpenAPItoSymbolGraph"
            ),
            module: SymbolKit.SymbolGraph.Module(
                name: moduleName,
                platform: SymbolKit.SymbolGraph.Platform(
                    architecture: nil,
                    vendor: "OpenAPI",
                    operatingSystem: nil
                )
            ),
            symbols: symbols,
            relationships: relationships
        )
        
        // Write the SymbolGraph to the output path
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let symbolGraphData = try encoder.encode(symbolGraph)
        try symbolGraphData.write(to: URL(fileURLWithPath: outputPath))
        
        return symbolGraph
    }
    
    /// Generates symbols and relationships for the OpenAPI specification
    private static func generateSymbolsAndRelationships(
        moduleName: String,
        title: String,
        description: String?,
        pathsDict: [String: Any],
        schemasDict: [String: Any]
    ) -> (symbols: [SymbolKit.SymbolGraph.Symbol], relationships: [SymbolKit.SymbolGraph.Relationship]) {
        var symbols: [SymbolKit.SymbolGraph.Symbol] = []
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []
        
        // Add API namespace
        let identifier = "s:\(moduleName)"
        let (apiSymbol, _) = SymbolMapper.createSymbol(
            kind: .namespace,
            identifier: identifier,
            title: title,
            description: description,
            pathComponents: [moduleName],
            parentIdentifier: nil,
            additionalDocumentation: nil
        )
        
        // Fix the namespace identifier to remove trailing dot
        let fixedNamespaceSymbol = SymbolKit.SymbolGraph.Symbol(
            identifier: SymbolKit.SymbolGraph.Symbol.Identifier(
                precise: "s:\(moduleName)",
                interfaceLanguage: "swift"
            ),
            names: apiSymbol.names,
            pathComponents: apiSymbol.pathComponents,
            docComment: apiSymbol.docComment,
            accessLevel: apiSymbol.accessLevel,
            kind: apiSymbol.kind,
            mixins: apiSymbol.mixins
        )
        
        symbols.append(fixedNamespaceSymbol)
        
        // Process paths
        for (path, pathItemObj) in pathsDict {
            guard let pathItemDict = pathItemObj as? [String: Any] else { continue }
            
            for (method, operationObj) in pathItemDict {
                guard let validMethod = HttpMethod(rawValue: method.lowercased()) else { continue }
                guard let operationDict = operationObj as? [String: Any] else { continue }
                
                // Extract operation details
                let operationId = operationDict["operationId"] as? String
                let summary = operationDict["summary"] as? String
                let operationDescription = operationDict["description"] as? String
                let tags = operationDict["tags"] as? [String]
                let deprecated = operationDict["deprecated"] as? Bool ?? false
                
                // Create partial OpenAPI.Operation for symbol mapping
                _ = OpenAPI.Operation(
                    tags: tags, 
                    summary: summary, 
                    description: operationDescription,
                    externalDocs: nil, 
                    operationId: operationId, 
                    parameters: [], 
                    requestBody: nil, 
                    responses: [:], 
                    callbacks: [:], 
                    deprecated: deprecated, 
                    security: [], 
                    servers: [], 
                    vendorExtensions: [:]
                )
                
                // Create operation title and documentation
                let opTitle = operationId ?? "\(validMethod.rawValue.lowercased())_\(path.replacingOccurrences(of: "/", with: "_"))"
                var documentation = summary ?? "Operation \(opTitle)"
                if let desc = operationDescription {
                    documentation += "\n\n\(desc)"
                }
                documentation += "\n\nPath: \(path)"
                documentation += "\nMethod: \(validMethod.rawValue.uppercased())"
                
                // Create operation symbol
                let opIdentifier = "f:\(moduleName).\(opTitle)"
                let (opSymbol, _) = SymbolMapper.createSymbol(
                    kind: .endpoint,
                    identifier: opIdentifier,
                    title: opTitle,
                    description: documentation,
                    pathComponents: [moduleName, opTitle],
                    parentIdentifier: identifier,
                    additionalDocumentation: nil
                )
                
                symbols.append(opSymbol)
                
                // Create relationship
                let operationRelationship = SymbolKit.SymbolGraph.Relationship(
                    source: identifier,
                    target: opIdentifier,
                    kind: .memberOf,
                    targetFallback: nil
                )
                relationships.append(operationRelationship)
            }
        }
        
        // Process schemas
        for (schemaName, schemaObj) in schemasDict {
            guard let schemaDict = schemaObj as? [String: Any] else { continue }
            
            let schemaTitle = schemaName
            let schemaDescription = schemaDict["description"] as? String ?? "Schema for \(schemaName)"
            let schemaIdentifier = "s:\(moduleName).\(schemaName)"
            
            // Create schema symbol
            let (schemaSymbol, _) = SymbolMapper.createSymbol(
                kind: .schema,
                identifier: schemaIdentifier,
                title: schemaTitle,
                description: schemaDescription,
                pathComponents: [moduleName, schemaName],
                parentIdentifier: identifier,
                additionalDocumentation: nil
            )
            
            symbols.append(schemaSymbol)
            
            // Create relationship
            let schemaRelationship = SymbolKit.SymbolGraph.Relationship(
                source: identifier,
                target: schemaIdentifier,
                kind: .memberOf,
                targetFallback: nil
            )
            relationships.append(schemaRelationship)
        }
        
        return (symbols, relationships)
    }
}

/// Errors that can occur during OpenAPI to SymbolGraph conversion
public enum ConversionError: Error {
    case parsingError(String)
    case invalidFileType(String)
    case conversionError(String)
}

// Re-export needed types for convenience
