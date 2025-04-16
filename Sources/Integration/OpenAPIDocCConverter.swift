import Foundation
import OpenAPI
import DocC
import SymbolKit

/// A converter that converts OpenAPI documents to DocC symbol graphs
public struct OpenAPIDocCConverter {
    /// Creates a new OpenAPI to DocC converter
    public init() {}
    
    /// Converts an OpenAPI document to a DocC symbol graph
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The DocC symbol graph
    public func convert(_ document: Document) -> SymbolKit.SymbolGraph {
        let generator = SymbolGraphGenerator()
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
