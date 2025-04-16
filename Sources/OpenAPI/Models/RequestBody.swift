import Foundation

/// Represents a request body
public struct RequestBody {
    /// The content of the request body
    public let content: [String: MediaType]
    
    /// Whether the request body is required
    public let required: Bool
    
    /// Creates a new request body
    /// - Parameters:
    ///   - content: The content of the request body
    ///   - required: Whether the request body is required
    public init(
        content: [String: MediaType],
        required: Bool = false
    ) {
        self.content = content
        self.required = required
    }
} 
