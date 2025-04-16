import Foundation
import Integration
import OpenAPI
import SymbolKit

/// Helper function to convert an OpenAPI document to documentation
/// - Parameter filePath: The path to the OpenAPI file
/// - Returns: The generated documentation
/// - Throws: An error if the conversion fails
public func convertFile(filePath: String) throws -> SymbolKit.SymbolGraph {
    // Read the file content
    let fileURL = URL(fileURLWithPath: filePath)
    let fileContent = try String(contentsOf: fileURL, encoding: .utf8)

    // Parse the OpenAPI document
    let parser = YAMLParser()
    let document = try parser.parse(fileContent)

    // Convert to symbol graph
    let converter = OpenAPIDocCConverter()
    return converter.convert(document)
}
