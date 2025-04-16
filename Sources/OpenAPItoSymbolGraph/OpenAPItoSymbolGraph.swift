import Foundation
import OpenAPI
import DocC
import Integration

/// The main entry point for converting OpenAPI documents to DocC documentation
public struct OpenAPItoSymbolGraph {
    private let converter: OpenAPIDocCConverter
    private let renderer: SymbolGraphRenderer
    
    /// Creates a new OpenAPI to DocC converter
    public init() {
        self.converter = OpenAPIDocCConverter()
        self.renderer = SymbolGraphRenderer()
    }
    
    /// Converts an OpenAPI document to DocC documentation
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated DocC documentation
    /// - Throws: An error if the conversion fails
    public func convert(_ document: Document) throws -> String {
        let symbolGraph = converter.convert(document)
        return renderer.render(symbolGraph)
    }
}
