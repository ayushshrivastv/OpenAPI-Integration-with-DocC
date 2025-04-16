import Foundation
import Integration

/// Helper function to convert an OpenAPI document to documentation
/// - Parameter filePath: The path to the OpenAPI file
/// - Returns: The generated documentation
/// - Throws: An error if the conversion fails
public func convertFile(filePath: String) throws -> String {
    let converter = OpenAPIDocCConverter()
    let fileURL = URL(fileURLWithPath: filePath)
    return try converter.convert(fileURL: fileURL)
}
