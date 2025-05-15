import Foundation
import OpenAPI
import DocC
import SymbolKit

/// A converter that converts OpenAPI documents to DocC symbol graphs
public struct OpenAPIDocCConverter {
    /// The name to use for the module
    private let moduleName: String?
    /// Base URL for the API
    private let baseURL: URL?
    /// Whether to include examples in the documentation
    private let includeExamples: Bool

    /// Creates a new OpenAPI to DocC converter
    /// - Parameters:
    ///   - moduleName: The name to use for the module. If nil, the info.title from the OpenAPI document will be used
    ///   - baseURL: The base URL to use for the API
    ///   - includeExamples: Whether to include examples in the documentation. Defaults to true
    public init(moduleName: String? = nil, baseURL: URL? = nil, includeExamples: Bool = true) {
        self.moduleName = moduleName
        self.baseURL = baseURL
        self.includeExamples = includeExamples
    }

    /// Converts an OpenAPI document to a DocC symbol graph
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The DocC symbol graph
    public func convert(_ document: Document) -> SymbolKit.SymbolGraph {
        let generator = SymbolGraphGenerator(
            moduleName: moduleName,
            baseURL: baseURL,
            includeExamples: includeExamples
        )
        return generator.generate(from: document)
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
