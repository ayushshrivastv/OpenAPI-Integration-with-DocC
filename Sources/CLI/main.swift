import Foundation
import ArgumentParser
import OpenAPItoSymbolGraph
import Integration
import OpenAPI

struct OpenAPIToolCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "openapi-tool",
        abstract: "Tools for working with OpenAPI and DocC",
        version: "1.0.0",
        subcommands: [
            OpenAPIToSymbolGraph.self,
            OpenAPIToDocC.self
        ]
    )
}

struct OpenAPIToSymbolGraph: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "to-symbolgraph",
        abstract: "Convert OpenAPI specifications to DocC symbol graphs"
    )

    @Argument(help: "Path to the OpenAPI specification file")
    var inputPath: String

    @Option(name: .long, help: "Path where the symbol graph file should be written", transform: { $0 })
    var outputPath: String = "openapi.symbolgraph.json"

    @Option(name: .long, help: "Name to use for the module in the symbol graph", transform: { $0 })
    var moduleName: String?

    @Option(name: .long, help: "Base URL of the API for HTTP endpoint documentation", transform: { URL(string: $0) })
    var baseURL: URL?

    @Flag(name: .long, help: "Include examples in the documentation")
    var includeExamples: Bool = true

    mutating func run() throws {
        // Check file extension
        let fileExtension = URL(fileURLWithPath: inputPath).pathExtension.lowercased()
        guard fileExtension == "yaml" || fileExtension == "yml" || fileExtension == "json" else {
            throw ConversionError.unsupportedFileType(fileExtension)
        }

        // Read the OpenAPI file
        let inputURL = URL(fileURLWithPath: inputPath)

        // Read the file content
        let fileContent = try String(contentsOf: inputURL, encoding: .utf8)

        // Parse the OpenAPI document
        let parser = YAMLParser()
        do {
            let document = try parser.parse(fileContent)

            // Convert to symbol graph
            let converter = OpenAPItoSymbolGraph(
                moduleName: moduleName,
                baseURL: baseURL,
                includeExamples: includeExamples
            )
            try converter.convertToSymbolGraph(document, outputPath: outputPath)

            print("Successfully generated symbol graph at \(outputPath)")
        } catch let error as ParserError {
            throw ConversionError.parsingError(error)
        }
    }
}

struct OpenAPIToDocC: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "to-docc",
        abstract: "Convert OpenAPI specifications to DocC catalogs"
    )

    @Argument(help: "Path to the OpenAPI specification file")
    var inputPath: String

    @Option(name: .long, help: "Directory where the DocC catalog will be created", transform: { URL(fileURLWithPath: $0) })
    var outputDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    @Option(name: .long, help: "Name to use for the module in the documentation", transform: { $0 })
    var moduleName: String?

    @Option(name: .long, help: "Base URL of the API for HTTP endpoint documentation", transform: { URL(string: $0) })
    var baseURL: URL?

    @Flag(name: .long, help: "Overwrite existing files")
    var overwrite: Bool = false

    @Flag(name: .long, help: "Include examples in the documentation")
    var includeExamples: Bool = true

    mutating func run() throws {
        // Check file extension
        let fileExtension = URL(fileURLWithPath: inputPath).pathExtension.lowercased()
        guard fileExtension == "yaml" || fileExtension == "yml" || fileExtension == "json" else {
            throw ConversionError.unsupportedFileType(fileExtension)
        }

        // Read the OpenAPI file
        let inputURL = URL(fileURLWithPath: inputPath)

        // Read the file content
        let fileContent = try String(contentsOf: inputURL, encoding: .utf8)

        // Parse the OpenAPI document
        let parser = YAMLParser()
        do {
            let document = try parser.parse(fileContent)

            // Convert to DocC catalog
            let converter = OpenAPItoSymbolGraph(
                moduleName: moduleName,
                baseURL: baseURL,
                outputDirectory: outputDirectory,
                includeExamples: includeExamples
            )

            let catalogURL = try converter.convertToDocCCatalog(document, overwrite: overwrite)

            print("Successfully generated DocC catalog at \(catalogURL.path)")
            print("\nTo build documentation with DocC, run:")
            print("xcrun docc convert \(catalogURL.lastPathComponent) --output-path ./docs")
        } catch let error as ParserError {
            throw ConversionError.parsingError(error)
        } catch let error as CatalogGenerationError {
            switch error {
            case .catalogAlreadyExists(let path):
                print("Error: Catalog already exists at \(path)")
                print("Use --overwrite to replace the existing catalog")
            case .failedToCreateDirectory(let path):
                print("Error: Failed to create directory at \(path)")
            case .failedToWriteFile(let path):
                print("Error: Failed to write file at \(path)")
            }
            throw error
        }
    }
}

OpenAPIToolCommand.main()
