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
        subcommands: [Analyze.self, ValidateRelationships.self, ShowSymbol.self, ShowHTTP.self]
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
}

SymbolGraphDebug.main() 
