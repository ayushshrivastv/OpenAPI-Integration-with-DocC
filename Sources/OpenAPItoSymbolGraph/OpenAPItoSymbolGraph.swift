import Foundation
import OpenAPI
import DocC
import Integration

/// The main entry point for converting OpenAPI documents to DocC documentation
public struct OpenAPItoSymbolGraph {
    /// The name to use for the module
    private let moduleName: String?
    /// Base URL for the API
    private let baseURL: URL?
    /// Output directory for generated files
    private let outputDirectory: URL
    /// Whether to include examples in the documentation
    private let includeExamples: Bool

    /// Creates a new OpenAPI to DocC converter
    /// - Parameters:
    ///   - moduleName: The name to use for the module. If nil, the info.title from the OpenAPI document will be used
    ///   - baseURL: The base URL to use for the API
    ///   - outputDirectory: The directory where the output files will be created
    ///   - includeExamples: Whether to include examples in the documentation. Defaults to true
    public init(
        moduleName: String? = nil,
        baseURL: URL? = nil,
        outputDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        includeExamples: Bool = true
    ) {
        self.moduleName = moduleName
        self.baseURL = baseURL
        self.outputDirectory = outputDirectory
        self.includeExamples = includeExamples
    }

    /// Converts an OpenAPI document to a SymbolGraph JSON file
    /// - Parameters:
    ///   - document: The OpenAPI document to convert
    ///   - outputPath: The path where the symbol graph file should be written
    /// - Throws: An error if the conversion fails
    public func convertToSymbolGraph(_ document: Document, outputPath: String) throws {
        let converter = OpenAPIDocCConverter(
            moduleName: moduleName,
            baseURL: baseURL,
            includeExamples: includeExamples
        )
        let symbolGraph = converter.convert(document)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(symbolGraph)

        let outputURL = URL(fileURLWithPath: outputPath)
        try jsonData.write(to: outputURL)
    }

    /// Converts an OpenAPI document to a DocC catalog
    /// - Parameters:
    ///   - document: The OpenAPI document to convert
    ///   - overwrite: Whether to overwrite existing files
    /// - Returns: The path to the generated .docc catalog
    /// - Throws: An error if the conversion fails
    public func convertToDocCCatalog(_ document: Document, overwrite: Bool = false) throws -> URL {
        let generator = DocCCatalogGenerator(
            moduleName: moduleName,
            baseURL: baseURL,
            outputDirectory: outputDirectory
        )

        return try generator.generateCatalog(from: document, overwrite: overwrite)
    }

    /// Converts an OpenAPI document to Markdown documentation
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated Markdown documentation
    /// - Throws: An error if the conversion fails
    public func convertToMarkdown(_ document: Document) throws -> String {
        let converter = OpenAPIDocCConverter(
            moduleName: moduleName,
            baseURL: baseURL,
            includeExamples: includeExamples
        )
        let symbolGraph = converter.convert(document)
        let renderer = SymbolGraphRenderer()

        return renderer.render(symbolGraph)
    }
}
