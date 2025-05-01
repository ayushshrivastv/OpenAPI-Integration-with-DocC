import Foundation
import ArgumentParser
import OpenAPI
import DocC
import SymbolKit
import OpenAPItoSymbolGraph

/// Command for converting OpenAPI documents to DocC symbol graphs
struct OpenAPItoDocC: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "openapi-to-docc",
        abstract: "Convert OpenAPI documents to DocC symbol graphs",
        version: "1.0.0"
    )
    
    @Argument(help: "The path to the OpenAPI document (YAML or JSON)")
    var input: String
    
    @Option(name: .shortAndLong, help: "The output directory for the symbol graph file")
    var output: String = "."
    
    @Option(name: .customLong("output-path"), help: "Alternative name for output directory")
    var outputPath: String?
    
    @Option(name: .shortAndLong, help: "The name for the module")
    var moduleName: String?
    
    @Option(name: .long, help: "The base URL for the API")
    var baseURL: String?
    
    mutating func run() throws {
        // Use outputPath if provided as alternative to output
        let finalOutput = outputPath ?? output
        
        // 1. Determine if input is YAML or JSON
        let inputURL = URL(fileURLWithPath: input)
        let fileExtension = inputURL.pathExtension.lowercased()
        
        // 2. Parse the document
        print("Parsing OpenAPI document: \(input)")
        let document: OpenAPI.Document
        
        do {
            if fileExtension == "yaml" || fileExtension == "yml" {
                let parser = OpenAPI.YAMLParser()
                document = try parser.parse(fileURL: inputURL)
            } else if fileExtension == "json" {
                let parser = OpenAPI.JSONParser()
                document = try parser.parse(fileURL: inputURL)
            } else {
                throw ValidationError("Unsupported file format. Please provide a YAML or JSON file.")
            }
        } catch {
            print("Error parsing OpenAPI document: \(error)")
            throw ValidationError("Failed to parse OpenAPI document")
        }
        
        // 3. Generate the symbol graph
        print("Generating symbol graph...")
        var baseURLObj: URL?
        if let baseURLString = baseURL {
            baseURLObj = URL(string: baseURLString)
        }
        
        var generator = DocC.SymbolGraphGenerator(
            moduleName: moduleName ?? document.info.title,
            baseURL: baseURLObj
        )
        
        let symbolGraph = generator.generate(from: document)
        
        // 4. Write the symbol graph to a file
        let outputFileName = (moduleName ?? document.info.title.replacingOccurrences(of: " ", with: "")) + ".symbols.json"
        let outputURL = URL(fileURLWithPath: finalOutput).appendingPathComponent(outputFileName)
        
        print("Writing symbol graph to: \(outputURL.path)")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(symbolGraph)
            try data.write(to: outputURL)
            print("Symbol graph successfully written to \(outputURL.path)")
        } catch {
            print("Error writing symbol graph: \(error)")
            throw ValidationError("Failed to write symbol graph")
        }
    }
}

OpenAPItoDocC.main() 
