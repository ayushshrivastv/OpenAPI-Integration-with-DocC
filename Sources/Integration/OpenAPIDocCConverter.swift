import Foundation
import Core
import OpenAPI
import DocC

/// The main converter that integrates OpenAPI parsing and DocC generation
public struct OpenAPIDocCConverter {
    private let yamlParser: YAMLParser
    private let jsonParser: JSONParser
    private let symbolGraphGenerator: SymbolGraphGenerator
    private let symbolGraphRenderer: SymbolGraphRenderer
    
    /// Creates a new OpenAPI to DocC converter
    public init() {
        self.yamlParser = YAMLParser()
        self.jsonParser = JSONParser()
        self.symbolGraphGenerator = SymbolGraphGenerator()
        self.symbolGraphRenderer = SymbolGraphRenderer()
    }
    
    /// Converts an OpenAPI file to DocC documentation
    /// - Parameter fileURL: The URL of the OpenAPI file to convert
    /// - Returns: The generated DocC documentation
    /// - Throws: An error if the file cannot be read or parsed
    public func convert(fileURL: URL) throws -> String {
        let document: Document
        
        switch fileURL.pathExtension.lowercased() {
        case "yaml", "yml":
            document = try yamlParser.parse(fileURL: fileURL)
        case "json":
            document = try jsonParser.parse(fileURL: fileURL)
        default:
            throw ConversionError.unsupportedFileType(fileURL.pathExtension)
        }
        
        let symbolGraph = symbolGraphGenerator.generate(from: document)
        return symbolGraphRenderer.render(symbolGraph)
    }
    
    /// Converts an OpenAPI string to DocC documentation
    /// - Parameters:
    ///   - content: The OpenAPI content to convert
    ///   - format: The format of the content (yaml or json)
    /// - Returns: The generated DocC documentation
    /// - Throws: An error if the content cannot be parsed
    public func convert(content: String, format: OpenAPIFormat) throws -> String {
        let document: Document
        
        switch format {
        case .yaml:
            document = try yamlParser.parse(content)
        case .json:
            document = try jsonParser.parse(content)
        }
        
        let symbolGraph = symbolGraphGenerator.generate(from: document)
        return symbolGraphRenderer.render(symbolGraph)
    }
}

/// The format of an OpenAPI document
public enum OpenAPIFormat {
    case yaml
    case json
}

/// Errors that can occur during conversion
public enum ConversionError: Error {
    case unsupportedFileType(String)
    case parsingError(Error)
    case generationError(Error)
    case renderingError(Error)
} 
