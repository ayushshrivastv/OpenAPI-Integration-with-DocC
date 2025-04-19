import Foundation
import ArgumentParser
import SymbolKit

// Define HTTP extension since we don't have direct access to the one in SymbolKit
extension SymbolKit.SymbolGraph.Symbol {
    enum HTTP {
        static let endpointMixinKey = "httpEndpoint"
        static let parameterSourceMixinKey = "httpParameterSource"
        static let mediaTypeMixinKey = "httpMediaType"
    }
    
    var httpEndpoint: [String: Any]? {
        // We can't cast to Mixin types directly without the protocols, so just check if the key exists
        return mixins.keys.contains(HTTP.endpointMixinKey) ? [:] : nil
    }
    
    var httpParameterSource: String? {
        // We can't cast to Mixin types directly without the protocols, so just check if the key exists
        return mixins.keys.contains(HTTP.parameterSourceMixinKey) ? "parameter" : nil
    }
    
    var httpMediaType: String? {
        // We can't cast to Mixin types directly without the protocols, so just check if the key exists
        return mixins.keys.contains(HTTP.mediaTypeMixinKey) ? "media-type" : nil
    }
}

struct SymbolGraphDebug: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "symbol-graph-debug",
        abstract: "Debug and analyze DocC symbol graph files",
        version: "1.0.0",
        subcommands: [Analyze.self, ValidateRelationships.self, ShowSymbol.self, ShowHTTP.self, UnifiedSymbolGraph.self, OpenAPIDebug.self]
    )
    
    struct Analyze: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "analyze",
            abstract: "Analyze a symbol graph file for common issues"
        )
        
        @Argument(help: "Path to the symbol graph file")
        var symbolGraphPath: String
        
        func run() throws {
            print("Analyzing symbol graph at \(symbolGraphPath)...")
            
            // Read and decode the symbol graph file
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let symbolGraphData = try Data(contentsOf: symbolGraphURL)
            let decoder = JSONDecoder()
            let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: symbolGraphData)
            
            // Print basic information
            print("\nSymbolGraph Summary:")
            print("Module: \(symbolGraph.module.name)")
            print("Format Version: \(symbolGraph.metadata.formatVersion.major).\(symbolGraph.metadata.formatVersion.minor).\(symbolGraph.metadata.formatVersion.patch)")
            print("Symbols Count: \(symbolGraph.symbols.count)")
            print("Relationships Count: \(symbolGraph.relationships.count)")
            
            // Analyze symbols by kind
            var symbolsByKind: [String: Int] = [:]
            for symbol in symbolGraph.symbols.values {
                let kind = symbol.kind.identifier.identifier
                symbolsByKind[kind, default: 0] += 1
            }
            
            print("\nSymbols by Kind:")
            for (kind, count) in symbolsByKind.sorted(by: { $0.value > $1.value }) {
                print("  \(kind): \(count)")
            }
            
            // Analyze relationships by kind
            var relationshipsByKind: [String: Int] = [:]
            for relationship in symbolGraph.relationships {
                let kind = relationship.kind.rawValue
                relationshipsByKind[kind, default: 0] += 1
            }
            
            print("\nRelationships by Kind:")
            for (kind, count) in relationshipsByKind.sorted(by: { $0.value > $1.value }) {
                print("  \(kind): \(count)")
            }
            
            // Check for orphaned symbols (no relationships)
            var orphanedSymbols: [String] = []
            for symbolID in symbolGraph.symbols.keys {
                let hasRelationship = symbolGraph.relationships.contains { $0.source == symbolID || $0.target == symbolID }
                if !hasRelationship && symbolID != "module" {
                    orphanedSymbols.append(symbolID)
                }
            }
            
            if !orphanedSymbols.isEmpty {
                print("\nWARNING: Found \(orphanedSymbols.count) orphaned symbols (no relationships):")
                for symbolID in orphanedSymbols.prefix(10) {
                    if let symbol = symbolGraph.symbols[symbolID] {
                        print("  - \(symbolID): \(symbol.names.title) (\(symbol.kind.displayName))")
                    } else {
                        print("  - \(symbolID)")
                    }
                }
                if orphanedSymbols.count > 10 {
                    print("  ...and \(orphanedSymbols.count - 10) more")
                }
            }
            
            // Check for dangling relationships (source or target doesn't exist)
            var danglingRelationships: [(String, String)] = []
            for relationship in symbolGraph.relationships {
                if relationship.source != "module" && symbolGraph.symbols[relationship.source] == nil {
                    danglingRelationships.append((relationship.source, "source"))
                }
                if symbolGraph.symbols[relationship.target] == nil {
                    danglingRelationships.append((relationship.target, "target"))
                }
            }
            
            if !danglingRelationships.isEmpty {
                print("\nERROR: Found \(danglingRelationships.count) dangling relationships (missing symbol):")
                for (symbolID, type) in danglingRelationships.prefix(10) {
                    print("  - Missing \(type): \(symbolID)")
                }
                if danglingRelationships.count > 10 {
                    print("  ...and \(danglingRelationships.count - 10) more")
                }
                
                print("\nDANGEROUS: This will cause DocC to crash with an error like:")
                print("'Symbol with identifier X has no reference. A symbol will always have at least one reference.'")
            }
            
            // Check for potential HTTP endpoints that could benefit from HTTP mixins
            var potentialHttpEndpoints: [String] = []
            for (symbolID, symbol) in symbolGraph.symbols {
                if symbolID.hasPrefix("operation:") || symbol.identifier.precise.hasPrefix("operation:") {
                    if symbol.httpEndpoint == nil {
                        potentialHttpEndpoints.append(symbolID)
                    }
                }
            }
            
            if !potentialHttpEndpoints.isEmpty {
                print("\nINFO: Found \(potentialHttpEndpoints.count) potential HTTP endpoints that could use HTTP mixins:")
                for symbolID in potentialHttpEndpoints.prefix(5) {
                    if let symbol = symbolGraph.symbols[symbolID] {
                        print("  - \(symbolID): \(symbol.names.title)")
                    }
                }
                if potentialHttpEndpoints.count > 5 {
                    print("  ...and \(potentialHttpEndpoints.count - 5) more")
                }
                
                print("\nTIP: SymbolKit supports HTTP-specific mixins to enhance REST API docs.")
                print("See swift-docc-symbolkit/Sources/SymbolKit/SymbolGraph/Symbol/HTTP/HTTP.swift")
            }
        }
    }
    
    struct ValidateRelationships: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "validate-relationships",
            abstract: "Validate all relationships in a symbol graph"
        )
        
        @Argument(help: "Path to the symbol graph file")
        var symbolGraphPath: String
        
        func run() throws {
            print("Validating relationships in symbol graph at \(symbolGraphPath)...")
            
            // Read and decode the symbol graph file
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let symbolGraphData = try Data(contentsOf: symbolGraphURL)
            let decoder = JSONDecoder()
            let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: symbolGraphData)
            
            // Check all relationships for validity
            var validCount = 0
            var invalidCount = 0
            var issues: [(relationship: SymbolKit.SymbolGraph.Relationship, issue: String)] = []
            
            for relationship in symbolGraph.relationships {
                var relationshipIssues: [String] = []
                
                // Check if source exists
                if symbolGraph.symbols[relationship.source] == nil && relationship.source != "module" {
                    relationshipIssues.append("Source symbol '\(relationship.source)' does not exist")
                }
                
                // Check if target exists
                if symbolGraph.symbols[relationship.target] == nil {
                    relationshipIssues.append("Target symbol '\(relationship.target)' does not exist")
                }
                
                if relationshipIssues.isEmpty {
                    validCount += 1
                } else {
                    invalidCount += 1
                    issues.append((relationship, relationshipIssues.joined(separator: ", ")))
                }
            }
            
            print("\nResults:")
            print("Total relationships: \(symbolGraph.relationships.count)")
            print("Valid relationships: \(validCount)")
            print("Invalid relationships: \(invalidCount)")
            
            if !issues.isEmpty {
                print("\nIssues found:")
                for (i, issue) in issues.prefix(20).enumerated() {
                    print("\(i+1). \(issue.relationship.source) -> \(issue.relationship.target) (\(issue.relationship.kind.rawValue))")
                    print("   Issue: \(issue.issue)")
                }
                
                if issues.count > 20 {
                    print("...and \(issues.count - 20) more issues")
                }
            }
        }
    }
    
    struct ShowSymbol: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "show-symbol",
            abstract: "Display details of a specific symbol"
        )
        
        @Argument(help: "Path to the symbol graph file")
        var symbolGraphPath: String
        
        @Argument(help: "ID of the symbol to show details for")
        var symbolID: String
        
        func run() throws {
            // Read and decode the symbol graph file
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let symbolGraphData = try Data(contentsOf: symbolGraphURL)
            let decoder = JSONDecoder()
            let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: symbolGraphData)
            
            // Find the symbol by ID
            guard let symbol = symbolGraph.symbols[symbolID] else {
                print("Symbol with ID '\(symbolID)' not found.")
                
                // Find similar symbols
                let similarSymbols = symbolGraph.symbols.keys.filter { $0.contains(symbolID) || symbolID.contains($0) }
                if !similarSymbols.isEmpty {
                    print("\nSimilar symbols found:")
                    for similarID in similarSymbols.prefix(5) {
                        print("- \(similarID)")
                    }
                    if similarSymbols.count > 5 {
                        print("...and \(similarSymbols.count - 5) more")
                    }
                }
                
                return
            }
            
            // Display detailed information about the symbol
            print("Symbol: \(symbolID)")
            print("\nBasic Information:")
            print("- Title: \(symbol.names.title)")
            print("- Kind: \(symbol.kind.displayName) (\(symbol.kind.identifier.identifier))")
            print("- Interface Language: \(symbol.identifier.interfaceLanguage)")
            print("- Access Level: \(symbol.accessLevel.rawValue)")
            
            // Path components
            print("\nPath Components:")
            for (i, component) in symbol.pathComponents.enumerated() {
                print("  \(i+1). \(component)")
            }
            
            // Documentation comment
            if let docComment = symbol.docComment {
                print("\nDocumentation:")
                for line in docComment.lines {
                    print("  \(line.text)")
                }
            } else {
                print("\nDocumentation: None")
            }
            
            // Mixins
            if !symbol.mixins.isEmpty {
                print("\nMixins:")
                for (key, _) in symbol.mixins {
                    print("- \(key)")
                }
            }
            
            // Find related symbols
            let relatedRelationships = symbolGraph.relationships.filter { 
                $0.source == symbolID || $0.target == symbolID
            }
            
            if !relatedRelationships.isEmpty {
                print("\nRelationships:")
                for relationship in relatedRelationships {
                    if relationship.source == symbolID {
                        let targetName = symbolGraph.symbols[relationship.target]?.names.title ?? relationship.target
                        print("- \(relationship.kind.rawValue) -> \(targetName) (\(relationship.target))")
                    } else {
                        let sourceName = symbolGraph.symbols[relationship.source]?.names.title ?? relationship.source
                        print("- \(sourceName) (\(relationship.source)) \(relationship.kind.rawValue) -> this symbol")
                    }
                }
            } else {
                print("\nRelationships: None (this symbol is orphaned)")
            }
        }
    }
    
    struct ShowHTTP: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "show-http",
            abstract: "Display HTTP-specific information for API endpoints"
        )
        
        @Argument(help: "Path to the symbol graph file")
        var symbolGraphPath: String
        
        func run() throws {
            print("Analyzing HTTP endpoints in symbol graph at \(symbolGraphPath)...")
            
            // Read and decode the symbol graph file
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let symbolGraphData = try Data(contentsOf: symbolGraphURL)
            let decoder = JSONDecoder()
            let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: symbolGraphData)
            
            // Find symbols representing HTTP endpoints
            var httpEndpoints: [(symbol: SymbolKit.SymbolGraph.Symbol, id: String)] = []
            
            for (id, symbol) in symbolGraph.symbols {
                if id.hasPrefix("operation:") || symbol.identifier.precise.hasPrefix("operation:") {
                    httpEndpoints.append((symbol, id))
                }
            }
            
            if httpEndpoints.isEmpty {
                print("\nNo HTTP endpoints found in the symbol graph.")
            } else {
                print("\nFound \(httpEndpoints.count) HTTP endpoints:")
                
                for (i, endpoint) in httpEndpoints.enumerated() {
                    print("\n\(i+1). \(endpoint.symbol.names.title) (\(endpoint.id))")
                    
                    // Check if the endpoint has HTTP mixins
                    if let httpEndpoint = endpoint.symbol.httpEndpoint {
                        if let method = httpEndpoint["method"] as? String {
                            print("  HTTP Method: \(method)")
                        }
                        if let baseURL = httpEndpoint["baseURL"] as? String {
                            print("  Base URL: \(baseURL)")
                        }
                        if let path = httpEndpoint["path"] as? String {
                            print("  Path: \(path)")
                        }
                        if let sandboxURL = httpEndpoint["sandboxURL"] as? String {
                            print("  Sandbox URL: \(sandboxURL)")
                        }
                    } else {
                        print("  No HTTP endpoint mixin found.")
                        
                        // Parse method and path from the title or ID if possible
                        let title = endpoint.symbol.names.title
                        if title.contains(" ") {
                            let components = title.components(separatedBy: " ")
                            if components.count >= 2 {
                                print("  Detected HTTP Method: \(components[0])")
                                print("  Detected Path: \(components[1])")
                            }
                        }
                    }
                    
                    // Find parameters
                    let parameterRelationships = symbolGraph.relationships.filter {
                        $0.target == endpoint.id && 
                        $0.kind == .memberOf
                    }
                    
                    let parameters = parameterRelationships.compactMap { relationship -> (SymbolKit.SymbolGraph.Symbol, String)? in
                        guard let symbol = symbolGraph.symbols[relationship.source],
                              symbol.identifier.precise.hasPrefix("parameter:") else {
                            return nil
                        }
                        return (symbol, relationship.source)
                    }
                    
                    if !parameters.isEmpty {
                        print("  Parameters:")
                        for (param, paramId) in parameters {
                            print("    - \(param.names.title) (\(paramId))")
                            if let source = param.httpParameterSource {
                                print("      Location: \(source)")
                            }
                        }
                    }
                    
                    // Find responses
                    let responseRelationships = symbolGraph.relationships.filter {
                        $0.target == endpoint.id && 
                        $0.kind == .memberOf
                    }
                    
                    let responses = responseRelationships.compactMap { relationship -> (SymbolKit.SymbolGraph.Symbol, String)? in
                        guard let symbol = symbolGraph.symbols[relationship.source],
                              symbol.identifier.precise.hasPrefix("response:") else {
                            return nil
                        }
                        return (symbol, relationship.source)
                    }
                    
                    if !responses.isEmpty {
                        print("  Responses:")
                        for (response, responseId) in responses {
                            print("    - \(response.names.title) (\(responseId))")
                            if let mediaType = response.httpMediaType {
                                print("      Media Type: \(mediaType)")
                            }
                        }
                    }
                }
                
                print("\nTIP: Use the HTTP mixins in SymbolKit to enhance REST API documentation:")
                print("- httpEndpoint: Defines HTTP method, base URL, and path")
                print("- httpParameterSource: Specifies where parameters are located (path, query, header, cookie)")
                print("- httpMediaType: Specifies content type for request/response payloads")
            }
        }
    }
    
    struct UnifiedSymbolGraph: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "unified",
            abstract: "Analyze a unified symbol graph using GraphCollector"
        )
        
        @Argument(help: "Directory containing symbol graph files or path to a specific .symbols.json file")
        var symbolGraphPath: String
        
        @Option(name: .shortAndLong, help: "Name of an output file to save the unified symbol graph")
        var outputPath: String?
        
        func run() throws {
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let fileManager = FileManager.default
            var inputURLs: [URL] = []
            
            // Check if path is a directory or a file
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: symbolGraphPath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Get all .symbols.json files in the directory
                    let directoryContents = try fileManager.contentsOfDirectory(at: symbolGraphURL, includingPropertiesForKeys: nil)
                    inputURLs = directoryContents.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("symbols") }
                } else {
                    // Single file
                    inputURLs = [symbolGraphURL]
                }
            } else {
                print("Error: Path \(symbolGraphPath) does not exist")
                return
            }
            
            if inputURLs.isEmpty {
                print("Error: No symbol graph files found at \(symbolGraphPath)")
                return
            }
            
            print("Found \(inputURLs.count) symbol graph files to analyze:")
            for url in inputURLs {
                print("- \(url.lastPathComponent)")
            }
            
            // Load all symbol graphs first
            var symbolGraphs: [SymbolKit.SymbolGraph] = []
            
            for url in inputURLs {
                do {
                    print("\nLoading \(url.lastPathComponent)...")
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let graph = try decoder.decode(SymbolKit.SymbolGraph.self, from: data)
                    symbolGraphs.append(graph)
                    print("Successfully loaded symbol graph: \(graph.module.name)")
                } catch {
                    print("Error loading \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            // Manual approach instead of using GraphCollector
            print("\n=== Manual Symbol Graph Analysis ===")
            
            // Combine all symbols and relationships
            var allSymbols: [String: SymbolKit.SymbolGraph.Symbol] = [:]
            var allRelationships: [SymbolKit.SymbolGraph.Relationship] = []
            var moduleNames: Set<String> = []
            
            for graph in symbolGraphs {
                // Add module name
                moduleNames.insert(graph.module.name)
                
                // Add symbols
                for (id, symbol) in graph.symbols {
                    allSymbols[id] = symbol
                }
                
                // Add relationships
                allRelationships.append(contentsOf: graph.relationships)
            }
            
            print("Modules: \(moduleNames.joined(separator: ", "))")
            print("Total symbols: \(allSymbols.count)")
            print("Total relationships: \(allRelationships.count)")
            
            // If outputPath specified, save the combined graph as JSON
            if let outputPath = outputPath {
                // Create a simplified JSON representation
                var combinedData: [String: Any] = [
                    "modules": Array(moduleNames),
                    "symbolCount": allSymbols.count,
                    "relationshipCount": allRelationships.count,
                    "symbols": allSymbols.keys.sorted()
                ]
                
                // Add relationship data in a simplified format
                var relationshipData: [[String: Any]] = []
                for relationship in allRelationships {
                    relationshipData.append([
                        "source": relationship.source,
                        "target": relationship.target,
                        "kind": relationship.kind.rawValue
                    ])
                }
                combinedData["relationships"] = relationshipData
                
                // Save as JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let outputURL = URL(fileURLWithPath: outputPath)
                
                // Convert to JSON manually since we have a mix of types
                let jsonData = try JSONSerialization.data(withJSONObject: combinedData, options: [.prettyPrinted, .sortedKeys])
                try jsonData.write(to: outputURL)
                print("\nSaved simplified analysis to \(outputPath)")
            }
            
            // Analyze relationships
            var problemSymbols: Set<String> = []
            var missingSourceSymbols: [String: [SymbolKit.SymbolGraph.Relationship]] = [:]
            var missingTargetSymbols: [String: [SymbolKit.SymbolGraph.Relationship]] = [:]
            
            for relationship in allRelationships {
                let sourceID = relationship.source
                let targetID = relationship.target
                
                // Check if source exists
                if !allSymbols.keys.contains(sourceID) && sourceID != "module" {
                    missingSourceSymbols[sourceID, default: []].append(relationship)
                    problemSymbols.insert(sourceID)
                }
                
                // Check if target exists
                if !allSymbols.keys.contains(targetID) {
                    missingTargetSymbols[targetID, default: []].append(relationship)
                    problemSymbols.insert(targetID)
                }
            }
            
            // Report findings
            if problemSymbols.isEmpty {
                print("\n✅ No relationship issues found! All symbol relationships are valid.")
            } else {
                print("\n❌ Found \(problemSymbols.count) symbols with relationship issues:")
                
                if !missingSourceSymbols.isEmpty {
                    print("\nMissing SOURCE symbols:")
                    for (sourceID, relationships) in missingSourceSymbols.sorted(by: { $0.key < $1.key }) {
                        print("  \(sourceID) - used in \(relationships.count) relationships:")
                        for relationship in relationships.prefix(3) {
                            print("    - \(relationship.kind.rawValue) -> \(relationship.target)")
                        }
                        if relationships.count > 3 {
                            print("    - ... and \(relationships.count - 3) more")
                        }
                    }
                }
                
                if !missingTargetSymbols.isEmpty {
                    print("\nMissing TARGET symbols:")
                    for (targetID, relationships) in missingTargetSymbols.sorted(by: { $0.key < $1.key }) {
                        print("  \(targetID) - used in \(relationships.count) relationships:")
                        for relationship in relationships.prefix(3) {
                            print("    - \(relationship.source) \(relationship.kind.rawValue) ->")
                        }
                        if relationships.count > 3 {
                            print("    - ... and \(relationships.count - 3) more")
                        }
                    }
                }
                
                print("\n⚠️ These issues will cause DocC to crash with an error like:")
                print("'Symbol with identifier X has no reference. A symbol will always have at least one reference.'")
                print("\nPossible fixes:")
                print("1. Ensure all referenced symbols are defined in your API schemas")
                print("2. Check for typos or mismatches in symbol identifiers")
                print("3. For path components, ensure parent symbols exist in the hierarchy")
                print("4. Verify the symbol graph generation logic adds all required symbols")
            }
        }
    }
    
    struct OpenAPIDebug: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "openapi-debug",
            abstract: "Debug OpenAPI to SymbolGraph conversion issues"
        )
        
        @Argument(help: "Path to the symbol graph file generated from OpenAPI")
        var symbolGraphPath: String
        
        func run() throws {
            print("Analyzing OpenAPI-generated symbol graph at \(symbolGraphPath)...")
            
            // Read and decode the symbol graph file
            let symbolGraphURL = URL(fileURLWithPath: symbolGraphPath)
            let symbolGraphData = try Data(contentsOf: symbolGraphURL)
            let decoder = JSONDecoder()
            let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: symbolGraphData)
            
            // Analyze the symbol graph structure for common OpenAPI conversion issues
            
            print("\n=== OpenAPI to SymbolGraph Analysis ===")
            
            // 1. Check for API operations/endpoints
            var operations: [(String, SymbolKit.SymbolGraph.Symbol)] = []
            var schemas: [(String, SymbolKit.SymbolGraph.Symbol)] = []
            var parameters: [(String, SymbolKit.SymbolGraph.Symbol)] = []
            var responses: [(String, SymbolKit.SymbolGraph.Symbol)] = []
            
            for (id, symbol) in symbolGraph.symbols {
                if id.hasPrefix("operation:") || symbol.identifier.precise.hasPrefix("operation:") {
                    operations.append((id, symbol))
                } else if id.hasPrefix("schema:") || symbol.identifier.precise.hasPrefix("schema:") {
                    schemas.append((id, symbol))
                } else if id.hasPrefix("parameter:") || symbol.identifier.precise.hasPrefix("parameter:") {
                    parameters.append((id, symbol))
                } else if id.hasPrefix("response:") || symbol.identifier.precise.hasPrefix("response:") {
                    responses.append((id, symbol))
                }
            }
            
            print("Found:")
            print("- \(operations.count) API operations/endpoints")
            print("- \(schemas.count) schemas/models")
            print("- \(parameters.count) parameters")
            print("- \(responses.count) responses")
            
            // 2. Check for HTTP mixins utilization
            var operationsWithHttpMixins = 0
            var operationsWithoutHttpMixins = 0
            
            for (_, symbol) in operations {
                if symbol.httpEndpoint != nil {
                    operationsWithHttpMixins += 1
                } else {
                    operationsWithoutHttpMixins += 1
                }
            }
            
            if operationsWithHttpMixins > 0 {
                print("\n✅ \(operationsWithHttpMixins)/\(operations.count) operations use HTTP mixins")
            } else if operations.count > 0 {
                print("\n⚠️ None of the operations use HTTP mixins, which could improve DocC rendering")
                print("Consider adding HTTP mixins to enhance documentation of REST APIs")
            }
            
            // 3. Check path component hierarchy
            var symbolsWithInvalidPaths: [(String, SymbolKit.SymbolGraph.Symbol, [String])] = []
            
            for (id, symbol) in symbolGraph.symbols {
                let pathComponents = symbol.pathComponents
                
                // Skip first component and module itself
                if pathComponents.count <= 1 || id == "module" {
                    continue
                }
                
                // Check if each parent in the path exists
                var validComponents: [String] = []
                var invalidComponents: [String] = []
                var currentPath: [String] = []
                
                for (index, component) in pathComponents.enumerated() {
                    // Skip the last component (which is the symbol itself)
                    if index == pathComponents.count - 1 {
                        continue
                    }
                    
                    currentPath.append(component)
                    let parentPath = currentPath.joined(separator: "/")
                    
                    // Check if a symbol with this path exists
                    let parentExists = symbolGraph.symbols.values.contains { parentSymbol in
                        parentSymbol.pathComponents.count == currentPath.count &&
                        parentSymbol.pathComponents.joined(separator: "/") == parentPath
                    }
                    
                    if !parentExists {
                        invalidComponents.append(component)
                    } else {
                        validComponents.append(component)
                    }
                }
                
                if !invalidComponents.isEmpty {
                    symbolsWithInvalidPaths.append((id, symbol, invalidComponents))
                }
            }
            
            if !symbolsWithInvalidPaths.isEmpty {
                print("\n❌ Found \(symbolsWithInvalidPaths.count) symbols with invalid path hierarchies:")
                for (id, symbol, invalidComponents) in symbolsWithInvalidPaths.prefix(10) {
                    print("  \(symbol.names.title) (\(id)):")
                    print("    Invalid path components: \(invalidComponents.joined(separator: ", "))")
                    print("    Full path: \(symbol.pathComponents.joined(separator: " → "))")
                }
                
                if symbolsWithInvalidPaths.count > 10 {
                    print("  ... and \(symbolsWithInvalidPaths.count - 10) more")
                }
                
                print("\nThis will cause DocC to crash with 'Symbol has no reference' errors")
                print("Ensure all parent components in paths have corresponding symbols in the graph")
            } else {
                print("\n✅ All symbols have valid path hierarchies")
            }
            
            // 4. Check for orphaned relationships
            var danglingRelationships: [(SymbolKit.SymbolGraph.Relationship, String)] = []
            
            for relationship in symbolGraph.relationships {
                if !symbolGraph.symbols.keys.contains(relationship.source) && relationship.source != "module" {
                    danglingRelationships.append((relationship, "Missing source: \(relationship.source)"))
                }
                
                if !symbolGraph.symbols.keys.contains(relationship.target) {
                    danglingRelationships.append((relationship, "Missing target: \(relationship.target)"))
                }
            }
            
            if !danglingRelationships.isEmpty {
                print("\n❌ Found \(danglingRelationships.count) dangling relationships:")
                for (relationship, issue) in danglingRelationships.prefix(10) {
                    print("  \(relationship.kind.rawValue) from \(relationship.source) to \(relationship.target)")
                    print("    Issue: \(issue)")
                }
                
                if danglingRelationships.count > 10 {
                    print("  ... and \(danglingRelationships.count - 10) more")
                }
                
                print("\nThis will cause DocC to crash with symbol reference errors")
            } else {
                print("\n✅ All relationships are valid (no dangling references)")
            }
            
            // 5. Give advice on OpenAPI to SymbolGraph conversion
            print("\n=== Recommendations for OpenAPI to SymbolGraph Conversion ===")
            print("1. Ensure all schemas have corresponding symbols with proper path hierarchies")
            print("2. Use HTTP mixins to enhance REST API documentation:")
            print("   - httpEndpoint: For operations (method, path, baseURL)")
            print("   - httpParameterSource: For parameters (path, query, header, body)")
            print("   - httpMediaType: For request/response content types")
            print("3. Create proper memberOf relationships between:")
            print("   - Parameters → Operations")
            print("   - Responses → Operations")
            print("   - Properties → Schemas")
            print("4. Generate conformsTo relationships for schema inheritance")
            print("5. Include defaultImplementationOf for endpoint implementations")
            
            print("\nFor more details on Symbol Graph structure, see:")
            print("https://github.com/apple/swift-docc-symbolkit/tree/main/Sources/SymbolKit")
        }
    }
}

SymbolGraphDebug.main() 
