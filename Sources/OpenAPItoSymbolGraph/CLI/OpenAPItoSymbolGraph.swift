import Foundation
import OpenAPIKit
import ArgumentParser
import Yams
import SymbolKit

@main
struct OpenAPItoSymbolGraph: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "openapi-to-symbolgraph",
        abstract: "Convert OpenAPI documents to DocC symbol graphs",
        version: "1.0.0"
    )

    @Argument(help: "Path to the OpenAPI document")
    var inputPath: String

    @Option(name: .long, help: "Output path for the symbol graph")
    var outputPath: String = "openapi.symbolgraph.json"

    func run() throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        let data = try Data(contentsOf: inputURL)
        let fileExtension = inputURL.pathExtension.lowercased()

        // Parse the OpenAPI document manually to avoid version parsing issues
        var rawDict: [String: Any]
        
        do {
            if fileExtension == "json" {
                print("Parsing JSON...")
                guard let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw RunError.parsingError("Failed to parse JSON as dictionary")
                }
                rawDict = jsonDict
            } else if fileExtension == "yaml" || fileExtension == "yml" {
                print("Parsing YAML...")
                let yamlString = String(data: data, encoding: .utf8)!
                guard let yamlDict = try Yams.load(yaml: yamlString) as? [String: Any] else {
                    throw RunError.parsingError("Failed to parse YAML as dictionary")
                }
                rawDict = yamlDict
            } else {
                throw RunError.invalidFileType("Unsupported file type: \(fileExtension). Please use .json or .yaml/.yml")
            }
        } catch {
            print("Error during initial parsing: \(error)")
            throw error
        }
        
        // Manually extract key information
        let infoDict = rawDict["info"] as? [String: Any] ?? [:]
        let title = infoDict["title"] as? String ?? "API"
        let description = infoDict["description"] as? String
        let apiVersion = infoDict["version"] as? String ?? "1.0.0"
        
        // Sanitize the title for use as a module name (remove spaces, hyphens, and periods)
        let moduleName = title.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ".", with: "")
        print("Using module name: \(moduleName)") // Debug print
        
        // Extract paths and components
        let pathsDict = rawDict["paths"] as? [String: Any] ?? [:]
        let componentsDict = rawDict["components"] as? [String: Any] ?? [:]
        let schemasDict = componentsDict["schemas"] as? [String: Any] ?? [:]
        
        // --- Symbol graph generation logic ---
        var symbols: [SymbolKit.SymbolGraph.Symbol] = []
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []

        // Add API namespace using SymbolMapper
        let (apiSymbol, _) = SymbolMapper.createSymbol(
            kind: .namespace,
            identifierPrefix: "s", 
            moduleName: moduleName, 
            localIdentifier: "", // Root namespace has no local identifier part - will result in "s:moduleName."
            title: title,
            description: description,
            pathComponents: [moduleName], // Path is just the module name
            parentIdentifier: nil // parentIdentifier is nil for root
        )
        
        // Fix the namespace identifier to remove the trailing dot
        let fixedNamespaceSymbol = SymbolKit.SymbolGraph.Symbol(
            identifier: SymbolKit.SymbolGraph.Symbol.Identifier(
                precise: "s:\(moduleName)", // No dot at the end
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

        // Process paths using SymbolMapper
        print("Processing paths...")
        print("DEBUG: pathsDict keys: \(pathsDict.keys)")
        
        for (path, pathItemObj) in pathsDict {
            print("DEBUG: Processing path: \(path)")
            guard let pathItemDict = pathItemObj as? [String: Any] else { 
                print("DEBUG: pathItemObj is not a dictionary")
                continue 
            }
            print("DEBUG: pathItemDict keys: \(pathItemDict.keys)")

            for (method, operationObj) in pathItemDict {
                 print("DEBUG: Processing method: \(method)")
                 guard let validMethod = OpenAPI.HttpMethod(rawValue: method.lowercased()) else { 
                     print("DEBUG: Not a valid HTTP method: \(method)")
                     continue 
                 }
                 guard let operationDict = operationObj as? [String: Any] else { 
                     print("DEBUG: operationObj is not a dictionary")
                     continue 
                 }
                 print("DEBUG: operationDict keys: \(operationDict.keys)")

                 // ---- Reconstruct OpenAPI.Operation (partially) ----
                 let operationId = operationDict["operationId"] as? String
                 print("DEBUG: operationId: \(operationId ?? "nil")")
                 let summary = operationDict["summary"] as? String
                 let operationDescription = operationDict["description"] as? String
                 let tags = operationDict["tags"] as? [String]
                 let deprecated = operationDict["deprecated"] as? Bool ?? false

                 let reconstructedOp = OpenAPI.Operation(
                     tags: tags, summary: summary, description: operationDescription,
                     externalDocs: nil, operationId: operationId, parameters: [], 
                     requestBody: nil, responses: [:], callbacks: [:], 
                     deprecated: deprecated, security: [], servers: [], vendorExtensions: [:])

                 // Pass moduleName to SymbolMapper functions
                 print("DEBUG: Creating operation symbol for \(operationId ?? "unknown"), method: \(method), path: \(path)")
                 let (opSymbol, opRelationships) = SymbolMapper.createOperationSymbol(
                     operation: reconstructedOp,
                     path: path,
                     method: validMethod.rawValue.uppercased(),
                     moduleName: moduleName // Pass moduleName
                 )
                 print("DEBUG: Created operation symbol with ID: \(opSymbol.identifier.precise)")
                 print("DEBUG: Adding operation relationships: \(opRelationships.map { "\($0.source)|\($0.target)" }.joined(separator: ", "))")
                 
                 symbols.append(opSymbol)
                 relationships.append(contentsOf: opRelationships)
            }
        }

        // Process schemas using SymbolMapper
        print("Processing schemas...")
        for (schemaName, schemaObj) in schemasDict {
            guard let schemaDict = schemaObj as? [String: Any] else { continue }

            do {
                let schemaData = try JSONSerialization.data(withJSONObject: schemaDict, options: [])
                let decoder = JSONDecoder()
                let jsonSchema = try decoder.decode(OpenAPIKit.JSONSchema.self, from: schemaData)

                // Pass moduleName to SymbolMapper functions
                let (schemaSymbols, schemaRelationships) = SymbolMapper.createSchemaSymbol(
                    name: schemaName,
                    schema: jsonSchema,
                    moduleName: moduleName // Pass moduleName
                )
                symbols.append(contentsOf: schemaSymbols)
                relationships.append(contentsOf: schemaRelationships)

            } catch {
                 print("Warning: Failed to decode schema '\(schemaName)' into OpenAPIKit.JSONSchema: \(error). Creating basic symbol.")
                 // Also update call here for basic symbol creation
                 let (basicSchemaSymbol, basicSchemaRelationship) = SymbolMapper.createSymbol(
                      kind: .schema,
                      identifierPrefix: "s", 
                      moduleName: moduleName, 
                      localIdentifier: schemaName, // Schema name is local ID
                      title: schemaName,
                      description: schemaDict["description"] as? String ?? "Schema for \(schemaName) (Decoding Failed)",
                      pathComponents: [moduleName, schemaName],
                      parentIdentifier: "s:\(moduleName)" // Use fixed namespace identifier (no dot)
                  )
                  symbols.append(basicSchemaSymbol)
                  if let rel = basicSchemaRelationship { relationships.append(rel) }
            }
        }
        
        // Create symbol graph (using sanitized moduleName)
        let symbolGraph = SymbolKit.SymbolGraph(
             metadata: SymbolKit.SymbolGraph.Metadata(
                 formatVersion: SymbolKit.SymbolGraph.SemanticVersion(major: 1, minor: 0, patch: 0),
                 generator: "OpenAPItoSymbolGraph"
             ),
             module: SymbolKit.SymbolGraph.Module(
                 name: moduleName, // Ensure this uses the fully sanitized name
                 platform: SymbolKit.SymbolGraph.Platform(
                     architecture: nil,
                     vendor: nil,
                     operatingSystem: SymbolKit.SymbolGraph.OperatingSystem(name: "macosx")
                 ),
                 version: parseVersion(apiVersion)
             ),
             symbols: symbols,
             relationships: relationships
         )

         // Write symbol graph to file
         let outputURL = URL(fileURLWithPath: outputPath)
         let encoder = JSONEncoder()
         encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
         let symbolGraphData = try encoder.encode(symbolGraph)
         try symbolGraphData.write(to: outputURL)

         print("Symbol graph generated at \(outputURL.path)")
    }

    /// Parses a version string (e.g., "1.2.3") into a `SymbolKit.SymbolGraph.SemanticVersion`.
    ///
    /// This function handles basic `major.minor.patch` formats. Pre-release identifiers
    /// and build metadata in the version string are ignored.
    /// - Parameter versionString: The version string to parse.
    /// - Returns: A `SemanticVersion` instance.
    private func parseVersion(_ versionString: String) -> SymbolKit.SymbolGraph.SemanticVersion {
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        // Note: Pre-release identifiers and build metadata are ignored in this simple parse.
        return SymbolKit.SymbolGraph.SemanticVersion(major: major, minor: minor, patch: patch)
    }
    
    // Helper function to map JSON types to Swift types
    func mapJsonTypeToSwift(type: String, format: String?) -> String {
        switch type.lowercased() {
        case "string":
            if let format = format {
                switch format.lowercased() {
                case "date": return "Date"
                case "date-time": return "Date" 
                case "email": return "String"
                case "uri": return "URL"
                case "uuid": return "UUID"
                case "binary", "byte": return "Data"
                default: return "String"
                }
            }
            return "String"
            
        case "integer":
            if let format = format {
                switch format.lowercased() {
                case "int32": return "Int32"
                case "int64": return "Int64"
                default: return "Int"
                }
            }
            return "Int"
            
        case "number":
            if let format = format {
                switch format.lowercased() {
                case "float": return "Float"
                case "double": return "Double"
                default: return "Double"
                }
            }
            return "Double"
            
        case "boolean":
            return "Bool"
            
        case "array":
            return "[Any]" // A more robust solution would extract the items type
            
        case "object":
            return "[String: Any]"
            
        default:
            return "Any"
        }
    }

    // Define custom error
    enum RunError: Error, CustomStringConvertible {
        case invalidFileType(String)
        case parsingError(String)
        case dataEncodingError(String)

        var description: String {
            switch self {
            case .invalidFileType(let msg): return msg
            case .parsingError(let msg): return msg
            case .dataEncodingError(let msg): return msg
            }
        }
    }
} 
