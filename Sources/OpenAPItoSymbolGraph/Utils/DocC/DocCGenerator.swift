import Foundation
import OpenAPI
import DocC
import Integration

/// A generator for DocC documentation from OpenAPI documents
struct DocCGenerator {
    /// Generates DocC documentation from an OpenAPI document
    /// - Parameter document: The OpenAPI document to generate documentation from
    /// - Returns: The generated DocC documentation
    /// - Throws: An error if the generation fails
    static func generate(from document: Document) throws -> String {
        let converter = OpenAPIDocCConverter()
        let renderer = SymbolGraphRenderer()
        
        let symbolGraph = converter.convert(document)
        return renderer.render(symbolGraph)
    }
} 
