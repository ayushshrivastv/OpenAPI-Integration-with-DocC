import Foundation
import ArgumentParser
import OpenAPItoSymbolGraph
import Integration
import OpenAPI

struct OpenAPIToSymbolGraph: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "openapi-to-symbolgraph",
        abstract: "Convert OpenAPI specifications to DocC symbol graphs",
        version: "1.0.0"
    )
    
    @Argument(help: "Path to the OpenAPI specification file")
    var inputPath: String
    
    @Option(name: .long, help: "Path where the symbol graph file should be written", transform: { $0 })
    var outputPath: String = "openapi.symbolgraph.json"
    
    @Option(name: .long, help: "Name to use for the module in the symbol graph", transform: { $0 })
    var moduleName: String?
    
    @Option(name: .long, help: "Base URL of the API for HTTP endpoint documentation", transform: { URL(string: $0) })
    var baseURL: URL?
    
    mutating func run() throws {
        // Check file extension
        let fileExtension = URL(fileURLWithPath: inputPath).pathExtension.lowercased()
        guard fileExtension == "yaml" || fileExtension == "yml" || fileExtension == "json" else {
            throw ConversionError.unsupportedFileType(fileExtension)
        }
        
        // Read the OpenAPI file
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Read the file content
        let fileContent = try String(contentsOf: inputURL, encoding: .utf8)
        
        // Parse the OpenAPI document
        let parser = YAMLParser()
        do {
            let document = try parser.parse(fileContent)
            
            // Convert to symbol graph
            let converter = Integration.OpenAPIDocCConverter(moduleName: moduleName, baseURL: baseURL)
            let symbolGraph = converter.convert(document)
            
            // Write the symbol graph to file
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(symbolGraph)
            try jsonData.write(to: outputURL)
            
            print("Successfully generated symbol graph at \(outputPath)")
        } catch let error as ParserError {
            throw ConversionError.parsingError(error)
        }
    }
}

OpenAPIToSymbolGraph.main() 
