import Foundation
import OpenAPIKit
import SymbolKit
import ArgumentParser
import Yams
import Core
import OpenAPItoSymbolGraph

@main
struct OpenAPItoSymbolGraphCommand: ParsableCommand {
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

        // Use the OpenAPItoSymbolGraph module to perform conversion
        _ = try OpenAPItoSymbolGraph.convert(
            openAPIData: data, 
            fileExtension: fileExtension,
            outputPath: outputPath
        )
        
        print("✅ Successfully generated symbol graph at: \(outputPath)")
    }
}

enum RunError: Error {
    case parsingError(String)
    case invalidFileType(String)
} 
