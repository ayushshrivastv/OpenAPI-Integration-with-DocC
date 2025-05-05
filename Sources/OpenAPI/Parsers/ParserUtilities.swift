import Foundation

/// Utility methods for parsing OpenAPI documents
class ParserUtilities {
    
    /// Detects and validates OpenAPI version string
    /// - Parameter dict: The dictionary containing the OpenAPI document
    /// - Returns: The validated OpenAPI version string
    /// - Throws: ParserError if the version is missing or invalid
    static func detectAndValidateVersion(in dict: [String: Any]) throws -> String {
        // Check for both OpenAPI v3 and Swagger v2 format
        let openapi: String
        if let openapiValue = dict["openapi"] as? String {
            openapi = openapiValue
        } else if let swaggerValue = dict["swagger"] as? String {
            // OpenAPI v2 (Swagger) format
            openapi = swaggerValue
            print("Detected OpenAPI v2 (Swagger) format.")
        } else {
            throw ParserError.missingRequiredField("openapi or swagger")
        }
        
        // Validate OpenAPI version - support both v2 and v3
        let versionComponents = openapi.split(separator: ".")
        guard versionComponents.count >= 2 else {
            throw ParserError.invalidDocument("Invalid OpenAPI version format. Expected format: major.minor.patch")
        }
        
        let majorVersion = String(versionComponents[0])
        guard majorVersion == "2" || majorVersion == "3" else {
            throw ParserError.invalidDocument("Unsupported OpenAPI version. Supported versions: 2.x.x and 3.x.x")
        }
        
        return openapi
    }
    
    /// Validates response codes in an OpenAPI document
    /// - Parameters:
    ///   - code: The response code to validate
    ///   - path: The path containing the response
    ///   - method: The HTTP method for the operation
    /// - Returns: Boolean indicating if the response code is valid
    static func validateResponseCode(_ code: String, path: String, method: String) -> Bool {
        // Handle common response code patterns
        let cleanedCode = code.trimmingCharacters(in: .punctuationCharacters)
        
        if let intCode = Int(cleanedCode) {
            if !(100...599).contains(intCode) {
                print("Warning: Potentially invalid response code \(code) in path: \(path), method: \(method). Will process anyway.")
                return true
            }
            return true
        } else if cleanedCode == "default" {
            return true
        } else {
            print("Warning: Unexpected response code format: \(code) in path: \(path), method: \(method). Will process anyway.")
            return true
        }
    }
    
    /// Creates a placeholder response for invalid or unexpected response formats
    /// - Parameter statusCode: The status code for the response
    /// - Returns: A Response object with a default description
    static func createPlaceholderResponse(for statusCode: String) -> Response {
        return Response(
            description: "Response for status code \(statusCode)",
            content: nil
        )
    }
    
    /// Handles schemas with missing type information
    /// - Parameter dict: The dictionary containing the schema definition
    /// - Returns: A JSONSchema object with a default type if none is specified
    /// - Throws: ParserError if the schema can't be parsed
    static func handleMissingSchemaType(_ dict: [String: Any]) -> JSONSchema {
        print("Warning: Schema missing type field. Defaulting to object type.")
        return .object(ObjectSchema(required: [], properties: [:]))
    }
    
    /// Handles unknown schema types
    /// - Parameters:
    ///   - type: The unknown schema type
    /// - Returns: A JSONSchema with a default type
    static func handleUnknownSchemaType(_ type: String) -> JSONSchema {
        print("Warning: Unsupported schema type '\(type)'. Defaulting to string type.")
        return .string(StringSchema())
    }
    
    /// Creates a placeholder schema for a reference that couldn't be resolved
    /// - Parameter refName: The name of the reference that couldn't be resolved
    /// - Returns: A JSONSchema object with a placeholder schema
    static func createPlaceholderSchema(for refName: String) -> JSONSchema {
        print("Creating placeholder schema for unresolved reference: \(refName)")
        return .object(ObjectSchema(
            required: [],
            properties: ["placeholder": .string(StringSchema())]
        ))
    }
    
    /// Validates and extracts a schema from a content dictionary, handling errors gracefully
    /// - Parameters:
    ///   - contentDict: The content dictionary from the OpenAPI document
    ///   - contentType: The content type being processed
    /// - Returns: A MediaType object or nil if processing failed
    static func extractSchema(from contentDict: [String: Any]?, contentType: String) -> MediaType? {
        guard let contentDict = contentDict else { return nil }
        
        guard let schemaDict = contentDict["schema"] as? [String: Any] else {
            print("Warning: Missing schema in content type \(contentType). Creating a placeholder schema.")
            return MediaType(schema: .object(ObjectSchema(required: [], properties: [:])))
        }
        
        // Try to handle the schema if possible
        do {
            if let parser = schemaDict["parser"] as? (([String: Any]) throws -> JSONSchema) {
                return MediaType(schema: try parser(schemaDict))
            } else {
                // Create a default schema based on the content type
                if contentType.contains("json") {
                    return MediaType(schema: .object(ObjectSchema(required: [], properties: [:])))
                } else if contentType.contains("xml") {
                    return MediaType(schema: .object(ObjectSchema(required: [], properties: [:])))
                } else if contentType.contains("text") || contentType.contains("plain") {
                    return MediaType(schema: .string(StringSchema()))
                } else {
                    return MediaType(schema: .string(StringSchema()))
                }
            }
        } catch {
            print("Warning: Error parsing schema for content type \(contentType): \(error). Creating a placeholder schema.")
            return MediaType(schema: .string(StringSchema()))
        }
    }
}
