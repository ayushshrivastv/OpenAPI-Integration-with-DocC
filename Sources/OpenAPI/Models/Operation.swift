import Foundation

/// Represents an API operation
public struct Operation {
    /// A short summary of the operation
    public let summary: String?
    
    /// A detailed description of the operation
    public let description: String?
    
    /// The parameters for the operation
    public let parameters: [Parameter]?
    
    /// The request body for the operation
    public let requestBody: RequestBody?
    
    /// The possible responses for the operation
    public let responses: [String: Response]
    
    /// Whether the operation is deprecated
    public let deprecated: Bool
    
    /// The tags for the operation
    public let tags: [String]?
    
    /// Creates a new operation
    /// - Parameters:
    ///   - summary: A short summary of the operation
    ///   - description: A detailed description of the operation
    ///   - parameters: The parameters for the operation
    ///   - requestBody: The request body for the operation
    ///   - responses: The possible responses for the operation
    ///   - deprecated: Whether the operation is deprecated
    ///   - tags: The tags for the operation
    public init(
        summary: String? = nil,
        description: String? = nil,
        parameters: [Parameter]? = nil,
        requestBody: RequestBody? = nil,
        responses: [String: Response],
        deprecated: Bool = false,
        tags: [String]? = nil
    ) {
        self.summary = summary
        self.description = description
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
        self.deprecated = deprecated
        self.tags = tags
    }
    
    /// Returns the response for the given status code
    /// - Parameter statusCode: The HTTP status code
    /// - Returns: The response for the given status code, or nil if not found
    public func response(for statusCode: String) -> Response? {
        return responses[statusCode]
    }
    
    /// Returns the default response (status code "default")
    /// - Returns: The default response, or nil if not found
    public func defaultResponse() -> Response? {
        return responses["default"]
    }
    
    /// Returns all parameters, including those from the path item
    /// - Parameter pathItem: The path item containing shared parameters
    /// - Returns: An array of all parameters
    public func allParameters(pathItem: PathItem? = nil) -> [Parameter] {
        var allParameters: [Parameter] = []
        
        // Add path item parameters first
        if let pathParameters = pathItem?.parameters {
            allParameters.append(contentsOf: pathParameters)
        }
        
        // Add operation parameters
        if let operationParameters = parameters {
            allParameters.append(contentsOf: operationParameters)
        }
        
        return allParameters
    }
    
    /// Returns the content type of the request body
    /// - Returns: The content type, or nil if no request body
    public func requestContentType() -> String? {
        return requestBody?.content.keys.first
    }
    
    /// Returns the schema of the request body
    /// - Returns: The schema, or nil if no request body
    public func requestSchema() -> JSONSchema? {
        return requestBody?.content.values.first?.schema
    }
} 
