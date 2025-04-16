import Foundation

/// Errors that can occur during parsing
public enum ParserError: Error {
    /// The YAML content is invalid
    case invalidYAML
    
    /// The JSON content is invalid
    case invalidJSON
    
    /// A required field is missing
    case missingRequiredField(String)
    
    /// A path item is invalid
    case invalidPathItem(String)
    
    /// A parameter location is invalid
    case invalidParameterLocation
    
    /// A media type is invalid
    case invalidMediaType(String)
    
    /// A response is invalid
    case invalidResponse(String)
    
    /// A schema is invalid
    case invalidSchema(String)
    
    /// A property is invalid
    case invalidProperty(String)
    
    /// A schema type is unknown
    case unknownSchemaType(String)
    
    /// The document is invalid
    case invalidDocument(String)
} 
