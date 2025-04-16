import Foundation

/// Represents a response
public struct Response {
    /// A description of the response
    public let description: String
    
    /// The content of the response
    public let content: [String: MediaType]?
    
    /// Creates a new response
    /// - Parameters:
    ///   - description: A description of the response
    ///   - content: The content of the response
    public init(
        description: String,
        content: [String: MediaType]? = nil
    ) {
        self.description = description
        self.content = content
    }
}

/// Represents a media type
public struct MediaType {
    /// The schema of the media type
    public let schema: JSONSchema
    
    /// Creates a new media type
    /// - Parameter schema: The schema of the media type
    public init(schema: JSONSchema) {
        self.schema = schema
    }
} 
